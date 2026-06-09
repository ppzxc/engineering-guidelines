<!--
Sync Impact Report:
- Version change: v3.0.0 -> v3.1.0
- Modified principles:
  - Principle II -> Generalized from LLM-specific peer fallback rules to general "Secure Command Execution & Sandbox Safety" guidelines.
- Added sections: None
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

### II. Secure Command Execution & Sandbox Safety (안전한 명령어 실행 및 샌드박스 안전성)
스크립트나 훅에서 외부 CLI 명령어 및 서브프로세스를 기동할 때 다음 보안 및 안전 수칙을 준수한다.
- 동적 데이터나 외부 입력값을 쉘 명령어 인자에 직접 보간(Interpolation)하는 것을 금지하며, 쉘 주입(Shell Injection) 취약점을 차단하기 위해 매개변수 배열 전달, stdin 파이프, 또는 안전한 임시 파일을 사용한다.
- 샌드박스 환경에서 구동되는 외부 CLI 호출 시 사용자 승인 프롬프트 락(Prompt Lock)으로 인한 전체 프로세스 데드락을 방지하도록, 백그라운드 호출 전 사전에 동기식 버전 체크(`--version`) 등을 수행하여 승인 여부를 사전에 확보(Warm-up)한다.

### III. Verification-First & Test-First (TDD for Skills)
모든 핵심 기능 구현/수정 전에 테스트를 먼저 작성하는 TDD 사이클을 준수한다.
마크다운 기반 스킬(`SKILL.md`)을 수정하기 전에 `docs/evaluation/test-cases.md`에 평가 테스트 케이스를 먼저 작성하여 실패를 확인한 뒤 가이드라인을 수정한다.
스크립트 및 프로그램 코드(Python, Node.js 등) 작성 시에도 기능 구현 전에 단위 테스트 코드를 먼저 작성하고 실패함을 확인한다.

### IV. Git Workflow & Version Synchronization (Git 워크플로우 및 버전 동기화)
PR 제목 및 본문은 기술 용어/코드를 제외하고 한국어로 작성한다. 
PR 본문에 처리한 이슈를 `Closes #N`으로 연결하며, 이는 사용자 승인 후에만 삽입한다. [ADR-0038]
플러그인 버전 변경 시 루트 `README.md`, `.claude-plugin/marketplace.json`, 그리고 플러그인의 `plugin.json` 세 곳의 버전을 동시에 업데이트하여 동기화한다.

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
- ADR 번호는 순차적으로 증가하며, 이전 결정을 대체할 때는 frontmatter of `status`를 `superseded by ADR-NNNN`으로 변경한다.

## Governance

- 본 헌법은 저장소의 모든 규칙과 컨벤션에 대해 최상위 권위를 가진다.
- 헌법의 수정은 ADR 또는 명확한 합의 하에 버전 BUMP를 통해 이루어지며, 관련 템플릿(`.specify/templates/` 아래 plan/spec/tasks 등)과의 일관성을 유지해야 한다.
- 헌법 버전은 유의적 버전(Semantic Versioning)을 따른다:
  - MAJOR: 하위 호환되지 않는 규칙의 폐기 또는 아키텍처 대변혁.
  - MINOR: 신규 원칙 추가 또는 규칙의 실질적 확장.
  - PATCH: 자구 수정, 오타 교정, 비실질적 문구 개선.

**Version**: 3.1.0 | **Ratified**: 2026-06-09 | **Last Amended**: 2026-06-09
