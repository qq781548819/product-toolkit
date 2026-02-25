---
name: data-dictionary
description: Use when user wants to define data models and fields - provides data dictionary template with schema, constraints, and index strategy
---

# 数据字典

为功能模块生成结构化数据字典文档。

## 使用方式

```bash
/product-toolkit:data-dictionary 用户模块
/product-toolkit:data-dictionary 订单系统
```

## 输出模板

```markdown
# 数据字典: {feature}

## 1. 数据模型总览
| 模型 | 说明 | 主键 |
|------|------|------|
| {table} | {desc} | id |

## 2. 字段定义
### {table}
| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| id | UUID | Y | - | 主键 |
| created_at | timestamp | Y | now() | 创建时间 |
| updated_at | timestamp | Y | now() | 更新时间 |

## 3. 约束与索引
- 唯一约束: {constraint}
- 外键约束: {fk}
- 索引策略: {index}

## 4. 数据生命周期
- 创建: {create rule}
- 更新: {update rule}
- 删除: {delete rule}
```

## 输出目录

默认模式（单命令调用）:
```
docs/tech/data-model/{feature}.md
```

工作流模式（/product-toolkit:workflow）:
```
docs/product/{version}/tech/data-model/{feature}.md
```

## 参考

- `../../references/data-dictionary.md` - 数据字典参考
