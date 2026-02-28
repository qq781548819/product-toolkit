---
name: product-toolkit
description: Product toolkit for PM workflows (think/user-story/prd/test-case/workflow etc.) with think vNext hard-switch rules.
---

# Product Toolkit v3.7.0

提供产品经理工作流工具集：需求澄清、用户故事、PRD、测试用例、技术方案与发布清单。

## 🚨 Hard Switch 声明（2026-02-25）

本版本对 `/product-toolkit:think` 执行**规则先行硬切换**：

1. 旧版"固定轮次 / 固定题数 / 固定题库"语义**退场**。
2. 采用 `think vNext`：**批量交互 + 上下文动态追问 + 冲突检测 + 每轮自动摘要 + 未决问题清单（ledger）**。
3. 下游 `user-story / prd / test-case / workflow` 按新契约消费输出。
4. 本次仅定义**规则与文档契约**，不包含行为引擎实现。

## ✅ v3.7.0 主路径声明（2026-02-28）

1. 默认入口保持：`/product-toolkit:workflow`（`/product-toolkit:work` 别名）。
2. workflow 核心产物链聚焦：`think → user-story → prd → test-case`。
3. 不新增用户操作命令。
4. workflow 完成后提供 OMC/OMX 下一步固定提示词模板（见 `docs/product/v3.6.0/execution/next-step-prompts.md`）。
5. 新增架构治理产物：`docs/product/{version}/architecture/*.md`（system-context / responsibility / contracts / nfr / adr）。
6. 新增证据加固产物：`raw-command-log.jsonl`、`evidence-manifest.json`、`gate-consistency-report.json`。
7. workflow 在终态写入后默认执行 `scripts/workflow_gate_autorun.sh` 自动收口（先一致性、再 manifest、最后 terminal 校验）。
8. gate 可使用 `scripts/validate_terminal_artifacts.py`（或 `scripts/check_terminal_artifacts.sh`）执行终态证据强校验（含架构治理项与一致性校验）。
9. OMC/OMX 为可选执行器，非入侵 PTK 生命周期规划职责。
10. `ralph-bridge` 保留为兼容/高级路径，不再作为默认主入口。
11. 版本元信息强一致：CLI 版本、插件版本、文档版本必须同步；不允许漂移。

---

## 关键词触发（ptk 前缀）

使用 `ptk` 前缀触发技能，避免与日常用语冲突：

> 说明：`ptk ...` 属于**对话层魔法关键词**，不是 shell 命令。  
> 在 Bash 工具中请执行实际脚本（如 `./scripts/auto_test.sh ...`），不要执行 `ptk ...`。

| 关键词 | 技能 | 说明 |
|--------|------|------|
| **基础技能** | | |
| `ptk think` | `/product-toolkit:think` | 产品思考 vNext |
| `ptk work` | `/product-toolkit:work` | 一键工作流（workflow 别名） |
| `ptk workflow` | `/product-toolkit:workflow` | 一键工作流 |
| `ptk save` | `/product-toolkit:save` | 保存会话 |
| `ptk resume` | `/product-toolkit:resume` | 恢复会话 |
| **测试相关** | | |
| `ptk auto-test` | `/product-toolkit:auto-test` | 自动化测试 |
| `ptk 自动测试` | `/product-toolkit:auto-test` | 自动化测试（中文） |
| `ptk test-case` | `/product-toolkit:test-case` | 生成测试用例 |
| `ptk 测试用例` | `/product-toolkit:test-case` | 生成测试用例（中文） |
| `ptk test-progress` | `/product-toolkit:test-progress` | 测试进度 |
| `ptk 冒烟` | `/product-toolkit:auto-test -t smoke` | 冒烟测试 |
| `ptk smoke` | `/product-toolkit:auto-test -t smoke` | 冒烟测试 |
| **需求相关** | | |
| `ptk user-story` | `/product-toolkit:user-story` | 用户故事 |
| `ptk 用户故事` | `/product-toolkit:user-story` | 用户故事（中文） |
| `ptk prd` | `/product-toolkit:prd` | 产品需求文档 |
| `ptk 需求` | `/product-toolkit:prd` | 产品需求文档（中文） |
| **其他技能** | | |
| `ptk gate` | `/product-toolkit:gate` | 门控检查 |
| `ptk status` | `/product-toolkit:status` | 状态面板 |
| `ptk ralph-bridge` | `/product-toolkit:ralph-bridge` | Ralph 长任务桥接（兼容路径） |
| `ptk remember` | `/product-toolkit:remember` | 记忆知识 |
| `ptk recall` | `/product-toolkit:recall` | 检索记忆 |
| `ptk version` | `/product-toolkit:version` | 版本规划 |
| `ptk roadmap` | `/product-toolkit:roadmap` | 产品路线图 |
| `ptk persona` | `/product-toolkit:persona` | 用户画像 |
| `ptk analyze` | `/product-toolkit:analyze` | 竞品分析 |
| `ptk release` | `/product-toolkit:release` | 发布检查 |

