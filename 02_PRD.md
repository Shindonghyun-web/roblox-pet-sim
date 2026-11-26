# PRD — 펫 보물 탐험대 (Pet Treasure Crew)

> **사용법:** AI에게 "CLAUDE.md와 02_PRD.md를 읽고 빌드 순서 N단계만 만들어줘"처럼 한 단계씩 요청하세요. 빈칸이 남아 있으면 AI는 추측하지 말고 먼저 물어봐야 합니다.

- 마지막 수정일: 2026-11-25
- 규칙 파일: `CLAUDE.md` (이 문서는 **무엇을** 만드는지, CLAUDE.md는 **어떻게** 만드는지)

---

## 0. 아직 정하지 못한 것

아래 숫자와 이름은 AI가 **초보자용 기본값으로 제안한 것**입니다. 해 보고 바꾸고 싶으면 `Config`만 고치면 됩니다. 확정되면 `[x]`로 바꾸세요.

- [ ] 4장 밸런스 숫자 전체 (알 가격, 펫 확률, 보물 체력/보상) — 기본값 제안 상태
- [ ] 펫 이름과 종류 (지금은 Dog, Cat, Bunny, Dragon / Fox, Owl, Deer, Unicorn)
- [ ] 큰 보물상자 보상을 "기여도 비율로 나누기"로 할지 "기여한 사람 모두 같은 양"으로 할지 — 지금은 기여도 비율 + 협동 보너스
- [ ] 펫 지우기(인벤토리가 꽉 찼을 때) 기능을 MVP에 넣을지
- [ ] 게임 이름 확정

---

## 1. 게임 개요와 목표

**한 줄 소개:** 펫과 함께 보물을 캐서 코인을 모으고, 알을 부화해 더 강한 펫을 얻고, 친구들과 힘을 합쳐 거대한 보물상자를 여는 협동 수집 게임

| 항목 | 내용 |
| --- | --- |
| 가제목 | 펫 보물 탐험대 (Pet Treasure Crew) |
| 장르 | 시뮬레이터 (펫 수집) |
| 참고 게임 | 로블록스의 펫 수집 시뮬레이터 장르 전반 — "보물을 클릭하면 펫이 캐러 간다", "알 부화 연출"이라는 장르 공통 구조만 참고. 이름, 그림, 맵은 전부 직접 만든다. |
| 서버 인원 | 최대 6명, 협동 (진행은 각자 저장, 큰 보물상자는 같이 캔다) |
| 플랫폼 | Roblox (PC, 모바일 우선 대응) |
| 개발 방식 | 1인 개발, Roblox Studio + AI 코딩 도구로 Luau 작성 (Rojo 사용) |

**목표**

1. 빌드 순서 1~7단계를 끝내 친구와 같이 플레이할 수 있는 MVP를 만든다.
2. 처음 온 플레이어가 3분 안에 첫 알을 부화한다.
3. 연습용이라 MVP에서는 수익 목표 없음.

---

## 2. 타깃 플레이어

- **나이대:** 9~14세
- **주 기기:** 모바일 → 버튼은 크게, 보물은 터치 한 번으로 선택
- **플레이 시간:** 한 번에 10~20분
- **원하는 것:** 코인 숫자가 커지는 성장감, 레전더리 펫이 나올지도 모르는 설렘, 친구와 같이 큰 상자를 여는 재미
- **피해야 할 것:** 긴 글 설명, 복잡한 조작, 혼자서는 절대 못 하는 구간

---

## 3. 코어 루프

1. **보물 캐기:** 보물(코인 더미, 상자)을 클릭하면 내 펫들이 그 보물을 캔다. 체력이 0이 되면 코인을 받는다.
2. **알 부화:** 코인으로 알을 사서 펫을 뽑는다.
3. **펫 장착:** 강한 펫을 장착하면 캐는 힘(파워)이 세진다.
4. **다음 구역으로:** 모든 구역은 처음부터 열려 있지만, 뒤 구역 보물은 체력이 매우 높아서 강한 펫이 있어야 빨리 깰 수 있다. 다음 구역 알로 더 강한 펫을 얻는다. → 1번으로 (2026-11-25 변경: 문을 사서 여는 방식 → 체력으로 막는 방식)

