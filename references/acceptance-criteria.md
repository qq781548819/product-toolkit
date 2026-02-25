# 验收标准模板库（think vNext Hard Switch）

## 1. 使用前提

本模板仅适用于 `think vNext` 输出，遵循：

- `references/user-story-mapping.md`（字段级映射契约）
- Rule-first（仅规则，不含行为引擎实现）
- Hard switch（不再使用旧版固定题号映射）

---

## 2. 七维基础验收标准（必选）

每个用户故事必须覆盖以下 7 维：

1. 正向流程（Happy Path）
2. 边界校验（Edge Cases）
3. 错误处理（Failure Modes）
4. 成功反馈（Success Signals）
5. 性能要求（Performance Targets）
6. 权限控制（Permissions）
7. 撤销/回退（Rollback Policy）

---

## 3. AC 编写契约（统一字段）

每条 AC 建议使用以下结构：

| 字段 | 说明 |
|---|---|
| `ac_id` | 唯一编号（如 `AC-001`） |
| `dimension` | 七维之一 |
| `statement` | 验收描述 |
| `source_field` | 来源字段（如 `requirements.happy_path`） |
| `priority` | `P0/P1/P2` |
| `blocking` | 是否阻塞交付（`true/false`） |
| `linked_tc` | 关联测试用例 ID |
| `status` | `covered/failed/blocked` |

---

## 4. think vNext → AC → TC 映射表

| think vNext 字段 | AC 维度 | QA 用例类型 |
|---|---|---|
| `requirements.happy_path` | 正向流程 | 功能测试 / 冒烟测试 |
| `requirements.edge_cases` | 边界校验 | 边界值测试 |
| `requirements.failure_modes` | 错误处理 | 异常场景测试 |
| `requirements.success_signals` | 成功反馈 | UI/提示/可视化校验 |
| `requirements.performance_targets` | 性能要求 | 性能测试 |
| `requirements.permissions` | 权限控制 | 权限测试 |
| `requirements.rollback_policy` | 撤销/回退 | 逆向流程测试 |

---

## 5. Block / Warn / Fail 统一语义

| 情况 | 结果 | 说明 |
|---|---|---|
| 高严重度冲突未解决（critical/high） | `Blocked` | 不可宣告交付完成 |
| `open_questions.blocking=true` 未关闭 | `Blocked` | 不可宣告交付完成 |
| 必填字段缺失 | `Blocked` | 禁止推断补齐 |
| 中低严重度冲突未解决 | `Warn` | 可继续，但必须写入风险 |
| 测试已执行但结果不满足 AC | `Fail` | 仅用于“已执行且失败”的测试结论 |

> 约束：`Warn` 是风险标签，不替代最终主状态（`Pass/Blocked`）。

---

## 6. 多平台可视化测试 Gate（如适用）

### Web

1. 使用 `agent-browser` 或 `browser-use`。
2. 从登录页进入（账号由用户提供）。
3. 留存关键截图，核验数据绑定与布局。
4. Console 无阻断级未处理错误。
5. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

### mobile-app

1. 模拟器或真机执行关键路径。
2. 留存截图/录屏证据。
3. 无阻断级 crash/log 错误。
4. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

### mini-program

1. 开发者工具或真机执行关键路径。
2. 留存截图，核验数据绑定与布局。
3. console/请求日志无阻断级错误。
4. 关键 API 成功标准：`HTTP 2xx` 且（若定义）业务成功码通过。

---

## 7. AC→TC 覆盖矩阵（必填）

每个交付必须附 AC→TC 映射矩阵，并满足：

- 所有阻塞级 AC 必须 `Covered`
- 总体覆盖率目标 100%
- 未覆盖项必须给出 `Blocked` 原因与关闭条件

模板：

```markdown
| AC-ID | 验收标准 | TC-ID | 覆盖状态 | 备注 |
|------|---------|-------|---------|------|
| AC-001 | ... | TC-001 | Covered | - |
| AC-002 | ... | TC-004 | Blocked | 缺少账号权限映射 |
```

---

## 8. 快速最小模板

```markdown
## 验收标准
- [ ] AC-001 正向流程: ...
- [ ] AC-002 边界校验: ...
- [ ] AC-003 错误处理: ...
- [ ] AC-004 成功反馈: ...
- [ ] AC-005 性能要求: ...
- [ ] AC-006 权限控制: ...
- [ ] AC-007 撤销/回退: ...

## 冲突与未决项
- 冲突: C-xxx（severity=...，status=...）
- 未决: OQ-xxx（blocking=true/false，closure_criteria=...）

## 交付结论
- 状态: Pass / Blocked
- 风险: Warn 列表（如有）
```
