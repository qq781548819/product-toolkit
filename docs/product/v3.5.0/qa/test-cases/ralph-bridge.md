# 测试用例：Ralph Bridge（v3.5.0）

**状态**: Draft  
**执行结论**: In Planning  
**来源**: think vNext + user-story + prd

---

## 前置 Gate 结论

- Gate0 输入完整性: **Pass**（PRD + US + AC 完整）
- Gate1 冲突未决判定: **Pass (+Warn)**（无 blocking 项）
- Gate2 AC→TC 映射: **Pass**（目标覆盖率 100%）

---

## 用例统计

| US | 用例数 | Smoke | 其他 TC |
|---|---:|---:|---:|
| US-351 | 3 | 1 | 2 |
| US-352 | 3 | 1 | 2 |
| US-353 | 4 | 1 | 3 |
| US-354 | 3 | 1 | 2 |
| US-355 | 2 | 1 | 1 |
| **总计** | **15** | **5** | **10** |

---

## 用例清单（按用户故事）

| TC ID | US | 类型 | 场景 | 关键检查点 | 覆盖 AC | 执行方式 |
|---|---|---|---|---|---|---|
| SMK-US351-01 | US-351 | 冒烟 | bridge 统一入口启动与状态查询 | 入口可用、返回 session 信息 | US351-AC01+AC04 | manual |
| TC-US351-02 | US-351 | 异常 | 非法 runtime 与参数校验 | Blocked + reason code | US351-AC02+AC03 | manual |
| TC-US351-03 | US-351 | 回滚 | 手工路径回退与安全审计 | 可回退、日志脱敏 | US351-AC05+AC06+AC07 | manual |
| SMK-US352-01 | US-352 | 冒烟 | bridge 状态映射写入 | 生成 `ralph-link.json`，映射正确 | US352-AC01+AC04 | manual |
| TC-US352-02 | US-352 | 边界 | session/root 双作用域恢复 | resume 稳定、重复可执行 | US352-AC02+AC05 | manual |
| TC-US352-03 | US-352 | 异常 | 状态文件损坏与重建 | 阻断并给修复步骤，可重建恢复 | US352-AC03+AC06+AC07 | manual |
| SMK-US353-01 | US-353 | 冒烟 | verify 三段式编排 | auto-test→review-gate→team-report 顺序执行 | US353-AC01+AC04 | manual |
| TC-US353-02 | US-353 | 异常 | auto-test strict 不通过 | verify 结论 Blocked，原因可追踪 | US353-AC02+AC03 | manual |
| TC-US353-03 | US-353 | 权限 | 报告与验证产物脱敏审查 | 证据可审计、无敏感泄露 | US353-AC06+AC07 | manual |
| TC-US353-04 | US-353 | 性能 | verify 编排耗时控制 | 验证链路在预算时长内 | US353-AC05 | manual |
| SMK-US354-01 | US-354 | 冒烟 | verify 失败后自动进入 fix loop | 阶段转移正确，终态未提前通过 | US354-AC01+AC04 | manual |
| TC-US354-02 | US-354 | 边界 | max_fix_loops 达阈值阻断 | 终态 Blocked + reason_code | US354-AC02+AC05+AC06 | manual |
| TC-US354-03 | US-354 | 回滚 | cancel 安全退出 | 终态 Cancelled，清理可复现 | US354-AC03+AC07 | manual |
| SMK-US355-01 | US-355 | 冒烟 | 缺口反馈自动回写并注入 | feedback 文件生成 + next-think 可消费 | US355-AC01+AC04+AC05 | manual |
| TC-US355-02 | US-355 | 边界 | 无缺口时不生成噪音反馈 | 无误报、失败可观测、支持重放 | US355-AC02+AC03+AC06+AC07 | manual |

---

## AC→TC 覆盖矩阵（完整）

