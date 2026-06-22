---
name: codex
description: Delegate cross-check to Codex CLI. Wrapper skill — pure delegation only, no routing logic. Called by llm:auto. — /llm:codex, "codex crosscheck", "codex 교차검증"
user-invocable: true

---

# llm:codex

Codex CLI에 cross-check를 위임하는 순수 wrapper 스킬. 라우팅 로직 없음. 복잡한 오케스트레이션은 `llm:auto` 담당.

## Sentinel 처리

응답이 아래 prefix로 시작하면 즉시 처리하고 **동일 인자 재호출 금지**.

| Sentinel | 의미 | 처리 |
|----------|------|------|
| `CLI_NOT_FOUND:codex` | codex 바이너리 부재 | 상위(`llm:auto`) 폴백 체인에서 다음 peer 시도. 단독 호출 시 → self-only |
| `CLI_TIMEOUT:codex` | 300s 초과 | 상동 |
| `CLI_ERROR:codex(exit=N)` | 비정상 종료 | 상동 |

## Step 1. 호스트 확인

`mcp__agy__*` MCP 도구 노출 → **Claude Code 호스트** → Step 2A 실행.  
그 외 → **비-Claude 호스트** → Step 2B 실행.

## Step 2A. Claude Code 호스트 — SubAgent dispatch

`codex:codex-rescue` SubAgent 1순위 시도:

```
Agent(
  subagent_type: "codex:codex-rescue",
  prompt: <cross-check 프롬프트 전문 — references/prompts.md 참조>
)
```

SubAgent 결과를 수신하면 `reviewer: codex` 헤더와 함께 표시.

SubAgent 실패(오류·타임아웃) 시 → Step 2B (CLI fallback).

## Step 2B. CLI Fallback

**Pre-flight:**

```bash
timeout 3 codex --version 2>/dev/null || echo "CLI_NOT_FOUND:codex"
```

exit ≠ 0 → `CLI_NOT_FOUND:codex` sentinel 발동. 이하 호출 건너뜀.

**stdin pipe 호출 (tmpfile 사용):**

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'CROSSEOF'
<cross-check 프롬프트 전문 — references/prompts.md 참조>
CROSSEOF

cat "$TMPFILE" | timeout 300 codex exec -
EXIT_CODE=$?
[ $EXIT_CODE -ne 0 ] && echo "CLI_ERROR:codex(exit=$EXIT_CODE)"
```

## 출력 형식

`references/prompts.md`의 출력 스키마에 따라 `reviewer: codex` 헤더로 반환.