- **협동 포인트:** 구역마다 가끔 **큰 보물상자**가 나타난다. 체력이 매우 높아서 여러 명이 같이 캐야 빨리 열리고, 기여한 사람 모두 보상 + 협동 보너스를 받는다.
- **한 바퀴 걸리는 시간:** 3~5분 (알 1개 살 코인을 모으는 시간)
- **"한 판만 더" 하게 만드는 순간:** 부화 연출에서 레전더리 펫이 나올지도 모르는 순간, 큰 보물상자가 등장했다는 알림

---

## 4. 기능 목록과 우선순위

| 우선순위 | 기능 | 완료 기준 (Play로 확인할 수 있는 결과) |
| --- | --- | --- |
| MVP | 데이터 저장 | 코인, 펫, 장착, 열린 구역이 Stop → 다시 Play해도 그대로 남는다 |
| MVP | 보물 캐기 | 보물을 클릭하면 1초마다 보물 체력이 내 파워만큼 줄고, 0이 되면 코인이 오르고 보물이 사라졌다가 5초 뒤 다시 생긴다. 펫이 없어도 기본 파워 1로 캘 수 있다. 60스터드보다 멀어지면 캐기가 멈춘다. |
| MVP | 큰 보물상자 (협동) | 2명이 같이 캐면 혼자보다 빨리 열리고, 둘 다 기여도에 맞는 코인 + 20% 보너스를 받는다. 한 번도 안 때린 사람은 받지 않는다. |
| MVP | HUD | 화면 위에 내 코인이 보이고, 코인이 바뀌면 바로 숫자가 바뀐다. 보물 위에 체력 바가 보인다. |
| MVP | 알 부화 | 알 앞에서 버튼을 누르면 100코인이 줄고 펫 1마리가 생긴다. 99코인이면 구매되지 않고 "코인이 부족해요"가 뜬다. 인벤토리가 50마리면 구매되지 않는다. |
| MVP | 펫 장착 | 인벤토리에서 펫을 누르면 장착/해제된다. 최대 3마리. 장착한 펫이 나를 따라다니고, 파워가 펫 파워의 합으로 바뀐다. |
| MVP | 구역 단계 | 6개 구역 모두 다리로 걸어갈 수 있다. 펫 없이 숲 보물(체력 150)은 오래 걸리고, 숲 펫 3마리면 약 5초에 깨진다. 구역에 들어가면 이름 알림과 조명/안개가 바뀐다. |
| 완료 | 펫 지우기, 알 3개 사기, 일일 보상, 광장 순위판, 펫 모양, 맵 꾸미기 | 업그레이드 1 (2026-11-25) |
| 이후 | 게임패스(코인 2배), 효과음 | — |

**밸런스 숫자** (전부 `Config`로 들어갑니다 — 0장에 적었듯 기본값 제안 상태)

| 이름 (Config 키) | 값 | 단위 / 의미 |
| --- | --- | --- |
| `BASE_POWER` | 1 | 펫이 하나도 없을 때 1초당 캐는 힘 |
| `MINE_INTERVAL` | 1 | 보물 데미지를 주는 간격 (초) |
| `MINE_MAX_DISTANCE` | 60 | 이보다 멀어지면 캐기가 멈추는 거리 (스터드) |
| `TREASURE_RESPAWN_TIME` | 5 | 보물이 사라진 뒤 다시 생기는 시간 (초) |
| `MAX_TREASURES_PER_ZONE` | 15 | 구역 하나에 동시에 있는 일반 보물 수 |
| `BIG_CHEST_INTERVAL` | 120 | 큰 보물상자가 나타나는 간격 (초) |
| `CO_OP_BONUS` | 0.2 | 2명 이상이 같이 열면 보상에 더하는 비율 (0.2 = 20%) |
| `MAX_EQUIPPED` | 3 | 동시에 장착할 수 있는 펫 수 |
| `MAX_PETS` | 50 | 인벤토리 최대 펫 수 |
| `REMOTE_COOLDOWN` | 0.2 | 같은 요청을 다시 보낼 수 있는 최소 간격 (초) |
| `EGG_MAX_DISTANCE` | 15 | 알을 살 수 있는 거리 (스터드) |

**보물 종류** (`Config.TREASURES`)

| ID | 구역 | 체력 | 보상 (코인) |
| --- | --- | --- | --- |
| `CoinPile` | 1 | 10 | 5 |
| `Chest` | 1 | 60 | 40 |
| `BigChest` | 1 | 1,500 | 1,200 (기여도 비율로 나눔) |
| `ForestCoinPile` | 2 | 150 | 80 |
| `ForestChest` | 2 | 800 | 500 |
| `ForestBigChest` | 2 | 20,000 | 15,000 (기여도 비율로 나눔) |
| 구역 3~6 | 3~6 | 코인 더미 2,000 / 15,000 / 120,000 / 900,000 | 900 / 6,000 / 45,000 / 330,000 (상자·큰 상자는 Config 참고) |

