-- Config: 게임의 모든 숫자 설정값을 모아 둔다. 서버와 클라이언트가 같이 읽는다.
-- 의존: 없음
-- 밸런스(가격, 확률, 속도)를 바꿀 때는 이 파일만 고친다.
local Config = {}

-- 저장 관련
Config.DATASTORE_NAME = "PlayerData" -- DataStore 이름. 바꾸면 지금까지 저장된 데이터가 안 보이게 되니 바꾸지 않는다.
Config.AUTO_SAVE_INTERVAL = 60 -- 자동 저장 간격 (초)
Config.SAVE_RETRY_COUNT = 3 -- 저장/불러오기 실패 시 다시 시도하는 최대 횟수 (번)
Config.SAVE_RETRY_WAIT = 1 -- 다시 시도하기 전에 기다리는 시간 (초)

-- 통신 관련
Config.REMOTE_COOLDOWN = 0.2 -- 같은 플레이어가 Remote(또는 클릭)를 다시 보낼 수 있는 최소 간격 (초)

-- 테스트용 (Studio에서만 동작, 실제 게임에서는 무시된다)
Config.STUDIO_TEST_COINS = 0 -- Studio에서 Play할 때마다 이만큼 코인을 더 준다 (코인). 저장 테스트가 끝나면 0으로 되돌린다.

-- 보물 캐기
Config.BASE_POWER = 1 -- 펫을 하나도 장착하지 않았을 때 1번에 주는 데미지 (파워)
Config.MINE_INTERVAL = 1 -- 보물에 데미지를 주는 간격 (초)
Config.MINE_MAX_DISTANCE = 60 -- 보물을 클릭할 수 있는 거리이자, 이보다 멀어지면 캐기가 멈추는 거리 (스터드)
Config.TREASURE_RESPAWN_TIME = 5 -- 일반 보물이 깨진 뒤 다시 생기는 시간 (초)
Config.MAX_TREASURES_PER_ZONE = 15 -- 구역 하나에 동시에 있는 일반 보물 수 (개)
Config.BIG_CHEST_INTERVAL = 120 -- 큰 보물상자가 깨진 뒤 다음 큰 보물상자가 나타나기까지 시간 (초)
Config.CO_OP_BONUS = 0.2 -- 큰 보물상자를 2명 이상이 같이 열면 보상에 더하는 비율 (0.2 = 20%)

-- 펫
Config.MAX_EQUIPPED = 3 -- 동시에 장착할 수 있는 펫 수 (마리)
Config.MAX_PETS = 50 -- 인벤토리에 가질 수 있는 최대 펫 수 (마리)
Config.EGG_MAX_DISTANCE = 15 -- 알을 살 수 있는 거리 (스터드)
Config.EGG_MULTI_AMOUNT = 3 -- "여러 개 사기" 버튼으로 한 번에 사는 알 수 (개)
Config.HATCH_ANIMATION_TIME = 2 -- 부화 연출 시간 (초)

-- 펫 따라다니기 연출 (화면에만 보이는 값)
Config.PET_SIZE = 2 -- 펫 몸통 크기 (스터드)
Config.PET_FOLLOW_DISTANCE = 5 -- 플레이어 뒤로 떨어진 거리 (스터드)
Config.PET_SPACING = 3.5 -- 펫끼리 옆으로 떨어진 거리 (스터드)
Config.PET_HOVER_HEIGHT = 1 -- 펫이 위아래로 둥둥 뜨는 높이 (스터드)
Config.PET_FOLLOW_SPEED = 8 -- 펫이 따라오는 빠르기 (클수록 빨리 붙는다)

-- 일일 보상
Config.DAILY_REWARD = 250 -- 하루에 한 번 받는 코인 (코인)
Config.DAILY_COOLDOWN = 24 * 60 * 60 -- 다음 일일 보상까지 기다리는 시간 (초, 24시간)

-- 순위판 (서버 안에 있는 사람끼리 코인 순위)
Config.LEADERBOARD_SIZE = 10 -- 순위판에 보여 줄 사람 수 (명)
Config.LEADERBOARD_UPDATE_INTERVAL = 5 -- 순위판을 새로 고치는 간격 (초)

