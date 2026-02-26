# 测试用例：Product Toolkit Platform（v3.3.0）

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
| US-001 | 6 | 1 | 5 |
| US-002 | 6 | 1 | 5 |
| US-003 | 6 | 1 | 5 |
| US-004 | 6 | 1 | 5 |
| US-005 | 6 | 1 | 5 |
| US-006 | 6 | 1 | 5 |
| US-007 | 6 | 1 | 5 |
| US-008 | 6 | 1 | 5 |
| US-009 | 6 | 1 | 5 |
| US-010 | 6 | 1 | 5 |
| **总计** | **60** | **10** | **50** |

---

## 用例清单（按用户故事）

| TC ID | US | 类型 | 场景 | 关键检查点 | 覆盖 AC | 执行方式 |
|---|---|---|---|---|---|---|
| SMK-US001-01 | US-001 | 冒烟 | think vNext 需求澄清-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US001-AC01+AC04 | manual |
| TC-US001-02 | US-001 | 边界 | think vNext 需求澄清-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US001-AC02 | manual |
| TC-US001-03 | US-001 | 异常 | think vNext 需求澄清-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US001-AC03 | manual |
| TC-US001-04 | US-001 | 性能 | think vNext 需求澄清-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US001-AC05 | manual |
| TC-US001-05 | US-001 | 权限 | think vNext 需求澄清-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US001-AC06 | manual |
| TC-US001-06 | US-001 | 回滚 | think vNext 需求澄清-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US001-AC07 | manual |
| SMK-US002-01 | US-002 | 冒烟 | 用户故事生成-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US002-AC01+AC04 | manual |
| TC-US002-02 | US-002 | 边界 | 用户故事生成-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US002-AC02 | manual |
| TC-US002-03 | US-002 | 异常 | 用户故事生成-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US002-AC03 | manual |
| TC-US002-04 | US-002 | 性能 | 用户故事生成-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US002-AC05 | manual |
| TC-US002-05 | US-002 | 权限 | 用户故事生成-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US002-AC06 | manual |
| TC-US002-06 | US-002 | 回滚 | 用户故事生成-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US002-AC07 | manual |
| SMK-US003-01 | US-003 | 冒烟 | PRD 生成-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US003-AC01+AC04 | manual |
| TC-US003-02 | US-003 | 边界 | PRD 生成-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US003-AC02 | manual |
| TC-US003-03 | US-003 | 异常 | PRD 生成-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US003-AC03 | manual |
| TC-US003-04 | US-003 | 性能 | PRD 生成-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US003-AC05 | manual |
| TC-US003-05 | US-003 | 权限 | PRD 生成-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US003-AC06 | manual |
| TC-US003-06 | US-003 | 回滚 | PRD 生成-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US003-AC07 | manual |
| SMK-US004-01 | US-004 | 冒烟 | 测试用例生成与 AC→TC 映射-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US004-AC01+AC04 | manual |
| TC-US004-02 | US-004 | 边界 | 测试用例生成与 AC→TC 映射-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US004-AC02 | manual |
| TC-US004-03 | US-004 | 异常 | 测试用例生成与 AC→TC 映射-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US004-AC03 | manual |
| TC-US004-04 | US-004 | 性能 | 测试用例生成与 AC→TC 映射-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US004-AC05 | manual |
| TC-US004-05 | US-004 | 权限 | 测试用例生成与 AC→TC 映射-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US004-AC06 | manual |
| TC-US004-06 | US-004 | 回滚 | 测试用例生成与 AC→TC 映射-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US004-AC07 | manual |
| SMK-US005-01 | US-005 | 冒烟 | workflow 串联与门控-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US005-AC01+AC04 | manual |
| TC-US005-02 | US-005 | 边界 | workflow 串联与门控-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US005-AC02 | manual |
| TC-US005-03 | US-005 | 异常 | workflow 串联与门控-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US005-AC03 | manual |
| TC-US005-04 | US-005 | 性能 | workflow 串联与门控-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US005-AC05 | manual |
| TC-US005-05 | US-005 | 权限 | workflow 串联与门控-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US005-AC06 | manual |
| TC-US005-06 | US-005 | 回滚 | workflow 串联与门控-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US005-AC07 | manual |
| SMK-US006-01 | US-006 | 冒烟 | 状态持久化与 save/resume-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US006-AC01+AC04 | manual |
| TC-US006-02 | US-006 | 边界 | 状态持久化与 save/resume-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US006-AC02 | manual |
| TC-US006-03 | US-006 | 异常 | 状态持久化与 save/resume-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US006-AC03 | manual |
| TC-US006-04 | US-006 | 性能 | 状态持久化与 save/resume-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US006-AC05 | manual |
| TC-US006-05 | US-006 | 权限 | 状态持久化与 save/resume-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US006-AC06 | manual |
| TC-US006-06 | US-006 | 回滚 | 状态持久化与 save/resume-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US006-AC07 | manual |
| SMK-US007-01 | US-007 | 冒烟 | 记忆系统（remember/recall/test-learnings）-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US007-AC01+AC04 | manual |
| TC-US007-02 | US-007 | 边界 | 记忆系统（remember/recall/test-learnings）-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US007-AC02 | manual |
| TC-US007-03 | US-007 | 异常 | 记忆系统（remember/recall/test-learnings）-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US007-AC03 | manual |
| TC-US007-04 | US-007 | 性能 | 记忆系统（remember/recall/test-learnings）-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US007-AC05 | manual |
| TC-US007-05 | US-007 | 权限 | 记忆系统（remember/recall/test-learnings）-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US007-AC06 | manual |
| TC-US007-06 | US-007 | 回滚 | 记忆系统（remember/recall/test-learnings）-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US007-AC07 | manual |
| SMK-US008-01 | US-008 | 冒烟 | 自动化测试 strict 生命周期-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US008-AC01+AC04 | manual |
| TC-US008-02 | US-008 | 边界 | 自动化测试 strict 生命周期-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US008-AC02 | manual |
| TC-US008-03 | US-008 | 异常 | 自动化测试 strict 生命周期-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US008-AC03 | manual |
| TC-US008-04 | US-008 | 性能 | 自动化测试 strict 生命周期-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US008-AC05 | manual |
| TC-US008-05 | US-008 | 权限 | 自动化测试 strict 生命周期-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US008-AC06 | manual |
| TC-US008-06 | US-008 | 回滚 | 自动化测试 strict 生命周期-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US008-AC07 | manual |
| SMK-US009-01 | US-009 | 冒烟 | test-progress 汇总与缺口回填-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US009-AC01+AC04 | manual |
| TC-US009-02 | US-009 | 边界 | test-progress 汇总与缺口回填-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US009-AC02 | manual |
| TC-US009-03 | US-009 | 异常 | test-progress 汇总与缺口回填-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US009-AC03 | manual |
| TC-US009-04 | US-009 | 性能 | test-progress 汇总与缺口回填-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US009-AC05 | manual |
| TC-US009-05 | US-009 | 权限 | test-progress 汇总与缺口回填-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US009-AC06 | manual |
| TC-US009-06 | US-009 | 回滚 | test-progress 汇总与缺口回填-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US009-AC07 | manual |
| SMK-US010-01 | US-010 | 冒烟 | 版本演进与发布检查-主流程关键路径校验（含成功反馈） | 输出契约、状态语义、可追踪产物 | US010-AC01+AC04 | manual |
| TC-US010-02 | US-010 | 边界 | 版本演进与发布检查-边界/约束校验 | 输出契约、状态语义、可追踪产物 | US010-AC02 | manual |
| TC-US010-03 | US-010 | 异常 | 版本演进与发布检查-异常与失败模式校验 | 输出契约、状态语义、可追踪产物 | US010-AC03 | manual |
| TC-US010-04 | US-010 | 性能 | 版本演进与发布检查-性能与稳定性目标校验 | 输出契约、状态语义、可追踪产物 | US010-AC05 | manual |
| TC-US010-05 | US-010 | 权限 | 版本演进与发布检查-权限/安全校验 | 输出契约、状态语义、可追踪产物 | US010-AC06 | manual |
| TC-US010-06 | US-010 | 回滚 | 版本演进与发布检查-撤销/回退/恢复校验 | 输出契约、状态语义、可追踪产物 | US010-AC07 | manual |

