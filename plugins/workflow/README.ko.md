# 워크플로우 스킬

> [English](README.md)

Planner-Executor 분리 + 멀티 LLM 크로스체크 워크플로우.
Claude(plan/execute) + Gemini(context/review).

## 스킬 목록

| 스킬 | 슬래시 커맨드 | 설명 |
|------|--------------|------|
| gemini-crosscheck | `/workflow:gemini-crosscheck` | 코딩 전 Gemini 멀티 LLM 크로스체크 — 컨텍스트 압축, 브레인스토밍, 계획 확정, 실행 |

## 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────────┐
│                    Gemini Crosscheck Pipeline                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐   .context-map.md   ┌───────────────────────┐ │
│  │ Gemini Flash │──────────────────>│ Claude (Brainstorm)   │ │
│  │ 1M context   │   ~4000 tokens     │ 2-3가지 접근 방식      │ │
│  │ $0.50/M in   │                    │ + Why NOT              │ │
│  └─────────────┘                     └───────────┬───────────┘ │
│        ▲                                         │              │
│        │ 소스 코드                       계획 초안 │              │
│        │ + git log                               ▼              │
│  ┌─────┴───────┐                     ┌───────────────────────┐ │
│  │  프로젝트    │                     │ Gemini Pro            │ │
│  │  코드베이스  │                     │ (Flash fallback 가능)  │ │
│  │             │                     │ 크로스체크             │ │
│  └─────────────┘                     │ + Pre-mortem          │ │
│                                      │ + 테스트 시나리오      │ │
│                                      └───────────┬───────────┘ │
│                                                   │              │
│                                          피드백    │              │
│                                                   ▼              │
│                                      ┌───────────────────────┐ │
│                                      │ Claude (Plan)         │ │
│                                      │ Tidy/Behavioral 분리  │ │
│                                      │ 전제 조건 + 대체 전략  │ │
│                                      └───────────┬───────────┘ │
│                                                   │              │
│                                       사용자 승인  │              │
│                                                   ▼              │
│                                      ┌───────────────────────┐ │
│                                      │ Claude (Execute)      │ │
│                                      │ Tidy First + TDD      │ │
│                                      │ Pre-read + Impact Scan│ │
│                                      └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 데이터 흐름

```
Step 1                Step 2              Step 3                    Step 4                Step 5
Gemini Flash          Claude              Gemini Pro/Flash          Claude                Claude
────────────          ──────              ─────────────────          ──────                ──────

소스 코드 ──>  .context-map.md ──> 계획 초안 ──> 피드백 ──> 최종 계획 ──> 코드
+ git log         (4000 tok)       (2-3 옵션)    + 테스트    + Tidy/Behav  + 테스트
                                   + Why NOT      + Pre-mort  + 전제 조건    + ADR
                                                  + 태그      + 3계층 테스트
                                                     │
                                                     ▼
                                               [사용자 게이트]
                                               승인 / 기각
                                                  │        │
                                                  ▼        ▼
                                               Step 5   Step 2
                                              (실행)    (재시도)
```

## 모델 라우팅

| 단계 | 모델 | 역할 | 입력 | 출력 | Fallback |
|------|------|------|------|------|----------|
| 1. 압축 | `gemini-3-flash-preview` | 컨텍스트 압축기 | 전체 코드베이스 + git log | `.context-map.md` (~4000 tok) | — |
| 2. 브레인스토밍 | Claude (Opus/Sonnet) | 계획자 | 컨텍스트 맵 + 작업 | 옵션 포함 계획 초안 | — |
| 3. 크로스체크 | `gemini-3.1-pro-preview` | 검토자/비평가 | 컨텍스트 맵 + 계획 초안 | 피드백 + 테스트 + Pre-mortem | Flash → Claude |
| 4. 계획 | Claude (Opus/Sonnet) | 의사결정자 | 피드백 + 계획 초안 | Tidy/Behavioral 분리된 최종 계획 (사용자 승인) | — |
| 5. 실행 | Claude (Sonnet) | 실행자 | 승인된 계획 + 소스 | 코드 + 테스트 + 커밋 | — |

## 비용 추정 (1회 사이클)

```
Gemini Flash (압축)              : ~100K input  = $0.05
Gemini Pro  (크로스체크)          : ~6K input    = $0.012
Gemini Flash (크로스체크 fallback): ~6K input    = $0.003  ← Pro 실패 시
Claude 컨텍스트 맵 읽기           : ~4K input    = $0.06
                                             합계: ~$0.12

vs. Opus가 소스 직접 읽을 때 : ~100K input = $1.50
                                  절감: ~93%
```

## Fallback 전략

```
전체 워크플로우 (Step 1-5) 정상 진행
         │
         │ Step 3 Cross-check
         ▼
gemini-3.1-pro-preview ──> 성공 ──> 계속
         │
      실패 (할당량/타임아웃)
         ▼
gemini-3-flash-preview ──> 성공 ──> "⚠️ Gemini Pro → Flash fallback" 알림 후 계속
         │
      실패
         ▼
Claude 자체 생성 ──> "⚠️ Gemini unavailable" 알림 + 테스트 시나리오 + Pre-mortem 자체 생성 후 계속

Gemini 전체 사용 불가 시:
     └── Step 1, 3 스킵
     └── Claude가 CLAUDE.md + 소스 직접 파악
     └── Execute에서 소스 직접 확인 강화
```

## 설치

```bash
claude plugin marketplace add https://github.com/ppzxc/engineering-guidelines.git
```
