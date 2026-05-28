---
name: agy
description: Cross-check execution plans using Antigravity (agy) MCP or CLI. Analysis output only — no code execution. — /llm:agy, "agy crosscheck", "교차검증"
user-invocable: true
---

# agy Crosscheck

실행 계획 교차검증. 분석 출력 전용 — 코드 실행 없음.

## Sentinel 처리

응답이 아래 prefix로 시작하면 즉시 처리하고 **동일 인자 재호출 금지.**

| Sentinel | 의미 | 처리 |
|----------|------|------|
| `AGY_TIMEOUT:` | 300s 초과 | `llm:auto` 폴백 체인에서 다음 peer 시도. 단독 호출 시 → Claude self-generate |
| `AGY_ERROR(exit=...)` | agy 비정상 종료 | `llm:auto` 폴백 체인에서 다음 peer 시도. 단독 호출 시 → Claude self-generate |
| `AGY_NOT_FOUND:` | agy 바이너리 부재 | `llm:auto` 폴백 체인에서 다음 peer 시도. 단독 호출 시 → Claude self-generate + 설치 안내 |

## Step 1. Cross-check

`mcp__agy__agy_cross_check(plan=<초안 실행 계획 전문>)`

결과를 사용자에게 표시한다.

**sentinel 응답 시 → 다음 peer 시도 (`llm:auto` 폴백 체인에서 처리). 단독 호출 시 → Claude self-generate:**

```markdown
## Cross-check (Claude self-generated)

| Tag | Item | Severity |
|-----|------|----------|
| [consistency|omission|ordering|risk|feasibility|version-compat] | 설명 | H/M/L |

## Test Scenarios (Claude self-generated)
1. [정상 케이스] 설명 및 검증 방법
2. [경계 케이스] 설명 및 검증 방법
3. [실패 케이스] 설명 및 검증 방법

## Pre-mortem (Claude self-generated)
1. [실패 이유 1] 구체적 시나리오
2. [실패 이유 2] 구체적 시나리오
3. [실패 이유 3] 구체적 시나리오
```

---

운영 (인증 만료·conversations 누적 cleanup): `references/operations.md` 참조.

