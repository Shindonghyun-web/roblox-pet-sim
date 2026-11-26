-- TreasureController: 보물 위에 이름과 체력 바를 그리고, 보물이 깨지면 반짝이 효과를 낸다. (보여주기만)
-- 의존: Config
-- 체력은 서버가 보물 파트의 HP / MaxHP 속성에 적어 둔 값을 읽기만 한다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)

local TreasureController = {}

local lastPositions = {} -- [보물 파트] = 위치 (깨진 뒤 효과를 낼 자리)

-- 큰 숫자를 짧게 쓴다. 1500 → "1.5K", 2000000 → "2M", 90000000 → "90M" (체력 바 글자가 넘치지 않게)
local function shortNumber(value: number): string
	local units = { { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, unit in units do
		if value >= unit[1] then
			local short = math.floor(value / unit[1] * 10) / 10
			return `{short}{unit[2]}`
		end
	end
	return tostring(math.floor(value))
end

-- 보물 하나에 체력 바를 붙인다.
local function attachHealthBar(part: BasePart)
	local def = Config.TREASURES[part:GetAttribute("TreasureId")]
	if not def then
		return
	end
	lastPositions[part] = part.Position

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromScale(if def.isBig then 8 else 4, if def.isBig then 1.6 else 1)
	billboard.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 1.2, 0)
	billboard.MaxDistance = if def.isBig then 250 else 80
	billboard.Adornee = part

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = def.name
	nameLabel.Parent = billboard

	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromScale(0, 0.55)
	barBack.Size = UDim2.fromScale(1, 0.4)
	barBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBack.BorderSizePixel = 0
	barBack.Parent = billboard

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBack

	local hpLabel = Instance.new("TextLabel")
	hpLabel.BackgroundTransparency = 1
	hpLabel.Size = UDim2.fromScale(1, 1)
	hpLabel.Font = Enum.Font.GothamBold
	hpLabel.TextScaled = true
	hpLabel.TextColor3 = Color3.new(1, 1, 1)
	hpLabel.TextStrokeTransparency = 0.5
	hpLabel.Parent = barBack

	local function refresh()
		local hp = part:GetAttribute("HP") or 0
		local maxHP = part:GetAttribute("MaxHP") or 1
		local ratio = math.clamp(hp / maxHP, 0, 1)
		barFill.Size = UDim2.fromScale(ratio, 1)
		-- 체력이 줄수록 초록 → 빨강
		barFill.BackgroundColor3 = Color3.fromRGB(230, 70, 60):Lerp(Color3.fromRGB(90, 220, 90), ratio)
		hpLabel.Text = `{shortNumber(math.max(0, hp))} / {shortNumber(maxHP)}`
	end
	refresh()
	part:GetAttributeChangedSignal("HP"):Connect(refresh)

	billboard.Parent = part
end

-- 보물이 깨진 자리에 반짝이를 뿌린다.
local function playBreakEffect(position: Vector3, color: Color3)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = position
	holder.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 230, 120))
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Enabled = false
	emitter.Parent = holder
	emitter:Emit(25)

	Debris:AddItem(holder, 1.5) -- 1.5초 뒤 자동으로 지운다.
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function TreasureController.Init(_controllers) end

-- 시작 단계: 지금 있는 보물과 새로 생기는 보물에 체력 바를 붙인다.
function TreasureController.Start()
	local folder = Workspace:WaitForChild("Treasures")

	for _, part in folder:GetChildren() do
		attachHealthBar(part)
	end
	folder.ChildAdded:Connect(function(part)
		-- 속성이 함께 도착하도록 한 프레임 기다린다.
		task.defer(attachHealthBar, part)
	end)
	folder.ChildRemoved:Connect(function(part)
		local position = lastPositions[part]
		lastPositions[part] = nil
		if position and part:IsA("BasePart") then
			playBreakEffect(position, part.Color)
		end
	end)

	print("[TreasureController] 준비 완료")
end

return TreasureController
