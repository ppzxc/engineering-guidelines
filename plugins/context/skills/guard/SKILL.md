---
name: guard
description: Install the context:update staleness-reminder Stop hook into the host project — /context:guard, "훅 설치", "진행상황 강제 설치", "컨텍스트 가드"
user-invocable: true
disable-model-invocation: true
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
# Claude Code Stop hook — context:update auto-run on staleness.
# Emits decision:block+reason when relevant context is stale; exit 0 otherwise.
# ADR-0028 superseded by ADR-0031.
# Known limitation: paths containing spaces may parse incorrectly (kebab-slug paths safe).

# 1. LOOP GUARD — stdin must be read first to prevent re-block on auto-run turn
# [ -t 0 ]: skip cat when stdin is a TTY (manual debug run), avoids hang
[ -t 0 ] && INPUT='' || INPUT=$(cat 2>/dev/null)
printf '%s' "$INPUT" | grep -qE '"stop_hook_active"[[:space:]]*:[[:space:]]*true|"stopHookActive"[[:space:]]*:[[:space:]]*true' && exit 0

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$GIT_ROOT" ] || exit 0

CONTEXT_DIR="$GIT_ROOT/docs/context"
[ -d "$CONTEXT_DIR" ] || exit 0

# 2. Collect changed code files — robust parsing + artifact exclusion
# cut -c4- strips porcelain status prefix; sed handles rename "old -> new" notation
ARTIFACT_RE='(^|/)(\.idea|\.vscode|\.fleet|\.gradle|node_modules|target|build|dist|out)/|\.(iml|ipr|iws)$'

CHANGED=$(git -C "$GIT_ROOT" status --porcelain 2>/dev/null \
  | cut -c4- | sed 's/^.* -> //' \
  | grep -vE '^(docs|\.claude)/' \
  | grep -vE "$ARTIFACT_RE")

[ -n "$CHANGED" ] || exit 0

# 3. Find relevant context — scope-prefix match or full-path match (no basename)
# Context is relevant if: (a) its <!-- scope: prefix --> covers a changed file, or
# (b) no scope declared and a changed file's full relative path appears in context docs.
BEST_FILE=""
BEST_TS=""

for CTX_MD in $(find "$CONTEXT_DIR" -maxdepth 2 -name "context.md" 2>/dev/null); do
  TS=$(grep -m1 '<!-- last_updated:' "$CTX_MD" 2>/dev/null \
       | sed 's/.*<!-- last_updated: *\([^ ]*\).*/\1/' \
       | tr -d '\r')
  [ -z "$TS" ] && continue

  MATCHED=0
  CTX_DIR_PATH=$(dirname "$CTX_MD")

  SCOPE=$(grep -m1 '<!-- scope:' "$CTX_MD" 2>/dev/null \
          | sed 's/.*<!-- scope: *//;s/ *-->.*//' | tr ',' '\n' \
          | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [ -n "$SCOPE" ]; then
    for cf in $CHANGED; do
      for prefix in $SCOPE; do
        [ -z "$prefix" ] && continue
        case "$cf" in
          "$prefix" | "$prefix"/*) MATCHED=1; break 2 ;;
        esac
      done
    done
  else
    for cf in $CHANGED; do
      [ -z "$cf" ] && continue
      if grep -qlF "$cf" "$CTX_DIR_PATH"/*.md 2>/dev/null; then
        MATCHED=1
        break
      fi
    done
  fi

  [ "$MATCHED" -eq 1 ] || continue

  if [ -z "$BEST_TS" ] || [ "$TS" \> "$BEST_TS" ]; then
    BEST_TS="$TS"
    BEST_FILE="$CTX_MD"
  fi
done

[ -n "$BEST_FILE" ] || exit 0

# 4. Convert last_updated ISO-8601 to epoch (GNU date; BSD/macOS fallback)
LAST_EPOCH=$(date -d "$BEST_TS" +%s 2>/dev/null)
if [ -z "$LAST_EPOCH" ]; then
  # Normalize for BSD date: strip subseconds, trailing Z, timezone offset; re-add Z
  TS_NORM=$(printf '%s' "$BEST_TS" \
    | sed 's/\.[0-9]*//' \
    | sed 's/Z$//' \
    | sed 's/[+-][0-9][0-9]:[0-9][0-9]$//')
  case "$TS_NORM" in
    *T*) TS_NORM="${TS_NORM}Z" ;;
    *)   TS_NORM="${TS_NORM}T00:00:00Z" ;;
  esac
  LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$TS_NORM" +%s 2>/dev/null)
fi
[ -n "$LAST_EPOCH" ] || exit 0

# 5. Find newest mtime among changed code files
NEWEST=0
for f in $CHANGED; do
  fp="$GIT_ROOT/$f"
  [ -f "$fp" ] || continue
  MT=$(stat -c %Y "$fp" 2>/dev/null)
  [ -z "$MT" ] && MT=$(stat -f %m "$fp" 2>/dev/null)
  [ -z "$MT" ] && continue
  [ "$MT" -gt "$NEWEST" ] && NEWEST=$MT
done

# If all changed files were deleted (no mtime), nothing to check against
[ "$NEWEST" -eq 0 ] && exit 0

[ "$NEWEST" -gt "$LAST_EPOCH" ] || exit 0

# 6. Stale: emit decision:block to trigger /context:update auto-run (ADR-0031)
TASK=$(dirname "$BEST_FILE" | sed "s|$GIT_ROOT/||")
TASKNAME=$(basename "$(dirname "$BEST_FILE")")
printf '{"decision":"block","reason":"코드가 변경됐고 %s/context.md 가 stale입니다. /context:update %s 를 실행해 진행상황을 기록하세요."}\n' "$TASK" "$TASKNAME"
exit 0
```

> **스키마 참고**: Stop hook staleness 판정 시 `{"decision":"block","reason":"..."}` 형식으로 emit한다 (ADR-0031).
> `stop_hook_active: true` 재진입 시에는 무조건 `exit 0`으로 무한루프를 차단한다.

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

동작 (ADR-0031):
  - 코드 파일 변경 후 턴이 종료될 때 관련 context.md가 stale이면
    decision:block+reason 으로 Claude가 /context:update를 자동 실행합니다.
  - IDE/툴 아티팩트(.idea 등) 및 무관 작업(매칭 context 없음)은 침묵합니다.
  - /context:update 실행 후 다음 Stop에서는 경고가 발생하지 않습니다.

제거 방법:
  1. .claude/settings.json 에서 context-staleness-check.sh 관련 Stop hook 항목 제거
  2. .claude/hooks/context-staleness-check.sh 삭제
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