-- 맵 (MapService가 코드로 꾸민다)
Config.MAP_SEED = 7 -- 나무, 꽃 위치를 정하는 숫자. 바꾸면 배치가 달라진다. 같으면 매번 같은 모양.
Config.SPAWN_POSITION = Vector3.new(0, 0.5, -98) -- 시작 광장 가운데, 처음 나타나는 곳 (스터드)
Config.PLAZA_RADIUS = 22 -- 시작 광장 반지름 (스터드)
Config.LEADERBOARD_POSITION = Vector3.new(38, 0.5, -98) -- 순위판이 서 있는 곳 (스터드)
Config.ZONE_CHECK_INTERVAL = 0.5 -- 내가 어느 구역에 있는지 확인하는 간격 (초, 화면 연출용)
Config.LIGHTING_TWEEN_TIME = 1.5 -- 구역에 들어갈 때 조명/안개가 바뀌는 시간 (초)

-- 구역 목록. 모든 구역은 처음부터 열려 있다.
-- 대신 뒤 구역일수록 보물 체력이 매우 높아서, 그 구역 펫이 없으면 오래 걸린다. (= 자연스러운 단계)
-- 구역은 번호 순서대로 다리로 이어진다. (1 → 2 → 3 → 4 → 5 → 6)
-- areaCenter/areaSize: 보물이 생기는 땅 (높이는 무시) / groundBorder: 보물 땅 바깥 꾸밈 땅 너비 (스터드)
-- theme: 꾸미기 종류 / groundColor, groundMaterial: 땅 색과 재질 / accent: 입구 아치 색
-- recommendedPower: 입구 표지판에 보여 줄 추천 파워 (보여주기만, 막지는 않음)
-- lighting: 그 구역에 들어가면 내 화면의 조명이 바뀐다 (ambient 주변광, fogColor/fogEnd 안개 색과 거리, clockTime 시각)
Config.ZONES = {
	[1] = {
		name = "시작 마을",
		areaCenter = Vector3.new(0, 0, 0),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 40,
		theme = "village",
		groundColor = Color3.fromRGB(110, 190, 80),
		groundMaterial = "Grass",
		accent = Color3.fromRGB(255, 200, 80),
		recommendedPower = 1,
		lighting = { ambient = Color3.fromRGB(90, 90, 90), fogColor = Color3.fromRGB(200, 220, 240), fogEnd = 100000, clockTime = 14 },
	},
	[2] = {
		name = "숲",
		areaCenter = Vector3.new(0, 0, 270),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 25,
		theme = "forest",
		groundColor = Color3.fromRGB(60, 130, 55),
		groundMaterial = "Grass",
		accent = Color3.fromRGB(120, 80, 40),
		recommendedPower = 40,
		lighting = { ambient = Color3.fromRGB(70, 95, 70), fogColor = Color3.fromRGB(150, 190, 150), fogEnd = 600, clockTime = 13 },
	},
	[3] = {
		name = "얼음 왕국",
		areaCenter = Vector3.new(270, 0, 270),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 25,
		theme = "ice",
		groundColor = Color3.fromRGB(225, 240, 250),
		groundMaterial = "Snow",
		accent = Color3.fromRGB(120, 200, 255),
		recommendedPower = 350,
		lighting = { ambient = Color3.fromRGB(120, 135, 160), fogColor = Color3.fromRGB(220, 235, 255), fogEnd = 500, clockTime = 12 },
	},
	[4] = {
		name = "사막 오아시스",
		areaCenter = Vector3.new(270, 0, 0),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 25,
		theme = "desert",
		groundColor = Color3.fromRGB(235, 205, 140),
		groundMaterial = "Sand",
		accent = Color3.fromRGB(210, 150, 60),
		recommendedPower = 2500,
		lighting = { ambient = Color3.fromRGB(130, 105, 70), fogColor = Color3.fromRGB(245, 220, 170), fogEnd = 700, clockTime = 15.5 },
	},
	[5] = {
		name = "화산",
		areaCenter = Vector3.new(540, 0, 0),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 25,
		theme = "volcano",
		groundColor = Color3.fromRGB(55, 45, 45),
		groundMaterial = "Basalt",
		accent = Color3.fromRGB(255, 90, 30),
		recommendedPower = 20000,
		lighting = { ambient = Color3.fromRGB(120, 55, 35), fogColor = Color3.fromRGB(110, 40, 20), fogEnd = 400, clockTime = 18.3 },
	},
	[6] = {
		name = "사탕 나라",
		areaCenter = Vector3.new(540, 0, 270),
		areaSize = Vector3.new(150, 0, 150),
		groundBorder = 25,
		theme = "candy",
		groundColor = Color3.fromRGB(255, 190, 220),
		groundMaterial = "SmoothPlastic",
		accent = Color3.fromRGB(255, 110, 180),
		recommendedPower = 160000,
		lighting = { ambient = Color3.fromRGB(140, 105, 130), fogColor = Color3.fromRGB(255, 205, 235), fogEnd = 800, clockTime = 14 },
	},
}

