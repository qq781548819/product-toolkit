---
name: analyze
description: Use when user wants to conduct competitor analysis - provides structured competitive analysis template covering features, positioning, and strategy
---

# 竞品分析

进行结构化的竞品分析。

## 使用方式

```
/product-toolkit:analyze [竞品]
```

例如：`/product-toolkit:analyze 抖音`

## 分析模板

```markdown
# 竞品分析: {competitorName}

**版本**: 1.0
**分析日期**: {date}
**分析师**: {analyst}

---

## 1. 概览

| 项目 | 内容 |
|------|------|
| 产品名称 | {name} |
| 产品类型 | {type} |
| 上线时间 | {launch_date} |
| 融资阶段 | {funding} |
| 用户规模 | {scale} |
| 商业模式 | {model} |

---

## 2. 产品定位

### 目标用户
{描述目标用户群体}

### 核心价值
{描述核心价值主张}

### 市场定位
- 定位: {positioning}
- 差异化: {differentiation}
- 定价: {pricing}

---

## 3. 功能分析

### 3.1 功能矩阵

| 功能 | 竞品A | 竞品B | 我方 | 备注 |
|------|-------|-------|------|------|
| {feature} | ✓ | ✓ | ✓/✗ | {note} |

### 3.2 核心功能分析

#### 功能 1: {featureName}
- 竞品实现: {implementation}
- 优缺点: {pros_cons}
- 借鉴点: {learnings}

---

## 4. 用户体验

### 4.1 交互设计
| 维度 | 竞品 | 评分 | 我方 | 评分 |
|------|------|------|------|------|
| 易用性 | {app} | {score} | {us} | {score} |
| 视觉 | {app} | {score} | {us} | {score} |
| 流程 | {app} | {score} | {us} | {score} |

### 4.2 用户评价
- App Store: {rating} 星
- Google Play: {rating} 星
- 主要好评: {positive}
- 主要差评: {negative}

---

## 5. 商业模式

### 收入来源
| 来源 | 占比 | 说明 |
|------|------|------|
| {source} | {percent} | {desc} |

### 定价策略
{描述定价策略}

---

## 6. 运营策略

### 增长策略
- 渠道: {channels}
- 活动: {campaigns}
- 用户获取成本: {cac}

### 用户留存
- 次日留存: {retention_d1}
- 7日留存: {retention_d7}
- 30日留存: {retention_d30}

---

## 7. 技术分析

### 技术架构
{描述技术特点}

### 性能表现
| 指标 | 竞品 | 行业平均 |
|------|------|---------|
| 启动时间 | {time} | {avg} |
| Crash率 | {rate} | {avg} |

---

## 8. SWOT 分析

### 优势 (Strengths)
- {s1}
- {s2}

### 劣势 (Weaknesses)
- {w1}
- {w2}

### 机会 (Opportunities)
- {o1}
- {o2}

### 威胁 (Threats)
- {t1}
- {t2}

---

## 9. 建议

### 功能建议
| 建议 | 优先级 | 理由 |
|------|--------|------|
| {advice} | P0 | {reason} |

### 战略建议
1. {advice 1}
2. {advice 2}

---

## 输出目录

```
docs/product/competitors/{name}.md
```
