---
name: team
description: Use when user wants multi-agent collaboration for product development - coordinates Product PM, UI Designer, QA Engineer, and Tech Lead roles to generate complete product packages. Supports multiple AI agents (Claude, OpenCLAW, OpenCode, Codex).
---

# 多代理团队协作

通过多代理团队协作，生成完整的产品包（用户故事、UI 设计、测试用例、技术方案）。

## 使用方式

```
/product-toolkit:team [功能]
/product-toolkit:team --agent=claude [功能]    # 指定 agent
/product-toolkit:team --list-agents            # 列出可用 agent
```

例如：`/product-toolkit:team 电商详情页`

## 支持的 Agent

| Agent | 说明 | 安装路径 |
|-------|------|---------|
| Claude (默认) | Claude Code 原生 Team 模式 | ~/.claude/skills/ |
| OpenCLAW | Subprocess 调用 | ~/.openclaw/skills/ |
| OpenCode | Subprocess 调用 | ~/.config/opencode/skills/ |
| Codex | Subprocess 调用 | ~/.agents/skills/ |

## 工作流

```
用户输入: /product-toolkit:team 电商详情页
         │
         ▼
    Agent Router (检测可用 agent)
         │
         ▼
    角色合并 (根据 agent 能力)
         │
         ▼
    并行执行:
    ├─ Product PM: 用户故事
    ├─ UI Designer: 草稿图+规范
    ├─ QA Engineer: 测试用例
    └─ Tech Lead: 技术方案
         │
         ▼
    Team Lead 整合验证
         │
         ▼
    输出: 完整产品包
```

## 团队角色

| 角色 | 任务 | 输出 |
|------|------|------|
| **Team Lead** | 协调、分解任务、整合 | 整合报告 |
| **Product PM** | 需求分析、用户故事 | docs/product/{version}/user-story/ |
| **UI Designer** | 草稿图、线框图、UI规范 | docs/product/{version}/design/ |
| **QA Engineer** | 测试用例、测试计划 | docs/product/{version}/qa/test-cases/ |
| **Tech Lead** | API设计、数据模型 | docs/product/{version}/tech/ |

## 角色映射

不同 Agent 有不同的角色数量：

| 角色 (Claude) | OpenCLAW | OpenCode | Codex |
|--------------|----------|----------|-------|
| Team Lead | pm | developer | coder |
| Product PM | pm | developer | coder |
| UI Designer | designer | developer | coder |
| QA Engineer | designer | reviewer | reviewer |
| Tech Lead | designer | developer | coder |

## 输出结构

```
docs/product/{version}/
├── user-story/{feature}.md
├── prd/{feature}.md
├── design/wireframe/{feature}.md
├── design/spec/{feature}.md
├── qa/test-cases/{feature}.md
├── tech/api/{feature}.md
└── tech/data-model/{feature}.md
```

## 整合报告模板

```markdown
# 产品包整合报告

## 功能: {featureName}

### 需求 (Product PM)
- 用户故事数: X
- 优先级分布: Must X, Should X, Could X

### 设计 (UI Designer)
- 页面数: X
- 组件数: X
- 设计规范: {spec}

### 测试 (QA Engineer)
- 用例数: X
- 覆盖率: X%

### 技术 (Tech Lead)
- API 端点数: X
- 数据模型数: X

### 验证结果
- [ ] 需求一致性: 通过
- [ ] 完整性: 通过
- [ ] 质量: 通过
```

## 使用场景

- 复杂功能需要多领域专家并行工作
- 需要完整产品包（需求+设计+测试+技术）
- 大型功能需要任务分解和协调
- 多 Agent 环境下的产品开发

## 配置

配置文件: `../../config/agent.yaml`

```yaml
agents:
  claude:
    enabled: true
    priority: 100
    roles: [team-lead, product-pm, ui-designer, qa-engineer, tech-lead]
  
  openclaw:
    enabled: auto
    priority: 90
    roles: [pm, designer]

role_mapping:
  # 角色映射规则
```

## 参考

- `../../references/team-collaboration.md` - 多代理协作指南
- `../../references/team-roles.md` - 角色定义与Prompt模板
- `../../templates/team-task.md` - 任务分解模板

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
