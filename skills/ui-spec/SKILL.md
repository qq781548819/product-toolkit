---
name: ui-spec
description: Use when user wants to generate UI design specifications, design tokens, or design system components - provides comprehensive UI specification document
---

# UI 设计规范

生成完整的 UI 设计规范文档，包括设计系统组件和样式定义。

## 使用方式

```
/product-toolkit:ui-spec [功能或组件]
```

例如：`/product-toolkit:ui-spec 详情页`

## 输出结构

### 1. 设计原则

```markdown
## 设计原则

### 核心原则
- 一致性: 相似元素保持一致的外观和行为
- 反馈: 每个操作都有清晰的视觉反馈
- 效率: 帮助用户快速完成任务
- 可控: 用户始终感到在掌控之中

### 视觉原则
- 层次: 通过大小、颜色、空间建立信息层次
- 对齐: 元素对齐创建秩序感
- 对比: 关键信息突出显示
- 留白: 适当的空白提高可读性
```

---

### 2. 色彩系统

```markdown
## 色彩系统

### 主色 (Primary)
- 主色: {hex}
- 主色浅: {hex}
- 主色深: {hex}
- 用途: 按钮、链接、强调

### 辅助色 (Secondary)
- 辅色1: {hex}
- 辅色2: {hex}
- 用途: 图表、图标、背景

### 功能色
- 成功: {hex} - #4CAF50
- 警告: {hex} - #FF9800
- 错误: {hex} - #F44336
- 信息: {hex} - #2196F3

### 中性色
- 文本主色: {hex}
- 文本次色: {hex}
- 文本禁用: {hex}
- 边框: {hex}
- 背景: {hex}
- 分割线: {hex}
```

---

### 3. 字体系统

```markdown
## 字体系统

### 字体家族
- 主字体: {font-family}
- 等宽字体: {font-family}

### 字号体系
| 层级 | 字号 | 行高 | 字重 |
|------|------|------|------|
| H1 | 32px | 40px | 700 |
| H2 | 24px | 32px | 600 |
| H3 | 20px | 28px | 600 |
| Body | 16px | 24px | 400 |
| Small | 14px | 20px | 400 |
| Caption | 12px | 16px | 400 |

### 文本样式
- 链接: 下划线，颜色 {hex}
- 强调: 字重 600
- 禁用: 颜色 {hex}，透明度 50%
```

---

### 4. 间距系统

```markdown
## 间距系统

### 基础单位
- 基准: 4px / 8px

### 间距变量
| 名称 | 值 | 用途 |
|------|------|------|
| xs | 4px | 紧凑元素间距 |
| sm | 8px | 组件内部间距 |
| md | 16px | 组件间距 |
| lg | 24px | 区块间距 |
| xl | 32px | 页面间距 |
| xxl | 48px | 区域间距 |
```

---

### 5. 组件规范

```markdown
## 组件规范

### 按钮 (Button)

#### 主按钮
- 背景: {primary}
- 文字: #FFFFFF
- 圆角: 8px
- 高度: 44px
- 间距: 16px 24px

#### 状态
- Hover: 亮度 +10%
- Active: 亮度 -10%
- Disabled: 透明度 50%

---

### 输入框 (Input)

#### 默认状态
- 边框: {border}
- 背景: {bg}
- 高度: 44px
- 圆角: 8px
- 内边距: 12px 16px

#### 获得焦点
- 边框: {primary}
- 阴影: 0 0 0 2px {primary}20

#### 错误状态
- 边框: {error}
- 文字: {error}
```

---

### 6. 动效规范

```markdown
## 动效规范

### 过渡时间
- 快速: 150ms
- 正常: 250ms
- 慢速: 350ms

### 缓动函数
- 入场: ease-out
- 出场: ease-in
- 交互动效: ease-in-out

### 常用动效
- 淡入淡出: opacity 250ms
- 位移: transform 250ms
- 缩放: scale 150ms
```

---

### 7. 响应式规范

```markdown
## 响应式断点

| 断点 | 宽度 | 布局 |
|------|------|------|
| xs | < 576px | 单列 |
| sm | ≥ 576px | 双列 |
| md | ≥ 768px | 双列+侧边 |
| lg | ≥ 992px | 多列 |
| xl | ≥ 1200px | 宽屏布局 |
```

---

## 完整工作流

```
产品思考 (5轮追问)
        ↓
/product-toolkit:wireframe [功能]  (草稿图)
        ↓
/product-toolkit:ui-spec [功能]  (UI规范)
```

## 参考

- `../../references/ui-spec.md` - UI 设计规范模板
- `../../references/product-to-ui.md` - 产品思考→UI 转换指南

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
