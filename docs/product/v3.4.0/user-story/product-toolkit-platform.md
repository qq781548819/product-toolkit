# 用户故事：Product Toolkit Platform（v3.4.0）

**状态**: Ready  
**范围**: M1/M2 增量交付

---

## US-341: strict 默认门控

作为产品负责人，我希望默认策略是 strict，这样不合格产物会被阻断而非默许通过。

### 验收标准（7维）

- [ ] AC01 正向：默认 gate 以阻断优先
- [ ] AC02 边界：`--force` 可覆盖但记录风险
- [ ] AC03 错误：缺少关键字段时返回 Blocked
- [ ] AC04 反馈：明确输出 Pass/Blocked
- [ ] AC05 性能：门控检查耗时可接受
- [ ] AC06 权限：风险日志不泄露敏感信息
- [ ] AC07 回退：可切回上一稳定流程配置

## US-342: 统一记忆信封与迁移

作为长期迭代团队，我希望记忆结构统一且可迁移，便于跨会话复用和审计。

### 验收标准（7维）

- [ ] AC01 正向：四类 memory schema 对齐统一字段
- [ ] AC02 边界：旧字段仍可读取
- [ ] AC03 错误：迁移失败可回滚
- [ ] AC04 反馈：dry-run 输出清晰差异
- [ ] AC05 性能：迁移执行稳定
- [ ] AC06 权限：证据引用不暴露敏感数据
- [ ] AC07 回退：支持 `--rollback`

## US-343: auto-test 反馈回写

作为 PM/QA，我希望测试缺口自动回写到 open-questions，以便下一轮需求迭代优先修补。

### 验收标准（7维）

- [ ] AC01 正向：触发条件下自动生成 requirement-feedback
- [ ] AC02 边界：无触发条件不重复生成噪音反馈
- [ ] AC03 错误：生成失败有可观测告警
- [ ] AC04 反馈：产出 state + docs 双落点
- [ ] AC05 性能：反馈生成耗时可控
- [ ] AC06 权限：反馈内容可脱敏共享
- [ ] AC07 回退：可手动重跑 feedback 生成器

## US-344: Team Runtime file/tmux 统一入口

作为协作负责人，我希望团队运行时有统一命令入口，并支持 file/tmux 两种形态。

### 验收标准（7维）

- [ ] AC01 正向：start/status/resume/shutdown 全链路可用
- [ ] AC02 边界：tmux 不可用时可回退 file
- [ ] AC03 错误：缺失 manifest 时有清晰错误
- [ ] AC04 反馈：输出当前 phase 与 worker 状态
- [ ] AC05 性能：状态读写稳定
- [ ] AC06 权限：状态目录不包含敏感凭据
- [ ] AC07 回退：shutdown 后可重新 start

## US-345: 双审查 Gate 与修复循环上限

作为质量负责人，我希望先 spec 再 quality，并在修复循环失控时自动阻断。

### 验收标准（7维）

- [ ] AC01 正向：spec pass 后才能提交 quality
- [ ] AC02 边界：critical/high 未清零 => Blocked
- [ ] AC03 错误：gate 文件缺失时不可误判 Pass
- [ ] AC04 反馈：evaluate 输出 reason codes
- [ ] AC05 性能：评估流程可重复执行
- [ ] AC06 权限：审查证据可追踪
- [ ] AC07 回退：max_fix_loops 达阈值自动 Blocked
