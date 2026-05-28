---
name: plan
description: Use when starting a new task from a raw idea and you want a resumable 4-file Dev Docs folder — /context:plan, "컨텍스트 플랜", "작업 폴더 만들어", "재개 가능한 계획"
user-invocable: true
---

# Context Plan — 4파일 Dev Docs 폴더 생성

raw 아이디어에서 출발해 `docs/context/{TASK_NAME}/`에 4파일 자기완결 폴더(spec/plan/tasks/context.md)를 만든다.
이 폴더 하나만 읽으면 세션이 끊겨도 정확히 재개된다.

이 스킬은 spec·plan 작성을 핵심 가치로 둔다. **그중 spec 리뷰가 가장 중요하다** — 사람의 의도가 spec에 정확히 반영됐는지 확인하는 단계다. spec이 틀리면 완벽한 plan도 엉뚱한 결과를 만든다. spec에 오류가 있으면 즉시 거부하고, 현재 spec을 기반으로 `grill-me`를 다시 호출하여 발산·교정한 뒤 재검토한다.

---

## 실행 순서

### Step 0. ARGUMENTS 검사

ARGUMENTS(사용자가 넘긴 raw 아이디어)가 비었는지 확인한다.

- **비었음(대화 모드)**: AskUserQuestion으로 "어떤 작업을 시작할까요?" 질문한다.
- **비었음(비대화 모드 — AskUserQuestion 불가)**: 에러 메시지 출력 후 즉시 종료. (`/context:plan <아이디어>` 형식으로 다시 호출하도록 안내)
- **있음**: Step 1로 진행.

### Step 1. 플랜모드 감지 및 자동 진입

플랜모드 활성 여부를 확인한다.

- **이미 활성**: 그대로 진행.
- **미활성**: `EnterPlanMode`를 호출하여 자동 진입한다. 이후 Step 2부터 탐색 단계(Step 5 완료)까지 플랜모드를 유지한다.

탐색 단계(Step 2–5)는 플랜모드 안에서 read-only로 진행된다. 단, spec 내용은 **플랜 파일**에 기록한다(플랜모드가 허용하는 유일한 쓰기).

### Step 2. TASK_NAME 정규화

ARGUMENTS로 받은 raw 아이디어에서 TASK_NAME을 kebab slug으로 변환한다:
1. 소문자로 변환
2. 공백 → `-`
3. `[^a-z0-9-]` 문자 제거 (`../` 등 경로 traversal 자동 제거됨)
4. 연속 `-` 축약 (예: `--` → `-`)
5. 양끝 `-` 제거

결과 경로: `docs/context/{TASK_NAME}/`

### Step 3. 폴더 충돌 정책

`docs/context/{TASK_NAME}/` 존재 여부를 확인한다. 존재하면 AskUserQuestion으로 분기:
- **덮어쓰기**: 기존 작업 상태 소실 경고 후 진행
- **기존 작업 재개**: `context:resume`를 안내하고 종료
- **다른 이름으로 생성**: 새 TASK_NAME 입력 받기

비대화 모드(AskUserQuestion 불가) 기본값: suffix `-2` 추가.

### Step 4. grill-me 호출 (raw 아이디어 발산)

`grill-me` 스킬을 호출하라. (네임스페이스 없음 — `grill-me` 그대로)

ARGUMENTS: raw 아이디어 + 의도 한 줄 요약

**grill-me는 파일을 쓰지 않는 순수 대화형 스킬이다.** grill 합의 결과(결정 사항)는
이 오케스트레이터가 대화에서 직접 캡처한다. grill 출력 파일을 읽으려 시도하지 말 것.

### Step 5. brainstorming 호출 + spec 플랜 파일 기록 + 사람 리뷰 게이트 ★

**brainstorming 호출:**

`superpowers:brainstorming` 스킬을 호출하라.
ARGUMENTS:
- grill에서 발산된 아이디어 + 보완 포인트
- **"디스크 쓰기 금지, spec 내용만 산출"** 명시 — 플랜모드가 sub-skill의 파일 쓰기를 차단한다.
  brainstorming이 쓰기를 시도하다 차단되어도 오케스트레이터가 대화에서 spec 내용을 캡처해
  플랜 파일에 기록하고 계속 진행한다(크래시 흡수).
- HARD-GATE 차단 없음 — writing-plans 자동연계는 이후 Step 6에서 오케스트레이터가 직접 제어한다.

**spec 내용을 플랜 파일에 기록:**

brainstorming이 산출한 spec 내용을 **지정 플랜 파일**에 작성한다.
이 파일이 ExitPlanMode 제시 화면에 표시된다.

**ExitPlanMode = spec 사람 리뷰 게이트 ★최우선 게이트★:**

`ExitPlanMode`를 호출한다. 플랜 파일(= spec)이 사용자에게 제시되고 승인을 받는다.

