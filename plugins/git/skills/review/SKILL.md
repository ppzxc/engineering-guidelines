---
name: review
description: Use when the user wants to review, automatically fix, and comment on a GitHub PR. — /git:review, "PR 리뷰", "코드 리뷰"
user-invocable: true
---

# review — PR Code Review & Auto-Fix

PR diff 분석 → 언어 감지 → Self/Peer SUBAGENT 병렬 dispatch → severity-gated 병합 → 수정 적용 → PR 코멘트 제출.

## Execution Steps

### 1. Find PR Number

PR 번호가 인자로 제공된 경우 사용.
없으면 현재 브랜치에서 감지:

```bash
git branch --show-current
gh pr view <FEATURE_BRANCH> --json number,title,state
```

PR이 없으면 사용자에게 직접 PR 번호 요청.

### 2. Fetch PR Info

```bash
gh pr view <PR_NUMBER> --json number,title,state,headRefName,baseRefName,additions,deletions,files,commits,url
gh pr checks <PR_NUMBER>
```

### 3. Detect Languages

Step 2에서 가져온 `files` 필드 사용 (추가 API 호출 불필요).

변경된 파일 확장자 → 언어 매핑:

| Extension | Language |
|-----------|----------|
| `.go` | go |
| `.java` | java |
| `.ts`, `.tsx` | typescript |
| `.js`, `.jsx` | javascript |
| `.py` | python |
| `.rs` | rust |

고유 언어 집합 수집. Spring 감지 여부 확인: diff에 `@RestController`, `@Service`, `@Component`, `@Repository`, `@Controller`, `@Configuration`, 또는 `import org.springframework.` 포함 여부.

### 4. Build Peer Ruleset

감지된 언어에 따라 peer prompt에 임베드할 ruleset 결정 (`peer-review-cli.md` Language Rulesets 섹션 참조):

| 감지 언어 | Ruleset 섹션 포함 |
|-----------|------------------|
| java (Spring 없음) | Java Ruleset |
| java (Spring 감지) | Java Ruleset + Java + Spring Ruleset |
| go | Go Ruleset |
| 기타 / 없음 | `<RULESET>` 비움 |

### 5. Cross-Review (parallel, host-aware)

PR diff 획득:
```bash
gh pr diff <PR_NUMBER>
```

---

#### Claude Code host — 두 SUBAGENT 병렬 dispatch

**5a. Self-Review SUBAGENT**

Agent 툴로 `pr-review-toolkit:code-reviewer` dispatch.

Prompt:

```
You are reviewing a GitHub PR as a self-reviewer.

Review the following diff thoroughly for bugs, security issues, and CLAUDE.md compliance.

Output MUST follow subagent-output-schema exactly:

reviewer: pr-review-toolkit:code-reviewer

| severity | file:line | category | issue |
| --- | --- | --- | --- |

Immediately after each row, add:
```diff
- old line
+ fixed line
```

Confidence → severity mapping:
- confidence 90-100 → severity: critical
- confidence 80-89 → severity: high
- below 80: do not report

severity: critical=security/data-loss, high=bug/runtime-error, medium=logic-issue, low=style/naming
If no issues: write "reviewer: pr-review-toolkit:code-reviewer\n\nNo issues found."

--- DIFF START ---
{PR_DIFF}
--- DIFF END ---
```

**5b. Peer-Review Coordinator SUBAGENT**

Agent 툴로 general-purpose dispatch.

Prompt:

```
You are a Peer Review Coordinator. Invoke an external LLM CLI to review a PR diff.

Host: Claude Code. Peer pool (in priority order): agy → gemini → codex.
If all fail: return exactly "reviewer: claude-self-generate\n\nNo issues found."

Follow peer-review-cli.md exactly:
1. Pre-flight: timeout 3 <cli> --version for each CLI in pool order
2. Try each available CLI with the review prompt
3. On any sentinel (NOT_FOUND/TIMEOUT/ERROR): skip to next CLI
4. Return raw output from first successful CLI

Ruleset and diff for embedding in CLI prompt:

<RULESET>
{RULESET from Step 4}
</RULESET>

<DIFF>
{PR_DIFF}
</DIFF>

Output must match subagent-output-schema.md format.
```

두 SUBAGENT 완료 대기 (동기 실행).

---

#### Gemini/agy/Codex host — sequential (self inline + peer CLI)

Self review: host가 diff를 직접 분석 (general review criteria). subagent-output-schema.md 포맷으로 출력.

Peer review: peer-review-cli.md의 호스트별 peer pool 따라 CLI fallback 체인 실행:
- Gemini host: claude → agy → codex
- agy host: claude → gemini → codex
- Codex host: claude → agy → gemini

Peer review 실패 시 (모든 sentinel): self-only로 진행. User notify.

---

#### 5c. Merge Findings (main thread)

Self (5a)와 Peer (5b) findings 수신 후 severity-gated hybrid 머지:

| Severity | 머지 규칙 |
|----------|----------|
| `critical`, `high` | **Union** — 어느 한쪽이라도 발견하면 포함 |
| `medium`, `low` | **Intersection** — 양쪽 모두 발견 시에만 포함 |

중복 제거: 동일 `file:line` + `category` → 단일 항목으로 통합 (양 reviewer 언급).

Peer unavailable: Self findings만 사용.
Self SUBAGENT 실패: Peer findings만 사용. User notify.

결과: 정확한 fix patch가 포함된 단일 unified findings 목록.

### 6. Apply Fixes & Push (Auto-Fix)

`--fix` 인자 제공 시 또는 auto-fix 모드: 5c unified findings 기반 수정 적용 (main thread):
1. **Apply Changes:** source 파일 직접 수정 (Edit 툴)
2. **Commit:**
```bash
git add .
git commit -m "fix: address review comments"
```
3. **Push:**
```bash
git push origin <HEAD_REF_NAME>
```

finding 없으면 skip.

### 7. Submit Review Comment

수정 후 (또는 수정 없는 경우) PR에 review comment 제출:

```bash
# fix 적용 + peer available:
gh pr review <PR_NUMBER> --comment --body "Cross-reviewed (code-reviewer + <peer: agy|gemini|codex>). <N> issue(s) found and fixed. (critical:<c> high:<h> medium:<m> low:<l>)"

# fix 적용 + peer unavailable:
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed (self-only: code-reviewer). <N> issue(s) found and fixed."

# fix 없음:
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed. No issues found."
```

*Note: author는 자신의 PR을 approve할 수 없으므로 comment 사용.*

## Error Handling

| Situation | Action |
|-----------|--------|
| PR not found | Abort, ask user for PR number |
| PR already merged/closed | Abort, display current state |
| CI failing | Include CI failure details in review |
| Empty diff | Display "No changes found" and abort |
| Peer reviewer unavailable | Proceed with self-only, notify user |
| Self SUBAGENT failed | Proceed with peer findings only, notify user |
| Both failed | Abort, display error |

## References

- `references/subagent-output-schema.md` — Self/Peer SUBAGENT 공통 출력 스키마
- `references/peer-review-cli.md` — CLI 폴백 체인, language rulesets, host fallback matrix

## Usage

```
/git:review
/git:review 42
PR 리뷰해줘
코드 리뷰
```
