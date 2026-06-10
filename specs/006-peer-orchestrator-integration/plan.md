# Implementation Plan: Peer Orchestrator Integration

**Branch**: `006-peer-orchestrator-integration` | **Date**: 2026-06-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-peer-orchestrator-integration/spec.md`

## Summary

This feature implements a centralized multi-LLM orchestration system (`llm:peer-orchestrator`) that handles parallel execution of Self-Review and Peer-Review subagents. It prevents sandbox locks via proactive warm-ups, handles execution failures gracefully using sentinel fallback chains (excluding the running host CLI), and merges review findings using a hybrid severity-gated Union/Intersection engine. Finally, the legacy `llm:auto` skill is refactored to delegate all logic to the new orchestrator.

## Technical Context

**Language/Version**: Bash / Shell Script (under agent runtime environment)

**Primary Dependencies**: `gh` CLI, `git`, `rtk` (Rust Token Killer proxy)

**Storage**: Temporary JSON/Markdown findings files under temp/artifacts directories

**Testing**: Markdown-based evaluation tests defined in `docs/evaluation/test-cases.md`

**Target Platform**: Linux Server (CLI execution environment)

**Project Type**: CLI tool plugin / Agent Skill

**Performance Goals**: Complete parallel review orchestration under 3 minutes (excluding network latency)

**Constraints**: Polling loop check interval of 30 seconds, maximum polling loop timeout of 5 minutes (300 seconds), sandbox warm-up check time < 3 seconds per CLI.

**Scale/Scope**: Support 2 concurrent subagents, fallback priority sequence for up to 3 peer CLIs, exclude 1 LOCAL host LLM CLI dynamically.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Gate 1**: Plugin-First & Modular Skill Design (플러그인 중심 및 모듈식 스킬 설계)
  - *Status*: **PASS**
  - *Details*: The skill is defined cleanly under `plugins/llm/skills/peer-orchestrator/SKILL.md` with no hardcoded implementation details.
- **Gate 2**: Verification-First & Test-First (TDD for Skills)
  - *Status*: **PASS**
  - *Details*: Test cases will be added to `docs/evaluation/test-cases.md` before finalizing guidelines or script modifications.
- **Gate 3**: Git Workflow & Version Synchronization
  - *Status*: **PASS**
  - *Details*: Git branch naming is set as `006-peer-orchestrator-integration`. Commits are structured cleanly, and no project version bumps are required for this slice.
- **Gate 4**: Glossary & Domain Terms Compliance
  - *Status*: **PASS**
  - *Details*: Conforms to definitions of `Plugin`, `Skill`, `Sentinel` (CLI_NOT_FOUND, CLI_TIMEOUT, CLI_ERROR), and `Peer`.

## Project Structure

### Documentation (this feature)

```text
specs/006-peer-orchestrator-integration/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── peer-orchestrator.md
└── tasks.md             # Phase 2 output (generated later)
```

### Source Code (repository root)

```text
plugins/
└── llm/
    ├── plugin.json
    └── skills/
        ├── auto/
        │   └── SKILL.md  # Refactored to delegate to peer-orchestrator
        └── peer-orchestrator/
            └── SKILL.md  # New centralized orchestrator skill
```

**Structure Decision**: Conforms to modular plugin directory structure under `plugins/llm/skills/`.

## Complexity Tracking

*No violations identified. System uses standard sequential scripts, built-in scheduling, and direct CLI command logic.*