```
├ 승인 → 플랜모드 해제 → Step 6으로 진행
└ spec 오류 → 플랜모드 유지 (ExitPlanMode 미해제)
     → grill-me 재호출 (현재 spec 기반, 틀린 점 발산)
     → brainstorming spec 갱신 → 플랜 파일 갱신 → ExitPlanMode 재제시 (루프)
     ※ MAX_RETRIES = 3. 3회 초과 시 루프 중단,
       미해결 항목을 Step 7의 context.md Blockers에 이관 후 진행
     ※ 루프 중 사용자가 "취소" / "abort" / "그만" 입력 시 → 즉시 루프 탈출,
       현재 spec으로 Step 6 진행 (Blockers에 "사용자 취소" 기록)
```

---

## ━━━ 산출 단계 (플랜모드 OFF, 파일 쓰기 허용) ━━━

### Step 6. spec.md 확정 + writing-plans 자동연계 + GAN gate

**spec.md 확정:**

플랜 파일의 spec 내용을 `docs/context/{TASK_NAME}/spec.md`에 작성(확정)한다.

```bash
test -f docs/context/{TASK_NAME}/spec.md
```
실패 시 작성 재시도.

**writing-plans 자동연계:**

`superpowers:writing-plans` 스킬을 호출하라.
ARGUMENTS:
- spec 경로 `docs/context/{TASK_NAME}/spec.md`
- (location override) plan 저장 위치를 `docs/context/{TASK_NAME}/plan.md`로 한다.

**파일위치 검증 (writing-plans 반환 직후 필수)**:
1. `test -f docs/context/{TASK_NAME}/plan.md` 확인.
2. 실패하면 `docs/superpowers/plans/` 아래 최신 `.md`를 찾아 정본 경로로 이동:
   `mv <found-path> docs/context/{TASK_NAME}/plan.md`
3. 재확인 후 진행.

**[Step-6 Gate] GAN cross-check (순서 고정):**

`references/verification.md`의 **Step-6 Gate**를 실행하라.

### Step 7. 분할·합성 + plan.md 트림

**tasks.md 추출**: 추출 전 트림 카운트를 먼저 캡처한다:
`ORIG_COUNT=$(grep -c -- '- \[ \]' docs/context/{TASK_NAME}/plan.md)`
그 후 plan.md의 `- [ ]` 체크리스트를 Phase별 그룹, `[P]` 병렬 마커,
체크포인트 보존하여 `docs/context/{TASK_NAME}/tasks.md`에 저장한다.

**context.md 생성**: 아래 템플릿으로 `docs/context/{TASK_NAME}/context.md`를 만든다.
- Current Status: 초기값 ("작업 폴더 생성 완료. tasks.md Step 1부터 시작.")
- Key Files: plan.md의 File Structure 섹션에서 추출
- Decision Log: Step 4(grill)에서 캡처한 합의 결정 사항 + GAN provenance
- Next Steps: tasks.md의 첫 번째 미완료 항목
- Blockers: spec 루프 MAX_RETRIES 초과 미해결 항목 (없으면 "None")
- `Last Updated`: 오늘 날짜

```markdown
<!-- last_updated: YYYY-MM-DDTHH:MM:SSZ -->

## Current Status
<!-- 한 줄: 지금 전체적으로 어디까지 -->

## Key Files
<!-- 주요 파일 경로 + 한 줄 역할 -->

## Decision Log
<!-- grill 합의 + 구현 중 추가 결정 (spec 초기 설계결정과 구분) -->
<!-- provenance: plan reviewed by <agy|gemini|codex|Claude self-generate> (GAN mode) — N findings (H:x M:y L:z), M addressed -->

## Next Steps
<!-- 바로 다음 할 일 -->

## Blockers / Known Issues
<!-- 막힌 것 / 미해결 -->

Last Updated: YYYY-MM-DD
```

**plan.md 트림**: tasks.md 추출 후 plan.md에서 bite-sized task 단계(`### Task N` 및 그 하위 `- [ ]` step 전체)를
제거하고 Header(Goal/Architecture/Tech Stack) + File Structure만 남긴다.
자동 수행, 사용자 확인 불필요(무손실 이동).

**Step-7 검증:**
- `tasks.md`의 `- [ ]` 수 == ORIG_COUNT (무손실)
- `grep -c '### Task' docs/context/{TASK_NAME}/plan.md` == 0

### Step 8. 완료 핸드오프

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
docs/context/{TASK_NAME}/ 폴더 생성 완료
  spec.md    — brainstorming 설계 산출물
  plan.md    — 목표·아키텍처·파일 구조 (tasks 제거됨)
  tasks.md   — 실행 체크리스트
  context.md — 동적 재개 앵커
  [GAN review] — <agy|gemini|codex|Claude self-generate>, N findings, M addressed

세션 단절 후 재개: /context:resume
작업 상태 저장:    /context:update

코딩 세션에서 /context:update 실행을 자동 리마인드하려면:
  /context:guard  — Stop hook 옵트인 설치
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
