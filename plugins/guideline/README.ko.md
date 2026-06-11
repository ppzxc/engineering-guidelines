# Guideline 플러그인

**Guideline** 플러그인은 소프트웨어 개발 및 아키텍처 설계를 위한 핵심 엔지니어링 표준 지침들을 하나로 모은 통합 플러그인입니다.

## 제공되는 스킬

### 1. `restful-api` (`/guideline:restful-api`)
* **설명**: 글로벌 표준 수준의 RESTful API 설계 규칙들을 정리한 고품질 개발 규격입니다. URL 구조, HTTP 메서드, 응답 상태 코드, 표준 헤더 규격 및 BOLA/BOPA 등 보안 모범 사례를 포괄합니다.
* **사용 목적**: 웹 API 인터페이스를 설계하거나, 새로운 컨트롤러 엔드포인트를 구현하거나, 기존 백엔드 설계에 대한 아키텍처 피어 리뷰를 수행할 때 사용합니다.
* **단축어**: "REST API 설계", "REST API 리뷰", "API 가이드라인"

---

## 설치 및 설정

별도의 수동 설치가 필요 없습니다. 본 프로젝트의 `.claude-plugin/marketplace.json`을 통해 플러그인이 자동으로 활성화됩니다.

```bash
# 터미널 또는 CLI 환경에서 스킬 호출 예시
/guideline:restful-api
```