-- 보물 종류
-- maxHP: 체력 / reward: 깨면 받는 코인 (여러 명이 캐면 때린 만큼 나눠 가진다)
-- spawnWeight: 일반 보물끼리 비교한 등장 비율 (클수록 자주 나온다)
-- isBig: true면 큰 보물상자 (구역에 1개만, 협동 보너스 있음)
-- shape/size/color/material: 모양 ("Ball" 공 / "Block" 상자), 크기 (스터드), 색, 재질 (없으면 매끈한 플라스틱)
-- 체력 기준: 그 구역 일반 펫 3마리로 코인 더미가 약 5초, 앞 구역 펫으로는 약 40초 이상 걸리게 정했다.
Config.TREASURES = {
	CoinPile = { name = "코인 더미", zone = 1, maxHP = 10, reward = 5, spawnWeight = 80, shape = "Ball", size = Vector3.new(3, 3, 3), color = Color3.fromRGB(255, 205, 50) },
	Chest = { name = "보물상자", zone = 1, maxHP = 60, reward = 40, spawnWeight = 20, shape = "Block", size = Vector3.new(4, 3, 3), color = Color3.fromRGB(150, 95, 45) },
	BigChest = { name = "큰 보물상자", zone = 1, maxHP = 1500, reward = 1200, isBig = true, shape = "Block", size = Vector3.new(10, 8, 8), color = Color3.fromRGB(170, 80, 255) },

	ForestCoinPile = { name = "도토리 더미", zone = 2, maxHP = 150, reward = 80, spawnWeight = 80, shape = "Ball", size = Vector3.new(3.5, 3.5, 3.5), color = Color3.fromRGB(150, 100, 50), material = "Wood" },
	ForestChest = { name = "통나무 상자", zone = 2, maxHP = 800, reward = 500, spawnWeight = 20, shape = "Block", size = Vector3.new(5, 4, 4), color = Color3.fromRGB(90, 60, 35), material = "Wood" },
	ForestBigChest = { name = "숲의 보물 나무상자", zone = 2, maxHP = 20000, reward = 15000, isBig = true, shape = "Block", size = Vector3.new(12, 10, 10), color = Color3.fromRGB(0, 200, 120) },

	IceCoinPile = { name = "얼음 코인", zone = 3, maxHP = 2000, reward = 900, spawnWeight = 80, shape = "Ball", size = Vector3.new(4, 4, 4), color = Color3.fromRGB(150, 220, 255), material = "Ice" },
	IceChest = { name = "얼음 상자", zone = 3, maxHP = 9000, reward = 5000, spawnWeight = 20, shape = "Block", size = Vector3.new(6, 4.5, 4.5), color = Color3.fromRGB(80, 150, 230), material = "Ice" },
	IceBigChest = { name = "거대 빙하 상자", zone = 3, maxHP = 200000, reward = 150000, isBig = true, shape = "Block", size = Vector3.new(14, 11, 11), color = Color3.fromRGB(40, 90, 220), material = "Glacier" },

	DesertCoinPile = { name = "황금 모래 더미", zone = 4, maxHP = 15000, reward = 6000, spawnWeight = 80, shape = "Ball", size = Vector3.new(4.5, 4.5, 4.5), color = Color3.fromRGB(255, 215, 90), material = "Sand" },
	DesertChest = { name = "파라오 상자", zone = 4, maxHP = 70000, reward = 35000, spawnWeight = 20, shape = "Block", size = Vector3.new(6, 5, 5), color = Color3.fromRGB(200, 160, 60), material = "Sandstone" },
	DesertBigChest = { name = "피라미드 보물", zone = 4, maxHP = 1500000, reward = 1000000, isBig = true, shape = "Block", size = Vector3.new(15, 12, 12), color = Color3.fromRGB(230, 180, 40), material = "Sandstone" },

	VolcanoCoinPile = { name = "용암 보석", zone = 5, maxHP = 120000, reward = 45000, spawnWeight = 80, shape = "Ball", size = Vector3.new(4.5, 4.5, 4.5), color = Color3.fromRGB(255, 100, 30), material = "Neon" },
	VolcanoChest = { name = "흑요석 상자", zone = 5, maxHP = 550000, reward = 260000, spawnWeight = 20, shape = "Block", size = Vector3.new(6.5, 5, 5), color = Color3.fromRGB(40, 30, 50), material = "Basalt" },
	VolcanoBigChest = { name = "화산 심장", zone = 5, maxHP = 12000000, reward = 8000000, isBig = true, shape = "Block", size = Vector3.new(16, 13, 13), color = Color3.fromRGB(200, 30, 10), material = "CrackedLava" },

	CandyCoinPile = { name = "사탕 더미", zone = 6, maxHP = 900000, reward = 330000, spawnWeight = 80, shape = "Ball", size = Vector3.new(5, 5, 5), color = Color3.fromRGB(255, 120, 200) },
	CandyChest = { name = "케이크 상자", zone = 6, maxHP = 4000000, reward = 1900000, spawnWeight = 20, shape = "Block", size = Vector3.new(7, 5, 5), color = Color3.fromRGB(255, 240, 200) },
	CandyBigChest = { name = "초대형 선물상자", zone = 6, maxHP = 90000000, reward = 60000000, isBig = true, shape = "Block", size = Vector3.new(17, 14, 14), color = Color3.fromRGB(150, 90, 255) },
}

