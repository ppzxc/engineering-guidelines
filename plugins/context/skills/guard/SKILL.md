---
name: guard
description: Install the context:update staleness-reminder Stop hook into the host project — /context:guard, "훅 설치", "진행상황 강제 설치", "컨텍스트 가드"
user-invocable: true
---

# Context Guard — Stop hook 설치

코딩 세션에서 코드가 변경됐는데 `context.md`가 오래됐을 때 턴 종료 시
`/context:update` 실행을 리마인드하는 Claude Code Stop hook을 호스트 프로젝트에 설치한다.

플러그인 자체는 hook-free (ADR-0028). 이 스킬은 명시 호출 시에만 `.claude/settings.json`을 변경한다.

---

## 실행 순서

### 1. 플랜모드 감지

시작 시 플랜모드가 활성이면:
- `.claude/settings.json` 쓰기를 수행하지 않는다.
- 사용자에게 Shift+Tab으로 플랜모드를 해제하고 다시 실행하도록 안내한다.
- **ExitPlanMode를 자체 호출하는 것은 절대 금지한다.**

### 2. 이미 설치 확인 (idempotent)

`.claude/settings.json`이 존재하면 읽는다.
`hooks.Stop` 배열에 `context-staleness-check.sh`를 포함하는 항목이 이미 있으면
"이미 설치되어 있습니다"를 출력하고 종료한다.

### 3. 스크립트 파일 작성

`.claude/hooks/` 디렉토리가 없으면 생성한다.
아래 내용을 `.claude/hooks/context-staleness-check.sh`에 정확히 쓴다:

```sh
#!/usr/bin/env sh
# Claude Code Stop hook — /context:update staleness reminder.
# Non-blocking (exit 0 always). Prints JSON systemMessage when stale.
# ADR-0028: plugin stays hook-free; host opts in via context:guard.
# Known limitation: filenames with spaces may be mishandled (kebab-slug paths are safe).

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$GIT_ROOT" ] || exit 0

CONTEXT_DIR="$GIT_ROOT/docs/context"
[ -d "$CONTEXT_DIR" ] || exit 0

# Select most recently updated context.md by ISO-8601 last_updated marker
BEST_FILE=""
BEST_TS=""
for f in $(find "$CONTEXT_DIR" -maxdepth 2 -name "context.md" 2>/dev/null); do
  TS=$(grep -m1 '<!-- last_updated:' "$f" 2>/dev/null \
       | sed 's/.*<!-- last_updated: *\([^ ]*\).*/\1/' \
       | tr -d '\r')
  [ -z "$TS" ] && continue
  if [ -z "$BEST_TS" ] || [ "$TS" \> "$BEST_TS" ]; then
    BEST_TS="$TS"
    BEST_FILE="$f"
  fi
done
[ -n "$BEST_FILE" ] || exit 0

# Check for code changes outside docs/
CHANGED=$(git -C "$GIT_ROOT" status --porcelain 2>/dev/null \
          | awk '{print $NF}' | grep -vE '^(docs|\.claude)/' | head -1)
[ -n "$CHANGED" ] || exit 0

# Convert last_updated ISO-8601 to epoch (GNU date; BSD/macOS fallback)
LAST_EPOCH=$(date -d "$BEST_TS" +%s 2>/dev/null)
if [ -z "$LAST_EPOCH" ]; then
  LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$BEST_TS" +%s 2>/dev/null)
fi
[ -n "$LAST_EPOCH" ] || exit 0

# Find newest mtime among changed code files
NEWEST=0
for f in $(git -C "$GIT_ROOT" status --porcelain 2>/dev/null \
           | awk '{print $NF}' | grep -vE '^(docs|\.claude)/'); do
  fp="$GIT_ROOT/$f"
  [ -f "$fp" ] || continue
  MT=$(stat -c %Y "$fp" 2>/dev/null)
  [ -z "$MT" ] && MT=$(stat -f %m "$fp" 2>/dev/null)
  [ -z "$MT" ] && continue
  [ "$MT" -gt "$NEWEST" ] && NEWEST=$MT
done

# If all changed files were deleted (no mtime available), treat as stale
[ "$NEWEST" -eq 0 ] && NEWEST=$(date +%s 2>/dev/null || printf '%s' '9999999999')

[ "$NEWEST" -gt "$LAST_EPOCH" ] || exit 0

# Stale: emit non-blocking reminder
TASK=$(dirname "$BEST_FILE" | sed "s|$GIT_ROOT/||")
printf '{"systemMessage":"⚠️  %s/context.md 가 stale입니다. /context:update 로 진행상황을 기록하세요."}\n' "$TASK"
exit 0
```

> **스키마 참고**: Stop hook 비차단 출력에 `{"systemMessage":"..."}` 형식을 사용한다.
> `decision` 필드는 Stop hook에서 `block` 또는 생략만 유효하며, 비차단 reminder는 decision 없이 systemMessage 단독으로 emit한다.

### 4. 사용자 확인

AskUserQuestion으로 확인을 받는다:
- 제목: "`.claude/settings.json`에 Stop hook을 추가합니다"
- 설명: 추가될 JSON 구조를 보여주고 계속 여부를 묻는다.
- 취소 시: 작성한 스크립트 파일(`.claude/hooks/context-staleness-check.sh`)을 삭제하고 종료.

### 5. settings.json 갱신

기존 `.claude/settings.json`을 읽는다(없으면 `{}`로 시작).
`hooks.Stop` 배열에 아래 항목을 **append** 한다 (기존 Stop hook 항목 및 다른 키는 보존):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh -c 'root=$(git rev-parse --show-toplevel 2>/dev/null) && sh \"$root/.claude/hooks/context-staleness-check.sh\" 2>/dev/null; true'"
          }
        ]
      }
    ]
  }
}
```

`permissions` 등 기존 키를 덮어쓰지 않도록 기존 내용과 병합하여 저장한다.

### 6. 완료 보고

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
context:guard 설치 완료
  .claude/hooks/context-staleness-check.sh  — staleness 체크 스크립트
  .claude/settings.json  — Stop hook 항목 추가됨

동작: 코드 파일을 변경한 후 턴이 종료될 때 context.md가 stale이면
      ⚠️  경고 메시지가 표시됩니다.

제거 방법:
  1. .claude/settings.json 에서 context-staleness-check.sh 관련 Stop hook 항목 제거
  2. .claude/hooks/context-staleness-check.sh 삭제
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
