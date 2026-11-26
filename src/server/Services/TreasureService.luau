-- TreasureService: 보물 생성/재생성, 클릭으로 목표 정하기, 1초마다 데미지, 기여도 계산과 보상을 담당한다.
-- 의존: CoinService, PetService, Config
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = Remotes:WaitForChild("Notify")

local TreasureService = {}

local CoinService -- Init에서 연결
local PetService

local treasureFolder -- Workspace 안에 보물을 모아 두는 폴더 (Start에서 만든다)
local targets = {} -- [player] = 지금 캐고 있는 보물 파트
local contributions = {} -- [보물 파트] = { [player] = 준 데미지 합 }
local lastClickTime = {} -- [player] = 마지막으로 클릭한 시각 (연타 제한용)
local random = Random.new()

-- 구역 넓이 안의 아무 위치를 고르고, 위에서 아래로 광선을 쏴서 땅 높이를 찾는다.
local function pickSpawnPosition(zoneId: number, size: Vector3): Vector3
	local zone = Config.ZONES[zoneId]
	local half = zone.areaSize / 2
	local x, z
	-- 알 받침대 바로 옆에는 놓지 않는다. (알이 보물에 가려지지 않게) 10번 안에 못 찾으면 그냥 놓는다.
	for _ = 1, 10 do
		x = zone.areaCenter.X + random:NextNumber(-half.X, half.X)
		z = zone.areaCenter.Z + random:NextNumber(-half.Z, half.Z)
		local nearEgg = false
		for _, egg in Config.EGGS do
			if Vector2.new(egg.position.X - x, egg.position.Z - z).Magnitude < 10 then
				nearEgg = true
				break
			end
		end
		if not nearEgg then
			break
		end
	end

	-- 맵의 땅(Map/Ground)에만 광선이 맞게 한다. 나무나 다른 보물 위에 놓이지 않게 하기 위해서다.
	local params = RaycastParams.new()
	local groundFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ground")
	if groundFolder then
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { groundFolder }
	else
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { treasureFolder }
	end

	local origin = Vector3.new(x, zone.areaCenter.Y + 100, z)
	local result = Workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
	local groundY = if result then result.Position.Y else zone.areaCenter.Y
	return Vector3.new(x, groundY + size.Y / 2, z)
end

-- 보물 파트를 만든다. 체력은 속성(Attribute)에 적어 두어 클라이언트도 볼 수 있게 한다.
local function spawnTreasure(treasureId: string)
	local def = Config.TREASURES[treasureId]
	local part = Instance.new("Part")
	part.Name = treasureId
	part.Shape = if def.shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
	part.Size = def.size
	part.Color = def.color
	-- 재질 이름(예: "Ice")이 Config에 있으면 그 재질로, 없으면 매끈한 플라스틱으로 만든다.
	part.Material = (def.material and Enum.Material[def.material]) or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Position = pickSpawnPosition(def.zone, def.size)

	part:SetAttribute("TreasureId", treasureId)
	part:SetAttribute("Zone", def.zone)
	part:SetAttribute("MaxHP", def.maxHP)
	part:SetAttribute("HP", def.maxHP)

	-- ClickDetector는 서버가 "누가 클릭했는지" 직접 알 수 있게 해 준다. 그래서 Remote가 필요 없다.
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = Config.MINE_MAX_DISTANCE
	clickDetector.MouseClick:Connect(function(player)
		TreasureService.SetTarget(player, part)
	end)
	clickDetector.Parent = part

	contributions[part] = {}
	part.Parent = treasureFolder
end

-- 일반 보물 중 하나를 spawnWeight 비율대로 뽑는다.
local function pickNormalTreasure(zoneId: number): string?
	local total = 0
	for _, def in Config.TREASURES do
		if def.zone == zoneId and not def.isBig then
			total += def.spawnWeight
		end
	end
	if total <= 0 then
		return nil
	end

	local roll = random:NextNumber(0, total)
	local lastId
	for treasureId, def in Config.TREASURES do
		if def.zone == zoneId and not def.isBig then
			roll -= def.spawnWeight
			lastId = treasureId
			if roll <= 0 then
				return treasureId
			end
		end
	end
	return lastId -- 소수점 오차로 끝까지 온 경우
end

local function countNormalTreasures(zoneId: number): number
	local count = 0
	for _, part in treasureFolder:GetChildren() do
		local def = Config.TREASURES[part:GetAttribute("TreasureId")]
		if def and def.zone == zoneId and not def.isBig then
			count += 1
		end
	end
	return count
end

-- 구역의 일반 보물 수가 최대치보다 적으면 채운다.
local function fillZone(zoneId: number)
	while countNormalTreasures(zoneId) < Config.MAX_TREASURES_PER_ZONE do
		local treasureId = pickNormalTreasure(zoneId)
		if not treasureId then
			return
		end
		spawnTreasure(treasureId)
	end
end