- 체력 기준: 그 구역 일반 펫 3마리로 코인 더미가 약 5초, 앞 구역 펫으로는 약 40초 이상

**알과 펫** (`Config.EGGS`, `Config.PETS`) — 유료가 아닌 코인 뽑기입니다. 각 알: 일반 60% / 일반 30% / 희귀 9% / 레전더리 1%

| 알 | 구역 | 가격 | 나오는 펫 (파워) |
| --- | --- | --- | --- |
| `BasicEgg` | 1 시작 마을 | 100 | 강아지 2 / 고양이 3 / 토끼 6 / 드래곤 20 |
| `ForestEgg` | 2 숲 | 1,500 | 여우 15 / 부엉이 20 / 사슴 45 / 유니콘 150 |
| `IceEgg` | 3 얼음 왕국 | 15,000 | 펭귄 120 / 물개 160 / 북극곰 350 / 얼음 드래곤 1,200 |
| `DesertEgg` | 4 사막 오아시스 | 150,000 | 낙타 900 / 전갈 1,200 / 사막여우 2,600 / 모래 드래곤 9,000 |
| `VolcanoEgg` | 5 화산 | 1,500,000 | 불도롱뇽 7,000 / 용암 골렘 9,500 / 불새 20,000 / 용암 드래곤 70,000 |
| `CandyEgg` | 6 사탕 나라 | 12,000,000 | 곰젤리 55,000 / 솜사탕 토끼 75,000 / 케이크 고양이 160,000 / 사탕 드래곤 550,000 |

- 구역 위치, 컨셉, 추천 파워는 `05_기능위치.md`의 "구역" 표 참고

---

## 5. 로블록스 기술 설계

핵심 원칙: **돈, 아이템, 점수, 구매 결과 같은 중요한 값은 서버만 바꾼다.** 클라이언트는 "요청"만 보내고 화면만 그린다. 자세한 규칙은 `CLAUDE.md` 1~8장을 따릅니다.

### 5-1. 모듈 목록

