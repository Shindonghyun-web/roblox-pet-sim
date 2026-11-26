-- EggController: 알 앞의 "알 사기" 버튼을 누르면 서버에 구매를 요청하고, 결과로 부화 연출을 보여 준다.
-- 의존: HUDController, Config, Remotes(BuyEgg)
-- 어떤 펫이 나올지는 서버가 정한다. 여기서는 서버가 알려 준 결과를 "보여주기만" 한다.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyEgg = Remotes:WaitForChild("BuyEgg")

local player = Players.LocalPlayer

local EggController = {}

local HUDController -- Init에서 연결

local hatchGui: ScreenGui
local eggRow: Frame -- 알(원)들이 가로로 놓이는 줄
local resultLabel: TextLabel
local busy = false -- 부화 연출 중에는 새 요청을 보내지 않는다.

local function buildGui()
	hatchGui = Instance.new("ScreenGui")
	hatchGui.Name = "HatchGui"
	hatchGui.ResetOnSpawn = false
	hatchGui.Enabled = false
	hatchGui.DisplayOrder = 10 -- 다른 화면보다 위에 보이게 한다.
	hatchGui.Parent = player:WaitForChild("PlayerGui")

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.Parent = hatchGui

	eggRow = Instance.new("Frame")
	eggRow.AnchorPoint = Vector2.new(0.5, 0.5)
	eggRow.Position = UDim2.fromScale(0.5, 0.42)
	eggRow.Size = UDim2.fromScale(0.8, 0.3)
	eggRow.BackgroundTransparency = 1
	eggRow.Parent = hatchGui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.03, 0)
	layout.Parent = eggRow

	resultLabel = Instance.new("TextLabel")
	resultLabel.AnchorPoint = Vector2.new(0.5, 0)
	resultLabel.Position = UDim2.fromScale(0.5, 0.62)
	resultLabel.Size = UDim2.fromScale(0.8, 0.18)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Font = Enum.Font.GothamBlack
	resultLabel.TextScaled = true
	resultLabel.RichText = true -- 펫마다 등급 색을 다르게 칠하기 위해
	resultLabel.TextStrokeTransparency = 0.3
	resultLabel.TextColor3 = Color3.new(1, 1, 1)
	resultLabel.Parent = hatchGui
end

local function makeCircle(color: Color3): Frame
	local circle = Instance.new("Frame")
	circle.Size = UDim2.fromScale(0.25, 1)
	circle.BackgroundColor3 = color
	circle.Parent = eggRow
	local ratio = Instance.new("UIAspectRatioConstraint") -- 화면 비율이 달라도 동그랗게 유지
	ratio.Parent = circle
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = circle
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = circle
	return circle
end

local function toHex(color: Color3): string
	return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

-- 알들이 흔들리다가 펫으로 바뀌는 연출
local function playHatch(eggId: string, petIds: { string })
	local egg = Config.EGGS[eggId]
	for _, child in eggRow:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local circles = {}
	for _ = 1, #petIds do
		table.insert(circles, makeCircle(egg.color))
	end

	hatchGui.Enabled = true
	resultLabel.Text = "두근두근..."

	-- 흔들기: 좌우로 기울이기를 반복한다. 끝으로 갈수록 빨라진다.
	local shakeEnd = os.clock() + Config.HATCH_ANIMATION_TIME
	local angle = 15
	while os.clock() < shakeEnd do
		local remaining = shakeEnd - os.clock()
		local speed = math.clamp(remaining / Config.HATCH_ANIMATION_TIME, 0.25, 1) * 0.15
		for _, circle in circles do
			circle.Rotation = angle
		end
		task.wait(speed)
		angle = -angle
	end

	-- 펫 공개
	local lines = {}
	for index, petId in petIds do
		local pet = Config.PETS[petId]
		local rarity = Config.RARITIES[pet.rarity]
		local circle = circles[index]
		circle.Rotation = 0
		circle.BackgroundColor3 = pet.color
		circle.Size = UDim2.fromScale(0.1, 0.4)
		TweenService:Create(circle, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = UDim2.fromScale(0.25, 1) }):Play()
		table.insert(lines, `<font color="{toHex(rarity.color)}">[{rarity.name}] {pet.name} (파워 {pet.power})</font>`)
	end
	resultLabel.Text = table.concat(lines, "\n")

	task.wait(1.8 + 0.4 * (#petIds - 1))
	hatchGui.Enabled = false
end

local function onPromptTriggered(prompt: ProximityPrompt)
	local eggId = prompt:GetAttribute("EggId")
	local amount = prompt:GetAttribute("Amount")
	if typeof(eggId) ~= "string" or typeof(amount) ~= "number" or busy then
		return
	end
	busy = true

	-- InvokeServer는 서버 문제로 오류가 날 수 있어서 pcall로 감싼다.
	local callOk, ok, result = pcall(function()
		return BuyEgg:InvokeServer(eggId, amount)
	end)
	if not callOk then
		HUDController.ShowMessage("요청에 실패했어요. 다시 시도해 주세요.", Color3.fromRGB(255, 120, 120))
	elseif ok and typeof(result) == "table" then
		playHatch(eggId, result)
	else
		HUDController.ShowMessage(if typeof(result) == "string" then result else "살 수 없어요.", Color3.fromRGB(255, 120, 120))
	end

	busy = false
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function EggController.Init(controllers)
	HUDController = controllers.HUDController
end

-- 시작 단계: 부화 화면을 만들고 "알 사기" 버튼을 연결한다.
function EggController.Start()
	buildGui()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
	print("[EggController] 준비 완료")
end

return EggController
