# context 플러그인 옵트인 Stop hook 도입 (context:guard)

* Status: accepted
* Date: 2026-05-27
* Decision Makers: ppzxc
* Consulted: Claude Opus (brainstorming)
* Informed: context 플러그인 사용자

## Context and Problem Statement

context 플러그인은 `context:plan`으로 4파일 폴더를 생성한 뒤 세션을 클리어하고 새 코딩 세션에서 구현한다. 그 코딩 세션 동안 `context:update`(진행상황 영속화)를 실행하도록 강제할 장치가 없다. 사용자가 잊으면 compaction·세션 종료 시 진행상황이 유실된다. 어떤 메커니즘으로 `context:update` 실행을 유도할 것인가?

## Decision Drivers

* context 플러그인 이식성 원칙 — 플러그인은 hook-free·자기완결 (ADR-0014)
* 코딩 세션 중 진행상황 유실 방지 필요
* hook이 스킬을 직접 호출할 수 없음 — Claude Code hook은 셸 명령만 실행 가능
* 과도한 간섭 없이 reminder 수준으로 충분 (reminder-only; decision:block 미사용)
* 호스트 환경 변형 최소화 — 명시적 옵트인 필요

## Considered Options

* 옵션 1: plugin.json에 hooks 필드 추가 (플러그인 자체가 hook 제공)
* 옵션 2: 전용 설치 스킬(`context:guard`)로 호스트 옵트인 Stop hook 제공
* 옵션 3: SKILL.md 안내문 강화만 (hook 없이 텍스트 경고만 추가)

## Decision Outcome

Chosen option: "옵션 2: 전용 설치 스킬로 호스트 옵트인 Stop hook 제공", because
플러그인 hook-free 이식성(ADR-0014)을 유지하면서도 명시 동의 후 호스트 설정에만 영향을 주어 플랫폼 의존성을 제어 가능한 범위로 한정한다.

### Consequences

* Good, because 플러그인 자체(plugin.json, SKILL.md)는 hook-free로 유지되어 ADR-0014 이식성 원칙을 위반하지 않는다.
* Good, because 사용자가 명시 동의(context:guard 호출)해야만 호스트 설정이 변경되어 예상치 못한 환경 변형이 없다.
* Good, because Stop hook staleness 체크는 git status + mtime 비교로 결정적이며, 변경이 없으면 조용히 종료한다.
* Bad, because 플러그인 설치만으로 자동 적용되지 않아 사용자가 context:guard를 별도로 알고 실행해야 한다.
* Bad, because hook이 스킬을 직접 실행하지 못하므로 reminder만 가능하다 — 사용자/Claude가 메시지를 보고 수동으로 /context:update를 실행해야 한다.

### Confirmation

* `context:guard` 실행 시 `.claude/settings.json`의 `hooks.Stop` 배열에 항목이 추가되는지 확인
* 코드 파일 변경 후 turnStop 시 staleness reminder 메시지가 표시되는지 확인
* `context:guard` 2회 실행 시 중복 항목이 추가되지 않는지 확인
* 플랜모드에서 `context:guard` 호출 시 settings.json 쓰기가 거부되는지 확인

## Pros and Cons of the Options

### 옵션 1: plugin.json에 hooks 필드 추가

* Good, because 플러그인 설치만으로 자동 적용된다.
* Bad, because ADR-0014의 "hook은 플랫폼 의존성을 만들고 SKILL.md 자체로 완결되지 않는다"는 근거를 정면으로 위반한다.
* Bad, because 플러그인이 호스트 설정을 암묵적으로 변형한다 — 사용자 동의 없이.
* Bad, because husky 등 기존 hook과 충돌 위험이 있다.

### 옵션 2: 전용 설치 스킬 (context:guard) — 채택

* Good, because 플러그인은 hook-free를 유지하여 ADR-0014와 호환.
* Good, because 명시 동의 + 플랜모드 차단 + idempotent 설치로 안전하다.
* Good, because Stop hook staleness 스크립트를 호스트 `.claude/hooks/`로 복사하여 plugin 캐시 경로(버전 의존)를 참조하지 않는다.
* Neutral, because 자동이 아니라 반자동 — 사용자가 한 번은 실행해야 한다.

### 옵션 3: SKILL.md 안내문 강화만

* Good, because 플러그인 변경 없이 즉시 적용 가능.
* Bad, because ADR-0014가 이미 "선언적 텍스트 강제는 실패했다"고 실증적으로 판단했다. 텍스트 안내만으로는 compaction 이후 무너진다.

## More Information

* [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md) — hook 기반 강제를 검토했으나 플랫폼 의존성 이유로 거부한 결정. 본 ADR이 그 원칙을 유지하면서 옵트인 경로를 열어 refine.
* [ADR-0027](0027-add-context-devdocs-plugin.md) — context 플러그인 도입 결정
* `.claude/rules/context-rules.md` — context:guard 관련 규칙 (`[ADR-0028]` 태그)
* Stop hook JSON 스키마: `{"systemMessage":"..."}` — `decision` 필드는 Stop hook에서 `block`/생략만 유효하므로 비차단 reminder는 systemMessage 단독으로 emit한다.
