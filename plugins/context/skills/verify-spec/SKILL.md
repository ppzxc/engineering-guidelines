---
name: verify-spec
description: Spec review retry loop + ExitPlanMode release gate for context:plan. Invokes grill-me hardening, AskUserQuestion approval loop, and ExitPlanMode as the final release gate. Can also be invoked standalone to re-run the spec review cycle — /context:verify-spec.
user-invocable: true
disable-model-invocation: true
---

# Verify Spec — Spec 리뷰 루프 + ExitPlanMode 게이트

`context:plan` Step 5(spec 경화·사람 리뷰)와 Step 7(ExitPlanMode 릴리스 게이트)을 위임받는 서브스킬.
단독 호출(`/context:verify-spec`)도 지원한다 — 기존 플랜 파일을 대상으로 리뷰 사이클을 재실행한다.

---

## Phase A. grill-me 경화 + Spec 사람 리뷰 게이트 (Step 5)

### A-1. grill-me 호출

`grill-me` 스킬을 호출하라. (네임스페이스 없음 — `grill-me` 그대로)

**ARGUMENTS**: 플랜 파일에 기록된 spec 또는 plan 내용 + 의도 한 줄 요약.
- idea/spec 브랜치: 플랜 파일의 **spec 내용**을 심문 대상으로 — "이 spec의 빈틈·모순·가정을 결정 트리로 심문하라"
- plan 브랜치: 플랜 파일의 **plan 내용**을 심문 대상으로 — "이 plan의 실행가능성·순서 리스크·누락을 결정 트리로 심문하라"

**중요**: grill-me는 RAW_IDEA(원시 입력)가 아닌 **플랜 파일에 기록된 내용을 심문**한다.
**grill-me는 파일을 쓰지 않는 순수 대화형 스킬이다.** grill 합의 결과는 오케스트레이터가 대화에서 캡처한다. grill 출력 파일을 읽으려 시도하지 말 것.

**결정 사항 영속화**: grill 합의 결정을 플랜 파일(플랜모드 허용 쓰기)에 즉시 기록한다. Step 8 context.md Decision Log 작성 시 이 기록을 소스로 사용한다.

갭이 발견됐으면 플랜 파일 해당 섹션을 보정한다.

### A-2. Spec 사람 리뷰 게이트 (AskUserQuestion)

`AskUserQuestion`을 호출한다. 현재 플랜 파일의 내용을 브랜치별로 요약하여 사용자에게 제시하고 승인/거부를 받는다.
- idea/spec 브랜치: **spec 내용** 요약 제시
- plan 브랜치: **plan 내용** 요약 제시

**MAX_RETRIES = 3.** 카운터를 명시적으로 추적한다: 첫 rejection 전 `RETRY=0` 초기화, 매 재시도 서두에 `[retry N/3]`을 출력하고 **플랜 파일에 기록**하여 컨텍스트 초기화 후에도 복구 가능하게 한다.

```
├ 승인 → Phase B (GAN gate / Step 6) 로 진행
└ 거부 →
    idea 브랜치: brainstorming 재호출(spec 갱신) → grill-me 재호출 → AskUserQuestion 재제시 (루프)
    spec/plan 브랜치: 사용자 피드백 반영 → 플랜 파일 보정 → grill-me 재호출 → AskUserQuestion 재제시 (루프)
    RETRY >= 3 → 루프 중단, 미해결 항목을 context.md Blockers에 이관 후 진행.
    "취소"/"abort"/"그만" 입력 → 즉시 루프 탈출, 현재 내용으로 진행 (Blockers에 "사용자 취소" 기록)
```

---

## Phase B. ExitPlanMode 릴리스 게이트 (Step 7)

**[하네스 제약]** `ExitPlanMode`는 하네스가 플랜 파일을 제시하고 Approve/Reject 클릭을 강제한다. 완전 자동화 불가 — 파일 쓰기 안전 게이트다.

**마찰 최소화**: `ExitPlanMode` 호출 직전, 플랜 파일 최상단에 다음 라인을 삽입한다:
```
> ✅ Step 5에서 spec 리뷰 완료. 이 Approve는 4파일 전사 시작 신호 — 내용 재검토 불필요.
```

`ExitPlanMode`를 호출한다. 플랜 파일(spec+plan+tasks+GAN 결과 포함)이 사용자에게 제시되고 최종 승인을 받는다.

- 승인 → 플랜모드 해제 → Step 8(기계적 전사)으로 진행
- 거부 → 사용자 피드백에 따라 해당 단계(Step 5 spec 수정 또는 Step 6 plan 수정)로 돌아가 플랜 파일 보정 후 ExitPlanMode 재호출
