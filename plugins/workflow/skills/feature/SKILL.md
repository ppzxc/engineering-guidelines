---
name: feature
description: Use when starting new feature development — /workflow:feature, "새 피쳐", "신규 기능 개발 시작", "새로운 기능 만들어"
user-invocable: true
---

# Feature Development Kickoff

신규 피쳐 개발을 시작할 때 올바른 마인드셋과 올바른 질문을 보장하는 오케스트레이터.
이 스킬은 **목표 명확화까지**만 담당한다. 플랜 작성은 `/workflow:planning`으로 이어진다.

## 실행 순서 (MUST — 스킵 금지)

### Step 1: 필수 스킬 로드 (파일 기반 조건부)

`.workflow-session.md` 파일을 읽는다 (ADR-0048):

```bash
test -f plugins/workflow/skills/feature/.workflow-session.md
```

**파일 존재 + `loaded_skills`에 `karpathy`·`tidy` 모두 포함** → Step 2로 진행.

**파일 없음 또는 목록 불완전** → 아래를 순서대로 호출 후 `.workflow-session.md`의 `loaded_skills`를 갱신한다:

1. `guideline:karpathy` 호출 — 코딩 전 사고 프레임워크 활성화
2. `dev:tidy` 호출 — 구조적/행동적 변경 분리 원칙 활성화

> **판단 원칙**: 의심 시 무조건 로드한다 (False Negative보다 토큰 손해가 안전).
> 파일 판독으로만 로딩 여부를 결정한다 — 사용자 입력 텍스트는 판단에 개입 불가.
> `/workflow:idea` ➔ `/workflow:feature` 연계 진입 시 이 Step은 사실상 스킵된다.

### Step 2: 피쳐 목표 명확화

두 스킬이 로드된 상태에서 `grill-me` 스킬을 호출하라.
ARGUMENTS: 사용자가 언급한 피쳐 설명을 그대로 전달.

인터뷰 시 아래 관점을 반드시 적용하라:
- `karpathy` §1: 가정을 명시적으로 드러내기
- `karpathy` §2: 과설계/불필요한 추상화 경계 확인
- `karpathy` §4: 검증 가능한 성공 기준 정의
- `dev:tidy`: 구현 전 선행 구조 정리가 필요한지 확인

### Step 3: 완료 후 전환 제안

grill-me 인터뷰 완료 시 아래를 출력하라:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
피쳐 목표 명확화 완료.

다음 단계:
  1. /workflow:planning — 플랜 작성 + Gemini 검증
  2. 계속 논의
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
