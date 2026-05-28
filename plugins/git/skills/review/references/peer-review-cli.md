# Peer Review CLI — 폴백 체인

git:review Step 5b (Peer-Review Coordinator SUBAGENT)에서 참조한다.
`context:plan/references/verification.md`의 CLI 패턴을 코드 리뷰용으로 fork.

---

## Host Fallback Matrix

| Self host | Peer 우선순위 |
|-----------|---------------|
| Claude Code | agy → gemini → codex |
| Gemini CLI | claude → agy → codex |
| Antigravity (agy) | claude → gemini → codex |
| Codex | claude → agy → gemini |

자기 자신은 풀에서 제외 (ADR-0022/0023). 전부 실패 시 `reviewer: claude-self-generate\n\nNo issues found.` 반환 후 notify user.

---

## Pre-flight 순서

CLI 시도 전 반드시 version 확인:

```bash
timeout 3 agy --version    2>/dev/null || echo "AGY_NOT_FOUND:"
timeout 3 gemini --version 2>/dev/null || echo "CLI_NOT_FOUND:gemini"
timeout 3 codex --version  2>/dev/null || echo "CLI_NOT_FOUND:codex"
timeout 3 claude --version 2>/dev/null || echo "CLAUDE_CLI_NOT_FOUND:"
```

exit ≠ 0이면 해당 sentinel 발동 → 다음 CLI로 skip. 확인된 CLI만 시도.

---

## 코드 리뷰 Prompt 템플릿

```
You are an adversarial code reviewer. The diff below was written by a different model.
Your mission: identify ALL defects — bugs, security issues, logic errors, style violations.

Output format (STRICT):

reviewer: <your-id: agy|gemini|codex>

| severity | file:line | category | issue |
| --- | --- | --- | --- |

Immediately after each row, add a fix block:
```diff
- old line
+ fixed line
```

severity: critical=security/data-loss, high=bug/runtime-error, medium=logic-issue, low=style/naming

If no issues found: output exactly:
reviewer: <your-id>

No issues found.

<RULESET>
{RULESET_BLOCK}
</RULESET>

--- DIFF START ---
{DIFF_CONTENT}
--- DIFF END ---
```

`{RULESET_BLOCK}`: 언어 감지 결과에 따라 아래 섹션에서 주입. 없으면 비워둔다.

---

## Language Rulesets (peer prompt 인라인 임베드용)

### Java Ruleset

```
## Java Review Rules

Critical (즉시 수정):
- 도메인 레이어에 Lombok(@Builder/@Data) 사용 금지 — 캡슐화 위반
- 비즈니스 실패에 Exception 사용 금지 — Sealed Class Result 패턴 사용
- 빈약한 도메인 모델(Anemic Model) — 비즈니스 로직을 도메인 객체로 이동
- 공유 가변 필드(non-final) — AtomicXxx 또는 불변화
- 외부 호출에 Timeout/Circuit Breaker 없음

High (수정 권장):
- Service 간 직접 순환 의존 — 이벤트/레이어 분리
- 동시성: synchronized 블록 내 JNI/native 호출 — Platform Thread Pool 격리 필수
- ThreadLocal 애플리케이션 코드 사용 — ScopedValue 마이그레이션 권장
- 여러 필드 compound action(check-then-act) — Lock 또는 CAS 패턴

Medium:
- 원시 타입 집착(Primitive Obsession) — Value Object 도입
- Effective Java 위반(equals/hashCode, static factory)
- 메서드 길이 / 중복 코드 / 매직 넘버
```

### Java + Spring Ruleset (Spring 어노테이션 감지 시 추가)

```
## Spring Review Rules

Critical:
- @Transactional(readOnly=true) 클래스 기본값 누락 또는 쓰기 메서드에 override 누락
- dirty checking 비활성화 상태(readOnly=true)에서 명시적 save 없음
- @Transactional self-invocation(this.method()) — AOP 미작동
- N+1: X-to-Many + Pageable에 Fetch Join/@EntityGraph 사용 — OOM 위험
- 생성자 주입 아닌 @Autowired 필드 주입

High:
- Controller에 비즈니스 로직 직접 구현
- ProblemDetail(RFC 9457) 미사용 에러 응답
- spring.jpa.open-in-view=true(기본값) — 예측 불가능한 Lazy 로딩
- WebClient를 동기 환경에서 사용 — RestClient 사용

Medium:
- @WebMvcTest 없는 Controller 단위 테스트
- @Testcontainers 없는 Repository 통합 테스트
- EAGER 로딩 기본값 설정
```

### Go Ruleset

