# QA Standards Playbook（对齐国际流程）

> 目标：将 Product Toolkit 自动化测试（UI/API/Manual）对齐主流标准流程，形成可审计的测试闭环。

## 1) 标准流程骨架（建议落地顺序）

1. Test Planning（范围/风险/退出准则）
2. Test Monitoring & Control（过程度量/偏差纠正）
3. Test Analysis / Design（US->TC->AC 可追踪）
4. Test Implementation（环境/数据/工具准备）
5. Test Execution（UI/API/Manual 并行执行）
6. Test Completion（缺陷复盘/回归与经验沉淀）

## 2) Product Toolkit 映射

- Planning: `think -> user-story -> test-case`
- Implementation: `auto-test`（构建 US→TC 执行计划）
- Execution:
  - UI: `agent-browser/browser-use`
  - API: `run_api_case`（method + expectation）
  - Manual: `--manual-results` 回填
- Completion:
  - `.ptk/state/test-sessions/*.json`
  - `docs/product/{version}/qa/test-progress/*.md|json`
  - `.ptk/memory/test-learnings.json`

## 3) 严格门禁（建议）

- 0 case -> Blocked
- 声明用例数 != 解析用例数 -> Blocked
- 任一 US 存在 blocked/failed/pending TC -> Blocked
- API expectation 不明确（默认）-> Blocked
- Manual 未回填 -> Blocked

## 4) 建议增加的 QA 深挖项

1. 缺陷优先级模型：Severity x Priority（P0/P1/P2）
2. 风险驱动回归集：按业务影响与变更热度动态排序
3. API 契约回归：OpenAPI/JSON Schema 校验 + 错误码断言
4. 非功能测试：性能阈值、稳定性、可观测性（日志/追踪）
5. 安全测试：OWASP WSTG 关键用例纳入回归
6. 退出准则：必须满足 `strict.completeness_passed=true`

## 4.1) Team Runtime 验证项（v3.4.0 新增）

1. `team_runtime.sh start/status/resume/shutdown` 在 file runtime 全链路可复现
2. `--runtime tmux` 与 file runtime 共用同一状态目录并可恢复
3. `review_gate.sh` 强制 `spec -> quality` 顺序
4. critical/high 未清零时，`evaluation.status` 必须为 `Blocked`
5. `max_fix_loops` 达阈值后，manifest 终态必须 `terminal + Blocked`
6. `team_report.sh` 需输出阶段历史、阻塞原因、终态结论（md/json）

## 5) 参考标准（官方链接）

- ISTQB CTFL 4.0 Syllabus（测试过程与追踪）  
  https://istqb-main-web-prod.s3.eu-west-1.amazonaws.com/media/documents/ISTQB_CTFL_v4.0_Syllabus.pdf
- ISO/IEC/IEEE 29119-2（测试过程）  
  https://www.iso.org/standard/45142.html
- ISO/IEC/IEEE 29119-3（测试文档）  
  https://www.iso.org/standard/45143.html
- NIST SP 800-218 (SSDF)（开发生命周期验证要求）  
  https://csrc.nist.gov/pubs/sp/800/218/final
- NISTIR 8397（最小验证技术）  
  https://csrc.nist.gov/pubs/ir/8397/final
- OWASP WSTG（Web 安全测试）  
  https://owasp.org/www-project-web-security-testing-guide/
