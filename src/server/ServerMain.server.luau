-- ServerMain: 서버 시작점. Services 폴더의 모듈을 불러와 Init → Start 순서로 호출만 한다.
-- 의존: Services 폴더 안의 모든 ModuleScript
local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")

-- DataService를 맨 앞에 두는 이유: 다른 서비스들이 Start에서 플레이어 데이터를 쓰기 때문이다.
local FIRST_SERVICES = { "DataService" }

local services = {}
local order = {}

local function loadService(moduleScript: ModuleScript)
	local ok, result = pcall(require, moduleScript)
	if ok then
		services[moduleScript.Name] = result
		table.insert(order, moduleScript.Name)
	else
		warn("[ServerMain] 불러오기 실패:", moduleScript.Name, result)
	end
end

-- 1) 먼저 와야 하는 서비스부터 불러온다.
for _, name in FIRST_SERVICES do
	local moduleScript = servicesFolder:FindFirstChild(name)
	if moduleScript and moduleScript:IsA("ModuleScript") then
		loadService(moduleScript)
	end
end

-- 2) 나머지 서비스는 이름순으로 불러온다. (새 서비스를 만들어도 여기를 고칠 필요가 없다)
local rest = {}
for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") and not table.find(FIRST_SERVICES, child.Name) then
		table.insert(rest, child)
	end
end
table.sort(rest, function(a, b)
	return a.Name < b.Name
end)
for _, moduleScript in rest do
	loadService(moduleScript)
end

-- 3) 모든 서비스를 먼저 Init(연결만) 한 뒤, 그다음 Start(실제 시작) 한다.
--    이렇게 나누면 Start 안에서 다른 서비스를 써도 이미 준비가 끝나 있다.
for _, name in order do
	local service = services[name]
	if type(service.Init) == "function" then
		local ok, err = pcall(service.Init, services)
		if not ok then
			warn("[ServerMain] Init 실패:", name, err)
		end
	end
end

for _, name in order do
	local service = services[name]
	if type(service.Start) == "function" then
		-- task.spawn: 한 서비스의 Start가 오래 걸려도 다른 서비스가 기다리지 않게 한다.
		task.spawn(function()
			local ok, err = pcall(service.Start)
			if not ok then
				warn("[ServerMain] Start 실패:", name, err)
			end
		end)
	end
end

print("[ServerMain] 준비 완료")
