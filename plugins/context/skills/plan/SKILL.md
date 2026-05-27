---
name: plan
description: Use when starting a new task from a raw idea and you want a resumable 4-file Dev Docs folder — /context:plan, "컨텍스트 플랜", "작업 폴더 만들어", "재개 가능한 계획"
user-invocable: true
---

# Context Plan — 4파일 Dev Docs 폴더 생성

raw 아이디어에서 출발해 `docs/context/{TASK_NAME}/`에 4파일 자기완결 폴더(spec/plan/tasks/context.md)를 만든다.
이 폴더 하나만 읽으면 세션이 끊겨도 정확히 재개된다.

---

## 실행 순서

### 1. 플랜모드 감지

시작 시 1회 확인한다. 플랜모드가 활성이면:
- read-only 단계(brainstorming Q&A, grill 질문)만 진행한다.
- 파일 쓰기 직전 사용자에게 Shift+Tab으로 플랜모드를 해제하도록 요청한다.
- **ExitPlanMode를 자체 호출하는 것은 절대 금지한다.**

### 2. TASK_NAME 정규화

ARGUMENTS로 받은 raw 아이디어(또는 사용자 입력)에서 TASK_NAME을 kebab slug으로 변환한다:
1. 소문자로 변환
2. 공백 → `-`
3. `[^a-z0-9-]` 문자 제거 (`../` 등 경로 traversal 자동 제거됨)
4. 연속 `-` 축약 (예: `--` → `-`)
5. 양끝 `-` 제거

결과 경로: `docs/context/{TASK_NAME}/`

### 3. 폴더 충돌 정책

`docs/context/{TASK_NAME}/` 존재 여부를 확인한다. 존재하면 AskUserQuestion으로 분기:
- **덮어쓰기**: 기존 작업 상태 소실 경고 후 진행
- **기존 작업 재개**: `context:resume`를 안내하고 종료
- **다른 이름으로 생성**: 새 TASK_NAME 입력 받기

비대화 모드(AskUserQuestion 불가) 기본값: suffix `-2` 추가.

### 4. brainstorming 호출 (location override) + 자동 체인 차단 + 파일위치 검증

`superpowers:brainstorming` 스킬을 호출하라.
ARGUMENTS:
- 사용자가 언급한 raw 아이디어 그대로
- (location override) spec 저장 위치를 기본값(`docs/superpowers/specs/...`) 대신
  `docs/context/{TASK_NAME}/spec.md`로 한다.
  이는 "User preferences for spec location override this default" 규칙에 따른
  ARGUMENTS 기반 명시적 경로 지정이다.
- (HARD-GATE 절단) spec 작성 + User Review Gate(사용자 승인)까지만 진행하고 거기서 정지하라.
  writing-plans를 호출하지 말 것 — 이 오케스트레이터가 grill을 거쳐 별도 호출한다.

> ⚠ 이 정지 지시가 없으면 brainstorming은 writing-plans를 하드와이어드 terminal state로 자동 실행하여
> `docs/superpowers/plans/`에 산출물이 생긴다. 차단 지점은 spec 작성 후 User Review Gate.

**파일위치 검증 (brainstorming 반환 직후 필수)**:
1. `test -f docs/context/{TASK_NAME}/spec.md` 확인.
2. 실패하면 `docs/superpowers/specs/` 아래 최신 `.md`를 찾아 정본 경로로 이동:
   `mv <found-path> docs/context/{TASK_NAME}/spec.md`
3. 재확인 후 진행.

**체크포인트**: User Review Gate 승인 즉시 `spec.md`가 정본 경로에 디스크에 확정됨을 확인한다.
이후 grill/writing-plans로 진행. 각 sub-skill 산출물은 다음 단계 진행 전 반드시 디스크에 확정되어야 한다.

### 5. grill-me 호출 (파일 미생성 보정)

