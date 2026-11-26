-- EggService: 알 받침대를 만들고, 알 구매(1개 / 여러 개)와 확률 뽑기를 담당한다.
-- 의존: DataService, CoinService, PetService, Config
-- 뽑은 펫을 인벤토리에 넣는 일은 PetService.GivePets에 부탁한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyEgg = Remotes:WaitForChild("BuyEgg")

local EggService = {}

local DataService -- Init에서 연결
local CoinService
local PetService

local eggParts = {} -- [eggId] = 알 파트 (거리 검사용)
local lastRequestTime = {} -- [player] = 마지막 요청 시각 (연타 제한용)
local random = Random.new()

local function getDistance(player: Player, part: BasePart): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return math.huge
	end
	return (root.Position - part.Position).Magnitude
end

-- 알에 적힌 확률(%)대로 펫 하나를 뽑는다. 확률 계산은 반드시 서버에서 한다.
local function rollPet(egg): string
	local roll = random:NextNumber(0, 100)
	for _, entry in egg.pets do
		roll -= entry.chance
		if roll <= 0 then
			return entry.id
		end
	end
	return egg.pets[1].id -- 확률 합이 100보다 작게 적혀 있을 때를 대비
end

local function makePrompt(part: BasePart, eggId: string, amount: number, key: Enum.KeyCode, egg)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = `Buy{amount}`
	prompt.ActionText = if amount == 1 then "알 1개 사기" else `알 {amount}개 사기`
	prompt.ObjectText = `{egg.name} ({egg.price * amount} 코인)`
	prompt.KeyboardKeyCode = key
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.EGG_MAX_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = if amount == 1 then Vector2.new(0, 0) else Vector2.new(0, 70) -- 두 버튼이 겹치지 않게
	-- 클라이언트(EggController)가 어떤 알을 몇 개 살지 알 수 있게 적어 둔다.
	prompt:SetAttribute("EggId", eggId)
	prompt:SetAttribute("Amount", amount)
	prompt.Parent = part
end

-- 알 받침대를 만든다. 가까이 가면 "알 1개 사기"(E), "알 3개 사기"(R) 버튼이 뜬다.
local function createEggStands()
	local folder = Instance.new("Folder")
	folder.Name = "Eggs"
	folder.Parent = Workspace

	for eggId, egg in Config.EGGS do
		local part = Instance.new("Part")
		part.Name = eggId
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(5, 6, 5)
		part.Color = egg.color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.Position = egg.position + Vector3.new(0, 3, 0)

		makePrompt(part, eggId, 1, Enum.KeyCode.E, egg)
		makePrompt(part, eggId, Config.EGG_MULTI_AMOUNT, Enum.KeyCode.R, egg)

		part.Parent = folder
		eggParts[eggId] = part
	end
end

-- BuyEgg 요청 처리. 돌려주는 값: (성공 여부, 뽑은 펫 ID 목록 또는 실패 이유)
local function onBuyEgg(player: Player, eggId, amount)
	-- 1) 타입
	if typeof(eggId) ~= "string" or typeof(amount) ~= "number" then
		return false, "잘못된 요청이에요."
	end
	-- 2) 존재: 있는 알인지, 정해진 개수(1개 또는 여러 개)인지
	local egg = Config.EGGS[eggId]
	if not egg then
		return false, "없는 알이에요."
	end
	if amount ~= 1 and amount ~= Config.EGG_MULTI_AMOUNT then
		return false, "잘못된 개수예요."
	end
	-- 4) 연타 제한
	local now = os.clock()
	if lastRequestTime[player] and now - lastRequestTime[player] < Config.REMOTE_COOLDOWN then
		return false, "잠시 후에 다시 눌러 주세요."
	end
	lastRequestTime[player] = now
	-- 3) 자격: 데이터, 거리, 인벤토리 자리, 코인 (모든 구역이 열려 있어서 구역 검사는 하지 않는다)
	local data = DataService.Get(player)
	if not data then
		return false, "데이터를 불러오는 중이에요."
	end
	if getDistance(player, eggParts[eggId]) > Config.EGG_MAX_DISTANCE + 5 then -- 움직임 지연을 감안해 5스터드 여유
		return false, "알에 더 가까이 가 주세요."
	end
	if #data.pets + amount > Config.MAX_PETS then
		return false, `펫 자리가 모자라요. (최대 {Config.MAX_PETS}마리) 펫 창에서 지워 주세요.`
	end
	if not CoinService.SpendCoins(player, egg.price * amount) then
		return false, "코인이 부족해요."
	end

	local petIds = {}
	for _ = 1, amount do
		table.insert(petIds, rollPet(egg))
	end
	PetService.GivePets(player, petIds)
	return true, petIds
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function EggService.Init(services)
	DataService = services.DataService
	CoinService = services.CoinService
	PetService = services.PetService
end

-- 시작 단계: 알 받침대를 만들고 BuyEgg를 연결한다.
function EggService.Start()
	createEggStands()
	BuyEgg.OnServerInvoke = onBuyEgg
	Players.PlayerRemoving:Connect(function(player)
		lastRequestTime[player] = nil
	end)
	print("[EggService] 준비 완료")
end

return EggService
