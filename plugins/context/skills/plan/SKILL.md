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

### Step 0. ARGUMENTS 파싱 및 검사

#### (0a) 디시플린 플래그 추출

ARGUMENTS 에서 아래 패턴의 토큰을 추출하여 제거한다.

| 플래그 형식 | 변수 |
|------------|------|
| `--no-karpathy=<reason>` | `NO_KARPATHY=1`, `KARPATHY_REASON=<reason>` |
| `--no-tdd-tidy=<reason>` | `NO_TDD_TIDY=1`, `TDD_TIDY_REASON=<reason>` |

**reason 누락(플래그만 존재, `=` 없거나 우측 공백)**:
- 대화 모드: AskUserQuestion 으로 reason 수집 ("옵트아웃 사유를 입력해 주세요: `--no-{flag}` 를 사용하는 이유").
- 비대화 모드: 에러 메시지 출력 후 즉시 종료. (`--no-{flag}=<reason>` 형식으로 다시 호출하도록 안내)

플래그 토큰 제거 후 잔여 ARGUMENTS 를 `RAW_IDEA` 로 사용한다. **이후 모든 단계는 RAW_IDEA 만 사용한다 (flag 누출 차단).**

#### (0b) RAW_IDEA 검사

RAW_IDEA 가 비었는지 확인한다.

- **비었음(대화 모드)**: AskUserQuestion으로 "어떤 작업을 시작할까요?" 질문한다.
- **비었음(비대화 모드 — AskUserQuestion 불가)**: 에러 메시지 출력 후 즉시 종료. (`/context:plan <아이디어>` 형식으로 다시 호출하도록 안내)
- **있음**: Step 1로 진행.

### Step 1. 플랜모드 감지 및 자동 진입

플랜모드 활성 여부를 확인한다.

- **이미 활성**: 그대로 진행.
- **미활성**: `EnterPlanMode`를 호출하여 자동 진입한다. 이후 Step 2부터 탐색 단계(Step 5 완료)까지 플랜모드를 유지한다.

탐색 단계(Step 2–5)는 플랜모드 안에서 read-only로 진행된다. 단, spec 내용은 **플랜 파일**에 기록한다(플랜모드가 허용하는 유일한 쓰기).

### Step 2. TASK_NAME 정규화

RAW_IDEA 에서 TASK_NAME을 kebab slug으로 변환한다 (flag 토큰은 Step 0a 에서 이미 제거됨):
1. 소문자로 변환
2. 공백 → `-`
3. `[^a-z0-9-]` 문자 제거 (`../` 등 경로 traversal 자동 제거됨)
4. 연속 `-` 축약 (예: `--` → `-`)
5. 양끝 `-` 제거

**빈 슬러그 방지**: 변환 결과가 빈 문자열이면 (한글·이모지 전용 입력 등):
- 대화 모드: AskUserQuestion으로 영문 slug 요청 (`어떤 영문 slug를 사용할까요? 예: my-feature`)
- 비대화 모드: 에러 출력 후 즉시 종료 (`TASK_NAME이 비어 있습니다. 영문·숫자를 포함한 아이디어로 다시 호출하세요.`)

결과 경로: `docs/context/{TASK_NAME}/`

### Step 3. 폴더 충돌 정책

`docs/context/{TASK_NAME}/` 존재 여부를 확인한다. 존재하면 AskUserQuestion으로 분기:
- **덮어쓰기**: 기존 작업 상태 소실 경고 후 진행
- **기존 작업 재개**: `ExitPlanMode` 호출 후 `context:resume`를 안내하고 종료
- **다른 이름으로 생성**: 새 TASK_NAME 입력 받기

비대화 모드(AskUserQuestion 불가) 기본값: suffix `-2` 추가.
`docs/context/{TASK_NAME}-2/`도 존재하면 `-3`, `-4`… 순서로 빈 슬롯을 찾는다 (최대 `-9`; 모두 사용 중이면 `ExitPlanMode` 호출 후 에러 출력 후 종료).

### Step 4. grill-me 호출 (raw 아이디어 발산)

`grill-me` 스킬을 호출하라. (네임스페이스 없음 — `grill-me` 그대로)

ARGUMENTS: raw 아이디어 + 의도 한 줄 요약

**grill-me는 파일을 쓰지 않는 순수 대화형 스킬이다.** grill 합의 결과(결정 사항)는
이 오케스트레이터가 대화에서 직접 캡처한다. grill 출력 파일을 읽으려 시도하지 말 것.

**결정 사항 영속화**: grill 합의 결정을 플랜 파일(플랜모드 허용 쓰기)에 즉시 기록한다.
Step 7에서 context.md Decision Log 작성 시 이 기록을 소스로 사용한다.
(in-context 메모리만 의존하면 Step 4→7 사이 컨텍스트 compaction 시 결정 사항 소실.)

