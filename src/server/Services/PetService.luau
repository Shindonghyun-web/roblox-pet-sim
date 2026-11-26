-- PetService: 펫 인벤토리(받기, 장착, 해제, 지우기)와 플레이어 파워 계산을 담당한다.
-- 의존: DataService, Config
-- 알 구매와 확률 뽑기는 EggService가 하고, 뽑은 펫은 PetService.GivePets로 받는다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataChanged = Remotes:WaitForChild("DataChanged")
local EquipPet = Remotes:WaitForChild("EquipPet")
local UnequipPet = Remotes:WaitForChild("UnequipPet")
local DeletePet = Remotes:WaitForChild("DeletePet")

local PetService = {}

local DataService -- Init에서 연결

local lastRequestTime = {} -- [player] = 마지막 요청 시각 (연타 제한용)

-- 연타 제한: 너무 자주 보내면 false
local function passCooldown(player: Player): boolean
	local now = os.clock()
	local last = lastRequestTime[player]
	if last and now - last < Config.REMOTE_COOLDOWN then
		return false
	end
	lastRequestTime[player] = now
	return true
end

local function findPet(data, petUid: string)
	for index, pet in data.pets do
		if pet.uid == petUid then
			return pet, index
		end
	end
	return nil, nil
end

-- 장착한 펫 종류를 플레이어 속성에 적어 둔다. 다른 플레이어 화면에서도 펫이 따라다니게 하기 위해서다.
local function refreshPets(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local petIds = {}
	for _, petUid in data.equipped do
		local pet = findPet(data, petUid)
		if pet then
			table.insert(petIds, pet.id)
		end
	end
	player:SetAttribute("EquippedPets", table.concat(petIds, ","))
	DataChanged:FireClient(player, "pets", data.pets)
	DataChanged:FireClient(player, "equipped", data.equipped)
end

-- EquipPet 요청 처리. 돌려주는 값: (성공 여부, 실패 이유)
local function onEquipPet(player: Player, petUid)
	if typeof(petUid) ~= "string" then
		return false, "잘못된 요청이에요."
	end
	if not passCooldown(player) then
		return false, "잠시 후에 다시 눌러 주세요."
	end
	local data = DataService.Get(player)
	if not data or not findPet(data, petUid) then
		return false, "없는 펫이에요."
	end
	if table.find(data.equipped, petUid) then
		return false, "이미 장착한 펫이에요."
	end
	if #data.equipped >= Config.MAX_EQUIPPED then
		return false, `펫은 최대 {Config.MAX_EQUIPPED}마리까지 장착할 수 있어요.`
	end

	DataService.Update(player, function(d)
		table.insert(d.equipped, petUid)
	end)
	refreshPets(player)
	return true
end

-- UnequipPet 요청 처리
local function onUnequipPet(player: Player, petUid)
	if typeof(petUid) ~= "string" then
		return false, "잘못된 요청이에요."
	end
	if not passCooldown(player) then
		return false, "잠시 후에 다시 눌러 주세요."
	end
	local data = DataService.Get(player)
	local index = data and table.find(data.equipped, petUid)
	if not index then
		return false, "장착하지 않은 펫이에요."
	end

	DataService.Update(player, function(d)
		table.remove(d.equipped, index)
	end)
	refreshPets(player)
	return true
end

-- DeletePet 요청 처리. 장착 중인 펫은 실수로 지우지 않게 먼저 해제해야 한다.
local function onDeletePet(player: Player, petUid)
	if typeof(petUid) ~= "string" then
		return false, "잘못된 요청이에요."
	end
	if not passCooldown(player) then
		return false, "잠시 후에 다시 눌러 주세요."
	end
	local data = DataService.Get(player)
	if not data or not findPet(data, petUid) then
		return false, "없는 펫이에요."
	end
	if table.find(data.equipped, petUid) then
		return false, "장착 중인 펫은 지울 수 없어요. 먼저 해제해 주세요."
	end

	DataService.Update(player, function(d)
		local _, index = findPet(d, petUid)
		if index then
			table.remove(d.pets, index)
		end
	end)
	refreshPets(player)
	return true
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function PetService.Init(services)
	DataService = services.DataService
end

-- 시작 단계: Remote를 연결하고, 접속한 플레이어에게 펫 목록을 보낸다.
function PetService.Start()
	EquipPet.OnServerInvoke = onEquipPet
	UnequipPet.OnServerInvoke = onUnequipPet
	DeletePet.OnServerInvoke = onDeletePet

	DataService.OnPlayerLoaded(function(player)
		refreshPets(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequestTime[player] = nil
	end)

	print("[PetService] 준비 완료")
end

-- 펫을 인벤토리에 넣는다. (EggService가 알을 판 뒤 부른다) 인벤토리 자리 검사는 부르는 쪽에서 한다.
function PetService.GivePets(player: Player, petIds: { string }): boolean
	local ok = DataService.Update(player, function(d)
		for _, petId in petIds do
			if Config.PETS[petId] then
				table.insert(d.pets, { uid = tostring(d.nextPetUid), id = petId })
				d.nextPetUid += 1
			end
		end
	end)
	if ok then
		refreshPets(player)
	end
	return ok
end

-- 플레이어가 보물에 1번에 주는 데미지(파워)를 돌려준다.
-- 장착한 펫 파워의 합이고, 펫이 없으면 기본 파워다.
function PetService.GetPower(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return Config.BASE_POWER
	end
	local total = 0
	for _, petUid in data.equipped do
		local pet = findPet(data, petUid)
		local def = pet and Config.PETS[pet.id]
		if def then
			total += def.power
		end
	end
	return if total > 0 then total else Config.BASE_POWER
end

return PetService
