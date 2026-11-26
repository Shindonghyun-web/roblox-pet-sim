-- CoinService: 코인 더하기/빼기와 DataChanged 알림, leaderstats 표시를 담당한다.
-- 의존: DataService, Config
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataChanged = Remotes:WaitForChild("DataChanged")

local CoinService = {}

local DataService -- Init에서 연결

-- 코인이 바뀌면 순위표(leaderstats)와 그 플레이어 화면에 새 값을 알려 준다.
local function showCoins(player: Player, coins: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
	if coinsValue then
		coinsValue.Value = coins
	end
	DataChanged:FireClient(player, "coins", coins)
end

-- 이상한 숫자(문자열, 음수, NaN, 무한대)가 들어오면 코인이 망가지므로 미리 걸러 낸다.
local function isValidAmount(amount): boolean
	return typeof(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
end

-- 데이터가 준비된 플레이어에게 순위표를 만들어 준다.
local function onPlayerLoaded(player: Player, data)
	-- 순위표는 화면 오른쪽 위에 보이는 로블록스 기본 표다. 폴더 이름은 꼭 "leaderstats"여야 한다.
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = data.coins
	coinsValue.Parent = leaderstats

	leaderstats.Parent = player

	-- 저장 테스트용: Studio에서만, Config 값이 0보다 클 때만 코인을 더 준다.
	if RunService:IsStudio() and Config.STUDIO_TEST_COINS > 0 then
		CoinService.AddCoins(player, Config.STUDIO_TEST_COINS)
		print(`[CoinService] Studio 테스트 코인 +{Config.STUDIO_TEST_COINS} → 지금 코인: {CoinService.GetCoins(player)}`)
	else
		showCoins(player, data.coins)
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function CoinService.Init(services)
	DataService = services.DataService
end

-- 시작 단계: 플레이어 데이터가 준비될 때마다 순위표를 만든다.
function CoinService.Start()
	DataService.OnPlayerLoaded(onPlayerLoaded)
	print("[CoinService] 준비 완료")
end

-- 지금 가진 코인 수를 돌려준다. 데이터가 아직 없으면 0이다.
function CoinService.GetCoins(player: Player): number
	local data = DataService.Get(player)
	return if data then data.coins else 0
end

-- 코인을 더한다. 성공하면 true를 돌려준다.
function CoinService.AddCoins(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		warn("[CoinService] 잘못된 코인 양:", amount)
		return false
	end
	amount = math.floor(amount) -- 코인은 정수로만 다룬다.

	local newCoins
	local ok = DataService.Update(player, function(data)
		data.coins += amount
		newCoins = data.coins
	end)
	if not ok then
		return false
	end

	showCoins(player, newCoins)
	return true
end

-- 코인을 뺀다. 코인이 모자라면 아무것도 바꾸지 않고 false를 돌려준다.
-- 구매하는 쪽(알, 구역)은 이 함수가 true를 돌려줄 때만 물건을 준다.
function CoinService.SpendCoins(player: Player, amount: number): boolean
	if not isValidAmount(amount) then
		warn("[CoinService] 잘못된 코인 양:", amount)
		return false
	end
	amount = math.floor(amount)

	local spent = false
	local newCoins
	DataService.Update(player, function(data)
		if data.coins >= amount then
			data.coins -= amount
			spent = true
		end
		newCoins = data.coins
	end)
	if not spent then
		return false
	end

	showCoins(player, newCoins)
	return true
end

return CoinService
