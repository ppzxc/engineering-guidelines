# Peer Cross-check CLI — 폴백 체인

`llm:auto` Step 2 (Peer-review Coordinator)에서 참조한다.  
`plugins/git/skills/review/references/peer-review-cli.md`의 인프라 패턴을 cross-check(plan/spec/idea) 용도로 fork.

공통 인프라(host matrix, pre-flight, 호출 골격, sentinel): → [`peer-fallback-core.md`](../../../../_shared/references/peer-fallback-core.md)

Self-host = {Claude Code, agy} 2종. Gemini CLI / Codex는 SKILL 실행 환경 미검증 → host matrix에서 자기 호스트 행 없음.

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

→ 호출 골격(mktemp+trap+timeout, sentinel 처리): [`peer-fallback-core.md`](../../../../_shared/references/peer-fallback-core.md#cli-호출-골격)

입력은 반드시 stdin pipe 또는 임시파일로 전달. CLI 인자 직접 보간 금지 (shell injection / ARG_MAX 초과 방지).

### AGY (MCP 우선, CLI fallback)

MCP 가용 시:
```
mcp__agy__agy_cross_check(plan=<cross-check 프롬프트 + 입력 전문>)
```

CLI fallback: peer-fallback-core.md AGY 골격에 Cross-check Prompt + `$CONTENT` 주입.

### Gemini (SubAgent 우선, CLI fallback)

SubAgent (Claude Code 호스트에서만):
```
Agent(subagent_type: "gemini:gemini-rescue", prompt: <프롬프트 전문>)
```

CLI fallback: peer-fallback-core.md Gemini 골격에 Cross-check Prompt + `$CONTENT` 주입.

### Codex (SubAgent 우선, CLI fallback)

SubAgent (Claude Code 호스트에서만):
```
Agent(subagent_type: "codex:codex-rescue", prompt: <프롬프트 전문>)
```

CLI fallback: peer-fallback-core.md Codex 골격에 Cross-check Prompt + `$CONTENT` 주입.

### Claude CLI (비-Claude 호스트용)

peer-fallback-core.md Claude CLI 골격에 Cross-check Prompt + `$CONTENT` 주입.

---

## Provenance 형식

```
cross-checked by <self-agent> + <peer: agy|gemini|codex|claude|claude-self-generate>
```