**触发规则：**
- 显式调用 `/product-toolkit:xxx` 优先于关键词触发
- 关键词检测不区分大小写
- 多个关键词匹配时，使用最长匹配

---

## 子命令

| 子命令 | 说明 | 示例 |
|---|---|---|
| `/product-toolkit:init` | 初始化产品文档目录与配置 | `/product-toolkit:init` |
| `/product-toolkit:think [问题]` | 产品思考 vNext（批量+动态追问+冲突检测） | `/product-toolkit:think 我想做社区点赞功能` |
| `/product-toolkit:brainstorm [主题]` | 发散思维探索 | `/product-toolkit:brainstorm 在线教育平台` |
| `/product-toolkit:design [主题]` | Design Thinking | `/product-toolkit:design 支付功能` |
| `/product-toolkit:jtbd [主题]` | JTBD 分析 | `/product-toolkit:jtbd 外卖订餐` |
| `/product-toolkit:version [主题]` | 版本规划 | `/product-toolkit:version 电商收藏` |
| `/product-toolkit:wireframe [主题]` | 生成草稿图/线框图描述 | `/product-toolkit:wireframe 登录页面` |
| `/product-toolkit:ui-spec [主题]` | 生成 UI 设计规范 | `/product-toolkit:ui-spec 详情页` |
| `/product-toolkit:user-story [功能]` | 生成用户故事与验收标准 | `/product-toolkit:user-story 电商收藏功能` |
| `/product-toolkit:prd [功能]` | 生成 PRD | `/product-toolkit:prd 用户登录模块` |
| `/product-toolkit:test-case [功能]` | 生成测试用例（含 Smoke/New/Regression + 可视化 Gate） | `/product-toolkit:test-case 登录功能` |
| `/product-toolkit:api-design [功能]` | API 设计 | `/product-toolkit:api-design 登录认证` |
| `/product-toolkit:data-dictionary [功能]` | 数据字典 | `/product-toolkit:data-dictionary 用户模块` |
| `/product-toolkit:moscow` | MoSCoW 优先级排序 | `/product-toolkit:moscow` |
| `/product-toolkit:kano` | KANO 模型分析 | `/product-toolkit:kano 社区功能` |
| `/product-toolkit:persona` | 生成用户画像 | `/product-toolkit:persona 00后大学生` |
| `/product-toolkit:roadmap` | 生成产品路线图 | `/product-toolkit:roadmap` |
| `/product-toolkit:release [版本]` | 发布/上线检查清单 | `/product-toolkit:release v1.0.0` |
| `/product-toolkit:analyze [对象]` | 竞品分析 | `/product-toolkit:analyze 抖音` |
| `/product-toolkit:team [功能]` | 多代理协作（file/tmux runtime） | `/product-toolkit:team 电商详情页` |
| `/product-toolkit:ralph-bridge [功能]` | Ralph 长任务桥接（兼容/高级路径） | `/product-toolkit:ralph-bridge v3.7.0 workflow-evidence-first` |
| `/product-toolkit:work [功能]` | workflow 别名（兼容 Claude 输入习惯） | `/product-toolkit:work 电商收藏功能` |
| `/product-toolkit:workflow [功能]` | 一键产品工作流 | `/product-toolkit:workflow 电商收藏功能` |
| `/product-toolkit:test-progress [版本]` | 测试进度记录 | `/product-toolkit:test-progress v1.0.0` |
| `/product-toolkit:auto-test -v 版本 -f 功能` | 自动化 Web 测试 | `/product-toolkit:auto-test v1.0.0 -f 电商收藏` |
| `/product-toolkit:evolution-summary [版本]` | 版本演进总结 | `/product-toolkit:evolution-summary v1.0.1` |
| `/product-toolkit:save` | 保存会话状态到 .ptk/ | `/product-toolkit:save` |
| `/product-toolkit:resume [session_id]` | 恢复会话状态 | `/product-toolkit:resume` |
| `/product-toolkit:gate [阶段]` | strict 默认门控检查 | `/product-toolkit:gate think` |
| `/product-toolkit:remember [内容]` | 记忆项目知识 | `/product-toolkit:remember --insight 核心用户是Z世代` |
| `/product-toolkit:recall [关键词]` | 检索项目记忆 | `/product-toolkit:recall 用户` |
| `/product-toolkit:status` | 显示状态面板 | `/product-toolkit:status` |

