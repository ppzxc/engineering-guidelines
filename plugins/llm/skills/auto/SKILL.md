---
name: auto
description: Use when performing automated cross-platform peer cross-check for plans, specs, and ideas. Delegated to the peer orchestrator. — /llm:auto, "교차검증", "cross-check", "peer check"
user-invocable: true
disable-model-invocation: true
---

# llm:auto

This skill is deprecated for local execution and delegates all execution steps to the centralized peer orchestrator.

## Execution

The skill MUST delegate all local warm-up, subagent invocation, polling, fallback sentinel handling, and findings merging logic directly to the [llm:peer-orchestrator](file:///home/ppzxc/projects/engineering-guidelines/plugins/llm/skills/peer-orchestrator/SKILL.md) skill.

To run, invoke:
```bash
/llm:peer-orchestrator
```
