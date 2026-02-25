---
name: resume
description: Resume a previous session from .ptk/ persistence
---

# 恢复会话状态

从 `.ptk/` 目录恢复之前保存的会话进度。

## 使用方式

```bash
/product-toolkit:resume
/product-toolkit:resume
/product-toolkit:resume --list
/product-toolkit:resume [session_id]
```

## 功能说明

### 列出可恢复的会话

```bash
/product-toolkit:resume --list
```

显示所有可恢复的会话：
```
Session ID                    Feature         Round   Status      Updated
---------------------------------------------------------------------------
abc123-def456                 电商收藏功能     3/5     in_progress 2026-02-25
xyz789-uvw012                 用户登录模块     5/5     converged   2026-02-24
```

### 恢复最新会话

```bash
/product-toolkit:resume
```

恢复最近保存的会话。

### 恢复指定会话

```bash
/product-toolkit:resume abc123-def456
```

通过 session_id 恢复指定会话。

## 恢复内容

恢复以下状态：
- think 阶段：收敛状态、已确认事实、冲突、未决问题
- workflow 阶段：当前阶段、已完成阶段、门控状态
- test-case 阶段：测试进度、测试用例状态

## 恢复后行为

1. 显示恢复的会话摘要
2. 询问用户是否继续该会话
3. 加载相关的记忆（insights, decisions）
4. 继续工作流或 think 阶段

## 选项

| 选项 | 说明 |
|------|------|
| `--list` | 列出所有可恢复的会话 |
| `--latest` | 恢复最新会话（默认） |
| `--clear` | 恢复后删除保存的文件 |

## 会话历史

默认保留最近 10 个会话。如需更多，使用配置：

```yaml
# config/persistence.yaml
session:
  max_history_count: 20
```

## 相关技能

- `/product-toolkit:save` - 保存当前会话
- `/product-toolkit:status` - 查看当前状态
