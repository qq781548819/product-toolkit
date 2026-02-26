---
name: recall
description: Recall project memory entries (insight/decision/vocabulary) with evidence/source/session context
---

# recall（统一记忆检索）

## 目标

检索 remember 产物，并返回可追溯上下文（来源会话 + 证据）。

## 检索方式

```bash
/product-toolkit:recall 用户
/product-toolkit:recall --insights
/product-toolkit:recall --decisions
/product-toolkit:recall --vocabulary
```

## 返回字段（建议）

- `memory_id`
- `type`
- `content/decision/term`
- `source_session_id`
- `source`
- `evidence_ref`
- `confidence`
- `updated_at`

## 用法建议

1. think 前先 recall：减少重复提问
2. prd 前先 recall decision：避免决策漂移
3. auto-test 后 recall test-learnings：复用修复策略
