---
name: user-story
description: Use when user wants to generate user stories from think vNext output - provides structured user story with acceptance criteria and blocking semantics
---

# 用户故事（think vNext Hard Switch）

基于 `think vNext` 输出生成结构化用户故事，统一接入冲突/未决问题判定。

## 使用方式

```bash
/product-toolkit:user-story [功能]
```

例如：`/product-toolkit:user-story 电商收藏功能`

---

## 输入契约（必须）

仅接受 `think vNext` 标准输入信封（Markdown + 结构化契约块）。

- 契约来源：`../../references/user-story-mapping.md`
- 验收标准来源：`../../references/acceptance-criteria.md`

### 最小检查清单

| 检查项 | 要求 |
|---|---|
| 角色/价值 | `requirements.actor` + `requirements.value` 必填 |
| 范围 | `in_scope/out_of_scope` 必填 |
| 验收七维来源 | happy/edge/failure/success/performance/permissions/rollback 齐全 |
| 冲突清单 | `conflicts[]` 存在（可为空） |
| 未决清单 | `open_questions[]` 存在（可为空） |

> 必填缺失：禁止推断补齐，直接输出 `Blocked`。

---

## 字段级映射（think vNext → user-story）

| think 字段 | 用户故事落位 |
|---|---|
| `meta.feature_name` | 标题、Story ID、范围说明 |
| `requirements.actor` | “作为...” Actor |
| `requirements.value` | “以便...” Value |
| `requirements.in_scope` | 概述 + In Scope |
| `requirements.out_of_scope` | Out of Scope |
| `requirements.preconditions` | 前置条件 |
| `requirements.permissions` | 权限控制验收标准 |
| `requirements.happy_path` | 正向流程验收标准 |
| `requirements.edge_cases` | 边界验收标准 |
| `requirements.failure_modes` | 错误处理验收标准 |
| `requirements.success_signals` | 成功反馈验收标准 |
| `requirements.performance_targets` | 性能验收标准 |
| `requirements.rollback_policy` | 撤销/回退验收标准 |
| `conflicts[]` | 风险与冲突章节 |
| `open_questions[]` | 未决问题章节 |

---

## 冲突与未决问题规则（Block vs Warn）

- `critical/high` 未解决冲突 ⇒ `Blocked`
- `open_question.blocking=true` 且未关闭 ⇒ `Blocked`
- `medium/low` 未解决冲突 ⇒ `Warn`（可继续）
- `Warn` 必须写入风险章节，不可静默丢弃

---

## 输出模板

```markdown
### US-{id}: {featureName}

**状态**: Ready / Blocked
**优先级**: P0/P1/P2
**来源**: think_vnext

**用户故事**: 作为 [{actor}]，我希望 [{capability}]，以便 [{value}]。

## 范围
- In Scope: {in_scope}
- Out of Scope: {out_of_scope}

## 前置条件
- {preconditions}

## 验收标准（7维）
- [ ] AC-001 正向流程: {happy_path}
- [ ] AC-002 边界校验: {edge_cases}
- [ ] AC-003 错误处理: {failure_modes}
- [ ] AC-004 成功反馈: {success_signals}
- [ ] AC-005 性能要求: {performance_targets}
- [ ] AC-006 权限控制: {permissions}
- [ ] AC-007 撤销/回退: {rollback_policy}

## 冲突与未决问题
- 冲突: {conflicts}
- 未决: {open_questions}

## 交付语义
- Blocked 原因: {blocking_items_or_none}
- Warn 风险: {warning_items_or_none}

## 可追踪映射
| think 字段 | 本文档位置 |
|---|---|
| requirements.actor | 用户故事主句 |
| requirements.happy_path | AC-001 |
| ... | ... |
```

---

## 完成语义

- `Ready`：无阻塞冲突/未决项，必填字段齐全。
- `Blocked`：存在阻塞项或必填信息缺失。

---

## 输出目录

默认模式（单命令调用）:

```text
docs/product/user-stories/{feature}.md
```

工作流模式（`/product-toolkit:workflow`）:

```text
docs/product/{version}/user-story/{feature}.md
```
