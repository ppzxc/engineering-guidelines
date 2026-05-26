# `llm:claude` 및 `llm:auto` 도입을 통한 3각 LLM 스킬 스위트 구축

* Status: accepted
* Date: 2026-05-26
* Decision Makers: ppzxc, Antigravity
* Consulted: ppzxc
* Informed: ppzxc

## Context and Problem Statement

현재 `llm` 플러그인에는 `llm:agy` 단일 스킬만 정의되어 있어, 특정한 상황에서 수동으로 `agy` 플랫폼을 지정해야만 크로스체크가 진행된다. 
사용자는 현재 구동 중인 AI 플랫폼(Claude Code vs Antigravity CLI)을 자체 감지하고, 자신이 아닌 상대방 플랫폼으로 자동으로 리뷰 요청을 위임하여 실행할 수 있는 `llm:auto` 스킬을 요구하고 있다. 이를 위해 `llm:agy`(기존) 외에 Claude 진영을 대변하는 `llm:claude`(신규)를 추가하고, 두 스킬을 지능적으로 감지하여 분기해주는 `llm:auto`(신규) 오케스트레이터 스킬을 도입하여 완전한 **3대 스킬 조합(llm:agy, llm:claude, llm:auto)**을 구축하고자 한다.

## Decision Drivers

* **스킬 구성의 완결성 및 대칭성**: AGY를 사용하는 `llm:agy`와 짝을 이루는 CLAUDE 전용 스킬 `llm:claude`를 신규 확보하여 대칭성을 완성함.
* **자동화 및 제로 설정(Zero-configuration)**: AI 플랫폼 환경을 스스로 파악하여 `llm:auto`를 통해 적절한 타겟 스킬로 즉각 라우팅함.
* **기존 피어 리뷰 모델과의 일관성**: ADR-0022 및 ADR-0023에서 확립된 "양방향 peer cross-review 모델" 계승.
* **안정성 (Sentinel)**: 타 플랫폼 호출 실패 시 300초 이상의 대기(hang)나 충돌 없이 로컬 리뷰로 복귀(fallback)하는 안정성 보장.

## Considered Options

* **Option 1: `llm:auto` 내부에 분기 로직을 전적으로 흡수 (2-Skill 체제)**
  * `llm:agy` 스킬만 유지한 채, `llm:auto` 단일 스킬 내부에 Claude 호출 쉘 파이프라인 로직을 인라인으로 정의하여 관리하는 구조.
* **Option 2: 대칭적인 3-Skill 스위트 도입 (`llm:agy`, `llm:claude`, `llm:auto`)**
  * 각 플랫폼을 명시적으로 대변하는 단위 스킬(`llm:agy`, `llm:claude`)을 독립시키고, `llm:auto`는 오로지 환경 감지와 이 두 개 스킬 간의 라우팅 오케스트레이션만 전담하는 모듈식 구조.

## Decision Outcome

Chosen option: **"Option 2: 대칭적인 3-Skill 스위트 도입"**, because 스킬의 역할과 책임을 분리(Separation of Concerns)함으로써 각 플랫폼별 리뷰 가이드라인을 독립적으로 정밀화할 수 있고, 사용자가 필요한 경우 개별 스킬을 명시적으로 호출할 수도 있으며, `llm:auto`는 순수한 라우팅 역할만 깔끔하게 수행할 수 있기 때문입니다.

즉, 다음과 같은 연동 매트릭스를 따릅니다:

| 현재 실행 중인 호스트 | 대상 플랫폼 (리뷰어) | 위임 대상 스킬 | 1차 연동 수단 | 2차(Fallback) 연동 수단 |
| :--- | :--- | :--- | :--- | :--- |
| **CLAUDE (Claude Code)** | AGY (Antigravity CLI) | **`llm:agy`** | MCP 도구 (`mcp__agy__agy_cross_check`) | CLI 명령 (`rtk proxy agy` 또는 `agy`) |
| **AGY (Antigravity CLI)** | CLAUDE (Claude Code) | **`llm:claude`** | 비대화형 CLI (`claude -p`) | Local Self-Review Fallback (Sentinel 처리) |

