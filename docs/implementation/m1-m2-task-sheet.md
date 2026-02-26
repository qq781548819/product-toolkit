# Product Toolkit M1/M2 完整任务单

> 生成日期：2026-02-26  
> 版本范围：M1（1周）+ M2（2-3周）  
> 状态：待执行

---

## 0. 方案冻结（已确认）

1. **Strict 默认开启**
2. **M2 运行时同时兼容**：文件状态机 + tmux 多 worker（统一命令入口）
3. **open-questions 回写落点**：先写 `.ptk/state` + `docs/product/feedback`

---

## 1. 里程碑与交付物

## M1（1周）

- 统一 memory schema（含迁移）
- strict 默认门禁落地
- auto-test 结果自动回写需求反馈

主要交付：
- `.ptk/memory/*schema.json`（统一字段）
- `scripts/migrate_memory_v3.py`
- `scripts/feedback_from_test.py`
- `.ptk/state/requirement-feedback.schema.json`

## M2（2-3周）

- Team 运行时：file/tmux 双兼容 + 命令化启动
- Team 状态机与恢复能力
- 双审查 gate（spec -> quality）和 max_fix_loops

主要交付：
- `scripts/team_runtime.sh`
- `.ptk/state/team-state.schema.json`
- `scripts/review_gate.sh`
- `.ptk/state/review-gates.schema.json`

---

## 2. M1 任务清单（执行级）

### PTK-M1-01（P0）统一记忆信封 Schema
- **目标**：定义跨记忆类型统一字段
- **文件**：新增 `.ptk/memory/memory-envelope.schema.json`
- **DoD**：
  - 包含字段：`memory_id/type/source_session_id/evidence_ref/confidence/tags/created_at/updated_at`
  - 可被 insights/decisions/vocabulary/test-learnings 复用
- **验证**：
  - `python3 -m json.tool .ptk/memory/memory-envelope.schema.json`
- **估时**：0.5d
- **依赖**：无

### PTK-M1-02（P0）四类 Memory Schema 对齐
- **目标**：4 个 schema 兼容统一信封字段
- **文件**：
  - `.ptk/memory/project-insights.schema.json`
  - `.ptk/memory/decisions.schema.json`
  - `.ptk/memory/vocabulary.schema.json`
  - `.ptk/memory/test-learnings.schema.json`
- **DoD**：
  - 保留旧字段兼容读取
  - 新增字段可选（避免破坏旧数据）
- **验证**：
  - `for f in .ptk/memory/*.schema.json; do python3 -m json.tool "$f" >/dev/null || exit 1; done`
- **估时**：1d
- **依赖**：PTK-M1-01

### PTK-M1-03（P0）Memory v3 迁移脚本
- **目标**：把现有 `.ptk/memory/*.json` 迁移到统一结构
- **文件**：新增 `scripts/migrate_memory_v3.py`
- **DoD**：
  - 支持 `--dry-run`
  - 自动备份（含时间戳）
  - 支持 `--rollback <backup>`
- **验证**：
  - `python3 scripts/migrate_memory_v3.py --dry-run`
- **估时**：1d
- **依赖**：PTK-M1-02

### PTK-M1-04（P1）remember/recall 契约更新
- **目标**：技能文档与统一 schema 对齐
- **文件**：
  - `skills/remember/SKILL.md`
  - `skills/recall/SKILL.md`
  - `README.md`（memory 章节）
- **DoD**：
  - 示例字段与 schema 一致
  - 明确 evidence/source/session 字段语义
- **验证**：
  - `rg -n "memory_id|evidence_ref|source_session_id|confidence" skills/remember/SKILL.md skills/recall/SKILL.md README.md`
- **估时**：0.5d
- **依赖**：PTK-M1-02

### PTK-M1-05（P0）Strict 默认开启
- **目标**：默认走严格门禁策略
- **文件**：
  - `config/persistence.yaml`
  - `skills/gate/SKILL.md`
  - `skills/workflow/SKILL.md`
  - `SKILL.md`
  - `commands/product-toolkit.md`
