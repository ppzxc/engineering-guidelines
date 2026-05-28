# context:guard Stop hook — auto-run via decision:block (supersedes ADR-0028)

* Status: accepted
* Date: 2026-05-28
* Decision Makers: ppzxc
* Consulted: Claude Opus, Gemini 2.5 Pro (GAN adversarial review)
* Informed: context 플러그인 사용자

## Context and Problem Statement

context:guard가 설치한 Stop hook(ADR-0028)이 `{"systemMessage":"..."}` reminder-only로 동작했다. 그 결과 두 가지 심각한 오탐 루프가 발생했다:

1. **무관 아티팩트 트리거**: `.idea/workspace.xml` 등 IDE 아티팩트가 `docs/`·`.claude/` 밖 "코드 변경"으로 카운트되어 불필요하게 발동됨.
2. **무관 context 비교**: 전역 최신 context.md를 무조건 선택하여, 현 세션 작업과 무관한 context에 대해 경고 발생 → `/context:update`를 실행해도 해소되지 않는 무한 경고 루프.

추가 원인: `systemMessage`는 Claude가 무시할 수 있어 reminder-only는 실효성이 낮았고 (ADR-0028의 근본 한계), `awk '{print $NF}'`를 이용한 `git status` 파싱은 rename·공백 경로에서 깨졌다.

## Decision Drivers

* 무한 경고 루프 → 사용자 불쾌, /context:update 실행 후에도 반복 경고
* systemMessage를 Claude가 무시 가능 → reminder-only 실효성 미달
* ADR-0028 당시 decision:block 거부 사유("무한루프 위험")는 stop_hook_active 가드로 해소 가능
* IDE/툴 아티팩트 변경은 의미 있는 코드 변경 아님 — 필터 필요
* 관련 없는 context를 전역 최신 기준으로 선택하는 로직은 오탐의 구조적 원인

## Considered Options

* 옵션 1: reminder-only 유지 + 오탐만 수정 (아티팩트 필터 + 관련 context만)
* 옵션 2: decision:block 자동 실행 + 오탐 수정 + 루프 가드 (채택)
* 옵션 3: Stop hook 제거, PreToolUse hook 등 다른 이벤트로 전환

## Decision Outcome

Chosen option: "옵션 2: decision:block 자동 실행 + 오탐 수정 + 루프 가드", because
`decision:block+reason`은 Claude가 반드시 이행해야 하므로 reminder-only의 무시 가능 문제를 해결하고, `stop_hook_active` 가드로 무한루프 위험(ADR-0028 거부 근거)도 완전히 차단한다.

### Consequences

* Good, because decision:block은 Claude가 reason을 보고 `/context:update`를 직접 실행하므로 update가 실질적으로 수행됨 (systemMessage 무시 가능성 해소).
* Good, because `stop_hook_active: true` 재진입 시 `exit 0`으로 단락하여 ADR-0028이 우려한 무한 block 위험이 완전 차단됨 — decision:block이 지금은 안전한 이유.
* Good, because IDE/툴 아티팩트 제외 + 관련 context 매칭으로 오탐 루프 해소.
* Good, because git status 파싱을 `cut -c4-`+rename sed로 교체하여 공백 파일명·rename 케이스 견고화.
* Bad, because block은 Claude 턴이 살아있을 때만 동작 — 사용자가 완전히 이탈한 후엔 작동 안 함.
* Bad, because full-path grep 매칭(scope 미선언 시)은 context 문서에 경로가 명시적으로 기록되어 있어야 하며, scope 선언이 없는 초기 context에서는 매칭 실패 가능.

### Confirmation

* 스크립트 직접 실행: `printf '{"stop_hook_active":true}' | sh plugins/context/hooks/context-staleness-check.sh; echo "exit=$?"` → 무출력, exit 0
* 아티팩트 오탐: `.idea/workspace.xml`만 dirty 상태에서 실행 → 무출력, exit 0
* 관련 context 없음: docs/ 밖 무관 파일 변경 → 무출력, exit 0
* 관련 stale: 관련 context가 있는 코드 파일 touch → `{"decision":"block",...}` 출력

## Pros and Cons of the Options

### 옵션 1: reminder-only 유지 + 오탐만 수정

* Good, because ADR-0028 behavior contract 유지 — 범위 최소.
* Bad, because systemMessage 무시 가능성은 여전히 존재 — 근본 문제 미해결.
* Bad, because 사용자가 수동으로 /context:update를 보고 실행해야 하는 UX 부담 유지.

### 옵션 2: decision:block 자동 실행 (채택)

* Good, because auto-run이 실질적으로 실현됨.
* Good, because stop_hook_active 가드로 무한루프 안전.
* Good, because git 파싱 견고화·아티팩트 필터·관련 context 매칭 일괄 개선.
* Neutral, because ADR-0028 supersede 필요 — 변경 범위가 더 큼.

### 옵션 3: Stop hook 제거

* Good, because hook 자체 제거로 모든 복잡성 소멸.
* Bad, because 진행상황 유실(context:update 미실행)이라는 원래 문제(ADR-0028 Context)로 완전 회귀.

## More Information

* [ADR-0028](0028-context-guard-opt-in-stop-hook.md) — 본 ADR이 supersede하는 원결정. reminder-only + systemMessage를 채택했으나 무한루프·오탐·무시 가능성 문제 노출.
* [ADR-0027](0027-add-context-devdocs-plugin.md) — context 플러그인 도입 결정
* `.claude/rules/context-rules.md` — context:guard 관련 규칙 (`[ADR-0031]` 태그)
* Stop hook 스키마: `{"decision":"block","reason":"..."}` — block은 Claude가 reason 이행 후 계속 처리; `stop_hook_active: true` 재진입 가드로 무한루프 방지.
* Gemini 2.5 Pro GAN 리뷰에서 지적된 3개 항목(git 파싱, basename 오탐, 루프 가드)을 이 결정에 반영.
