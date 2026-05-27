# context:plan 계층형 자가검증·리뷰 게이트 도입

* Status: accepted
* Date: 2026-05-27
* Decision Makers: ppzxc
* Consulted: Claude Opus (brainstorming, grill-me)
* Informed: context 플러그인 사용자

## Context and Problem Statement

`context:plan` 스킬은 raw 아이디어를 입력받아 `docs/context/{TASK_NAME}/`의 4파일(spec.md / plan.md / tasks.md / context.md)을 7스텝으로 오케스트레이션한다. 그런데 스텝별 검증 깊이가 불균형하다.

- Step 4 (spec.md): brainstorm self-review + grill-me + User Gate — 두터운 검증
- Step 6 (plan.md): 파일 존재 확인뿐 — 얇은 검증
- Step 7 (tasks.md, context.md): 검증 없음

`workflow:planning`은 동일한 plan 산출물을 만들면서 멀티 LLM 교차검증 게이트를 두지만, `context:plan`에는 동등한 게이트가 없다. 프로젝트에 `superpowers:verification-before-completion`(자가검증)과 `git:review` peer cross-check(멀티 LLM 교차검증) 방법론이 이미 있음에도 `context:plan`에 연결되지 않아 plan.md·tasks.md·context.md의 결함이 걸러지지 않고 구현 단계로 넘어갔다.

## Decision Drivers

* context 플러그인 self-contained 원칙 — 외부 리뷰 스킬(git:review 등) 추가 의존 금지
* 자기 cross-check 금지 (ADR-0022, ADR-0023) — Claude 호스트는 자기 자신에게 리뷰 요청 불가
* CLI 직접 호출로 멀티 LLM cross-check 구현 — 기존 agy / gemini / codex CLI 재활용
* `superpowers:verification-before-completion`은 허용 — 명시 Skill 호출로 동일 세션 내 자가검증
* graceful fallback + provenance 로깅 필수 — CLI 부재 환경에서도 산출물 중단 없이 동작해야 함

## Considered Options

* 옵션 1: Tier 1 Only — 체크리스트 자가검토 (추가 LLM 없음)
* 옵션 2: Tier 1 + Tier 2 CLI — 비-Claude CLI 직접 호출 (채택)
* 옵션 3: Tier 2 Only — 멀티 LLM 교차검증만

## Decision Outcome

Chosen option: "옵션 2: Tier 1 + Tier 2 CLI", because
Tier 1(self-review: 저비용, 즉각)과 Tier 2(GAN cross-check: 독립 시각 확보) 계층이 상호 보완하여 self-contained 제약 내에서 최대 검증 깊이를 달성한다.

### Consequences

* Good, because plan.md + tasks.md / context.md의 검증 공백이 해소된다.
* Good, because CLI sentinel + graceful fallback으로 CLI 부재 환경에서도 산출물 생성이 중단되지 않는다.
* Good, because provenance 로깅으로 어느 모델이 리뷰했는지 추적 가능하다.
* Bad, because Tier 2 CLI 호출로 Step 6 실행 시간이 ~5분 증가한다.
* Bad, because AGY / Gemini / Codex 모두 미설치 환경에서는 Claude self-generate fallback만 가능하다 (완전한 교차검증 아님).

### Confirmation

* `grep "Step-4 Gate\|Step-6 Gate\|Step-7 Gate" plugins/context/skills/plan/SKILL.md` → exit 0
* `test -f plugins/context/skills/plan/references/verification.md` → exit 0
* `/context:plan` 실행 시 Step 6에서 Tier 2 GAN cross-check 실행 + provenance 기록 확인
* AGY / Gemini / Codex 미설치 시 Claude self-generate fallback 발동 확인

## Pros and Cons of the Options

### 옵션 1: Tier 1 Only

* Good, because 추가 CLI 없이 즉시 적용 가능하다.
* Good, because 실행 시간 증가 없음.
* Bad, because 동일 모델(Claude)이 생성하고 검토하므로 시스템적 blind spot을 미탐지할 수 있다.
* Bad, because plan.md 수준의 복잡한 결함(순서 위험, feasibility)의 탐지가 제한된다.

### 옵션 2: Tier 1 + Tier 2 CLI — 채택

* Good, because 독립 모델이 결함을 탐지하여 작성 모델의 blind spot을 보완한다.
* Good, because sentinel + fallback으로 CLI 부재 환경을 대응한다.
* Good, because ADR-0022 / ADR-0023의 자기 cross-check 금지 원칙을 준수한다.
* Neutral, because Claude self-generate fallback은 완전한 교차검증이 아니다 (동일 모델).
* Bad, because Step 6 실행 시간이 ~5분 증가한다.

### 옵션 3: Tier 2 Only

* Good, because 독립 모델 리뷰를 확보한다.
* Bad, because Tier 1 체크리스트(무결성 검증, ORIG_COUNT 비교) 없이는 tasks.md / context.md 추출 오류를 미탐지한다.
* Bad, because Step 4(spec.md)에 Tier 1도 없으면 TBD / placeholder 자동 수정이 불가능하다.

## More Information

* `plugins/context/skills/plan/references/verification.md` — tier 정의, 체크리스트, GAN 프롬프트, CLI 패턴
* [ADR-0022](0022-bidirectional-peer-cross-review.md) — 자기 cross-check 금지 원칙
* [ADR-0023](0023-git-clean-bidirectional-peer-cross-check.md) — 동일 원칙 (git:clean 적용)
* [ADR-0027](0027-add-context-devdocs-plugin.md) — context 플러그인 도입
* `.claude/rules/context-rules.md` — `[ADR-0029]` 가드레일
