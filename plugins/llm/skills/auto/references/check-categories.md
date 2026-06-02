# Cross-check 카테고리 정의

`llm:auto` 입력 분류 후 타입별 필수/선택 카테고리를 이 문서에서 결정한다.

severity H/M/L alias: → [`severity-taxonomy.md`](../../../../_shared/references/severity-taxonomy.md) — H=high, M=medium, L=low.

---

## 카테고리 태그

| Tag | 의미 | 설명 |
|-----|------|------|
| `consistency` | 일관성 | 단계 간 모순, 전제↔결론 불일치, 용어 혼용 |
| `omission` | 누락 | 누락된 단계, 예외 처리, 롤백 경로, 전제조건 |
| `ordering` | 순서 | 의존성 위반 순서 (B가 A보다 먼저 와야 하는데 뒤에 옴) |
| `feasibility` | 실현 가능성 | 제안된 API/라이브러리 실재 여부, 권한·환경 제약 |
| `risk` | 위험 | 부수효과, 동시성, 데이터 손실, 보안 취약점 |
| `fact-check` | 사실 검증 | 함수·API 실재 여부, 인용 정확성, 환경 가정 |
| `trade-off` | 트레이드오프 | 옵션별 장단점, 포기한 대안 폐기 사유 |
| `doc-sync` | 문서 동기화 | 코드↔문서 불일치, 영향받는 파일 누락, ADR↔rules 태그 |
| `version-compat` | 버전 호환 | 라이브러리/런타임 버전 호환성 |

---

## 입력 타입별 카테고리 매트릭스

| 타입 | 필수 태그 | 선택 태그 | 출력 섹션 |
|------|----------|----------|----------|
| **plan** | consistency / omission / ordering / feasibility / risk | fact-check / version-compat | Cross-check + Test Scenarios + Pre-mortem |
| **spec** | consistency / trade-off / doc-sync | fact-check / version-compat | Cross-check + Trade-off Analysis + Doc-sync Check |
| **idea** | trade-off / fact-check / pre-mortem | consistency | Cross-check + Trade-off Analysis + Pre-mortem |
| **diff** | (처리 없음 — git:review로 redirect) | — | — |

---

## 출력 섹션 정의

### Test Scenarios (plan 전용)

```
## Test Scenarios
1. [정상 케이스] 설명 및 검증 방법
2. [경계 케이스] 설명 및 검증 방법 (off-by-one, empty, max 등)
3. [실패 케이스] 설명 및 검증 방법 (timeout, perm denied, network 등)
```

### Pre-mortem (plan / idea)

```
## Pre-mortem
1. [가장 빠른 실패 시나리오] 구체적 트리거 조건
2. [데이터·상태 손실 시나리오] 구체적 상황
3. [외부 의존성 실패 시나리오] API/CLI/서비스 장애
```

### Trade-off Analysis (spec / idea)

```
## Trade-off Analysis
| Option | Pros | Cons |
|--------|------|------|
| [옵션 A] | ... | ... |
| [옵션 B] | ... | ... |

Recommendation: [선택 이유 1-2문장]
Rejected: [포기한 옵션 폐기 사유]
```

### Doc-sync Check (spec 전용)

```
## Doc-sync Check
| File | Status | Note |
|------|--------|------|
| [영향받는 파일] | outdated/in-sync/missing | 구체적 불일치 설명 |
```
