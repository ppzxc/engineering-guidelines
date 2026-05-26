# engineering-guidelines

> [한국어](README.ko.md)

A collection of engineering guidelines for software development, as a Claude Code marketplace.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [api](./plugins/api) | v0.2.4 | RESTful API design guidelines — URL structure, HTTP methods, status codes, JSON format, error responses, versioning, headers, non-CRUD action endpoints |
| [docs](./plugins/docs) | v0.0.7 | Documentation decision records — ADR (Nygard format) and MADR (MADR 4.0) for architecture decisions |
| [git](./plugins/git) | v0.0.16 | Git workflow skills — safe commit, Korean PR creation, PR review with host-aware peer cross-check, squash merge, issue creation, full PR lifecycle orchestration, and worktree cleanup |
| [llm](./plugins/llm) | v0.1.3 | LLM delegation skills — agy (Antigravity CLI) context map, claude advanced reasoning, and auto bidirectional crosscheck |
| [workflow](./plugins/workflow) | v0.2.3 | Workflow skills — karpathy-guideline (11 Karpathy coding principles, verbatim) |
| [dev](./plugins/dev) | v0.0.4 | Development methodology skills — Tidy First, TDD, and language-agnostic development practices |

## Marketplace Registration

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```

### Import to Antigravity CLI (agy)
For installing this plugin in the Antigravity CLI environment, please refer to the [Antigravity CLI Import Guidelines](docs/agy-import-guidelines.md).
