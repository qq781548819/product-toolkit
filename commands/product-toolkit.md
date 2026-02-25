---
name: product-toolkit
description: 通用产品经理工具集 - think vNext 规则先行硬切换版本
---

# Product Toolkit v3.2.1

[PRODUCT TOOLKIT ACTIVATED]

## 🚨 Breaking Change

`/product-toolkit:think` 已切换为 **think vNext**：

- 批量交互（非固定题库）
- 上下文动态追问
- 冲突检测
- 每轮自动摘要
- 未决问题清单（open questions ledger）

旧版“固定轮次 / 固定题数”语义已下线。

---

## 子命令

| 命令 | 功能 | 输出文件 |
|---|---|---|
| `/product-toolkit` | 主工具集入口 | - |
| `/product-toolkit:init` | 初始化配置 | `docs/product/config.yaml` |
| `/product-toolkit:workflow` | 一键产品工作流 | `docs/product/{version}/` |
| `/product-toolkit:think` | 产品思考 vNext（批量+动态追问+冲突检测） | 下游命令输入 |
| `/product-toolkit:brainstorm` | 发散思维 | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:design` | Design Thinking | `docs/product/{version}/design/` |
| `/product-toolkit:jtbd` | JTBD 分析 | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:version` | 版本规划 | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:wireframe` | 草稿图/线框图 | `docs/product/{version}/design/wireframe/{feature}.md` |
| `/product-toolkit:ui-spec` | UI 设计规范 | `docs/product/{version}/design/spec/{feature}.md` |
| `/product-toolkit:user-story` | 用户故事 | `docs/product/{version}/user-story/{feature}.md` |
| `/product-toolkit:prd` | PRD | `docs/product/prd/{feature}.md` |
| `/product-toolkit:test-case` | 测试用例（含 Smoke/New/Regression + UI 可视化 Gate） | `docs/product/{version}/qa/test-cases/{feature}.md` |
| `/product-toolkit:api-design` | API 设计 | `docs/product/{version}/tech/api/{feature}.md` |
| `/product-toolkit:data-dictionary` | 数据字典 | `docs/product/{version}/tech/data-model/{feature}.md` |
| `/product-toolkit:moscow` | MoSCoW 优先级 | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:kano` | KANO 模型分析 | `docs/product/{version}/SUMMARY.md` |
| `/product-toolkit:persona` | 用户画像 | `docs/product/personas/{name}.md` |
| `/product-toolkit:roadmap` | 路线图 | `docs/product/roadmap.md` |
| `/product-toolkit:release` | 上线检查 | `docs/product/release/v{version}.md` |
| `/product-toolkit:analyze` | 竞品分析 | `docs/product/competitors/{name}.md` |
| `/product-toolkit:team` | 多代理协作 | `docs/product/{version}/` |
| `/product-toolkit:test-progress` | 测试进度 | `docs/product/test-progress/{version}.md` |
| `/product-toolkit:evolution-summary` | 版本演进 | `docs/product/evolution/{version}.md` |
| `/product-toolkit:save` | 保存会话 | `.ptk/state/` |
| `/product-toolkit:resume` | 恢复会话 | `.ptk/state/` |
| `/product-toolkit:gate` | 门控检查 | - |
| `/product-toolkit:remember` | 记忆知识 | `.ptk/memory/` |
| `/product-toolkit:recall` | 检索记忆 | `.ptk/memory/` |
| `/product-toolkit:status` | 状态面板 | - |

---

## think vNext 入口契约（摘要）

- 批量交互（每轮一批问题）
- 动态追问（缺失信息 / 冲突信息 / 高风险未证实 / 边界未闭环）
- 每轮自动摘要（confirmed facts / assumptions / conflicts / open questions）
- 未决问题 ledger 驱动下游阻塞语义（`blocking=true` 未关闭 => `Blocked`）

---

## Open Questions Triage Gate（先做）

执行 hard switch 前，先在 `.omx/plans/open-questions.md` 完成 think vNext 条目“关闭或 triage”。

最少满足：

1. 每条未决项都有 `blocking` 判定。
2. 每条未决项都有 `owner` 与 `close_criteria`。
3. 阻塞项未关闭时，`/product-toolkit:workflow` 结论必须为 `Blocked`。

---

## Cutover Checklist

- [ ] 三个入口文件已同步（`SKILL.md` / `commands/product-toolkit.md` / `README.md`）
- [ ] 已删除旧版固定题库口径
- [ ] 已保留 think vNext 关键词与契约章节
- [ ] 已明确 `Blocked` 判定
- [ ] 已记录 breaking change

---

## 一致性验证（推荐）

```bash
rg -n "think vNext|动态追问|冲突检测|每轮自动摘要|未决问题|Hard Switch|Breaking Change|Blocked" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md

rg -n "<legacy-fixed-round-pattern>|<legacy-compat-pattern>" \
  product-toolkit/SKILL.md product-toolkit/commands/product-toolkit.md product-toolkit/README.md
```

---

*规则先行。一次切换。无旧流程兼容层。*
