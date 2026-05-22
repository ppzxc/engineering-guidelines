# engineering-guidelines

> [한국어](README.ko.md)

A collection of engineering guidelines for software development, as a Claude Code marketplace.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [api](./plugins/api) | v0.2.1 | RESTful API design guidelines — URL structure, HTTP methods, status codes, JSON format, error responses, versioning, headers, non-CRUD action endpoints |
| [docs](./plugins/docs) | v0.0.4 | Documentation decision records — ADR (Nygard format) and MADR (MADR 4.0) for architecture decisions |
| [git](./plugins/git) | v0.0.11 | Git workflow skills — safe commit, Korean PR creation, PR review with agy cross-check, squash merge, issue creation, full PR lifecycle orchestration, and worktree cleanup |
| [llm](./plugins/llm) | v0.1.0 | LLM delegation skills — agy(Antigravity CLI) context map generation and execution plan cross-check |
| [workflow](./plugins/workflow) | v0.2.0 | Workflow skills — karpathy-guideline (11 Karpathy coding principles, verbatim) |
| [dev](./plugins/dev) | v0.0.1 | Development methodology skills — Tidy First, TDD, and language-agnostic development practices |

## Marketplace Registration

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
