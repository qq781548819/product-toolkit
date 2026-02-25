---
name: wireframe
description: Use when user wants to generate wireframes, mockups, or visual descriptions for UI - provides wireframe structure and layout descriptions
---

# UI 草稿图与线框图

生成功能页面的草稿图描述和线框图布局。

## 使用方式

```
/product-toolkit:wireframe [功能或页面]
```

例如：`/product-toolkit:wireframe 登录页面`

## 输出结构

### 1. 页面概述

```markdown
## 页面: {pageName}

### 页面类型
- [ ] 列表页
- [ ] 详情页
- [ ] 表单页
- [ ] 弹窗/抽屉
- [ ] 流程页

### 核心目标
{页面要达成的主要目标}

### 用户场景
{典型用户使用场景}
```

---

### 2. 信息架构

```markdown
## 信息架构

### 页面结构
- Header (头部)
  - Logo
  - 导航
  - 用户信息

- Content (内容区)
  - 主内容
  - 侧边栏

- Footer (底部)
  - 版权
  - 链接
```

---

### 3. 线框图描述

```markdown
## 线框图布局

### 顶部导航
| 元素 | 描述 | 状态 |
|------|------|------|
| Logo | 产品logo | 固定 |
| 导航栏 | 主导航菜单 | 固定 |
| 搜索框 | 商品/内容搜索 | 可收起 |

### 主要内容区
| 区域 | 内容 | 布局 |
|------|------|------|
| 焦点区域 | 轮播/推荐 | 宽度100% |
| 功能区 | 核心功能入口 | 2-4列 |
| 列表区 | 内容列表 | 瀑布流/网格 |

### 交互元素
| 元素 | 交互 | 反馈 |
|------|------|------|
| 按钮 | 点击 | 状态变化 |
| 卡片 | 点击 | 跳转/详情 |
| 输入框 | 获得焦点 | 边框高亮 |
```

---

### 4. 组件清单

```markdown
## 组件清单

### 基础组件
- [ ] 按钮 (Button)
- [ ] 输入框 (Input)
- [ ] 选择器 (Select)
- [ ] 开关 (Switch)
- [ ] 复选框 (Checkbox)
- [ ] 单选框 (Radio)

### 业务组件
- [ ] 商品卡片
- [ ] 用户头像
- [ ] 评价星级
- [ ] 价格显示
- [ ] 数量选择器

### 容器组件
- [ ] 卡片 (Card)
- [ ] 列表项 (ListItem)
- [ ] 表格 (Table)
- [ ] 标签页 (Tabs)
```

---

### 5. 流程图

```markdown
## 用户流程

### 流程 1: {flowName}
1. 入口 → 页面加载
2. 操作 → 反馈
3. 确认 → 结果

### 分支流程
- 成功路径:
- 失败路径:
- 中断路径:
```

---

### 6. 响应式设计

```markdown
## 响应式断点

| 断点 | 宽度 | 布局变化 |
|------|------|---------|
| Mobile | < 768px | 单列，底部导航 |
| Tablet | 768-1024px | 双列，侧边栏 |
| Desktop | > 1024px | 多列，完整功能 |
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

- `../../references/ui-wireframe.md` - UI 草稿图与线框图
- `../../references/product-to-ui.md` - 产品思考→UI 转换指南

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