### Step 5. brainstorming 호출 + spec 플랜 파일 기록 + 사람 리뷰 게이트 ★

**[디시플린] karpathy 풀 Skill 디스패치:**

`NO_KARPATHY` 가 설정되지 않은 경우: `guideline:karpathy` 스킬을 호출하라 (정확한 등록명, 추론 금지).
brainstorming 에서 spec scope 결정 시 karpathy simplicity/surgical lens 가 적용되도록 한다.

**brainstorming 호출:**

`superpowers:brainstorming` 스킬을 호출하라.
ARGUMENTS:
- grill에서 발산된 아이디어 + 보완 포인트
- **"디스크 쓰기 금지, spec 내용만 산출"** 명시 — 플랜모드가 sub-skill의 파일 쓰기를 차단한다.
  brainstorming이 쓰기를 시도하다 차단되어도 오케스트레이터가 대화에서 spec 내용을 캡처해
  플랜 파일에 기록하고 계속 진행한다(크래시 흡수).
- HARD-GATE 차단 없음 — writing-plans 자동연계는 이후 Step 6에서 오케스트레이터가 직접 제어한다.
- `NO_KARPATHY` 미설정이면: "spec scope 에 karpathy simplicity/surgical lens 적용. flag·reason 토큰은 spec 본문에 절대 포함 금지" 한 줄 추가.

**spec 내용을 플랜 파일에 기록:**

brainstorming이 산출한 spec 내용을 **지정 플랜 파일**에 작성한다.
이 파일이 ExitPlanMode 제시 화면에 표시된다.

**[디시플린] 옵트아웃 기록:**

옵트아웃 플래그가 설정된 경우, spec.md 작성 시 **본문 첫 줄 위치** 에 blockquote 라인을 삽입한다:
```markdown
> Discipline opt-out: --no-tdd-tidy (reason: <TDD_TIDY_REASON>)
> Discipline opt-out: --no-karpathy (reason: <KARPATHY_REASON>)
```
해당 플래그가 설정된 만큼만 (최대 2 줄). 디폴트 케이스(옵트아웃 없음)는 변경 없음.

**ExitPlanMode = spec 사람 리뷰 게이트 ★최우선 게이트★:**

`ExitPlanMode`를 호출한다. 플랜 파일(= spec)이 사용자에게 제시되고 승인을 받는다.

```
├ 승인 → 플랜모드 해제 → Step 6으로 진행
└ spec 오류 → 플랜모드 유지 (ExitPlanMode 미해제)
     → grill-me 재호출 (현재 spec 기반, 틀린 점 발산)
     → brainstorming spec 갱신 → 플랜 파일 갱신 → ExitPlanMode 재제시 (루프)
     ※ MAX_RETRIES = 3. **카운터를 명시적으로 추적한다**: 첫 rejection 전 `SPEC_RETRY=0` 초기화,
       매 재시도 서두에 `[spec-retry N/3]`을 출력하고 **플랜 파일에 기록**하여 컨텍스트 초기화 후에도 복구 가능하게 한다.
       `SPEC_RETRY >= 3`이면 루프 중단, 미해결 항목을 Step 7의 context.md Blockers에 이관 후 진행.
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
- `NO_TDD_TIDY` 미설정이면: "tasks.md 의 모든 `- [ ]` 항목에 `[S]`(structural) 또는 `[B]`(behavioral) 태그 필수. `[S]` 항목을 동일 Phase 내 `[B]` 보다 먼저 배치. non-trivial `[B]` 항목은 `- [ ] RED: <test>` / `- [ ] GREEN: <minimal impl>` / `- [ ] REFACTOR: <cleanup>` 3 sub-step 으로 분해. trivial [B](한 줄 수정·typo·import 정리·테스트 커버 영역의 단순 값 변경)는 single line 허용. 커밋 prefix = 프로젝트 convention 우선, 없으면 ♻️ refactor / 🧹 tidy / ✨ feat / 🐛 fix"
- `NO_KARPATHY` 미설정이면: "karpathy lens 유지: scope·simplicity·surgical 그대로 (spec 에서 결정된 범위 이상 확장 금지)"

**파일위치 검증 (writing-plans 반환 직후 필수)**:
1. `test -f docs/context/{TASK_NAME}/plan.md` 확인.
2. 실패하면 `docs/superpowers/plans/` 아래 파일명에 `{TASK_NAME}`이 포함된 최신 `.md`를 먼저 찾는다.
   - 이름 매칭 성공: 내용 헤더 검증(Goal 섹션 존재) 후 이동. 실패 시 에러 출력 후 종료.
   - 이름 매칭 실패: 임의 파일 `mv` 금지 [ADR-0027]. writing-plans 재호출(override 위치 직접 쓰기)만 허용.
3. 재확인 후 진행.

**[Step-6 Gate] GAN cross-check (순서 고정):**

`references/verification.md`의 **Step-6 Gate**를 실행하라.

GAN gate 는 `plan.md` 의 **디시플린 의도**만 평가한다 (tasks.md 는 Step 7 이후 생성 — 여기서 검증 불가).

TMPFILE 빌드 전 `{DISCIPLINE_STATE}` 자리에 실제 상태를 주입한다:
- `NO_KARPATHY` 미설정 → `karpathy=on` / 설정 → `karpathy=off(<KARPATHY_REASON>)`
- `NO_TDD_TIDY` 미설정 → `tdd-tidy=on` / 설정 → `tdd-tidy=off(<TDD_TIDY_REASON>)`
예: `DISCIPLINE: karpathy=on tdd-tidy=off(minimal 변경)`

dicipline 단락은 항상 GAN 프롬프트에 포함된다 (verification.md TMPFILE 빌드 참조). self-generate fallback 시 별도 추가 불필요.

### Step 7. 분할·합성 + plan.md 트림

**tasks.md 추출**: plan.md의 `- [ ]` 체크리스트를 `## Task N` 또는 `### Task N` 섹션 기준,
Phase별 그룹, `[P]` 병렬 마커, 체크포인트 보존하여 `docs/context/{TASK_NAME}/tasks.md`에 저장한다.

