---
name: work
description: Alias for workflow; run the complete strict workflow with feedback injection
---

# Work（workflow 别名）

当用户使用 `/product-toolkit:work` 时，按 `/product-toolkit:workflow` 执行。

执行语义与 `skills/workflow/SKILL.md` 保持一致：

- `think → user-story → prd → test-case → auto-test → feedback → next-think`
- strict 默认阻断
- 反馈产物优先注入下一轮
