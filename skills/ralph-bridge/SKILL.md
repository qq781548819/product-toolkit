---
name: ralph-bridge
description: Bridge OMX/OMC Ralph long-task runtime with PTK team/verify acceptance loop
---

# Ralph Bridge（v3.5.0）

统一桥接长任务控制流与 PTK 验收闭环。

## 命令入口

```bash
./scripts/ralph_bridge.sh start --team <name> --runtime omx|omc|auto --task "..."
./scripts/ralph_bridge.sh resume --team <name> --version <v> --feature <feature> --test-file <path> [--manual-results <json>]
./scripts/ralph_bridge.sh status --team <name>
./scripts/ralph_bridge.sh finalize --team <name> --terminal-status Pass|Blocked|Cancelled
```

## 关键行为

1. 运行时解析：`auto` 按 `PTK_BRIDGE_RUNTIME_PREFERENCE` 或默认 `omx -> omc`
2. 状态映射：
   - `team-plan/prd/exec` -> `executing`
   - `team-verify` -> `verifying`
   - `team-fix` -> `fixing`
   - `terminal(Pass/Blocked/Cancelled)` -> `complete/failed/cancelled`
3. verify 阶段强制编排：
   - `auto_test.sh`
   - `review_gate.sh evaluate`
   - `team_report.sh`
4. bridge 状态落盘：`.ptk/state/bridge/<team>/ralph-link.json`（并同步 latest 快照到 `.ptk/state/bridge/ralph-link.json`）

## 验收建议

```bash
# 1) 启动
./scripts/ralph_bridge.sh start --team rb-v350 --runtime auto --team-runtime file --task "v3.5.0 bridge"

# 2) 推进阶段（执行 3 次，第三次会触发 verify）
./scripts/ralph_bridge.sh resume --team rb-v350 --version v3.5.0 --feature ralph-bridge \
  --test-file docs/product/v3.5.0/qa/test-cases/ralph-bridge.md \
  --manual-results docs/product/v3.5.0/qa/manual-results/v3.5.0-ralph-bridge-pass.json \
  --no-frontend-start

# 3) 查看状态
./scripts/ralph_bridge.sh status --team rb-v350
```

期望终态：`terminal_status=Pass`，并且 `verification.overall_status=Pass`。
