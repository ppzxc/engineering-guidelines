#!/usr/bin/env bash
# Context Map용 PROJECT_DATA 수집 스크립트. agy SKILL.md §Step 1-1에서 호출.
# 출력은 stdout으로. 호출자가 PROJECT_DATA 변수로 캡처해 agy_context_map 인자로 전달.

set -u

echo "=== [Project Tree (depth 3)] ==="
tree -L 3 --dirsfirst -I 'node_modules|.git|target|build|dist|vendor|.idea|__pycache__' 2>/dev/null \
  || find . -maxdepth 3 -not \( -path './.git' -prune -o -path './node_modules' -prune \
       -o -path './target' -prune -o -path './build' -prune \
       -o -path './dist' -prune -o -path './vendor' -prune \) \
       \( -type f -o -type d \) | sort | head -100

echo ""
echo "=== [Build Configuration] ==="
for f in pom.xml build.gradle build.gradle.kts go.mod go.sum Cargo.toml \
          package.json composer.json requirements.txt pyproject.toml; do
  if [ -f "$f" ]; then
    echo "--- $f ---"
    head -80 "$f"
    echo ""
  fi
done

echo ""
echo "=== [Core Entity/Model Signatures] ==="
find . -not \( -path './.git' -prune -o -path './target' -prune -o -path './build' -prune \) \
  -type f \( -name '*.java' -o -name '*.kt' \) \
  \( -path '*/domain/*' -o -path '*/entity/*' -o -path '*/model/*' \) \
  2>/dev/null | head -20 | while read -r src; do
  echo "--- $src ---"
  grep -n '^\(public \)\?\(class\|interface\|record\|enum\|data class\) ' "$src" | head -5
  grep -n '^\s*private \|^\s*val \|^\s*var ' "$src" | head -10
  echo ""
done
find . -not \( -path './.git' -prune -o -path './vendor' -prune -o -path './build' -prune \) \
  -type f -name '*.go' 2>/dev/null | head -20 | while read -r src; do
  if grep -q '^type .*struct' "$src"; then
    echo "--- $src ---"
    grep -n '^type \|^\s\+[A-Z]' "$src" | head -15
    echo ""
  fi
done

echo ""
echo "=== [Recent Git Changes (last 2 weeks)] ==="
git log --since='2 weeks ago' --grep='^\(feat\|fix\|refactor\|perf\|chore\)' \
  --pretty=format:'%h - %s' --no-merges 2>/dev/null | head -n 20
