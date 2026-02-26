---
name: team
description: N coordinated agents with file/tmux runtime, state machine resume, and spec->quality review gates
---

# Team 多代理协作（v3.4.0）

## 运行时形态

- `file`：纯文件状态机（保底）
- `tmux`：多 worker 进程协作
- `auto`：按配置自动选择（默认偏好 file）

## 统一命令入口

```bash
./scripts/team_runtime.sh start --team <name> --runtime file|tmux|auto --task "..."
./scripts/team_runtime.sh status --team <name>
./scripts/team_runtime.sh resume --team <name>
./scripts/team_runtime.sh shutdown --team <name> --terminal-status Pass|Blocked|Cancelled
```

## 阶段状态机

`team-plan → team-prd → team-exec → team-verify → team-fix → terminal`

终态语义：

- `Pass`
- `Blocked`
- `Cancelled`

`max_fix_loops` 达上限自动 `Blocked`（`reason_code=max_fix_loops_exceeded`）。

## 双审查 Gate（spec -> quality）

```bash
./scripts/review_gate.sh --team <name> init
./scripts/review_gate.sh --team <name> spec --status pass --reviewer pm
./scripts/review_gate.sh --team <name> quality --status pass --reviewer qa
./scripts/review_gate.sh --team <name> evaluate --critical-open 0 --high-open 0
```

规则：

1. spec 未 pass，quality 不可提交
2. critical/high 未清零，evaluation=Blocked

## 状态目录

```text
.ptk/state/team/<team>/
├── manifest.json
├── tasks/task-001.json
├── workers/<id>/status.json
├── mailbox/*.json
├── review-gates.json
└── reports/*.md|json
```

## Handoff 与报告

- 阶段迁移自动生成：`.ptk/handoffs/<team>-<from>-to-<to>.md`
- 运行报告：

```bash
./scripts/team_report.sh --team <name> --format both
```
