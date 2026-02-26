# 测试进度记录: {version}

**Session ID**: {session_id}  
**功能**: {feature}  
**测试类型**: {test_type}  
**工具**: {tool}  
**生命周期模型**: start → record → stop → consolidate

---

## 1) Lifecycle Timeline

| 阶段 | 时间 | 说明 |
|---|---|---|
| start | {started_at} | 初始化会话、加载历史记忆、构建 US→TC 执行计划 |
| record | {during} | 按顺序执行并记录 case/step/fix 事件 |
| stop | {stopped_at} | 生成本轮覆盖率、缺口、结果总结 |
| consolidate | {consolidated_at} | 合并 signature/playbook/session 到测试记忆体 |

---

## 2) US → TC 顺序执行矩阵

| 顺序 | 用户故事 | 测试用例 | 执行方式 | Method | 期望 | 状态 | 备注 |
|---:|---|---|---|---|---|---|---|
| 1 | US-001 | TC-XXX | agent-browser/manual/api | GET/POST/... | success/error | Pass/Fail/Blocked/Pending | {note} |

---

## 3) 覆盖率

| 维度 | 结果 |
|---|---|
| US 覆盖 | {us_executed}/{us_total}（通过 {us_passed}） |
| TC 覆盖 | {tc_executed}/{tc_total}（Pass {tc_passed} / Fail {tc_failed} / Blocked {tc_blocked}） |
| AC 覆盖 | {ac_covered}/{ac_total} |

---

## 4) US 完整性矩阵（严格）

| US | 声明用例数 | 计划用例数 | 已执行 | 通过 | 失败 | 阻塞 | 待执行 |
|---|---:|---:|---:|---:|---:|---:|---:|
| US-001 | 5 | 5 | 5 | 5 | 0 | 0 | 0 |

---

## 5) 执行方式覆盖

| 执行方式 | 计划 | 已执行 | 通过 | 失败 | 阻塞 |
|---|---:|---:|---:|---:|---:|
| agent-browser | 35 | 35 | 34 | 1 | 0 |
| manual | 18 | 0 | 0 | 0 | 18 |
| api | 5 | 0 | 0 | 0 | 5 |

---

## 6) 缺口与阻塞

- 缺失用户故事映射: {missing_user_stories}
- 缺失测试用例的 US: {missing_test_cases}
- 未执行用例: {unexecuted_test_cases}
- 阻塞用例: {blocked_test_cases}
- 阻塞原因分布: {blocked_reason_counts}
- 阻塞原因代码列表: {blocked_reason_codes}
- 非当前工具可自动执行用例: {non_automatable_test_cases}
- 声明/解析数量不一致: {declared_count_mismatches}

---

## 7) Strict Gate

- declared_vs_parsed_match: {declared_vs_parsed_match}
- suspicious_one_to_one: {suspicious_one_to_one}
- us_completeness_passed: {us_completeness_passed}
- non_automatable_pending: {non_automatable_pending}
- completeness_passed: {completeness_passed}

---

## 8) 失败→修复→复测链路

### {case_id}
- signature: `{signature}`
- 失败原因: {reason}
- 复用 playbook: {playbook_name}
- 复测结果: Pass/Fail/Blocked
- 关联用户故事: {us_id}
- 修复建议: {suggestion}

---

## 9) Memory Delta（本轮记忆增量）

- 新增 signatures: {new_signatures}
- 更新 signatures: {updated_signatures}
- 复用 playbook 次数: {playbook_reused}
- 重复坑拦截次数: {repeat_guard_triggered}

---

## 10) 自迭代建议

- 需补充用户故事: {todo_user_stories}
- 需补充测试用例: {todo_test_cases}
- 下轮优先回归 signature: {priority_signatures}
