# subagent 완료 대기 시 schedule + manage_subagents 폴링 루프 도입

* Status: accepted
* Date: 2026-06-08
* Decision Makers: ppzxc

## Context and Problem Statement

`git:review` 및 `llm:auto` 스킬에서 두 subagent(Self, Peer Coordinator)를 병렬 실행한 뒤 대기할 때, 기존의 "두 SUBAGENT 완료 대기 (동기 실행)" 지침은 구체적인 대기 방법론을 결여하고 있었다. 이로 인해 에이전트가 유휴 상태로 들어간 뒤 백그라운드 완료 이벤트가 유실되거나 UI 갱신이 멈춰, 사용자가 수동으로 interaction(예: ESC 키 입력)하기 전까지 대기 상태에 갇혀 있는 현상이 발생했다.

## Decision Outcome

Chosen option: "`schedule` 툴을 이용한 1회성 타이머 알림 설정 + `manage_subagents` `list` 툴을 활용한 능동적 폴링 지침 구체화", because 메인 에이전트가 턴을 완전히 종료하고 notification을 마냥 기다리는 대신, 주기적인 타이머 트리거로 강제 wakeup을 유도하고 `manage_subagents` `list`를 통해 직접 subagent 상태를 비교 검증함으로써 UI 대기 데드락 현상을 원천 차단할 수 있다.

범위는 병렬 subagent 완료를 대기하는 `git:review`와 `llm:auto` 스킬에 적용하며, 규칙에도 반영한다.
