---
name: develop
description: Use when implementing after /planning is complete and a plan file exists in docs/plans/ — /workflow:develop, "개발 시작", "구현 시작"
user-invocable: true
---

# Develop

`/workflow:planning`의 확정 플랜을 받아 격리된 worktree에서 TDD로 구현하고 브랜치를 마무리한다.

## 전제 조건

`/workflow:planning`이 출력한 `docs/plans/<slug>.md` 경로가 대화 컨텍스트에 있어야 한다.
시작 전 해당 파일을 Read하여 태스크 목록과 완료 기준을 파악하라.

## 실행 순서

### Step 1: 언어/프레임워크 감지 + 스킬 로드

프로젝트 루트에서 아래 파일 존재 여부를 확인하고, 매칭되는 스킬을 **모두 즉시** 로드하라.

| 감지 파일 | 로드할 스킬 |
|-----------|-------------|
| `build.gradle.kts` 또는 `pom.xml` | `java:coder`, `java:spring`, `java:tester` |
| `go.mod` | `golang:coder`, `golang:tester` |

매칭 없음 → 스킵. 로드된 스킬은 이후 모든 단계에 적용된다.

### Step 2: Worktree 생성

`superpowers:using-git-worktrees` 스킬을 호출하라.
이후 모든 작업은 생성된 worktree 경로에서 진행한다.

### Step 3: TDD 구현

`tdd` 스킬을 호출하라. 플랜 태스크를 아래 순서로 실행한다.

**Phase 1 — [TIDY] 태스크 (구조 변경)**
- `dev:tidy` 스킬 활성화
- 행동 변경 없음. `refactor:` 커밋 단위.
- 모든 [TIDY] 완료 후에만 Phase 2 진입.

**Phase 2 — [TDD] 태스크 (행동 변경)**
- RED → GREEN → REFACTOR 루프 엄수.
- 테스트 1개 → 구현 1개 → 반복 (수직 슬라이싱).
- `feat:` / `fix:` 커밋 단위.

각 태스크 완료 시 플랜 파일의 `- [ ]`를 `- [x]`로 업데이트하라.

### Step 4: 완료 검증

두 조건을 모두 충족해야 완료로 간주한다.

```bash
# 조건 1: 미완료 태스크 없음
grep -c '^\- \[ \]' docs/plans/<slug>.md   # 0이어야 함

# 조건 2: 전체 테스트 통과 (Step 1 감지 결과에 따라 적용)
# - build.gradle.kts 또는 pom.xml 감지 시: ./gradlew test
# - go.mod 감지 시: go test ./...
```

조건 미충족 시 Step 3으로 돌아간다. 이유를 사용자에게 보고한다.

두 조건 충족 시 출력:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
모든 태스크 완료 + 테스트 통과.

다음 단계: superpowers:finishing-a-development-branch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: 브랜치 마무리

`superpowers:finishing-a-development-branch` 스킬을 호출하라.
