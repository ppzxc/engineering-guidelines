# engineering-guidelines

> [한국어](README.ko.md)

A collection of engineering guidelines for software development, as a Claude Code marketplace.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [guideline](./plugins/guideline) | v0.3.0 | Software engineering guidelines and coding principles — including RESTful API guidelines, Andrej Karpathy's 11 coding principles, and the Honest Judgment anti-sycophancy review rule |
| [workflow](./plugins/workflow) | v0.1.1 | Orchestrated developer workflow skills — including init, idea, feature, develop, and planning for rigorous software engineering |
| [docs](./plugins/docs) | v0.0.8 | Documentation decision records — ADR (Nygard format) and MADR (MADR 4.0) for architecture decisions |
| [git](./plugins/git) | v0.7.0 | Git workflow skills — safe commit, Korean PR creation, PR review with host-aware peer cross-check and selectable review tier (fast/balanced/deep), union-merge with agreement-tagged auto-fix, squash merge, issue creation, issue-PR linkage via Closes #N, full PR lifecycle orchestration, and worktree cleanup |
| [llm](./plugins/llm) | v0.5.0 | LLM delegation skills — 4-way peer cross-check (agy, claude, gemini, codex) with host-aware fallback chain |
| [dev](./plugins/dev) | v0.1.0 | Development methodology skills — Tidy First, TDD, and language-agnostic development practices |
| [context](./plugins/context) | v0.9.0 | Dev Docs System skills — self-contained 4-file task folders for resumable, context-preserving development |

## Marketplace Registration

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Import to Antigravity CLI (agy)
For installing this plugin in the Antigravity CLI environment, please refer to the [Antigravity CLI Import Guidelines](docs/agy-import-guidelines.md).
