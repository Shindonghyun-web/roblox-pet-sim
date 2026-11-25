# CLAUDE.md — 로블록스(Luau) 프로젝트 규칙

이 파일은 이 프로젝트에서 코드를 작성하는 AI가 **매번 작업 전에 읽고 반드시 지키는 규칙**입니다.
게임 장르와 상관없이 적용됩니다. 게임 내용(무엇을 만드는지)은 `02_PRD.md`에 있고, 이 파일은 "어떻게 만드는지"를 정합니다.

## 0. 이 프로젝트의 개발자에 대해

- 개발자는 코딩을 처음 배우는 **초보자**입니다. 설명은 쉬운 한국어로, 전문 용어는 처음 나올 때 한 줄로 풀어서 설명하세요.
- 개발자는 Roblox Studio에서 직접 스크립트를 만들고 코드를 붙여넣습니다. 그래서 코드를 줄 때마다 **어느 서비스, 어느 폴더에, 어떤 종류(Script / LocalScript / ModuleScript)로, 어떤 이름으로** 만들어야 하는지 반드시 먼저 알려주세요.
- 파일 하나를 고칠 때는 일부 조각이 아니라 **그 파일의 전체 코드**를 주세요. 초보자가 어디에 끼워 넣어야 할지 헷갈리지 않게 하기 위해서입니다.

## 1. 가장 중요한 원칙 5가지

1. **한 파일은 한 가지 일만 한다.** (코인 담당, 상점 담당, 저장 담당처럼 나눈다)
2. **중요한 값은 서버만 바꾼다.** 돈, 아이템, 점수, 레벨, 구매 결과는 서버에서만 계산하고 바꾼다. 클라이언트는 "요청"을 보내고 "화면"만 그린다.
3. **클라이언트와 서버는 정해진 Remote로만 대화한다.** 서버는 받은 요청을 절대 믿지 말고 항상 검사한다.
4. **숫자 설정값은 `Config` 한곳에 모은다.** 가격, 속도, 확률, 쿨타임을 코드 안에 직접 쓰지 않는다.
5. **저장은 `DataService` 하나만 한다.** 다른 파일은 DataStore를 직접 건드리지 않는다.

## 2. 폴더 구조

모든 스크립트는 아래 위치에만 둡니다. 새 위치가 필요하면 만들기 전에 개발자에게 먼저 물어보세요.

```
ServerScriptService/
  ServerMain            (Script)        서버 시작점. Services 폴더의 모듈을 순서대로 불러와 Init/Start만 호출
  Services/             (Folder)
    DataService         (ModuleScript)  저장/불러오기 전담
    ○○Service           (ModuleScript)  기능 하나당 하나 (예: CoinService, ShopService)

ReplicatedStorage/
  Shared/               (Folder)        서버와 클라이언트가 같이 쓰는 것
    Config              (ModuleScript)  모든 숫자 설정값
    ○○Util              (ModuleScript)  공용 계산 함수 (필요할 때만)
  Remotes/              (Folder)        RemoteEvent / RemoteFunction 전부 여기에

StarterPlayer/StarterPlayerScripts/
  ClientMain            (LocalScript)   클라이언트 시작점. Controllers 모듈을 불러와 Init/Start만 호출
  Controllers/          (Folder)
    ○○Controller        (ModuleScript)  입력 처리, 화면 갱신, 연출 (예: HUDController)

StarterGui/
  ○○Gui                 (ScreenGui)     화면 디자인만. 로직은 Controller에서 처리

ServerStorage/
  (서버만 보는 모델, 템플릿)

Workspace/
  (맵. 스크립트는 되도록 두지 않는다)
```

- `02_PRD.md`의 기술 설계 표에서 `○○Service (Script)`라고 적힌 것은 위 구조대로 **`Services` 폴더 안의 ModuleScript**로 만듭니다.
- Script와 LocalScript는 `ServerMain`, `ClientMain` 두 개만 두는 것을 기본으로 합니다. 나머지는 모두 ModuleScript입니다.

## 3. 모듈 작성 규칙

모든 Service와 Controller는 같은 모양을 따릅니다.

```lua
-- CoinService: 코인 생성과 획득 판정을 담당한다.
-- 의존: DataService, Config
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local CoinService = {}

local DataService -- Init에서 연결

-- 준비 단계: 다른 모듈을 연결만 한다. 여기서 게임을 시작하지 않는다.
function CoinService.Init(services)
	DataService = services.DataService
end

-- 시작 단계: 이벤트 연결, 반복 작업 시작
function CoinService.Start()
	-- ...
end

-- 다른 모듈이 쓸 수 있는 공개 함수
function CoinService.AddCoins(player: Player, amount: number)
	-- ...
end

return CoinService
```