| US | AC-ID | AC 描述 | TC-ID | 覆盖状态 |
|---|---|---|---|---|
| US-351 | US351-AC01 | 统一入口支持 start/resume/status/finalize | SMK-US351-01 | Covered |
| US-351 | US351-AC02 | runtime 选择规则明确 | TC-US351-02 | Covered |
| US-351 | US351-AC03 | 非法 runtime 阻断并返回原因 | TC-US351-02 | Covered |
| US-351 | US351-AC04 | 输出 bridge session 反馈 | SMK-US351-01 | Covered |
| US-351 | US351-AC05 | 入口调度性能可接受 | TC-US351-03 | Covered |
| US-351 | US351-AC06 | 日志脱敏 | TC-US351-03 | Covered |
| US-351 | US351-AC07 | 可回退到手工执行 | TC-US351-03 | Covered |
| US-352 | US352-AC01 | 生成桥接状态文件 | SMK-US352-01 | Covered |
| US-352 | US352-AC02 | 支持多作用域恢复 | TC-US352-02 | Covered |
| US-352 | US352-AC03 | 状态损坏阻断并提示修复 | TC-US352-03 | Covered |
| US-352 | US352-AC04 | status 可展示映射信息 | SMK-US352-01 | Covered |
| US-352 | US352-AC05 | 恢复流程稳定可重复 | TC-US352-02 | Covered |
| US-352 | US352-AC06 | 状态文件不含敏感信息 | TC-US352-03 | Covered |
| US-352 | US352-AC07 | 可重建 bridge state | TC-US352-03 | Covered |
| US-353 | US353-AC01 | verify 按顺序触发三类验证 | SMK-US353-01 | Covered |
| US-353 | US353-AC02 | 任一验证阻断整体通过 | TC-US353-02 | Covered |
| US-353 | US353-AC03 | 验证失败可定位 | TC-US353-02 | Covered |
| US-353 | US353-AC04 | 输出结构化验证结果 | SMK-US353-01 | Covered |
| US-353 | US353-AC05 | 验证时长可接受 | TC-US353-04 | Covered |
| US-353 | US353-AC06 | 验证产物脱敏审计 | TC-US353-03 | Covered |
| US-353 | US353-AC07 | 失败后可回 fix loop | TC-US353-03 | Covered |
| US-354 | US354-AC01 | 失败自动进入 fix loop | SMK-US354-01 | Covered |
| US-354 | US354-AC02 | max_fix_loops 阈值阻断 | TC-US354-02 | Covered |
| US-354 | US354-AC03 | 终态冲突被拦截 | TC-US354-03 | Covered |
| US-354 | US354-AC04 | 输出 terminal_status + reason_codes | SMK-US354-01 | Covered |
| US-354 | US354-AC05 | 循环调度稳定 | TC-US354-02 | Covered |
| US-354 | US354-AC06 | 终态记录可审计 | TC-US354-02 | Covered |
| US-354 | US354-AC07 | 支持人工 cancel 安全退出 | TC-US354-03 | Covered |
| US-355 | US355-AC01 | 缺口触发 feedback 自动生成 | SMK-US355-01 | Covered |
| US-355 | US355-AC02 | 无缺口不生成噪音反馈 | TC-US355-02 | Covered |
| US-355 | US355-AC03 | 反馈失败可观测且不误判 | TC-US355-02 | Covered |
| US-355 | US355-AC04 | 下一轮可注入 open_questions | SMK-US355-01 | Covered |
| US-355 | US355-AC05 | 反馈生成开销可控 | SMK-US355-01 | Covered |
| US-355 | US355-AC06 | 反馈内容脱敏 | TC-US355-02 | Covered |
| US-355 | US355-AC07 | 支持手动重放反馈 | TC-US355-02 | Covered |

---

## 风险与未决

- Warn-01：`runtime=auto` 优先级若未固化，跨项目行为可能不一致
- Warn-02：bridge 摘要是否同步全局 feedback 索引尚待确认

## 执行策略（建议）

1. 先跑 Smoke（5 条）验证主路径
2. 再跑异常/边界/回滚（10 条）验证阻断语义
3. 任一 Blocked 原因必须落 reason code 并保留证据
4. 仅当 AC→TC 全覆盖且无 blocking 未决时，允许标记 Ready