---

## `/product-toolkit:think` vNext 规则契约（入口摘要）

> 唯一目标：把需求澄清过程转成可下游消费的结构化结论。

### 1) 交互节奏

- 批量提问（每轮一批，不再依赖固定题库顺序）
- 基于上下文动态追问（缺失信息 / 冲突信息 / 高风险未证实）
- 每轮必须产出自动摘要
- 以“收敛条件”而非“固定轮次数”结束

### 2) 冲突检测（最小分类）

- 语义冲突（同一术语前后含义不一致）
- 边界冲突（角色、前置条件、权限、限制矛盾）
- 目标冲突（业务目标与验收目标对冲）
- 约束冲突（时间、合规、资源约束互斥）

每个冲突至少记录：`type`、`severity`、`evidence`、`action`、`status`。

### 3) 每轮自动摘要（必填）

- 已确认事实（confirmed_facts）
- 关键假设（assumptions）
- 新发现冲突（conflicts_delta）
- 未决问题变化（open_questions_delta）
- 下一轮追问目标（next_round_focus）

### 4) 未决问题清单（Open Questions Ledger）

每个条目至少包含：
`id`、`question`、`reason`、`source_round`、`priority`、`blocking`、`owner`、`close_criteria`、`status`。

### 5) 下游完成门槛语义

- 只要存在 `blocking=true` 且未关闭的未决项，`workflow` 结论必须是 `Blocked`。
- 非阻塞未决项可带风险继续，但必须显式列入风险摘要。

---

## 下游映射（入口层）

| think vNext 输出 | user-story | prd | test-case | workflow |
|---|---|---|---|---|
| confirmed_facts | 角色/场景/前置条件 | 背景与目标 | 前置条件与数据准备 | 作为通过依据 |
| assumptions | 风险注记 | 假设与依赖 | 待验证假设用例 | Warn/Blocked 判定输入 |
| conflicts | 标注边界冲突故事 | PRD 风险章节 | 生成冲突回归与阻断用例 | 冲突未解可阻塞 |
| open_questions_ledger | 留白并标注阻塞项 | 未决决策清单 | Blocked 测试条件 | 决定 Pass/Warn/Blocked |
| round_summaries | 需求演进说明 | 方案收敛记录 | 用例来源追溯 | 审计与复盘输入 |

---

## 多平台可视化测试交付门槛（保持强制）

当测试对象是可视化 UI 时，`/product-toolkit:test-case` 结果必须包含并满足：

1. Web：`agent-browser`/`browser-use`，从登录流程开始，保留关键截图，Console 无未处理错误，关键 API 成功。
2. mobile-app：模拟器/真机关键路径执行，保留截图/录屏，检查崩溃与关键日志，关键 API 成功。
3. mini-program：开发者工具/真机关键路径执行，保留截图，检查 console/请求日志，关键 API 成功。
4. 输出 AC→TC 覆盖矩阵，证明用户故事验收标准全覆盖。
5. 测试凭据仅可由用户提供并脱敏记录，文档不得存储明文账号密码。

