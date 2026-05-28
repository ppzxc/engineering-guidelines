# Triage Labels

matt pocock 스킬의 canonical triage 5종과 본 저장소 실제 라벨의 매핑.

| mattpocock/skills canonical | 본 저장소 라벨 | 의미 |
|-----------------------------|----------------|------|
| `needs-triage` | `needs-triage` | Maintainer 평가 대기 |
| `needs-info` | `needs-info` | Reporter 추가 정보 대기 |
| `ready-for-agent` | `ready` | AFK agent 즉시 투입 가능 (fully specified) |
| `ready-for-human` | `ready-for-human` | 사람 구현 필요 |
| `wontfix` | `wontfix` | 대응하지 않음 |

## 주의

`ready-for-agent` canonical은 기존 이슈 호환성을 위해 `ready` alias로 유지된다 (ADR-0037).
스킬이 "AFK-ready 라벨 적용"을 언급할 때 `ready` 라벨을 사용한다.

## 기타 라벨

`refactor`, `architecture`, `chore`, `bug`, `enhancement`, `priority:*` 등 유형/우선순위 라벨은 triage 라벨과 독립적으로 사용한다.