- **DoD**：
  - 默认 strict 生效
  - `--force` 保留但必须记录风险
- **验证**：
  - `rg -n "strict|hard|force|Blocked" config/persistence.yaml skills/gate/SKILL.md skills/workflow/SKILL.md SKILL.md commands/product-toolkit.md`
- **估时**：1d
- **依赖**：无

### PTK-M1-06（P0）auto-test strict reason code 标准化
- **目标**：blocked 原因输出 machine-readable code
- **文件**：
  - `scripts/auto_test.sh`
  - （可选）新增 `config/strict-reason-codes.yaml`
- **DoD**：
  - 输出 `blocked_reason_codes`（稳定枚举）
  - 与 gaps/strict 字段可追溯映射
- **验证**：
  - `rg -n "blocked_reason|reason_code|strict case-plan guard failed" scripts/auto_test.sh`
- **估时**：1d
- **依赖**：PTK-M1-05

### PTK-M1-07（P0）需求反馈 Schema + 生成器
- **目标**：把测试缺口转成需求反馈产物
- **文件**：
  - 新增 `.ptk/state/requirement-feedback.schema.json`
  - 新增 `scripts/feedback_from_test.py`
- **DoD**：
  - 输入：`test-session.json`
  - 输出：
    - `.ptk/state/requirement-feedback/{version}-{feature}.json`
    - `docs/product/{version}/feedback/{feature}.md`
    - `docs/product/{version}/feedback/{feature}.json`
- **验证**：
  - `python3 scripts/feedback_from_test.py --help`
- **估时**：1d
- **依赖**：PTK-M1-06

### PTK-M1-08（P0）auto-test 挂接反馈回写
- **目标**：consolidate 后自动生成 feedback
- **文件**：`scripts/auto_test.sh`
- **DoD**：
  - 触发条件：`missing_user_stories` / `missing_test_cases` / `repeat_guard`
  - 自动写入 `.ptk/state` 与 `docs/product/feedback`
- **验证**：
  - `rg -n "feedback_from_test|requirement-feedback|missing_user_stories|repeat_guard" scripts/auto_test.sh`
- **估时**：0.5d
- **依赖**：PTK-M1-07

### PTK-M1-09（P1）think/workflow 消费反馈输入
- **目标**：下一轮将 feedback 注入 open-questions
- **文件**：
  - `skills/think/SKILL.md`
  - `skills/workflow/SKILL.md`
  - `README.md`
- **DoD**：
  - 文档明确 feedback -> open-questions 映射
  - 工作流说明包含“反馈优先读取”
- **验证**：
  - `rg -n "feedback|open-questions|requirement-feedback" skills/think/SKILL.md skills/workflow/SKILL.md README.md`
- **估时**：0.5d
- **依赖**：PTK-M1-08

---

## 3. M2 任务清单（执行级）

### PTK-M2-01（P0）Team Runtime 统一入口
- **目标**：统一 file/tmux/auto 运行时入口
- **文件**：新增 `scripts/team_runtime.sh`
- **命令契约**：
  - `team_runtime.sh start --runtime file|tmux|auto ...`
  - `team_runtime.sh status --team <name>`
  - `team_runtime.sh resume --team <name>`
  - `team_runtime.sh shutdown --team <name>`
- **DoD**：
  - 至少 file runtime 可跑通完整命令链
- **估时**：1d
- **依赖**：无

### PTK-M2-02（P0）Team 状态 Schema
- **目标**：定义 Team 状态机数据结构
- **文件**：新增 `.ptk/state/team-state.schema.json`
- **DoD**：
  - 状态覆盖：`team-plan/team-prd/team-exec/team-verify/team-fix/terminal`
  - 支持 resume 所需字段
- **估时**：0.5d
- **依赖**：PTK-M2-01

### PTK-M2-03（P0）File Runtime 实现
- **目标**：文件状态机完整生命周期
- **文件**：`scripts/team_runtime.sh`
- **目录约定**：
  - `.ptk/state/team/<team>/manifest.json`
  - `.ptk/state/team/<team>/tasks/task-<id>.json`
  - `.ptk/state/team/<team>/workers/<id>/status.json`
  - `.ptk/state/team/<team>/mailbox/*.json`