### Consequences

* **Good**: 사용자가 호스트의 종류를 신경 쓸 필요 없이 단일 `/llm:auto` 슬래시 명령만으로 양방향 크로스-플랫폼 코드 리뷰를 완전 자동화할 수 있다.
* **Good**: 각 플랫폼별로 완전히 독립된 스킬 지침(`llm:agy`, `llm:claude`)을 가지므로, 모델 맞춤형 성능 개선 및 가이드라인 튜닝이 용이하다.
* **Good**: 사용자가 원할 경우 특정 플랫폼 스킬만 콕 집어 직접 실행할 수도 있다. (예: `/llm:claude` 또는 `/llm:agy`)
* **Bad**: 관리해야 할 마크다운 스킬 파일이 늘어나지만, 모듈화의 장점이 이를 상쇄한다.
* **Bad**: `claude` CLI가 로컬 환경에 사전 구성 및 로그인되어 있지 않으면 연동 과정에서 지연이 발생할 수 있다. (이는 3초 타임아웃의 pre-flight `claude --version` 체크 및 Sentinel 처리로 보완한다.)

### Confirmation

* Claude Code에서 `/llm:auto`를 실행했을 때 AGY 호스트임을 인지하여 **`llm:agy`** 스킬 호출로 자연스럽게 위임하는지 확인.
* Antigravity CLI (AGY)에서 `/llm:auto`를 실행했을 때 CLAUDE 호스트임을 인지하여 **`llm:claude`** 스킬 호출로 자연스럽게 위임하는지 검증.
* `/llm:claude` 직접 실행 시 Claude CLI 존재 여부를 pre-flight로 확인한 후 `claude -p`에 stdin 파이프로 코드를 안전하게 전달하여 리뷰 답변을 수집하는지 검증.
* 상대 진영의 CLI/MCP가 응답 불능일 경우 `AGY_TIMEOUT` 또는 `CLAUDE_CLI_TIMEOUT` 센티넬을 인지하여 자체 로컬 모델 리뷰로 매끄럽게 넘어가는지 확인.

## Pros and Cons of the Options

### Option 1: `llm:auto` 내부에 로직을 전적으로 흡수 (2-Skill 체제)

* **Good**: 생성할 물리적 파일 개수가 적어 버전 변경 등이 미세하게 간소화된다.
* **Bad**: 단일 파일 내부에서 분기 로직과 각기 다른 리뷰 지시문이 마구 혼재되어 유지보수 난이도가 급격히 올라간다.
* **Bad**: 사용자가 명시적으로 Claude 기반의 리뷰만 강제 수행하고 싶을 때 단독 호출할 수 있는 전용 인터페이스가 제공되지 않는다.

### Option 2: 대칭적인 3-Skill 스위트 도입

* **Good**: 책임의 완벽한 분리(Separation of Concerns). `agy` 스킬은 AGY 활용법만, `claude` 스킬은 Claude 활용법만 다루고, `auto`는 오직 호스트 감지 및 위임만 담당하여 가독성과 유지보수성이 극대화된다.
* **Good**: 대칭적인 스킬 스펙(`llm:agy`, `llm:claude`, `llm:auto`)을 구성하여 마켓플레이스 플러그인으로서의 완성도가 대폭 상승한다.
* **Bad**: 스킬 파일이 다수 생기므로, 변경 사항 발생 시 연동 버전을 정확히 동기화하는 절차가 필수적이다.

## More Information

* Amends ADR-0022 (`git:review` 양방향 peer cross-review 도입)
* Amends ADR-0023 (`git:clean` 양방향 peer cross-check 도입)
* Related skill documents:
  - [plugins/llm/skills/agy/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/llm/skills/agy/SKILL.md)
  - [plugins/llm/skills/claude/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/llm/skills/claude/SKILL.md)
  - [plugins/llm/skills/auto/SKILL.md](file:///home/ppzxc/projects/engineering-guidelines/plugins/llm/skills/auto/SKILL.md)
