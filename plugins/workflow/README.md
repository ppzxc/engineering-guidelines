# Workflow Skills

> [한국어](README.ko.md)

Planner-Executor separation + multi-LLM cross-check workflow.
Claude (plan/execute) + Gemini (context/review).

## Skills

| Skill | Slash Command | Description |
|-------|---------------|-------------|
| gemini-crosscheck | `/workflow:gemini-crosscheck` | Multi-LLM cross-check with Gemini before coding — context compression, brainstorm, plan finalization, and execution |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Gemini Crosscheck Pipeline                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐   .context-map.md   ┌───────────────────────┐ │
│  │ Gemini Flash │──────────────────>│ Claude (Brainstorm)   │ │
│  │ 1M context   │   ~4000 tokens     │ 2-3 approaches        │ │
│  │ $0.50/M in   │                    │ + Why NOT              │ │
│  └─────────────┘                     └───────────┬───────────┘ │
│        ▲                                         │              │
│        │ source code                    draft plan│              │
│        │ + git log                               ▼              │
│  ┌─────┴───────┐                     ┌───────────────────────┐ │
│  │  Project    │                     │ Gemini Pro            │ │
│  │  Codebase   │                     │ (Flash fallback avail)│ │
│  │             │                     │ Cross-check           │ │
│  └─────────────┘                     │ + Pre-mortem          │ │
│                                      │ + Test scenarios      │ │
│                                      └───────────┬───────────┘ │
│                                                   │              │
│                                         feedback  │              │
│                                                   ▼              │
│                                      ┌───────────────────────┐ │
│                                      │ Claude (Plan)         │ │
│                                      │ Tidy/Behavioral split │ │
│                                      │ Assumption + Fallback │ │
│                                      └───────────┬───────────┘ │
│                                                   │              │
│                                      user approval│              │
│                                                   ▼              │
│                                      ┌───────────────────────┐ │
│                                      │ Claude (Execute)      │ │
│                                      │ Tidy First + TDD      │ │
│                                      │ Pre-read + Impact Scan│ │
│                                      └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
Step 1                Step 2              Step 3 (Pro/Flash)      Step 4           Step 5
Gemini Flash          Claude              Gemini Pro/Flash      Claude           Claude
────────────          ──────              ─────────────────      ──────           ──────

Source code ──>  .context-map.md ──> Draft plan ──> Feedback ──> Final plan ──> Code
+ git log           (4000 tok)       (2-3 options)   + Tests     + Tidy/Behav   + Tests
                                     + Why NOT        + Pre-mort  + Assumption   + ADR
                                                      + Tags      + 3-tier test
                                                         │
                                                         ▼
                                                   [User Gate]
                                                   approve / reject
                                                      │        │
                                                      ▼        ▼
                                                   Step 5   Step 2
                                                  (execute)  (retry)
```

## Model Routing

| Step | Model | Role | Input | Output | Fallback |
|------|-------|------|-------|--------|----------|
| 1. Compress | `gemini-3-flash-preview` | Context compressor | Full codebase + git log | `.context-map.md` (~4000 tok) | Claude reads source directly (skip Steps 1 & 3) |
| 2. Brainstorm | Claude (Opus/Sonnet) | Planner | Context map + task | Draft plan with options | — |
| 3. Cross-check | `gemini-3.1-pro-preview` | Reviewer/Critic | Context map + draft plan | Feedback + tests + pre-mortem | Flash → Claude |
| 4. Plan | Claude (Opus/Sonnet) | Decision maker | Feedback + draft plan | Final plan with Tidy/Behavioral split (user approval) | — |
| 5. Execute | Claude (Sonnet) | Executor | Approved plan + source | Code + tests + commits | — |

## Cost Estimation (per cycle)

```
Gemini Flash (compress)             : ~100K input  = $0.05
Gemini Pro  (crosscheck)            : ~6K input    = $0.012
Gemini Flash (crosscheck fallback)  : ~6K input    = $0.003  ← if Pro fails
Claude reads context map            : ~4K input    = $0.06
                                               Total: ~$0.12

vs. Opus reading full source directly : ~100K input = $1.50
                                  Savings: ~93%
```

## Fallback Strategy

```
Full workflow (Steps 1-5) running normally
         │
         │ Step 3 Cross-check
         ▼
gemini-3.1-pro-preview ──> success ──> continue
         │
      fails (rate limit / timeout)
         ▼
gemini-3-flash-preview ──> success ──> "⚠️ Gemini Pro → Flash fallback" notice, continue
         │
      fails
         ▼
Claude self-generate ──> "⚠️ Gemini unavailable" notice + test scenarios + pre-mortem self-generated, continue

When Gemini is entirely unavailable:
     └── skip Steps 1, 3
     └── Claude reads CLAUDE.md + source directly
     └── strengthened pre-read in execute
```

## Installation

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### MCP Server Requirement

Gemini 호출은 MCP를 통해 이루어진다. 아래 명령어로 MCP 서버를 등록해야 한다:

```bash
claude mcp add gemini-cli -s user -- uvx --from git+https://github.com/DiversioTeam/gemini-cli-mcp.git gemini-mcp
```
