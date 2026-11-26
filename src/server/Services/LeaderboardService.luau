-- LeaderboardService: 시작 광장에 순위판을 세우고, 지금 서버에 있는 사람들의 코인 순위를 보여 준다.
-- 의존: CoinService, Config
-- 순위판 글씨는 서버가 바꾸면 모든 플레이어 화면에 똑같이 보인다. (보기만 하는 판이라 Remote가 필요 없다)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local LeaderboardService = {}

local CoinService -- Init에서 연결

local rowLabels = {} -- 순위 줄 글씨들 (1등부터)

local function formatNumber(value: number): string
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function buildBoard()
	local base = Config.LEADERBOARD_POSITION
	local boardHeight = 14
	local boardPos = base + Vector3.new(0, boardHeight / 2 + 1, 0)
	-- 앞면이 시작 위치를 바라보게 세운다.
	local spawnPos = Config.SPAWN_POSITION
	local cframe = CFrame.lookAt(boardPos, Vector3.new(spawnPos.X, boardPos.Y, spawnPos.Z))

	local board = Instance.new("Part")
	board.Name = "Leaderboard"
	board.Anchored = true
	board.CanQuery = false
	board.Size = Vector3.new(12, boardHeight, 1)
	board.CFrame = cframe
	board.Color = Color3.fromRGB(40, 40, 60)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = Workspace

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 30
	gui.Parent = board

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 215, 60)
	title.Text = "코인 순위"
	title.Parent = gui

	local rowHeight = 0.85 / Config.LEADERBOARD_SIZE
	for rank = 1, Config.LEADERBOARD_SIZE do
		local row = Instance.new("TextLabel")
		row.LayoutOrder = rank
		row.Size = UDim2.fromScale(1, rowHeight)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if rank == 1 then Color3.fromRGB(255, 215, 60) else Color3.new(1, 1, 1)
		row.Text = ""
		row.Parent = gui
		table.insert(rowLabels, row)
	end
end

local function refresh()
	local entries = {}
	for _, player in Players:GetPlayers() do
		table.insert(entries, { name = player.DisplayName, coins = CoinService.GetCoins(player) })
	end
	table.sort(entries, function(a, b)
		return a.coins > b.coins
	end)
	for rank, label in rowLabels do
		local entry = entries[rank]
		label.Text = if entry then `  {rank}. {entry.name}  -  {formatNumber(entry.coins)}` else ""
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function LeaderboardService.Init(services)
	CoinService = services.CoinService
end

-- 시작 단계: 순위판을 세우고 주기적으로 새로 고친다.
function LeaderboardService.Start()
	buildBoard()
	task.spawn(function()
		while true do
			refresh()
			task.wait(Config.LEADERBOARD_UPDATE_INTERVAL)
		end
	end)
	print("[LeaderboardService] 준비 완료")
end

return LeaderboardService
