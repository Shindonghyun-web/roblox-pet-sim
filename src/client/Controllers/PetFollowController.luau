-- PetFollowController: 장착한 펫 모델을 만들고 주인을 따라다니게 한다. (보기만 하는 움직임)
-- 의존: Config
-- 서버가 각 플레이어의 "EquippedPets" 속성(예: "Dog,Cat")에 장착한 펫 종류를 적어 두면,
-- 모든 플레이어의 화면에서 그걸 읽어 펫 모델을 만들고 움직인다. 서버는 펫 모델을 움직이지 않는다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local PetFollowController = {}

local petFolder: Folder -- 내 화면에만 있는 펫 모델들을 모아 두는 폴더
local followers = {} -- [player] = { key = "Dog,Cat", models = { Model, ... } }

-- 펫 장식 모양. 몸통 크기(S)에 대한 비율로 적는다. (위치 x, y, z / 크기 x, y, z / 기울기 z도)
-- 몸통의 앞쪽은 -Z 방향이다.
local STYLE_PARTS = {
	ears = {
		{ pos = { 0.3, 0.45, 0 }, size = { 0.3, 0.35, 0.15 }, tilt = -15 },
		{ pos = { -0.3, 0.45, 0 }, size = { 0.3, 0.35, 0.15 }, tilt = 15 },
	},
	longEars = {
		{ pos = { 0.2, 0.75, 0 }, size = { 0.22, 0.8, 0.12 }, tilt = -8 },
		{ pos = { -0.2, 0.75, 0 }, size = { 0.22, 0.8, 0.12 }, tilt = 8 },
	},
	wings = {
		{ pos = { 0.65, 0.15, 0.1 }, size = { 0.7, 0.1, 0.45 }, tilt = 20 },
		{ pos = { -0.65, 0.15, 0.1 }, size = { 0.7, 0.1, 0.45 }, tilt = -20 },
	},
	horn = {
		{ pos = { 0, 0.65, -0.2 }, size = { 0.14, 0.55, 0.14 }, tilt = 0, neon = true },
	},
	beak = {
		{ pos = { 0, -0.05, -0.52 }, size = { 0.25, 0.15, 0.25 }, tilt = 0 },
	},
	antlers = {
		{ pos = { 0.25, 0.7, 0 }, size = { 0.1, 0.6, 0.1 }, tilt = -25 },
		{ pos = { -0.25, 0.7, 0 }, size = { 0.1, 0.6, 0.1 }, tilt = 25 },
		{ pos = { 0.42, 0.85, 0 }, size = { 0.08, 0.3, 0.08 }, tilt = -60 },
		{ pos = { -0.42, 0.85, 0 }, size = { 0.08, 0.3, 0.08 }, tilt = 60 },
	},
	tusks = {
		{ pos = { 0.12, -0.3, -0.45 }, size = { 0.08, 0.3, 0.08 }, tilt = 0 },
		{ pos = { -0.12, -0.3, -0.45 }, size = { 0.08, 0.3, 0.08 }, tilt = 0 },
	},
	hump = {
		{ pos = { 0, 0.45, 0.2 }, size = { 0.55, 0.55, 0.55 }, tilt = 0, ball = true },
	},
	spikes = {
		{ pos = { 0, 0.5, -0.15 }, size = { 0.12, 0.35, 0.22 }, tilt = 0 },
		{ pos = { 0, 0.47, 0.15 }, size = { 0.12, 0.35, 0.22 }, tilt = 0 },
		{ pos = { 0, 0.38, 0.4 }, size = { 0.12, 0.3, 0.2 }, tilt = 0 },
	},
	flame = {
		{ pos = { 0, 0.62, 0 }, size = { 0.45, 0.45, 0.45 }, tilt = 0, ball = true, neon = true },
	},
	cherry = {
		{ pos = { 0, 0.62, 0 }, size = { 0.35, 0.35, 0.35 }, tilt = 0, ball = true },
		{ pos = { 0.05, 0.85, 0 }, size = { 0.05, 0.22, 0.05 }, tilt = -20 },
	},
}

