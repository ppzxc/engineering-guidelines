# context:plan 입력 성숙도 분류 + idea 브랜치 brainstorm→grill 재배치

* Status: accepted
* Date: 2026-06-02
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`/context:plan`은 입력이 raw 아이디어든 완성된 플랜이든 항상 고정 파이프라인(grill-me → brainstorming)을 거친다. 두 가지 구조적 문제가 있다. 첫째, 입력 성숙도를 무시한다 — raw 아이디어는 *생성*(brainstorming)이, 완성 플랜은 *경화*(grill-me 스트레스 테스트)가 필요하나 고정 시퀀스는 둘 중 하나에 항상 헛돈다. 둘째, 순서가 역전됐고 질문이 중복된다 — brainstorming(idea→design 생성)이 먼저, grill-me(생성된 design 심문)가 나중이어야 하나 현재 반대이며, 두 스킬 모두 "clarifying questions"를 raw 아이디어에 적용해 사용자가 같은 의도를 두 번 심문당한다.

## Decision Drivers

* brainstorming의 정의는 "ideas → fully formed designs"(생성형), grill-me의 정의는 "interview about this plan, resolve decision tree"(수렴형 — 기존 artifact 전제). 현재 grill→brainstorm 순서는 두 스킬의 목적과 역전됐다.
* raw 아이디어에 grill-me를 적용하면 심문할 artifact가 없고, 완성 플랜에 brainstorming from-scratch를 적용하면 기존 설계를 버린다.
* `llm:auto`(ADR-0034)가 동일 레포에서 이미 입력 4종(plan/spec/idea/diff) 휴리스틱 분류+분기를 구현했다 — context:plan도 같은 패턴으로 일관화할 수 있다.
* ADR-0030이 grill-first를 의도적으로 채택했으나 근거는 "grill-me를 발산 도구로 재프레임"이었다. 본 결정은 grill-me를 원래 정의(경화)로 되돌리고 발산을 brainstorming이 담당하도록 역할을 재분리한다.
* 게이트 3종(spec 사람 리뷰/GAN/ExitPlanMode)과 플랜모드 Opus 설계(ADR-0041)는 유지한다.

## Considered Options

* **Option A (채택)**: 입력 성숙도 4종 분류(idea/spec/plan/diff) + idea 브랜치 brainstorm→grill 정순.
* **Option B**: 순서만 교정(brainstorm→grill). 입력 분류 미적용.
* **Option C**: 현행 유지(grill→brainstorm 고정 + 입력 분류 없음).

## Decision Outcome

Chosen option: **Option A**, because 입력 분류를 통해 헛돈 단계와 중복 질문을 동시에 제거할 수 있고, llm:auto 기존 패턴을 그대로 차용해 구현 비용이 낮으며, idea 브랜치에서 brainstorm(생성)→grill(경화) 정순이 각 스킬의 목적과 정합한다.

### Consequences

* Good, because 완성 플랜/spec 입력 시 brainstorming 헛돈 단계 없음.
* Good, because idea 입력 시 brainstorming이 design을 먼저 만들어 grill-me가 심문할 artifact를 확보 — 중복 질문 해소.
* Good, because diff 입력이 EnterPlanMode 전에 차단돼 플랜모드 오진입 없음.
* Good, because llm:auto 패턴 재사용 — 신규 메커니즘 불필요.
* Bad, because SKILL.md Step 4·5·6 재작성 범위가 크고, 세 브랜치를 동시에 올바르게 동작시키는 검증이 필요하다.
* Bad, because plan 브랜치에서 writing-plans 생성을 생략하고 tasks 정규화만 수행하는 로직이 신규 구현 사항이다.

### Confirmation

1. `grep -n 'INPUT_TYPE\|idea\|spec\|plan\|diff' plugins/context/skills/plan/SKILL.md` — Step 0c 분류 테이블 + 브랜치 분기 존재 확인.
2. `grep -rn '\[ADR-0043\]' .claude/rules/context-rules.md` — 규칙 항목 2개 확인.
3. ADR-0030 frontmatter에 "partially superseded by ADR-0043" 추가 확인.
4. 버전 동기 4곳 확인.
5. 수동 E2E:
   - `/context:plan idea <막연한 한 줄>` → brainstorming 먼저 → grill-me 나중 → 4파일 생성.
   - `/context:plan plan <체크리스트 텍스트>` → brainstorming 생략, grill-me만 → 4파일 생성.
   - `/context:plan <diff --git ...>` → git:review redirect, 플랜모드 미진입.

## Pros and Cons of the Options

### Option A — 입력 분류 + idea 정순 (채택)

* Good, because 헛돈 단계·중복 질문 동시 제거
* Good, because llm:auto 패턴 재사용 — 검증된 메커니즘
* Good, because grill-me가 생성된 design을 심문 — 원래 정의와 정합
* Bad, because SKILL.md 재작성 범위 큼 (Step 4·5·6)
* Bad, because plan 브랜치 tasks 정규화 신규 구현 필요

### Option B — 순서만 교정

* Good, because 변경 범위 작음 (Step 4·5 swap)
* Bad, because 입력 분류 없음 — 완성 플랜 입력 시 brainstorming 헛돈 단계 잔류
* Bad, because 중복 질문 일부 잔류 (두 스킬 모두 spec 정제를 거침)

### Option C — 현행 유지

* Good, because 변경 없음
* Bad, because 입력 성숙도 무시 지속
* Bad, because grill-me 역전 순서 유지 — 스킬 정의와 불일치

## More Information

- Supersedes (부분): [ADR-0030](0030-context-plan-pipeline-redesign.md) — idea 브랜치 grill-first ordering → brainstorm-first, 입력 무분기 → 4-way 분류.
- ADR-0030의 나머지(grill 존재 자체, writing-plans 자동연계 허용, GAN 단일 게이트, MAX_RETRIES=3 루프)는 유지.
- [ADR-0041](0041-context-plan-opusplan-design-relocation.md) — 플랜모드 Opus 설계·ExitPlanMode 릴리스 게이트·터미널 계약 불변.
- [ADR-0034](0034-llm-plugin-4way-and-context-map-deprecation.md) — llm:auto 입력 분류 패턴 차용.
- 관련 rules: `context-rules.md` `[ADR-0043]` 항목 2개.
- 관련 스킬: `plugins/context/skills/plan/SKILL.md` Step 0c 신설·Step 4·5·6 재작성.
