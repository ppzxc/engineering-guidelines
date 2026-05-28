# Peer Cross-check CLI — 폴백 체인

`llm:auto` Step 2 (Peer-review Coordinator)에서 참조한다.  
`plugins/git/skills/review/references/peer-review-cli.md`의 인프라 패턴을 cross-check(plan/spec/idea) 용도로 fork.

---

## Host Fallback Matrix

| Self host | Peer 우선순위 |
|-----------|---------------|
| Claude Code | agy → gemini → codex |
| Antigravity (agy) | claude → gemini → codex |

자기 자신은 풀에서 제외 (ADR-0022/0023/0034). 전부 실패 시 self-only fallback, 사용자에게 알림.

Self-host = {Claude Code, agy} 2종. Gemini CLI / Codex는 SKILL 실행 환경 미검증 → self-host 행 없음.

---

## Pre-flight 순서

CLI 시도 전 반드시 version 확인:

```bash
timeout 3 agy --version    2>/dev/null || echo "AGY_NOT_FOUND:"
timeout 3 gemini --version 2>/dev/null || echo "CLI_NOT_FOUND:gemini"
timeout 3 codex --version  2>/dev/null || echo "CLI_NOT_FOUND:codex"
timeout 3 claude --version 2>/dev/null || echo "CLAUDE_CLI_NOT_FOUND:"
```

exit ≠ 0이면 해당 sentinel 발동 → 다음 CLI로 skip. 확인된 CLI만 시도.

---

## Cross-check Prompt 템플릿

입력 타입별로 `references/prompts.md`의 해당 섹션을 사용.  
(code diff 리뷰 prompt는 `plugins/git/skills/review/references/peer-review-cli.md` 참조 — 본 파일과 별개)

```
You are an adversarial cross-checker. The content below was produced by a different model.
Your mission: identify ALL issues — inconsistencies, omissions, ordering violations, feasibility gaps, factual errors.

Output format (STRICT):

reviewer: <your-id: agy|gemini|codex|claude>
input_type: <plan|spec|idea>

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

Tag: consistency / omission / ordering / feasibility / risk / fact-check / trade-off / doc-sync / version-compat

Severity: H=high(blocking), M=medium(should-fix), L=low(note)

## <Type-specific sections per prompts.md>

## Provenance
- reviewer: <your-id>

If no issues found:
reviewer: <your-id>
input_type: <type>

No issues found.

--- CONTENT START ---
{CONTENT}
--- CONTENT END ---
```

`{CONTENT}`: 분류된 입력 텍스트 전체.

---

## CLI 호출 패턴

입력은 반드시 stdin pipe 또는 임시파일로 전달. CLI 인자 직접 보간 금지 (shell injection / ARG_MAX 초과 방지).

### AGY (MCP 우선, CLI fallback)

MCP 가용 시:
```
mcp__agy__agy_cross_check(plan=<cross-check 프롬프트 + 입력 전문>)
```

CLI fallback:
```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'CROSSEOF'
[cross-check 프롬프트, reviewer: agy]
CROSSEOF

printf '\n--- CONTENT START ---\n%s\n--- CONTENT END ---\n' "$CONTENT" >> "$TMPFILE"

timeout 330 agy -p "$(cat "$TMPFILE")" --print-timeout 300s
```

### Gemini (SubAgent 우선, CLI fallback)

SubAgent (Claude Code 호스트에서만):
```
Agent(subagent_type: "gemini:gemini-rescue", prompt: <프롬프트 전문>)
```

CLI fallback:
```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'CROSSEOF'
[cross-check 프롬프트, reviewer: gemini]
CROSSEOF

printf '\n--- CONTENT START ---\n%s\n--- CONTENT END ---\n' "$CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 gemini -p "CROSS-CHECK MODE — see stdin"
```

### Codex (SubAgent 우선, CLI fallback)

SubAgent (Claude Code 호스트에서만):
```
Agent(subagent_type: "codex:codex-rescue", prompt: <프롬프트 전문>)
```

CLI fallback:
```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'CROSSEOF'
[cross-check 프롬프트, reviewer: codex]
CROSSEOF

printf '\n--- CONTENT START ---\n%s\n--- CONTENT END ---\n' "$CONTENT" >> "$TMPFILE"

cat "$TMPFILE" | timeout 300 codex exec -
```

### Claude CLI (비-Claude 호스트용)

```bash
# Pre-flight
timeout 3 claude --version 2>/dev/null || { echo "CLAUDE_CLI_NOT_FOUND:"; exit 1; }

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'CROSSEOF'
[cross-check 프롬프트, reviewer: claude]
CROSSEOF

printf '\n--- CONTENT START ---\n%s\n--- CONTENT END ---\n' "$CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 claude -p "CROSS-CHECK MODE — see stdin"
```

---

## Sentinel 처리

모든 sentinel → 다음 peer로 시도. 동일 인자 재호출 금지.

| Sentinel prefix | 의미 | 처리 |
|----------------|------|------|
| `AGY_NOT_FOUND:` | agy 부재 | 다음 peer |
| `AGY_TIMEOUT:` | 300s 초과 | 다음 peer |
| `AGY_ERROR(exit=N):` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:gemini` | gemini 부재 | 다음 peer |
| `CLI_TIMEOUT:gemini` | 300s 초과 | 다음 peer |
| `CLI_ERROR:gemini(exit=N)` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:codex` | codex 부재 | 다음 peer |
| `CLI_TIMEOUT:codex` | 300s 초과 | 다음 peer |
| `CLI_ERROR:codex(exit=N)` | 비정상 종료 | 다음 peer |
| `CLAUDE_CLI_NOT_FOUND:` | claude CLI 부재 | 다음 peer |
| `CLAUDE_CLI_TIMEOUT:` | 300s 초과 | 다음 peer |
| `CLAUDE_CLI_ERROR(exit=N):` | 비정상 종료 | 다음 peer |
| (모두 실패) | — | self-only fallback, user notify |

---

## Provenance 형식

```
cross-checked by <self-agent> + <peer: agy|gemini|codex|claude|claude-self-generate>
```
