---
name: auto
description: Use when performing automated cross-platform peer-reviews between Claude Code and Antigravity CLI without manual host routing.
user-invocable: true
---

# llm:auto

현재 구동 중인 AI 플랫폼 호스트(Claude Code 또는 Antigravity CLI)를 자동으로 판별하고, 자신이 아닌 **상대 플랫폼으로 위임(Delegation)하여 크로스 코드 리뷰 및 피어 체크**를 오케스트레이션합니다. 

사용자가 개별 호스트의 환경을 수동으로 감지하여 명령어를 라우팅할 필요를 없애주는 마스터 오케스트레이터 스킬입니다.

## Sentinel 처리

대상 플랫폼 위임 호출 중 실패(타임아웃, CLI 부재 등)가 발생하면, 프로세스의 무기한 대기나 중단을 방지하기 위해 즉시 **자체 플랫폼 로컬 리뷰(Self-Review)**로 Fallback 처리를 강제합니다.

---

## Step 1. 호스트 환경 자동 감지

이 지침을 수신한 AI Agent는 자신이 구동되고 있는 로컬 호스트 터미널의 가용 시그널을 확인합니다.
1. **CLAUDE (Claude Code)** 호스트 판별:
   * 환경에서 `mcp__agy__agy_cross_check` 등 `mcp__agy__` MCP 도구가 발견되는 경우.
2. **AGY (Antigravity CLI)** 호스트 판별:
   * MCP 도구가 보이지 않고, `claude` CLI 혹은 `rtk` 환경이 가용하며 `GEMINI_` 혹은 `AGY` 환경 시그널이 우세한 경우.

---

## Step 2. 플랫폼 양방향 위임 라우팅

환경 감지 결과에 따라 즉시 상대방의 핵심 리뷰 스킬로 라우팅을 수행합니다.

### 케이스 A. 현재 호스트가 CLAUDE (Claude Code)인 경우
현재 플랫폼이 Claude이므로, 상대 플랫폼인 **Gemini/Antigravity (AGY)**의 강력한 컨텍스트 분석을 받아야 합니다.
* **위임 행동**: **`llm:agy`** 스킬 지침을 전적으로 활성화하여 실행합니다.
  * 1차적으로 `mcp__agy__agy_cross_check(plan=...)` MCP 도구를 사용해 리뷰 및 크로스체크를 수행합니다.
  * MCP 도구가 부재할 경우, 로컬 쉘에서 `rtk proxy agy` 또는 `agy` 명령을 트리거하여 Gemini/Antigravity 분석을 획득합니다.

---

### 케이스 B. 현재 호스트가 AGY (Antigravity CLI)인 경우
현재 플랫폼이 Antigravity이므로, 상대 플랫폼인 **Claude Code (CLAUDE)**의 아키텍처 및 세부 추론 리뷰를 받아야 합니다.
* **위임 행동**: **`llm:claude`** 스킬 지침을 전적으로 활성화하여 실행합니다.
  * `llm:claude` 가이드에 명시된 3초 pre-flight `claude --version`을 거쳐, 안전하게 stdin 파이프 방식으로 `claude -p`를 트리거하여 리뷰를 위임합니다.

---

## 예외 상황 및 Sentinel Fallback

위임 처리 중 다음 예외 발생 시, 즉시 로컬 자체 모델을 통한 **자가 리뷰(Self-Review)**를 완수하여 결과를 반환합니다.
* 상대 플랫폼 CLI 호출이 `CLAUDE_CLI_TIMEOUT` / `AGY_TIMEOUT` 등에 의해 타임아웃된 경우.
* 위임할 툴체인(MCP 서버, CLI 바이너리)이 설치되어 있지 않아 `CLAUDE_CLI_NOT_FOUND` / `AGY_NOT_FOUND`가 발생한 경우.
* 상대 진영 호출 시 에러 코드(Exit code > 0)가 반환된 경우.

```markdown
## Peer 위임 오류 - 로컬 자가 리뷰 (Fallback)
[상대방 플랫폼 CLI/MCP 호출 중 감지된 예외 및 원인 요약]
- 예외: CLAUDE_CLI_NOT_FOUND / AGY_TIMEOUT 등
- 결과: 로컬 모델 추론 성능을 활용한 1차 자체 리뷰 리포트 생성 완료.
```
