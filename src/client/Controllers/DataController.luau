-- DataController: 서버가 DataChanged로 보내 준 내 데이터를 한곳에 모아 두고, 바뀌면 다른 컨트롤러에게 알려 준다.
-- 의존: Remotes(DataChanged)
-- 왜 필요한가: 서버가 보낸 이벤트는 "처음 연결한 한 곳"에만 쌓였다가 전달된다.
-- 여러 컨트롤러가 각자 DataChanged를 받으면 접속 직후 값을 놓칠 수 있어서, 여기서 한 번만 받고 나눠 준다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DataChanged = Remotes:WaitForChild("DataChanged")

local DataController = {}

local values = {} -- [key] = 서버가 마지막으로 보내 준 값 (예: values.coins = 120)
local listeners = {} -- [key] = { callback, ... }

-- 준비 단계: 다른 모듈을 연결만 한다.
function DataController.Init(_controllers) end

-- 시작 단계: 서버가 보내는 데이터를 받기 시작한다.
function DataController.Start()
	DataChanged.OnClientEvent:Connect(function(key, value)
		values[key] = value
		for _, callback in listeners[key] or {} do
			task.spawn(callback, value)
		end
	end)
	print("[DataController] 준비 완료")
end

-- 마지막으로 받은 값을 돌려준다. 아직 못 받았으면 nil이다.
function DataController.Get(key: string)
	return values[key]
end

-- key 값이 바뀔 때마다 callback(새 값)을 불러 준다. 이미 받은 값이 있으면 바로 한 번 불러 준다.
function DataController.OnChanged(key: string, callback: (value: any) -> ())
	listeners[key] = listeners[key] or {}
	table.insert(listeners[key], callback)
	if values[key] ~= nil then
		task.spawn(callback, values[key])
	end
end

return DataController
