# workflow 플러그인 폐기 및 관련 메타데이터 정리

* Status: "accepted"
* Date: 2026-06-09
* Decision Makers: ppzxc, Antigravity
* Consulted: ppzxc
* Informed: ppzxc

## Context and Problem Statement

이전에 `gatekeeper` 프로젝트에서 이관되었던 고강도 개발 기율 강제용 `workflow` 플러그인(5대 스킬: `init`, `idea`, `feature`, `planning`, `develop`)이 현재 환경 및 요구사항에 더 이상 불필요해짐에 따라, 프로젝트 유지보수 비용을 줄이고 복잡성을 낮추기 위해 이를 완전히 제거하고자 합니다.

## Decision Drivers

* **불필요한 기능 제거**: 더 이상 사용되지 않는 스킬과 플러그인 코드를 제거하여 프로젝트 용량 및 컨텍스트 복잡성 완화.
* **아키텍처 기록 보존**: 플러그인을 제거하되, 이전 결정(ADR 0026, 0048)의 흔적을 올바르게 폐기(deprecated)로 기록하여 설계 역사를 보존함.

## Considered Options

* **Option 1**: workflow 플러그인과 메타데이터만 단순히 삭제하고 ADR 기록은 방치함.
* **Option 2**: workflow 플러그인 관련 리소스를 삭제하고, 기존 ADR 0026 및 0048의 상태를 `deprecated`로 변경하며, 본 신규 ADR(0050)을 추가하여 폐기 이력을 명확히 남김.

## Decision Outcome

Chosen option: "Option 2", because 코드 리소스 삭제뿐만 아니라 관련 아키텍처 의사결정의 상태(Status)를 투명하게 업데이트하고 이번 폐기 사실을 신규 ADR로 남김으로써, 가이드라인 프로젝트의 역사적 일관성을 유지할 수 있기 때문입니다.

### Consequences

* Good, because:
  * 불필요한 플러그인 코드(`plugins/workflow/`)가 삭제되어 프로젝트가 단순해집니다.
  * 기존 결정들(ADR 0026, 0048)의 최신 유효 여부가 명확히 표시됩니다.
* Bad, because:
  * 이전 워크플로우를 참조하여 작성되었던 설계 및 예시를 확인하기 위해 이전 리포지토리 버전을 조회해야 할 수 있습니다.

### Confirmation

* `plugins/workflow/` 디렉토리가 더 이상 존재하지 않는지 확인합니다.
* `.claude-plugin/marketplace.json` 내 `workflow` 플러그인 등록 정보가 제거되었는지 확인합니다.
* `README.md` 및 `README.ko.md`에서 `workflow` 항목 행이 존재하지 않는지 확인합니다.
* `docs/adr/0026-integrate-workflow-skills-from-gatekeeper.md` 및 `docs/adr/0048-workflow-session-state.md`의 `Status` 헤더가 `deprecated`로 수정되었는지 확인합니다.

## Pros and Cons of the Options

### Option 1: 단순 삭제

* Good, because 신규 문서 작성이나 기존 문서 수정 공수가 줄어듭니다.
* Bad, because 이전 ADR들이 여전히 `accepted` 상태로 남아 있어 향후 독자에게 혼란을 줄 수 있습니다.

### Option 2: 파일 삭제 및 관련 ADR 마킹 + 신규 ADR 기록

* Good, because 아키텍처 가이드라인 프로젝트로서 결론의 변동과 그 역사를 가장 깔끔하게 추적할 수 있도록 돕습니다.
* Bad, because 추가적인 수동 문서 업데이트 작업이 필요합니다.

## More Information

* [ADR 0026](file:///home/ppzxc/projects/engineering-guidelines/docs/adr/0026-integrate-workflow-skills-from-gatekeeper.md)
* [ADR 0048](file:///home/ppzxc/projects/engineering-guidelines/docs/adr/0048-workflow-session-state.md)
