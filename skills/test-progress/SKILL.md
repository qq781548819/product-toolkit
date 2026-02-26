---
name: test-progress
description: Use when user wants to record test progress, smoke/regression test results, and generate test summary with requirement traceability
---

# 测试进度记录 (test-progress)

独立于版本测试用例文档，记录测试执行进度、结果追溯与演进自反馈。

## 使用方式

```
/product-toolkit:test-progress [版本]
/product-toolkit:test-progress --type=smoke|regression|full [版本]
```

例如：
- `/product-toolkit:test-progress v1.0.0` - 记录测试进度
- `/product-toolkit:test-progress --type=smoke v1.0.0` - 冒烟测试

## 测试进度文档位置

```
docs/product/{version}/
└── test-progress.md       # 测试进度（独立文件，不侵入版本测试用例）
    └── qa/test-progress/{feature}-{session_id}.md
```

机读产物：

```
.ptk/state/test-progress.json
.ptk/state/test-sessions/{session_id}.json
.ptk/state/requirement-feedback/{version}-{feature}.json
docs/product/{version}/qa/test-progress/{feature}-{session_id}.json
```

## 测试类型标识

| 标识 | 含义 | 用途 |
|------|------|------|
| `[SMOKE]` | 冒烟测试 | 核心路径，必须通过 |
| `[REGRESSION]` | 回归测试 | 已有功能回归验证 |
| `[NEW]` | 新功能测试 | 当前版本新功能 |
| `[FIX]` | 修复验证 | Bug修复验证 |

## 测试追溯机制

### 失败用例追溯链

```
测试失败 → 测试用例ID → 用户故事ID → 需求ID → 修复建议
```

### 追溯记录格式

```markdown
### TC-XXX: {用例名称}

- **失败原因**: {原因描述}
- **关联用户故事**: US-XXX
- **关联需求**: {需求ID}
- **修复建议**: {建议}
```

## 测试轮次记录

每次测试运行记录：

| 轮次 | 日期 | 类型 | 通过率 | 状态 |
|------|------|------|--------|------|
| 1 | 2026-02-25 | 冒烟 | 100% | PASS |
| 2 | 2026-02-25 | 回归 | 95% | FAIL |
| 3 | 2026-02-26 | 全面 | 100% | PASS |

并记录生命周期阶段：`start → record → stop → consolidate`。

## 演进自反馈

### 自反馈流程

```
测试失败 → 定位根因 → 追溯到需求/用户故事 → 生成修复建议 → 记录到演进总结
```

### 修复记录

```markdown
## 演进自反馈

### 本轮发现的问题
- 2026-02-25: 收藏列表加载慢 → 优化了缓存策略

### 修复验证
- 2026-02-26: 收藏列表加载时间已优化至 < 500ms
```

## 与版本测试用例的区别

| 维度 | 版本测试用例 | 测试进度文档 |
|------|-------------|-------------|
| 位置 | `qa/test-cases/` | 独立 `test-progress.md` |
| 内容 | 具体的测试用例 | 测试执行记录 |
| 更新 | 版本内更新 | 每次测试后追加 |
| 目的 | 定义测什么 | 记录测了什么 |

## 输出

1. 创建/更新 `docs/product/{version}/test-progress.md`
2. 追加测试轮次记录
3. 生成失败用例追溯
4. 生成演进自反馈建议
