# Gatekeeper 개발 워크플로우 스킬들의 workflow 플러그인 통합 및 연계 무결성 확보

* Status: "deprecated" (superseded/removed by [ADR-0050](0050-deprecate-workflow-plugin.md))
* Date: 2026-05-26
* Decision Makers: ppzxc (USER), Antigravity (AI)
* Consulted: ppzxc
* Informed: ppzxc

## Context and Problem Statement

현재 `gatekeeper` 프로젝트에는 에이전트의 강력한 개발 원칙 및 기율을 강제하기 위한 5대 핵심 워크플로우 스킬(`init`, `idea`, `feature`, `develop`, `planning`)이 `.claude/skills/` 하위에 분산 적용되어 있습니다. 
이 스킬들을 소프트웨어 개발 엔지니어링 가이드라인 모음인 본 `engineering-guidelines` 마켓플레이스 리포지토리의 신설 **`workflow` 플러그인**으로 중앙화 통합하여 마켓플레이스를 통한 배포 및 전역 재사용성을 확보하고자 합니다. 
동시에, 이관되는 5대 스킬들이 상호 간에 맺고 있는 긴밀한 연계 호출 구문들의 무결성을 손상 없이 지켜내야 합니다.

## Decision Drivers

* **마켓플레이스 통합 배포**: 분산된 유용한 워크플로우 스킬들을 패키징하여 한 곳에서 쉽게 추가하고 업데이트할 수 있도록 지원.
* **스킬 연계 정합성 보장**: `/init` ➔ `/idea` ➔ `/feature` ➔ `/planning` ➔ `/develop`로 이어지는 기계적/논리적 파이프라인 연계 구문이 플러그인 접두사 개편(`/workflow:xxx`) 후에도 정상 동작하도록 보완.
* **아키텍처적 일관성**: 플러그인에 기반한 규격 설계 컨벤션 유지.

## Considered Options

* **Option 1**: 외부 스킬을 단순 복사하여 사용하되 명령어 네임스페이스를 그대로 유지 (마켓플레이스 스펙과 어긋날 위험 존재)
* **Option 2**: `workflow` 플러그인을 신설하여 5대 스킬을 하위로 완벽 이관하고, 스킬 내부의 상호 참조 명령어 구문들을 `/workflow:xxx` 네임스페이스로 정밀 치환하여 정합성을 일괄 보장.

## Decision Outcome

Chosen option: "**Option 2**", because 마켓플레이스 규격을 완벽히 충족하면서도 스킬 본문에 산재한 상호 호출 구문을 모두 개편 네임스페이스로 리팩토링함으로써 스킬 간의 실무 작동 연계 무결성을 100% 보장하기 때문입니다.

### Consequences

* **Good, because**:
  * `gatekeeper`에 속해 있던 5가지 강력한 핵심 스킬들을 한 곳에서 마켓플레이스를 통해 통합 관리할 수 있게 됩니다.
  * 호출 단축어가 `/workflow:init`, `/workflow:planning` 등으로 직관적으로 묶입니다.
  * 각 스킬 내부에 존재하는 상호 호출 참조가 일관되게 업데이트되어 연동 동작이 차질 없이 보장됩니다.
* **Bad, because**:
  * 사용자가 단독 명령어 형태(`/init` 등)로 사용하던 단축 구문을 `/workflow:init` 등으로 입력해야 하는 사용자 행동 변화가 발생합니다.

### Confirmation

* `plugins/workflow/skills/` 내에 5대 스킬 디렉토리가 완벽히 복사되었는지 확인합니다.
* `init`, `idea`, `feature`, `develop`, `planning` 하위의 `SKILL.md` 본문에서 이전 단독 명령어(`/xxx`)가 모두 `/workflow:xxx`로 개편 적용되었는지 정합성을 검수합니다.

## Pros and Cons of the Options

### Option 1: 외부 스킬의 단순 복사 및 기존 단축어 유지

* Good, because 기존에 사용하던 단독 단축 명령어를 그대로 계승할 수 있어 전환 피로가 적습니다.
* Bad, because 플러그인 패키지 규격을 위반하거나 타 플러그인과 단축어 네이밍 충돌이 날 수 있으며 정석적인 마켓플레이스 설계 사상에 위배됩니다.

### Option 2: workflow 플러그인 신설 및 연계 구문 정밀 리팩토링

* Good, because 마켓플레이스 표준 아키텍처에 완벽하게 부합하며, 스킬 간의 연계 무결성까지 수동 치환을 통해 실무적으로 확실하게 보장해 줍니다.
* Bad, because 스킬 본문 내 여러 곳의 연계 텍스트를 정밀 치환해야 하는 초기 이관 공수가 수반됩니다.

## More Information

* [AGENTS.md](file:///home/ppzxc/projects/engineering-guidelines/AGENTS.md)
* `.claude-plugin/marketplace.json`
