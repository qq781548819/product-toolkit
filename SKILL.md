---
name: product-toolkit
description: Product toolkit for PM workflows (think/user-story/prd/test-case/workflow etc.) with think vNext hard-switch rules.
---

# Product Toolkit v3.0.1

提供产品经理工作流工具集：需求澄清、用户故事、PRD、测试用例、技术方案与发布清单。

## 🚨 Hard Switch 声明（2026-02-25）

本版本对 `/product-toolkit:think` 执行**规则先行硬切换**：

1. 旧版“固定轮次 / 固定题数 / 固定题库”语义**退场**。
2. 采用 `think vNext`：**批量交互 + 上下文动态追问 + 冲突检测 + 每轮自动摘要 + 未决问题清单（ledger）**。
3. 下游 `user-story / prd / test-case / workflow` 按新契约消费输出。
4. 本次仅定义**规则与文档契约**，不包含行为引擎实现。

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
| `/product-toolkit:team [功能]` | 多代理协作 | `/product-toolkit:team 电商详情页` |
| `/product-toolkit:workflow [功能]` | 一键产品工作流 | `/product-toolkit:workflow 电商收藏功能` |
| `/product-toolkit:test-progress [版本]` | 测试进度记录 | `/product-toolkit:test-progress v1.0.0` |
| `/product-toolkit:evolution-summary [版本]` | 版本演进总结 | `/product-toolkit:evolution-summary v1.0.1` |

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

**版本**: v3.0.1

**更新日志**:
- v3.0.1: 添加版本演进与测试回归系统（自动 patch+1、用户故事继承、测试进度跟踪、演进总结）
- v3.0.1: 版本号修正，与 plugin.json 保持一致
- v3.0.0: 添加一键工作流、版本化输出配置、子技能结构。
