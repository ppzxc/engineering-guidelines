# API 설계 및 리뷰 규칙

API 설계 문서를 작성하거나 코드 리뷰를 수행할 때 반드시 다음 제약을 확인한다.

✓ 클라이언트 요청에 `Api-Version` 헤더가 없는 경우 무조건 `400 Bad Request` 에러를 반환할 것 (최신 버전 자동 할당 금지) [T1] [ADR-0009] [ADR-0010]
✓ 모든 단일 리소스 접근(`/{resource}/{id}`) 시, 백엔드는 요청자가 해당 리소스 소유자이거나 접근 권한이 있는지 반드시 검증할 것 (BOLA 방지) [T1] [ADR-0009] [ADR-0010]
✓ `PATCH` 요청(`updateMask`) 시, 서버 DTO 계층에 명시적인 허용 목록(Allowlist)을 구현하여 권한 상승 필드(role 등) 조작을 차단할 것 (BOPA 방지) [T1] [ADR-0009] [ADR-0010]
✓ `?expand=` 파라미터 지원 시, 한 번의 요청에 반환되는 확장 엔티티의 총 개수 상한선(예: 100개)을 강제하고 초과 시 `400 Bad Request`를 반환할 것 [T1] [ADR-0009] [ADR-0010]
✓ 부분 응답(`?fields=`)을 반환할 때는 전체 리소스의 Strong ETag 대신 Weak ETag(`W/"..."`)를 반환하거나 생략할 것 [T1] [ADR-0009] [ADR-0010]
✓ 모든 API 응답에 `X-Content-Type-Options: nosniff` 및 `Strict-Transport-Security` 헤더를 반드시 포함할 것 [T1] [ADR-0009] [ADR-0010]
