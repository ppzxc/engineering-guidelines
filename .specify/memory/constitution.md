<!--
Sync Impact Report:
- Version change: v1.2.0 -> v2.0.0
- Modified principles:
  - Principle I, II, III, IV, V -> Re-mapped to Core Principles representing repository development conventions (Plugin-First, Multi-LLM, TDD, Git Workflow).
- Added sections:
  - Plugin-Specific Domain Standards (플러그인별 도메인 표준)
    - 1. Context & Plan Plugin Constraints
    - 2. API Guideline Review Standards
    - 3. Git & LLM Fallback Execution
- Removed sections: None
- Templates requiring updates:
  - .specify/templates/plan-template.md (✅ checked/aligned)
  - .specify/templates/spec-template.md (✅ checked/aligned)
  - .specify/templates/tasks-template.md (✅ checked/aligned)
- Follow-up TODOs: None
-->

# engineering-guidelines Constitution

## Core Principles

### I. Plugin-First & Modular Skill Design (플러그인 중심 및 모듈식 스킬 설계)
모든 스킬과 플러그인은 `plugins/{name}/` 내에 독립적인 배포 단위로 작성하며, `.claude-plugin/plugin.json`, `skills/` 구조를 엄격히 준수한다.
스킬 파일(`SKILL.md`)은 가이드라인과 규칙을 명확하고 선언적으로 기술하되, 불필요한 구현 디테일(코드 블록, 설정 파일 예시 등)의 하드코딩을 배제한다.

### II. Multi-LLM Peer Fallback & Sandbox Safety (멀티 LLM 피어 폴백 및 샌드박스 안전성)
외부 LLM CLI 호출 전 `timeout 3 <cli> --version` 검사(Warm-up)를 수행하여 샌드박스 승인 락을 예방하고, 미충족 시 sentinel을 발동한다. [ADR-0033][ADR-0034]
CLI 인자 보간 시 쉘 주입을 방지하기 위해 stdin 파이프 또는 임시 파일을 이용한다. [ADR-0034]

### III. Verification-First & Test-First (TDD for Skills)
모든 핵심 기능 구현/수정 전에 테스트를 먼저 작성하는 TDD 사이클을 준수한다.
마크다운 기반 스킬(`SKILL.md`)을 수정하기 전에 `docs/evaluation/test-cases.md`에 평가 테스트 케이스를 먼저 작성하여 실패를 확인한 뒤 가이드라인을 수정한다.
스크립트 및 프로그램 코드(Python, Node.js 등) 작성 시에도 기능 구현 전에 단위 테스트 코드를 먼저 작성하고 실패함을 확인한다.

### IV. Git Workflow & Version Synchronization (Git 워크플로우 및 버전 동기화)
PR 제목 및 본문은 기술 용어/코드를 제외하고 한국어로 작성한다. 
PR 본문에 처리한 이슈를 `Closes #N`으로 연결하며, 이는 사용자 승인 후에만 삽입한다. [ADR-0038]
플러그인 버전 변경 시 루트 `README.md`, `.claude-plugin/marketplace.json`, 그리고 플러그인의 `plugin.json` 세 곳의 버전을 동시에 업데이트하여 동기화한다.

## Plugin-Specific Domain Standards (플러그인별 도메인 표준)

본 저장소가 제공/배포하는 각 플러그인 및 스킬의 도메인 행동 양식과 검증 기준은 다음과 같다.

### 1. Context & Plan Plugin Constraints (`context` & `workflow` 플러그인 제약)
- Task별 독립 컨텍스트는 `docs/context/{TASK_NAME}/` 아래 `spec.md`, `plan.md`, `tasks.md`, `context.md` 4개 파일로 관리한다.
- `TASK_NAME`은 kebab-case로 정규화하며, 특수문자와 traversal 경로를 제거하고 빈 문자열일 경우 즉시 차단한다. [ADR-0027]
- context 산출물과 workflow 산출물의 경로 경계를 혼용하지 않는다. [ADR-0027]
- 설계(spec/plan/tasks)는 코드 수정 전 계획 모드(ExitPlanMode 이전)에서 완료되어야 한다. [ADR-0030][ADR-0041]
- 설계 검증 게이트는 spec 사용자 리뷰(AskUserQuestion)와 plan GAN cross-check 2단계로 제한하며 self-review는 금지한다. [ADR-0030][ADR-0041]
- context/dev/guideline 스킬이 인자 없이 호출되어 의도를 유추할 때, 세션에서 유추 결과를 제시하고 AskUserQuestion으로 확인 후 진행한다. [ADR-0045]

