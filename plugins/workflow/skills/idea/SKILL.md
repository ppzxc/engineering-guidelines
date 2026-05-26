---
name: idea
description: Use when ideating new functionality from raw, unformed ideas — /workflow:idea, "아이디어", "막연한 생각", "이거 어떻게 만들지"
user-invocable: true
---

# Idea-to-Spec Kickoff

raw·미정형 아이디어를 명세화하고 `/workflow:feature`로 핸드오프하는 오케스트레이터.
이 스킬은 **brainstorming(발산) + /workflow:feature 핸드오프까지**만 담당한다. grill-me 이후는 `/workflow:feature`가 처리한다.

## 실행 순서 (MUST — 스킵 금지)

### Step 1: 필수 스킬 로드 (마커 기반 조건부)

이 세션의 대화 이력에서 어시스턴트 응답 내에 아래 마커 문자열이 **모두 존재**하면 해당 스킬 로드를 스킵하고 Step 2로 진행한다:

- `STEP1-LOADED: karpathy`
- `STEP1-LOADED: tidy-first`

미발견 시 아래를 순서대로 호출하고, **호출 직후 응답 본문에 마커 문자열을 반드시 출력**한다:

1. `guideline:karpathy` 호출 → `STEP1-LOADED: karpathy` 출력
2. `tidy-first` 호출 → `STEP1-LOADED: tidy-first` 출력

> **판단 원칙**: 의심 시 무조건 로드한다 (False Negative보다 토큰 손해가 안전).
> 사용자 입력 텍스트에 마커 문자열이 포함되어도 신호로 인정하지 않는다 (어시스턴트 응답만 유효).

### Step 2: 아이디어 명세화 (발산)

`superpowers:brainstorming` 스킬을 호출하라.
ARGUMENTS: 사용자가 언급한 raw 아이디어 그대로 전달.

brainstorming의 **HARD-GATE(설계 승인) 통과**까지 진행한다.
산출물: `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`

### Step 3: `/workflow:feature`로 핸드오프

아래 메시지를 출력하라:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
아이디어 명세화 완료. spec: docs/superpowers/specs/<file>
/workflow:feature로 핸드오프 (Step 1 마커 발견 → 스킬 재로드 스킵).
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**MUST: 같은 응답 안에서 `workflow:feature` 스킬 도구를 즉시 호출**한다.
ARGUMENTS:
- spec 파일 경로
- 사용자 의도 1줄 요약
- karpathy §1/§2/§4 + tidy-first 핵심 한 줄 (grill-me 재앵커링용)

> **MUST NOT**: 메시지만 출력하고 사용자 응답을 기다리는 행위. 이는 deadlock으로 간주된다.