-- 펫 등급: 이름과 화면에 보일 색
Config.RARITIES = {
	Common = { name = "일반", color = Color3.fromRGB(200, 200, 200) },
	Rare = { name = "희귀", color = Color3.fromRGB(80, 160, 255) },
	Legendary = { name = "레전더리", color = Color3.fromRGB(255, 200, 40) },
}

-- 펫 종류
-- power: 장착하면 보물에 주는 데미지 (파워)
-- style: 몸통에 붙는 장식 ("ears" 귀 / "longEars" 긴 귀 / "wings" 날개 / "horn" 뿔 / "beak" 부리 / "antlers" 사슴뿔
--        / "tusks" 엄니·집게 / "hump" 혹 / "spikes" 등 가시 / "flame" 머리 불꽃 / "cherry" 머리 체리)
-- accent: 장식 색
Config.PETS = {
	Dog = { name = "강아지", power = 2, rarity = "Common", color = Color3.fromRGB(170, 120, 70), style = "ears", accent = Color3.fromRGB(110, 70, 40) },
	Cat = { name = "고양이", power = 3, rarity = "Common", color = Color3.fromRGB(255, 160, 60), style = "ears", accent = Color3.fromRGB(255, 220, 180) },
	Bunny = { name = "토끼", power = 6, rarity = "Rare", color = Color3.fromRGB(255, 190, 220), style = "longEars", accent = Color3.fromRGB(255, 255, 255) },
	Dragon = { name = "드래곤", power = 20, rarity = "Legendary", color = Color3.fromRGB(220, 40, 40), style = "wings", accent = Color3.fromRGB(255, 170, 40) },

	Fox = { name = "여우", power = 15, rarity = "Common", color = Color3.fromRGB(230, 100, 30), style = "ears", accent = Color3.fromRGB(255, 255, 255) },
	Owl = { name = "부엉이", power = 20, rarity = "Common", color = Color3.fromRGB(120, 100, 80), style = "beak", accent = Color3.fromRGB(255, 190, 50) },
	Deer = { name = "사슴", power = 45, rarity = "Rare", color = Color3.fromRGB(200, 160, 110), style = "antlers", accent = Color3.fromRGB(110, 80, 50) },
	Unicorn = { name = "유니콘", power = 150, rarity = "Legendary", color = Color3.fromRGB(250, 240, 255), style = "horn", accent = Color3.fromRGB(255, 120, 220) },

	Penguin = { name = "펭귄", power = 120, rarity = "Common", color = Color3.fromRGB(40, 45, 60), style = "beak", accent = Color3.fromRGB(255, 170, 40) },
	Seal = { name = "물개", power = 160, rarity = "Common", color = Color3.fromRGB(150, 160, 175), style = "tusks", accent = Color3.fromRGB(250, 250, 240) },
	PolarBear = { name = "북극곰", power = 350, rarity = "Rare", color = Color3.fromRGB(245, 245, 250), style = "ears", accent = Color3.fromRGB(200, 200, 210) },
	IceDragon = { name = "얼음 드래곤", power = 1200, rarity = "Legendary", color = Color3.fromRGB(120, 210, 255), style = "wings", accent = Color3.fromRGB(230, 250, 255) },

	Camel = { name = "낙타", power = 900, rarity = "Common", color = Color3.fromRGB(210, 170, 110), style = "hump", accent = Color3.fromRGB(180, 140, 85) },
	Scorpion = { name = "전갈", power = 1200, rarity = "Common", color = Color3.fromRGB(120, 70, 40), style = "tusks", accent = Color3.fromRGB(60, 35, 20) },
	Fennec = { name = "사막여우", power = 2600, rarity = "Rare", color = Color3.fromRGB(245, 215, 160), style = "longEars", accent = Color3.fromRGB(255, 180, 150) },
	SandDragon = { name = "모래 드래곤", power = 9000, rarity = "Legendary", color = Color3.fromRGB(230, 190, 90), style = "wings", accent = Color3.fromRGB(160, 110, 40) },

	Salamander = { name = "불도롱뇽", power = 7000, rarity = "Common", color = Color3.fromRGB(255, 120, 40), style = "spikes", accent = Color3.fromRGB(255, 220, 60) },
	LavaGolem = { name = "용암 골렘", power = 9500, rarity = "Common", color = Color3.fromRGB(70, 55, 55), style = "flame", accent = Color3.fromRGB(255, 110, 20) },
	FireBird = { name = "불새", power = 20000, rarity = "Rare", color = Color3.fromRGB(255, 70, 30), style = "wings", accent = Color3.fromRGB(255, 200, 50) },
	LavaDragon = { name = "용암 드래곤", power = 70000, rarity = "Legendary", color = Color3.fromRGB(40, 20, 20), style = "spikes", accent = Color3.fromRGB(255, 80, 0) },

	GummyBear = { name = "곰젤리", power = 55000, rarity = "Common", color = Color3.fromRGB(255, 80, 80), style = "ears", accent = Color3.fromRGB(255, 140, 140) },
	CottonBunny = { name = "솜사탕 토끼", power = 75000, rarity = "Common", color = Color3.fromRGB(190, 220, 255), style = "longEars", accent = Color3.fromRGB(255, 200, 235) },
	CakeCat = { name = "케이크 고양이", power = 160000, rarity = "Rare", color = Color3.fromRGB(255, 245, 225), style = "cherry", accent = Color3.fromRGB(220, 20, 40) },
	CandyDragon = { name = "사탕 드래곤", power = 550000, rarity = "Legendary", color = Color3.fromRGB(255, 120, 210), style = "wings", accent = Color3.fromRGB(140, 230, 255) },
}