> 任一项不满足，测试结论必须标记 `Blocked` / 不可交付。

---

## Breaking Change + Cutover Checklist

上线此版本前，至少完成：

- [ ] 已在 `.omx/plans/open-questions.md` 先完成 think vNext 条目“关闭或分级 triage”。
- [ ] 三个入口文档（`SKILL.md`、`commands/product-toolkit.md`、`README.md`）已统一硬切声明。
- [ ] 已移除旧版固定题库承诺（如“固定轮次/固定题数”）。
- [ ] 已明确 `Blocked` 触发语义（阻塞未决项不可判定通过）。
- [ ] 已同步下游映射说明（think → user-story/prd/test-case/workflow）。
- [ ] 变更日志已标注为 breaking change。

---

## 一致性验证清单（关键词/章节）

### 必须出现关键词
- `think vNext`
- `动态追问`
- `冲突检测`
- `每轮自动摘要`
- `未决问题清单` 或 `open questions ledger`
- `Hard Switch` / `Breaking Change`
- `Blocked`

### 必须不存在旧语义
- `固定轮次+固定题数承诺`
- `legacy 题库兼容承诺`
- `legacy 流程兼容承诺`

### 推荐检索命令

```bash
rg -n "think vNext|动态追问|冲突检测|每轮自动摘要|未决问题|Hard Switch|Breaking Change|Blocked" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md

rg -n "<legacy-fixed-round-pattern>|<legacy-compat-pattern>" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md
```

---

## 持久化系统 (.ptk/)

v3.1.0 新增状态跨会话持久化功能：

```
.ptk/
├── state/
│   ├── think-progress.json    # think vNext 会话进度
│   ├── workflow-state.yaml    # workflow 执行状态
│   ├── version-history.json   # 版本演进历史
│   ├── test-progress.json     # 测试进度追踪（版本/功能聚合）
│   └── test-sessions/         # 自动化测试会话明细（start-record-stop-consolidate）
├── memory/
│   ├── project-insights.json # 项目洞察（跨会话）
│   ├── decisions.json         # 历史决策记录
│   ├── vocabulary.json       # 领域术语表
│   └── test-learnings.json   # 自动化测试踩坑记忆（signatures/playbooks/sessions）
└── cache/
    └── templates/           # 模板缓存
```

### 持久化技能

| 技能 | 说明 |
|------|------|
| `/product-toolkit:save` | 保存当前会话进度 |
| `/product-toolkit:resume` | 恢复历史会话 |

### 记忆技能

| 技能 | 说明 |
|------|------|
| `/product-toolkit:remember` | 记忆项目洞察/决策/术语 |
| `/product-toolkit:recall` | 检索历史记忆 |

### 状态面板

| 技能 | 说明 |
|------|------|
| `/product-toolkit:status` | 显示当前工作流状态 |
| `/product-toolkit:gate` | strict 默认门控检查 |

---

## Gate（strict 默认）

v3.4.0 默认启用 strict 策略：

### 门控行为

- **默认**: 门控失败即 `Blocked`
- **覆盖**: 可使用 `--force` 继续
- **记录**: `--force` 必须记录风险

### 门控检查项

| 阶段 | 门控项 | 判定标准 |
|------|--------|---------|
| think | 收敛门 | 无 blocking=true 的未决项 |
| user-story | AC门 | 七维 AC 完整，覆盖率100% |
| prd | 风险门 | critical/high 冲突已解决或标注 |
| test-case | 覆盖门 | AC→TC 覆盖矩阵完整 |
| release | 测试门 | 冒烟测试 100% 通过 |

使用 `/product-toolkit:gate [阶段]` 检查门控。

---

## 自动化测试系统

v3.1.0 新增自动化测试能力：

### 测试执行

