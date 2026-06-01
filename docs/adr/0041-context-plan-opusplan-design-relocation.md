# context:plan opusplan 호환 재설계 — 전체 설계를 플랜모드(Opus)로 이동, ExitPlanMode를 릴리스 게이트로 재배치

* Status: accepted
* Date: 2026-06-01
* Decision Makers: ppzxc
* Consulted: —
* Informed: —

## Context and Problem Statement

`/context:plan` 실행 시 두 가지 버그가 관측됐다: (1) 산출물인 `docs/context/{TASK}/` 4파일이 생성되지 않음. (2) ExitPlanMode 승인 직후 소스코드 편집이 자동 시작됨. 원인 분석 결과, 글로벌 설정 `"model": "opusplan"`으로 인해 플랜모드=Opus, 플랜모드 밖=Sonnet인 환경에서 하니스 네이티브 Plan Workflow가 context:plan 스킬을 가리고, ExitPlanMode 승인이 "지금 구현" 기본값으로 연결된 것이 근본 원인이다. 추가로 ADR-0030의 아키텍처(spec만 플랜모드, plan·tasks·GAN은 ExitPlanMode 이후=Sonnet)가 "전체 Opus 설계" 사용자 의도와 불일치한다.

## Decision Drivers

* opusplan 사용자는 `/context:plan` 전체(spec·plan·tasks·GAN)를 Opus로 설계하기를 원한다.
* ExitPlanMode 승인 이후는 Sonnet이므로, 창의·판단 작업 전부가 ExitPlanMode 이전에 끝나야 한다.
* ExitPlanMode 승인의 하니스 기본값("지금 구현")이 context:plan의 "4파일 생성 후 종료" 의도를 덮어쓴다 — 부정형 가드 부재 확인.
* 스킬이 로드되지 않는 문제(네이티브 Plan Workflow가 선점)를 라우팅 강화로 차단해야 한다.

## Considered Options

* **Option A**: ADR-0030 구조 유지 + 터미널 계약 가드만 추가 (spec 게이트=ExitPlanMode 유지, plan/tasks/GAN=Sonnet).
* **Option B (채택)**: 전체 설계(spec·plan·tasks·GAN)를 플랜모드(Opus) 내로 이동. spec 사람 리뷰를 AskUserQuestion으로. ExitPlanMode를 최종 릴리스 게이트로. ExitPlanMode 이후는 순수 기계적 전사+종료.
* **Option C**: 플랜모드 제거, AskUserQuestion만으로 모든 게이트 처리 (opusplan 이점 상실).

## Decision Outcome

Chosen option: **Option B**, because opusplan 환경에서 ExitPlanMode 이후는 Sonnet이므로 창의·판단 작업(plan 구조화·tasks 분해·GAN 검증) 전부를 ExitPlanMode 이전 플랜모드(Opus)에 배치해야 사용자 의도를 충족한다. spec 게이트는 플랜모드를 유지하는 AskUserQuestion으로 대체해 Opus 세션을 끊지 않으며, ExitPlanMode는 완성된 Opus 설계를 최종 제시·승인받는 릴리스 게이트로 재용도화된다.

### Consequences

* Good, because spec·plan·tasks·GAN 전부 Opus가 수행 — 설계 품질 최대.
* Good, because ExitPlanMode 이후 Sonnet은 기계적 전사만 수행 — 의도치 않은 구현 시작 불가.
* Good, because 터미널 계약 가드 2곳(스킬 상단·전사 단계 진입부) 명문화 — "소스코드 편집 금지" 부정형 규칙 최초 추가.
* Good, because `docs/superpowers/plans/` mv 탐색 로직 제거 — ADR-0027이 우려한 임의 mv 경로 사라짐.
* Bad, because spec 거부 루프(AskUserQuestion 기반)가 플랜모드를 계속 유지하므로 컨텍스트 길이가 길어질 수 있다 (MAX_RETRIES=3 한도로 완화).
* Bad, because writing-plans가 플랜모드 내 no-disk-write 모드로 실행되어 crash-absorb 패턴에 의존한다 (기존 brainstorming과 동일 패턴).

### Confirmation

1. SKILL.md를 처음부터 따라 읽어 (a) 모든 설계(spec/plan/tasks/GAN)가 ExitPlanMode 前인지, (b) post-exit이 전사+STOP뿐인지, (c) spec 게이트가 AskUserQuestion인지 확인.
2. `grep -n '소스코드\|구현 금지\|기계적 전사' plugins/context/skills/plan/SKILL.md` — 터미널 계약 2곳 확인.
3. context-rules.md에 `[ADR-0041]` 태그 항목 2개 존재 확인.
4. `/context:plan <소형 아이디어>` 실행 → 4파일 생성·구현 미착수·플랜모드 Opus 흐름 육안 확인.

## Pros and Cons of the Options

### Option A — ADR-0030 유지 + 가드만 추가

* Good, because 변경 범위 최소
* Bad, because plan/tasks/GAN이 여전히 ExitPlanMode 이후(Sonnet) — 전체 Opus 의도 미충족
* Bad, because ExitPlanMode 승인 후 "지금 구현" 기본값 차단 강도 약함

### Option B — 전체 설계 플랜모드(Opus) 이동 (채택)

* Good, because 모든 설계 = Opus (opusplan 의도 완전 충족)
* Good, because 터미널 계약 명문화로 자동 구현 원천 차단
* Bad, because 스킬 재작성 규모 큼
* Bad, because writing-plans no-disk-write crash-absorb 패턴 의존

### Option C — 플랜모드 제거

* Good, because 네이티브 Plan Workflow 충돌 없음
* Bad, because opusplan 이점(플랜모드=Opus) 상실 — 사용자 요구 불충족

## More Information

- Supersedes (부분): [ADR-0030](0030-context-plan-pipeline-redesign.md) — 게이트 배치(ExitPlanMode=spec 게이트 → AskUserQuestion=spec 게이트, ExitPlanMode=릴리스 게이트로 재배치), plan·tasks·GAN 실행 위치(ExitPlanMode 이후 → 이전).
- ADR-0030의 나머지(grill 우선 배치, 자동연계 허용, GAN 단일 게이트, MAX_RETRIES 루프)는 유지.
- 관련 rules: `context-rules.md` `[ADR-0041]` 태그 항목.
- 관련 스킬: `plugins/context/skills/plan/SKILL.md` Step 5~9 재작성, `references/verification.md` GAN 대상 갱신.