-- 알 종류. price: 1개 가격 (코인) / position: 알이 놓일 위치 / pets: 나오는 펫과 확률 (%, 합이 100)
-- 게임 코인으로만 사는 알이라 로블록스 유료 확률 상품 정책에는 해당하지 않는다.
Config.EGGS = {
	BasicEgg = {
		name = "기본 알", zone = 1, price = 100, position = Vector3.new(-30, 0.5, -98), color = Color3.fromRGB(245, 235, 210),
		pets = { { id = "Dog", chance = 60 }, { id = "Cat", chance = 30 }, { id = "Bunny", chance = 9 }, { id = "Dragon", chance = 1 } },
	},
	ForestEgg = {
		name = "숲 알", zone = 2, price = 1500, position = Vector3.new(25, 0.5, 205), color = Color3.fromRGB(110, 200, 110),
		pets = { { id = "Fox", chance = 60 }, { id = "Owl", chance = 30 }, { id = "Deer", chance = 9 }, { id = "Unicorn", chance = 1 } },
	},
	IceEgg = {
		name = "얼음 알", zone = 3, price = 15000, position = Vector3.new(205, 0.5, 295), color = Color3.fromRGB(170, 225, 255),
		pets = { { id = "Penguin", chance = 60 }, { id = "Seal", chance = 30 }, { id = "PolarBear", chance = 9 }, { id = "IceDragon", chance = 1 } },
	},
	DesertEgg = {
		name = "사막 알", zone = 4, price = 150000, position = Vector3.new(295, 0.5, 65), color = Color3.fromRGB(240, 200, 110),
		pets = { { id = "Camel", chance = 60 }, { id = "Scorpion", chance = 30 }, { id = "Fennec", chance = 9 }, { id = "SandDragon", chance = 1 } },
	},
	VolcanoEgg = {
		name = "화산 알", zone = 5, price = 1500000, position = Vector3.new(475, 0.5, 25), color = Color3.fromRGB(230, 70, 30),
		pets = { { id = "Salamander", chance = 60 }, { id = "LavaGolem", chance = 30 }, { id = "FireBird", chance = 9 }, { id = "LavaDragon", chance = 1 } },
	},
	CandyEgg = {
		name = "사탕 알", zone = 6, price = 12000000, position = Vector3.new(565, 0.5, 205), color = Color3.fromRGB(255, 150, 220),
		pets = { { id = "GummyBear", chance = 60 }, { id = "CottonBunny", chance = 30 }, { id = "CakeCat", chance = 9 }, { id = "CandyDragon", chance = 1 } },
	},
}

-- 화면 (UI)
Config.NOTIFY_DURATION = 2.5 -- 알림 문구가 화면에 떠 있는 시간 (초)

return Config
