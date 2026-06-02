# 스킬 no-arg 유추 시 실행 전 확인 게이트 도입

* Status: accepted
* Date: 2026-06-02
* Decision Makers: ppzxc

## Context and Problem Statement

`context:*`, `dev:*`, `guideline:*` 플러그인 스킬을 인자 없이 호출하면, 일부 스킬이 파일시스템/세션 상태에서 의도를 유추한 뒤 사용자 확인 없이 곧바로 실행한다. 대표 사례: `context:recall`/`context:update`의 최신 폴더 자동선택 후 읽기·쓰기, `dev:tidy`의 리팩토링 대상 무언 유추, `guideline:restful-api`의 프로필 묵시적 적용. 이 자동실행이 사용자의 예측 범위를 벗어나는 문제가 제기됨.

## Considered Options

1. **유추 결과 확인 게이트** — 유추 로직은 유지하되, interactive 세션에서 유추 직후 결과를 제시하고 AskUserQuestion으로 확인받은 뒤 실행
2. **인자 강제 요구** — 인자 없으면 즉시 오류 종료 (유추 로직·ADR-0027 동작 파괴)
3. **현행 유지** — 자동실행 그대로 유지

## Decision Outcome

Chosen option: "유추 결과 확인 게이트", because interactive 세션에서 유추 직후 결과를 사용자에게 제시하고 확인받으면 유추 로직(ADR-0027 최신폴더 선택 등)을 보존하면서 자동실행 surprise를 제거할 수 있다. non-interactive 세션은 기존 동작 유지로 자동화에 영향 없음.

적용 스킬: `context:recall`, `context:update`, `dev:tidy`, `guideline:restful-api`.

비해당: `guideline:honest-judgment`, `guideline:karpathy`는 인자·유추·실행이 없는 verbatim 로드 전용이므로 이 게이트 비해당.

### Consequences

* Good: interactive 세션에서 유추 자동실행 surprise 제거, 유추 로직(ADR-0027)·non-interactive 동작 보존.
* Bad: interactive no-arg 호출마다 확인 1회 추가로 왕복 비용 증가.
