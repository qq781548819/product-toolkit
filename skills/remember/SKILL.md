---
name: remember
description: Remember project insights, decisions, or vocabulary for cross-session persistence
---

# 记忆项目知识

将项目洞察、决策或术语保存到记忆系统，实现跨会话知识积累。

## 使用方式

```bash
/product-toolkit:remember [insight]
/product-toolkit:remember --insight "核心用户是 Z 世代"
// 项目洞察
/product-toolkit:remember --decision "采用微服务架构"
// 决策记录
/product-toolkit:remember --vocabulary "SKU: Stock Keeping Unit, 库存量单位"
// 领域术语
```

## 记忆类型

### 项目洞察 (insight)

保存产品核心假设、用户画像、技术约束等：

```bash
/product-toolkit:remember --insight "核心用户是 Z 世代大学生"
/product-toolkit:remember --insight "支付渠道需要支持支付宝和微信"
```

### 决策记录 (decision)

保存历史决策及其理由：

```bash
/product-toolkit:remember --decision "采用微服务架构"
  --rationale "业务复杂度高，需要独立部署和扩展"
/product-toolkit:remember --decision "使用 PostgreSQL"
  --alternatives "MySQL, MongoDB"
```

### 领域术语 (vocabulary)

保存领域专有术语：

```bash
/product-toolkit:remember --vocabulary "SKU: Stock Keeping Unit, 库存量单位"
/product-toolkit:remember --vocabulary "DAU: Daily Active Users, 日活跃用户数"
```

## 选项

| 选项 | 说明 |
|------|------|
| `--insight` | 保存项目洞察 |
| `--decision` | 保存决策记录 |
| `--vocabulary` | 保存领域术语 |
| `--category` | 分类标签 |
| `--confidence` | 置信度 (0-1) |
| `--source` | 来源说明 |

## 记忆位置

```
.ptk/memory/
├── project-insights.json
├── decisions.json
└── vocabulary.json
```

## 自动注入

在以下阶段自动注入记忆：
- `/product-toolkit:think` - 注入相关 insights
- `/product-toolkit:prd` - 注入相关 decisions 和 vocabulary

## 查看记忆

使用 `/product-toolkit:recall` 检索记忆：

```bash
/product-toolkit:recall 用户
/product-toolkit:recall --decisions
/product-toolkit:recall --insights
```

## 相关技能

- `/product-toolkit:recall` - 检索记忆
- `/product-toolkit:save` - 保存会话状态
- `/product-toolkit:status` - 查看状态
