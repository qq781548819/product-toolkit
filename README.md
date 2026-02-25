# Product Toolkit

> 通用产品经理工具集 - 集成在 Claude Code / Codex 中使用

## 🚨 Hard Switch（2026-02-25）

`/product-toolkit:think` 已执行 **think vNext 规则先行硬切换**：

- 旧版固定题库语义退场（不再按固定题号/固定轮次驱动）
- 启用：批量交互、上下文动态追问、冲突检测、每轮自动摘要、未决问题清单（ledger）
- 下游 `user-story / prd / test-case / workflow` 按新契约消费输出
- 本次切换仅覆盖规则与文档契约，不包含行为引擎实现细节

---

## 安装

### Claude Code（本地仓库安装）

```bash
claude plugin marketplace add /绝对路径/product-toolkit
claude plugin install product-toolkit@product-toolkit-dev
```

示例：

```bash
claude plugin marketplace add /Users/apple/Developer/Personal/my_skill/product-toolkit
claude plugin install product-toolkit@product-toolkit-dev
```

验证安装：

```bash
claude plugin list
```

### Codex

```bash
git clone https://github.com/justin-mc-lai/product-toolkit ~/.codex/product-toolkit
mkdir -p ~/.agents/skills
ln -s ~/.codex/product-toolkit ~/.agents/skills/product-toolkit
```

验证安装：

```bash
ls -la ~/.agents/skills/product-toolkit
```

详细说明见 `.codex/INSTALL.md`。

---

## 功能概览

| 功能 | 说明 |
|---|---|
| 状态持久化 | .ptk/ 目录跨会话保存 think/workflow/test 状态 |
| 记忆系统 | remember/recall 项目洞察、决策、术语 |
| 门控机制 | Soft-Gate 阻止阶段流转，支持 --force 强制覆盖 |
| 状态面板 | /product-toolkit:status 显示阶段/门控/进度 |
| 产品思考（think vNext） | 批量问答 + 动态追问 + 冲突检测 + 自动摘要 |
| 发散思维 | 网状思维头脑风暴，多维分析 |
| Design Thinking | 设计思维五阶段 |
| JTBD | 用户任务理论，深入理解用户动机 |
| 版本迭代 | 自动版本推进（默认 patch+1）+ 用户故事继承 |
| UI 设计 | 草稿图、线框图、设计规范 |
| 用户故事 | 标准验收标准模板（含权限与逆向流程）|
| PRD | 完整结构 + 快速模板 |
| 测试用例 | 从验收标准自动生成（含 Smoke/New/Regression） |
| 测试进度 | 独立测试记录 + 失败追溯 + 演进自反馈 |
| 需求池 | MoSCoW / KANO / RICE 优先级管理 |
| 用户画像 | 模板 + 用户旅程 |
| 产品路线图 | 季度/月度规划 |
| 上线检查 | 上线前后检查清单 |
| 竞品分析 | 功能矩阵 + SWOT |
| 多代理协作 | Product PM + UI + QA + Tech Lead |
| 一键工作流 | 场景路由自动编排完整产品包 |
| 演进总结 | 版本需求变更 + 用户故事状态 + 测试覆盖 |

---

## 快速开始

```bash
# 规则先行需求澄清
/product-toolkit:think 我想做社区点赞功能

# 从 think vNext 输出生成用户故事
/product-toolkit:user-story 社区点赞功能

# 生成测试用例（含可视化 Gate）
/product-toolkit:test-case 社区点赞功能

# 一键工作流
/product-toolkit:workflow 社区点赞功能
```

---

## 完整工作流

### 需求澄清 → 用户故事 → QA 用例

```text
/product-toolkit:think [功能描述]
    ↓
批量问答 + 动态追问 + 冲突检测 + 每轮自动摘要 + 未决问题 ledger
    ↓
/product-toolkit:user-story [功能]
    ↓
/product-toolkit:test-case [功能]
```

### 完整版本迭代工作流

