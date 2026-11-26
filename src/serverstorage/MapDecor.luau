-- MapDecor: 맵 장식(나무, 선인장, 사탕 등)의 "모양"을 만드는 함수 모음. 서버만 쓴다.
-- 의존: 없음 (MapService가 불러서 쓴다)
-- 어디에 몇 개 놓을지는 MapService가 정하고, 여기는 "하나를 어떻게 생기게 만들지"만 담당한다.
local MapDecor = {}

local folder: Instance -- 장식을 넣을 폴더 (Setup에서 받는다)
local random: Random -- 같은 MAP_SEED면 매번 같은 모양이 나오게 MapService의 Random을 같이 쓴다

function MapDecor.Setup(decorFolder: Instance, sharedRandom: Random)
	folder = decorFolder
	random = sharedRandom
end

-- MapThemes가 같은 Random을 쓰게 돌려준다.
function MapDecor.GetRandom(): Random
	return random
end

-- 장식 파트 하나. 클릭/닿기 판정을 꺼서 보물 클릭을 가리지 않게 한다.
local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		p[key] = value
	end
	p.Parent = folder
	return p
end

local function ball(position: Vector3, size: number, color: Color3, material: Enum.Material, collide: boolean?): Part
	return part({ Shape = Enum.PartType.Ball, Size = Vector3.one * size, Position = position, Color = color, Material = material, CanCollide = collide == true })
end