local function makeDetail(model: Model, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?)
	local part = Instance.new("Part")
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = offset
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false -- 플레이어 발에 걸리지 않게
	part.CanQuery = false -- 클릭에 맞지 않게 (보물 클릭을 가리지 않도록)
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = model
	return part
end

-- 펫 모델 하나를 만든다. 몸통(공) + 눈 + 종류별 장식
local function makePetModel(petId: string): Model
	local def = Config.PETS[petId]
	local s = Config.PET_SIZE
	local model = Instance.new("Model")
	model.Name = petId

	local bodyColor = if def then def.color else Color3.new(1, 1, 1)
	local body = makeDetail(model, Vector3.one * s, CFrame.new(), bodyColor, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	model.PrimaryPart = body

	for _, side in { 1, -1 } do
		makeDetail(model, Vector3.one * s * 0.22, CFrame.new(side * s * 0.22, s * 0.12, -s * 0.42), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end

	local accent = if def then def.accent else Color3.new(1, 1, 1)
	for _, info in (def and STYLE_PARTS[def.style]) or {} do
		local offset = CFrame.new(info.pos[1] * s, info.pos[2] * s, info.pos[3] * s) * CFrame.Angles(0, 0, math.rad(info.tilt))
		local size = Vector3.new(info.size[1] * s, info.size[2] * s, info.size[3] * s)
		makeDetail(model, size, offset, accent, if info.neon then Enum.Material.Neon else Enum.Material.SmoothPlastic, if info.ball then Enum.PartType.Ball else nil)
	end

	-- 레전더리 펫은 반짝이를 뿌린다.
	if def and def.rarity == "Legendary" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Config.RARITIES.Legendary.color
		sparkles.Parent = body
	end

	model.Parent = petFolder
	return model
end

local function clearPets(owner: Player)
	local entry = followers[owner]
	if entry then
		for _, model in entry.models do
			model:Destroy()
		end
		followers[owner] = nil
	end
end

-- 속성 값이 바뀌었으면 펫 모델을 새로 만든다.
local function syncPets(owner: Player)
	local key = owner:GetAttribute("EquippedPets") or ""
	local entry = followers[owner]
	if entry and entry.key == key then
		return
	end
	clearPets(owner)
	if key == "" then
		return
	end
	local models = {}
	for _, petId in string.split(key, ",") do
		table.insert(models, makePetModel(petId))
	end
	followers[owner] = { key = key, models = models }
end

-- 매 프레임 펫을 주인 뒤쪽 자리로 부드럽게 옮긴다.
local function onHeartbeat(deltaTime: number)
	local now = os.clock()
	-- 프레임 속도가 달라도 같은 빠르기로 따라오게 하는 계산
	local alpha = 1 - math.exp(-Config.PET_FOLLOW_SPEED * deltaTime)

	for _, owner in Players:GetPlayers() do
		syncPets(owner)
		local entry = followers[owner]
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if entry and root then
			local count = #entry.models
			for index, model in entry.models do
				-- 캐릭터는 앞쪽이 -Z 방향이라서, +Z 쪽이 등 뒤다.
				local sideOffset = (index - (count + 1) / 2) * Config.PET_SPACING
				local bob = math.sin(now * 3 + index) * Config.PET_HOVER_HEIGHT * 0.5
				local goal = root.CFrame * CFrame.new(sideOffset, -1 + bob, Config.PET_FOLLOW_DISTANCE)
				local current = model:GetPivot()
				if (current.Position - goal.Position).Magnitude > 50 then
					model:PivotTo(goal) -- 막 생겼거나 주인이 순간이동했으면 바로 옆으로 옮긴다.
				else
					model:PivotTo(current:Lerp(goal, alpha))
				end
			end
		end
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function PetFollowController.Init(_controllers) end

-- 시작 단계: 펫 폴더를 만들고 매 프레임 움직이기 시작한다.
function PetFollowController.Start()
	petFolder = Instance.new("Folder")
	petFolder.Name = "LocalPets"
	petFolder.Parent = Workspace

	Players.PlayerRemoving:Connect(clearPets)
	RunService.Heartbeat:Connect(onHeartbeat)

	print("[PetFollowController] 준비 완료")
end

return PetFollowController
