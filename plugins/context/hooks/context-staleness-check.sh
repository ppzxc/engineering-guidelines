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
          | awk '{print $NF}' | grep -v '^docs/' | head -1)
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
           | awk '{print $NF}' | grep -v '^docs/'); do
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
printf '{"decision":"allow","systemMessage":"⚠️  %s/context.md 가 stale입니다. /context:update 로 진행상황을 기록하세요."}\n' "$TASK"
exit 0