- 파일 맨 위에 **이 모듈이 하는 일 한 줄**과 **의존하는 모듈 목록**을 주석으로 씁니다.
- 다른 모듈의 내부 변수를 직접 건드리지 않습니다. 공개 함수(`CoinService.AddCoins`)를 통해서만 부탁합니다.
- 모듈끼리 서로를 `require`하는 순환을 만들지 않습니다. 필요하면 `Init`에서 받은 `services`를 씁니다.
- 한 파일이 **300줄을 넘으면** 나눌 것을 개발자에게 제안합니다.
- `wait()`, `spawn()`, `delay()` 대신 `task.wait()`, `task.spawn()`, `task.delay()`를 씁니다.
- 서비스는 `game.Players`가 아니라 `game:GetService("Players")`로 가져옵니다.
- 오래된/폐기된 API(예: `Instance.new`의 두 번째 인자로 부모 지정)는 쓰지 않습니다.

## 4. 이름 규칙

| 대상 | 규칙 | 예시 |
|---|---|---|
| 모듈, 스크립트, 폴더 | PascalCase, 역할 접미사 | `ShopService`, `HUDController`, `MathUtil` |
| Remote | 동사로 시작하는 PascalCase | `BuyItem`, `EquipPet`, `DataChanged` |
| 지역 변수, 함수 인자 | camelCase | `coinAmount`, `targetPlayer` |
| 공개 함수 | PascalCase | `ShopService.BuyItem()` |
| 내부 함수 | camelCase, `local function` | `local function calculatePrice()` |
| 상수, Config 키 | UPPER_SNAKE_CASE | `MAX_EQUIPPED`, `EGG_PRICE` |

- 같은 것을 부르는 이름은 프로젝트 전체에서 하나로 통일합니다. (Coins / Money / Cash를 섞어 쓰지 않는다)

## 5. 서버와 클라이언트

- **서버가 결정하는 것:** 돈과 아이템 증감, 구매, 뽑기 확률, 데미지, 레벨업, 잠금 해제, 저장.
- **클라이언트가 하는 것:** 버튼 입력, 카메라, UI 표시, 효과음, 파티클, 보기만 하는 움직임(펫 따라다니기 등).
- 클라이언트가 "나 코인 10개 주웠어", "나 이거 샀어"처럼 **결과를 보고하는 구조는 금지**입니다. 클라이언트는 "이거 사고 싶어"라고 **요청**만 하고, 서버가 판단합니다.
- 닿기 판정(`Touched`), 시간 계산, 쿨타임은 가능하면 서버에서 합니다.

## 6. Remote 규칙

- 모든 Remote는 `ReplicatedStorage/Remotes` 폴더 안에, Studio에서 미리 만들어 둡니다. 코드에서 실행 중에 몰래 만들지 않습니다.
- Remote 이름과 용도는 `02_PRD.md`의 통신 표와 똑같이 맞춥니다. 새 Remote를 만들면 그 표에도 한 줄 추가합니다.
- 서버의 `OnServerEvent` / `OnServerInvoke`는 **항상 아래를 검사**합니다.
  1. 인자 타입이 맞는가 (`typeof(itemId) == "string"` 등)
  2. 그 값이 실제로 존재하는가 (`Config`에 있는 아이템 ID인가)
  3. 플레이어가 할 자격이 있는가 (돈이 충분한가, 그 아이템을 가졌는가, 가까이 있는가)
  4. 너무 자주 보내지 않는가 (플레이어별 쿨타임, 예: 0.2초)
- 검사에 실패하면 조용히 무시하거나 `false, "이유"`를 돌려주고, 서버를 멈추지 않습니다.
- 서버 → 클라이언트 방향은 RemoteEvent를 씁니다. 서버에서 `InvokeClient`는 쓰지 않습니다.

## 7. Config 규칙

- 가격, 확률, 속도, 개수 제한, 쿨타임, 아이템 목록은 전부 `ReplicatedStorage/Shared/Config`에 둡니다.
- 각 값 옆에 한국어 주석으로 의미와 단위를 씁니다.

```lua
local Config = {}

Config.MAX_EQUIPPED = 3        -- 동시에 장착할 수 있는 펫 수
Config.COIN_RESPAWN_TIME = 5   -- 코인이 다시 생기는 시간 (초)

Config.EGGS = {
	BasicEgg = { price = 100, zone = 1 }, -- 가격은 코인 단위
}

return Config
```

