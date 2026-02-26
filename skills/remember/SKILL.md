---
name: remember
description: Remember project insights/decisions/vocabulary with unified memory envelope metadata
---

# remember（统一记忆信封）

## 目标

写入跨会话可追溯记忆：insight / decision / vocabulary。

## 统一字段（v3.4.0）

每条记忆应兼容以下元数据：

- `memory_id`
- `type`
- `source_session_id`
- `source`
- `evidence_ref`
- `confidence`
- `tags`
- `created_at`
- `updated_at`

## 用法

```bash
/product-toolkit:remember --insight "核心用户是Z世代"
/product-toolkit:remember --decision "采用PostgreSQL" --source "architecture-review"
/product-toolkit:remember --vocabulary "SKU: Stock Keeping Unit"
```

## 证据语义

- `source_session_id`: 来源会话（如 think/auto-test session id）
- `source`: 人类可读来源（如 think-vnext、manual-review）
- `evidence_ref`: 证据链接/文件路径（可字符串或数组）

## 存储位置

```text
.ptk/memory/project-insights.json
.ptk/memory/decisions.json
.ptk/memory/vocabulary.json
```
