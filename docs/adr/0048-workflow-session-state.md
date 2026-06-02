# workflow:feature 스킬 로딩 감지 — 파일 기반 structured state

* Status: accepted
* Date: 2026-06-03
* Decision Makers: ppzxc

## Context and Problem Statement

`workflow:feature` Step 1은 `STEP1-LOADED:` 문자열을 대화 이력에서 탐색하여 스킬 로딩 여부를 판단한다. 이 방식은 사용자 입력 텍스트가 마커 문자열을 포함할 경우 false-positive 위험이 있고, 세션 경계를 넘을 경우 신뢰할 수 없다. 로딩 상태를 파일로 저장하면 string match 취약점을 제거하고 상태를 명시적·검증 가능하게 관리할 수 있다.

## Decision Outcome

Chosen option: "`.workflow-session.md` frontmatter YAML structured read", because 파일 존재 여부로 로딩 상태를 판단하면 사용자 입력이 로딩 판단에 개입할 수 없고, YAML frontmatter가 포맷 문서화와 상태 저장을 동시에 달성한다. 범위는 feature 스킬만 (idea/init 동일 패턴은 후속 이슈).
