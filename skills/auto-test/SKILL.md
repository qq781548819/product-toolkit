---
name: auto-test
description: Run automated Web tests using agent-browser for product-toolkit test cases
---

# 自动化测试 (auto-test)

运行 Web 端自动化测试，使用 agent-browser 执行测试用例。

## 使用方式

```bash
/product-toolkit:auto-test v1.0.0 -f 电商收藏功能
/product-toolkit:auto-test --version v1.0.0 --feature 登录功能 --type smoke
```

## 参数

| 参数 | 简写 | 说明 | 必需 |
|------|------|------|------|
| `--version` | `-v` | 产品版本 | 是 |
| `--feature` | `-f` | 功能名称 | 是 |
| `--type` | `-t` | 测试类型: smoke/regression/full | 否 (默认: full) |
| `--iterations` | `-i` | 最大迭代次数 | 否 (默认: 3) |
| `--test-file` | - | 自定义测试用例文件路径 | 否 |
| `--dry-run` | - | 模拟运行，不执行实际测试 | 否 |

## 测试类型

| 类型 | 说明 | 用途 |
|------|------|------|
| smoke | 冒烟测试 | 核心路径，P0 级别，必须通过 |
| regression | 回归测试 | 已有功能验证 |
| full | 完整测试 | 全面测试 |

## 示例

```bash
# 运行完整测试
/product-toolkit:auto-test v1.0.0 -f 电商收藏功能

# 运行冒烟测试
/product-toolkit:auto-test v1.0.0 -f 登录功能 -t smoke

# 模拟运行查看执行计划
/product-toolkit:auto-test v1.0.0 -f 用户中心 --dry-run

# 自定义测试用例文件
/product-toolkit:auto-test v1.0.0 -f 支付功能 --test-file /path/to/test-cases.md
```

## 魔法关键词

使用 `ptk auto-test` 触发：

```bash
ptk auto-test v1.0.0 -f 电商收藏功能
ptk auto-test v1.0.0 -f 登录功能 -t smoke
```

## 测试流程

1. **解析测试用例**: 从 test-case 生成的文档中提取测试用例
2. **执行测试**: 使用 agent-browser 或 browser-use 执行 Web 测试
3. **收集证据**: 截图、Console 日志、API 响应
4. **更新进度**: 记录到 `.ptk/state/test-progress.json`
5. **生成报告**: 输出测试结果和覆盖率

## 测试用例位置

自动查找测试用例文件（按优先级）：

1. `docs/product/{version}/qa/test-cases/{feature}.md`
2. `docs/product/test-cases/{feature}.md`
3. `docs/product/{version}/test-cases/{feature}.md`
4. `--test-file` 指定的自定义路径

## 证据收集

测试执行后，证据保存在：

```
.ptk/evidence/{version}/{feature}/
├── screenshots/     # 测试截图
├── console.log    # Console 日志
├── report.json    # 测试报告
└── api-responses/ # API 响应
```

## 输出示例

```
========================================
Test Report: v1.0.0 - 电商收藏功能
========================================
Test Type:     full
Total:         10
Passed:        9
Failed:        1
Coverage:      90%
Evidence Dir:  .ptk/evidence/v1.0.0/电商收藏功能/

✗ 1 TEST(S) FAILED
Review evidence in: .ptk/evidence/v1.0.0/电商收藏功能/
```

## 依赖

- **agent-browser**: MCP 工具，用于 Web 自动化测试
- **browser-use**: 备选方案，npm 包

## 相关技能

- `/product-toolkit:test-case` - 生成测试用例
- `/product-toolkit:test-progress` - 查看测试进度
- `/product-toolkit:gate` - 门控检查