```text
/product-toolkit:design [功能] (可选)
    ↓
/product-toolkit:jtbd [功能] (可选)
    ↓
/product-toolkit:think [功能]
    ↓
/product-toolkit:version [功能]
    ↓
/product-toolkit:user-story [功能]
    ↓
/product-toolkit:prd [功能]
    ↓
/product-toolkit:api-design [功能]
    ↓
/product-toolkit:data-dictionary [功能]
    ↓
/product-toolkit:test-case [功能]
    ↓
/product-toolkit:release [版本]
    ↓
/product-toolkit:test-progress [版本]    # 测试进度记录
    ↓
/product-toolkit:evolution-summary [版本] # 演进总结
```

### 版本演进工作流（自动版本推进 + 测试自反馈）

```text
# 默认：自动 patch+1 热修复
/product-toolkit:version 电商收藏
    ↓
自动 patch+1 (如 v1.0.0 → v1.0.1)
用户故事自动继承 [INHERITED]
    ↓
/product-toolkit:test-progress v1.0.1
    ↓
记录冒烟/回归测试结果
失败追溯到用户故事 → 需求
    ↓
/product-toolkit:evolution-summary v1.0.1
    ↓
生成版本演进总结
```

### 多代理团队协作工作流

```text
/product-toolkit:team [功能]
    ↓
Team Lead 分解任务
    ↓
Product PM / UI Designer / QA Engineer / Tech Lead 并行
    ↓
Team Lead 整合与验收
```

---

## 版本演进规则（摘要）

> 详细规则以 `skills/version/SKILL.md` 与 `config/version-strategy.yaml` 为准。

### 版本号推进

| 用法 | 推进方式 | 示例 |
|------|----------|------|
| 无参数 | 自动 patch+1 | v1.0.0 → v1.0.1 |
| `--bump=minor` | minor+1 | v1.0.0 → v1.1.0 |
| `--bump=major` | major+1 | v1.0.0 → v2.0.0 |
| `--version=x.y.z` | 手动指定 | 任意版本 |

### 用户故事状态标识

| 标识 | 含义 |
|------|------|
| `[NEW]` | 当前版本新增 |
| `[INHERITED]` | 从上一版本继承（默认）|
| `[MODIFIED]` | 继承后有修改 |
| `[DEPRECATED]` | 当前版本废弃 |
| `[COMPLETED]` | 已完成，可回归 |

### 测试用例标识

| 标识 | 含义 |
|------|------|
| `[SMOKE]` | 冒烟测试 |
| `[REGRESSION]` | 回归测试 |
| `[NEW]` | 新功能测试 |
| `[FIX]` | 修复验证 |

---

## think vNext 入口契约（摘要）

> 详细规则以 `skills/think/SKILL.md` 与 `references/socratic-questioning.md` 为准。

### 1) 交互机制

- 批量提问（每轮一批）
- 动态追问触发：缺失信息 / 上下文冲突 / 高风险未证实 / 边界未闭环
- 每轮必须产出自动摘要
- 按收敛条件结束，不按固定题号或固定轮次结束

### 2) 冲突检测（最小分类）

- 语义冲突（Semantic）
- 边界冲突（Boundary）
- 目标冲突（Goal）
- 约束冲突（Constraint）

每个冲突需记录：`type`、`severity`、`evidence`、`action`、`status`。

### 3) 每轮自动摘要（必填）

- Confirmed Facts
- Assumptions
- Conflicts Detected
- Open Questions（Delta）
- Next-round Objectives
- Convergence Check

### 4) Open Questions Ledger 与 Blocked 语义

- 未决问题需包含 `id/reason/priority/blocking/owner/close_criteria/status`
- 若存在 `blocking=true` 且未关闭的未决项，`workflow` 结论必须为 `Blocked`
- 非阻塞未决项可继续，但必须显式记录风险

---

## 多平台可视化测试交付门槛（Web / mobile-app / mini-program）

当测试对象是可视化 UI 时，`/product-toolkit:test-case` 产出必须满足：