`grill-me` 스킬을 호출하라.  (네임스페이스 없음 — `grill-me` 그대로)
ARGUMENTS: `docs/context/{TASK_NAME}/spec.md` 경로 + spec 핵심 1줄 요약

**보정 명시**: grill-me는 파일을 쓰지 않는 순수 대화형 스킬이다. grill 합의 결과(결정 사항)는
이 오케스트레이터가 대화에서 직접 캡처하여 Step 7의 `context.md` Decision Log에 기록한다.
grill 출력 파일을 읽으려 시도하지 말 것.

### 6. writing-plans 호출 (location override) + 파일위치 검증

`superpowers:writing-plans` 스킬을 호출하라.
ARGUMENTS:
- spec 경로 `docs/context/{TASK_NAME}/spec.md`
- (location override) plan 저장 위치를 기본값(`docs/superpowers/plans/...`) 대신
  `docs/context/{TASK_NAME}/plan.md`로 한다 (ARGUMENTS 기반 경로 지정).

**파일위치 검증 (writing-plans 반환 직후 필수)**:
1. `test -f docs/context/{TASK_NAME}/plan.md` 확인.
2. 실패하면 `docs/superpowers/plans/` 아래 최신 `.md`를 찾아 정본 경로로 이동:
   `mv <found-path> docs/context/{TASK_NAME}/plan.md`
3. 재확인 후 Step 7로 진행.

### 7. 분할·합성 + plan.md 트림

**tasks.md 추출**: plan.md의 `- [ ]` 체크리스트를 Phase별 그룹, `[P]` 병렬 마커,
체크포인트 보존하여 `docs/context/{TASK_NAME}/tasks.md`에 저장한다.

**context.md 생성**: 아래 템플릿으로 `docs/context/{TASK_NAME}/context.md`를 만든다.
- Current Status: 초기값 ("작업 폴더 생성 완료. tasks.md Step 1부터 시작.")
- Key Files: plan.md의 File Structure 섹션에서 추출
- Decision Log: Step 5(grill)에서 캡처한 합의 결정 사항
- Next Steps: tasks.md의 첫 번째 미완료 항목
- Blockers: "None"
- `Last Updated`: 오늘 날짜

```markdown
<!-- last_updated: YYYY-MM-DDTHH:MM:SSZ -->

## Current Status
<!-- 한 줄: 지금 전체적으로 어디까지 -->

## Key Files
<!-- 주요 파일 경로 + 한 줄 역할 -->

## Decision Log
<!-- grill 합의 + 구현 중 추가 결정 (spec 초기 설계결정과 구분) -->

## Next Steps
<!-- 바로 다음 할 일 -->

## Blockers / Known Issues
<!-- 막힌 것 / 미해결 -->

Last Updated: YYYY-MM-DD
```

> **스캔 키**: `update`·`resume`의 최신 태스크 선택은 `<!-- last_updated: ... -->` 주석 라인(ISO-8601 UTC)을
> grep하여 `sort -r` 정렬로 결정한다. `Last Updated:` 가시 라인은 사람용이며 스캔에 사용하지 않는다.

**plan.md 트림**: tasks.md 추출 후 plan.md에서 bite-sized task 단계(`### Task N` 및 그 하위 `- [ ]` step 전체)를
제거하고 Header(Goal/Architecture/Tech Stack) + File Structure만 남긴다.
자동 수행, 사용자 확인 불필요(무손실 이동).

### 8. 완료 핸드오프

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
docs/context/{TASK_NAME}/ 폴더 생성 완료
  spec.md    — brainstorming 설계 산출물
  plan.md    — 목표·아키텍처·파일 구조 (tasks 제거됨)
  tasks.md   — 실행 체크리스트
  context.md — 동적 재개 앵커

세션 단절 후 재개: /context:resume
작업 상태 저장:    /context:update

코딩 세션에서 /context:update 실행을 자동 리마인드하려면:
  /context:guard  — Stop hook 옵트인 설치
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