| Studio 위치 | 이름 (종류) | Rojo 파일 경로 | 역할 |
| --- | --- | --- | --- |
| ServerScriptService | `ServerMain` (Script) | `src/server/ServerMain.server.luau` | 서비스들을 불러와 Init/Start 호출 |
| ServerScriptService/Services | `DataService` (ModuleScript) | `src/server/Services/DataService.luau` | 저장/불러오기 전담 |
| ServerScriptService/Services | `CoinService` (ModuleScript) | `src/server/Services/CoinService.luau` | 코인 더하기/빼기, `DataChanged` 알림, leaderstats 표시 |
| ServerScriptService/Services | `TreasureService` (ModuleScript) | `src/server/Services/TreasureService.luau` | 보물 생성/재생성, 클릭으로 목표 정하기, 1초마다 데미지, 기여도 계산과 보상 |
| ServerScriptService/Services | `PetService` (ModuleScript) | `src/server/Services/PetService.luau` | 펫 받기, 장착/해제/지우기, 플레이어 파워 계산 |
| ServerScriptService/Services | `EggService` (ModuleScript) | `src/server/Services/EggService.luau` | 알 받침대, 알 구매(1개/3개)와 확률 뽑기 |
| ServerStorage/ServerOnly | `MapDecor` (ModuleScript) | `src/serverstorage/MapDecor.luau` | 장식 모양 만드는 함수 모음 (MapService가 씀) |
| ServerStorage/ServerOnly | `MapThemes` (ModuleScript) | `src/serverstorage/MapThemes.luau` | 구역 컨셉별 장식 종류와 개수 표 |
| ServerScriptService/Services | `MapService` (ModuleScript) | `src/server/Services/MapService.luau` | 구역 땅, 다리, 시작 광장, 나무/장식, 표지판, 시작 위치 (땅 밖은 낭떠러지) |
| ServerScriptService/Services | `DailyRewardService` (ModuleScript) | `src/server/Services/DailyRewardService.luau` | 하루 한 번 일일 보상 |
| ServerScriptService/Services | `LeaderboardService` (ModuleScript) | `src/server/Services/LeaderboardService.luau` | 광장 순위판 (서버 안 코인 순위) |
| ReplicatedStorage/Shared | `Config` (ModuleScript) | `src/shared/Config.luau` | 모든 숫자 설정값 |
| StarterPlayerScripts | `ClientMain` (LocalScript) | `src/client/ClientMain.client.luau` | 컨트롤러들을 불러와 Init/Start 호출 |
| StarterPlayerScripts/Controllers | `DataController` (ModuleScript) | `src/client/Controllers/DataController.luau` | `DataChanged`를 한 곳에서 받아 다른 컨트롤러에 나눠 줌 |
| StarterPlayerScripts/Controllers | `HUDController` (ModuleScript) | `src/client/Controllers/HUDController.luau` | 화면 위 코인 표시, 알림 문구, 첫 플레이 안내 |
| StarterPlayerScripts/Controllers | `DailyRewardController` (ModuleScript) | `src/client/Controllers/DailyRewardController.luau` | 오른쪽 일일 보상 버튼과 남은 시간 |
| StarterPlayerScripts/Controllers | `TreasureController` (ModuleScript) | `src/client/Controllers/TreasureController.luau` | 보물 체력 바 표시 (보물의 `HP` 속성을 읽어서 그리기만) |
| StarterPlayerScripts/Controllers | `EggController` (ModuleScript) | `src/client/Controllers/EggController.luau` | 알 구매 버튼, 부화 연출 |
| StarterPlayerScripts/Controllers | `InventoryController` (ModuleScript) | `src/client/Controllers/InventoryController.luau` | 펫 목록 UI, 장착/해제 요청 |
| StarterPlayerScripts/Controllers | `PetFollowController` (ModuleScript) | `src/client/Controllers/PetFollowController.luau` | 장착한 펫이 플레이어를 따라다니는 연출 (보기만) |
| StarterPlayerScripts/Controllers | `ZoneController` (ModuleScript) | `src/client/Controllers/ZoneController.luau` | 구역에 들어가면 이름 알림, 구역별 조명/안개 |
| (PlayerGui) | `HUDGui`, `InventoryGui`, `HatchGui`, `DailyRewardGui` (ScreenGui) | 각 Controller가 코드로 생성 | 화면. Studio에서 만들지 않음 (`CLAUDE.md` 2장) |

- 기능별 정확한 파일/함수 위치는 `05_기능위치.md`에 있다.

- 보물을 고르는 것은 **서버 쪽 ClickDetector**로 처리한다. 서버가 누가 클릭했는지 직접 알 수 있으므로 Remote가 필요 없다.
- 보물 체력은 보물 파트의 `HP`, `MaxHP` 속성(Attribute)에 서버가 써 두면 클라이언트에 자동으로 보인다.

### 5-2. 통신 (Remotes)

| 이름 | 종류 | 방향 | 서버가 확인할 것 |
| --- | --- | --- | --- |
| `DataChanged` | RemoteEvent | 서버 → 클라 | (서버가 보내는 쪽) 바뀐 데이터를 UI에 반영 |
| `Notify` | RemoteEvent | 서버 → 클라 | (서버가 보내는 쪽) "큰 보물상자 등장!", "+40 코인" 같은 알림 문구 |
| `BuyEgg` | RemoteFunction | 클라 → 서버 | eggId(문자열)와 개수(숫자)인지, `Config.EGGS`에 있는지, 개수가 1 또는 `EGG_MULTI_AMOUNT`인지, 그 구역이 열렸는지, 알 근처인지, 코인이 충분한지, 펫 자리가 남는지, 쿨타임 |
| `EquipPet` | RemoteFunction | 클라 → 서버 | petUid가 문자열인지, 그 펫을 가졌는지, 이미 장착했는지, `MAX_EQUIPPED` 미만인지, 쿨타임 |
| `UnequipPet` | RemoteFunction | 클라 → 서버 | petUid가 문자열인지, 장착 중인지, 쿨타임 |
| `DeletePet` | RemoteFunction | 클라 → 서버 | petUid가 문자열인지, 그 펫을 가졌는지, 장착 중이 아닌지, 쿨타임 |
| `ClaimDaily` | RemoteFunction | 클라 → 서버 | (인자 없음) 서버 시계로 `DAILY_COOLDOWN`이 지났는지, 쿨타임 |

> 보물 캐기와 보상은 서버가 ClickDetector와 타이머로 직접 처리하므로 Remote를 만들지 않습니다.

### 5-3. 저장 데이터 모양

