# PRD: Ralph Bridge Integration（v3.5.0）

**状态**: Ready for Implementation  
**来源**: v3.4.0 基线 + ralph 长任务桥接方案评审

---

## 1. 背景与目标

### 背景

当前长任务执行存在“控制流”和“验收流”分离问题：

1. OMX/OMC 的 ralph/team 擅长持续执行与循环修复
2. PTK 的 workflow/auto-test/gate 擅长需求与验收闭环
3. 缺少统一桥接层，导致终态判定与证据落盘不一致

### 目标

1. 形成统一桥接入口，驱动 ralph 长任务与 PTK 验收链路协同
2. 建立可恢复、可审计的状态映射
3. 将“完成”定义为通过验证门控，而非主观声明

---

## 2. 用户与价值

- 目标用户：PM、Tech Lead、QA Lead、交付负责人
- 用户价值：
  - 降低手工编排成本
  - 提高验收一致性与可追溯性
  - 避免长任务“假完成”

---

## 3. 范围定义

### In Scope

1. 定义 ralph 桥接契约（入口、状态、终态）
2. 串联 `auto-test + review_gate + team_report` 验证闭环
3. 统一 `Pass / Blocked / Cancelled` 语义
4. 反馈回写到 requirement-feedback 并注入下一轮 think/workflow

### Out of Scope

1. 重写 OMX/OMC 内部调度引擎
2. 新增外部缺陷系统（Jira/Linear）自动同步
3. 云端分布式任务编排

---

## 4. 功能需求（FR）

### FR-351 统一桥接入口

- 提供桥接命令面：`start / resume / status / finalize`
- 支持运行时：`omx | omc | auto`
- 产出 bridge session 元信息（关联 team/session/runtime）

### FR-352 状态映射与恢复

- 维护桥接状态文件：`.ptk/state/bridge/<team>/ralph-link.json`
- 映射：
  - ralph `executing` ↔ PTK `team-plan/team-prd/team-exec`
  - ralph `verifying` ↔ PTK `team-verify + auto-test + review_gate`
  - ralph `fixing` ↔ PTK `team-fix`
  - ralph `complete/failed/cancelled` ↔ PTK `Pass/Blocked/Cancelled`
- 支持中断恢复（resume）

### FR-353 验证闭环编排

- verify 阶段必须按顺序执行：
  1. `auto_test` strict 验证
  2. `review_gate evaluate`
  3. `team_report` 产出
- 任一步骤 `Blocked/Fail` 必须阻断终态通过

### FR-354 失败回环与终态控制

- 未通过时转入 `team-fix + ralph fixing`
- `max_fix_loops` 达阈值后强制终态 `Blocked`
- 终态必须输出 reason codes

### FR-355 反馈回写与下一轮注入

- 使用现有 feedback 机制生成：
  - `.ptk/state/requirement-feedback/{version}-{feature}.json`
  - `docs/product/{version}/feedback/{feature}.md|json`
- 下一轮 think/workflow 优先读取并注入 open_questions

### FR-356 可观测与审计

- 统一输出 bridge 级别执行摘要
- 关联 artifacts：team manifest、review-gates、test-session、feedback
- 支持人工追溯每次循环为何 Pass/Blocked

---

## 5. 非功能需求（NFR）

1. 可靠性：桥接状态写入失败需快速失败并给出修复路径
2. 可观测性：所有终态均有结构化 reason codes
3. 安全性：日志、报告、状态文件不得记录明文凭据
4. 可维护性：桥接逻辑与现有 PTK/OMX/OMC 状态契约解耦

---

## 6. 风险与未决问题

## 风险

1. 双状态源风险（`.omx/.omc` 与 `.ptk`）导致一致性问题  
   - 缓解：以 bridge state 记录“权威映射快照”
2. 终态语义不一致风险  
   - 缓解：桥接层统一映射并强制结构化终态
3. fix loop 过长风险  
   - 缓解：沿用 `max_fix_loops` 强制阻断

## 未决问题（非阻塞）

1. OQ-356-01：`runtime=auto` 优先级是否允许项目配置覆盖
2. OQ-356-02：是否需要把 bridge 摘要同步到全局 release 报告

---

## 7. 交付判定（DoD）

1. v3.5.0 文档基线完整（PRD + 用户故事 + 测试用例）
2. bridge 状态映射规则明确且可测试
3. 验证闭环规则明确：未通过不可标记 Pass
4. AC→TC 覆盖矩阵达到 100%
5. 不存在 blocking 未决项
