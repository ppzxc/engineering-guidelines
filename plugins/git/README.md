# Git Workflow Skills

> [한국어](README.ko.md)

A collection of safe, opinionated git workflow skills for Claude Code.

## Skills

| Skill | Slash Command | Description |
|-------|---------------|-------------|
| commit | `/git:commit` | Safe staging and committing with Conventional Commits |
| pull-request | `/git:pull-request` | Push branch and create a GitHub PR |
| review | `/git:review` | Analyze PR diff and submit a code review |
| merge | `/git:merge` | Squash-merge a PR safely |
| issue | `/git:issue` | Create a GitHub Issue with type-specific templates |
| clean | `/git:clean` | Full PR lifecycle: commit → PR → review → merge → cleanup |

## Safety Philosophy

All skills enforce:

- Mandatory user confirmation before destructive or irreversible operations
- No `git add -A` or `git add .` (prevents accidental sensitive file inclusion)
- No force push unless explicitly requested by the user
- No `--force`, `--admin`, or `--auto` flags on `gh pr merge`
- Automatic exclusion of sensitive files (`.env`, `*.pem`, `*.key`, `credentials.json`, etc.)
- Confirmation steps cannot be bypassed by urgency statements

## Skill Relationships

`clean` is an orchestrator that delegates to the other skills in sequence:

```
clean
  ├─ Step 1: commit       (if uncommitted changes exist)
  ├─ Step 2: pull-request (if no open PR exists, includes issue detection)
  ├─ Step 3: review
  ├─ Step 4: merge        (always requires confirmation)
  └─ Step 5: Cleanup      (always requires confirmation, inline)
```

Steps 4 and 5 always require explicit confirmation regardless of auto mode.

## Project-Specific Customization

Skills automatically adapt to project conventions:

- **commit** — reads `git log` history to match the project's existing commit style
- **pull-request** — detects the repository's default branch via `gh repo view` instead of hardcoding `main`; detects related issues from branch name, commit messages, and session context, then inserts `Closes #N` in the PR body after user confirmation (GitHub auto-closes issue on merge)
- **review** — detects languages in the PR diff, loads matching language-specific reviewer skills, and falls back to general best practices when no reviewer skill is available
- **merge** — detects the default branch dynamically; deletes remote and local branch after squash merge
- **issue** — supports 4 issue types (bug, feature, chore, docs) with type-specific body templates
- **clean** — full PR lifecycle orchestrator; delegates to pull-request (with issue-PR linkage) and merge (with branch deletion)

## Installation

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
