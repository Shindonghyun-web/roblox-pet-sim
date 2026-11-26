-- MapService: 맵(구역 땅, 다리, 시작 광장, 입구 아치, 구역별 장식)을 코드로 만들고 시작 위치를 정한다.
-- 땅 바깥은 아무것도 없는 낭떠러지라서, 밖으로 나가면 떨어진다.
-- 의존: Config, MapDecor, MapThemes (ServerStorage/ServerOnly)
-- 만든 것은 Workspace/Map 안에 들어간다. Ground(밟는 땅)와 Decor(장식)로 나눈 이유:
-- 보물은 Ground 위에만 놓이게 해야 나무 꼭대기에 보물이 생기지 않기 때문이다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local serverOnly = ServerStorage:WaitForChild("ServerOnly")
local MapDecor = require(serverOnly:WaitForChild("MapDecor"))
local MapThemes = require(serverOnly:WaitForChild("MapThemes"))

local MapService = {}

local GROUND_TOP = 0.5 -- 모든 땅의 윗면 높이 (스터드). 땅 두께 1, 가운데 높이 0.
local PATH_WIDTH = 16 -- 구역 사이 다리 너비 (스터드)

local groundFolder: Folder
local random: Random
local blockers = {} -- 큰 장식을 놓으면 안 되는 자리 목록 { position, radius }

