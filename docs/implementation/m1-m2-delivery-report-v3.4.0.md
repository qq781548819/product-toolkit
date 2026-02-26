# M1/M2 交付报告（v3.4.0）

**日期**: 2026-02-26  
**结论**: 可验证 / 可交付 / 可测试

## 1) 任务状态

| 任务 | 状态 | 关键产物 |
|---|---|---|
| PTK-M1-01/02 | ✅ | `.ptk/memory/*schema.json` |
| PTK-M1-03 | ✅ | `scripts/migrate_memory_v3.py` |
| PTK-M1-04 | ✅ | `skills/remember/SKILL.md`, `skills/recall/SKILL.md`, `README.md` |
| PTK-M1-05 | ✅ | `config/persistence.yaml`, `skills/gate/SKILL.md`, `skills/workflow/SKILL.md`, `SKILL.md`, `commands/product-toolkit.md` |
| PTK-M1-06 | ✅ | `scripts/auto_test.sh`, `config/strict-reason-codes.yaml` |
| PTK-M1-07 | ✅ | `.ptk/state/requirement-feedback.schema.json`, `scripts/feedback_from_test.py` |
| PTK-M1-08 | ✅ | `scripts/auto_test.sh`（自动挂接 feedback） |
| PTK-M1-09 | ✅ | `skills/think/SKILL.md`, `skills/workflow/SKILL.md`, `README.md` |
| PTK-M2-01/03/04 | ✅ | `scripts/team_runtime.sh`（file/tmux/auto） |
| PTK-M2-02 | ✅ | `.ptk/state/team-state.schema.json` |
| PTK-M2-05 | ✅ | `scripts/review_gate.sh`, `.ptk/state/review-gates.schema.json` |
| PTK-M2-06 | ✅ | `config/workflow.yaml`, `scripts/team_runtime.sh` |
| PTK-M2-07 | ✅ | `scripts/team_handoff.py` + runtime 自动调用 |
| PTK-M2-08 | ✅ | `skills/team/SKILL.md`, `commands/product-toolkit.md`, `README.md` |
| PTK-M2-09 | ✅ | `scripts/team_report.sh`, `docs/qa-standards-playbook.md` |

## 2) 版本产物

- `docs/product/v3.4.0/SUMMARY.md`
- `docs/product/v3.4.0/prd/product-toolkit-platform.md`
- `docs/product/v3.4.0/user-story/product-toolkit-platform.md`
- `docs/product/v3.4.0/qa/test-cases/product-toolkit-platform.md`
- `docs/product/v3.4.0/feedback/README.md`
- `docs/product/feedback/README.md`

## 3) 验证命令（建议）

```bash
# schema
for f in .ptk/memory/*.schema.json .ptk/state/*.schema.json; do python3 -m json.tool "$f" >/dev/null; done

# scripts help
python3 scripts/migrate_memory_v3.py --help
python3 scripts/feedback_from_test.py --help
python3 scripts/team_handoff.py --help
./scripts/team_runtime.sh --help
./scripts/review_gate.sh --help
./scripts/team_report.sh --help

# runtime smoke
./scripts/team_runtime.sh start --team demo-v340 --runtime file --task "smoke"
./scripts/team_runtime.sh status --team demo-v340
./scripts/team_runtime.sh resume --team demo-v340
./scripts/team_runtime.sh shutdown --team demo-v340 --terminal-status Cancelled
```
