---
name: prd
description: Use when user wants to generate a Product Requirements Document from think vNext output with explicit conflict/open-question handling
---

# PRD（think vNext Hard Switch）

基于 `think vNext` 契约产出可评审 PRD，强制落文风险、冲突、未决问题。

## 使用方式

```bash
/product-toolkit:prd [功能或模块]
```

例如：`/product-toolkit:prd 用户登录模块`

---

## 输入契约（必须）

- 输入必须符合 `../../references/user-story-mapping.md` 的标准信封
- 验收字段必须符合 `../../references/acceptance-criteria.md`
- 不再使用旧版固定题号映射

### 入门校验

| 校验项 | 要求 |
|---|---|
| 目标与范围 | `meta.objective` + `in_scope/out_of_scope` 完整 |
| 主流程与异常 | `happy_path` + `failure_modes` 完整 |
| 性能/权限/回退 | `performance_targets` + `permissions` + `rollback_policy` 完整 |
| 冲突与未决 | `conflicts[]`、`open_questions[]` 存在 |

> 必填字段缺失或阻塞项未关闭：PRD 状态必须为 `Blocked`。

---

## 字段级映射（think vNext → PRD）

| think 字段 | PRD 章节 |
|---|---|
| `meta.feature_name` | 标题、范围 |
| `meta.objective` | 背景、目标、成功指标 |
| `requirements.actor` | 目标用户 |
| `requirements.value` | 价值阐述 |
| `requirements.in_scope/out_of_scope` | 功能范围/非目标 |
| `requirements.preconditions` | 依赖与约束 |
| `requirements.happy_path` | 主业务流程 |
| `requirements.edge_cases` | 边界规则 |
| `requirements.failure_modes` | 异常处理 |
| `requirements.success_signals` | UI/反馈要求 |
| `requirements.performance_targets` | 性能与可用性 |
| `requirements.permissions` | 安全与权限 |
| `requirements.rollback_policy` | 发布与回滚 |
| `conflicts[]` | 风险登记簿 |
| `open_questions[]` | 决策待办与阻塞清单 |

---

## 冲突与未决问题规则

- `critical/high` 未解决冲突 ⇒ `Blocked`
- `open_question.blocking=true` 且未关闭 ⇒ `Blocked`
- `medium/low` 未解决冲突 ⇒ `Warn`，可继续但必须保留风险与 owner
- 禁止对必填项进行模型推断补齐

---

## PRD 输出模板（最小）

```markdown
# PRD: {featureName}

**状态**: Draft / In Review / Ready / Blocked
**来源**: think_vnext

## 1. 背景与目标
- 背景: {objective_context}
- 目标: {objective}
- 成功指标: {kpi}

## 2. 用户与价值
- 目标用户: {actor}
- 用户价值: {value}

## 3. 范围定义
- In Scope: {in_scope}
- Out of Scope: {out_of_scope}

## 4. 功能需求
- 主流程: {happy_path}
- 边界规则: {edge_cases}
- 异常处理: {failure_modes}
- 成功反馈: {success_signals}

## 5. 非功能需求
- 性能: {performance_targets}
- 权限/安全: {permissions}

## 6. 发布与回滚
- 回滚策略: {rollback_policy}

## 7. 风险与未决问题
- 冲突: {conflicts}
- 未决问题: {open_questions}

## 8. 交付判定
- Blocked 原因: {blocking_items_or_none}
- Warn 风险: {warning_items_or_none}
```

---

## 输出目录

默认模式（单命令调用）:

```text
docs/product/prd/{feature}.md
```

工作流模式（`/product-toolkit:workflow`）:

```text
docs/product/{version}/prd/{feature}.md
```
