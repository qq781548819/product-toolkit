---
name: version
description: Use when user wants to plan product versions, roadmap iterations, or release planning - provides structured version planning with user stories breakdown
---

# 版本规划

基于产品思考的答案，生成版本化的用户故事和迭代计划。

## 使用方式

```
/product-toolkit:version [功能]                    # 自动 patch+1
/product-toolkit:version --bump=minor [功能]        # minor+1
/product-toolkit:version --bump=major [功能]        # major+1
/product-toolkit:version --version=1.2.3 [功能]    # 手动指定版本
```

例如：
- `/product-toolkit:version 电商收藏功能` → v1.0.0 → v1.0.1 (自动 patch+1)
- `/product-toolkit:version --bump=minor 电商收藏` → v1.0.0 → v1.1.0
- `/product-toolkit:version --bump=major 电商收藏` → v1.0.0 → v2.0.0
- `/product-toolkit:version --version=2.0.0 电商收藏` → v2.0.0

## 版本号推进规则

### 默认行为（自动热修复）

不指定版本推进方式时，默认 **patch+1**：

| 当前版本 | 推进后 | 类型 | 适用场景 |
|----------|--------|------|----------|
| 1.0.0 | 1.0.1 | patch | Bug修复、小优化 |
| 1.1.0 | 1.1.1 | patch | Bug修复 |
| 2.0.0 | 2.0.1 | patch | 热修复 |

### 手动指定推进方式

| 参数 | 推进 | 示例 | 适用场景 |
|------|------|------|----------|
| `--bump=minor` | minor+1 | 1.0.0 → 1.1.0 | 新增功能（向下兼容）|
| `--bump=major` | major+1 | 1.0.0 → 2.0.0 | 破坏性变更 |
| `--version=x.y.z` | 手动指定 | 任意版本 | 特殊版本要求 |

## 用户故事继承规则

### 状态标识

| 标识 | 含义 | 使用场景 |
|------|------|----------|
| `[NEW]` | 新增 | 当前版本新创建的用户故事 |
| `[INHERITED]` | 继承 | 从上一版本自动继承（默认）|
| `[MODIFIED]` | 变更 | 继承后有功能修改 |
| `[DEPRECATED]` | 废弃 | 当前版本不再实现 |
| `[COMPLETED]` | 完成 | 已完成，可回归验证 |

### 继承逻辑

```
新版本用户故事 = 上一版本用户故事 (标记为 [INHERITED])
                + 当前版本新增 (标记为 [NEW])
                + 当前版本修改 (标记为 [MODIFIED])
                - 当前版本废弃 (标记为 [DEPRECATED])
```

### 继承示例

**v1.0.0 用户故事**:
```markdown
## US-0001: 用户可以收藏商品

**版本**: v1.0.0
**优先级**: Must
**状态**: [NEW]

作为普通用户，我希望能够收藏商品...
```

**v1.0.1 用户故事** (继承):
```markdown
## US-0001: 用户可以收藏商品

**版本**: v1.0.1
**优先级**: Must
**状态**: [INHERITED] (from v1.0.0)

作为普通用户，我希望能够收藏商品...
```

**v1.1.0 用户故事** (新增+继承):
```markdown
## US-0001: 用户可以收藏商品

**版本**: v1.1.0
**状态**: [INHERITED] (from v1.0.1)

## US-0002: 批量收藏

**版本**: v1.1.0
**状态**: [NEW]

作为普通用户，我希望批量收藏商品...
```

## 工作流

```
产品思考答案 (5轮追问结果)
        ↓
版本规划
        ↓
生成版本化用户故事
```

## 输出模板

### 版本信息

```markdown
## 版本: {version}
## 主题: {theme}
## 目标: {goal}

### 时间范围
- 开始: {date}
- 结束: {date}

### 资源
- PM: {name}
- Dev: {names}
- Design: {names}
- QA: {names}
```

### 用户故事 (版本化)

```markdown
### US-{id}: {title}

**版本**: {version}
**优先级**: {Must|Should|Could|Won't}
**状态**: {New|Regression|Enhanced}

**用户故事**: 作为 [{actor}]，我希望 [{feature}]，以便 [{value}]。

**验收标准**:
- [ ] {criterion 1}
- [ ] {criterion 2}

**技术备注**:
- API:
- 数据模型:

**测试重点**:
- {test focus}
```

---

### MoSCoW 优先级

| 优先级 | 比例 | 定义 |
|--------|------|------|
| Must | 20-30% | 上线阻塞项 |
| Should | 30-40% | 重要非阻塞 |
| Could | 20-30% | 锦上添花 |
| Won't | 10% | 本期不实现 |

---

### 版本规划示例

```markdown
## v1.0.0: MVP 版本

### 目标
完成核心功能，满足用户基本需求

### Must (上线阻塞)
- [ ] US-001: 用户可以收藏商品
- [ ] US-002: 用户可以查看收藏列表
- [ ] US-003: 用户可以取消收藏

### Should (重要非阻塞)
- [ ] US-004: 收藏时支持备注
- [ ] US-005: 支持批量操作

### Could (锦上添花)
- [ ] US-006: 收藏夹分类
- [ ] US-007: 收藏推荐

### Won't (本期不做)
- [ ] US-008: 跨设备同步
- [ ] US-009: 分享收藏夹
```

## 与其他命令关系

```
/product-toolkit:think [功能]  (产品思考)
        ↓
/product-toolkit:version [功能]  (版本规划)
        ↓
/product-toolkit:user-story [功能]  (用户故事)
        ↓
/product-toolkit:test-case [功能]  (测试用例)
```

## 参考

- `../../references/product-versioning.md` - 产品版本迭代规划
- `../../references/sprint-planning.md` - Sprint 规划
- `../../references/user-story-inheritance.md` - 用户故事继承规则
- `../../config/version-strategy.yaml` - 版本策略配置

---

## 输出目录

工作流模式下输出到: `docs/product/{version}/{category}/{feature}.md`

- 用户故事: `docs/product/{version}/user-story/`
- PRD: `docs/product/{version}/prd/`
- UI设计: `docs/product/{version}/design/`
- 测试用例: `docs/product/{version}/qa/test-cases/`
- 技术方案: `docs/product/{version}/tech/`
