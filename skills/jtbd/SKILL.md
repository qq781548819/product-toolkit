---
name: jtbd
description: Use when user wants to apply Jobs-to-be-Done framework - analyzes what job user is trying to accomplish and what progress they seek
---

# JTBD 用户任务理论

理解用户"雇佣"产品来完成的工作，而不仅仅是产品功能。

## 使用方式

```
/product-toolkit:jtbd [产品或服务]
```

例如：`/product-toolkit:jtbd 外卖订餐`

## 核心框架

### 1. 任务定义 (The Job)

**问题**：用户雇佣这个产品来完成什么工作？

**格式**：
> 当我想要 [要完成的进度] 时，我会使用 [产品] 来帮助我 [预期的解决方案]。

**示例**：
> 当我想要在忙碌的工作日快速解决午餐时，我会使用外卖 app 来帮助我足不出户就能吃到热腾腾的饭菜。

---

### 2. 任务维度

#### 功能性任务 (Functional Jobs)
- 用户需要完成什么具体任务？
- 有什么痛点需要解决？
- 效率如何提升？

#### 情感性任务 (Emotional Jobs)
- 用户希望感受到什么？
- 希望别人如何看待自己？
- 想要避免什么负面情绪？

#### 社会性任务 (Social Jobs)
- 用户希望如何在他人面前展示自己？
- 想要融入哪个群体？
- 想要区别于哪个群体？

---

### 3. 用户旅程

| 阶段 | 用户想法 | 痛点 | 机会点 |
|------|---------|------|-------|
| 开始前 | | | |
| 寻找中 | | | |
| 选择时 | | | |
| 使用中 | | | |
| 使用后 | | | |

---

### 4. 竞争对手

**问题**：用户现在用什么替代方案？

| 替代方案 | 用户为什么选择它？ | 它的缺点是什么？ |
|---------|-----------------|----------------|
| 竞品A | | |
| 竞品B | | |
| 自己动手 | | |
| 凑合不用 | | |
| 完全不做 | | |

---

### 5. 推动力与阻碍

**推动力**（让用户选择你的产品）：
-
-

**阻碍**（让用户不选择你的产品）：
-
-

---

### 6. 输出模板

```markdown
## JTBD 分析报告

### 核心任务
[一句话描述用户要完成的工作]

### 任务维度
- 功能性任务：
- 情感性任务：
- 社会性任务：

### 用户画像
- 典型用户：
- 使用场景：

### 竞争格局
- 直接竞品：
- 间接竞品：
- 替代方案：

### 产品机会
- 核心机会1：
- 核心机会2：
```

## 与产品思考关系

JTBD 可以作为产品思考的前置分析：
- JTBD 帮你理解"为什么"
- 产品思考帮你定义"做什么"

```
/product-toolkit:jtbd [产品]  (理解用户任务)
        ↓
/product-toolkit:think [功能]  (定义具体需求)
        ↓
/product-toolkit:user-story
```

## 参考

- `../../references/jtbd.md` - JTBD 完整指南
- `../../references/value-proposition.md` - 价值主张画布

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
