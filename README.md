# engineering-guidelines

> [한국어](README.ko.md)

A collection of engineering guidelines for software development, as a Claude Code marketplace.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [guideline](./plugins/guideline) | v0.1.2 | Software engineering guidelines and coding principles — including RESTful API guidelines and Andrej Karpathy's 11 coding principles |
| [workflow](./plugins/workflow) | v0.1.1 | Orchestrated developer workflow skills — including init, idea, feature, develop, and planning for rigorous software engineering |
| [docs](./plugins/docs) | v0.0.7 | Documentation decision records — ADR (Nygard format) and MADR (MADR 4.0) for architecture decisions |
| [git](./plugins/git) | v0.0.16 | Git workflow skills — safe commit, Korean PR creation, PR review with host-aware peer cross-check, squash merge, issue creation, full PR lifecycle orchestration, and worktree cleanup |
| [llm](./plugins/llm) | v0.2.0 | LLM delegation skills — agy (Antigravity CLI) context map, claude advanced reasoning, and auto bidirectional crosscheck |
| [dev](./plugins/dev) | v0.0.4 | Development methodology skills — Tidy First, TDD, and language-agnostic development practices |
| [context](./plugins/context) | v0.2.0 | Dev Docs System skills — self-contained 4-file task folders for resumable, context-preserving development |

## Marketplace Registration

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Import to Antigravity CLI (agy)
For installing this plugin in the Antigravity CLI environment, please refer to the [Antigravity CLI Import Guidelines](docs/agy-import-guidelines.md).
