# Context 플러그인

**Context** 플러그인은 세션이 끊겨도 재개 가능한 Dev Docs 시스템을 제공한다.
`docs/context/{TASK_NAME}/` 폴더 하나만 읽으면 정확히 이어서 작업할 수 있다.

## 스킬 목록

| 스킬 | 트리거 | 설명 |
|------|--------|------|
| `plan` | `/context:plan` | 입력을 분류(idea/spec/plan/diff)하여 4파일 Dev Docs 폴더를 생성. idea: brainstorming → grill-me → writing-plans; spec: grill-me → writing-plans; plan: grill-me → tasks 정규화; diff: /git:review로 redirect |
| `update` | `/context:update` | 컨텍스트 압축 직전 현재 세션 상태를 폴더에 저장 |
| `recall` | `/context:recall` | 세션 단절 후 4파일을 읽어 작업을 재개 |
| `guard` | `/context:guard` | 코드가 stale일 때 `/context:update` 실행을 리마인드하는 옵트인 Stop hook 설치 |

## 산출물 구조

각 태스크는 자기완결 폴더를 생성한다:

```
docs/context/{TASK_NAME}/
  spec.md      — brainstorming 설계 산출물 (보존)
  plan.md      — 목표·아키텍처·파일 구조 (tasks 제거됨)
  tasks.md     — 추출된 체크리스트
  context.md   — 동적 재개 앵커 (현재 상태 / 결정 로그 / 다음 할 일 / 블로커)
```

`context.md` 최상단의 `<!-- last_updated: ISO-8601 -->` 마커를 `update`·`recall`가 grep하여 최신 태스크를 자동 선택한다.

## Stop hook (옵트인)

`context:guard`는 호스트 프로젝트의 `.claude/settings.json`에 Claude Code Stop hook을 설치한다.
코딩 세션이 끝날 때 마지막 `context:update` 이후 코드가 변경됐으면 아래 경고가 표시된다:

```
⚠️  docs/context/<task>/context.md 가 stale입니다. /context:update 로 진행상황을 기록하세요.
```

**동작 방식**: non-blocking (reminder-only, `decision:block` 미사용).  
**설치**: 프로젝트별 1회, 플랜모드 밖에서 `/context:guard` 실행.  
**제거**: `.claude/settings.json`에서 해당 Stop hook 항목 삭제 + `.claude/hooks/context-staleness-check.sh` 삭제.

플러그인 자체는 hook-free를 유지한다 (ADR-0028 참조). Stop hook은 플러그인이 아닌 호스트 프로젝트 설정에 저장된다.

## 휴대성 원칙

이 플러그인은 런타임에 호스트 프로젝트의 컨벤션을 상속한다.
ADR 번호와 rules 파일 경로는 스킬 파일 안에 하드코딩하지 않는다 — 호스트의 `docs/adr/`와 `.claude/rules/`에 둔다.

## 설치

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

## 디시플린 (디폴트 ON)

`/context:plan` 은 karpathy/tdd/tidy 디시플린을 디폴트로 주입한다. 단일 토큰 플래그로 옵트아웃:

- `--no-karpathy=<reason>` — simplicity/surgical 설계 lens 비활성
- `--no-tdd-tidy=<reason>` — tasks.md 의 [S]/[B] 태그 + RGR sub-step 비활성

옵트아웃 reason 은 필수이며 `spec.md` 최상단 blockquote 에 기록된다. [ADR-0032] 참조.

## 사용법

```bash
/context:plan  raw 아이디어를 여기에
/context:plan --no-tdd-tidy=throwaway-prototype "빠른 스파이크"
/context:update
/context:recall
/context:guard   # 선택: staleness reminder hook 설치
```
