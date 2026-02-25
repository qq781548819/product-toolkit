---
name: evolution-summary
description: Use when user wants to generate version evolution summary with requirement changes, user story status, and test feedback
---

# 演进总结 (evolution-summary)

自动生成版本演进总结，包含需求变更、用户故事状态、测试覆盖变化与自反馈记录。

## 使用方式

```
/product-toolkit:evolution-summary [版本]
```

例如：`/product-toolkit:evolution-summary v1.0.1`

## 演进总结文档位置

```
docs/product/{version}/
└── SUMMARY.md              # 版本总览（演进总结）
```

## 演进总结内容

### 版本信息

```markdown
## 版本信息
- 上一版本: v1.0.0
- 当前版本: v1.0.1
- 版本类型: patch (热修复)
- 推进方式: 自动 patch+1
```

### 需求变更

```markdown
## 需求变更

### 新增需求
- REQ-001: 用户收藏功能 [NEW]
- REQ-002: 收藏列表展示 [NEW]

### 变更需求
- REQ-003: 收藏性能优化 [MODIFIED]

### 废弃需求
- REQ-010: 旧版分享功能 [DEPRECATED]
```

### 用户故事状态

```markdown
## 用户故事状态

| ID | 标题 | 状态 | 来源 |
|----|------|------|------|
| US-0001 | 用户收藏商品 | [INHERITED] | v1.0.0 |
| US-0002 | 查看收藏列表 | [INHERITED] | v1.0.0 |
| US-0003 | 性能优化 | [NEW] | - |
| US-0004 | 旧版分享 | [DEPRECATED] | v1.0.0 |
```

### 测试覆盖

```markdown
## 测试覆盖

| 类型 | 数量 | 通过率 |
|------|------|--------|
| [SMOKE] | 10 | 100% |
| [REGRESSION] | 50 | 98% |
| [NEW] | 5 | 100% |
| [FIX] | 3 | 100% |
```

### 测试自反馈

```markdown
## 测试自反馈

### 失败用例
- TC-023: 收藏列表加载超时 → US-0002 → REQ-002
  - 原因: 数据库查询未优化
  - 修复: 添加索引优化

### 修复记录
- 2026-02-25: 添加数据库索引
- 2026-02-25: 验证通过，通过率从 95% 提升到 100%
```

## 自动汇总逻辑

### 版本号推进

- 无参数: 自动 patch+1
- `--bump=minor`: minor+1
- `--bump=major`: major+1

### 用户故事继承

```
新版本用户故事 = 上一版本 [INHERITED]
                + 当前版本新增 [NEW]
                + 当前版本修改 [MODIFIED]
                - 当前版本废弃 [DEPRECATED]
```

### 测试自反馈追溯

```
测试失败 → TC → US → REQ → 修复建议 → 演进总结
```

## 与其他命令关系

```
/product-toolkit:version [功能]        (版本规划)
        ↓
/product-toolkit:test-progress [版本]   (测试进度记录)
        ↓
/product-toolkit:evolution-summary [版本] (演进总结)
```

## 输出

1. 创建/更新 `docs/product/{version}/SUMMARY.md`
2. 汇总需求变更
3. 汇总用户故事状态
4. 汇总测试覆盖
5. 生成测试自反馈记录
