# feature-pipeline을 Plan Mode와 호환되도록 단계 재구성

* Status: accepted
* Date: 2026-05-19
* Decision Makers: ppzxc
* Consulted: -
* Informed: AI agents using workflow:feature-pipeline

## Context and Problem Statement

Plan mode가 외부에서 이미 활성화된 상태에서 `/workflow:feature-pipeline "..."` 인자 형태로 호출했을 때, SKILL.md에 이 시나리오를 다루는 분기가 0건이라 모델이 즉흥적으로 "충돌을 정리하겠습니다"라고 응답한 뒤 멈추는 현상이 발생했다. S2(worktree 생성)·S6(subagent dispatch)·S7(commit/PR)은 plan mode가 강제하는 "비-readonly 도구 차단" 제약과 본질적으로 양립 불가하다. 반면 S1(grill-me)·S1.5(karpathy 로드)·S3(plan 작성)·S4(Gemini ask)·S5(TDD grep gate)는 모두 read-only/AskUserQuestion/plan-file-only 기반이라 plan mode와 호환된다. 또한 현재 S2가 S3 앞에 있어 plan mode 활성 시 plan 파일 경로도 충돌한다(ADR-0011의 `docs/plans/<slug>.md` vs plan mode 강제 `/root/.claude/plans/<auto-slug>.md`).

## Decision Drivers

* plan mode에서 호출 시 모델 즉흥 대응을 제거하고 명확한 동작 절차를 정의
* S1~S5(Design phase)와 S2·S6·S7(Execute phase)의 자연스러운 분리 — plan mode의 설계 단계 활용을 가능하게 함
* 단일 흐름 유지 — plan mode 여부에 따른 조건 분기를 최소화해 SKILL.md 복잡도 억제
* ADR-0016 정신 유지 — feature-pipeline이 자체적으로 ExitPlanMode를 호출하지 않음

## Considered Options

* 옵션 1: 단일 순서 재배치 + plan mode 감지 + dual-path 경로 전략 (채택)
* 옵션 2: plan mode 진입 시에만 S2를 후행 조건 분기로 처리 (거절)
* 옵션 3: plan mode 진입 즉시 STOP — 비활성 후 재시작 안내 (거절)

## Decision Outcome

Chosen option: "옵션 1: 단일 순서 재배치 + plan mode 감지 + dual-path 경로 전략", because S2를 영구히 S5 뒤로 이동하면 plan mode 여부 무관하게 동일한 단일 흐름을 유지하면서 plan mode에서도 S1~S5 전체가 자연스럽게 진행된다. plan 파일 경로는 plan mode 활성 시 harness가 부여한 경로를 우선 사용하고 Gate 3 통과 후 S2 진입 직전에 `git mv`로 `docs/plans/<slug>.md`로 이전해 ADR-0011도 존중한다.

**3개 핵심 결정:**

1. **Phase 재구성 (단일 순서)**: `S1 → S1.5 → S3 → S4 → S5 → S2 → S6 → S7`. Plan mode 여부에 따른 분기 없음. S2(worktree 생성)를 S5 뒤로 영구 이동.
2. **외부 plan mode 통합**: S0에서 활성 여부 1회 감지. 활성이면 S1~S5만 진행, Gate 3 직전에 사용자에게 Shift+Tab 해제 요청. ExitPlanMode는 스킬이 호출하지 않음(ADR-0016 유지).
3. **Plan 파일 경로 이중 모드**: plan mode 활성이면 harness가 부여한 `/root/.claude/plans/<auto>.md` 사용. Gate 3 통과 + plan mode 해제 후 S2 진입 직전 `git mv`로 `docs/plans/<slug>.md` 이전. Plan mode 비활성이면 처음부터 `docs/plans/<slug>.md` 직접 사용.

**Supersedes (부분):**
- ADR-0014: "S3 시작 전 cwd=worktree 검증" → "S2 진입 시점(=Gate 3 통과 후) 및 S6 시작 전 검증"으로 시점 이동. ADR-0014 본문은 immutable 유지하며 이 ADR에서 시점 변경을 명시.
- ADR-0016: "자체적 ExitPlanMode 호출 금지"만 다루던 범위 → "외부 plan mode 활성 시나리오"까지 확장. ADR-0016 본문 immutable 유지.

