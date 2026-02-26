---
name: product-toolkit
description: 通用产品经理工具集 - v3.4.0（strict 默认 + team runtime + feedback 回写）
---

# Product Toolkit v3.4.0

[PRODUCT TOOLKIT ACTIVATED]

## 🚨 Breaking Change（延续）

`/product-toolkit:think` 已使用 **think vNext** 规则契约，旧版固定轮次/固定题库语义已下线。

## ✅ 默认策略

- **Strict 默认开启**（门控阻断优先）
- 允许 `--force`，但必须记录风险
- open-questions 反馈落点：`.ptk/state/requirement-feedback` + `docs/product/feedback`

---

## 子命令（核心）

| 命令 | 功能 | 主要产物 |
|---|---|---|
| `/product-toolkit:think` | think vNext（批量+动态追问+冲突检测） | 下游输入契约 |
| `/product-toolkit:user-story` | 用户故事（7维 AC） | `docs/product/{version}/user-story/` |
| `/product-toolkit:prd` | PRD | `docs/product/{version}/prd/` |
| `/product-toolkit:test-case` | 测试用例 + AC→TC | `docs/product/{version}/qa/test-cases/` |
| `/product-toolkit:auto-test` | strict 自动测试生命周期 | `.ptk/state/test-sessions/` + `docs/product/{version}/qa/test-progress/` |
| `/product-toolkit:test-progress` | 测试进度汇总 | `.ptk/state/test-progress.json` |
| `/product-toolkit:workflow` | 全链路编排 + Gate | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:team` | 多代理协作 | `docs/product/{version}/` + `.ptk/state/team/` |
| `/product-toolkit:remember` | 记忆写入 | `.ptk/memory/*.json` |
| `/product-toolkit:recall` | 记忆检索 | `.ptk/memory/*.json` |
| `/product-toolkit:gate` | strict gate 检查 | 终态 `Pass/Blocked` |

---

## M1：strict + 反馈闭环（已落地）

1. 统一记忆信封字段：`memory_id/type/source_session_id/evidence_ref/confidence/tags/created_at/updated_at`
2. auto-test 输出 `gaps.blocked_reason_codes`（machine-readable）
3. 测试缺口自动回写：
   - `.ptk/state/requirement-feedback/{version}-{feature}.json`
   - `docs/product/{version}/feedback/{feature}.md|json`
   - `docs/product/feedback/{version}-{feature}.md|json`

---

## M2：Team Runtime 命令契约（已落地）

```bash
# 统一入口（file/tmux/auto）
./scripts/team_runtime.sh start --team <name> --runtime file|tmux|auto --task "..."
./scripts/team_runtime.sh status --team <name>
./scripts/team_runtime.sh resume --team <name>
./scripts/team_runtime.sh shutdown --team <name> --terminal-status Pass|Blocked|Cancelled
```

状态目录约定：

```text
.ptk/state/team/<team>/
├── manifest.json
├── tasks/task-001.json
├── workers/<worker>/status.json
├── mailbox/*.json
├── review-gates.json
└── reports/*.md|json
```

---

## 双审查 Gate（spec -> quality）

```bash
./scripts/review_gate.sh --team <name> init
./scripts/review_gate.sh --team <name> spec --status pass --reviewer pm
./scripts/review_gate.sh --team <name> quality --status pass --reviewer qa
./scripts/review_gate.sh --team <name> evaluate --critical-open 0 --high-open 0
./scripts/review_gate.sh --team <name> status
```

规则：

1. spec 未 pass，不允许提交 quality
2. critical/high 未清零，`evaluation.status=Blocked`
3. `max_fix_loops` 达阈值，team 终态自动 `Blocked`

---

## Team 报告

```bash
./scripts/team_report.sh --team <name> --format both
```

输出阶段历史、阻塞原因、终态结论（可审计）。
