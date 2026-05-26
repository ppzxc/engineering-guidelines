---
name: planning
description: Use when writing and validating a development plan after feature goals are defined — /workflow:planning, "플랜 작성", "계획 수립", "플랜 짜자"
user-invocable: true
---

# Planning with Gemini Cross-check

플랜 작성 → Context Map 생성 → Gemini 검증 → 확정.
**실행(코드 작성, TDD, 커밋)은 이 스킬의 범위 밖이다.**

## 실행 순서

### Step 1: 플랜 작성

`superpowers:writing-plans` 스킬을 호출하라.
`/workflow:feature`에서 grill-me로 명확화된 피쳐 목표를 컨텍스트로 활용한다.

### Step 2: Context Map 생성

`llm`의 `Context Map` 섹션을 실행하라 (재생성 스킵 조건 동일 적용).
이 Context Map은 Step 3에서 Gemini가 프로젝트 맥락을 이해하는 데 사용된다.

### Step 3: Gemini 교차 검증

`llm`의 `Plan Cross-check` 섹션을 실행하라.
Step 1에서 작성된 플랜 전문을 REVIEW_CONTEXT에 포함하라.

### Step 4: 플랜 확정

Gemini 피드백을 반영하여 플랜을 수정하라.
Pre-mortem 결과를 플랜의 Assumption 섹션에 반영하라.
사용자 승인을 기다린다. 거부 시 피드백 반영 후 Step 3으로 돌아간다.

승인 완료 시:

1. 플랜 제목(Goal 첫 줄)에서 kebab-case slug를 추론한다.
2. `docs/plans/` 디렉토리가 없으면 생성한다.
3. 확정된 플랜 전문을 `docs/plans/<slug>.md`에 저장한다.
4. 아래를 출력한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
플랜 검증 완료. docs/plans/<slug>.md 저장됨.

다음 단계:
  1. /workflow:develop — worktree 생성 후 TDD 구현 시작
  2. 계속 논의
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Gemini 사용 불가 시 (Conservative mode)

`llm` Conservative mode 규칙을 동일하게 따른다.
Claude가 직접 Test Scenarios 3개 + Pre-mortem 3개를 생성한다.
