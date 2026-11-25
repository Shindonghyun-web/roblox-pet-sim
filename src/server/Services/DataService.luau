-- DataService: 플레이어 데이터 저장/불러오기를 전담한다. DataStore는 이 파일에서만 쓴다.
-- 의존: Config
-- 지금은 빌드 순서 1단계(뼈대)용 빈 모양이다. 실제 저장 코드는 2단계(저장)에서 AI가 채운다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

-- 기본 데이터 모양. 새 항목은 여기에만 추가한다. (02_PRD.md 5-3 저장 데이터 모양과 같게 유지)
local DEFAULT_DATA = {
	version = 1,
}

-- 준비 단계: 다른 모듈을 연결만 한다.
function DataService.Init(_services)
end

-- 시작 단계: 2단계에서 PlayerAdded / PlayerRemoving / BindToClose / 자동 저장을 연결한다.
function DataService.Start()
	print("[DataService] 준비 완료")
end

-- 다른 모듈이 플레이어 데이터를 읽을 때 쓰는 공개 함수 (2단계에서 구현)
function DataService.Get(_player: Player)
	return nil
end

-- 사용하지 않는 값 경고를 막기 위한 줄. 2단계에서 실제로 쓰게 되면 지운다.
local _ = Config
local _ = DEFAULT_DATA

return DataService
