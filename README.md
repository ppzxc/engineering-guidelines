# engineering-guidelines

> [한국어](README.ko.md)

A collection of engineering guidelines for software development, as a Claude Code marketplace.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [api](./plugins/api) | v0.0.5 | RESTful API design guidelines — URL structure, HTTP methods, status codes, JSON format, error responses, versioning, headers, non-CRUD action endpoints |
| [docs](./plugins/docs) | v0.0.2 | Documentation decision records — ADR (Nygard format) and MADR (MADR 3.x) for architecture decisions |
| [git](./plugins/git) | v0.0.4 | Git workflow skills — safe commit, PR creation, PR review, squash merge, issue creation, full PR lifecycle orchestration, and worktree cleanup |

## Marketplace Registration

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
