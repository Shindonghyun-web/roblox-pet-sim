-- Config: 게임의 모든 숫자 설정값을 모아 둔다. 서버와 클라이언트가 같이 읽는다.
-- 의존: 없음
-- 밸런스(가격, 확률, 속도)를 바꿀 때는 이 파일만 고친다.
local Config = {}

Config.AUTO_SAVE_INTERVAL = 60 -- 자동 저장 간격 (초)
Config.SAVE_RETRY_COUNT = 3 -- 저장/불러오기 실패 시 다시 시도하는 최대 횟수 (번)
Config.SAVE_RETRY_WAIT = 1 -- 다시 시도하기 전에 기다리는 시간 (초)
Config.REMOTE_COOLDOWN = 0.2 -- 같은 플레이어가 Remote를 다시 보낼 수 있는 최소 간격 (초)

-- 게임별 값은 아래에 추가한다. 예:
-- Config.COIN_RESPAWN_TIME = 5 -- 코인이 다시 생기는 시간 (초)

return Config
