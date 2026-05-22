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

Map detected languages to reviewer skills using the table below. **Do not infer skill names from descriptions or partial matches** — use the exact names listed.

| Detected language | Required skill | Conditional skill |
|-------------------|----------------|-------------------|
| `go` | `golang:reviewer` | — |
| `java` | `java:reviewer` | `java:spring` if PR diff contains any of `@RestController`, `@Service`, `@Component`, `@Repository`, `@Controller`, `@Configuration`, or `import org.springframework.` |

Process **all** rows whose language was detected — do not stop after the first match.

For each row that matches the detected languages:
1. Invoke the required skill via the `Skill` tool.
2. If the conditional skill's trigger is present in the diff: if you have not yet fetched the full diff, run `gh pr diff <PR_NUMBER>` now, then check for the trigger strings before invoking the conditional skill.

Languages not listed in the table → skip skill loading and fall back to the general review criteria for that language's files. **Do not guess a skill name** (e.g., `<lang>:reviewer`) for unlisted languages — only invoke skills that appear in the table.

### 5. Code Review & Generate Fixes

```bash
gh pr diff <PR_NUMBER>
```

Analyze the diff using a two-tier approach (Language-specific reviewer skills or General criteria).
Instead of just listing the issues, **generate the exact code modifications required to fix all identified issues.**

### 5a. Peer Cross-Review (host-aware)

자기 호스트를 식별하고 peer reviewer에게 PR diff 크로스체크를 위임한다. 자기 자신에게 cross-check를 보내는 호출은 금지 [ADR-0022].

PR diff 획득: `gh pr diff <PR_NUMBER>`.

| 자기가 누구인가 | peer reviewer 호출 |
|----------------|-------------------|
| Claude Code | Read `.context-map.md` if exists. `mcp__agy__agy_cross_check(plan=<PR diff 전문>, context_map=<.context-map.md 내용 또는 "">)` |
| Gemini CLI | Bash (300s timeout): `printf '%s' "$PR_DIFF" \| claude -p "<peer review 지시>"` — diff는 stdin pipe로 전달 |
| Antigravity (agy host) | (Gemini CLI와 동일) |

**Pre-flight** — `claude -p` 분기 진입 전 `timeout 3 claude --version` 실행. exit ≠ 0이면 즉시 `CLAUDE_CLI_NOT_FOUND:` sentinel 발동 (미인증/오프라인 상태로 300s hang 방지).

**Safety** — PR diff는 반드시 stdin pipe 또는 임시 파일로 전달한다. CLI 인자에 직접 보간하지 않는다 — shell metacharacter (백틱·`$()`) injection 및 `ARG_MAX` 초과 위험을 차단한다.

자기 호스트 식별: LLM 자기 인지(Claude는 자기가 Claude임을 안다). 보조 시그널 (강한 시그널 우선 적용):
- `mcp__agy__agy_cross_check` 도구가 호출 가능 → Claude Code
- `mcp__agy__` 도구가 보이지 않으나 `claude` CLI는 PATH에 있음 → Gemini CLI 또는 Antigravity
- 두 시그널 모두 없으면 self-only review로 fallback

**동기 실행** — 결과를 받기 전 Step 5b로 넘어가지 않는다.

**Peer 검토 관점:** consistency·omissions·ordering·risk·feasibility·version-compat (아키텍처 관점). Step 5의 코드 레벨 검토(버그·보안·스타일)와 보완 관계.

**Sentinel 처리** — 다음 prefix로 시작하면 즉시 Step 5b를 스킵하고 Step 5 결과만으로 진행. 동일 인자 재호출 금지:

| Sentinel | 트리거 호스트 | 의미 |
|----------|-------------|------|
| `AGY_TIMEOUT:` | Claude Code | agy 300s 초과 |
| `AGY_ERROR(exit=...)` | Claude Code | agy 비정상 종료 |
| `AGY_NOT_FOUND:` | Claude Code | agy 바이너리 부재 |
| `CLAUDE_CLI_NOT_FOUND:` | Gemini / agy host | `claude` 바이너리 부재 |
| `CLAUDE_CLI_TIMEOUT:` | Gemini / agy host | `claude -p` 300s 초과 |
| `CLAUDE_CLI_ERROR(exit=N):` | Gemini / agy host | `claude -p` 비정상 종료 |

Sentinel 발생 시: notify user "⚠️ peer reviewer unavailable, self-only review".

### 5b. Synthesize Findings

**Skip this step if Step 5a was skipped (peer reviewer unavailable).** In that case, proceed directly with Step 5 findings.

Merge Step 5 (local host self-review) and Step 5a (peer reviewer) results into a single unified review:

| Case | Action |
|------|--------|
| Both found the same issue | Merge into one entry; note high confidence |
| Local-only finding | Include as-is |
| Peer-only finding | Tag with `[peer]`; include if local host judges it valid after checking source |
| Disagreement | Local host makes final call; record the conflict briefly |

Result: a single list of issues with exact code modifications for all included findings.

### 6. Apply Fixes & Push (Auto-Fix)

If the `--fix` argument is provided (or if running in auto-fix mode), apply all fixes from the unified findings (Step 5b):
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

If fixes were applied and peer reviewer was available:
```bash
gh pr review <PR_NUMBER> --comment --body "Cross-reviewed (local + peer). <N> issue(s) found and fixed."
```

If fixes were applied and peer reviewer was unavailable:
```bash
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed (local only). <N> issue(s) found and fixed."
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
| Peer reviewer unavailable | Proceed with local-only self-review, notify user |

## Usage

```
/git:review
/git:review 42
PR 리뷰해줘
코드 리뷰
```
