---
description: Use when the user wants to review and automatically fix a GitHub PR — /git:review, "PR 리뷰", "코드 리뷰", or any request to review, fix, and comment on a pull request
user-invocable: true
---

# review — PR Code Review & Auto-Fix

Analyze PR diff → detect languages → load language-specific reviewer skills → display review results → apply fixes → submit review comment via `gh pr review` after user confirmation (or automatically if --fix is provided).

## Execution Steps

### 1. Find PR Number

If a PR number is provided as an argument, use it.
Otherwise detect from current branch:

```bash
git branch --show-current
gh pr view <FEATURE_BRANCH> --json number,title,state
```

If no PR is found, ask the user for the PR number directly.

### 2. Fetch PR Info

```bash
gh pr view <PR_NUMBER> --json number,title,state,headRefName,baseRefName,additions,deletions,files,commits,url
gh pr checks <PR_NUMBER>
```

### 3. Detect Languages

Use the `files` field already retrieved in Step 2 (no additional API call needed).

Inspect the changed file extensions and map to languages:

| Extension | Language |
|-----------|----------|
| `.go` | go |
| `.java` | java |
| `.ts`, `.tsx` | typescript |
| `.js`, `.jsx` | javascript |
| `.py` | python |
| `.rs` | rust |

Collect the unique set of detected languages.

### 4. Load Reviewer Skills

From the list of skills available in the system (shown in session context), find skills whose name contains `reviewer`.

For each detected language, attempt to match a reviewer skill:
- `go` → look for a skill containing `golang` or `go` and `reviewer` (e.g., `golang:reviewer`)
- `java` → look for a skill containing `java` and `reviewer` (e.g., `java-reviewer:java-reviewer`)
- Other languages → look for skill containing the language name and `reviewer`

For each matched reviewer skill, invoke it using the `Skill` tool to load its review criteria into context.

If no reviewer skill matches a detected language, fall back to the general review criteria for that language's files.

### 5. Code Review & Generate Fixes

```bash
gh pr diff <PR_NUMBER>
```

Analyze the diff using a two-tier approach (Language-specific reviewer skills or General criteria).
Instead of just listing the issues, **generate the exact code modifications required to fix all identified issues.**

### 6. Apply Fixes & Push (Auto-Fix)

If the `--fix` argument is provided (or if running in auto-fix mode):
1. **Apply Changes:** Directly modify the source files with the generated fixes.
2. **Commit:**
```bash
git add .
git commit -m "fix: address review comments"
```
3. **Push:**
```bash
git push origin <HEAD_REF_NAME>
```

If no issues were found, skip this step.

### 7. Submit Review Comment

Once fixes are pushed (or if no fixes were needed), submit a review comment on the PR.

If fixes were applied:
```bash
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed. <N> issue(s) found and fixed."
```

If no issues were found:
```bash
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed. No issues found."
```

*Note: Comment is used instead of approve, as GitHub does not allow PR authors to approve their own PRs.*

## Error Handling

| Situation | Action |
|-----------|--------|
| PR not found | Abort, ask user for PR number |
| PR already merged/closed | Abort, display current state |
| CI failing | Include CI failure details in review |
| Empty diff | Display "No changes found" and abort |
| No reviewer skill found | Use general review criteria, note it in results |

## Usage

```
/git:review
/git:review 42
PR 리뷰해줘
코드 리뷰
```
