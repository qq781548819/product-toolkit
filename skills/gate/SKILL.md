---
name: gate
description: Check Soft-Gate validation for current workflow phase - blocks stage transitions but allows force override
---

# Soft-Gate 验证门控

验证当前工作流阶段的门控条件，支持软门控机制：默认阻止，但允许强制覆盖。

## 使用方式

```bash
/product-toolkit:gate
/product-toolkit:gate think
/product-toolkit:gate --force
/product-toolkit:gate --verbose
```

## Soft-Gate 机制

### 门控行为

| 模式 | 行为 |
|------|------|
| **Soft-Gate (默认)** | 阻止未通过门控的阶段流转，显示警告 |
| **强制覆盖** | 使用 `--force` 强制继续，记录风险到下游 |

### 强制覆盖风险记录

当使用 `--force` 强制通过时：
1. 记录风险到 `.ptk/state/risks.json`
2. 在下游阶段注入风险警告
3. 风险随发布版本记录

## 门控检查清单

### think 阶段门控

| 门控项 | 判定标准 | 状态 |
|--------|----------|------|
| 收敛门 | 无 `blocking=true` 的未决项 | 必填 |
| 冲突门 | 无 critical 级别冲突 | 必填 |
| 事实门 | confirmed_facts >= 3 | 建议 |

### user-story 阶段门控

| 门控项 | 判定标准 | 状态 |
|--------|----------|------|
| AC 门 | 七维 AC 完整，覆盖率 100% | 必填 |
| 角色门 | 每个角色有对应故事 | 必填 |
| 验收门 | AC 可测试、可验证 | 建议 |

### prd 阶段门控

| 门控项 | 判定标准 | 状态 |
|--------|----------|------|
| 风险门 | critical/high 冲突已解决或标注 | 必填 |
| 依赖门 | 外部依赖已标注 | 建议 |
| 边界门 | 边界条件已覆盖 | 建议 |

### test-case 阶段门控

| 门控项 | 判定标准 | 状态 |
|--------|----------|------|
| 覆盖门 | AC→TC 覆盖矩阵完整 | 必填 |
| 可视化门 | UI 测试包含截图/录屏证据 | 平台相关 |
| 优先级门 | critical/high TC 已通过 | 必填 |

### release 阶段门控

| 门控项 | 判定标准 | 状态 |
|--------|----------|------|
| 测试门 | 冒烟测试 100% 通过 | 必填 |
| 文档门 | Release notes 已生成 | 必填 |
| 回归门 | 回归测试无新增失败 | 建议 |

## 输出示例

### 通过示例

```
┌─────────────────────────────────────────────┐
│  Gate Check: think                          │
├─────────────────────────────────────────────┤
│  ✓ 收敛门: Pass (无 blocking 未决项)        │
│  ✓ 冲突门: Pass (无 critical 冲突)          │
│  ✓ 事实门: Pass (5 confirmed facts)         │
├─────────────────────────────────────────────┤
│  Status: 🟢 PASS                            │
│  Next: user-story                           │
└─────────────────────────────────────────────┘
```

### 阻止示例

```
┌─────────────────────────────────────────────┐
│  Gate Check: think                          │
├─────────────────────────────────────────────┤
│  ✗ 收敛门: BLOCKED (2 blocking questions)   │
│  ✓ 冲突门: Pass                             │
│  ✓ 事实门: Pass                             │
├─────────────────────────────────────────────┤
│  Status: 🔴 BLOCKED                         │
│  Reason: 存在 blocking=true 的未决项        │
│  Use --force to override                    │
└─────────────────────────────────────────────┘
```

### 警告示例 (使用 --force)

```
┌─────────────────────────────────────────────┐
│  Gate Check: think (FORCED)                 │
├─────────────────────────────────────────────┤
│  ⚠ 收敛门: WARN (forced override)          │
│  - Risk: 存在 2 个 blocking 未决项          │
│  ✓ 冲突门: Pass                             │
├─────────────────────────────────────────────┤
│  Status: 🟡 WARN (forced)                   │
│  Risk recorded to downstream                │
└─────────────────────────────────────────────┘
```

## 选项

| 选项 | 说明 |
|------|------|
| `[phase]` | 指定检查的阶段 (think/user-story/prd/test-case/release) |
| `--force` | 强制覆盖，忽略门控阻止 |
| `--verbose` | 显示详细门控信息 |
| `--json` | JSON 格式输出 |

## 门控配置

在 `config/persistence.yaml` 中配置：

```yaml
gate:
  mode: soft  # soft | hard | disabled
  warn_on_force: true
  log_risks: true
```

## 相关技能

- `/product-toolkit:save` - 保存状态
- `/product-toolkit:resume` - 恢复状态
- `/product-toolkit:status` - 查看状态