local function makeGround(name: string, center: Vector3, sizeX: number, sizeZ: number, color: Color3, material: Enum.Material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = Vector3.new(sizeX, 1, sizeZ)
	part.Position = Vector3.new(center.X, GROUND_TOP - 0.5, center.Z)
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = groundFolder
	return part
end

local function groundHalf(zone): Vector3
	return zone.areaSize / 2 + Vector3.new(zone.groundBorder, 0, zone.groundBorder)
end

local function isBlocked(position: Vector3): boolean
	for _, blocker in blockers do
		local flat = Vector3.new(position.X - blocker.position.X, 0, position.Z - blocker.position.Z)
		if flat.Magnitude < blocker.radius then
			return true
		end
	end
	return false
end

-- 땅 안의 아무 자리. ringOnly면 보물 땅(area) 바깥 테두리에서만 고른다.
local function randomSpot(zone, ringOnly: boolean): Vector3?
	local outer = groundHalf(zone)
	local inner = zone.areaSize / 2 + Vector3.new(3, 0, 3)
	for _ = 1, 30 do
		local x = random:NextNumber(-outer.X + 2, outer.X - 2)
		local z = random:NextNumber(-outer.Z + 2, outer.Z - 2)
		local insideArea = math.abs(x) < inner.X and math.abs(z) < inner.Z
		local pos = Vector3.new(zone.areaCenter.X + x, GROUND_TOP, zone.areaCenter.Z + z)
		if not (ringOnly and insideArea) and not isBlocked(pos) then
			return pos
		end
	end
	return nil
end

-- 구역 컨셉(MapThemes)대로 상징물 → 큰 장식 → 작은 장식 순서로 놓는다.
local function decorateZone(zone)
	local theme = MapThemes[zone.theme]
	if not theme then
		warn("[MapService] 모르는 테마:", zone.theme)
		return
	end
	for _ = 1, theme.landmarkCount or 0 do
		local pos = randomSpot(zone, true)
		if pos then
			theme.landmark(pos)
			table.insert(blockers, { position = pos, radius = 14 })
		end
	end
	for _ = 1, theme.largeCount do
		local pos = randomSpot(zone, true)
		if pos then
			theme.large(pos)
			table.insert(blockers, { position = pos, radius = 4 })
		end
	end
	-- 작은 장식은 밟고 지나갈 수 있어서 보물 땅 안에도 흩뿌린다. (막는 자리 검사도 하지 않는다)
	local outer = groundHalf(zone)
	for _ = 1, theme.smallCount do
		theme.small(Vector3.new(zone.areaCenter.X + random:NextNumber(-outer.X, outer.X), GROUND_TOP, zone.areaCenter.Z + random:NextNumber(-outer.Z, outer.Z)))
	end
end

-- 앞 구역에서 이 구역까지 다리를 놓고, 이 구역 입구에 아치를 세운다.
-- 구역들은 가로 또는 세로로 나란히 있다고 가정한다. (Config의 areaCenter 배치)
local function connectZones(fromZone, toZone)
	local offset = toZone.areaCenter - fromZone.areaCenter
	local dir = if math.abs(offset.X) > math.abs(offset.Z) then Vector3.new(math.sign(offset.X), 0, 0) else Vector3.new(0, 0, math.sign(offset.Z))
	local alongX = dir.X ~= 0
	local fromHalf, toHalf = groundHalf(fromZone), groundHalf(toZone)
	local startPos = fromZone.areaCenter + dir * (if alongX then fromHalf.X else fromHalf.Z)
	local endPos = toZone.areaCenter - dir * (if alongX then toHalf.X else toHalf.Z)
	local length = (endPos - startPos).Magnitude
	if length > 0 then
		local mid = (startPos + endPos) / 2
		makeGround("Bridge", mid, if alongX then length else PATH_WIDTH, if alongX then PATH_WIDTH else length, Color3.fromRGB(170, 130, 85), Enum.Material.WoodPlanks)
	end

	MapDecor.arch(Vector3.new(endPos.X, GROUND_TOP, endPos.Z), dir, `{toZone.name}\n추천 파워 {toZone.recommendedPower}+`, toZone.accent)

	-- 양쪽 구역 안에서 다리 줄을 따라 큰 장식이 길을 막지 않게 한다.
	local fromAreaEdge = fromZone.areaCenter + dir * (if alongX then fromZone.areaSize.X / 2 else fromZone.areaSize.Z / 2)
	local toAreaEdge = toZone.areaCenter - dir * (if alongX then toZone.areaSize.X / 2 else toZone.areaSize.Z / 2)
	for step = 0, 12 do
		table.insert(blockers, { position = fromAreaEdge:Lerp(toAreaEdge, step / 12), radius = 13 })
	end
end

-- 원래 맵에 있던 시작 위치(SpawnLocation)는 끄고 숨긴다. (Studio에서 지워도 된다)
local function hideOtherSpawns(mySpawn: SpawnLocation)
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") and descendant ~= mySpawn then
			descendant.Enabled = false
			descendant.Transparency = 1
			descendant.CanCollide = false
			for _, child in descendant:GetChildren() do
				if child:IsA("Decal") then
					child.Transparency = 1
				end
			end
		end
	end
end

-- Studio에 원래 있던 회색 바닥(Baseplate)을 실행 중에만 안 보이고 통과되게 만든다.
-- 떨어진 캐릭터는 로블록스가 알아서 없애고, 시작 광장에서 다시 태어난다. (Studio 탐색기에서 Baseplate를 지워도 된다)
local function hideBaseplate()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child.Transparency = 1
			end
		end
	end
end

-- 납작한 원판 땅 (광장, 알 받침대)
local function makeDisc(name: string, center: Vector3, radius: number, thickness: number, color: Color3, material: Enum.Material)
	local disc = makeGround(name, center, 1, 1, color, material)
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(thickness, radius * 2, radius * 2)
	disc.CFrame = CFrame.new(center.X, GROUND_TOP + thickness / 4, center.Z) * CFrame.Angles(0, 0, math.rad(90))
end

local function buildPlaza(mapFolder: Folder)
	local center = Config.SPAWN_POSITION
	local radius = Config.PLAZA_RADIUS
	makeDisc("Plaza", center, radius, 0.2, Color3.fromRGB(205, 185, 150), Enum.Material.Cobblestone)

	for i = 0, 5 do
		local angle = math.rad(i * 60 + 30)
		MapDecor.lampPost(Vector3.new(center.X + math.cos(angle) * (radius + 2), GROUND_TOP, center.Z + math.sin(angle) * (radius + 2)))
	end
	MapDecor.sign(Vector3.new(center.X, GROUND_TOP, center.Z + radius - 3), Vector3.new(center.X, 0, center.Z - 50), "펫 보물 탐험대", 16)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StartSpawn"
	spawn.Size = Vector3.new(8, 0.4, 8)
	-- 180도 돌려서, 시작할 때 보물 땅(북쪽, +Z) 쪽을 바라보게 한다.
	spawn.CFrame = CFrame.new(center.X, GROUND_TOP + 0.3, center.Z) * CFrame.Angles(0, math.pi, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0 -- 시작할 때 보호막(포스필드) 없음
	spawn.Color = Color3.fromRGB(255, 205, 80)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = mapFolder
	hideOtherSpawns(spawn)
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function MapService.Init(_services) end

-- 시작 단계: 맵 전체를 만든다. 보물/알이 놓이기 전에 끝나도록 기다리는 일(yield) 없이 한 번에 만든다.
function MapService.Start()
	random = Random.new(Config.MAP_SEED)

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = mapFolder
	local decorFolder = Instance.new("Folder")
	decorFolder.Name = "Decor"
	decorFolder.Parent = mapFolder
	MapDecor.Setup(decorFolder, random)

	-- 장식을 피해야 할 자리: 광장, 순위판, 알. 알 자리에는 하얀 받침대를 깐다.
	table.insert(blockers, { position = Config.SPAWN_POSITION, radius = Config.PLAZA_RADIUS + 6 })
	table.insert(blockers, { position = Config.LEADERBOARD_POSITION, radius = 10 })
	for _, egg in Config.EGGS do
		table.insert(blockers, { position = egg.position, radius = 9 })
		makeDisc("EggStand", egg.position, 4.5, 0.4, Color3.fromRGB(240, 240, 240), Enum.Material.Marble)
	end

	-- 땅 바깥은 낭떠러지다. 원래 회색 바닥(Baseplate)을 숨겨서, 땅이나 다리 밖으로 나가면 떨어지게 한다.
	hideBaseplate()

	-- 구역 땅과 다리 (1 → 2 → 3 ... 순서대로 잇는다)
	for zoneId, zone in Config.ZONES do
		local half = groundHalf(zone)
		makeGround(`Zone{zoneId}Ground`, zone.areaCenter, half.X * 2, half.Z * 2, zone.groundColor, Enum.Material[zone.groundMaterial] or Enum.Material.Grass)
		local previous = Config.ZONES[zoneId - 1]
		if previous then
			connectZones(previous, zone)
		end
	end

	mapFolder.Parent = Workspace
	buildPlaza(mapFolder)
	for _, zone in Config.ZONES do
		decorateZone(zone)
	end

	print("[MapService] 준비 완료")
end

return MapService
