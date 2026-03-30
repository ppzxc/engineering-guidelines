# 플러그인 스킬 성능 평가 시스템 구조

## Status

accepted

## Context and Problem Statement

git, docs 플러그인 스킬의 성능을 체계적으로 검증할 방법이 없다. api 플러그인에는 이미 독립 평가 시스템(test-cases.md + coverage-map.md + report.md)이 있으나, git/docs 스킬은 워크플로우 기반이라 api의 Writing/Review 모드 커버리지 기준이 맞지 않는다. Safety Rules 준수와 워크플로우 단계 정확도를 검증할 수 있는 별도 평가 체계가 필요하다.

## Decision Drivers

* api 평가 시스템 변경 없이 독립적으로 운영
* 워크플로우 스킬 특성 반영 — Safety + Workflow 두 축 평가
* 플러그인별 독립 발전 가능
* 파일 구조 컨벤션을 api와 통일

## Considered Options

* Option A: 플러그인별 독립 평가 시스템
* Option B: 공통 평가 템플릿 + 플러그인별 인스턴스
* Option C: 평가 전용 스킬 추가

## Decision Outcome

Chosen option: **Option A (플러그인별 독립 평가 시스템)**, because 현재 플러그인 수(2개)에서 템플릿 추상화는 불필요하고, api와 동일한 파일 구조를 따르면 일관성이 충분히 확보되기 때문이다.

### Consequences

* Good: 플러그인 독립적, 각자 발전 가능
* Good: api 패턴 준수로 구조 일관성 확보
* Bad: 스킬마다 테스트케이스 직접 작성 필요

## Pros and Cons of the Options

### Option A: 플러그인별 독립 평가 시스템

* Good: 단순하고 자명한 구조
* Good: api 기존 패턴과 일치
* Good: 플러그인 간 독립적 진화 가능
* Bad: 공통 로직 중복 (커버율 계산 공식 등)

### Option B: 공통 평가 템플릿 + 플러그인별 인스턴스

* Good: DRY — 공통 구조 중복 없음
* Bad: 현재 플러그인 수에서 오버엔지니어링
* Bad: 템플릿-인스턴스 동기화 부담

### Option C: 평가 전용 스킬 추가

* Good: 자동화 가능성
* Bad: 워크플로우 스킬은 수동 검토가 더 정확
* Bad: 범위 대비 복잡도 과잉
