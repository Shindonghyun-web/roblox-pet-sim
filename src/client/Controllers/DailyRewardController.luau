-- DailyRewardController: 화면 오른쪽 "일일 보상" 버튼과 남은 시간 표시를 담당한다.
-- 의존: DataController, HUDController, Config, Remotes(ClaimDaily)
-- 받을 수 있는지는 서버(DailyRewardService)가 정한다. 여기서는 남은 시간을 보여 주고 요청만 보낸다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimDaily = Remotes:WaitForChild("ClaimDaily")

local player = Players.LocalPlayer

local DailyRewardController = {}

local DataController -- Init에서 연결
local HUDController

local button: TextButton
local busy = false

local READY_COLOR = Color3.fromRGB(80, 200, 100)
local WAIT_COLOR = Color3.fromRGB(90, 90, 110)

-- 3725초 → "01:02:05"
local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DailyRewardGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.fromScale(0.985, 0.5)
	button.Size = UDim2.fromScale(0.09, 0.09)
	button.BackgroundColor3 = WAIT_COLOR
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "일일\n보상"
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = button
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = button
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(56, 56)
	limit.MaxSize = Vector2.new(90, 90)
	limit.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.08, 0)
	padding.PaddingRight = UDim.new(0.08, 0)
	padding.Parent = button
end

-- 1초마다 버튼 글자를 바꾼다. 서버 시계(GetServerTimeNow)를 써서 내 컴퓨터 시계가 틀려도 맞게 보인다.
local function updateButton()
	local nextDaily = DataController.Get("nextDaily")
	if not nextDaily then
		return
	end
	local remaining = nextDaily - Workspace:GetServerTimeNow()
	if remaining <= 0 then
		button.Text = "일일\n보상!"
		button.BackgroundColor3 = READY_COLOR
	else
		button.Text = `일일 보상\n{formatTime(remaining)}`
		button.BackgroundColor3 = WAIT_COLOR
	end
end

local function onPressed()
	if busy then
		return
	end
	busy = true
	local callOk, ok, result = pcall(function()
		return ClaimDaily:InvokeServer()
	end)
	if not callOk then
		HUDController.ShowMessage("요청에 실패했어요. 다시 시도해 주세요.", Color3.fromRGB(255, 120, 120))
	elseif ok then
		HUDController.ShowMessage(`일일 보상 +{result} 코인!`, Color3.fromRGB(120, 255, 140))
	else
		HUDController.ShowMessage(result or "아직 받을 수 없어요.", Color3.fromRGB(255, 120, 120))
	end
	busy = false
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function DailyRewardController.Init(controllers)
	DataController = controllers.DataController
	HUDController = controllers.HUDController
end

-- 시작 단계: 버튼을 만들고 1초마다 남은 시간을 새로 그린다.
function DailyRewardController.Start()
	buildGui()
	button.Activated:Connect(onPressed)
	DataController.OnChanged("nextDaily", updateButton)
	task.spawn(function()
		while true do
			updateButton()
			task.wait(1)
		end
	end)
	print("[DailyRewardController] 준비 완료")
end

return DailyRewardController
