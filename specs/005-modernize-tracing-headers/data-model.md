# Data Model & Schema Specification: Tracing Headers

분산 추적 헤더에 사용되는 데이터 엔티티, 속성 규격 및 유효성 검증 규칙을 정의합니다.

---

## 1. W3C `traceparent` Header

`traceparent` 헤더는 분산 트레이스의 식별 정보와 제어 플래그를 나타내며, 하이픈(`-`)으로 구분된 4개의 필드로 구성됩니다.

### 포맷 규칙 (Format)
*   **구조**: `version-trace_id-parent_id-trace_flags`
*   **예시**: `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01`
*   **전체 길이**: 55자 고정 문자열
*   **인코딩**: 소문자 16진수(Hexadecimal) 문자열 및 하이픈

### 속성 상세 (Attributes)

| 필드명 | 설명 | 데이터 타입 | 유효성 검증 규칙 |
| :--- | :--- | :--- | :--- |
| **version** | Trace Context 명세 버전 | 2 hex chars | - 현재 규격은 `00` 고정.<br>- 향후 버전 호환성 판단의 기준. |
| **trace_id** | 전체 분산 트레이스 고유 식별자 | 32 hex chars | - `00000000000000000000000000000000` (all-zeros)은 허용되지 않음 (유효성 실패). |
| **parent_id** | 호출한 상위 Span(구간)의 고유 식별자 | 16 hex chars | - `0000000000000000` (all-zeros)은 허용되지 않음 (유효성 실패). |
| **trace_flags** | 트레이스 수집 제어 옵션 (예: 샘플링 여부) | 2 hex chars | - 8비트 비트맵 구조.<br>- `01`: Sampled (데이터 수집 대상)<br>- `00`: Not Sampled (수집 제외) |

---

## 2. W3C `tracestate` Header

`tracestate` 헤더는 벤더별 특정 모니터링 메타데이터를 시스템 간에 전파하기 위해 사용합니다.

### 포맷 규칙 (Format)
*   **구조**: 쉼표(`,`)로 구분된 `key=value` 목록
*   **예시**: `rojo=1,congo=2`
*   **전체 길이**: 최대 512자 제한
*   **키 규칙**: 소문자 알파벳과 숫자로만 구성된 식별자 (최대 256자)

### 속성 상세 (Attributes)
*   최대 32개의 `key=value` 쌍을 포함할 수 있습니다.
*   자체적으로 파싱이 실패하더라도 시스템의 가용성에 영향을 미치지 않고 조용히 무시되어야 합니다.

---

## 3. Legacy `Request-Id` Header

하위 호환성 및 과도기 마이그레이션을 보장하기 위해 병행 전파하는 기존의 커스텀 요청 식별 헤더입니다.

### 포맷 규칙 (Format)
*   **구조**: UUID v4 포맷 (하이픈 포함 36자)
*   **예시**: `9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d`
*   **인코딩**: ASCII 문자열 (대소문자 구분 없음)

### 관계 및 매핑 규칙 (Mapping)
*   동일한 분산 트레이스 내에서 `Request-Id`는 `traceparent`의 `trace_id`와 개념적으로 1:1 대응해야 합니다.
*   다만 하이픈 제거 및 패딩 처리 방식 등에 대한 복잡성을 최소화하기 위해 다음 규칙을 권장합니다:
    *   **신규 Trace 생성 시**: `trace_id`를 새로 발급하고, 이 값의 하이픈 포맷팅 등을 가공하지 않고 독립적인 UUID v4 형태로 `Request-Id`도 새로 발급하여 동시에 전달합니다.