- **DoD**：
  - `start -> status -> resume -> shutdown` 闭环可用
- **估时**：2d
- **依赖**：PTK-M2-02

### PTK-M2-04（P0）tmux Runtime 适配
- **目标**：接入 tmux worker 并共享同一状态目录
- **文件**：
  - `scripts/team_runtime.sh`
  - （可选）新增 `scripts/team_runtime_tmux.sh`
- **DoD**：
  - `--runtime tmux` 可启动 worker
  - `status/resume/shutdown` 与 file runtime 一致
- **估时**：2d
- **依赖**：PTK-M2-03

### PTK-M2-05（P0）双审查 Gate（spec -> quality）
- **目标**：先 spec 再 quality，强制顺序
- **文件**：
  - 新增 `scripts/review_gate.sh`
  - 新增 `.ptk/state/review-gates.schema.json`
- **DoD**：
  - spec 未 pass，quality 不可执行
  - 记录 gate 证据与阻塞原因
- **估时**：1d
- **依赖**：PTK-M2-03

### PTK-M2-06（P0）max_fix_loops 与 Blocked 终态
- **目标**：修复循环上限控制
- **文件**：
  - `config/workflow.yaml`
  - `scripts/team_runtime.sh`
- **DoD**：
  - 达阈值自动 `Blocked`
  - 写入结构化 reason
- **估时**：0.5d
- **依赖**：PTK-M2-05

### PTK-M2-07（P1）阶段 Handoff 机制
- **目标**：阶段切换上下文可恢复
- **文件**：
  - 新增 `scripts/team_handoff.py`
  - 输出 `.ptk/handoffs/<stage>.md`
- **DoD**：
  - 每次阶段迁移自动写 handoff
  - resume 时优先读取 handoff
- **估时**：0.5d
- **依赖**：PTK-M2-03

### PTK-M2-08（P1）Team 技能/命令文档更新
- **目标**：把新命令和 runtime 契约写入文档
- **文件**：
  - `skills/team/SKILL.md`
  - `commands/product-toolkit.md`
  - `README.md`
- **DoD**：
  - 文档包含 runtime 参数、命令示例、终态语义（Pass/Blocked/Cancelled）
- **估时**：0.5d
- **依赖**：PTK-M2-04, PTK-M2-06

### PTK-M2-09（P1）Team 可观测报告
- **目标**：输出阶段历史、阻塞原因、最终态报告
- **文件**：
  - 新增 `scripts/team_report.sh`
  - `docs/qa-standards-playbook.md`（增加 team 验证项）
- **DoD**：
  - 生成可读报告（md/json 二选一或双产出）
- **估时**：1d
- **依赖**：PTK-M2-08

---

## 4. 总执行顺序（依赖拓扑）

`M1-01 -> M1-02 -> M1-03 -> M1-04`  
`M1-05 -> M1-06 -> M1-07 -> M1-08 -> M1-09`  
`M2-01 -> M2-02 -> M2-03 -> M2-04`  
`M2-03 -> M2-05 -> M2-06 -> M2-08 -> M2-09`  
`M2-03 -> M2-07`

---

## 5. 风险与预案

1. **Schema 变更导致旧数据不可读**
   - 预案：M1-03 必须先 dry-run + backup + rollback
2. **Strict 默认开启引发历史流程失败**
   - 预案：提供临时 `--force` + reason code 指引文档
3. **tmux runtime 行为不稳定**
   - 预案：file runtime 作为保底路径，`--runtime auto` 优先 file 回退

---

## 6. 完成定义（M1/M2）

### M1 完成定义
- 统一 memory schema 已落地并迁移可用
- strict 默认开启且可追踪 blocked reason
- test -> feedback 自动回写可生成产物并被 think/workflow 消费

### M2 完成定义
- team runtime 支持 file/tmux/auto 且命令一致
- spec->quality 双审查 gate 生效
- max_fix_loops + terminal 语义稳定（Pass/Blocked/Cancelled）

