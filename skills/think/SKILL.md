---
name: think
description: Use when user needs vNext product thinking with batch Q&A, dynamic follow-up, conflict detection, per-round auto-summary, and open-question ledger output
---

# 产品思考（think vNext）

> **Hard Switch**：本技能已切换到 vNext 规则；旧版固定 `Q1-Q24` 题库不再作为执行规范。

## 使用方式

```bash
/product-toolkit:think [功能或问题描述]
```

例如：`/product-toolkit:think 我想做社区点赞功能`

---

## 1) think vNext canonical rule spec

### 1.1 批量问答策略（Batch Policy）
- 每轮问题数：`3-5` 题
- 动态追问深度上限：`2` 层（针对同一未决点）
- 单会话总问题上限：`20` 题
- 每轮必须输出自动摘要并更新未决问题清单

### 1.2 动态追问触发器（Dynamic Follow-up Triggers）
出现以下任一情况，必须触发追问：
1. **信息缺失**：mandatory 字段未回答或回答不可判定
2. **上下文冲突**：本轮答案与前文答案在目标/边界/约束上冲突
3. **高风险未证实**：关键假设缺乏证据支持
4. **边界不闭环**：角色、权限、频次、异常路径、回滚路径不完整

### 1.3 收敛停止条件（Convergence Stop Conditions）
满足以下条件可结束会话：
- mandatory 字段已闭环，或已显式登记为 `hypothesis + open question`
- 无 `critical/high` 且未解决的冲突
- 无 `blocking=true` 且 `status=open` 的未决问题
- 用户确认可结束，或达到问题上限后进入强制收敛输出

---

## 2) Conflict taxonomy + severity + action matrix

| 冲突类型 | 说明 | 典型信号 |
|---|---|---|
| 语义冲突（semantic） | 同一事实被给出互斥描述 | “必须实时” vs “可异步” |
| 边界冲突（boundary） | 角色/权限/频次/范围冲突 | “游客可用” vs “必须登录” |
| 目标冲突（goal） | 业务目标互相掣肘 | “提升转化” vs “减少打扰” |
| 约束冲突（constraint） | 合规/技术/资源约束冲突 | “本周上线” vs “依赖未就绪” |

| 严重度 | 处理动作 | 下游影响 |
|---|---|---|
| critical | 立即追问 + 标记阻塞 | 必须 Blocked |
| high | 本轮优先追问 + 标记阻塞 | 默认 Blocked |
| medium | 下一轮追问 + 风险记录 | 可 Warn 继续 |
| low | 记录观察 + 可选追问 | 可继续 |

---

## 3) Per-round auto-summary template

每轮结束必须产出以下模板：

```markdown
## Round {n} Summary
- Confirmed Facts:
- Assumptions (Hypotheses):
- Conflicts Detected:
- Open Questions (added/updated/closed):
- Next Round Goal:
```

---

## 最终输出契约（用于下游衔接）

最终输出必须包含：
1. 人类可读 Markdown 总结
2. 可解析结构化块（YAML）

```yaml
think_vnext_output:
  session:
    rounds: 0
    total_questions: 0
    convergence: converged|forced_stop
  confirmed_facts: []
  assumptions: []
  conflicts: []
  open_questions: []
  downstream_handoff:
    user_story_inputs: []
    prd_inputs: []
    test_case_inputs: []
    workflow_gates: []
```

---

## mandatory 字段规则

以下字段缺失时不得静默推断：
- 目标用户/角色
- 目标问题与业务目标
- 成功判定标准
- 关键边界（权限/限制/异常）

如确需暂存推断，必须显式标注 `hypothesis` 并写入 `open_questions`。

---

## 参考

- `../../references/socratic-questioning.md`（vNext 主规范）

