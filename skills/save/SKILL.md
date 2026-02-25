---
name: save
description: Save current session state to .ptk/ for persistence across sessions
---

# 保存会话状态

将当前会话进度保存到 `.ptk/` 目录，实现跨会话持久化。

## 使用方式

```bash
/product-toolkit:save
/product-toolkit:save --force
```

## 保存内容

根据当前工作流阶段，保存以下内容：

### think 阶段
- `session_id`: 会话唯一标识
- `feature`: 功能名称
- `current_round`: 当前轮次
- `convergence_status`: 收敛状态
- `confirmed_facts`: 已确认事实
- `conflicts`: 冲突列表
- `open_questions`: 未决问题清单
- `assumptions`: 假设列表
- `round_summaries`: 每轮摘要

### workflow 阶段
- `workflow_id`: 工作流唯一标识
- `current_phase`: 当前阶段
- `completed_phases`: 已完成阶段
- `gate_status`: 门控状态
- `outputs`: 各阶段输出

### test-case 阶段
- `version`: 版本号
- `test_cases`: 测试用例列表
- `summary`: 测试汇总

## 保存位置

```
.ptk/state/
├── think-progress.json
├── workflow-state.json
└── test-progress.json
```

## 选项

| 选项 | 说明 |
|------|------|
| `--force` | 强制覆盖已有保存 |
| `--include-memory` | 同时保存记忆（insights, decisions） |

## 自动保存

在以下情况自动保存：
- 每个阶段完成时
- 每 60 秒（可配置）
- 切换阶段时

## 恢复会话

使用 `/product-toolkit:resume` 恢复会话：
```bash
/product-toolkit:resume
/product-toolkit:resume [session_id]
```

## 相关技能

- `/product-toolkit:resume` - 恢复会话
- `/product-toolkit:status` - 查看当前状态