**context.md 생성**: 아래 템플릿으로 `docs/context/{TASK_NAME}/context.md`를 만든다.
- Current Status: 초기값 ("작업 폴더 생성 완료. tasks.md Step 1부터 시작.")
- Key Files: plan.md의 File Structure 섹션에서 추출
- Decision Log: Step 4(grill)에서 **플랜 파일에 기록한** 합의 결정 사항 + GAN provenance
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

**last_updated 필수 충전**: 생성 시 `<!-- last_updated: ... -->` 주석과 `Last Updated:` 라인 모두 실제 ISO-8601 UTC 타임스탬프로 채울 것.
(`context:resume`·`context:update`가 주석을 grep+`sort -r`로 활성 task를 선택하므로, 리터럴 플레이스홀더가 잔류하면 sort 오염 발생.)

**plan.md 트림**: tasks.md 추출 후 plan.md에서 bite-sized task 단계(`## Task N` 또는 `### Task N` 및 그 하위 `- [ ]` step 전체)를
제거하고 Header(Goal/Architecture/Tech Stack) + File Structure만 남긴다.
자동 수행, 사용자 확인 불필요(무손실 이동).

**Step-7 검증:**
- `grep -cE '^#{2,4} Task' docs/context/{TASK_NAME}/plan.md` == 0 (trim 완료)
- `grep -c -- '- \[ \]' docs/context/{TASK_NAME}/tasks.md` > 0 (추출 성공)

**[디시플린] tasks.md 태그 검증 (`NO_TDD_TIDY` 미설정 시만):**

```bash
TASKS="docs/context/${TASK_NAME}/tasks.md"
untagged=$(grep -E '^[[:space:]]*- \[ \]' "$TASKS" | grep -vE '\[(S|B)\]' | wc -l)
tagged=$(grep -cE '^[[:space:]]*- \[ \].*\[(S|B)\]' "$TASKS")
if [ "$untagged" -gt 0 ] || [ "$tagged" -eq 0 ]; then
    # 디시플린 검증 실패 → 사용자 결정 (대화 모드)
    # AskUserQuestion 으로 3 옵션 제시:
    # (1) "재시도" — writing-plans 재호출, 미분류 항목에 [S]/[B] 보강 지시
    # (2) "수동 수정" — tasks.md 직접 편집 후 재검증 실행
    # (3) "post-hoc opt-out" — spec.md 상단에 "> Discipline opt-out: post-hoc (discipline check failed, N untagged items)" blockquote 자동 추가 후 진행
    # 비대화 모드: 에러 메시지 출력 후 종료
fi
```

**주의 (Known Limitation):** `untagged==0` 검증은 태그 존재만 확인한다. 모든 항목에 `[S]` 만 있어도 통과한다. 시맨틱 강제력은 Step 6 GAN (plan.md 의도 평가) + 사용자 spec 리뷰 (ExitPlanMode) 에 의존한다.

### Step 8. 완료 핸드오프

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
docs/context/{TASK_NAME}/ 폴더 생성 완료
  spec.md    — brainstorming 설계 산출물
  plan.md    — 목표·아키텍처·파일 구조 (tasks 제거됨)
  tasks.md   — 실행 체크리스트
  context.md — 동적 재개 앵커
  [GAN review] — <agy|gemini|codex|Claude self-generate>, N findings, M addressed
  [discipline] karpathy=<on|off(reason)> tdd-tidy=<on|off(reason)>

세션 단절 후 재개: /context:resume
작업 상태 저장:    /context:update

코딩 세션에서 /context:update 실행을 자동 리마인드하려면:
  /context:guard  — Stop hook 옵트인 설치
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
