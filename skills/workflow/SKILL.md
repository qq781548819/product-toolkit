---
name: workflow
description: Use when user wants to run complete product workflow with think vNext hard-switch gates and downstream mapping consistency
---

# 一键产品工作流（think vNext Hard Switch）

按统一契约串联 `think → user-story → prd → test-case`，并以规则 Gate 判定 `Pass/Blocked`。

## 使用方式

```bash
/product-toolkit:workflow [功能]
/product-toolkit:workflow --scenario=iteration [功能]
/product-toolkit:workflow --platforms=web,mini-program [功能]
```

---

## 全局规则

1. Rule-first：只定义规则契约，不做行为引擎实现。
2. Hard switch：不再使用旧版固定题号兼容逻辑。
3. Open-questions 先行：先 triage，再进入下游产物生成。
4. 下游映射唯一来源：`../../references/user-story-mapping.md`。

---

## 工作流阶段

### Phase 0：Open Questions Triage（先决）

- 汇总 `think vNext` 未决问题与冲突。
- 标记 `blocking=true/false`。
- 明确关闭标准与 owner。

### Phase 1：think vNext 收敛

- 产出标准输入信封（Markdown + structured block）。
- 必填字段齐全后方可进入下游。

### Phase 2：下游产物生成

基础链路：

```text
think → user-story → prd → test-case
```

场景扩展（可选）：

- new_product: `think → brainstorm → design → ... → user-story → prd → test-case → release`
- iteration: `think → version → user-story → prd → test-case → release`
- competitor: `analyze → think → user-story → prd → test-case`
- mvp: `think → user-story → prd → test-case`

### Phase 3：一致性校验 Gate

#### Gate A：契约完整性

- 必填字段缺失 ⇒ `Blocked`

#### Gate B：冲突/未决判定

- `critical/high` 未解决冲突 ⇒ `Blocked`
- `open_question.blocking=true` 未关闭 ⇒ `Blocked`
- `medium/low` 未解决冲突 ⇒ `Warn`

#### Gate C：映射一致性

- `think → user-story → prd → test-case` 字段追踪必须完整
- 任一链路断裂 ⇒ `Blocked`

#### Gate D：可视化 QA Gate（如适用）

- 平台强制证据（截图/日志/API 成功）不满足 ⇒ `Blocked`

---

## Workflow 完成语义

- `Pass`：所有 Gate 通过；若有 `Warn`，需显式列出风险。
- `Blocked`：任一阻塞条件触发。

> `Warn` 不是最终状态，只是 `Pass` 的风险附注。

---

## 输出目录

```text
docs/product/{version}/
├── SUMMARY.md
├── user-story/{feature}.md
├── prd/{feature}.md
├── qa/test-cases/{feature}.md
├── tech/
└── release/
```

`SUMMARY.md` 必须包含：

1. Gate 结果（A/B/C/D）
2. 最终状态（Pass/Blocked）
3. Warn 风险列表
4. 未决问题闭环状态

---

## 相关引用

- `../../references/user-story-mapping.md`
- `../../references/acceptance-criteria.md`
- `../../config/workflow.yaml`
