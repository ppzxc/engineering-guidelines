# Peer Review CLI — 폴백 체인

git:review Step 5b (Peer-Review Coordinator SUBAGENT)에서 참조한다.
`context:plan/references/verification.md`의 CLI 패턴을 코드 리뷰용으로 fork.

공통 인프라(host matrix, pre-flight, 호출 골격, sentinel): → [`peer-fallback-core.md`](../../../../_shared/references/peer-fallback-core.md)

---

## Tier × CLI 모델 매핑

`--fast` / `--balanced` / `--deep` tier에 따라 5a Self(Claude subagent)와 5b Peer CLI 모두 해당 모델로 실행한다.
**이 표를 수정하면 5a/5b 양쪽 동작이 변경된다 — 모델명 변경 시 이 표 1곳만 수정.**

### 5a Self — Claude subagent `model` 파라미터

| tier | model |
|------|-------|
| fast | haiku |
| balanced | sonnet |
| deep (기본) | opus |

### 5b Peer CLI — 모델 플래그

| tier | gemini | codex |
|------|--------|-------|
| fast | `-m gemini-2.5-flash` | `--model o4-mini -c model_reasoning_effort=low` |
| balanced | `-m gemini-2.5-pro` | `--model o3 -c model_reasoning_effort=medium` |
| deep (기본) | `-m gemini-2.5-pro` | `--model o3 -c model_reasoning_effort=high` |

**agy**: 모델 선택 플래그 미지원. 전 tier에서 CLI 기본 모델 사용. provenance에 `agy-default` 기록.
**매핑 미확인 CLI**: 기본값 사용 + provenance에 `<cli>-default` 기록.

CLI 호출 시 위 플래그를 해당 CLI 호출 패턴에 삽입한다.

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

severity: → [`severity-taxonomy.md`](../../../../_shared/references/severity-taxonomy.md) 4-level 표준 참조

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

→ 호출 골격(mktemp+trap+timeout, sentinel 처리): [`peer-fallback-core.md`](../../../../_shared/references/peer-fallback-core.md#cli-호출-골격)

각 CLI 호출 시 Review Prompt를 tmpfile에 작성 후 `{RULESET_BLOCK}`과 `{DIFF_CONTENT}`를 주입하여 실행.
tier별 모델 플래그는 위 Tier × CLI 모델 매핑 표에서 선택.

---

## Provenance 형식

Peer review 완료 후 reviewer 정보 기록:
```
cross-reviewed by <self-agent>[<tier>/<model>] + <peer: agy|gemini|codex|claude-self-generate>[<tier>/<model>]
```

`<tier>/<model>` 예시: `deep/opus`, `fast/haiku`, `balanced/gemini-2.5-pro`, `fast/agy-default`.
