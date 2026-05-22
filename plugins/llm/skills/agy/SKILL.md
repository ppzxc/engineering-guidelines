---
description: Generate context map and cross-check execution plans using Antigravity (agy). Analysis output only — no code execution. — /llm:agy, "agy crosscheck", "교차검증", "context map"
user-invocable: true
---

# agy Crosscheck

Context Map 생성 + 실행 계획 교차검증. 분석 출력 전용 — 코드 실행 없음.

## Sentinel 처리

응답이 아래 prefix로 시작하면 즉시 Conservative mode 전환. **동일 인자 재호출 금지.**

| Sentinel | 의미 | 처리 |
|----------|------|------|
| `AGY_TIMEOUT:` | 300s 초과 | Claude self-generate |
| `AGY_ERROR(exit=...)` | agy 비정상 종료 | Claude self-generate |
| `AGY_NOT_FOUND:` | agy 바이너리 부재 | Claude self-generate + 설치 안내 |

## Step 1. Context Map 생성

**스킵 조건** — 세 조건 모두 충족 시 스킵:

```bash
[ -f .context-map.md ] \
  && [ -z "$(find .context-map.md -mmin +60 2>/dev/null)" ] \
  && grep -q "git:$(git rev-parse HEAD)" .context-map.md \
  && echo "context-map 최신 상태 — 재생성 스킵" \
  || echo "context-map 재생성 필요"
```

**Step 1-1. PROJECT_DATA 수집:**

```bash
{
  echo "=== [Project Tree (depth 3)] ==="
  tree -L 3 --dirsfirst -I 'node_modules|.git|target|build|dist|vendor|.idea|__pycache__' 2>/dev/null \
    || find . -maxdepth 3 -not \( -path './.git' -prune -o -path './node_modules' -prune \
         -o -path './target' -prune -o -path './build' -prune \
         -o -path './dist' -prune -o -path './vendor' -prune \) -type f | head -100

  echo ""
  echo "=== [Build Configuration] ==="
  for f in pom.xml build.gradle build.gradle.kts go.mod go.sum Cargo.toml package.json pyproject.toml requirements.txt; do
    [ -f "$f" ] && { echo "--- $f ---"; head -80 "$f"; echo ""; }
  done

  echo ""
  echo "=== [Recent Git Changes (last 2 weeks)] ==="
  git log --since='2 weeks ago' --pretty=format:'%h - %s' --no-merges 2>/dev/null | head -20
}
```

**Step 1-2. Context Map 생성:**

`mcp__agy__agy_context_map(project_data=<Step 1-1 출력 전체>)`

결과를 `.context-map.md`에 저장. 파일 맨 아래에 `<!-- git:<git rev-parse HEAD 출력> -->` 추가.

```bash
grep -qxF '.context-map.md' .gitignore 2>/dev/null || printf '\n.context-map.md\n' >> .gitignore
```

**sentinel 응답 시 → Conservative mode**: Claude가 `CLAUDE.md`, `AGENTS.md`, 핵심 소스 파일 직접 읽어 컨텍스트 구성.

## Step 2. Cross-check

`.context-map.md`가 존재하면 읽는다.

`mcp__agy__agy_cross_check(plan=<초안 실행 계획 전문>, context_map=<.context-map.md 내용 또는 "">)`

결과를 사용자에게 표시한다.

**sentinel 응답 시 → Claude self-generate:**

```markdown
## Cross-check (Claude self-generated)

| Tag | Item | Severity |
|-----|------|----------|
| [consistency|omission|ordering|risk|feasibility|version-compat] | 설명 | H/M/L |

## Test Scenarios (Claude self-generated)
1. [정상 케이스] 설명 및 검증 방법
2. [경계 케이스] 설명 및 검증 방법
3. [실패 케이스] 설명 및 검증 방법

## Pre-mortem (Claude self-generated)
1. [실패 이유 1] 구체적 시나리오
2. [실패 이유 2] 구체적 시나리오
3. [실패 이유 3] 구체적 시나리오
```
