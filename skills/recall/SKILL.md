---
name: recall
description: Recall project insights, decisions, or vocabulary from memory
---

# 检索项目记忆

从记忆系统中检索之前保存的项目洞察、决策和术语。

## 使用方式

```bash
/product-toolkit:recall [query]
/product-toolkit:recall 用户
/product-toolkit:recall --insights
/product-toolkit:recall --decisions
```

## 功能说明

### 关键词检索

```bash
/product-toolkit:recall 用户
/product-toolkit:recall 支付
/product-toolkit:recall 架构
```

检索包含关键词的记忆。

### 按类型检索

```bash
# 只检索洞察
/product-toolkit:recall --insights

# 只检索决策
/product-toolkit:recall --decisions

# 只检索术语
/product-toolkit:recall --vocabulary
```

### 列出所有记忆

```bash
# 列出所有
/product-toolkit:recall --list

# 按类型列出
/product-toolkit:recall --list --insights
/product-toolkit:recall --list --decisions
```

## 输出示例

### 检索洞察

```
┌─────────────────────────────────────────────┐
│  Project Insights: "用户"                   │
├─────────────────────────────────────────────┤
│  #1 [product_assumption]                    │
│  核心用户是 Z 世代大学生                    │
│  Confidence: 0.9 | Source: think vNext     │
│  Created: 2026-02-25                        │
├─────────────────────────────────────────────┤
│  #2 [user_persona]                          │
│  用户画像：18-25岁，追求性价比               │
│  Confidence: 0.85 | Source: persona       │
│  Created: 2026-02-24                        │
└─────────────────────────────────────────────┘
```

### 检索决策

```
┌─────────────────────────────────────────────┐
│  Decisions: "架构"                          │
├─────────────────────────────────────────────┤
│  #1 [active]                                │
│  采用微服务架构                              │
│  Rationale: 业务复杂度高，需要独立部署和扩展   │
│  Alternatives: 单体架构                     │
│  Decided: 2026-02-20                        │
├─────────────────────────────────────────────┤
│  #2 [active]                                │
│  使用 PostgreSQL 数据库                     │
│  Rationale: 强一致性需求，丰富的 JSON 支持   │
│  Alternatives: MySQL, MongoDB              │
│  Decided: 2026-02-18                        │
└─────────────────────────────────────────────┘
```

### 检索术语

```
┌─────────────────────────────────────────────┐
│  Vocabulary: "U"                           │
├─────────────────────────────────────────────┤
│  SKU                                        │
│  Stock Keeping Unit - 库存量单位            │
│  Category: 电商                             │
├─────────────────────────────────────────────┤
│  DAU                                        │
│  Daily Active Users - 日活跃用户数           │
│  Category: 运营                             │
├─────────────────────────────────────────────┤
│  UV                                         │
│  Unique Visitor - 独立访客                  │
│  Category: 运营                             │
└─────────────────────────────────────────────┘
```

## 选项

| 选项 | 说明 |
|------|------|
| `[query]` | 检索关键词 |
| `--insights` | 只检索洞察 |
| `--decisions` | 只检索决策 |
| `--vocabulary` | 只检索术语 |
| `--list` | 列出所有 |
| `--json` | JSON 格式输出 |

## 自动注入到工作流

检索结果会自动注入到相关阶段：
- think 阶段：注入相关 insights
- prd 阶段：注入相关 decisions 和 vocabulary

## 相关技能

- `/product-toolkit:remember` - 记忆知识
- `/product-toolkit:save` - 保存会话状态
- `/product-toolkit:status` - 查看状态
