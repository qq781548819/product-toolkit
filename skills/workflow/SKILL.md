---
name: workflow
description: Run complete strict workflow with think vNext hard-switch gates and requirement-feedback injection
---

# 一键工作流（v3.4.0）

## 链路

`think → user-story → prd → test-case → auto-test → feedback → next-think`

## strict 默认

- gate 默认阻断
- `--force` 可继续，但必须落风险记录
- 最终态仅：`Pass` / `Blocked`

## 执行前置：反馈优先读取（新增）

进入新一轮 workflow 前，优先读取：

1. `.ptk/state/requirement-feedback/*.json`
2. `docs/product/feedback/*.json`
3. `docs/product/{version}/feedback/*.json`

并把 `open_questions` 注入 think 输入。

## 阻塞规则

任一成立即 `Blocked`：

1. `open_question.blocking=true` 且未关闭
2. critical/high 冲突未关闭
3. AC→TC 映射缺失
4. auto-test strict 缺口存在（missing_user_stories / missing_test_cases / strict_guard）

## 反馈回写

auto-test consolidate 后自动生成：

- `.ptk/state/requirement-feedback/{version}-{feature}.json`
- `docs/product/{version}/feedback/{feature}.md|json`
- `docs/product/feedback/{version}-{feature}.md|json`

这些文件是下一轮 workflow 的 first-class input。
