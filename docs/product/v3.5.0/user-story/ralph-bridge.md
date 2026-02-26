# 用户故事：Ralph Bridge（v3.5.0）

**状态**: Ready  
**范围**: OMX/OMC 长任务与 PTK workflow 桥接

---

## US-351: 统一桥接入口

作为交付负责人，我希望有统一桥接入口来驱动 ralph 长任务，这样可以避免手工串联多个命令导致流程失真。

### 验收标准（7维）

- [ ] US351-AC01 正向：支持 `start/resume/status/finalize` 统一入口
- [ ] US351-AC02 边界：明确 `runtime=omx|omc|auto` 选择规则
- [ ] US351-AC03 错误：不支持 runtime 时返回 Blocked + reason code
- [ ] US351-AC04 反馈：输出 bridge session id 与关联 team/session 信息
- [ ] US351-AC05 性能：单次入口调度耗时可接受
- [ ] US351-AC06 权限：日志不暴露敏感凭据
- [ ] US351-AC07 回退：可切回手工执行路径

## US-352: 状态映射与恢复

作为执行负责人，我希望 ralph 状态与 PTK 状态有统一映射，这样可以在中断后恢复执行，不丢失上下文。

### 验收标准（7维）

- [ ] US352-AC01 正向：生成 `.ptk/state/bridge/<team>/ralph-link.json`
- [ ] US352-AC02 边界：支持 session-scoped 与 root-scoped 状态读取
- [ ] US352-AC03 错误：桥接状态损坏时阻断并给出修复指引
- [ ] US352-AC04 反馈：status 可展示 phase 映射与终态候选
- [ ] US352-AC05 性能：恢复流程稳定且可重复
- [ ] US352-AC06 权限：状态文件不含明文凭据
- [ ] US352-AC07 回退：可重建 bridge state 并继续执行

## US-353: 验证闭环编排

作为 QA 负责人，我希望在 verify 阶段自动执行 `auto-test + review_gate + team_report`，确保“完成”是可验证的，不是口头完成。

### 验收标准（7维）

- [ ] US353-AC01 正向：verify 阶段按顺序触发三类验证
- [ ] US353-AC02 边界：任一验证 Blocked 则整体 Blocked
- [ ] US353-AC03 错误：执行失败可定位到具体验证步骤
- [ ] US353-AC04 反馈：输出结构化验证结果与 reason codes
- [ ] US353-AC05 性能：验证步骤可在可接受时长内完成
- [ ] US353-AC06 权限：验证产物可审计且脱敏
- [ ] US353-AC07 回退：失败后可回到 fix loop 重试

## US-354: 失败回环与终态语义一致

作为团队负责人，我希望 Blocked/Fail 能自动回到 `team-fix + ralph fixing`，并在达到上限时正确终态阻断。

### 验收标准（7维）

- [ ] US354-AC01 正向：verify 未通过时自动转入 fix loop
- [ ] US354-AC02 边界：`max_fix_loops` 达上限后终态 Blocked
- [ ] US354-AC03 错误：终态冲突（例如双终态）被拦截
- [ ] US354-AC04 反馈：终态输出包含 `terminal_status + reason_codes`
- [ ] US354-AC05 性能：循环调度过程稳定
- [ ] US354-AC06 权限：终态记录可追踪且可审计
- [ ] US354-AC07 回退：允许人工 `cancel` 并安全退出

## US-355: 反馈回写与下一轮注入

作为产品经理，我希望测试缺口自动回写并注入下一轮 think/workflow，使长任务形成真正闭环。

### 验收标准（7维）

- [ ] US355-AC01 正向：触发条件满足时自动生成 requirement-feedback
- [ ] US355-AC02 边界：无缺口时不生成噪音反馈
- [ ] US355-AC03 错误：反馈生成失败可观测且不误判 Pass
- [ ] US355-AC04 反馈：next-think/workflow 可读取并注入 open_questions
- [ ] US355-AC05 性能：反馈生成与注入开销可控
- [ ] US355-AC06 权限：反馈内容符合脱敏要求
- [ ] US355-AC07 回退：支持手动重放反馈产物

---

## 冲突与未决

- 冲突：无 `critical/high` 未解决冲突
- 未决（非阻塞）：
  - OQ-355-01：`runtime=auto` 的默认优先级是否允许项目级覆盖（建议支持）
  - OQ-355-02：Bridge 报告是否需要统一汇总到 `docs/product/feedback` 顶层索引

## 交付语义

- Blocked 原因：当前无阻塞项
- Warn 风险：存在 2 项非阻塞未决，进入实现阶段需同步确认
