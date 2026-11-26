-- HUDController: 화면 위 코인 표시, 알림 문구, 첫 플레이 안내를 담당한다. (보여주기만 하고 값은 바꾸지 않는다)
-- 의존: DataController, Config, Remotes(Notify)
-- 화면(HUDGui)은 코드로 만든다. (Studio에서 따로 만들 필요 없음)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify = Remotes:WaitForChild("Notify")

local player = Players.LocalPlayer

local HUDController = {}

local DataController -- Init에서 연결

local coinLabel: TextLabel
local messageList: Frame
local hintLabel: TextLabel

-- 1234567 → "1,234,567" (큰 숫자를 읽기 쉽게)
local function formatNumber(value: number): string
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUDGui"
	gui.ResetOnSpawn = false -- 캐릭터가 죽어도 화면이 다시 만들어지지 않게 한다.
	gui.IgnoreGuiInset = false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- 코인 표시 (화면 위 가운데)
	local coinFrame = Instance.new("Frame")
	coinFrame.Name = "Coins"
	coinFrame.AnchorPoint = Vector2.new(0.5, 0)
	coinFrame.Position = UDim2.fromScale(0.5, 0.02)
	coinFrame.Size = UDim2.fromScale(0.28, 0.08)
	coinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	coinFrame.BackgroundTransparency = 0.25
	coinFrame.Parent = gui
	addCorner(coinFrame, 12)
	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MaxSize = Vector2.new(320, 60)
	sizeLimit.MinSize = Vector2.new(160, 40)
	sizeLimit.Parent = coinFrame

	coinLabel = Instance.new("TextLabel")
	coinLabel.BackgroundTransparency = 1
	coinLabel.Size = UDim2.fromScale(1, 1)
	coinLabel.Font = Enum.Font.GothamBold
	coinLabel.TextScaled = true
	coinLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
	coinLabel.Text = "코인 0"
	coinLabel.Parent = coinFrame
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.Parent = coinLabel

	-- 알림 문구가 쌓이는 곳 (코인 아래)
	messageList = Instance.new("Frame")
	messageList.Name = "Messages"
	messageList.BackgroundTransparency = 1
	messageList.AnchorPoint = Vector2.new(0.5, 0)
	messageList.Position = UDim2.fromScale(0.5, 0.12)
	messageList.Size = UDim2.fromScale(0.6, 0.3)
	messageList.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = messageList

	-- 첫 플레이 안내 (화면 아래 가운데)
	hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.fromScale(0.5, 0.95)
	hintLabel.Size = UDim2.fromScale(0.7, 0.06)
	hintLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	hintLabel.BackgroundTransparency = 0.3
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.TextScaled = true
	hintLabel.TextColor3 = Color3.new(1, 1, 1)
	hintLabel.Text = "노란 공을 클릭하면 보물을 캐요! 100코인이 모이면 알을 사 보세요"
	hintLabel.Visible = false
	hintLabel.Parent = gui
	addCorner(hintLabel, 10)
end

-- 코인이 바뀌면 숫자를 바꾸고 살짝 커졌다 돌아오는 효과를 준다.
local function onCoinsChanged(coins: number)
	coinLabel.Text = `코인 {formatNumber(coins)}`
	local grow = TweenService:Create(coinLabel, TweenInfo.new(0.08), { TextTransparency = 0.3 })
	grow:Play()
	grow.Completed:Once(function()
		TweenService:Create(coinLabel, TweenInfo.new(0.12), { TextTransparency = 0 }):Play()
	end)
end

-- 펫이 하나도 없으면 안내 문구를 보여 준다.
local function onPetsChanged(pets)
	hintLabel.Visible = #pets == 0
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function HUDController.Init(controllers)
	DataController = controllers.DataController
end

-- 시작 단계: 화면을 만들고 데이터와 알림을 받기 시작한다.
function HUDController.Start()
	buildGui()
	DataController.OnChanged("coins", onCoinsChanged)
	DataController.OnChanged("pets", onPetsChanged)
	Notify.OnClientEvent:Connect(function(text)
		if typeof(text) == "string" then
			HUDController.ShowMessage(text)
		end
	end)
	print("[HUDController] 준비 완료")
end

-- 화면 위에 알림 문구를 잠깐 띄운다. 다른 컨트롤러도 이 함수를 쓴다. (예: "코인이 부족해요")
function HUDController.ShowMessage(text: string, color: Color3?)
	if not messageList then
		return
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.18)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.35
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = messageList
	addCorner(label, 8)

	-- 너무 많이 쌓이면 오래된 것부터 지운다.
	local labels = {}
	for _, child in messageList:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > 4 then
		labels[1]:Destroy()
	end

	task.delay(Config.NOTIFY_DURATION, function()
		if label.Parent then
			local fade = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			label:Destroy()
		end
	end)
end

return HUDController
