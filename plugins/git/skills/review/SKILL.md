---
name: review
description: Use when the user wants to review, automatically fix, and comment on a GitHub PR. — /git:review, "PR 리뷰", "코드 리뷰"
user-invocable: true
---

# review — PR Code Review & Auto-Fix

PR diff 분석 → 언어 감지 → Self/Peer SUBAGENT 병렬 dispatch → union+agreement 태그 머지 → severity×agreement fix-gate → PR 코멘트 제출.

## Argument Parsing

실행 전 인자 파싱:

| Argument | Description |
|----------|-------------|
| `<PR number>` | 리뷰할 PR 번호 (없으면 현재 브랜치에서 감지) |
| `--fix` | Auto-fix 모드 (git:clean 내부 호출 시 전달됨) |
| `--fast` | tier = fast (5a: haiku, 5b: fast 모델) |
| `--balanced` | tier = balanced (5a: sonnet, 5b: balanced 모델) |
| `--deep` | tier = deep (5a: opus, 5b: deep 모델) — **기본값** |

**tier 검증:** `--fast` / `--balanced` / `--deep` 세 값만 허용. 그 외 tier 단어 입력 시 즉시 에러 후 중단:
```
Error: 알 수 없는 tier '...' — 유효값: --fast | --balanced | --deep
```

인자들은 직교(독립): PR 번호 · `--fix` · tier 세 종류를 임의 조합 가능.

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

Agent 툴로 `pr-review-toolkit:code-reviewer` dispatch. `model` 파라미터에 tier 매핑 적용:

| tier | model 파라미터 |
|------|--------------|
| fast | haiku |
| balanced | sonnet |
| deep (기본) | opus |

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

severity: → `plugins/_shared/references/severity-taxonomy.md` 4-level 표준 참조
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

Tier: {TIER} — use the "Tier × CLI 모델 매핑" table in peer-review-cli.md to select the correct model flag and reasoning_effort for each CLI.

Follow peer-review-cli.md exactly:
1. Pre-flight: timeout 3 <cli> --version for each CLI in pool order
2. Try each available CLI with the review prompt and tier-matched model
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

두 SUBAGENT 완료 대기 (동기 실행):
1. `invoke_subagent` 호출 직후, 현재 서브에이전트들의 완료를 대기 중이라는 진행 상황 메시지(예: "Self/Peer 서브에이전트 완료 대기 중...")를 반드시 텍스트로 출력하고 턴을 종료(stop calling tools)한다. (대기 전 텍스트 출력이 누락되면 대기 데드락 현상이 발생한다.)
2. 대기 과정에서 데드락을 방지하고 상태 갱신을 강제하기 위해, 1회 호출 후 `schedule` 툴을 사용하여 30초 뒤에 `Peer review status check` 알림을 설정한다. [ADR-0049]
3. 알림을 받아 깨어나거나 subagent notification을 받으면 `manage_subagents` `list`를 호출하여 두 subagent의 status가 모두 Done인지 확인한다. 둘 다 Done이 아니라면 대기 메시지를 다시 출력하고 2번 단계(schedule 예약 및 턴 종료)를 반복하여 대기한다. [ADR-0049]

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

Self (5a)와 Peer (5b) findings 수신 후 union + agreement 태그 머지:

1. **Union 수집**: Self와 Peer 양쪽 findings를 모두 포함 (버리지 않음).
2. **퍼지 dedup**: `(file:line ±2줄, category)` 기준 중복 제거. 양쪽에서 발견 시 단일 항목으로 통합 (양 reviewer 언급).
3. **Agreement 태그 부여** (main thread 계산):
   - `both`: Self와 Peer 양쪽에서 발견
   - `single`: 어느 한쪽만 발견

| 상황 | 처리 |
|------|------|
| Peer unavailable | Self findings만 사용. 전 항목 → `single` 태그. |
| Self SUBAGENT 실패 | Peer findings만 사용. 전 항목 → `single` 태그. User notify. |
| 양쪽 모두 실패 | Abort, display error. |

결과: agreement 태그(`both`/`single`)가 포함된 단일 unified findings 목록.

### 6. Apply Fixes & Push (Auto-Fix)

`--fix` 인자 제공 시 또는 auto-fix 모드: 5c unified findings 기반 **severity × agreement fix-gate** 적용 (main thread):

| severity | agreement | 처리 |
|----------|-----------|------|
| `critical`, `high` | `both` 또는 `single` | **자동수정** |
| `medium`, `low` | `both` | **자동수정** |
| `medium`, `low` | `single` | **코멘트 보고만** (수정 안 함) |

자동수정 대상 finding이 있을 경우:
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
gh pr review <PR_NUMBER> --comment --body "Cross-reviewed (code-reviewer[<TIER>/<MODEL>] + <peer: agy|gemini|codex>). <N> issue(s) found and fixed. (critical:<c> high:<h> medium:<m> low:<l>) | agreement: both:<b> single:<s>(코멘트만)"

# fix 적용 + peer unavailable:
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed (self-only: code-reviewer[<TIER>/<MODEL>]). <N> issue(s) found and fixed."

# fix 없음:
gh pr review <PR_NUMBER> --comment --body "Auto-reviewed. No issues found. (tier: <TIER>)"
```

`<TIER>/<MODEL>`: 사용한 tier와 실제 모델명 (예: `deep/opus`, `fast/haiku`, `balanced/sonnet`).
`<b>`: both 합의 finding 수. `<s>`: single 발견 finding 수 (코멘트 보고, 자동수정 제외).

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
/git:review --fast
/git:review 42 --balanced
PR 리뷰해줘
코드 리뷰
```
