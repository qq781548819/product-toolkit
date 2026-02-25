---
name: init
description: Use when user wants to initialize product documentation structure - creates baseline docs/product directories and config from templates
---

# 初始化项目配置

初始化 Product Toolkit 所需的目录和基础配置。

## 使用方式

```bash
/product-toolkit:init
/product-toolkit:init 电商平台
```

## 初始化内容

1. 创建目录结构：
- `docs/product/`
- `docs/product/prd/`
- `docs/product/test-cases/`
- `docs/product/personas/`
- `docs/product/release/`
- `docs/product/competitors/`

2. 生成配置文件：
- `docs/product/config.yaml`（参考 `../../config/template.yaml`）
- `docs/product/README.md`（参考 `../../templates/README.md.tmpl`）

3. 提示下一步：
- `/product-toolkit:think [功能]`
- `/product-toolkit:workflow [产品概念]`

## 输出目录

默认模式（单命令调用）:
```
docs/product/
```

工作流模式（/product-toolkit:workflow）:
```
docs/product/{version}/
```

## 参考

- `../../config/template.yaml` - 初始化配置模板
- `../../templates/README.md.tmpl` - 文档索引模板
