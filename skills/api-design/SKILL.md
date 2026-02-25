---
name: api-design
description: Use when user wants to design APIs for a feature - provides RESTful API design template including endpoints, request/response contracts, and error handling
---

# API 设计

为功能模块生成结构化 API 设计文档。

## 使用方式

```bash
/product-toolkit:api-design 登录认证
/product-toolkit:api-design 电商收藏功能
```

## 输出模板

# API 设计: {feature}

## 1. 概述
- 目标: {goal}
- 认证方式: {auth}
- 版本: v1

## 2. 端点清单
| API | 方法 | 说明 |
|-----|------|------|
| /api/{resource} | GET | 列表 |
| /api/{resource} | POST | 创建 |
| /api/{resource}/{id} | PATCH | 更新 |
| /api/{resource}/{id} | DELETE | 删除 |

## 3. 请求/响应
### Request
```json
{ "example": "value" }
```

### Response
```json
{ "success": true, "data": {} }
```

## 4. 错误码
| code | 场景 | 说明 |
|------|------|------|
| 400 | 参数错误 | 请求参数不合法 |
| 401 | 未授权 | 登录失效或缺失 |
| 403 | 无权限 | 角色不允许 |
| 500 | 服务异常 | 服务端错误 |

## 输出目录

默认模式（单命令调用）:
```
docs/tech/api/{feature}.md
```

工作流模式（/product-toolkit:workflow）:
```
docs/product/{version}/tech/api/{feature}.md
```

## 参考

- `../../references/api-design.md` - API 设计参考