local function pick(list)
	return list[random:NextInteger(1, #list)]
end

-- 공통 ---------------------------------------------------------------

function MapDecor.roundTree(pos: Vector3, leafColor: Color3)
	local height = random:NextNumber(5, 8)
	part({ Size = Vector3.new(1.6, height, 1.6), Position = pos + Vector3.new(0, height / 2, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood })
	local leaf = random:NextNumber(7, 10)
	ball(pos + Vector3.new(0, height + leaf * 0.3, 0), leaf, leafColor, Enum.Material.Grass)
end

function MapDecor.pineTree(pos: Vector3, leafColor: Color3, snowy: boolean)
	part({ Size = Vector3.new(1.4, 4, 1.4), Position = pos + Vector3.new(0, 2, 0), Color = Color3.fromRGB(95, 65, 40), Material = Enum.Material.Wood })
	for layer = 1, 3 do
		local width = 8 - layer * 2
		local color = if snowy and layer == 3 then Color3.new(1, 1, 1) else leafColor
		part({ Size = Vector3.new(width, 2.5, width), CFrame = CFrame.new(pos + Vector3.new(0, 3 + layer * 2.2, 0)) * CFrame.Angles(0, math.rad(45 * layer), 0), Color = color, Material = Enum.Material.Grass, CanCollide = false })
	end
end

function MapDecor.rock(pos: Vector3, color: Color3, material: Enum.Material?)
	local size = random:NextNumber(2, 4.5)
	ball(pos + Vector3.new(0, size * 0.2, 0), size, color, material or Enum.Material.Slate, true)
end

function MapDecor.tiny(pos: Vector3, colors: { Color3 }, material: Enum.Material?, size: number?)
	ball(pos + Vector3.new(0, 0.5, 0), size or 0.8, pick(colors), material or Enum.Material.SmoothPlastic)
end

function MapDecor.lampPost(pos: Vector3)
	part({ Size = Vector3.new(0.6, 8, 0.6), Position = pos + Vector3.new(0, 4, 0), Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.Metal })
	local lamp = ball(pos + Vector3.new(0, 8.4, 0), 1.6, Color3.fromRGB(255, 230, 150), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.5
	light.Color = lamp.Color
	light.Parent = lamp
end

-- 글씨판. 앞면과 뒷면 모두에 글씨를 쓴다.
local function writeText(board: Part, text: string, pixelsPerStud: number)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.PixelsPerStud = pixelsPerStud
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Text = text
		label.Parent = gui
	end
end

function MapDecor.sign(pos: Vector3, lookAt: Vector3, text: string, width: number)
	part({ Size = Vector3.new(0.8, 5, 0.8), Position = pos + Vector3.new(0, 2.5, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood })
	local boardPos = pos + Vector3.new(0, 6, 0)
	local board = part({ Size = Vector3.new(width, 3, 0.5), CFrame = CFrame.lookAt(boardPos, Vector3.new(lookAt.X, boardPos.Y, lookAt.Z)), Color = Color3.fromRGB(150, 105, 60), Material = Enum.Material.Wood })
	writeText(board, text, 40)
end

-- 구역 입구 아치. forward: 구역 안쪽 방향
function MapDecor.arch(pos: Vector3, forward: Vector3, text: string, color: Color3)
	local side = Vector3.new(-forward.Z, 0, forward.X)
	local height = 14
	for _, s in { 1, -1 } do
		part({ Size = Vector3.new(2.5, height, 2.5), Position = pos + side * s * 10 + Vector3.new(0, height / 2, 0), Color = color, Material = Enum.Material.SmoothPlastic })
	end
	local beamPos = pos + Vector3.new(0, height + 1.5, 0)
	local beam = part({ Size = Vector3.new(24, 4, 1.5), CFrame = CFrame.lookAt(beamPos, beamPos + forward), Color = color, Material = Enum.Material.SmoothPlastic })
	writeText(beam, text, 30)
end

-- 숲 ---------------------------------------------------------------

function MapDecor.mushroom(pos: Vector3)
	part({ Size = Vector3.new(0.8, 1.6, 0.8), Position = pos + Vector3.new(0, 0.8, 0), Color = Color3.fromRGB(245, 235, 215), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	ball(pos + Vector3.new(0, 1.8, 0), 2.4, pick({ Color3.fromRGB(220, 50, 50), Color3.fromRGB(240, 150, 40) }), Enum.Material.SmoothPlastic)
end

-- 얼음 ---------------------------------------------------------------

function MapDecor.iceCrystal(pos: Vector3, scale: number?)
	local height = random:NextNumber(4, 9) * (scale or 1)
	part({ Size = Vector3.new(1.5, height, 1.5) * (scale or 1), CFrame = CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(math.rad(random:NextNumber(-15, 15)), math.rad(45), math.rad(random:NextNumber(-15, 15))), Color = Color3.fromRGB(140, 210, 255), Material = Enum.Material.Ice, Transparency = 0.2, CanCollide = (scale or 1) >= 1 })
end

function MapDecor.snowman(pos: Vector3)
	local y = 0
	for _, size in { 4, 3, 2 } do
		ball(pos + Vector3.new(0, y + size / 2, 0), size, Color3.new(1, 1, 1), Enum.Material.Snow, true)
		y += size * 0.8
	end
end

-- 사막 ---------------------------------------------------------------

function MapDecor.cactus(pos: Vector3)
	local green = Color3.fromRGB(70, 150, 70)
	local height = random:NextNumber(6, 10)
	part({ Size = Vector3.new(2, height, 2), Position = pos + Vector3.new(0, height / 2, 0), Color = green, Material = Enum.Material.Grass })
	for _, s in { 1, -1 } do
		local armY = random:NextNumber(height * 0.4, height * 0.7)
		part({ Size = Vector3.new(2.5, 1.4, 1.4), Position = pos + Vector3.new(s * 1.8, armY, 0), Color = green, Material = Enum.Material.Grass })
		part({ Size = Vector3.new(1.4, 3, 1.4), Position = pos + Vector3.new(s * 2.6, armY + 1.5, 0), Color = green, Material = Enum.Material.Grass })
	end
end

function MapDecor.palmTree(pos: Vector3)
	local height = random:NextNumber(10, 14)
	local tilt = CFrame.Angles(math.rad(random:NextNumber(-10, 10)), 0, math.rad(random:NextNumber(-10, 10)))
	local base = CFrame.new(pos) * tilt
	part({ Size = Vector3.new(1.3, height, 1.3), CFrame = base * CFrame.new(0, height / 2, 0), Color = Color3.fromRGB(150, 110, 60), Material = Enum.Material.Wood })
	local top = base * CFrame.new(0, height, 0)
	for i = 0, 5 do
		part({ Size = Vector3.new(1.8, 0.3, 7), CFrame = top * CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(-20), 0, 0), Color = Color3.fromRGB(60, 160, 60), Material = Enum.Material.Grass, CanCollide = false })
	end
end

function MapDecor.pyramid(pos: Vector3, size: number)
	local layers = 6
	for i = 0, layers - 1 do
		local width = size * (1 - i / layers)
		part({ Size = Vector3.new(width, size / layers, width), Position = pos + Vector3.new(0, size / layers * (i + 0.5), 0), Color = Color3.fromRGB(215, 180, 110), Material = Enum.Material.Sandstone })
	end
end

-- 화산 ---------------------------------------------------------------

function MapDecor.deadTree(pos: Vector3)
	local height = random:NextNumber(6, 9)
	local dark = Color3.fromRGB(40, 30, 30)
	part({ Size = Vector3.new(1.2, height, 1.2), Position = pos + Vector3.new(0, height / 2, 0), Color = dark, Material = Enum.Material.Wood })
	for _, s in { 1, -1 } do
		part({ Size = Vector3.new(0.6, 3.5, 0.6), CFrame = CFrame.new(pos + Vector3.new(s * 1, height * 0.75, 0)) * CFrame.Angles(0, 0, math.rad(-s * 40)), Color = dark, Material = Enum.Material.Wood })
	end
end

function MapDecor.fireVent(pos: Vector3)
	local stone = ball(pos + Vector3.new(0, 0.6, 0), 3, Color3.fromRGB(60, 50, 50), Enum.Material.Basalt, true)
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 12
	fire.Parent = stone
end

function MapDecor.lavaPool(pos: Vector3, radius: number)
	local pool = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, radius * 2, radius * 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Range = radius * 2
	light.Color = pool.Color
	light.Brightness = 2
	light.Parent = pool
end

-- 사탕 ---------------------------------------------------------------

local CANDY_COLORS = { Color3.fromRGB(255, 90, 160), Color3.fromRGB(120, 210, 255), Color3.fromRGB(255, 230, 90), Color3.fromRGB(170, 120, 255), Color3.fromRGB(120, 240, 160) }

function MapDecor.lollipop(pos: Vector3)
	local height = random:NextNumber(6, 10)
	part({ Size = Vector3.new(0.6, height, 0.6), Position = pos + Vector3.new(0, height / 2, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 5, 5), CFrame = CFrame.new(pos + Vector3.new(0, height + 2, 0)) * CFrame.Angles(0, math.rad(random:NextNumber(0, 180)), 0), Color = pick(CANDY_COLORS), Material = Enum.Material.SmoothPlastic, CanCollide = false })
end

function MapDecor.candyCane(pos: Vector3)
	for i = 0, 6 do
		part({ Size = Vector3.new(1, 1.2, 1), Position = pos + Vector3.new(0, 0.6 + i * 1.2, 0), Color = if i % 2 == 0 then Color3.fromRGB(230, 30, 50) else Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic })
	end
	part({ Size = Vector3.new(2.5, 1, 1), Position = pos + Vector3.new(0.8, 8.8, 0), Color = Color3.fromRGB(230, 30, 50), Material = Enum.Material.SmoothPlastic })
end

function MapDecor.gumdrop(pos: Vector3)
	local size = random:NextNumber(3, 5)
	ball(pos + Vector3.new(0, size * 0.3, 0), size, pick(CANDY_COLORS), Enum.Material.Glass, true).Transparency = 0.15
end

MapDecor.CANDY_COLORS = CANDY_COLORS

return MapDecor