- 밸런스를 바꿔 달라는 요청은 **Config만 고치는 것**으로 끝나야 합니다. 코드 수정이 필요하다면 그 이유를 먼저 설명하세요.
- 비밀이어야 하는 값(서버 전용 확률 계산 등)은 `ServerStorage`에 별도 모듈로 둡니다.

## 8. 데이터 저장 규칙 (DataService)

- DataStore에 접근하는 코드는 **`DataService` 안에만** 있습니다. 다른 모듈은 `DataService.Get(player)`, `DataService.Update(player, ...)` 같은 공개 함수만 씁니다.
- 키는 `Player_<UserId>` 형식, 값은 테이블 하나로 저장합니다. 테이블에는 항상 `version` 필드를 둡니다.
- 기본 데이터 모양은 `DataService` 맨 위 `DEFAULT_DATA` 한곳에 정의합니다. 새 항목이 생기면 여기에 추가하고, 불러온 데이터에 없는 항목은 기본값으로 채웁니다.
- 모든 `GetAsync` / `SetAsync` / `UpdateAsync`는 `pcall`로 감싸고, 실패하면 잠깐 기다렸다가 **최대 3번** 다시 시도합니다. 저장에는 `UpdateAsync`를 우선 씁니다.
- **불러오기에 실패한 플레이어는 저장하지 않습니다.** (빈 데이터로 덮어써 날리는 사고 방지)
- `PlayerRemoving`, `game:BindToClose`, 그리고 주기적 자동 저장(예: 60초)에서 저장합니다.
- 데이터 모양을 바꾸면 `version`을 올리고, 옛 데이터를 새 모양으로 바꾸는 코드를 함께 씁니다. 기존 플레이어 데이터가 사라지는 변경은 **반드시 개발자에게 먼저 확인**받습니다.
- 유료 상품(Developer Product)은 `ProcessReceipt`에서 저장이 끝난 뒤에만 `PurchaseGranted`를 돌려줍니다.

## 9. 주석과 로그

- 주석은 **한국어**로, "무엇을 하는지"보다 **"왜 이렇게 하는지"**를 씁니다. 초보자가 읽고 이해할 수 있게 씁니다.
- 각 모듈은 시작할 때 `print("[CoinService] 준비 완료")`처럼 이름표를 붙인 로그를 한 번 출력합니다.
- 오류와 경고에도 이름표를 붙입니다: `warn("[DataService] 저장 실패:", err)`
- 디버그용 `print`를 남발하지 않습니다. 테스트가 끝난 임시 로그는 지웁니다.

## 10. 수정할 때의 규칙 (가장 자주 쓰임)

이 프로젝트의 목표는 **고장 난 부분, 바꾸고 싶은 부분만 골라서 고치는 것**입니다.

1. **요청받은 범위만 고칩니다.** 개발자가 파일을 지정하면 그 파일만 고칩니다. 다른 파일도 고쳐야 한다면 **고치기 전에** 어떤 파일을 왜 고쳐야 하는지 먼저 말하고 허락을 받습니다.
2. **잘 돌아가는 코드를 새로 갈아엎지 않습니다.** 더 좋은 방법이 보여도 요청이 없으면 제안만 하고 바꾸지 않습니다.
3. **이름을 함부로 바꾸지 않습니다.** 모듈, 함수, Remote, 데이터 키 이름을 바꾸면 다른 파일이 깨집니다. 꼭 필요하면 영향받는 파일 목록과 함께 먼저 제안합니다.
4. **작업 전에 계획을 먼저 말합니다.** 형식:
   - 고칠 파일: (위치와 이름)
   - 바꿀 내용: (한두 줄)
   - 영향받는 다른 부분: (없으면 "없음")
5. **오류를 고칠 때는 원인부터 설명합니다.** 개발자가 붙여준 Output 창 오류 메시지를 보고, 어느 파일 몇 번째 줄에서 왜 났는지 설명한 뒤 고칩니다. 추측이면 추측이라고 말합니다.
6. **작업 후에는 변경 요약을 줍니다.** 무엇을 바꿨는지, 개발자가 Studio에서 무엇을 확인하면 되는지(아래 11장).
7. `02_PRD.md`의 "범위 밖" 목록에 있는 기능은 요청이 없으면 만들지 않습니다.

## 11. 변경마다 확인할 체크리스트

AI는 작업을 끝낼 때마다 아래 형식으로 **개발자가 직접 해볼 테스트**를 알려줍니다.

