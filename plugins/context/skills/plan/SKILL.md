---
name: plan
description: Use when starting a new task from a raw idea and you want a resumable 4-file Dev Docs folder — /context:plan, "컨텍스트 플랜", "작업 폴더 만들어", "재개 가능한 계획", "context plan". IMPORTANT: When the user types /context:plan, invoke this skill with the Skill tool BEFORE any other action, including entering plan mode.
user-invocable: true

---

# Context Plan — 4파일 Dev Docs 폴더 생성

raw 아이디어에서 출발해 `docs/context/{TASK_NAME}/`에 4파일 자기완결 폴더(spec/plan/tasks/context.md)를 만든다.

> **⛔ 터미널 계약**: 유일한 산출물은 4개 마크다운 파일. 소스코드 편집 불가. ExitPlanMode 승인 후 기계적 전사+종료만.

---

## 실행 로그 컨벤션

각 Step 진입 시 `━━━ [Step N/9] <제목> ━━━` 를 대화에 출력.

| Step | 제목 |
|------|------|
| 0/9 | ARGUMENTS 파싱 및 검사 |
| 1/9 | 플랜모드 감지 및 자동 진입 |
| 2/9 | TASK_NAME 정규화 |
| 3/9 | 폴더 충돌 정책 |
| 4/9 | Design 생성 |
| 5/9 | grill-me 경화 + spec 사람 리뷰 게이트 |
| 6/9 | Plan 구조화 + GAN gate |
| 7/9 | 최종 릴리스 게이트 (ExitPlanMode) |
| 8/9 | 4파일 전사 + 검증 |
| 9/9 | 완료 핸드오프 |

---

## 실행 순서

### Step 0. ARGUMENTS 파싱 및 검사

→ 플래그 파싱 규칙: `references/discipline-flags.md`

diff 시그널(`diff --git` / `--- a/`) 감지 시 `git:review` 안내 후 즉시 종료(EnterPlanMode 호출 금지).

INPUT_TYPE 결정: 명시 인자(`idea|spec|plan`) → 휴리스틱(`## Decision Outcome`/`- [ ]` ≥3/기타→idea).

### Step 1. 플랜모드 감지 및 자동 진입

미활성 시 `EnterPlanMode` 호출. Step 6 완료(GAN gate)까지 유지. Step 2–6은 Opus가 플랜모드 내 수행.

### Step 2. TASK_NAME 정규화

RAW_IDEA → kebab slug(소문자, 공백→`-`, `[^a-z0-9-]` 제거). 빈 슬러그 시 대화 모드: AskUserQuestion, 비대화 모드: 에러+종료.

### Step 3. 폴더 충돌 정책

`docs/context/{TASK_NAME}/` 존재 시 AskUserQuestion(덮어쓰기/재개/새이름). 비대화 기본: `-2` suffix.

### Step 4. Design 생성 (INPUT_TYPE 의존)

- **idea**: `guideline:karpathy` → `superpowers:brainstorming` → spec 기록. 옵트아웃 blockquote → `references/discipline-flags.md`
- **spec**: RAW_IDEA를 spec 섹션에 직접 기록.
- **plan**: RAW_IDEA를 spec·plan 소스로 분리 기록.

### Step 5. grill-me 경화 + spec 사람 리뷰 게이트

→ `context:verify-spec` 서브스킬 위임 (Phase A): grill-me 호출 + AskUserQuestion 재시도 루프.

### Step 6. Plan 구조화 + GAN gate

- idea/spec: `superpowers:writing-plans` 호출(디스크 쓰기 금지) → plan·tasks 플랜 파일 기록.
- plan: 기존 tasks 정규화(`[S]`/`[B]` 태그, Phase 내 순서).
- GAN: `references/verification.md` Step-6 Gate 실행. `{DISCIPLINE_STATE}` 주입 후 H-severity 보정(1회).

### Step 7. 최종 릴리스 게이트 (ExitPlanMode)

→ `context:verify-spec` 서브스킬 위임 (Phase B): 마찰 최소화 라인 삽입 후 ExitPlanMode 호출.

---

## ━━━ 전사 단계 (플랜모드 OFF · 기계적 전사만) ━━━

### Step 8. 4파일 전사 + 구문 검사

`spec.md` / `tasks.md`(체크리스트 추출) / `plan.md`(tasks 제거, Header+FileStructure+VerificationCommand 잔류) / `context.md` 생성.
`context.md` `<!-- last_updated: ... -->` 및 `Last Updated:` 실제 ISO-8601 UTC로 충전(플레이스홀더 금지).
`NO_TDD_TIDY` 미설정 시 `[S]`/`[B]` 태그 구문 검증(Syntax Validation). 미충족 시 AskUserQuestion(태그추가/수동수정/post-hoc opt-out).

### Step 9. 완료 핸드오프

```
docs/context/{TASK_NAME}/ 완료 — /context:recall 로 재개, /context:update 로 상태 저장, /context:guard 로 Stop hook 설치
```
