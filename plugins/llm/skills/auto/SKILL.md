---
name: auto
description: Use when performing automated cross-platform peer cross-check for plans, specs, and ideas using 4-way LLM fallback chain (agy, claude, gemini, codex). — /llm:auto, "교차검증", "cross-check", "peer check"
user-invocable: true
---

# llm:auto

입력 분류(plan/spec/idea/diff) → 호스트 감지 → Self+Peer SUBAGENT 병렬 dispatch → severity-gated 병합.

code diff는 `git:review`로 redirect. 라우팅·오케스트레이션 전담 스킬.

## References

- `references/check-categories.md` — 타입별 검증 항목, 출력 섹션 정의
- `references/prompts.md` — 입력 타입별 프롬프트 4종
- `references/peer-cli.md` — 4-way CLI 폴백 체인, sentinel 처리, host matrix

## Execution Steps

### Step 1. 입력 타입 분류

사용자 인자 우선(`/llm:auto plan`, `/llm:auto spec`, `/llm:auto idea`), 없으면 휴리스틱:

| 시그널 | 분류 |
|--------|------|
| `diff --git` / `--- a/` / `+++ b/` 헤더 포함 | **diff** |
| `## Decision Outcome` / `status:` / MADR frontmatter | **spec** |
| `## Considered Options` / "should we" / "what if" | **idea** |
| 기타 (단계·체크리스트·실행 절차) | **plan** (default) |

**diff 감지 시**: 즉시 redirect 메시지 표시 후 종료 (`references/prompts.md` Diff redirect 섹션).

### Step 2. 호스트 감지

`mcp__agy__*` MCP 도구 노출 → **Claude Code** 호스트 → Step 3A.  
그 외 → **agy/비-Claude 호스트** → Step 3B.

### Step 3A. Claude Code 호스트 — Self + Peer SUBAGENT 병렬 dispatch

**Self-Review SUBAGENT와 Peer-Review Coordinator SUBAGENT를 동시에 dispatch한다.**

---

#### 3a-Self. Self-Review SUBAGENT

Agent 툴로 review-capable agent dispatch (description에 "review"/"code"/"audit" 포함, 없으면 general-purpose + model=opus).

Prompt:

```
You are an adversarial cross-checker. Review the content below using the appropriate prompt from references/prompts.md for input_type: {INPUT_TYPE}.

Apply ALL required categories from references/check-categories.md for this input type.

{PROMPT_TEMPLATE from references/prompts.md — {INPUT_TYPE} section}

Replace {CONTENT} with the actual input content.
```

---

#### 3a-Peer. Peer-Review Coordinator SUBAGENT

Agent 툴로 general-purpose dispatch.

Prompt:

```
You are a Peer Review Coordinator. Invoke an external LLM CLI to cross-check content.

Host: Claude Code. Peer pool (in priority order): agy → gemini → codex.
If all fail: return exactly "reviewer: claude-self-generate\ninput_type: {INPUT_TYPE}\n\nNo issues found."

Follow references/peer-cli.md exactly:
1. Pre-flight: timeout 3 <cli> --version for each CLI in pool order
2. For agy: try mcp__agy__agy_cross_check first, then CLI
3. For gemini: try Agent(subagent_type="gemini:gemini-rescue") first, then CLI
4. For codex: try Agent(subagent_type="codex:codex-rescue") first, then CLI
5. For claude CLI: pre-flight + stdin pipe
6. On any sentinel (NOT_FOUND/TIMEOUT/ERROR): skip to next peer
7. Return raw output from first successful peer

Input type: {INPUT_TYPE}
Prompt template: use references/prompts.md {INPUT_TYPE} section.
Replace {CONTENT} with:
--- CONTENT START ---
{INPUT_CONTENT}
--- CONTENT END ---
```

두 SUBAGENT 완료 대기 (동기 실행):
1. `invoke_subagent` 호출 직후, 현재 서브에이전트들의 완료를 대기 중이라는 진행 상황 메시지(예: "Self/Peer 서브에이전트 완료 대기 중...")를 반드시 텍스트로 출력하고 턴을 종료(stop calling tools)한다. (대기 전 텍스트 출력이 누락되면 대기 데드락 현상이 발생한다.)
2. 대기 과정에서 데드락을 방지하고 상태 갱신을 강제하기 위해, 1회 호출 후 `schedule` 툴을 사용하여 30초 뒤에 `Peer review status check` 알림을 설정한다. [ADR-0049]
3. 알림을 받아 깨어나거나 subagent notification을 받으면 `manage_subagents` `list`를 호출하여 두 subagent의 status가 모두 Done인지 확인한다. 둘 다 Done이 아니라면 대기 메시지를 다시 출력하고 2번 단계(schedule 예약 및 턴 종료)를 반복하여 대기한다. [ADR-0049]

---

#### 3a-Merge. Findings 병합 (main thread)

Self (3a-Self)와 Peer (3a-Peer) findings 수신 후 severity-gated hybrid 병합:

| Severity | 병합 규칙 |
|----------|----------|
| `H` (high/blocking) | **Union** — 어느 한쪽이라도 발견 시 포함 |
| `M`, `L` | **Intersection** — 양쪽 모두 발견 시에만 포함 |

중복 제거: 동일 Tag + Item → 단일 항목으로 통합 (양 reviewer 언급).

Peer unavailable (모든 sentinel): Self findings만 사용. User notify.  
Self SUBAGENT 실패: Peer findings만 사용. User notify.

### Step 3B. agy/비-Claude 호스트 — sequential (self inline + peer CLI)

Self review: 호스트가 직접 `references/prompts.md` 해당 타입 프롬프트로 분석.

Peer review: `references/peer-cli.md` 호스트별 peer pool 따라 CLI fallback 체인:
- agy host: claude → gemini → codex

Peer review 실패 시 (모든 sentinel): self-only. User notify.

### Step 4. 출력

병합 결과를 `references/check-categories.md` 출력 스키마 형식으로 표시:

```
## Cross-check Result
input_type: {plan|spec|idea}
self-reviewer: <agent>
peer-reviewer: <agy|gemini|codex|claude-self-generate>

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

[타입별 섹션 — check-categories.md 참조]

## Provenance
- self: <agent>
- peer: <peer-id>
- peer-chain: <시도 결과 예: agy→sentinel, gemini→success>
- fallback-reason: <if any>
```

## Sentinel 처리

`references/peer-cli.md` Sentinel 처리 섹션 참조. 모든 sentinel → 다음 peer. 전부 실패 → self-only.

## 자기-호출 금지

자기 자신 호스트와 동일한 peer 호출 금지 (ADR-0022/0023/0034). `references/peer-cli.md` Host Fallback Matrix 참조.