local function spawnBigChest(zoneId: number)
	for treasureId, def in Config.TREASURES do
		if def.zone == zoneId and def.isBig then
			spawnTreasure(treasureId)
			-- 모두에게 알려서 같이 캐러 모이게 한다. (협동 유도)
			Notify:FireAllClients(`[{Config.ZONES[zoneId].name}] {def.name} 등장! 같이 캐면 보너스 +{math.floor(Config.CO_OP_BONUS * 100)}%`)
		end
	end
end

local function getDistance(player: Player, part: BasePart): number
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return math.huge
	end
	return (root.Position - part.Position).Magnitude
end

-- 보물이 깨지면 때린 사람들에게 때린 비율만큼 코인을 나눠 준다.
local function breakTreasure(part: BasePart)
	local treasureId = part:GetAttribute("TreasureId")
	local def = Config.TREASURES[treasureId]
	local damageByPlayer = contributions[part] or {}

	-- 아직 게임에 남아 있는 기여자만 센다.
	local helpers = {}
	for player, damage in damageByPlayer do
		if player.Parent and damage > 0 then
			helpers[player] = damage
		end
	end
	local helperCount = 0
	for _ in helpers do
		helperCount += 1
	end

	-- 협동 보너스: 큰 보물상자를 2명 이상이 같이 열었을 때만 준다.
	local bonus = if def.isBig and helperCount >= 2 then 1 + Config.CO_OP_BONUS else 1
	for player, damage in helpers do
		local share = damage / def.maxHP
		local reward = math.max(1, math.floor(def.reward * share * bonus))
		CoinService.AddCoins(player, reward)
		local bonusText = if bonus > 1 then " (협동 보너스!)" else ""
		Notify:FireClient(player, `+{reward} 코인{bonusText}`)
	end

	-- 이 보물을 캐던 사람들의 목표를 지운다.
	for player, target in targets do
		if target == part then
			targets[player] = nil
		end
	end
	contributions[part] = nil
	part:Destroy()

	-- 다시 생기게 한다. 큰 보물상자는 더 오래 기다린다.
	if def.isBig then
		task.delay(Config.BIG_CHEST_INTERVAL, spawnBigChest, def.zone)
	else
		task.delay(Config.TREASURE_RESPAWN_TIME, fillZone, def.zone)
	end
end

-- MINE_INTERVAL마다 한 번씩, 보물을 캐고 있는 모든 플레이어의 데미지를 준다.
local function mineTick()
	for player, part in targets do
		-- 보물이 이미 사라졌거나, 너무 멀리 갔으면 캐기를 멈춘다.
		if not part.Parent or getDistance(player, part) > Config.MINE_MAX_DISTANCE then
			targets[player] = nil
			continue
		end

		local hp = part:GetAttribute("HP")
		local damage = math.min(PetService.GetPower(player), hp) -- 남은 체력보다 많이 때린 건 기여도에 넣지 않는다.
		local damageByPlayer = contributions[part]
		damageByPlayer[player] = (damageByPlayer[player] or 0) + damage

		hp -= damage
		part:SetAttribute("HP", hp)
		if hp <= 0 then
			breakTreasure(part)
		end
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function TreasureService.Init(services)
	CoinService = services.CoinService
	PetService = services.PetService
end

-- 시작 단계: 보물을 채우고, 데미지 반복 작업을 시작한다.
function TreasureService.Start()
	treasureFolder = Instance.new("Folder")
	treasureFolder.Name = "Treasures"
	treasureFolder.Parent = Workspace

	-- 맵(MapService)이 먼저 만들어져야 보물이 땅 위에 놓인다. 최대 10초 기다린다.
	Workspace:WaitForChild("Map", 10)

	for zoneId in Config.ZONES do
		fillZone(zoneId)
		spawnBigChest(zoneId)
	end

	Players.PlayerRemoving:Connect(function(player)
		targets[player] = nil
		lastClickTime[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Config.MINE_INTERVAL)
			mineTick()
		end
	end)

	print("[TreasureService] 준비 완료")
end

-- 플레이어가 캘 보물을 정한다. (보물 클릭 시 불린다)
-- 클릭은 클라이언트가 보내는 것이므로 Remote처럼 검사한다.
function TreasureService.SetTarget(player: Player, part: BasePart)
	-- 1) 실제로 존재하는 보물인가
	if not part.Parent or part.Parent ~= treasureFolder then
		return
	end
	local def = Config.TREASURES[part:GetAttribute("TreasureId")]
	if not def or part:GetAttribute("HP") <= 0 then
		return
	end
	-- 2) 자격: 가까이 있는가 (모든 구역이 열려 있다. 대신 뒤 구역 보물은 체력이 매우 높다)
	if getDistance(player, part) > Config.MINE_MAX_DISTANCE then
		return
	end
	-- 3) 너무 자주 누르지 않는가
	local now = os.clock()
	if lastClickTime[player] and now - lastClickTime[player] < Config.REMOTE_COOLDOWN then
		return
	end
	lastClickTime[player] = now

	targets[player] = part
end

return TreasureService
