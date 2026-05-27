# Context Plugin

The **Context** plugin provides a self-contained Dev Docs system for resumable, context-preserving development across sessions.
A single folder `docs/context/{TASK_NAME}/` holds all 4 files needed to re-anchor exactly where you left off — even after session breaks.

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `plan` | `/context:plan` | Start a new task from a raw idea — creates the 4-file Dev Docs folder via brainstorming → grill → writing-plans pipeline |
| `update` | `/context:update` | Persist current session state before context compaction |
| `resume` | `/context:resume` | Re-anchor on a task after a session break by reading the 4-file folder |

## Output Structure

Each task produces a self-contained folder:

```
docs/context/{TASK_NAME}/
  spec.md      — brainstorming design output (preserved)
  plan.md      — goal, architecture, file structure (tasks trimmed)
  tasks.md     — extracted checkbox checklist
  context.md   — dynamic resume anchor (Current Status / Decision Log / Next Steps / Blockers)
```

The `context.md` file carries a `<!-- last_updated: ISO-8601 -->` marker used by `update` and `resume` to auto-detect the most recent task.

## Portability Principle

This plugin inherits the host project's conventions at runtime.
ADR numbers and rule file paths are **not** hardcoded inside skill files — they stay in the host project's `docs/decisions/` and `.claude/rules/`.

## Installation

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

## Usage

```bash
/context:plan  my raw idea here
/context:update
/context:resume
```
