---
name: roadmap
description: Use when user wants to create product roadmap - provides structured roadmap template with phases, milestones, and feature timeline
---

# 产品路线图

创建产品路线图，展示产品长期规划和迭代计划。

## 使用方式

```
/product-toolkit:roadmap [产品或规划]
```

## 路线图模板

```markdown
# 产品路线图: {productName}

**版本**: {version}
**周期**: {start} - {end}
**产品经理**: {PM name}

---

## 愿景

> {一句话描述产品愿景}

---

## 战略目标

| 目标 | 衡量指标 | 时间范围 |
|------|---------|---------|
| {goal 1} | {metric} | {period} |
| {goal 2} | {metric} | {period} |

---

## 版本规划

### Q1 {year}

| 版本 | 主题 | 关键功能 | 日期 |
|------|------|---------|------|
| v1.0 | MVP | {features} | {date} |
| v1.1 | 优化 | {features} | {date} |

### Q2 {year}

| 版本 | 主题 | 关键功能 | 日期 |
|------|------|---------|------|
| v1.2 | {theme} | {features} | {date} |
| v1.3 | {theme} | {features} | {date} |

---

## 路线图视图

### 时间轴视图

```
{year}
Q1 ──────────────────
  v1.0 [========]
  v1.1      [====]
Q2 ────────────────────────
  v1.2            [====]
  v1.3                 [====]
```

### 功能视图

| 功能 | 状态 | Q1 | Q2 | Q3 | Q4 |
|------|------|----|----|----|---|
| {feature} | 规划 | ✓ | | | |
| {feature} | 开发中 | | ✓ | | |
| {feature} | 完成 | | | ✓ | |

---

## 里程碑

| 里程碑 | 日期 | 交付物 | 状态 |
|--------|------|--------|------|
| {milestone} | {date} | {deliverable} | {status} |

---

## 依赖与风险

### 技术依赖
| 依赖项 | 负责方 | 完成时间 |
|--------|-------|---------|
| {dep} | {team} | {date} |

### 风险
| 风险 | 影响 | 应对措施 |
|------|------|---------|
| {risk} | {impact} | {mitigation} |

---

## 输出目录

```
docs/product/roadmap.md
```