```lua
DEFAULT_DATA = {
	version = 2,        -- 1 → 2: lastDaily 추가 (기존 데이터는 그대로 유지)
	lastDaily = 0,      -- 마지막 일일 보상 시각 (os.time)
	coins = 0,
	pets = {},          -- { { uid = "1", id = "Dog" }, ... }  uid는 펫마다 다른 번호
	equipped = {},      -- { "1", "3" }  장착한 펫의 uid 목록
	zones = { 1 },      -- 열린 구역 번호 목록
	nextPetUid = 1,     -- 다음에 줄 펫 uid
}
```

- 키: `Player_<UserId>` / 저장 시점: 나갈 때, 서버 종료 시, 60초마다 (`CLAUDE.md` 8장)
- Studio 테스트: Game Settings → Security → "Enable Studio Access to API Services" 켜기

### 5-4. 성능과 모바일

- 동시에 존재하는 보물 수: 구역당 일반 보물 최대 15개 + 큰 보물상자 1개
- 펫 따라다니기, 보물 체력 바는 클라이언트에서 처리
- 펫 모델은 기본 파트(몸통 공 + 눈 + 귀/날개/뿔 등 장식)를 코드로 조립한다
- UI는 Scale 단위로 배치해 폰과 PC 모두에서 깨지지 않게

### 5-5. 맵 (MapService가 코드로 제작)

- `Workspace/Map/Ground`: 공중에 뜬 구역 땅, 다리, 광장 (보물은 이 땅 위에만 놓인다). 땅 밖으로 나가면 떨어져서 시작 광장에서 다시 태어난다. 원래 Baseplate는 실행 중에 숨겨진다.
- `Workspace/Map/Decor`: 나무, 꽃, 바위, 버섯, 얼음 수정, 눈사람, 가로등, 표지판 (클릭을 가리지 않음)
- 시작 광장 (`SPAWN_POSITION`)에서 시작한다. 원래 있던 SpawnLocation은 실행 중에 꺼지고 숨겨진다.
- 구역은 번호 순서대로 다리로 이어지고, 다리 끝에 구역 이름 + 추천 파워 아치가 선다. 벽과 문은 없다. (2026-11-25 `ZoneService`, `UnlockZone` 삭제)
- 구역마다 `theme`(village/forest/ice/desert/volcano/candy)에 맞는 장식을 `MapThemes`(무엇을 몇 개) + `MapDecor`(모양)로 놓는다.
- 배치도는 `05_기능위치.md`의 "맵 배치" 참고

---

## 6. 수익화

MVP에서는 없음. 이후 후보: 코인 2배 게임패스.

**구현 규칙 (모든 게임 공통)**

- 게임패스: 접속 시 `MarketplaceService:UserOwnsGamePassAsync`로 확인, 게임 안에서 산 경우 `PromptGamePassPurchaseFinished`로 바로 적용
- Developer Product: `ProcessReceipt`에서 저장이 끝난 뒤에만 `PurchaseGranted` 반환 (중복/미지급 방지)
- 확률형 유료 상품(로벅스로 알 사기)은 로블록스 정책상 확률 표시 등 확인이 필요합니다. MVP의 알은 **게임 코인으로만** 사므로 해당하지 않습니다.

---

## 7. 성공 기준

출시 후 2주 동안 Creator Hub의 Analytics에서 봅니다.

| 지표 | 목표 | 의미 |
| --- | --- | --- |
| 첫 알 부화까지 걸리는 시간 | 3분 이내 | 초반이 지루하지 않은가 |
| 평균 플레이 시간 | 10분 이상 | 코어 루프가 재미있는가 |
| D1 재방문율 | 10% 이상 | 다음 날 다시 오고 싶은가 |
| 데이터 유실 제보 | 0건 | 저장이 믿을 만한가 |
| 큰 보물상자를 2명 이상이 연 비율 | 50% 이상 | 협동이 실제로 일어나는가 |

---

## 8. 범위 밖 (MVP에서 하지 않음)

- 플레이어 간 트레이드
- PvP, 전투
- 펫 합성/골드 펫, 리버스(환생)
- 게임패스, Developer Product
- 직접 만든 3D 모델과 애니메이션 (기본 파트나 확인된 모델로 대체)
- 다국어 지원 (처음에는 한국어만)
- 서버 간 이벤트, 글로벌 리더보드

---

## 9. 바이브코딩 빌드 순서

**한 번에 한 단계만** AI에게 맡기고, 단계마다 Studio에서 Play로 "확인"을 직접 테스트한 뒤 체크하고 다음으로 넘어갑니다.

