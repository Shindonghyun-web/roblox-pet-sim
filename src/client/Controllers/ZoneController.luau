-- ZoneController: 내가 어느 구역에 있는지 보고, 구역에 들어가면 이름을 알려 주고 그 구역 분위기로 조명을 바꾼다.
-- 의존: HUDController, Config
-- 조명은 내 화면에서만 바뀐다. (보기만 하는 연출이라 서버가 할 필요가 없다)
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local ZoneController = {}

local HUDController -- Init에서 연결

local currentZoneId: number? = nil

-- 캐릭터 위치가 들어 있는 구역 번호를 돌려준다. 다리 위나 공중이면 nil
local function findZone(position: Vector3): number?
	for zoneId, zone in Config.ZONES do
		local half = zone.areaSize / 2 + Vector3.new(zone.groundBorder, 0, zone.groundBorder)
		if math.abs(position.X - zone.areaCenter.X) <= half.X and math.abs(position.Z - zone.areaCenter.Z) <= half.Z then
			return zoneId
		end
	end
	return nil
end

-- 그 구역의 조명으로 천천히 바꾼다.
local function applyLighting(zone, instant: boolean)
	local settings = zone.lighting
	if not settings then
		return
	end
	local goal = {
		Ambient = settings.ambient,
		OutdoorAmbient = settings.ambient,
		FogColor = settings.fogColor,
		FogEnd = settings.fogEnd,
		ClockTime = settings.clockTime,
	}
	if instant then
		for property, value in goal do
			Lighting[property] = value
		end
	else
		TweenService:Create(Lighting, TweenInfo.new(Config.LIGHTING_TWEEN_TIME), goal):Play()
	end
end

local function checkZone()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local zoneId = findZone(root.Position)
	-- 다리 위(nil)에서는 이전 구역 분위기를 그대로 둔다.
	if not zoneId or zoneId == currentZoneId then
		return
	end
	local isFirst = currentZoneId == nil
	currentZoneId = zoneId

	local zone = Config.ZONES[zoneId]
	applyLighting(zone, isFirst)
	if not isFirst then
		HUDController.ShowMessage(`{zone.name}에 왔어요! (추천 파워 {zone.recommendedPower}+)`, zone.accent)
	end
end

-- 준비 단계: 다른 모듈을 연결만 한다.
function ZoneController.Init(controllers)
	HUDController = controllers.HUDController
end

-- 시작 단계: ZONE_CHECK_INTERVAL마다 내 위치의 구역을 확인한다.
function ZoneController.Start()
	task.spawn(function()
		while true do
			checkZone()
			task.wait(Config.ZONE_CHECK_INTERVAL)
		end
	end)
	print("[ZoneController] 준비 완료")
end

return ZoneController
