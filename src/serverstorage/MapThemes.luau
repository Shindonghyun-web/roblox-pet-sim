-- MapThemes: 구역 컨셉(theme)마다 "어떤 장식을 몇 개 놓을지" 적은 표. 서버만 쓴다.
-- 의존: MapDecor
-- Config.ZONES[n].theme 이름(village, forest, ice, desert, volcano, candy)과 같은 키를 쓴다.
-- large: 보물 땅 바깥 테두리에 놓는 큰 장식 (부딪힘 있음)
-- small: 구역 아무 데나 흩뿌리는 작은 장식 (밟고 지나감)
-- landmark: 구역마다 몇 개만 놓는 큰 상징물
local MapDecor = require(script.Parent:WaitForChild("MapDecor"))

-- 0~1 사이 아무 숫자. MapDecor와 같은 Random을 써서 MAP_SEED가 같으면 매번 같은 모양이 된다.
local function roll(): number
	return MapDecor.GetRandom():NextNumber()
end

local MapThemes = {
	village = {
		largeCount = 55,
		large = function(pos)
			if roll() < 0.75 then
				MapDecor.roundTree(pos, Color3.fromRGB(70, 160, 60):Lerp(Color3.fromRGB(120, 200, 70), roll()))
			else
				MapDecor.rock(pos, Color3.fromRGB(140, 140, 145))
			end
		end,
		smallCount = 140,
		small = function(pos)
			MapDecor.tiny(pos, { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 60), Color3.fromRGB(180, 120, 255), Color3.new(1, 1, 1) })
		end,
	},
	forest = {
		largeCount = 75,
		large = function(pos)
			if roll() < 0.6 then
				MapDecor.pineTree(pos, Color3.fromRGB(35, 100, 45), false)
			else
				MapDecor.roundTree(pos, Color3.fromRGB(40, 120, 50))
			end
		end,
		smallCount = 60,
		small = MapDecor.mushroom,
	},
	ice = {
		largeCount = 60,
		large = function(pos)
			local r = roll()
			if r < 0.65 then
				MapDecor.pineTree(pos, Color3.fromRGB(60, 110, 90), true)
			elseif r < 0.9 then
				MapDecor.iceCrystal(pos)
			else
				MapDecor.snowman(pos)
			end
		end,
		smallCount = 60,
		small = function(pos)
			MapDecor.iceCrystal(pos, 0.4)
		end,
	},
	desert = {
		largeCount = 50,
		large = function(pos)
			local r = roll()
			if r < 0.5 then
				MapDecor.cactus(pos)
			elseif r < 0.85 then
				MapDecor.palmTree(pos)
			else
				MapDecor.rock(pos, Color3.fromRGB(200, 160, 100), Enum.Material.Sandstone)
			end
		end,
		smallCount = 70,
		small = function(pos)
			MapDecor.tiny(pos, { Color3.fromRGB(210, 180, 120), Color3.fromRGB(190, 150, 90) }, Enum.Material.Sandstone, 1)
		end,
		landmarkCount = 2,
		landmark = function(pos)
			MapDecor.pyramid(pos, 18)
		end,
	},
	volcano = {
		largeCount = 55,
		large = function(pos)
			local r = roll()
			if r < 0.5 then
				MapDecor.rock(pos, Color3.fromRGB(45, 40, 40), Enum.Material.Basalt)
			elseif r < 0.75 then
				MapDecor.deadTree(pos)
			else
				MapDecor.fireVent(pos)
			end
		end,
		smallCount = 80,
		small = function(pos)
			MapDecor.tiny(pos, { Color3.fromRGB(255, 110, 20), Color3.fromRGB(255, 200, 50) }, Enum.Material.Neon, 0.6)
		end,
		landmarkCount = 5,
		landmark = function(pos)
			MapDecor.lavaPool(pos, 5 + roll() * 4)
		end,
	},
	candy = {
		largeCount = 60,
		large = function(pos)
			local r = roll()
			if r < 0.5 then
				MapDecor.lollipop(pos)
			elseif r < 0.8 then
				MapDecor.candyCane(pos)
			else
				MapDecor.gumdrop(pos)
			end
		end,
		smallCount = 120,
		small = function(pos)
			MapDecor.tiny(pos, MapDecor.CANDY_COLORS, Enum.Material.Neon, 0.6)
		end,
	},
}

return MapThemes
