# Git 플러그인 규칙

git 플러그인 스킬을 사용하거나 수정할 때 반드시 다음 제약을 따른다.

✓ 다른 스킬을 디스패치할 때 스킬명을 추론으로 구성하지 말고 마켓플레이스에 실제 등록된 정확한 이름(`<plugin>:<skill>`)을 SKILL.md에 명시할 것
✓ 언어별 reviewer 매핑은 결정적 테이블로 관리하고, 등재되지 않은 언어는 general review criteria로 fallback할 것
✓ `.java` 파일 변경 시 항상 `java:reviewer`를 로드하고, PR diff에 Spring 어노테이션(@RestController/@Service/@Component/@Repository/@Controller/@Configuration) 또는 `import org.springframework.`가 보이면 `java:spring`을 추가 로드할 것
✓ `.go` 파일 변경 시 `golang:reviewer`를 로드할 것
✓ PR 제목과 본문은 한글로 작성할 것 (기술 용어·코드·커맨드 제외)
✓ git:review의 peer crosscheck는 자기 호스트와 다른 LLM에게 위임할 것. 자기 자신에게 cross-check를 보내는 호출 금지 [ADR-0022][ADR-0033]
✓ git:clean entry에서 별도 peer crosscheck를 추가하지 말 것 (post-work pipeline이므로 plan 검토 대상 없음) [ADR-0035]
✓ git:review의 cross-review는 Self/Peer 두 SUBAGENT 병렬 dispatch로 수행할 것 (Claude Code host) [ADR-0033]
✓ peer 폴백 체인은 자기 호스트를 제외한 풀에서 우선순위대로 시도하고 모든 sentinel(NOT_FOUND/TIMEOUT/ERROR)에서 다음 peer로 이동할 것 [ADR-0033]
✓ Auto-fix는 severity-gated hybrid(high/critical=union, medium/low=intersection)로 적용할 것 [ADR-0033]
✓ Self-Review SUBAGENT는 언어별 스킬 대신 pr-review-toolkit:code-reviewer (opus)를 단독 사용할 것 [ADR-0036]
✓ Self-Review SUBAGENT prompt에 gh pr diff 결과를 직접 주입할 것 (checkout 불필요) [ADR-0036]