```bash
# 运行自动化测试
./scripts/auto_test.sh -v v1.0.0 -p web
./scripts/auto_test.sh -v v1.0.0 -p mobile-app
./scripts/auto_test.sh -v v1.0.0 -p mini-program
```

### 自迭代机制

- 迭代上限: 3 次
- 失败时自动修复并重新测试
- 收集截图/Console/API 证据

### 进度跟踪

使用 `/product-toolkit:test-progress [版本]` 跟踪测试进度。

### 需求反馈回写（新增）

auto-test 在 consolidate 后会根据触发条件自动生成 feedback（missing_user_stories / missing_test_cases / repeat_guard）：

- `.ptk/state/requirement-feedback/{version}-{feature}.json`
- `docs/product/{version}/feedback/{feature}.md|json`
- `docs/product/feedback/{version}-{feature}.md|json`

下一轮 think/workflow 必须优先读取 feedback 并注入 open-questions。

---

## Team Runtime（M2）

统一命令入口（file/tmux/auto）：

```bash
./scripts/team_runtime.sh start --team <name> --runtime file|tmux|auto
./scripts/team_runtime.sh status --team <name>
./scripts/team_runtime.sh resume --team <name>
./scripts/team_runtime.sh shutdown --team <name> --terminal-status Pass|Blocked|Cancelled
```

双审查 Gate：

```bash
./scripts/review_gate.sh --team <name> init
./scripts/review_gate.sh --team <name> spec --status pass
./scripts/review_gate.sh --team <name> quality --status pass
./scripts/review_gate.sh --team <name> evaluate --critical-open 0 --high-open 0
```

阶段报告：

```bash
./scripts/team_report.sh --team <name> --format both
```

---

## 输出目录

默认模式（单命令调用）：

```
docs/product/
├── prd/{feature}.md
├── test-cases/{feature}.md
├── personas/{name}.md
├── roadmap.md
├── release/v{version}.md
└── competitors/{name}.md
```

工作流模式（`/product-toolkit:workflow`）：

```
docs/product/{version}/
├── SUMMARY.md
├── prd/{feature}.md
├── user-story/{feature}.md
├── design/wireframe/{feature}.md
├── design/spec/{feature}.md
├── qa/test-cases/{feature}.md
├── execution/boundaries.md
├── execution/terminal.json
├── execution/next-step-prompts.md
├── tech/api/{feature}.md
├── tech/data-model/{feature}.md
└── release/v{version}.md
```

---

## 参考文档

- `references/socratic-questioning.md`
- `references/acceptance-criteria.md`
- `references/user-story-mapping.md`
- `references/team-collaboration.md`
- `references/team-roles.md`

---

**版本**: v3.7.0

**更新日志**:
- v3.7.0: CLI 统一入口、Scope Guard 越界记录（deviations/confirmations）、dual-mode 报告（summary.md + summary.json）、证据三件套（raw-command-log/evidence-manifest/gate-consistency）
- v3.6.0: workflow 主路径聚焦 PRD/US/QA、OMC/OMX 下一步固定提示词模板、boundaries/terminal 证据闭环模板、bridge 降级为兼容路径
- v3.5.2: 版本一致性修正（入口文档版本标识统一）
- v3.5.1: 新增 `/product-toolkit:work`（workflow 别名）
- v3.5.0: Ralph Bridge 长任务桥接（start/resume/status/finalize）
- v3.4.0: strict 默认策略、测试反馈回写、team file/tmux 统一运行时、spec->quality 双审查 gate、max_fix_loops 终态阻断
- v3.3.0: Product Toolkit 平台化文档基线（PRD/US/QA）
- v3.2.2: 自动化测试增强（支持启动前端、按优先级选择 agent-browser/browser-use、失败记忆沉淀防重复踩坑）
- v3.1.0: 添加状态持久化系统 (.ptk/)、Soft-Gate门控、记忆系统、自动化测试
- v3.0.1: 添加版本演进与测试回归系统（自动 patch+1、用户故事继承、测试进度跟踪、演进总结）
- v3.0.1: 版本号修正，与 plugin.json 保持一致
- v3.0.0: 添加一键工作流、版本化输出配置、子技能结构。
