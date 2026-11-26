-- DailyRewardService: 하루에 한 번 받는 일일 보상 코인을 담당한다.
-- 의존: DataService, CoinService, Config
-- 시간은 서버 시계(os.time)로만 잰다. 클라이언트가 보낸 시간은 믿지 않는다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataChanged = Remotes:WaitForChild("DataChanged")
local ClaimDaily = Remotes:WaitForChild("ClaimDaily")

local DailyRewardService = {}

local DataService -- Init에서 연결
local CoinService

local lastRequestTime = {} -- [player] = 마지막 요청 시각 (연타 제한용)

-- 다음 보상을 받을 수 있는 시각(os.time 기준)을 클라이언트에 보낸다. 버튼의 남은 시간 표시에 쓴다.
local function sendNextTime(player: Player)
	local data = DataService.Get(player)
	if data then
		DataChanged:FireClient(player, "nextDaily", data.lastDaily + Config.DAILY_COOLDOWN)
	end
end

-- ClaimDaily 요청 처리. 돌려주는 값: (성공 여부, 받은 코인 또는 실패 이유)
local function onClaimDaily(player: Player)
	-- 인자가 없는 요청이라 타입/존재 검사는 필요 없다. 연타 제한과 자격만 본다.
	local now = os.clock()
	if lastRequestTime[player] and now - lastRequestTime[player] < Config.REMOTE_COOLDOWN then
		return false, "잠시 후에 다시 눌러 주세요."
	end
	lastRequestTime[player] = now

	local data = DataService.Get(player)
	if not data then
		return false, "데이터를 불러오는 중이에요."
	end
	local currentTime = os.time()
	if currentTime < data.lastDaily + Config.DAILY_COOLDOWN then
		return false, "아직 받을 수 없어요. 내일 다시 와 주세요!"
	end

	DataService.Update(player, function(d)
		d.lastDaily = currentTime
	end)
	CoinService.AddCoins(player, Config.DAILY_REWARD)
	sendNextTime(player)
	return true, Config.DAILY_REWARD
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function DailyRewardService.Init(services)
	DataService = services.DataService
	CoinService = services.CoinService
end

-- 시작 단계: ClaimDaily를 연결하고, 접속한 플레이어에게 다음 보상 시각을 보낸다.
function DailyRewardService.Start()
	ClaimDaily.OnServerInvoke = onClaimDaily
	DataService.OnPlayerLoaded(sendNextTime)
	Players.PlayerRemoving:Connect(function(player)
		lastRequestTime[player] = nil
	end)
	print("[DailyRewardService] 준비 완료")
end

return DailyRewardService
