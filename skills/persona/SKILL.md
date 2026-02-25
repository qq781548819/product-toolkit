---
name: persona
description: Use when user wants to create user personas - provides structured persona template with demographics, behaviors, goals, and pain points
---

# 用户画像

创建结构化的用户画像（Persona）。

## 使用方式

```
/product-toolkit:persona [用户描述]
```

例如：`/product-toolkit:persona 00后大学生`

## Persona 模板

```markdown
# 用户画像: {name}

**版本**: 1.0
**创建日期**: {date}
**产品经理**: {PM name}

---

## 基本信息

| 字段 | 内容 |
|------|------|
| 姓名 | {name} |
| 年龄 | {age} |
| 性别 | {gender} |
| 职业 | {occupation} |
| 收入 | {income} |
| 地区 | {location} |
| 学历 | {education} |
| 婚恋状态 | {status} |

---

## 用户特征

### 人口统计特征
{描述人口统计特征}

### 行为特征
- 使用频率: {frequency}
- 使用场景: {scenarios}
- 渠道偏好: {channels}
- 设备偏好: {devices}

### 心理特征
- 价值观: {values}
- 兴趣爱好: {interests}
- 生活方式: {lifestyle}

---

## 目标与动机

### 核心目标
| 目标 | 优先级 | 痛点 |
|------|--------|------|
| {goal 1} | P0 | {pain} |
| {goal 2} | P1 | {pain} |

### 动机
- 内在动机: {intrinsic}
- 外在动机: {extrinsic}

---

## 痛点

### 主要痛点
| 痛点 | 影响 | 当前解决方案 |
|------|------|-------------|
| {pain 1} | {impact} | {solution} |
| {pain 2} | {impact} | {solution} |

### 阻碍因素
- {factor 1}
- {factor 2}

---

## 使用场景

### 场景 1: {scenarioName}
- **时间**: {time}
- **地点**: {location}
- **触发**: {trigger}
- **行为**: {actions}
- **阻碍**: {barrier}

### 场景 2: {scenarioName}
...

---

## 需求与期望

### 功能需求
| 需求 | 优先级 | 理由 |
|------|--------|------|
| {need 1} | P0 | {reason} |
| {need 2} | P1 | {reason} |

### 服务期望
- {expectation 1}
- {expectation 2}

---

## 触点与渠道

### 主要触点
| 触点 | 频率 | 满意度 |
|------|------|--------|
| {touchpoint} | {freq} | {satisfaction} |

### 偏好渠道
- 线上: {online}
- 线下: {offline}
- 客服: {service}

---

## Quotes

> "{quote 1}"
> - {name}

> "{quote 2}"
> - {name}

---

## 设计建议

### 界面偏好
- 风格: {style}
- 配色: {colors}
- 交互: {interaction}

### 功能优先级
1. {priority 1}
2. {priority 2}
3. {priority 3}

---

## 验证

### 调研方法
- [ ] 用户访谈 (N=5)
- [ ] 问卷调查 (N=100)
- [ ] 数据分析
- [ ] 竞品分析

### 验证结果
{验证结果描述}
```

---

## 示例

```markdown
# 用户画像: 小美

**版本**: 1.0

---

## 基本信息

| 字段 | 内容 |
|------|------|
| 姓名 | 小美 |
| 年龄 | 22 |
| 性别 | 女 |
| 职业 | 大学生 |
| 地区 | 北京 |
| 学历 | 本科在读 |

---

## 用户特征

### 行为特征
- 使用频率: 每天多次
- 使用场景: 通勤、课间、睡前
- 渠道偏好: 移动端App、小红书
- 设备偏好: 智能手机

### 心理特征
- 价值观: 追求个性、注重体验
- 兴趣爱好: 社交媒体、购物、美妆
- 生活方式: 碎片化时间多

---

## 目标与动机

### 核心目标
- 便捷购物 - P0
- 发现好物 - P1

### 痛点
- 选择困难 - 商品太多
- 信息过载 - 评价难辨真假

---

## Quotes

> "我希望买的东西室友都夸好看"
> - 小美
```

---

## 输出目录

```
docs/product/personas/{name}.md
```
