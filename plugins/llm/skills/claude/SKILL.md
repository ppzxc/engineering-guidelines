---
name: claude
description: Use when code review or architectural verification needs to be performed using Claude Code, particularly when triggered from either Claude Code directly or from Gemini/Antigravity via non-interactive CLI.
user-invocable: true
disable-model-invocation: true
---

# llm:claude

Claude Code의 강력한 아키텍처 추론 및 검증 능력을 활용하여 정밀 코드 리뷰를 수행합니다. 현재 호스트 환경을 스스로 판단하여, CLAUDE 환경이면 즉시 모델 정밀 리뷰를 수행하고, AGY 환경이면 비대화형 Claude CLI를 호출하여 리뷰를 위임합니다.

## Sentinel 처리

AGY 호스트에서 Claude CLI 호출 중 아래와 같은 예외가 발생하면 즉시 Conservative mode로 전환하고 **동일 인자로의 재호출을 즉각 금지**합니다.

| Sentinel | 의미 | 처리 |
|---|---|---|
| `CLAUDE_CLI_TIMEOUT:` | 300s 초과 대기 | AGY 로컬 모델 자체 리뷰로 fallback |
| `CLAUDE_CLI_ERROR(exit=...)` | CLI 비정상 종료 | AGY 로컬 모델 자체 리뷰로 fallback |
| `CLAUDE_CLI_NOT_FOUND:` | Claude CLI 부재 | AGY 로컬 모델 자체 리뷰 + 설치 안내 |

## Step 1. 호스트 환경 감지

AI Agent는 사용 가능한 도구 및 환경 정보를 확인하여 구동 중인 호스트를 판별합니다.
* `mcp__agy__` 계열 도구 노출 여부 -> 감지되면 **CLAUDE (Claude Code)** 호스트.
* MCP 도구가 보이지 않고 `claude` CLI가 PATH 상에 존재 -> **AGY (Antigravity CLI)** 호스트.

---

## Step 2. 호스트별 실행 분기

### 케이스 A. CLAUDE (Claude Code) 호스트에서 직접 실행하는 경우

Claude의 고수준 추론을 활용하여 대상 파일/코드에 대해 아래 3가지 관점의 정밀 리뷰를 자체 수행하고 마크다운 리포트를 즉각 반환합니다.
1. **성능 & 리소스 최적화**: 메모리 누수, 불필요한 루프, 비효율적 연산 감지.
2. **보안 & 안정성**: 쉘 인젝션 취약점, 하드코딩된 크레덴셜, 예외 처리 누락 점검.
3. **아키텍처 & 스타일**: 프로젝트 컨벤션(`AGENTS.md` 등) 및 단일 책임 원칙(SRP) 준수 여부.

---

### 케이스 B. AGY (Antigravity CLI) 호스트에서 실행하는 경우 (위임 호출)

**Step 2-1. Pre-flight 가용성 검증 (필수):**
무한 대기(300s hang)를 원천 차단하기 위해 3초 타임아웃의 버전 체크 명령을 먼저 실행합니다.
```bash
timeout 3 claude --version || echo "CLAUDE_CLI_NOT_FOUND"
```
* 출력물에 `CLAUDE_CLI_NOT_FOUND`가 포함되어 있거나 에러 코드가 리턴되면 즉시 **Sentinel Fallback** 처리합니다.

**Step 2-2. 비대화형 CLI 위임 호출 (stdin pipe 사용):**
대용량 파일/디프 전송 시 `ARG_MAX` 한계 초과 및 쉘 인젝션을 방지하기 위해 반드시 **stdin 리디렉션 파이프** 형식을 고수합니다.

```bash
cat << 'EOF' | claude -p "Perform architectural and code quality review in Korean markdown format."
<리뷰 대상 파일 경로 또는 Diff 내용 전체>
EOF
```
* 호출 실패 또는 타임아웃 시 즉시 Sentinel 메커니즘을 가동하여 AGY 로컬 자체 리뷰로 즉시 fallback을 수행합니다.

---

## 흔히 하는 실수 (Common Mistakes)

* **Pre-flight 스킵**: `claude --version` 체크를 생략하고 바로 위임 호출을 트리거했다가, 로그인 세션 만료 등의 원인으로 인해 300초간 hang 상태에 빠지는 현상.
* **Here-doc 식별자 이스케이프 누락**: `cat << EOF` 형태로 따옴표 없이 사용 시 코드 내부의 `$()` 나 백틱이 현재 호스트 쉘에서 미리 해석되어 인젝션 혹은 구문 에러를 야기함. 반드시 `cat << 'EOF'` 형식으로 홑따옴표 식별자를 적용해야 합니다.
