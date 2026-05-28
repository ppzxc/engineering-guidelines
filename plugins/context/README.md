# Context Plugin

The **Context** plugin provides a self-contained Dev Docs system for resumable, context-preserving development across sessions.
A single folder `docs/context/{TASK_NAME}/` holds all 4 files needed to re-anchor exactly where you left off — even after session breaks.

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `plan` | `/context:plan` | Start a new task from a raw idea — creates the 4-file Dev Docs folder via brainstorming → grill → writing-plans pipeline |
| `update` | `/context:update` | Persist current session state before context compaction |
| `resume` | `/context:resume` | Re-anchor on a task after a session break by reading the 4-file folder |
| `guard` | `/context:guard` | Install an opt-in Stop hook that reminds you to run `/context:update` when code is stale |

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

## Stop Hook (opt-in)

`context:guard` installs a Claude Code Stop hook into the host project's `.claude/settings.json`.
When a coding session ends and code has changed since the last `context:update`, a reminder message appears:

```
⚠️  docs/context/<task>/context.md 가 stale입니다. /context:update 로 진행상황을 기록하세요.
```

**Behavior**: non-blocking (reminder only, `decision:block` is never used).  
**Install**: run `/context:guard` once per project (outside plan mode).  
**Remove**: delete the Stop hook entry from `.claude/settings.json` and remove `.claude/hooks/context-staleness-check.sh`.

The plugin itself stays hook-free (see ADR-0028). The Stop hook lives in the host project's settings, not inside the plugin.

## Portability Principle

This plugin inherits the host project's conventions at runtime.
ADR numbers and rule file paths are **not** hardcoded inside skill files — they stay in the host project's `docs/decisions/` and `.claude/rules/`.

## Installation

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

## Discipline (default ON)

`/context:plan` injects karpathy/tdd/tidy discipline by default. Opt out with single-token flags:

- `--no-karpathy=<reason>` — disable simplicity/surgical design lens
- `--no-tdd-tidy=<reason>` — disable [S]/[B] tagging + RGR sub-steps in tasks.md

Opt-out reason is mandatory and recorded as a blockquote at the top of `spec.md`. See [ADR-0032].

## Usage

```bash
/context:plan  my raw idea here
/context:plan --no-tdd-tidy=throwaway-prototype "quick spike"
/context:update
/context:resume
/context:guard   # optional: install staleness reminder hook
```
