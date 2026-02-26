---
name: gate
description: Check strict-by-default gate validation for current workflow phase; supports --force with risk logging
---

# Gate（strict 默认）

## 目标

在 `think / user-story / prd / test-case / release` 阶段执行门控检查，默认阻断不合格流转。

## 默认策略

1. `strict_default=true`
2. 门控失败 => `Blocked`
3. 可使用 `--force`，但必须记录风险到 `.ptk/state/risks.json`（或等价下游风险记录）

## 用法

```bash
/product-toolkit:gate
/product-toolkit:gate think
/product-toolkit:gate --force
```

## 判定核心

- `blocking=true` 的 open question 未关闭 => Blocked
- critical/high 冲突未解决 => Blocked
- AC→TC 映射缺口 => Blocked
- strict 测试缺口（missing US/TC、strict guard 失败）=> Blocked

## 配置

`config/persistence.yaml`

```yaml
gate:
  strict_default: true
  mode: soft
  warn_on_force: true
  log_risks: true
```

## 输出语义

- `Pass`
- `Blocked`
- `Pass + Risk`（仅在 `--force` 时）
