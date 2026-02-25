---
name: test-case
description: Use when user wants to generate QA test cases from think vNext/user-story/prd outputs with strict Pass/Fail/Blocked semantics
---

# 测试用例（think vNext Hard Switch）

从 `think vNext` + `user-story` + `prd` 生成可执行 QA 测试包。

## 使用方式

```bash
/product-toolkit:test-case [功能]
```

例如：`/product-toolkit:test-case 登录功能`

---

## 输入契约与前置 Gate

### Gate 0：输入完整性

必须具备：

- think vNext 标准信封（见 `../../references/user-story-mapping.md`）
- 用户故事（含 7 维 AC）
- PRD（含范围、风险、回滚）

必填字段缺失 ⇒ `Blocked`。

### Gate 1：冲突与未决判定（Block vs Warn）

- `critical/high` 未解决冲突 ⇒ `Blocked`
- `open_question.blocking=true` 未关闭 ⇒ `Blocked`
- `medium/low` 未解决冲突 ⇒ `Warn`（继续执行并保留风险）

### Gate 2：AC→TC 映射完整性

- 阻塞级 AC 必须有对应 TC
- 目标覆盖率：100%
- 不满足时：`Blocked`

---

## 多平台可视化 Gate（可视化功能强制）

### A. Web

1. 使用 `agent-browser` 或 `browser-use`。
2. 从登录页开始（账号/权限映射仅由用户提供）。
3. 关键步骤截图，核验数据绑定与布局。
4. Console 无阻断级未处理错误。
5. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

### B. mobile-app

1. 模拟器或真机关键路径测试（登录→核心功能→退出）。
2. 留存关键截图/录屏。
3. 崩溃/错误日志无阻断级错误。
4. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

### C. mini-program

1. 开发者工具或真机关键路径测试。
2. 留存截图并核验数据绑定与布局。
3. console/请求日志无阻断级错误。
4. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

任一强制项缺失或失败：`Blocked`（不可交付）。

---

## 字段级映射（think vNext → 测试类型）

| think 字段 | 测试用例类型 |
|---|---|
| `requirements.happy_path` | 功能测试 / 冒烟测试 |
| `requirements.edge_cases` | 边界值测试 |
| `requirements.failure_modes` | 异常场景测试 |
| `requirements.success_signals` | UI/提示/可视化验证 |
| `requirements.performance_targets` | 性能测试 |
| `requirements.permissions` | 权限测试 |
| `requirements.rollback_policy` | 逆向流程测试 |
| `conflicts[]` / `open_questions[]` | Blocked 原因或 Warn 风险 |

---

## 统一状态语义

- `Pass`：已执行，且所有阻塞级要求满足。
- `Fail`：已执行，但至少一项验证不满足。
- `Blocked`：前置信息不足或阻塞项未闭环，无法形成可交付结论。

> `Warn` 仅作为风险标签附加在 `Pass/Fail` 上，不替代主状态。

---

## 输出模板（最小）

```markdown
# 测试用例: {featureName}

**状态**: Draft/Reviewed/Approved
**执行结论**: Pass/Fail/Blocked

## 前置 Gate 结论
- Gate0 输入完整性: Pass/Blocked
- Gate1 冲突未决判定: Pass/Blocked (+Warn)
- Gate2 AC→TC 映射: Pass/Blocked

## 用例分类
- 冒烟测试
- 功能测试
- 边界测试
- 异常测试
- UI/可视化测试
- 性能测试
- 权限测试
- 逆向流程测试
- 回归测试

## AC→TC 覆盖矩阵
| AC-ID | TC-ID | 覆盖状态 | 备注 |
|---|---|---|---|

## 风险与未决
- 冲突: {conflicts}
- 未决问题: {open_questions}
- Warn: {warnings}
```

---

## 输出目录

默认模式（单命令调用）:

```text
docs/product/test-cases/{feature}.md
```

工作流模式（`/product-toolkit:workflow`）:

```text
docs/product/{version}/qa/test-cases/{feature}.md
```

## 参考

- `../../references/acceptance-criteria.md`
- `../../references/user-story-mapping.md`