> 1~8단계는 2026-11-25에 완료하고 개발자가 Play로 확인했다. (효과음은 아직 없음)

- [x] **1단계 뼈대:** 5-1의 서버 모듈/컨트롤러를 빈 상태로 만들고 `Config`, Remotes, `ServerMain`/`ClientMain`을 연결한다.
    - 확인: Output에 오류가 없고, 모든 모듈이 `[이름] 준비 완료`를 출력한다.
- [x] **2단계 저장:** `DataService`로 `DEFAULT_DATA`를 불러오고 저장한다. `CoinService`가 leaderstats에 코인을 보여준다.
    - 확인: Config의 `STUDIO_TEST_COINS`를 50으로 두고 플레이 → 중지 → 플레이 했을 때 코인이 50 → 100이 된다.
- [x] **3단계 보물 캐기:** `TreasureService`로 구역 1에 보물을 만들고, 클릭 → 1초마다 데미지 → 코인 보상 → 5초 뒤 재생성. 큰 보물상자와 기여도 보상 포함.
    - 확인: 펫 없이 `CoinPile`을 클릭하면 10초 뒤 leaderstats 코인이 5 오른다. Test 탭 → 플레이어 2명으로 큰 보물상자를 같이 캐면 둘 다 코인을 받는다.
- [x] **4단계 화면:** `HUDGui` + `HUDController`(코인 표시, `DataChanged`, `Notify`), `TreasureController`(체력 바).
    - 확인: 보물을 캐면 화면 위 코인 숫자가 바로 바뀐다. 폰 화면 에뮬레이터에서도 글자가 잘리지 않는다.
- [x] **5단계 알 부화:** `PetService`의 `BuyEgg`, `EggController`와 `HatchGui` 부화 연출.
    - 확인: 100코인 이상일 때 알을 사면 코인이 100 줄고 펫 이름이 뜬다. 99코인이면 "코인이 부족해요"가 뜨고 코인이 그대로다.
- [x] **6단계 펫 장착:** `EquipPet`/`UnequipPet`, `InventoryGui` + `InventoryController`, `PetFollowController`, 파워를 보물 캐기에 반영.
    - 확인: 펫을 장착하면 따라다니고 보물이 더 빨리 깨진다. 4마리째는 장착되지 않는다. Stop → Play 후에도 장착이 유지된다.
- [x] **7단계 구역 해제:** `ZoneService`의 `UnlockZone`, 구역 2 보물과 `ForestEgg`, `ZoneController`. (이후 업그레이드 2에서 잠금 방식은 없앰)
    - 확인: 2,500코인으로 문을 열면 지나갈 수 있고, 다시 접속해도 열려 있다. 코인이 부족하면 열리지 않는다.
- [x] **8단계 다듬기:** 보물 깨질 때 파티클, 큰 보물상자 등장 알림, 첫 플레이 안내 문구 (효과음은 아직 없음)
    - 확인: 처음 하는 친구가 설명 없이 3분 안에 첫 알을 부화한다.
- [x] **업그레이드 1 (2026-11-25 완료, 개발자 Play 확인):** 맵 꾸미기와 시작 광장, 알 3개 사기, 펫 지우기, 펫 모양, 일일 보상, 광장 순위판, 구역 3 얼음 왕국
    - 확인: 05_기능위치.md의 기능 목록대로 플레이해 본다.
- [ ] **업그레이드 2 (2026-11-25 작성, 테스트 전):** 구역 6개(사막, 화산, 사탕 추가), 구역별 컨셉(장식, 보물 재질, 조명/안개, 입장 알림), 잠금 없애고 보물 체력으로 단계
    - 확인: 05_기능위치.md의 "구역" 표대로 다리를 따라 6개 구역을 돌아본다.
- [ ] **9단계 출시:** Public으로 바꾸고 아이콘, 썸네일, 설명을 넣는다.

**AI에게 보낼 요청 예시**

```text
CLAUDE.md 규칙과 02_PRD.md를 읽고 '빌드 순서 3단계'만 구현해줘.
- 시작 전에 만들 파일/고칠 파일 목록을 먼저 보여줘.
- 다른 단계 기능은 만들지 마.
- PRD에 [작성 필요]로 남은 칸이 이 단계에 필요하면 추측하지 말고 먼저 물어봐.
- 끝나면 ✅ 확인 방법과 PRD에서 고칠 부분을 알려줘.
```
