# 苏格拉底式产品思考 vNext（规则先行硬切换）

> 本文档是 `/product-toolkit:think` 的**唯一规则源**（Single Source of Truth）。
> 范围仅覆盖规则与契约，不包含行为引擎实现细节。

## 范围与原则

- **Hard Switch**：旧版固定题号问卷（Q1-Q24）不再作为执行规范。
- **Rule-first**：先统一问答规则、冲突规则、收敛规则，再联动下游。
- **可审计**：每轮必须有摘要；未决问题必须入账（ledger）。
- **可衔接**：最终输出必须同时提供 Markdown + 结构化块（YAML）。

---

## 1) think vNext canonical rule spec

### 1.1 会话生命周期

1. **初始化**：重述问题、确认目标、识别初始风险
2. **轮次推进**：按批量问答 + 动态追问推进澄清
3. **轮次总结**：输出 round summary + 更新 open-questions ledger
4. **收敛判定**：满足收敛条件则结束，否则进入下一轮
5. **最终交付**：输出 Markdown 总结 + YAML 结构化块

### 1.2 批量问答策略（Batch Policy）

| 规则项 | 约束 |
|---|---|
| 每轮问题数 | 3-5 |
| 动态追问深度（单未决点） | ≤ 2 层 |
| 单会话总问题数 | ≤ 20 |
| 每轮必须产物 | round summary + ledger 更新 |
| 结束前强制检查 | mandatory 字段、冲突状态、阻塞项 |

### 1.3 动态追问触发器

以下触发器命中任意一项，必须追加追问：

1. **信息缺失（Missing Mandatory）**
   - mandatory 字段为空、模糊或不可判定
2. **上下文冲突（Conflict）**
   - 与历史回答在目标/边界/约束上矛盾
3. **高风险未证实（High-risk Unverified）**
   - 关键假设无证据、无验证路径
4. **闭环缺口（Closure Gap）**
   - 角色、权限、频次、异常、回滚未形成闭环

### 1.4 mandatory 字段清单

以下字段缺失时，不得静默推断：

- 目标用户/角色
- 要解决的问题与业务目标
- 成功判定标准（至少一条可验证标准）
- 核心边界（权限/限制/异常路径）

如必须暂时假设，需同时满足：
- 显式标记为 `hypothesis`
- 写入 `open_questions`
- 指定 `close_criteria`

### 1.5 收敛停止条件（Convergence Stop Conditions）

会话仅在以下条件满足时标记 `converged`：

- mandatory 字段全部已确认，或已登记为可追踪 hypothesis
- 无 `critical/high` 且未解决冲突
- 无 `blocking=true` 且 `status=open` 的未决问题
- 用户确认可结束

若触达总问题上限（20）仍未满足上述条件：
- 输出 `forced_stop`
- 将未闭环项全部写入 ledger
- 给出明确 `Blocked/Warn` 建议

---

## 2) Conflict taxonomy + severity + action matrix

### 2.1 冲突分类（Taxonomy）

| 分类 | 定义 | 示例 |
|---|---|---|
| semantic | 同一概念被给出互斥语义 | “实时返回” vs “离线批处理” |
| boundary | 角色/权限/范围/限制互斥 | “游客可用” vs “必须登录” |
| goal | 目标方向互相冲突 | “最大化转化” vs “最小化打扰” |
| constraint | 资源/合规/技术约束冲突 | “本周上线” vs “依赖下月交付” |

### 2.2 严重度定义（Severity）

| 严重度 | 判定信号 |
|---|---|
| critical | 影响核心业务正确性或合规，继续推进会导致错误决策 |
| high | 影响核心范围或验收边界，不解决会造成返工 |
| medium | 影响方案质量，但可在受控风险下继续 |
| low | 局部不一致，不影响主链路推进 |

### 2.3 动作矩阵（Action Matrix）

| 严重度 | 动作 | ledger 标记 | 下游语义 |
|---|---|---|---|
| critical | 立即追问；未解即停 | `blocking=true` | `Blocked` |
| high | 本轮优先追问；未解不放行 | `blocking=true` | `Blocked` |
| medium | 下一轮定向追问 | `blocking=false` + risk | `Warn` 可继续 |
| low | 记录观察，必要时补问 | `blocking=false` | 可继续 |

---

## 3) Per-round auto-summary template

### 3.1 Markdown 模板

```markdown
## Round {n} Summary
### Confirmed Facts
- ...

### Assumptions (Hypotheses)
- ...

### Conflicts Detected
- [C-xxx][severity][category] ...

### Open Questions Ledger Updates
- Added: OQ-xxx ...
- Updated: OQ-xxx ...
- Closed: OQ-xxx ...

### Next Round Goal
- ...
```

### 3.2 结构化模板（YAML）

```yaml
think_vnext_round_summary:
  round: 1
  questions_asked: 4
  confirmed_facts: []
  assumptions: []
  conflicts:
    - id: C-001
      category: boundary
      severity: high
      statement_a: "游客可用"
      statement_b: "必须登录"
      status: open
  open_questions:
    - id: OQ-001
      title: "游客是否允许发起操作"
      severity: high
      blocking: true
      status: open
      source_round: 1
      next_action: "下一轮先确认权限策略"
  next_round_goal: []
```

---

## 4) Open Questions Ledger 规范

### 4.1 字段 Schema

| 字段 | 说明 |
|---|---|
| id | 稳定 ID（如 OQ-001） |
| title | 未决问题标题 |
| category | scope/dependency/policy/data/ux 等 |
| severity | critical/high/medium/low |
| source_round | 首次出现轮次 |
| status | open/in_progress/resolved/deferred |
| blocking | 是否阻塞下游 |
| owner | 责任角色（可空） |
| next_action | 下一步动作 |
| close_criteria | 关闭标准（必须可验证） |

### 4.2 去重规则

满足以下条件视为同一未决项并合并：
- `title` 语义一致（规范化后）
- `category` 相同
- 影响对象相同（同一角色/流程/边界）

### 4.3 生命周期规则

- 新增：首次出现即 `open`
- 升级：严重度上升时保留同一 `id` 更新 `severity`
- 关闭：满足 `close_criteria` 后改为 `resolved`
- 延后：需外部依赖时标记 `deferred` 并附恢复条件

---

## 5) 最终输出契约（下游统一输入）

最终输出必须同时包含：

1. **Markdown 总结**（给人读）
2. **YAML 结构块**（给下游技能稳定解析）

```yaml
think_vnext_output:
  session:
    rounds: 0
    total_questions: 0
    convergence: converged|forced_stop
  confirmed_facts: []
  assumptions:
    - content: "..."
      confidence: low|medium|high
  conflicts:
    - id: C-001
      category: semantic|boundary|goal|constraint
      severity: critical|high|medium|low
      status: open|resolved
      blocking: true|false
  open_questions:
    - id: OQ-001
      title: "..."
      severity: high
      status: open
      blocking: true
      close_criteria: "..."
  downstream_handoff:
    user_story_inputs: []
    prd_inputs: []
    test_case_inputs: []
    workflow_gates: []
```

---

## 6) 下游放行语义（供映射阶段引用）

- **Blocked**：存在 `critical/high` 未解冲突，或存在 `blocking=true` 且 `open` 的未决项
- **Warn**：仅剩 `medium/low` 风险项，允许继续但必须显式继承风险
- **Pass**：无阻塞项，且 mandatory 字段已闭环

