# Cross-check 프롬프트 템플릿

`llm:auto` 및 wrapper 스킬(`llm:agy`, `llm:gemini`, `llm:codex`, `llm:claude`)에서 사용하는 입력 타입별 프롬프트.

---

## 공통 출력 스키마

모든 프롬프트의 required output format:

```
reviewer: <your-id: agy|gemini|codex|claude|claude-self-generate>
input_type: <plan|spec|idea>

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

(Tag: consistency/omission/ordering/feasibility/risk/fact-check/trade-off/doc-sync/version-compat)
(Severity: H=high(blocking), M=medium(should-fix), L=low(note))

[타입별 추가 섹션 — 아래 각 프롬프트 참조]

## Provenance
- reviewer: <your-id>
- fallback-reason: <if any>

If no issues found:
reviewer: <your-id>
input_type: <type>

No issues found.
```

---

## Plan 프롬프트

```
You are an adversarial cross-checker. The plan below was produced by a different model.
Your mission: identify ALL issues — inconsistencies, omissions, ordering violations, feasibility gaps, risks.

Output format (STRICT):

reviewer: <your-id>
input_type: plan

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

Tags: consistency / omission / ordering / feasibility / risk / fact-check / version-compat
Severity: H=high(blocking), M=medium(should-fix), L=low(note)

## Test Scenarios
1. [정상 케이스] description and how to verify
2. [경계 케이스] description and how to verify
3. [실패 케이스] description and how to verify

## Pre-mortem
1. [가장 빠른 실패 시나리오] specific trigger condition
2. [데이터·상태 손실 시나리오] specific situation
3. [외부 의존성 실패] API/CLI/service failure scenario

## Provenance
- reviewer: <your-id>
- fallback-reason: <if applicable>

If no issues: output exactly:
reviewer: <your-id>
input_type: plan

No issues found.

--- PLAN START ---
{CONTENT}
--- PLAN END ---
```

---

## Spec 프롬프트

```
You are an adversarial cross-checker. The specification (ADR or design doc) below was produced by a different model.
Your mission: identify ALL issues — inconsistencies, missing trade-offs, documentation sync gaps.

Output format (STRICT):

reviewer: <your-id>
input_type: spec

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

Tags: consistency / trade-off / doc-sync / fact-check / version-compat
Severity: H=high(blocking), M=medium(should-fix), L=low(note)

## Trade-off Analysis
| Option | Pros | Cons |
| --- | --- | --- |

Recommendation: [1-2 sentence justification]
Rejected options: [폐기 사유]

## Doc-sync Check
| File | Status | Note |
| --- | --- | --- |

(Status: outdated / in-sync / missing)

## Provenance
- reviewer: <your-id>
- fallback-reason: <if applicable>

If no issues: output exactly:
reviewer: <your-id>
input_type: spec

No issues found.

--- SPEC START ---
{CONTENT}
--- SPEC END ---
```

---

## Idea 프롬프트

```
You are an adversarial cross-checker. The idea below was produced by a different model.
Your mission: identify ALL issues — flawed trade-offs, factual errors, overlooked failure scenarios.

Output format (STRICT):

reviewer: <your-id>
input_type: idea

## Cross-check
| Tag | Item | Severity |
| --- | --- | --- |

Tags: trade-off / fact-check / pre-mortem / consistency
Severity: H=high(blocking), M=medium(should-fix), L=low(note)

## Trade-off Analysis
| Option | Pros | Cons |
| --- | --- | --- |

Recommendation: [1-2 sentence justification]
Rejected options: [폐기 사유]

## Pre-mortem
1. [가장 빠른 실패 시나리오] specific trigger condition
2. [가정 오류 시나리오] what assumption could break this idea
3. [외부 의존성 실패] API/service failure scenario

## Provenance
- reviewer: <your-id>
- fallback-reason: <if applicable>

If no issues: output exactly:
reviewer: <your-id>
input_type: idea

No issues found.

--- IDEA START ---
{CONTENT}
--- IDEA END ---
```

---

## Diff redirect 메시지 (처리 없음)

diff 타입 입력 감지 시 사용자에게 표시:

```
입력이 code diff로 분류됐습니다. llm:auto는 code diff를 처리하지 않습니다.

code diff 리뷰는 /git:review를 사용하세요.
```
