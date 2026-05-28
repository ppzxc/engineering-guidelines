# 가이드라인 플러그인 통합 및 api/workflow 플러그인 폐기

* Status: "accepted"
* Date: 2026-05-26
* Decision Makers: ppzxc (USER), Antigravity (AI)
* Consulted: ppzxc
* Informed: ppzxc

## Context and Problem Statement

현재 저장소에는 단 하나의 스킬만 포함하고 있는 파편화된 소규모 플러그인들이 존재합니다:
1. `plugins/api` (보유 스킬: `restful-guidelines`)
2. `plugins/workflow` (보유 스킬: `karpathy-guideline`)

이처럼 개별 스킬 단위로 플러그인이 쪼개져 있는 구조는 플러그인 관리 비용을 증가시키고(메타데이터, 개별 리드미, 버전 동기화 등), 호출 네임스페이스가 직관적이지 못하며, 장기적으로 가이드라인 관련 지침이 여러 곳으로 흩어질 위험이 있습니다. 따라서 이를 "가이드라인"이라는 거대 범주 하에 통합하여 저장소 구조를 정리하고자 합니다.

## Decision Drivers

* **일관성 및 응집도**: 유사한 개발 지침 및 설계 가이드 성격의 스킬을 하나의 단일 플러그인에서 제공함으로써 결합도 및 모듈성을 높임.
* **직관적인 네이밍**: AI 에이전트와 사용자 모두 직관적으로 가이드라인 스킬들을 찾고 실행할 수 있는 네임스페이스 설계.
* **관리 편의성**: 불필요하게 쪼개진 플러그인들을 단일 플러그인으로 축소하여 마켓플레이스 등록 정보(`.claude-plugin/marketplace.json`) 및 리드미 버전 관리 공수를 대폭 절감.

## Considered Options

* **Option 1**: 기존 구조 유지 (파편화된 `api` 및 `workflow` 플러그인을 그대로 둠)
* **Option 2**: `guideline` 플러그인 신설 및 통합 (기존 두 플러그인은 폐기하고, 스킬들을 하나의 플러그인 내에 개편하여 이관)

## Decision Outcome

Chosen option: "**Option 2**", because 개발 설계 지침 성격의 스킬들이 일관된 네임스페이스(`/guideline:karpathy`, `/guideline:restful-api`) 아래 묶임으로써 직관성이 극대화되고, 플러그인 유지 보수 복잡도가 획기적으로 줄어들기 때문입니다.

### Consequences

* **Good, because**:
  * 단일 스킬용 소형 플러그인 2개가 폐기되고 `guideline` 1개로 통폐합되어 모듈성이 극대화됩니다.
  * 명령어 인터페이스가 `/guideline:karpathy`, `/guideline:restful-api`로 간결하게 개편되어 직관성이 상승합니다.
  * 플러그인 신규 생성 및 버전 정보 동기화 관리가 쉬워집니다.
* **Bad, because**:
  * 기존 네임스페이스(`/api:restful-guidelines`, `/workflow:karpathy-guideline`)를 사용하는 모든 기존 워크플로우나 단축어 설정이 호환되지 않으므로 수정이 수반되어야 합니다.

### Confirmation

* 새 플러그인 경로 `plugins/guideline`에 메타데이터(`plugin.json`) 및 스킬 파일들이 규격에 맞게 존재함을 확인합니다.
* `.claude-plugin/marketplace.json` 및 루트 `README.md` / `README.ko.md` 파일이 동기화되었는지 최종 검토합니다.

## Pros and Cons of the Options

### Option 1: 기존 구조 유지

* Good, because 기존 워크플로우나 명령어 단축어의 변경 없이 안정적으로 유지됩니다.
* Bad, because 단일 스킬만을 가진 미니 플러그인이 불필요하게 늘어나 관리가 파편화되고 가이드라인 성격의 스킬들이 결집되지 못합니다.

### Option 2: guideline 플러그인 신설 및 통합

* Good, because 개발/설계 모범 지침이 한 곳으로 모여 구조가 깔끔해지고, 네임스페이스 호출 직관성이 대폭 증가합니다.
* Bad, because 기존 스킬 명령어가 하위 호환성을 잃게 되어 기존 가이드라인 관련 단축어의 개편이 필요합니다.

## More Information

* [AGENTS.md](file:///home/ppzxc/projects/engineering-guidelines/AGENTS.md)
* `.claude-plugin/marketplace.json`
