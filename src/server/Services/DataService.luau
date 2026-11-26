-- DataService: 플레이어 데이터 저장/불러오기를 전담한다. DataStore는 이 파일에서만 쓴다.
-- 의존: Config
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

-- 기본 데이터 모양. 새 항목은 여기에만 추가한다. (02_PRD.md 5-3 저장 데이터 모양과 같게 유지)
local DEFAULT_DATA = {
	version = 2,
	lastDaily = 0, -- 마지막으로 일일 보상을 받은 시각 (1970년부터 센 초, os.time()). 0이면 아직 안 받음
	coins = 0,
	pets = {}, -- { { uid = "1", id = "Dog" }, ... }
	equipped = {}, -- 장착한 펫의 uid 목록
	zones = { 1 }, -- (지금은 안 씀) 예전 "구역 열기" 기록. 모든 구역이 열려 있게 바뀌었지만, 저장된 값을 지우지 않으려고 남겨 둔다.
	nextPetUid = 1, -- 다음에 줄 펫 uid
}

local dataStore = nil -- Start에서 연결한다. 연결에 실패하면 nil로 남는다.
local profiles = {} -- [player] = 그 플레이어의 데이터 테이블
local canSave = {} -- [player] = true. 불러오기에 "성공한" 플레이어만 저장한다. (빈 데이터로 덮어쓰기 방지)
local loadedCallbacks = {} -- 데이터가 준비됐을 때 알려 줄 함수 목록

-- 테이블을 통째로 복사한다. 기본값을 그대로 넘기면 모든 플레이어가 같은 테이블을 나눠 쓰게 되기 때문이다.
local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function getKey(player: Player): string
	return "Player_" .. player.UserId
end

-- DataStore 요청은 가끔 실패하므로 pcall로 감싸고 최대 SAVE_RETRY_COUNT번 다시 시도한다.
local function retry(label: string, func)
	local lastError
	for attempt = 1, Config.SAVE_RETRY_COUNT do
		local ok, result = pcall(func)
		if ok then
			return true, result
		end
		lastError = result
		warn(`[DataService] {label} 실패 ({attempt}/{Config.SAVE_RETRY_COUNT}):`, result)
		if attempt < Config.SAVE_RETRY_COUNT then
			task.wait(Config.SAVE_RETRY_WAIT)
		end
	end
	return false, lastError
end

-- 옛날 모양의 데이터를 지금 모양으로 바꾼다. version을 올릴 때마다 여기에 변환 코드를 추가한다.
local function migrate(data)
	if type(data.version) ~= "number" then
		data.version = 1
	end
	-- 버전 1 → 2: lastDaily(일일 보상) 항목이 생겼다. 값은 아래 fillDefaults가 0으로 채우므로 버전만 올린다.
	-- 기존 코인, 펫, 구역은 그대로 남는다.
	if data.version < 2 then
		data.version = 2
	end
end

-- 불러온 데이터에 새로 생긴 항목이 없으면 기본값으로 채운다.
local function fillDefaults(data)
	for key, defaultValue in DEFAULT_DATA do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		end
	end
end

-- 데이터가 준비됐다고 다른 서비스들에게 알린다.
local function notifyLoaded(player: Player, data)
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
end

local function onLoadFailed(player: Player, reason)
	warn("[DataService] 불러오기 최종 실패:", player.Name, reason)
	if RunService:IsStudio() then
		-- Studio에서는 테스트를 계속할 수 있게 기본 데이터로 놀게 하되, 저장은 하지 않는다.
		warn("[DataService] Studio 안내: 게임을 게시(File → Publish to Roblox)하고, Game Settings → Security → 'Enable Studio Access to API Services'를 켜야 저장돼요.")
		profiles[player] = deepCopy(DEFAULT_DATA)
		notifyLoaded(player, profiles[player])
	else
		-- 실제 게임에서는 저장이 안 되는 채로 놀다가 진행을 잃지 않도록 다시 접속하게 한다.
		player:Kick("데이터를 불러오지 못했어요. 잠시 후 다시 접속해 주세요.")
	end
