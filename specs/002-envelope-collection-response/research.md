# Research: JSON HAL (HATEOAS) for API Collection Responses

## Decision

기존의 Top-level JSON Array 강제 정책을 폐지하고, **IANA 표준인 JSON HAL (`application/hal+json`) 포맷을 객체 봉투(Envelope)의 표준 구조로 채택**한다.

## Rationale

1. **표준 및 HATEOAS 지향성**: JSON HAL(Hypertext Application Language)은 IANA에 정식 등록된 표준 규격(draft-kelly-json-hal-11)으로, REST 아키텍처의 최종 단계인 HATEOAS(Hypermedia As The Engine Of Application State)를 깔끔하게 충족시킵니다.
2. **보안성 (JSON Hijacking 예방)**: 최상위 응답을 JSON Array `[]` 대신 객체 `{}` 형식으로 래핑함으로써 모던 웹 브라우저의 JSON Hijacking 취약점을 원천적으로 예방합니다.
3. **뛰어난 확장성**: HAL 규격은 최상위에 `_links`(네비게이션 링크)와 `_embedded`(실제 데이터 목록) 필드를 사용하면서도, `totalCount`와 같은 커스텀 메타데이터 필드를 최상위 객체에 직접 확장하여 기재할 수 있도록 명세를 열어두고 있습니다.

## Alternatives Considered

- **커스텀 봉투 패턴 (`{"items": [], "totalCount": N}`)**: 임의로 필드명을 정하는 커스텀 Envelope 방식도 가능하나, 표준 지향적이지 않으며 HATEOAS 하이퍼미디어 링크 표준(예: RFC 8288 Link 헤더 대체)을 정형화하기 어려워 기각되었습니다.
- **Top-level JSON Array 단독 반환 유지**: JSON Hijacking 취약점이 있고 HTTP 커스텀 헤더(`Total-Count`, `Link` 등)에 무조건 의존해야 하므로 확장성 및 프런트엔드 연동성이 떨어져 기각되었습니다.