---

## 自动化执行明细（供 `/product-toolkit:auto-test` 解析）

## US-351 统一桥接入口

### SMK-US351-01 [manual]

- 步骤：执行 `./scripts/ralph_bridge.sh start --team rb-us351 --runtime auto --task "us351 smoke"`，再执行 `status`
- 期望：返回 bridge session id，含 team/runtime/session 关联字段
- AC: US351-AC01, US351-AC04

### TC-US351-02 [manual]

- 步骤：执行 `./scripts/ralph_bridge.sh start --team rb-us351-invalid --runtime invalid`
- 期望：命令失败，输出 unsupported runtime / reason code
- AC: US351-AC02, US351-AC03

### TC-US351-03 [manual]

- 步骤：执行桥接后切换为手工路径 `team_runtime + review_gate + team_report`，检查日志
- 期望：可回退执行且无凭据泄漏
- AC: US351-AC05, US351-AC06, US351-AC07

## US-352 状态映射与恢复

### SMK-US352-01 [manual]

- 步骤：执行 `start` 与 `status`，检查 `.ptk/state/bridge/<team>/ralph-link.json`
- 期望：状态文件存在，包含 team phase 与 mapped ralph phase
- AC: US352-AC01, US352-AC04

### TC-US352-02 [manual]

- 步骤：在 session-scoped/root-scoped ralph-state 条件下多次执行 `resume`
- 期望：均可稳定恢复，重复执行结果一致
- AC: US352-AC02, US352-AC05

### TC-US352-03 [manual]

- 步骤：模拟 bridge 状态文件损坏后恢复（备份->破坏->重建）
- 期望：阻断并给出修复路径，可重建后继续执行
- AC: US352-AC03, US352-AC06, US352-AC07

## US-353 验证闭环编排

### SMK-US353-01 [manual]

- 步骤：将 team 推进到 verify，执行 `ralph_bridge.sh resume`
- 期望：按顺序执行 auto-test → review-gate evaluate → team-report
- AC: US353-AC01, US353-AC04

### TC-US353-02 [manual]

- 步骤：制造 auto-test blocked（缺失 manual-results），再执行 verify
- 期望：verify 整体 Blocked，并定位到 auto-test 步骤
- AC: US353-AC02, US353-AC03

### TC-US353-03 [manual]

- 步骤：检查验证产物（test-session/review-gates/report）脱敏与可审计性
- 期望：产物可追溯且不含敏感信息
- AC: US353-AC06, US353-AC07

### TC-US353-04 [manual]

- 步骤：记录 verify 阶段端到端耗时
- 期望：耗时在项目预算阈值内
- AC: US353-AC05

## US-354 失败回环与终态语义一致

### SMK-US354-01 [manual]

- 步骤：在 verify 失败条件下执行 `resume`
- 期望：状态从 team-verify 转 team-fix，未提前 Pass
- AC: US354-AC01, US354-AC04

### TC-US354-02 [manual]

- 步骤：设置 `--max-fix-loops 1` 并循环 `resume`
- 期望：达到阈值后终态 Blocked，reason_code=max_fix_loops_exceeded
- AC: US354-AC02, US354-AC05, US354-AC06

### TC-US354-03 [manual]

- 步骤：执行 `finalize --terminal-status Cancelled`
- 期望：终态 Cancelled，且状态清理一致
- AC: US354-AC03, US354-AC07

## US-355 反馈回写与下一轮注入

### SMK-US355-01 [manual]

- 步骤：在存在缺口时执行 auto-test consolidate
- 期望：生成 requirement-feedback（state + docs）并可用于下一轮输入
- AC: US355-AC01, US355-AC04, US355-AC05

### TC-US355-02 [manual]

- 步骤：在无缺口时执行 auto-test consolidate；并尝试手动重放反馈
- 期望：不产生噪音反馈；异常可观测；重放可执行
- AC: US355-AC02, US355-AC03, US355-AC06, US355-AC07
