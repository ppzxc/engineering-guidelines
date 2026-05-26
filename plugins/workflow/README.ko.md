# Workflow 플러그인

**Workflow** 플러그인은 `gatekeeper` 프로젝트로부터 이관된 고강도 소프트웨어 엔지니어링 및 개발 프로세스 오케스트레이션 스킬 모음입니다.

## 포함된 스킬

### 1. `init` (`/workflow:init`)
* **설명**: 신규 작업(피처 구현, 버그 수정 등)을 시작할 때 필수 개발 기율(Karpathy, Tidy First, TDD)을 로드하고 격리된 Git Worktree를 생성하여 안전한 개발 환경을 제공합니다.
* **단축어**: "새 기능 구현", "버그 수정", "새로운 작업 시작"

### 2. `idea` (`/workflow:idea`)
* **설명**: 아직 구체화되지 않은 raw 아이디어를 명세화하고, 피처 핸드오프 단계로 도달할 수 있도록 돕는 브레인스토밍 도구입니다.
* **단축어**: "아이디어", "막연한 생각", "이거 어떻게 만들지"

### 3. `feature` (`/workflow:feature`)
* **설명**: 명세화된 목표를 기반으로 피처 개발 범위를 구체화하며, 엄격한 질의응답 세션을 통해 목표를 정밀화합니다.
* **단축어**: "새 피쳐", "신규 기능 개발 시작", "새로운 기능 만들어"

### 4. `planning` (`/workflow:planning`)
* **설명**: 확정된 목표에 맞춰 단계별 상세 구현 플랜(`implementation_plan.md`)을 수립하고, AI 교차 검증을 수행합니다.
* **단축어**: "플랜 작성", "계획 수립", "플랜 짜자"

### 5. `develop` (`/workflow:develop`)
* **설명**: 확정된 구현 계획에 따라 격리된 환경 내에서 안전하게 Red-Green-Refactor TDD 개발 사이클을 기계적으로 반복 구현합니다.
* **단축어**: "개발 시작", "구현 시작"

---

## 설치 및 호출

본 프로젝트의 `.claude-plugin/marketplace.json`을 통해 플러그인이 자동으로 탑재됩니다.

```bash
# 터미널 또는 CLI 환경에서의 호출 예시
/workflow:init
/workflow:idea
/workflow:feature
/workflow:planning
/workflow:develop
```
