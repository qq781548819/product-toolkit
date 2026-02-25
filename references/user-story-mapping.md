# think vNext → Downstream Mapping Contract（Hard Switch）

## 1) 适用范围与硬切换声明

本契约是 `think vNext` 到以下下游技能的唯一映射来源：

- `user-story`
- `prd`
- `test-case`
- `workflow`

硬切换要求：

1. 不再使用旧版固定题号映射（例如 `Q1~Q24`）。
2. 不保留旧版兼容分支描述。
3. 仅做规则契约，不做行为引擎实现。

---

## 2) think vNext 标准输入信封（Canonical Input Envelope）

下游技能必须接收 **Markdown 叙述 + 结构化契约块**（二者都要）。

### 2.1 必填字段

| 字段 | 说明 |
|---|---|
| `meta.feature_name` | 功能名/需求主题 |
| `meta.objective` | 业务目标 |
| `meta.platforms` | 平台集合（web/mobile-app/mini-program/...） |
| `convergence.state` | `converged` / `needs_followup` |
| `requirements.actor` | 角色 |
| `requirements.value` | 用户价值 |
| `requirements.in_scope` | 范围内能力 |
| `requirements.out_of_scope` | 范围外能力 |
| `requirements.preconditions` | 前置条件 |
| `requirements.permissions` | 权限要求 |
| `requirements.happy_path` | 正向流程 |
| `requirements.edge_cases` | 边界场景 |
| `requirements.failure_modes` | 异常/失败场景 |
| `requirements.success_signals` | 成功反馈 |
| `requirements.performance_targets` | 性能目标 |
| `requirements.rollback_policy` | 撤销/回退策略 |
| `conflicts[]` | 冲突清单（含严重度、状态） |
| `open_questions[]` | 未决问题清单（含阻塞标记） |

### 2.2 结构化块示例

```yaml
think_vnext:
  meta:
    feature_name: 收藏商品
    objective: 提升复访与转化
    platforms: [web, mini-program]
  convergence:
    state: converged
    rationale: "核心路径已收敛，剩余低风险开放项"
  requirements:
    actor: "已登录用户"
    value: "快速找回感兴趣商品"
    in_scope: ["收藏", "取消收藏", "收藏列表查看"]
    out_of_scope: ["收藏分组", "跨端同步策略重构"]
    preconditions: ["用户已登录", "商品可售"]
    permissions: ["普通用户可操作"]
    happy_path: ["进入详情页", "点击收藏", "状态更新+提示"]
    edge_cases: ["重复收藏", "上限控制", "商品下架"]
    failure_modes: ["网络超时", "服务异常", "权限不足"]
    success_signals: ["按钮态变化", "toast", "收藏数更新"]
    performance_targets: ["操作响应<1s"]
    rollback_policy: "可撤销，5秒内即时回退"
  conflicts:
    - id: C-001
      type: boundary
      severity: medium
      status: unresolved
      blocking: false
      description: "收藏上限是99还是100"
  open_questions:
    - id: OQ-001
      question: "上限值最终是多少？"
      reason: "影响边界测试"
      source_round: 3
      priority: P1
      blocking: false
      status: open
      closure_criteria: "产品确认并同步验收标准"
      owner: PM
```

---

## 3) 字段级映射（think vNext → 4 个下游）

| think vNext 字段 | user-story | prd | test-case | workflow |
|---|---|---|---|---|
| `meta.feature_name` | 标题/故事编号 | 文档标题/范围 | 测试包标题 | 版本目录与产物索引 |
| `meta.objective` | 价值描述 | 背景与目标/KPI | 测试目标 | 工作流目标摘要 |
| `meta.platforms` | 平台适配备注 | 非功能与兼容性 | 平台测试 Gate 选择 | 子流程编排与 Gate 路径 |
| `requirements.actor` | 作为谁（Actor） | 用户分析 | 角色测试矩阵 | 角色依赖检查 |
| `requirements.value` | 以便（Value） | 业务价值 | 验收目标来源 | 完成语义基线 |
| `requirements.in_scope` | 故事范围 | 功能范围 | 覆盖范围 | 必要产物清单 |
| `requirements.out_of_scope` | 非目标说明 | 非目标约束 | 非测试范围 | 防止流程扩张 |
| `requirements.preconditions` | 前置条件 | 业务前提/依赖 | 前置条件 | 执行前置 Gate |
| `requirements.permissions` | 权限验收条目 | 权限需求 | 权限测试集 | 权限阻塞检查 |
| `requirements.happy_path` | 正向验收标准 | 主流程 | 功能/冒烟用例 | 主链路完成判定 |
| `requirements.edge_cases` | 边界验收标准 | 边界规则 | 边界用例 | 风险补测触发 |
| `requirements.failure_modes` | 错误处理标准 | 异常处理需求 | 异常用例 | 异常处置门槛 |
| `requirements.success_signals` | 成功反馈标准 | UI/反馈要求 | UI验证用例 | 交付证据要求 |
| `requirements.performance_targets` | 性能验收标准 | 性能/NFR | 性能用例 | 性能 Gate |
| `requirements.rollback_policy` | 撤销验收标准 | 回滚方案 | 逆向流程用例 | 失败后回退策略 |
| `conflicts[]` | 风险/冲突章节 | 风险登记簿 | 阻塞或警告来源 | Pass/Blocked 判定输入 |
| `open_questions[]` | 未决项章节 | 决策待办章节 | Blocked 原因/风险备注 | 完成 Gate 判定输入 |
| `convergence.state` | Story Ready 判定 | PRD Ready 判定 | 可执行性判定 | 工作流最终状态 |

---

## 4) 冲突与未决问题处理规则（Block vs Warn）

### 4.1 决策矩阵

| 条件 | 动作 | 下游状态 |
|---|---|---|
| `severity in [critical, high]` 且未解决 | 阻塞 | `Blocked` |
| `open_question.blocking = true` 且未关闭 | 阻塞 | `Blocked` |
| 必填字段缺失 | 阻塞 | `Blocked` |
| `severity = medium` 未解决 | 风险提示并继续 | `Warn` |
| `severity = low` 未解决 | 风险提示并继续 | `Warn` |

### 4.2 推断规则

- 必填字段缺失时：**禁止模型自行推断补齐**，必须保留为 `open_questions`。
- 非必填字段缺失时：可临时假设，但必须写入 `assumptions + risks`。

---

## 5) Open Questions Ledger Schema（统一字段）

每条未决问题至少包含：

| 字段 | 说明 |
|---|---|
| `id` | 全局唯一 ID（建议 `OQ-###`） |
| `question` | 问题本体 |
| `reason` | 产生原因 |
| `source_round` | 来源轮次 |
| `priority` | `P0/P1/P2` |
| `blocking` | `true/false` |
| `status` | `open/triaged/resolved/closed` |
| `closure_criteria` | 关闭标准 |
| `owner` | 责任角色 |
| `linked_artifacts` | 受影响产物（US/PRD/TC/WF） |

生命周期规则：

1. 新问题先去重（同 question + same scope）。
2. 被确认影响交付时升级 `blocking=true`。
3. 满足 `closure_criteria` 后改为 `resolved`，确认落文后 `closed`。

---

## 6) Workflow 完成语义（统一）

- `Pass`：无阻塞冲突/未决项，必填字段齐全，所需产物齐全。
- `Blocked`：存在阻塞项或缺少必填信息。
- `Warn`：仅用于风险提示标签，不是最终完成状态。

> 说明：`Warn` 可以附着在 `Pass` 结果中（如 “Pass with warnings”），但不能替代 `Pass/Blocked` 主判定。