1. **Web**：`agent-browser` / `browser-use`；从登录起点执行；保留关键截图；Console 无未处理阻断错误；关键 API 成功。
2. **mobile-app**：模拟器/真机关键路径；保留截图/录屏；检查崩溃与关键日志；关键 API 成功。
3. **mini-program**：开发者工具/真机关键路径；保留截图；检查 console/请求日志；关键 API 成功。
4. 输出 AC→TC 覆盖矩阵，覆盖用户故事全部验收标准。
5. 凭据仅可由用户提供并脱敏记录，不得在仓库写入明文账号密码。

> 任一项不满足：测试结论必须标记为 `Blocked`（不可交付）。

---

## Breaking Change + Cutover Checklist

上线 hard switch 前，至少确认：

- [ ] `.omx/plans/open-questions.md` 已完成 think vNext 条目关闭或分级 triage
- [ ] 入口文档三件套已统一：`SKILL.md` / `commands/product-toolkit.md` / `README.md`
- [ ] 已删除旧版固定题库口径（仅保留“已退场”声明）
- [ ] 已明确 `Blocked` 判定（阻塞未决项不可通过）
- [ ] 已同步 think → user-story/prd/test-case/workflow 的入口映射语义
- [ ] 版本历史已标记 breaking change

---

## 一致性验证清单（关键词 / 章节）

### 必须出现

- `think vNext`
- `动态追问`
- `冲突检测`
- `每轮自动摘要`
- `未决问题` / `open questions ledger`
- `Hard Switch` / `Breaking Change`
- `Blocked`

### 必须具备章节

- Hard Switch 声明
- think vNext 入口契约
- 可视化测试交付门槛
- Cutover Checklist
- 一致性验证清单

### 推荐检索命令

```bash
rg -n "think vNext|动态追问|冲突检测|每轮自动摘要|未决问题|Hard Switch|Breaking Change|Blocked" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md

rg -n "<legacy-fixed-round-pattern>|<legacy-question-id-pattern>|<legacy-compat-pattern>" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md
```

---

## 输出目录

独立模式（单命令调用）：

```text
docs/product/
├── prd/{feature}.md
├── test-cases/{feature}.md
├── personas/{name}.md
├── roadmap.md
├── release/v{version}.md
└── competitors/{name}.md
```

工作流模式（`/product-toolkit:workflow`）：

```text
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

## 版本历史

| 版本 | 日期 | 变更 |
|---|---|---|
| v3.2.0 | 2026-02-25 | 添加自动化测试 (auto-test) 子命令，支持 Web 端 agent-browser 自动化 |
| v3.1.1 | 2026-02-25 | 添加 ptk 关键词触发机制（ptk think / ptk workflow 等） |
| v3.1.0 | 2026-02-25 | 添加状态持久化系统(.ptk/)、Soft-Gate门控、记忆系统(remember/recall)、自动化测试(status面板) |
| v3.0.1 | 2026-02-25 | 添加版本演进与测试回归系统（自动 patch+1、用户故事继承、测试进度跟踪、演进总结）|
| v3.0.0 | 2026-02-24 | 添加一键工作流、版本化输出配置、平台模板与版本配置 |
| v2.6.0 | 2026-02-19 | 添加 Claude Team 多代理协作 |
| v2.5.0 | 2026-02-19 | 添加 UI 设计（草稿图、线框图、UI 规范） |
| v2.4.0 | 2026-02-19 | 添加版本迭代、Design Thinking、JTBD、价值主张画布 |
| v2.3.0 | 2026-02-19 | 添加 Sprint 规划、KPI 指标、用户故事地图 |
| v2.2.0 | 2026-02-19 | 产品思考 → 用户故事 → QA 用例完整工作流 |
| v2.1.0 | 2026-02-14 | 添加产品思考和发散思维功能 |
| v2.0.0 | 2026-02-14 | 完整功能集 |

---

## 参考文档

- `references/socratic-questioning.md`
- `references/acceptance-criteria.md`
- `references/user-story-mapping.md`
- `references/user-story-inheritance.md` (新增)
- `references/team-collaboration.md`
- `references/team-roles.md`
- `config/version-strategy.yaml` (版本策略配置)

---

*规则先行。一次切换。无旧流程兼容层。*
