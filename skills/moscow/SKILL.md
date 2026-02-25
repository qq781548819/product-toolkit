---
name: moscow
description: Use when user wants to prioritize requirements using MoSCoW method - Must, Should, Could, Won't framework for requirement prioritization
---

# MoSCoW 优先级排序

使用 MoSCoW 方法对需求进行优先级排序。

## 使用方式

```
/product-toolkit:moscow [功能或需求列表]
```

## MoSCoW 框架

| 优先级 | 比例 | 定义 | 含义 |
|--------|------|------|------|
| **Must** | 20-30% | 必须做 | 上线阻塞项，没有这个功能产品无法发布 |
| **Should** | 30-40% | 应该做 | 重要非阻塞，强烈建议实现 |
| **Could** | 20-30% | 可以做 | 锦上添花，有时间再做 |
| **Won't** | 10% | 不做 | 本期不实现，未来可能考虑 |

---

## 决策指南

### Must（必须做）
- 没有这个功能产品无法上线
- 法律法规要求
- 严重安全问题
- 核心业务流程

### Should（应该做）
- 重要但非阻塞
- 会影响用户体验
- 竞争对手都有

### Could（可以做）
- 提升体验
- 有则更好
- 资源允许时

### Won't（本期不做）
- 超出本期范围
- 优先级较低
- 未来版本考虑

---

## 输出模板

```markdown
## MoSCoW 优先级排序

### {version} 版本

#### Must (必须做) - {count} 项
| ID | 需求 | 理由 |
|----|------|------|
| 1 | {requirement} | {reason} |
| 2 | {requirement} | {reason} |

#### Should (应该做) - {count} 项
| ID | 需求 | 理由 |
|----|------|------|
| 1 | {requirement} | {reason} |
| 2 | {requirement} | {reason} |

#### Could (可以做) - {count} 项
| ID | 需求 | 理由 |
|----|------|------|
| 1 | {requirement} | {reason} |
| 2 | {requirement} | {reason} |

#### Won't (本期不做) - {count} 项
| ID | 需求 | 理由 |
|----|------|------|
| 1 | {requirement} | {reason} |
| 2 | {requirement} | {reason} |

---

## 决策记录

### 争议项讨论
| 需求 | 分歧点 | 决策 | 决策人 |
|------|--------|------|--------|
| {item} | {issue} | {decision} | {person} |

### 优先级变更历史
| 日期 | 需求 | 原优先级 | 新优先级 | 变更原因 |
|------|------|----------|----------|----------|
| {date} | {item} | {old} | {new} | {reason} |
```

---

## 快速判断方法

### 问题法
1. **没有这个功能能上线吗？**
   - 不能 → Must
   - 能 → 继续

2. **不做用户会流失吗？**
   - 会 → Should
   - 不会 → 继续

3. **做了用户体验会显著提升吗？**
   - 会 → Could
   - 不会 → Won't

### 比例法
```
本期总需求数 = N

Must ≤ N × 30%
Should ≤ N × 40%
Could ≤ N × 30%
Won't ≥ N × 10%
```

---

## 示例

```markdown
## 电商收藏功能 MoSCoW

### Must (3项)
1. 收藏商品 - 核心功能
2. 查看收藏列表 - 基本功能
3. 取消收藏 - 核心功能

### Should (2项)
1. 批量收藏 - 提升效率
2. 收藏分类 - 提升体验

### Could (2项)
1. 收藏推荐 - 锦上添花
2. 分享收藏夹 - 社交功能

### Won't (1项)
1. 跨设备同步 - 超本期范围
```

---

## 参考

- `../../references/MOSCOW.md` - MoSCoW 优先级详解

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