> 说明：`SMK-*` 用于发布前冒烟门禁，`TC-*` 用于回归与全量验证。

---

## AC→TC 覆盖矩阵（完整）

| US | AC-ID | AC 描述 | TC-ID | 覆盖状态 |
|---|---|---|---|---|
| US-001 | US001-AC01 | think vNext 需求澄清-正向流程 | SMK-US001-01 | Covered |
| US-001 | US001-AC02 | think vNext 需求澄清-边界校验 | TC-US001-02 | Covered |
| US-001 | US001-AC03 | think vNext 需求澄清-错误处理 | TC-US001-03 | Covered |
| US-001 | US001-AC04 | think vNext 需求澄清-成功反馈 | SMK-US001-01 | Covered |
| US-001 | US001-AC05 | think vNext 需求澄清-性能要求 | TC-US001-04 | Covered |
| US-001 | US001-AC06 | think vNext 需求澄清-权限控制 | TC-US001-05 | Covered |
| US-001 | US001-AC07 | think vNext 需求澄清-撤销回退 | TC-US001-06 | Covered |
| US-002 | US002-AC01 | 用户故事生成-正向流程 | SMK-US002-01 | Covered |
| US-002 | US002-AC02 | 用户故事生成-边界校验 | TC-US002-02 | Covered |
| US-002 | US002-AC03 | 用户故事生成-错误处理 | TC-US002-03 | Covered |
| US-002 | US002-AC04 | 用户故事生成-成功反馈 | SMK-US002-01 | Covered |
| US-002 | US002-AC05 | 用户故事生成-性能要求 | TC-US002-04 | Covered |
| US-002 | US002-AC06 | 用户故事生成-权限控制 | TC-US002-05 | Covered |
| US-002 | US002-AC07 | 用户故事生成-撤销回退 | TC-US002-06 | Covered |
| US-003 | US003-AC01 | PRD 生成-正向流程 | SMK-US003-01 | Covered |
| US-003 | US003-AC02 | PRD 生成-边界校验 | TC-US003-02 | Covered |
| US-003 | US003-AC03 | PRD 生成-错误处理 | TC-US003-03 | Covered |
| US-003 | US003-AC04 | PRD 生成-成功反馈 | SMK-US003-01 | Covered |
| US-003 | US003-AC05 | PRD 生成-性能要求 | TC-US003-04 | Covered |
| US-003 | US003-AC06 | PRD 生成-权限控制 | TC-US003-05 | Covered |
| US-003 | US003-AC07 | PRD 生成-撤销回退 | TC-US003-06 | Covered |
| US-004 | US004-AC01 | 测试用例生成与 AC→TC 映射-正向流程 | SMK-US004-01 | Covered |
| US-004 | US004-AC02 | 测试用例生成与 AC→TC 映射-边界校验 | TC-US004-02 | Covered |
| US-004 | US004-AC03 | 测试用例生成与 AC→TC 映射-错误处理 | TC-US004-03 | Covered |
| US-004 | US004-AC04 | 测试用例生成与 AC→TC 映射-成功反馈 | SMK-US004-01 | Covered |
| US-004 | US004-AC05 | 测试用例生成与 AC→TC 映射-性能要求 | TC-US004-04 | Covered |
| US-004 | US004-AC06 | 测试用例生成与 AC→TC 映射-权限控制 | TC-US004-05 | Covered |
| US-004 | US004-AC07 | 测试用例生成与 AC→TC 映射-撤销回退 | TC-US004-06 | Covered |
| US-005 | US005-AC01 | workflow 串联与门控-正向流程 | SMK-US005-01 | Covered |
| US-005 | US005-AC02 | workflow 串联与门控-边界校验 | TC-US005-02 | Covered |
| US-005 | US005-AC03 | workflow 串联与门控-错误处理 | TC-US005-03 | Covered |
| US-005 | US005-AC04 | workflow 串联与门控-成功反馈 | SMK-US005-01 | Covered |
| US-005 | US005-AC05 | workflow 串联与门控-性能要求 | TC-US005-04 | Covered |
| US-005 | US005-AC06 | workflow 串联与门控-权限控制 | TC-US005-05 | Covered |
| US-005 | US005-AC07 | workflow 串联与门控-撤销回退 | TC-US005-06 | Covered |
| US-006 | US006-AC01 | 状态持久化与 save/resume-正向流程 | SMK-US006-01 | Covered |
| US-006 | US006-AC02 | 状态持久化与 save/resume-边界校验 | TC-US006-02 | Covered |
| US-006 | US006-AC03 | 状态持久化与 save/resume-错误处理 | TC-US006-03 | Covered |
| US-006 | US006-AC04 | 状态持久化与 save/resume-成功反馈 | SMK-US006-01 | Covered |
| US-006 | US006-AC05 | 状态持久化与 save/resume-性能要求 | TC-US006-04 | Covered |
| US-006 | US006-AC06 | 状态持久化与 save/resume-权限控制 | TC-US006-05 | Covered |
| US-006 | US006-AC07 | 状态持久化与 save/resume-撤销回退 | TC-US006-06 | Covered |
| US-007 | US007-AC01 | 记忆系统（remember/recall/test-learnings）-正向流程 | SMK-US007-01 | Covered |
| US-007 | US007-AC02 | 记忆系统（remember/recall/test-learnings）-边界校验 | TC-US007-02 | Covered |
| US-007 | US007-AC03 | 记忆系统（remember/recall/test-learnings）-错误处理 | TC-US007-03 | Covered |
| US-007 | US007-AC04 | 记忆系统（remember/recall/test-learnings）-成功反馈 | SMK-US007-01 | Covered |
| US-007 | US007-AC05 | 记忆系统（remember/recall/test-learnings）-性能要求 | TC-US007-04 | Covered |
| US-007 | US007-AC06 | 记忆系统（remember/recall/test-learnings）-权限控制 | TC-US007-05 | Covered |
| US-007 | US007-AC07 | 记忆系统（remember/recall/test-learnings）-撤销回退 | TC-US007-06 | Covered |
| US-008 | US008-AC01 | 自动化测试 strict 生命周期-正向流程 | SMK-US008-01 | Covered |
| US-008 | US008-AC02 | 自动化测试 strict 生命周期-边界校验 | TC-US008-02 | Covered |
| US-008 | US008-AC03 | 自动化测试 strict 生命周期-错误处理 | TC-US008-03 | Covered |
| US-008 | US008-AC04 | 自动化测试 strict 生命周期-成功反馈 | SMK-US008-01 | Covered |
| US-008 | US008-AC05 | 自动化测试 strict 生命周期-性能要求 | TC-US008-04 | Covered |
| US-008 | US008-AC06 | 自动化测试 strict 生命周期-权限控制 | TC-US008-05 | Covered |
| US-008 | US008-AC07 | 自动化测试 strict 生命周期-撤销回退 | TC-US008-06 | Covered |
| US-009 | US009-AC01 | test-progress 汇总与缺口回填-正向流程 | SMK-US009-01 | Covered |
| US-009 | US009-AC02 | test-progress 汇总与缺口回填-边界校验 | TC-US009-02 | Covered |
| US-009 | US009-AC03 | test-progress 汇总与缺口回填-错误处理 | TC-US009-03 | Covered |
| US-009 | US009-AC04 | test-progress 汇总与缺口回填-成功反馈 | SMK-US009-01 | Covered |
| US-009 | US009-AC05 | test-progress 汇总与缺口回填-性能要求 | TC-US009-04 | Covered |
| US-009 | US009-AC06 | test-progress 汇总与缺口回填-权限控制 | TC-US009-05 | Covered |
| US-009 | US009-AC07 | test-progress 汇总与缺口回填-撤销回退 | TC-US009-06 | Covered |
| US-010 | US010-AC01 | 版本演进与发布检查-正向流程 | SMK-US010-01 | Covered |
| US-010 | US010-AC02 | 版本演进与发布检查-边界校验 | TC-US010-02 | Covered |
| US-010 | US010-AC03 | 版本演进与发布检查-错误处理 | TC-US010-03 | Covered |
| US-010 | US010-AC04 | 版本演进与发布检查-成功反馈 | SMK-US010-01 | Covered |
| US-010 | US010-AC05 | 版本演进与发布检查-性能要求 | TC-US010-04 | Covered |
| US-010 | US010-AC06 | 版本演进与发布检查-权限控制 | TC-US010-05 | Covered |
| US-010 | US010-AC07 | 版本演进与发布检查-撤销回退 | TC-US010-06 | Covered |

---

## 风险与未决

- Warn-01: manual 回填可能被机械通过，需抽样复核机制
- Warn-02: API 断言目前多为 HTTP 级，后续需补业务码/schema 双层断言

## 执行策略（建议）

1. 每次版本发布前至少执行全量 Smoke
2. 高风险模块（US-008/US-009）必须执行 full 回归
3. strict gate 不通过时禁止标记 Ready
4. 执行后必须输出 test-progress 与 session 明细
