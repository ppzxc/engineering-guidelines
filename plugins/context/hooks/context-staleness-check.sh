#!/usr/bin/env sh
# Claude Code Stop hook — context:update auto-run on staleness.
# Emits decision:block+reason when relevant context is stale; exit 0 otherwise.
# ADR-0028 superseded by ADR-0031.
# Known limitation: paths containing spaces may parse incorrectly (kebab-slug paths safe).

# 1. LOOP GUARD — stdin must be read first to prevent re-block on auto-run turn
INPUT=$(cat 2>/dev/null)
printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

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
          "$prefix"*) MATCHED=1; break 2 ;;
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
  LAST_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$BEST_TS" +%s 2>/dev/null)
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

# If all changed files were deleted (no mtime), treat as stale
[ "$NEWEST" -eq 0 ] && NEWEST=$(date +%s 2>/dev/null || printf '%s' '9999999999')

[ "$NEWEST" -gt "$LAST_EPOCH" ] || exit 0

# 6. Stale: emit decision:block to trigger /context:update auto-run (ADR-0031)
TASK=$(dirname "$BEST_FILE" | sed "s|$GIT_ROOT/||")
TASKNAME=$(basename "$(dirname "$BEST_FILE")")
printf '{"decision":"block","reason":"코드가 변경됐고 %s/context.md 가 stale입니다. /context:update %s 를 실행해 진행상황을 기록하세요."}\n' "$TASK" "$TASKNAME"
exit 0
