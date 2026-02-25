---
name: kano
description: Use when user wants to analyze requirements using KANO model - classifies requirements into Must-be, One-dimensional, Attractive, Indifferent, Reverse
---

# KANO 模型分析

使用 KANO 模型对功能进行分类分析，理解用户满意度与功能实现的关系。

## 使用方式

```
/product-toolkit:kano [功能或产品]
```

例如：`/product-toolkit:kano 社区功能`

## KANO 框架

### 5 类需求

| 类型 | 含义 | 用户满意度 | 例子 |
|------|------|-----------|------|
| **Must-be** | 必备型 | 有→满意，无→不满意 | 基础功能、安全性 |
| **One-dimensional** | 期望型 | 有→满意，无→不满意 | 性能、响应速度 |
| **Attractive** | 兴奋型 | 有→惊喜，无→无影响 | 创新功能、彩蛋 |
| **Indifferent** | 无差异型 | 有无都无所谓 | 冗余功能 |
| **Reverse** | 反向型 | 有→不满意，无→满意 | 强制弹窗、复杂流程 |

---

### 用户反应矩阵

| 功能\期望 | 我喜欢 | 理应如此 | 无所谓 | 勉强接受 | 我不喜欢 |
|----------|-------|---------|-------|---------|---------|
| **有该功能** | Q | A | A | O | M |
| **无该功能** | R | I | I | M | Q |

### 分类结果
- **A (Attractive)**: 兴奋型需求
- **O (One-dimensional)**: 期望型需求
- **M (Must-be)**: 必备型需求
- **I (Indifferent)**: 无差异需求
- **R (Reverse)**: 反向需求
- **Q (Questionable)**: 可疑结果（需重新调研）

---

## 分析流程

### 1. 功能列表

| 功能 | 假设类型 | 优先级 |
|------|---------|--------|
| {feature 1} | Must-be | P0 |
| {feature 2} | One-dimensional | P1 |
| {feature 3} | Attractive | P2 |

### 2. 问卷设计

```markdown
## 功能: {feature}

### 正向问题
如果该功能可用，您的感受是？
- [ ] 我喜欢
- [ ] 理应如此
- [ ] 无所谓
- [ ] 勉强接受
- [ ] 我不喜欢

### 负向问题
如果该功能不可用，您的感受是？
- [ ] 我喜欢
- [ ] 理应如此
- [ ] 无所谓
- [ ] 勉强接受
- [ ] 我不喜欢
```

### 3. 结果分析

| 功能 | A% | O% | M% | I% | R% | Q% | 分类 |
|------|-----|-----|-----|-----|-----|-----|------|
| {f1} | {v} | {v} | {v} | {v} | {v} | {v} | {type} |
| {f2} | {v} | {v} | {v} | {v} | {v} | {v} | {type} |

---

## 输出模板

```markdown
## KANO 分析报告

### 功能分类

#### Must-be (必备型)
| 功能 | 影响 | 建议 |
|------|------|------|
| {f} | 满意度大幅下降 | 必须实现 |

#### One-dimensional (期望型)
| 功能 | 满意度曲线 | 建议 |
|------|-------------|------|
| {f} | 线性相关 | 尽量实现 |

#### Attractive (兴奋型)
| 功能 | 惊喜程度 | 建议 |
|------|---------|------|
| {f} | 高 | 尽量实现 |

#### Indifferent (无差异)
| 功能 | 处理建议 |
|------|---------|
| {f} | 可考虑不做 |

#### Reverse (反向)
| 功能 | 问题 | 建议 |
|------|------|------|
| {f} | {issue} | 避免实现 |

---

### 满意度-功能矩阵

      无功能
        ↓
   低 ↓    ← Indifferent
        │
        │
 M    O    │   有功能
 ↓    ↓    ↓    ↑
低←────────────→高
满意度
```

---

## 示例

```markdown
## 电商收藏功能 KANO 分析

### Must-be (必备型)
- 商品价格显示 - 用户基本期望
- 支付安全 - 信任基础

### One-dimensional (期望型)
- 收藏操作便捷 - 有则满意
- 收藏列表清晰 - 有则满意

### Attractive (兴奋型)
- 收藏提醒 - 超出预期
- 智能推荐 - 惊喜功能

### Indifferent (无差异)
- 收藏背景颜色 - 无所谓

### Reverse (反向)
- 强制关注 - 反感
```

---

## 决策建议

1. **Must-be 优先**: 必须满足，否则用户不满意
2. **关注 O/A**: 投入产出比最高
3. **避免 R**: 用户反感的功能不做
4. **简化 I**: 无差异功能可不做

---

## 参考

- `../../references/KANO.md` - KANO 模型详解

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
