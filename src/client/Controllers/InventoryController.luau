-- InventoryController: 펫 목록 창을 그리고, 펫을 누르면 서버에 장착/해제/지우기를 요청한다.
-- 의존: DataController, HUDController, Config, Remotes(EquipPet, UnequipPet, DeletePet)
-- 화면(InventoryGui)은 코드로 만든다. 장착 결과는 서버가 정하고, 바뀐 목록은 DataChanged로 다시 받는다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquipPet = Remotes:WaitForChild("EquipPet")
local UnequipPet = Remotes:WaitForChild("UnequipPet")
local DeletePet = Remotes:WaitForChild("DeletePet")

local player = Players.LocalPlayer

local InventoryController = {}

local DataController -- Init에서 연결
local HUDController

local panel: Frame
local titleLabel: TextLabel
local grid: ScrollingFrame
local deleteButton: TextButton
local busy = false
local deleteMode = false -- 켜져 있으면 펫 카드를 눌렀을 때 장착 대신 지운다.
local refresh -- 아래에서 정의 (지우기 모드 버튼이 먼저 부르기 때문에 미리 이름만 만든다)

local ERROR_COLOR = Color3.fromRGB(255, 120, 120)

local function addCorner(parent: Instance, scale: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(scale, 0)
	corner.Parent = parent
end

local function makeLabel(parent: Instance, text: string, position: UDim2, size: UDim2, color: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = parent
	return label
end

local function buildGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "InventoryGui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- 왼쪽 가운데 "펫" 버튼 (모바일에서도 누르기 쉽게 크게)
	local openButton = Instance.new("TextButton")
	openButton.Name = "OpenButton"
	openButton.AnchorPoint = Vector2.new(0, 0.5)
	openButton.Position = UDim2.fromScale(0.015, 0.5)
	openButton.Size = UDim2.fromScale(0.09, 0.09)
	openButton.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	openButton.Font = Enum.Font.GothamBlack
	openButton.TextScaled = true
	openButton.TextColor3 = Color3.new(1, 1, 1)
	openButton.Text = "펫"
	openButton.Parent = gui
	addCorner(openButton, 0.25)
	local buttonRatio = Instance.new("UIAspectRatioConstraint")
	buttonRatio.Parent = openButton
	local buttonLimit = Instance.new("UISizeConstraint")
	buttonLimit.MinSize = Vector2.new(56, 56)
	buttonLimit.MaxSize = Vector2.new(90, 90)
	buttonLimit.Parent = openButton

	-- 펫 목록 창 (가운데)
	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.7, 0.7)
	panel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	panel.Visible = false
	panel.Parent = gui
	addCorner(panel, 0.04)
	local panelLimit = Instance.new("UISizeConstraint")
	panelLimit.MaxSize = Vector2.new(700, 500)
	panelLimit.Parent = panel

	titleLabel = makeLabel(panel, "내 펫", UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.62, 0.1))
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- 지우기 모드 버튼: 켜면 카드를 눌렀을 때 펫을 지운다. 실수를 막으려고 기본은 꺼져 있다.
	deleteButton = Instance.new("TextButton")
	deleteButton.AnchorPoint = Vector2.new(1, 0)
	deleteButton.Position = UDim2.fromScale(0.86, 0.02)
	deleteButton.Size = UDim2.fromScale(0.2, 0.1)
	deleteButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	deleteButton.Font = Enum.Font.GothamBold
	deleteButton.TextScaled = true
	deleteButton.TextColor3 = Color3.new(1, 1, 1)
	deleteButton.Text = "지우기 모드"
	deleteButton.Parent = panel
	addCorner(deleteButton, 0.25)
	deleteButton.Activated:Connect(function()
		deleteMode = not deleteMode
		deleteButton.BackgroundColor3 = if deleteMode then Color3.fromRGB(220, 70, 70) else Color3.fromRGB(90, 90, 110)
		deleteButton.Text = if deleteMode then "지우기 켜짐" else "지우기 모드"
		refresh()
	end)

	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(0.98, 0.02)
	closeButton.Size = UDim2.fromScale(0.1, 0.1)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.TextScaled = true
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Text = "X"
	closeButton.Parent = panel
	addCorner(closeButton, 0.25)
	local closeRatio = Instance.new("UIAspectRatioConstraint")
	closeRatio.Parent = closeButton

	grid = Instance.new("ScrollingFrame")
	grid.Position = UDim2.fromScale(0.03, 0.15)
	grid.Size = UDim2.fromScale(0.94, 0.82)
	grid.BackgroundTransparency = 1
	grid.ScrollBarThickness = 8
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = panel
	local layout = Instance.new("UIGridLayout")
	-- 가로는 창 너비의 비율, 세로는 고정 픽셀. (스크롤 창 안에서 세로를 비율로 쓰면 크기가 꼬일 수 있다)
	layout.CellSize = UDim2.new(0.23, 0, 0, 120)
	layout.CellPadding = UDim2.new(0.02, 0, 0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	openButton.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
	closeButton.Activated:Connect(function()
		panel.Visible = false
	end)
end

-- 펫 카드를 누르면: 지우기 모드면 지우기, 장착 중이면 해제, 아니면 장착을 서버에 요청한다.
local function onCardPressed(petUid: string, isEquipped: boolean)
	if busy then
		return
	end
	busy = true
	local remote = if deleteMode then DeletePet elseif isEquipped then UnequipPet else EquipPet
	local callOk, ok, reason = pcall(function()
		return remote:InvokeServer(petUid)
	end)
	if not callOk then
		HUDController.ShowMessage("요청에 실패했어요. 다시 시도해 주세요.", ERROR_COLOR)
	elseif not ok then
		HUDController.ShowMessage(reason or "할 수 없어요.", ERROR_COLOR)
	end
	busy = false
end

-- 펫 목록을 다시 그린다. 장착한 펫이 먼저, 그다음 파워가 센 순서로 보여 준다.
function refresh()
	if not grid then
		return
	end
	local pets = DataController.Get("pets") or {}
	local equipped = DataController.Get("equipped") or {}

	for _, child in grid:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	local sorted = table.clone(pets)
	table.sort(sorted, function(a, b)
		local aEquipped = table.find(equipped, a.uid) ~= nil
		local bEquipped = table.find(equipped, b.uid) ~= nil
		if aEquipped ~= bEquipped then
			return aEquipped
		end
		local aPower = Config.PETS[a.id] and Config.PETS[a.id].power or 0
		local bPower = Config.PETS[b.id] and Config.PETS[b.id].power or 0
		return aPower > bPower
	end)

	-- 파워 합계는 화면 표시용으로만 계산한다. 실제 데미지는 서버(PetService.GetPower)가 계산한다.
	local totalPower = 0
	for index, pet in sorted do
		local def = Config.PETS[pet.id]
		if def then
			local isEquipped = table.find(equipped, pet.uid) ~= nil
			if isEquipped then
				totalPower += def.power
			end
			local rarity = Config.RARITIES[def.rarity]

			local card = Instance.new("TextButton")
			card.LayoutOrder = index
			card.Text = ""
			card.AutoButtonColor = true
			card.BackgroundColor3 = if deleteMode and not isEquipped
				then Color3.fromRGB(120, 45, 45)
				elseif isEquipped then Color3.fromRGB(50, 110, 70)
				else Color3.fromRGB(55, 55, 75)
			card.Parent = grid
			addCorner(card, 0.1)
			local stroke = Instance.new("UIStroke")
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Thickness = 3
			stroke.Color = rarity.color
			stroke.Parent = card

			local circle = Instance.new("Frame")
			circle.AnchorPoint = Vector2.new(0.5, 0)
			circle.Position = UDim2.fromScale(0.5, 0.06)
			circle.Size = UDim2.fromScale(0.4, 0.4)
			circle.BackgroundColor3 = def.color
			circle.Parent = card
			addCorner(circle, 0.5)
			local circleRatio = Instance.new("UIAspectRatioConstraint")
			circleRatio.Parent = circle

			makeLabel(card, def.name, UDim2.fromScale(0.05, 0.5), UDim2.fromScale(0.9, 0.17))
			makeLabel(card, `{rarity.name} · 파워 {def.power}`, UDim2.fromScale(0.05, 0.67), UDim2.fromScale(0.9, 0.13), rarity.color)
			local hint = if deleteMode then (if isEquipped then "장착 중이라 못 지움" else "누르면 지우기")
				elseif isEquipped then "장착 중 (누르면 해제)"
				else "누르면 장착"
			makeLabel(card, hint, UDim2.fromScale(0.05, 0.82), UDim2.fromScale(0.9, 0.12), Color3.fromRGB(200, 200, 200))

			card.Activated:Connect(function()
				onCardPressed(pet.uid, isEquipped)
			end)
		end
	end

	titleLabel.Text = `내 펫 {#pets}/{Config.MAX_PETS} · 장착 {#equipped}/{Config.MAX_EQUIPPED} · 파워 {math.max(totalPower, Config.BASE_POWER)}`
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function InventoryController.Init(controllers)
	DataController = controllers.DataController
	HUDController = controllers.HUDController
end

-- 시작 단계: 펫 창을 만들고, 펫 목록이 바뀔 때마다 다시 그린다.
function InventoryController.Start()
	buildGui()
	DataController.OnChanged("pets", refresh)
	DataController.OnChanged("equipped", refresh)
	print("[InventoryController] 준비 완료")
end

return InventoryController
