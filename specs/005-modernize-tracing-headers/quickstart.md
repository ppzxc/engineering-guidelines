# Quickstart Validation Guide: Tracing Headers

이 가이드는 분산 추적 헤더 현대화 규격이 개별 프레임워크 및 시스템에 정상적으로 적용되었는지 종단 간(End-to-End) 검증할 수 있는 시나리오와 절차를 안내합니다.

상세 헤더 규격 및 데이터 정의는 다음 문서를 참고하십시오:
*   [Data Model](file:///home/ppzxc/projects/engineering-guidelines/specs/005-modernize-tracing-headers/data-model.md)
*   [Header Contracts](file:///home/ppzxc/projects/engineering-guidelines/specs/005-modernize-tracing-headers/contracts/trace-headers.json)

---

## 1. Prerequisites (사전 요건)

*   `curl` 또는 API 테스트 클라이언트 (Postman 등)
*   로그 파일 조회가 가능한 터미널 권한
*   분산 로깅 규격이 반영된 검증 대상 어플리케이션 구동 환경

---

## 2. Validation Scenarios (검증 시나리오)

### 시나리오 1: 표준적인 신규 트레이스 시작 (최초 진입)
외부로부터 추적 헤더가 없이 최초 요청이 유입되었을 때, API Gateway 등에서 헤더를 올바르게 발급하는지 검증합니다.

1.  **실행 명령어 (Run Command)**:
    ```bash
    curl -i -X GET http://localhost:8080/api/v1/resources
    ```
2.  **기대되는 결과 (Expected Outcome)**:
    *   **HTTP 응답 헤더**:
        *   `traceparent`가 새로 생성되어 포함되어야 함 (예: `00-{32자리 랜덤 hex}-{16자리 랜덤 hex}-01`).
        *   `Request-Id`가 UUID v4 형식으로 새로 생성되어 포함되어야 함.
    *   **애플리케이션 로그**:
        *   발급된 `traceparent`의 `trace_id`와 `Request-Id`가 동일한 요청 내에 로깅 연관 필드로 기록되어야 함.

---

### 시나리오 2: 하위 호환성 전파 검증
업스트림에서 신구 헤더를 함께 수신했을 때, 이를 변경 없이 다운스트림 서비스로 동시 전파(Dual Propagation)하는지 검증합니다.

1.  **실행 명령어 (Run Command)**:
    ```bash
    curl -i -X GET http://localhost:8080/api/v1/resources \
      -H "traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01" \
      -H "Request-Id: 9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d"
    ```
2.  **기대되는 결과 (Expected Outcome)**:
    *   **내부 서비스 간 호출 및 응답**:
        *   수신된 `trace_id`(`4bf92f3577b34da6a3ce929d0e0e4736`)와 `Request-Id`(`9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d`)를 다운스트림 서비스로의 내부 호출 헤더에 그대로 유지하여 전송해야 함.

---

### 시나리오 3: 유효하지 않은 헤더 유입 시 폴백 처리
잘못된 포맷의 `traceparent`가 들어왔을 때 요청이 거부되지 않고, 새로운 헤더를 발급하여 처리하며 경고 로그를 기록하는지 검증합니다.

1.  **실행 명령어 (Run Command)**:
    ```bash
    # trace_id가 all-zeros인 유효하지 않은 헤더 전송
    curl -i -X GET http://localhost:8080/api/v1/resources \
      -H "traceparent: 00-00000000000000000000000000000000-00f067aa0ba902b7-01"
    ```
2.  **기대되는 결과 (Expected Outcome)**:
    *   **응답 상태**: HTTP `200 OK` (요청 거부 없이 가용한 비즈니스 결과 반환).
    *   **HTTP 응답 헤더**:
        *   기존의 잘못된 `traceparent`를 버리고, 새로 발급된 정상적인 `traceparent`가 전송되어야 함.
    *   **애플리케이션 로그**:
        *   시스템 경고 로그에 `Invalid traceparent header received. Restarting trace.` 문구가 기록되어야 함.