```
✅ 확인 방법
1. Studio에서 Play(F5)를 누른다.
2. (구체적으로 해볼 행동)
3. (보여야 하는 결과)
4. Output 창(보기 → 출력)에 빨간 오류가 없는지 본다.
```

AI가 코드를 줄 때 스스로 점검할 것:
- [ ] 중요한 값을 클라이언트가 바꾸는 곳은 없는가?
- [ ] 새 Remote에 서버 검사(타입, 존재, 자격, 쿨타임)가 있는가?
- [ ] 숫자를 코드에 직접 쓰지 않고 Config에서 가져왔는가?
- [ ] DataStore를 DataService 밖에서 건드리지 않았는가?
- [ ] 요청받지 않은 파일이나 이름을 바꾸지 않았는가?
- [ ] 저장이 필요한 경우 저장 테스트 방법을 알려줬는가? (Stop 후 다시 Play)
- [ ] 여러 명 관련 기능이면 Test 탭 → 서버와 플레이어 2명으로 테스트하도록 알려줬는가?

## 12. PRD와 맞추기

- 게임 내용의 기준은 `02_PRD.md`입니다. 코드와 PRD가 다르면 **임의로 고르지 말고** 개발자에게 어느 쪽이 맞는지 물어봅니다.
- 다음이 바뀌면 작업 끝에 **PRD에서 고칠 부분을 문장으로 제안**합니다.
  - 새 Service / Controller / Remote 추가
  - Config의 주요 값(가격, 확률) 변경
  - 데이터 저장 모양 변경
  - 빌드 순서 단계 완료 (체크 표시)
- 빌드 순서의 한 단계가 끝나기 전에는 다음 단계 기능을 미리 만들지 않습니다.
- 작업을 시작할 때 `03_진행기록.md`를 읽고, 작업이 끝나면 그 파일에 적을 내용(한 일, 다음 할 일, 알려진 버그)을 제안합니다.
- 기능을 추가하면 `04_테스트체크리스트.md`에서 개발자가 확인할 항목을 골라 11장의 확인 방법에 함께 알려줍니다.

## 13. 하지 않는 것

- 외부 도구(Wally, 외부 라이브러리) 도입은 개발자가 요청할 때만. Rojo는 14장 규칙을 따릅니다.
- 무료 모델(Toolbox)의 스크립트를 그대로 쓰지 않습니다. 모델을 쓸 때는 안에 든 스크립트를 지우거나 확인하도록 안내합니다. (백도어 위험)
- `loadstring`, `require(숫자 ID)` 같은 외부 코드 불러오기는 쓰지 않습니다.
- 확률형 유료 상품, 개인정보, 채팅 필터처럼 로블록스 정책이 걸린 기능은 만들기 전에 "정책 확인이 필요하다"고 알립니다.

## 14. Rojo를 쓸 때 (default.project.json이 있으면)

프로젝트 폴더에 `default.project.json`이 있으면 코드는 Studio가 아니라 **`src` 폴더의 파일**로 관리합니다.

| 파일 위치 | Studio에 들어가는 곳 |
|---|---|
| `src/server/` | ServerScriptService |
| `src/shared/` | ReplicatedStorage/Shared |
| `src/serverstorage/` | ServerStorage/ServerOnly |
| `src/client/` | StarterPlayer/StarterPlayerScripts |

- 파일 이름 끝으로 스크립트 종류가 정해집니다: `이름.server.luau` = Script, `이름.client.luau` = LocalScript, `이름.luau` = ModuleScript.
  - 예: `src/server/ServerMain.server.luau`, `src/server/Services/DataService.luau`, `src/client/ClientMain.client.luau`, `src/shared/Config.luau`
- 코드 파일을 줄 때는 Studio 위치 대신 **`src` 안의 파일 경로**를 알려줍니다.
- Remote는 `default.project.json`의 `Remotes` 안에 한 줄씩 추가합니다. (`"BuyItem": { "$className": "RemoteFunction" }`) PRD 통신 표와 같게 맞춥니다.
- 맵, 모델, GUI 디자인은 Rojo로 관리하지 않고 Studio에서 직접 만듭니다. `src`에 연결된 위치(ServerScriptService 등)에 Studio에서 직접 넣은 것은 동기화 때 지워질 수 있으니, 그 위치에는 Studio에서 스크립트를 만들지 않도록 안내합니다.
- `default.project.json`의 구조를 바꾸는 것은 개발자에게 먼저 확인받습니다.