end

local function loadPlayer(player: Player)
	if not dataStore then
		onLoadFailed(player, "DataStore에 연결되지 않음")
		return
	end

	local ok, stored = retry("불러오기", function()
		return dataStore:GetAsync(getKey(player))
	end)

	-- 불러오는 동안 플레이어가 나갔으면 아무것도 하지 않는다.
	if not player.Parent then
		return
	end
	if not ok then
		onLoadFailed(player, stored)
		return
	end

	-- 처음 온 플레이어는 저장된 값이 없으므로 기본 데이터로 시작한다.
	local data = if type(stored) == "table" then stored else deepCopy(DEFAULT_DATA)
	migrate(data)
	fillDefaults(data)

	profiles[player] = data
	canSave[player] = true
	notifyLoaded(player, data)
end

local function savePlayer(player: Player)
	local data = profiles[player]
	if not data or not canSave[player] or not dataStore then
		return
	end

	-- UpdateAsync를 쓰는 이유: 같은 키에 동시에 저장이 일어나도 덮어쓰기 충돌을 Roblox가 안전하게 처리해 준다.
	local ok, err = retry("저장", function()
		return dataStore:UpdateAsync(getKey(player), function()
			return data
		end)
	end)
	if not ok then
		warn("[DataService] 저장 최종 실패:", player.Name, err)
	end
end

local function onPlayerRemoving(player: Player)
	savePlayer(player)
	profiles[player] = nil
	canSave[player] = nil
end

-- 서버가 꺼질 때 모든 플레이어를 동시에 저장하고, 다 끝날 때까지 기다린다.
local function onServerClose()
	local remaining = 0
	for _, player in Players:GetPlayers() do
		remaining += 1
		task.spawn(function()
			savePlayer(player)
			remaining -= 1
		end)
	end
	while remaining > 0 do
		task.wait()
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다. (DataService는 다른 서비스가 필요 없다)
function DataService.Init(_services) end

-- 시작 단계: DataStore 연결, 플레이어 입장/퇴장, 서버 종료, 자동 저장을 연결한다.
function DataService.Start()
	-- 게시하지 않은 게임에서는 GetDataStore 자체가 오류를 내므로 pcall로 감싼다.
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		dataStore = result
	else
		warn("[DataService] DataStore 연결 실패:", result)
	end

	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onServerClose)

	-- Studio에서는 서버가 준비되기 전에 플레이어가 먼저 들어와 있을 수 있어서 한 번 더 확인한다.
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	-- 자동 저장: 서버가 갑자기 꺼져도 잃는 진행이 최대 AUTO_SAVE_INTERVAL초가 되게 한다.
	task.spawn(function()
		while true do
			task.wait(Config.AUTO_SAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				task.spawn(savePlayer, player)
			end
		end
	end)

	print("[DataService] 준비 완료")
end

-- 플레이어 데이터를 읽는다. 아직 준비되지 않았으면 nil을 돌려준다.
-- 값을 바꿀 때는 이 테이블을 직접 고치지 말고 DataService.Update를 쓴다.
function DataService.Get(player: Player)
	return profiles[player]
end

-- 플레이어 데이터를 바꾼다. callback 안에서 data를 고치면 다음 저장 때 함께 저장된다.
-- 데이터가 준비되지 않은 플레이어면 false를 돌려준다.
function DataService.Update(player: Player, callback: (data: any) -> ()): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	callback(data)
	return true
end

-- 플레이어 데이터가 준비되면 callback(player, data)를 불러 준다.
-- 이미 준비된 플레이어에게도 바로 불러 주므로, 늦게 연결해도 빠지는 사람이 없다.
function DataService.OnPlayerLoaded(callback: (player: Player, data: any) -> ())
	table.insert(loadedCallbacks, callback)
	for player, data in profiles do
		task.spawn(callback, player, data)
	end
end

return DataService
