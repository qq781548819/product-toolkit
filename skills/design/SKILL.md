---
name: design
description: Use when user wants to apply Design Thinking methodology - provides 5-stage framework (Empathize, Define, Ideate, Prototype, Test) for user-centered problem solving
---

# Design Thinking 设计思维

以用户为中心的创新方法论，5 阶段系统化解决复杂问题。

## 使用方式

```
/product-toolkit:design [功能或问题]
```

例如：`/product-toolkit:design 支付功能`

## 5 阶段框架

### 阶段 1: Empathize 同理心

**目标**：深入理解用户

**问题**：
- 目标用户是谁？他们的日常生活是什么样的？
- 用户的核心痛点是什么？
- 用户现在用什么方式解决这个问题？
- 用户的情感和期望是什么？

**输出**：用户画像、痛点列表、用户旅程图

---

### 阶段 2: Define 定义问题

**目标**：提炼真正要解决的问题

**问题**：
- 从同理心阶段发现了什么洞察？
- 真正的问题是什么？
- 如何用一句话描述这个问题？
- 问题的本质是什么？

**输出**：问题陈述 (Problem Statement)

---

### 阶段 3: Ideate 创意

**目标**：产出大量创意点子

**问题**：
- 可能的解决方案有哪些？（至少 10 个）
- 如果没有任何限制，会怎么做？
- 竞品是怎么解决的？
- 可以从其他行业借鉴什么？

**工具**：
- 头脑风暴
- 思维导图
- SCAMPER 奔驰法

**输出**：创意清单、MoSCoW 优先级

---

### 阶段 4: Prototype 原型

**目标**：快速验证想法

**问题**：
- 最简单的验证方式是什么？
- 需要做什么样的原型？
- 如何以最小成本测试核心假设？

**原型类型**：
- 纸质原型
- 流程图
- 线框图
- 交互原型

**输出**：原型方案

---

### 阶段 5: Test 测试

**目标**：验证解决方案

**问题**：
- 用户对原型的反馈是什么？
- 哪些设计有效？哪些需要改进？
- 需要迭代哪些部分？
- 学到了什么新洞察？

**输出**：测试反馈、迭代建议

---

## 与产品思考关系

Design Thinking 是**第 0 轮**（可选），其输出可作为产品思考（第 1-5 轮）的输入：

```
Design Thinking (第0轮，可选)
        ↓
产品思考 5 轮追问 (第1-5轮)
        ↓
用户故事 + 测试用例
```

## 完整工作流

```
/product-toolkit:design [功能]  (可选第0轮)
        ↓
产品思考 (5轮追问)
        ↓
/product-toolkit:wireframe [功能]
        ↓
/product-toolkit:ui-spec [功能]
```

## 参考

- `../../references/design-thinking.md` - Design Thinking 完整指南

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