### 2. API Guideline Review Standards (`guideline:restful-api` 리뷰 표준)
- 클라이언트 요청에 `Api-Version` 헤더가 없을 경우 `400 Bad Request`를 반환하도록 설계한다. [ADR-0009][ADR-0010]
- 모든 단일 리소스 접근(`/{resource}/{id}`) 시 백엔드에서 리소스 소유권 및 권한을 반드시 검증하도록 규정한다 (BOLA 방지). [ADR-0009][ADR-0010]
- `PATCH` 요청(`updateMask` 사용) 시 DTO에 허용 목록(Allowlist)을 적용하여 role 등 권한 필드 조작을 차단한다 (BOPA 방지). [ADR-0009][ADR-0010]
- `?expand=` 매개변수로 한 번에 가져올 수 있는 리소스 상한(최대 100개)을 강제하며 초과 시 `400 Bad Request`를 반환하도록 설계한다. [ADR-0009][ADR-0010]
- 부분 응답(`?fields=`) 반환 시 Strong ETag 대신 Weak ETag(`W/"..."`)를 사용하거나 생략하게 한다. [ADR-0009][ADR-0010]
- 모든 응답에 `X-Content-Type-Options: nosniff` 및 `Strict-Transport-Security` 보안 헤더를 포함한다. [ADR-0009][ADR-0010]

### 3. Git & LLM Fallback Execution (`git` & `llm` 피어 검증 제약)
- Peer cross-check는 호스트와 다른 외부 LLM(agy/gemini/codex)에 위임하며, 자기 자신에 대한 호출을 금지한다. [ADR-0022][ADR-0034]
- Peer 폴백 체인은 호스트를 제외한 풀에서 우선순위로 시도하고 sentinel(NOT_FOUND/TIMEOUT/ERROR) 감지 시 다음 peer로 이동한다. [ADR-0033][ADR-0034]
- 두 subagent 병렬 대기 시 `schedule`로 30초 타이머를 설정해 `manage_subagents` `list`를 폴링하되, 턴 종료 전 대기 메시지를 출력해 데드락을 방지한다. [ADR-0049]
- Git PR 리뷰의 Auto-fix 정책(Severity-gated Merge)을 따른다: critical/high는 자동 수정, medium/low는 Self/Peer 양측 합의 시만 자동 수정한다. [ADR-0040]

## Glossary & Domain Terms

- **Plugin**: `plugins/<name>/`의 독립 배포 단위. `.claude-plugin/plugin.json` + `skills/` + (선택) `hooks/`로 구성.
- **Skill**: `plugins/<name>/skills/<skill>/SKILL.md` 또는 글로벌 `~/.claude/skills/<skill>/SKILL.md`. 사용자가 `/<skill>` 또는 `/<plugin>:<skill>`로 호출.
- **Marketplace**: `.claude-plugin/marketplace.json`에 등재된 플러그인 카탈로그. 버전 동기화는 `plugin.json`, `marketplace.json`, 루트 `README.md` 세 곳 동시 갱신.
- **ADR**: `docs/adr/`에 기록하는 MADR 4.0 아키텍처 결정 기록. 번호는 immutable하며 번복 시 supersede 패턴 사용.
- **Sentinel**: CLI 부재, 타임아웃, 오류 발생 시의 상태 신호(NOT_FOUND/TIMEOUT/ERROR). 폴백 트리거.
- **Tracer Bullet**: 통합 레이어를 관통하는 vertical slice 단위의 독립적인 태스크/이슈 분해 단위.
- **Peer**: self-host가 아닌 외부 LLM CLI (agy/gemini/codex).

## Architecture Decision Records (ADR)

- 새로운 결정이 내려지면 `docs/adr/0000-template.md` (혹은 minimal)를 사용하여 ADR을 신규 작성한다.
- ADR은 결정의 역사적 근거(why)를 기록하고, 이로 인해 변경되는 구체적 가이드라인/제약사항은 본 헌법(Constitution)의 Core Principles에 동기화 반영하여 현행화한다.
- ADR 번호는 순차적으로 증가하며, 이전 결정을 대체할 때는 frontmatter의 `status`를 `superseded by ADR-NNNN`으로 변경한다.

## Governance

- 본 헌법은 저장소의 모든 규칙과 컨벤션에 대해 최상위 권위를 가진다.
- 헌법의 수정은 ADR 또는 명확한 합의 하에 버전 BUMP를 통해 이루어지며, 관련 템플릿(`.specify/templates/` 아래 plan/spec/tasks 등)과의 일관성을 유지해야 한다.
- 헌법 버전은 유의적 버전(Semantic Versioning)을 따른다:
  - MAJOR: 하위 호환되지 않는 규칙의 폐기 또는 아키텍처 대변혁.
  - MINOR: 신규 원칙 추가 또는 규칙의 실질적 확장.
  - PATCH: 자구 수정, 오타 교정, 비실질적 문구 개선.

**Version**: 2.0.0 | **Ratified**: 2026-06-09 | **Last Amended**: 2026-06-09

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->
