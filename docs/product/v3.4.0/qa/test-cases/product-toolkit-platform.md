# 测试用例：Product Toolkit Platform（v3.4.0）

**状态**: Ready  
**来源**: v3.4.0 PRD + User Story

---

## 用例统计

| US | 用例数 |
|---|---:|
| US-341 | 2 |
| US-342 | 3 |
| US-343 | 3 |
| US-344 | 3 |
| US-345 | 5 |
| **总计** | **16** |

---

## US-341 strict 默认门控

### SMK-US341-01 [manual]

- 步骤：检查 `config/persistence.yaml` 是否包含 `strict_default: true`
- 期望：strict 默认开启
- AC: US341-AC01

### TC-US341-02 [manual]

- 步骤：检查 gate/workflow 文档是否声明 `--force` 覆盖需要风险留痕
- 期望：存在明确 force 风险记录要求
- AC: US341-AC02, US341-AC04

## US-342 统一记忆信封与迁移

### TC-US342-01 [manual]

- 步骤：执行 `for f in .ptk/memory/*.schema.json; do python3 -m json.tool "$f"; done`
- 期望：全部 schema 可解析
- AC: US342-AC01

### TC-US342-02 [manual]

- 步骤：执行 `python3 scripts/migrate_memory_v3.py --dry-run`
- 期望：返回 dry-run 结果且不破坏数据
- AC: US342-AC03, US342-AC04

### TC-US342-03 [manual]

- 步骤：执行 `python3 scripts/migrate_memory_v3.py --help`
- 期望：包含 `--rollback`
- AC: US342-AC07

## US-343 auto-test 反馈回写

### SMK-US343-01 [manual]

- 步骤：执行 `python3 scripts/feedback_from_test.py --help`
- 期望：脚本可执行
- AC: US343-AC01

### TC-US343-02 [manual]

- 步骤：检查 `scripts/auto_test.sh` 包含 `generate_requirement_feedback_if_needed`
- 期望：auto-test consolidate 后自动触发反馈回写
- AC: US343-AC01, US343-AC04

### TC-US343-03 [manual]

- 步骤：运行反馈生成并验证产物落点（state + docs/version + docs/global）
- 期望：三类目录均生成反馈文件
- AC: US343-AC04, US343-AC07

## US-344 Team Runtime 统一入口

### SMK-US344-01 [manual]

- 步骤：执行 `./scripts/team_runtime.sh --help`
- 期望：返回 start/status/resume/shutdown 命令说明
- AC: US344-AC01

### TC-US344-02 [manual]

- 步骤：`team_runtime.sh start/status/resume/shutdown --runtime file`
- 期望：`.ptk/state/team/<team>/` 目录结构完整
- AC: US344-AC01, US344-AC04

### TC-US344-03 [manual]

- 步骤：`team_runtime.sh start/status/resume/shutdown --runtime tmux`
- 期望：worker pane 正常启动并可关闭
- AC: US344-AC02

## US-345 双审查 Gate + max_fix_loops

### SMK-US345-01 [manual]

- 步骤：执行 `./scripts/review_gate.sh --help`
- 期望：包含 init/spec/quality/evaluate/status
- AC: US345-AC01

### TC-US345-02 [manual]

- 步骤：在 spec 未 pass 时直接提交 quality
- 期望：quality 被阻止
- AC: US345-AC01

### TC-US345-03 [manual]

- 步骤：执行 evaluate 并设置 `--high-open 1`
- 期望：`evaluation.status=Blocked`
- AC: US345-AC02, US345-AC04

### TC-US345-04 [manual]

- 步骤：`team_runtime.sh` 设置 `--max-fix-loops 1` 后多次 resume
- 期望：终态 `Blocked` 且 `reason_code=max_fix_loops_exceeded`
- AC: US345-AC07

### TC-US345-05 [manual]

- 步骤：执行 `./scripts/team_report.sh --team <name> --format both`
- 期望：生成 md/json 报告并含阻塞原因
- AC: US345-AC04