### Consequences

* Good, because plan mode에서 S1~S5(Design phase)가 중단 없이 진행됨 — grill-me + karpathy + plan + cross-check + TDD gate를 plan mode에서 완성 가능
* Good, because S6 시점에 항상 worktree + `docs/plans/` 경로가 정합 — subagent의 plan 파일 참조 오류 없음
* Good, because ADR-0016의 plan_file_reference reattach 슬림화 유지 — plan mode 해제 후 S2 진행이므로 worktree 생성 시점에 plan mode 비활성
* Good, because 단일 흐름 — plan mode 조건 분기가 S3 경로 결정 1곳에만 존재
* Bad, because S3~S5 동안 plan 파일이 `docs/plans/` 외부(`/root/.claude/plans/`)에 위치할 수 있음 — S4 grep 등에서 절대경로/변수 사용 필요
* Bad, because `git mv` 실패 시(untracked 파일) `mv + git add` fallback 필요 — 엣지케이스 가드 요구
* Neutral, because S2의 의미가 "plan 전 worktree 생성"에서 "Gate 3 통과 후 worktree 생성 + plan 파일 이전"으로 확장

### Confirmation

```bash
# 1. SKILL.md 단계 순서 확인 — S2가 S5 뒤에 위치하는지
grep -B2 -A1 'S2.*[Ww]orktree' plugins/workflow/skills/feature-pipeline/SKILL.md | head -20

# 2. plan mode 감지 관련 내용 존재 확인
grep -nE 'plan mode|Shift\+Tab|/root/\.claude/plans' plugins/workflow/skills/feature-pipeline/SKILL.md

# 3. S3 경로 분기 확인
grep -n 'harness\|plan mode 활성\|/root.*plans' plugins/workflow/skills/feature-pipeline/SKILL.md

# 4. workflow-rules.md ADR-0019 항목 확인 (≥4건)
grep -c 'ADR-0019' .claude/rules/workflow-rules.md

# 5. ADR-0019 파일 존재 + README 인덱스 확인
test -f docs/adr/0019-make-feature-pipeline-plan-mode-compatible.md && echo OK
grep '0019' docs/adr/README.md
```

## Pros and Cons of the Options

### 옵션 1: 단일 순서 재배치 + plan mode 감지 + dual-path 경로 전략 (채택)

* Good, because 단일 흐름 — plan mode 여부 분기 없이 동일 순서
* Good, because plan mode에서 S1~S5 전체 활용 가능 (grill-me + plan + cross-check 완성도)
* Good, because S6 진입 시점에 항상 worktree + 올바른 plan 경로 정합
* Neutral, because S3~S5 구간에서 plan 파일이 `/root/.claude/plans/`에 위치 — 절대경로 사용 필요
* Bad, because `git mv` + fallback 엣지케이스 처리 로직 필요

### 옵션 2: plan mode 시에만 S2 후행 조건 분기

* Good, because plan mode 비활성 시 기존 흐름 완전 유지
* Bad, because SKILL.md에 조건 분기 추가 — 복잡도↑
* Bad, because ADR-0014의 단일 순서 원칙과 충돌

### 옵션 3: plan mode 진입 즉시 STOP

* Good, because 구현 단순 — S0에서 감지 후 메시지 출력
* Bad, because plan mode를 의도적으로 켠 사용자의 설계 단계 의도 무시
* Bad, because grill-me + plan + cross-check + TDD gate를 plan mode에서 할 수 없음 — UX 저하

## More Information

* 관련 ADR: [ADR-0011](0011-add-feature-pipeline-orchestrator.md), [ADR-0014](0014-strengthen-feature-pipeline-evidence-based-gates.md), [ADR-0016](0016-avoid-plan-mode-in-feature-pipeline.md)
* 적용 규칙: `.claude/rules/workflow-rules.md` `[ADR-0019]` 항목
* 발단: gatekeeper 프로젝트에서 plan mode 활성 상태로 `/workflow:feature-pipeline "standards.yml 상단 주석을 info.description에 포함"` 호출 시 모델 즉흥 우회 발생 (2026-05-19)
