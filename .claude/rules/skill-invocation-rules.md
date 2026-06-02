# 스킬 호출 규칙

스킬 no-arg 동작을 사용하거나 수정할 때 반드시 다음 제약을 따른다.

✓ context/dev/guideline 스킬은 인자 없이 호출되어 의도를 유추할 때, interactive 세션에서 유추 결과를 보여주고 AskUserQuestion으로 확인받은 뒤 진행할 것 (자동실행 금지, 유추 로직·non-interactive 동작은 유지) [ADR-0045]
✓ verbatim 로드 전용 스킬(인자·유추·실행 없음)은 ADR-0045 게이트 비해당으로 간주할 것 [ADR-0045]
