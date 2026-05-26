# Antigravity CLI (agy) - Claude 스킬 플러그인 Import 가이드라인

본 가이드라인은 Claude 마켓플레이스 표준 규격(숨겨진 `.claude-plugin/` 구조 또는 단독 `SKILL.md` 구조)으로 작성된 스킬 폴더를 Antigravity CLI 환경에서 `agy plugin install` 명령어로 정상 설치하기 위한 가이드입니다.

---

## 🔍 문제 원인
* **Claude 규격:** 매니페스트(`plugin.json`)가 숨김 디렉터리(`.claude-plugin/plugin.json`) 내부에 위치하거나, 단독 스킬의 경우 매니페스트가 아예 없습니다.
* **Antigravity 규격:** 플러그인 루트 디렉터리(`./plugin.json`)에서 매니페스트를 인식합니다.

따라서 변환 작업 없이 `agy plugin install <경로>`를 수행하면 매니페스트 누락 에러가 발생합니다.

---

## 🛠️ 해결 프로세스 요약

플러그인의 형태에 따라 아래의 **Case A** 또는 **Case B** 방법을 적용하여 구조를 맞춘 후 `agy plugin install .` 명령을 실행합니다.

### 💡 Case A: `.claude-plugin/` 폴더가 존재하는 경우 (마켓플레이스 표준 포맷)
Claude 공식 마켓플레이스 패키지 형태라면 숨겨진 매니페스트 파일을 루트로 꺼내주어야 합니다.

```bash
# 1. 대상 Claude 플러그인 폴더로 이동
cd /path/to/your-claude-plugin

# 2. 숨겨진 매니페스트를 루트로 복사
cp .claude-plugin/plugin.json ./

# 3. 루트에 매니페스트가 존재하므로 현재 폴더(.) 기준으로 바로 설치
agy plugin install .
```
