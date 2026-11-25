-- ClientMain: 클라이언트 시작점. Controllers 폴더의 모듈을 불러와 Init → Start 순서로 호출만 한다.
-- 의존: Controllers 폴더 안의 모든 ModuleScript
local controllersFolder = script.Parent:WaitForChild("Controllers")

local controllers = {}
local order = {}

-- 이름순으로 불러온다. 새 컨트롤러를 만들어도 여기를 고칠 필요가 없다.
local children = controllersFolder:GetChildren()
table.sort(children, function(a, b)
	return a.Name < b.Name
end)

for _, child in children do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if ok then
			controllers[child.Name] = result
			table.insert(order, child.Name)
		else
			warn("[ClientMain] 불러오기 실패:", child.Name, result)
		end
	end
end

-- 모두 Init(연결만) 한 뒤 Start(실제 시작) 한다.
for _, name in order do
	local controller = controllers[name]
	if type(controller.Init) == "function" then
		local ok, err = pcall(controller.Init, controllers)
		if not ok then
			warn("[ClientMain] Init 실패:", name, err)
		end
	end
end

for _, name in order do
	local controller = controllers[name]
	if type(controller.Start) == "function" then
		task.spawn(function()
			local ok, err = pcall(controller.Start)
			if not ok then
				warn("[ClientMain] Start 실패:", name, err)
			end
		end)
	end
end

print("[ClientMain] 준비 완료")
