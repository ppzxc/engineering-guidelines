# Peer Fallback Core — 공유 인프라

`peer-review-cli.md`와 `peer-cli.md`의 공통 CLI 인프라 SOT. [ADR-0046](../../../docs/adr/0046-shared-peer-fallback-core.md)

---

## Host Fallback Matrix

| Self host | Peer 우선순위 |
|-----------|---------------|
| Claude Code | agy → gemini → codex |
| Gemini CLI | claude → agy → codex |
| Antigravity (agy) | claude → gemini → codex |
| Codex | claude → agy → gemini |

자기 자신은 풀에서 제외 (ADR-0022/0023). 전부 실패 시 self-only fallback, 사용자에게 알림.

---

## Pre-flight 확인

CLI 시도 전 반드시 version 확인:

```bash
timeout 3 agy --version    2>/dev/null || echo "CLI_NOT_FOUND:agy"
timeout 3 gemini --version 2>/dev/null || echo "CLI_NOT_FOUND:gemini"
timeout 3 codex --version  2>/dev/null || echo "CLI_NOT_FOUND:codex"
timeout 3 claude --version 2>/dev/null || echo "CLI_NOT_FOUND:claude"
```

exit ≠ 0이면 해당 sentinel 발동 → 다음 CLI로 skip. 확인된 CLI만 시도.

---

## CLI 호출 헤더

입력은 반드시 stdin pipe 또는 임시파일로 전달. CLI 인자 직접 보간 금지 (shell injection / ARG_MAX 초과 방지).

---

## CLI 호출 골격

각 CLI 공통 패턴. `<PROMPT_CONTENT>`는 호출처 파일의 domain-specific 프롬프트로 대체.

### AGY

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
<PROMPT_CONTENT>
EOF

printf '\n<CONTENT_DELIMITER_START>\n%s\n<CONTENT_DELIMITER_END>\n' "$CONTENT" >> "$TMPFILE"

timeout 330 agy -p "$(cat "$TMPFILE")" --print-timeout 300s
```

### Gemini

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
<PROMPT_CONTENT>
EOF

printf '\n<CONTENT_DELIMITER_START>\n%s\n<CONTENT_DELIMITER_END>\n' "$CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 gemini -p "MODE — see stdin"
```

### Codex

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
<PROMPT_CONTENT>
EOF

printf '\n<CONTENT_DELIMITER_START>\n%s\n<CONTENT_DELIMITER_END>\n' "$CONTENT" >> "$TMPFILE"

cat "$TMPFILE" | timeout 300 codex exec -
```

### Claude CLI (비-Claude 호스트용)

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'EOF'
<PROMPT_CONTENT>
EOF

printf '\n<CONTENT_DELIMITER_START>\n%s\n<CONTENT_DELIMITER_END>\n' "$CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 claude -p "MODE — see stdin"
```

---

## Sentinel 카탈로그

모든 sentinel → 다음 peer로 시도. 동일 인자 재호출 금지.

통합 prefix 형식: `CLI_NOT_FOUND:<cli>` / `CLI_TIMEOUT:<cli>` / `CLI_ERROR:<cli>(exit=N)`

| Sentinel | 의미 | 처리 |
|----------|------|------|
| `CLI_NOT_FOUND:agy` | agy 부재 | 다음 peer |
| `CLI_TIMEOUT:agy` | 300s 초과 | 다음 peer |
| `CLI_ERROR:agy(exit=N)` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:gemini` | gemini 부재 | 다음 peer |
| `CLI_TIMEOUT:gemini` | 300s 초과 | 다음 peer |
| `CLI_ERROR:gemini(exit=N)` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:codex` | codex 부재 | 다음 peer |
| `CLI_TIMEOUT:codex` | 300s 초과 | 다음 peer |
| `CLI_ERROR:codex(exit=N)` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:claude` | claude CLI 부재 | 다음 peer |
| `CLI_TIMEOUT:claude` | 300s 초과 | 다음 peer |
| `CLI_ERROR:claude(exit=N)` | 비정상 종료 | 다음 peer |
| (모두 실패) | — | self-only fallback, user notify |
