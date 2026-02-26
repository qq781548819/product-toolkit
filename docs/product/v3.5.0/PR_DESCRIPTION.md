# PR: feat(v3.5.0) Ralph Bridge 长任务桥接与验收闭环

## 背景

v3.5.0 目标是打通 OMX/OMC 长任务执行流与 PTK 验收流，避免“执行完成但未验收闭环”的假完成状态。

## 主要变更

### 1) 新增 Ralph Bridge 执行入口
- 新增脚本：`scripts/ralph_bridge.sh`
- 子命令：`start | resume | status | finalize`
- 运行时支持：`omx | omc | auto`
- 桥接状态：`.ptk/state/bridge/ralph-link.json`

### 2) verify 阶段三段式编排（强制顺序）
1. `auto_test.sh`
2. `review_gate.sh evaluate`
3. `team_report.sh --format both`

未通过时自动进入 fix loop，达到阈值后终态 `Blocked`。

### 3) 状态契约与技能文档补齐
- 新增 schema：`.ptk/state/bridge/ralph-link.schema.json`
- 新增 skill：`skills/ralph-bridge/SKILL.md`
- 更新入口文档：
  - `SKILL.md`
  - `commands/product-toolkit.md`
  - `README.md`

### 4) v3.5.0 产品文档与验收资产
- `docs/product/v3.5.0/prd/ralph-bridge.md`
- `docs/product/v3.5.0/user-story/ralph-bridge.md`
- `docs/product/v3.5.0/qa/test-cases/ralph-bridge.md`
- `docs/product/v3.5.0/qa/manual-results/v3.5.0-ralph-bridge-pass.json`
- `docs/product/v3.5.0/qa/manual-results/v3.5.0-ralph-bridge-acceptance.md`

## 验收结果

- Bridge Session: `rb-20260226-092854`
- Runtime: `omx (requested=auto)`
- Team Terminal: `Pass`
- Verify Overall: `Pass`
- Auto-test session: `.ptk/state/test-sessions/v3.5.0-ralph-bridge-20260226T092856Z.json`

## 关键验证命令

```bash
./scripts/ralph_bridge.sh start --team rb-v350 --runtime auto --team-runtime file --task "v3.5.0 ralph bridge acceptance"
./scripts/ralph_bridge.sh resume --team rb-v350 --runtime auto --version v3.5.0 --feature ralph-bridge --test-file docs/product/v3.5.0/qa/test-cases/ralph-bridge.md --manual-results docs/product/v3.5.0/qa/manual-results/v3.5.0-ralph-bridge-pass.json --no-frontend-start
./scripts/ralph_bridge.sh status --team rb-v350 --runtime auto
```

## 风险与回滚

- 风险：`runtime=auto` 的优先策略依赖 `PTK_BRIDGE_RUNTIME_PREFERENCE`（默认 omx -> omc）
- 回滚：可退回手工路径（`team_runtime + review_gate + team_report`）

## Checklist

- [x] PRD / 用户故事 / 测试用例齐备
- [x] Bridge 状态映射与 schema 落地
- [x] verify 三段式闭环编排已实现
- [x] 验收通过（terminal=Pass）
