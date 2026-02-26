# PRD: Product Toolkit Platform v3.4.0

**状态**: Ready for Delivery  
**来源**: v3.3.0 基线 + M1/M2 任务单实现

---

## 1. 背景

v3.3.0 已完成文档化基线，但工程闭环仍需补足：

1. strict 默认策略统一
2. 测试缺口自动反哺需求迭代
3. team 多代理运行时可恢复与可审查

## 2. 目标

1. 提供可执行、可验证、可交付的 v3.4.0 增量
2. 将测试缺口自动沉淀为 requirement-feedback
3. 形成 file/tmux 双兼容 team runtime 与双审查 gate

## 3. 范围

### In Scope

1. 统一 memory envelope schema 与迁移脚本
2. auto-test 输出 blocked reason code 并触发 feedback 回写
3. strict 默认配置与文档契约同步
4. `team_runtime.sh`（start/status/resume/shutdown）
5. `review_gate.sh`（spec -> quality -> evaluate）
6. `team_report.sh`（md/json 报告）

### Out of Scope

1. 云端分布式调度
2. 外部缺陷系统自动同步

## 4. 功能需求（FR）

### FR-341 统一记忆信封

- 统一字段：`memory_id/type/source_session_id/evidence_ref/confidence/tags/created_at/updated_at`
- 兼容 insights/decisions/vocabulary/test-learnings

### FR-342 strict 默认

- `config/persistence.yaml` 默认 strict 策略开启
- `--force` 可继续但必须风险留痕

### FR-343 自动反馈回写

- 来源：test-session gaps + repeat_guard
- 写入：
  - `.ptk/state/requirement-feedback/{version}-{feature}.json`
  - `docs/product/{version}/feedback/{feature}.md|json`
  - `docs/product/feedback/{version}-{feature}.md|json`

### FR-344 Team Runtime 双形态

- 统一入口：file/tmux/auto
- 状态机：`team-plan/team-prd/team-exec/team-verify/team-fix/terminal`
- resume/shutdown 可恢复可终止

### FR-345 双审查 Gate

- spec 必须先于 quality
- critical/high 未清零 => evaluate=Blocked

### FR-346 max_fix_loops

- 达阈值自动终态 `Blocked`
- 输出结构化 reason code：`max_fix_loops_exceeded`

## 5. 可验证性（DoD）

1. `python3 scripts/migrate_memory_v3.py --dry-run`
2. `python3 scripts/feedback_from_test.py --help`
3. `./scripts/team_runtime.sh --help`
4. `./scripts/review_gate.sh --help`
5. `./scripts/team_report.sh --help`
6. file/tmux runtime 均可 `start -> status -> resume -> shutdown`

## 6. 风险与预案

1. tmux 不可用：auto 回退 file runtime
2. strict 默认引发阻塞增多：保留 `--force` + 风险留痕
3. 反馈量增长：通过 feedback 目录按版本归档
