# Git 플러그인 규칙

git 플러그인 스킬을 사용하거나 수정할 때 반드시 다음 제약을 따른다.

✓ 다른 스킬을 디스패치할 때 스킬명을 추론으로 구성하지 말고 마켓플레이스에 실제 등록된 정확한 이름(`<plugin>:<skill>`)을 SKILL.md에 명시할 것
✓ 언어별 reviewer 매핑은 결정적 테이블로 관리하고, 등재되지 않은 언어는 general review criteria로 fallback할 것
✓ `.java` 파일 변경 시 항상 `java:reviewer`를 로드하고, PR diff에 Spring 어노테이션(@RestController/@Service/@Component/@Repository/@Controller/@Configuration) 또는 `import org.springframework.`가 보이면 `java:spring`을 추가 로드할 것
✓ `.go` 파일 변경 시 `golang:reviewer`를 로드할 것
✓ PR 제목과 본문은 한글로 작성할 것 (기술 용어·코드·커맨드 제외)
✓ `git:review`의 peer cross-review는 자기 호스트와 다른 LLM에게 위임할 것. 자기 자신에게 cross-check를 보내는 호출 금지 [ADR-0022]
