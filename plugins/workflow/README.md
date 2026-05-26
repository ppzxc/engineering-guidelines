# Workflow Plugin

The **Workflow** plugin consolidates high-discipline software engineering and development workflow orchestration skills imported from the `gatekeeper` project.

## Included Skills

### 1. `init` (`/workflow:init`)
* **Description**: Orchestrates programming task initialization. Automatically aligns critical guidelines (Karpathy, Tidy First, TDD) and provisions isolated Git Worktrees for code safety.
* **Keywords**: "새 기능 구현", "버그 수정", "새로운 작업 시작"

### 2. `idea` (`/workflow:idea`)
* **Description**: Helps brain-storming and specs out raw, unformed ideas, preparing them for the feature handoff stage.
* **Keywords**: "아이디어", "막연한 생각", "이거 어떻게 만들지"

### 3. `feature` (`/workflow:feature`)
* **Description**: Handles new feature goals and clarifies objectives using strict interactive interviews.
* **Keywords**: "새 피쳐", "신규 기능 개발 시작", "새로운 기능 만들어"

### 4. `planning` (`/workflow:planning`)
* **Description**: Drafts and validates step-by-step implementation plans after goals are explicitly solidified.
* **Keywords**: "플랜 작성", "계획 수립", "플랜 짜자"

### 5. `develop` (`/workflow:develop`)
* **Description**: Runs red-green-refactor TDD cycles inside isolated environments according to approved plans.
* **Keywords**: "개발 시작", "구현 시작"

---

## Installation

Auto-configured per `.claude-plugin/marketplace.json`.

```bash
# Example usage
/workflow:init
/workflow:idea
/workflow:feature
/workflow:planning
/workflow:develop
```