```
## Go Review Rules

Critical (MUST):
- library code에서 panic 사용 — error 반환으로 교체
- 동일 에러를 log + return 중복 처리
- 공유 가변 필드 미동기화 — AtomicXxx / sync.Mutex
- WaitGroup.Add 위치 — goroutine 시작 전에 호출
- goroutine exit path 없음 (context cancel 불가)
- SQL에 user input 직접 보간 — parameterized query 사용
- 파일 경로 미정규화 — filepath.Clean 사용

High (SHOULD):
- sync primitive 값 복사 (mutex copy) — 포인터 리시버로 변경
- Go < 1.22 loop var closure capture
- unbuffered channel에 보장된 receiver 없음
- deferred Close() 에러 무시 (write path)
- goroutine 소유권 없음 (fire-and-forget)

Medium:
- 5+ method interface — 분리 고려
- 단일 구현체에 exported interface — 조기 추상화
- MixedCaps 아닌 snake_case 네이밍
- 두문자어 비대문자 처리 (Http → HTTP, Url → URL)

Low:
- //nolint 주석 없는 lint 억제
- package stuttering (http.HTTPServer → http.Server)
- exported 타입/함수에 doc comment 없음
```

---

## CLI 호출 패턴

입력은 반드시 stdin pipe 또는 임시파일로 전달. CLI 인자 직접 보간 금지 (shell injection / ARG_MAX 초과 방지).

### AGY

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Write prompt to tmpfile (heredoc + diff append)
cat > "$TMPFILE" << 'REVIEWEOF'
You are an adversarial code reviewer. The diff below was written by a different model.
Your mission: identify ALL defects — bugs, security issues, logic errors, style violations.

Output format (STRICT):

reviewer: agy

| severity | file:line | category | issue |
| --- | --- | --- | --- |

Immediately after each row, add a fix block:
```diff
- old line
+ fixed line
```

severity: critical=security/data-loss, high=bug/runtime-error, medium=logic-issue, low=style/naming

If no issues found: output exactly:
reviewer: agy

No issues found.

REVIEWEOF

# Append ruleset + diff
printf '<RULESET>\n%s\n</RULESET>\n\n--- DIFF START ---\n%s\n--- DIFF END ---\n' \
  "$RULESET_CONTENT" "$DIFF_CONTENT" >> "$TMPFILE"

timeout 330 agy -p "$(cat "$TMPFILE")" --print-timeout 300s
```

### Gemini

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'REVIEWEOF'
[동일 프롬프트, reviewer: gemini]
REVIEWEOF

printf '<RULESET>\n%s\n</RULESET>\n\n--- DIFF START ---\n%s\n--- DIFF END ---\n' \
  "$RULESET_CONTENT" "$DIFF_CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 gemini -p "CODE REVIEW MODE — see stdin"
```

### Codex

```bash
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'REVIEWEOF'
[동일 프롬프트, reviewer: codex]
REVIEWEOF

printf '<RULESET>\n%s\n</RULESET>\n\n--- DIFF START ---\n%s\n--- DIFF END ---\n' \
  "$RULESET_CONTENT" "$DIFF_CONTENT" >> "$TMPFILE"

cat "$TMPFILE" | timeout 300 codex exec -
```

### Claude CLI (비-Claude 호스트용)

```bash
# Pre-flight
timeout 3 claude --version || { echo "CLAUDE_CLI_NOT_FOUND:"; exit 1; }

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

cat > "$TMPFILE" << 'REVIEWEOF'
[동일 프롬프트, reviewer: claude]
REVIEWEOF

printf '<RULESET>\n%s\n</RULESET>\n\n--- DIFF START ---\n%s\n--- DIFF END ---\n' \
  "$RULESET_CONTENT" "$DIFF_CONTENT" >> "$TMPFILE"

printf '%s' "$(cat "$TMPFILE")" | timeout 300 claude -p "CODE REVIEW MODE — see stdin"
```

---

## Sentinel 처리

모든 sentinel → 다음 peer로 시도. 동일 인자 재호출 금지.

| Sentinel prefix | 의미 | 처리 |
|----------------|------|------|
| `AGY_NOT_FOUND:` | agy 부재 | 다음 peer |
| `AGY_TIMEOUT:` | 300s 초과 | 다음 peer |
| `AGY_ERROR(exit=N):` | 비정상 종료 | 다음 peer |
| `CLI_NOT_FOUND:` | gemini/codex 부재 | 다음 peer |
| `CLI_TIMEOUT:` | 300s 초과 | 다음 peer |
| `CLI_ERROR(exit=N):` | 비정상 종료 | 다음 peer |
| `CLAUDE_CLI_NOT_FOUND:` | claude CLI 부재 | 다음 peer |
| `CLAUDE_CLI_TIMEOUT:` | claude CLI 300s 초과 | 다음 peer |
| `CLAUDE_CLI_ERROR(exit=N):` | claude CLI 비정상 종료 | 다음 peer |
| (모두 실패) | — | self-only로 fallback, user notify |

---

## Provenance 형식

Peer review 완료 후 reviewer 정보 기록:
```
cross-reviewed by <self-agent> + <peer: agy|gemini|codex|claude-self-generate>
```
