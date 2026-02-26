# PRD: Product Toolkit Platform

**状态**: In Review  
**版本**: v3.3.0  
**来源**: think_vnext（基于现有能力梳理）

---

## 1. 背景与目标

### 背景

Product Toolkit 已覆盖 PM 工作流主要阶段，但仍需要统一“规则契约 + 可追踪输出 + 严格测试闭环”的产品化定义，降低跨会话断层与文档不一致问题。

### 目标

1. 建立统一的需求到交付链路：`think → user-story → prd → test-case → auto-test → test-progress`
2. 保证输出可追踪、可复用、可审计
3. 支持严格 QA 闭环，避免重复踩坑

### 成功指标（KPI）

1. 工作流主链路一次产物完整率 ≥ 95%
2. AC→TC 覆盖率目标 100%
3. 自动化测试重复问题触发率逐轮下降（memory 生效）
4. 文档落盘完整率（版本目录）= 100%

---

## 2. 用户与价值

### 目标用户

1. 产品经理（单人或团队）
2. 研发负责人 / Tech Lead
3. QA 工程师
4. AI 协作工程流用户（Claude/Codex）

### 核心价值

1. 用统一契约消除“想法-文档-测试”断层
2. 把“可读文档 + 机读状态 + 测试记忆”打通
3. 让迭代具备可复盘、可验证的工程闭环

---

## 3. 范围定义

### In Scope

1. think vNext 硬切契约落地
2. user-story/prd/test-case 文档标准化输出
3. workflow 串联与 Soft-Gate 门控
4. auto-test 严格执行（UI/API/Manual）
5. test-progress 会话化汇总与缺口回填
6. .ptk 持久化状态与测试记忆体

### Out of Scope

1. 云端多租户 SaaS 控制台
2. 外部缺陷平台深度双向同步（Jira/禅道）
3. 大规模实时多人协同编辑引擎

---

## 4. 功能需求

### FR-001 think vNext 规则引擎（契约层）

1. 批量提问 + 动态追问
2. 冲突检测（语义/边界/目标/约束）
3. 每轮自动摘要
4. open questions ledger 输出

### FR-002 用户故事生成

1. 从 think 契约映射到用户故事
2. 强制输出 7 维 AC
3. Block/Warn 判定语义

### FR-003 PRD 生成

1. 统一 PRD 章节结构（范围、流程、NFR、风险）
2. 强制记录 conflicts/open questions
3. 阻塞项存在时状态必须 Blocked

### FR-004 测试用例生成

1. AC→TC 覆盖矩阵
2. 用例分层（smoke/regression/full）
3. Pass/Fail/Blocked 统一语义

### FR-005 一键工作流编排

1. 从 think 到 release 的串联
2. 阶段门控与状态可视化
3. 输出目录按版本组织

### FR-006 状态持久化与记忆体

1. .ptk/state 保存会话状态
2. .ptk/memory 保存洞察、决策、测试踩坑
3. save/resume 跨会话恢复

### FR-007 自动化测试 strict 引擎

1. start→record→stop→consolidate 生命周期
2. 支持 UI/API/Manual 混合用例
3. 输出会话报告与阻塞原因分布
4. 失败 signature / playbook 复用

### FR-008 测试进度与复盘

1. 产出 test-progress.md + session 明细
2. 追踪 missing US / missing TC / blocked reasons
3. 支持版本回填与趋势比较

---

## 5. 主流程（Happy Path）

1. 用户执行 `/product-toolkit:think` 产出契约化结论
2. 生成用户故事并落盘
3. 生成 PRD 并完成风险登记
4. 生成测试用例与 AC→TC 覆盖矩阵
5. 运行 auto-test 并生成 test-progress
6. 根据 gaps 回填文档与下一轮计划

---

## 6. 边界与异常

### 边界规则

1. 无有效 case 时禁止“伪通过”
2. US↔TC 可疑 1:1（在多 US 场景）需触发严格告警
3. Manual/API 未闭环时不得给出完整通过结论（除非明确回填）

### 异常处理

1. 前端不可达：给出可执行修复建议
2. API 占位符未替换：标记阻塞并要求 `--api-vars`
3. Manual 未回填：标记 `manual_result_missing`

### 成功反馈

1. 输出会话级摘要（passed/failed/blocked）
2. 输出阻塞原因分布与可执行下一步
3. 生成可读 + 机读双产物

---

## 7. 非功能需求

### 性能与稳定性

1. 典型 50+ 用例运行流程需稳定完成
2. 错误信息需可定位到 case_id 与证据文件

### 安全与权限

1. 默认不在文档保存明文凭据
2. 敏感参数通过外部传入与脱敏记录

### 可审计性

1. 关键状态变更需有会话记录
2. 支持从 test-progress 追溯到 session 原始明细

---

## 8. 数据与产物

### 核心状态目录

1. `.ptk/state/`：workflow/test 进度
2. `.ptk/memory/`：signatures/playbooks/sessions
3. `docs/product/{version}/`：PRD/US/TC/QA 报告

### 必要产物

1. PRD 文档
2. 用户故事文档
3. 测试用例文档
4. test-progress 详情与汇总
5. strict gate 判定结果

---

## 9. 发布与回滚

### 发布策略

1. 先发布文档契约，再发布脚本行为
2. 重大变更以 Hard Switch 公告
3. 新增字段保持 schema 向后兼容

### 回滚策略

1. 保留旧版文档与归档目录
2. 脚本参数保持向后兼容开关
3. 问题版本可回切到上一稳定标签

---

## 10. 风险与未决问题

### conflicts

1. `medium`：manual 回填容易被“机械通过”滥用，需抽样复核制度
2. `medium`：API expectation 推断存在误判风险，需逐步引入 case-level config

### open questions

1. 是否引入“manual 回填审批态”（pending-review/approved）
2. 是否将 API 断言升级为 schema/业务码双层校验
3. 是否在 workflow 内置“失败自动派单”接口

---

## 11. 交付判定

### Ready 条件

1. 用户故事与 PRD 字段齐全
2. AC→TC 覆盖矩阵完整
3. strict gate 规则定义明确
4. 文档目录与输出路径一致

### Blocked 条件

1. 关键契约字段缺失
2. 存在 blocking open question 未关闭
3. 关键流程无可执行测试链路
