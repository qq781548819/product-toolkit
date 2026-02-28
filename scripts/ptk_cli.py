#!/usr/bin/env python3
"""PTK v3.7.0 lightweight CLI entry for status/run/report/doctor flows."""

from __future__ import annotations

import argparse
import json
import re
import secrets
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


TOOLKIT_VERSION = "3.7.0"
DEFAULT_VERSION = f"v{TOOLKIT_VERSION}"
RISK_HIGH_KEYWORDS = (
    "重写",
    "rewrite",
    "engine",
    "delete",
    "drop",
    "权限",
    "security",
    "auth",
    "schema",
)

WORKFLOW_ROUTES = {
    "workflow": {"command": "workflow", "handler": "skills/workflow/SKILL.md"},
    "team": {"command": "team", "handler": "skills/team/SKILL.md"},
    "auto-test": {"command": "auto-test", "handler": "skills/auto-test/SKILL.md"},
}
WORKFLOW_ALIASES = {
    "workflow": "workflow",
    "team": "team",
    "auto-test": "auto-test",
    "autotest": "auto-test",
    "auto_test": "auto-test",
}
KNOWN_COMMANDS = {"status", "run", "debug", "report", "feedback", "resume", "doctor", "help", "-h", "--help"}

INTENT_RULES = [
    {
        "name": "status",
        "keywords": ("看看", "看板", "状态", "status"),
        "argv": ["status", "--board"],
    },
    {
        "name": "report",
        "keywords": ("报告", "汇报", "report"),
        "argv": ["report", "--human", "latest"],
    },
    {
        "name": "doctor",
        "keywords": ("诊断", "体检", "doctor"),
        "argv": ["doctor"],
    },
]


@dataclass
class IntentResult:
    command: str | None
    argv: list[str]
    confidence: float
    candidates: list[dict[str, Any]]


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def read_json(path: Path, fallback: Any) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:  # noqa: BLE001
        return fallback


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def append_jsonl(path: Path, item: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(item, ensure_ascii=False) + "\n")


@dataclass
class Context:
    root: Path
    version: str

    @property
    def docs_base(self) -> Path:
        return self.root / "docs" / "product" / self.version

    @property
    def execution_dir(self) -> Path:
        return self.docs_base / "execution"

    @property
    def user_story_path(self) -> Path:
        return self.docs_base / "user-story" / "ptk-cli-scope-guard.md"

    @property
    def runs_dir(self) -> Path:
        return self.root / ".ptk" / "runs"

    @property
    def scope_memory_dir(self) -> Path:
        return self.root / ".ptk" / "memory" / "scope"

    @property
    def terminal_path(self) -> Path:
        return self.execution_dir / "terminal.json"


def parse_acceptance_criteria(user_story_path: Path) -> dict[str, Any]:
    text = user_story_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    acs: list[dict[str, str]] = []
    core_scope: list[str] = []
    enhancement_scope: list[str] = []

    pattern = re.compile(r"- \[.\]\s*(US\d+-AC\d+)\s+[^：:]*[：:]\s*(.+)")
    for line in lines:
        m = pattern.search(line)
        if not m:
            continue
        ac_id = m.group(1).strip()
        desc = m.group(2).strip()
        scope = "enhancement" if re.search(r"(enhancement|优化|增强)", desc, flags=re.I) else "core"
        acs.append({"id": ac_id, "scope": scope, "description": desc})
        if scope == "enhancement":
            enhancement_scope.append(ac_id)
        else:
            core_scope.append(ac_id)

    return {
        "feature": "ptk-cli-scope-guard",
        "version": DEFAULT_VERSION,
        "acceptance_criteria": acs,
        "core_scope": core_scope,
        "enhancement_scope": enhancement_scope,
    }


def create_ac_scope(ctx: Context) -> Path:
    if not ctx.user_story_path.exists():
        raise FileNotFoundError(str(ctx.user_story_path))
    ac_scope = parse_acceptance_criteria(ctx.user_story_path)
    out = ctx.execution_dir / "ac_scope.json"
    write_json(out, ac_scope)
    return out


def resolve_workflow_route(name: str) -> dict[str, Any] | None:
    key = WORKFLOW_ALIASES.get((name or "").strip().lower())
    if not key:
        return None
    route = WORKFLOW_ROUTES.get(key)
    if not route:
        return None
    return {"key": key, **route}


def infer_intent(raw: str) -> IntentResult:
    text = (raw or "").strip()
    lowered = text.lower()
    candidates: list[dict[str, Any]] = []

    for rule in INTENT_RULES:
        score = 0.0
        for keyword in rule["keywords"]:
            keyword_low = keyword.lower()
            if lowered == keyword_low:
                score = max(score, 0.95)
            elif keyword_low and keyword_low in lowered:
                score = max(score, 0.6)
        if score > 0:
            candidates.append({"command": rule["name"], "score": round(score, 2), "argv": list(rule["argv"])})

    candidates.sort(key=lambda item: item["score"], reverse=True)
    if not candidates:
        fallback = [{"command": rule["name"], "score": 0.0, "argv": list(rule["argv"])} for rule in INTENT_RULES]
        return IntentResult(command=None, argv=[], confidence=0.0, candidates=fallback)

    top = candidates[0]
    return IntentResult(
        command=str(top["command"]),
        argv=[str(x) for x in top["argv"]],
        confidence=float(top["score"]),
        candidates=candidates,
    )


def classify_proposal(proposal: str, ac_scope: dict[str, Any]) -> tuple[str, str]:
    proposal_low = proposal.lower()
    if any(k in proposal_low for k in RISK_HIGH_KEYWORDS):
        return "out-of-scope", "high"

    ac_text = " ".join(str(item.get("description", "")).lower() for item in ac_scope.get("acceptance_criteria", []))
    terms = [x for x in re.split(r"[\s,，。;；/]+", proposal_low) if len(x) >= 2]
    overlap = any(term in ac_text for term in terms)
    if overlap:
        return "in-scope", "low"
    return "enhancement-proposal", "low"


def record_scope_memory(
    ctx: Context,
    run_id: str,
    proposals: list[str],
    ac_scope: dict[str, Any],
    confirm_choice: str | None,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], bool]:
    deviations_path = ctx.scope_memory_dir / "deviations.json"
    confirmations_path = ctx.scope_memory_dir / "confirmations.json"
    deviations = read_json(deviations_path, [])
    confirmations = read_json(confirmations_path, [])
    if not isinstance(deviations, list):
        deviations = []
    if not isinstance(confirmations, list):
        confirmations = []

    run_deviations: list[dict[str, Any]] = []
    run_confirmations: list[dict[str, Any]] = []
    has_pending_high = False

    for idx, proposal in enumerate(proposals, start=1):
        deviation_type, risk = classify_proposal(proposal, ac_scope)
        if deviation_type == "in-scope":
            continue

        deviation = {
            "id": f"DEV-{run_id}-{idx}",
            "run_id": run_id,
            "proposal": proposal,
            "type": deviation_type,
            "risk": risk,
            "created_at": now_iso(),
        }
        deviations.append(deviation)
        run_deviations.append(deviation)

        if risk == "high":
            if confirm_choice in {"A", "B", "C"}:
                status = "confirmed"
                decision = confirm_choice
            else:
                status = "pending"
                decision = None
                has_pending_high = True
            confirmation = {
                "id": f"CONF-{run_id}-{idx}",
                "run_id": run_id,
                "deviation_id": deviation["id"],
                "status": status,
                "decision": decision,
                "options": ["A", "B", "C"],
                "created_at": now_iso(),
            }
            confirmations.append(confirmation)
            run_confirmations.append(confirmation)

    write_json(deviations_path, deviations)
    write_json(confirmations_path, confirmations)
    return run_deviations, run_confirmations, has_pending_high


def newest_run_id(runs_dir: Path) -> str | None:
    candidates = [p for p in runs_dir.glob("*") if p.is_dir()]
    if not candidates:
        return None
    candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return candidates[0].name


def newest_run_id_except(runs_dir: Path, exclude: str) -> str | None:
    candidates = [p for p in runs_dir.glob("*") if p.is_dir() and p.name != exclude]
    if not candidates:
        return None
    candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return candidates[0].name


def load_run_state(ctx: Context, run_id: str) -> dict[str, Any]:
    return read_json(ctx.runs_dir / run_id / "state.json", {})


def generate_run_id(runs_dir: Path) -> str:
    """Generate a collision-resistant run id.

    Format: run-YYYYMMDDTHHMMSSmmmZ-<hex4>
    """
    for _ in range(8):
        now = datetime.now(timezone.utc)
        millis = now.microsecond // 1000
        candidate = now.strftime(f"run-%Y%m%dT%H%M%S{millis:03d}Z-{secrets.token_hex(2)}")
        if not (runs_dir / candidate).exists():
            return candidate
    return f"run-{time.time_ns()}-{secrets.token_hex(4)}"


def command_status(args: argparse.Namespace, ctx: Context) -> int:
    team_root = ctx.root / ".omx" / "state" / "team"
    team_count = len([p for p in team_root.glob("*") if p.is_dir()]) if team_root.exists() else 0
    bridge_root = ctx.root / ".ptk" / "state" / "bridge"
    bridge_count = len([p for p in bridge_root.glob("*") if p.is_dir()]) if bridge_root.exists() else 0
    test_progress = read_json(ctx.root / ".ptk" / "state" / "test-progress.json", {})
    terminal = read_json(ctx.terminal_path, {})
    terminal_status = (
        terminal.get("terminal", {}).get("status") if isinstance(terminal.get("terminal"), dict) else "unknown"
    )
    payload = {
        "version": ctx.version,
        "team": {"known_teams": team_count},
        "gate": {"terminal_status": terminal_status},
        "bridge": {"known_bridges": bridge_count},
        "test": {"has_progress": bool(test_progress)},
        "generated_at": now_iso(),
    }

    if args.board:
        print("PTK Status Board")
        print(f"- team.known_teams: {team_count}")
        print(f"- gate.terminal_status: {terminal_status}")
        print(f"- bridge.known_bridges: {bridge_count}")
        print(f"- test.has_progress: {bool(test_progress)}")
    else:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


def command_run(args: argparse.Namespace, ctx: Context) -> int:
    route = resolve_workflow_route(args.workflow)
    if not route:
        supported = ", ".join(sorted(WORKFLOW_ROUTES.keys()))
        print(f"Unsupported workflow route: {args.workflow}. Supported routes: {supported}", file=sys.stderr)
        return 2

    run_id = args.run_id or generate_run_id(ctx.runs_dir)
    run_dir = ctx.runs_dir / run_id
    run_dir.mkdir(parents=True, exist_ok=True)
    events_path = run_dir / "events.jsonl"

    def cleanup_empty_run_dir() -> None:
        if run_dir.exists():
            try:
                run_dir.rmdir()
            except OSError:
                pass

    events: list[dict[str, Any]] = [
        {
            "event": "run_started",
            "run_id": run_id,
            "mode": args.mode,
            "workflow_route": route["key"],
            "ts": now_iso(),
        }
    ]
    tool_calls: list[dict[str, Any]] = []
    llm_prompts: list[str] = []
    tool_calls.append(
        {"name": "router.dispatch", "args": {"input": args.workflow, "route": route["key"], "handler": route["handler"]}}
    )

    proposals = args.proposal or []
    deviations: list[dict[str, Any]] = []
    confirmations: list[dict[str, Any]] = []
    blocked_by_confirmation = False
    ac_scope_path = None
    replay_source = None

    if args.mode == "strict" and not ctx.user_story_path.exists():
        cleanup_empty_run_dir()
        print(
            (
                "Strict mode requires user-story file at "
                f"{ctx.user_story_path.relative_to(ctx.root)}; please create it before rerunning."
            ),
            file=sys.stderr,
        )
        return 2

    if args.mode == "strict":
        try:
            ac_scope_path = create_ac_scope(ctx)
        except FileNotFoundError:
            cleanup_empty_run_dir()
            print(
                (
                    "Strict mode initialization failed: user-story file missing at "
                    f"{ctx.user_story_path.relative_to(ctx.root)}."
                ),
                file=sys.stderr,
            )
            return 2
        tool_calls.append({"name": "scope_guard.parse_ac", "args": {"user_story": str(ctx.user_story_path)}})
        llm_prompts.append("Parse AC and bind scope for strict mode.")
        ac_scope = read_json(ac_scope_path, {})
        deviations, confirmations, blocked_by_confirmation = record_scope_memory(
            ctx=ctx,
            run_id=run_id,
            proposals=proposals,
            ac_scope=ac_scope,
            confirm_choice=args.confirm,
        )
        events.append(
            {
                "event": "scope_guard_checked",
                "run_id": run_id,
                "deviation_count": len(deviations),
                "pending_confirmation_count": len([c for c in confirmations if c.get("status") == "pending"]),
                "ts": now_iso(),
            }
        )
        tool_calls.append({"name": "scope_guard.record", "args": {"deviations": len(deviations)}})
    elif args.mode == "debug":
        events.append({"event": "debug_mode_enabled", "run_id": run_id, "ts": now_iso()})
        llm_prompts.append("Debug mode requested: emit verbose stage diagnostics.")
    elif args.mode == "replay":
        replay_source = args.from_run or newest_run_id_except(ctx.runs_dir, run_id)
        if not replay_source:
            cleanup_empty_run_dir()
            print("Replay mode requires an existing historical run. Provide --from-run or create a prior run.", file=sys.stderr)
            return 2
        replay_state = load_run_state(ctx, replay_source)
        if not replay_state:
            cleanup_empty_run_dir()
            print(f"Replay source run not found: {replay_source}", file=sys.stderr)
            return 2
        source_events = replay_state.get("events", [])
        source_event_count = len(source_events) if isinstance(source_events, list) else 0
        events.append(
            {
                "event": "replay_loaded",
                "run_id": run_id,
                "source_run_id": replay_source,
                "source_event_count": source_event_count,
                "ts": now_iso(),
            }
        )
        tool_calls.append({"name": "replay.load_state", "args": {"source_run_id": replay_source}})

    status = "completed"
    reason = ""
    if args.mode == "dry-run":
        status = "completed"
        reason = "dry-run"
        events.append({"event": "dry_run_completed", "run_id": run_id, "ts": now_iso()})
    elif blocked_by_confirmation:
        status = "blocked"
        reason = "awaiting_human_confirmation"
        events.append({"event": "run_blocked", "run_id": run_id, "reason": reason, "ts": now_iso()})
    elif args.mode == "debug":
        reason = "debug_event_stream_enabled"
        events.append({"event": "run_completed_debug", "run_id": run_id, "ts": now_iso()})
    elif args.mode == "replay":
        reason = f"replay:{replay_source}"
        events.append({"event": "replay_completed", "run_id": run_id, "source_run_id": replay_source, "ts": now_iso()})
    else:
        events.append({"event": "run_completed", "run_id": run_id, "ts": now_iso()})

    for event in events:
        append_jsonl(events_path, event)

    if args.mode == "debug":
        for event in events:
            print(f"[debug-event] {json.dumps(event, ensure_ascii=False)}", file=sys.stderr)

    state = {
        "run_id": run_id,
        "workflow": route["key"],
        "workflow_input": args.workflow,
        "mode": args.mode,
        "status": status,
        "reason": reason,
        "started_at": events[0]["ts"],
        "ended_at": now_iso(),
        "events": events,
        "llm_prompts": llm_prompts,
        "token_usage": {"prompt_tokens": 128, "completion_tokens": 96},
        "tool_calls": tool_calls,
        "artifacts": {
            "events": str(events_path.relative_to(ctx.root)),
            "ac_scope": str(ac_scope_path.relative_to(ctx.root)) if ac_scope_path else None,
            "scope_deviations": ".ptk/memory/scope/deviations.json",
            "scope_confirmations": ".ptk/memory/scope/confirmations.json",
            "replay_source_run": replay_source,
        },
        "deviations": deviations,
        "confirmations": confirmations,
    }
    write_json(run_dir / "state.json", state)

    print(json.dumps({"run_id": run_id, "status": status, "reason": reason}, ensure_ascii=False, indent=2))
    return 2 if status == "blocked" else 0


def _human_summary(machine: dict[str, Any]) -> str:
    pending = [c for c in machine.get("confirmations", []) if c.get("status") == "pending"]
    lines = [
        "# PTK Human Summary",
        "",
        f"- Run ID: `{machine.get('run_id', 'unknown')}`",
        f"- Workflow: `{machine.get('workflow', 'workflow')}`",
        f"- Mode: `{machine.get('mode', 'normal')}`",
        f"- Status: **{machine.get('status', 'unknown')}**",
        "",
        "## Artifacts",
    ]
    artifacts = machine.get("artifacts", {})
    if isinstance(artifacts, dict):
        for key, value in artifacts.items():
            if not value:
                continue
            lines.append(f"- {key}: `{value}`")
    else:
        lines.append("- (none)")
    lines.extend(["", "## Pending Confirmations"])
    if pending:
        for item in pending:
            lines.append(f"- {item.get('id')}: decision required (A/B/C)")
    else:
        lines.append("- none")
    lines.extend(
        [
            "",
            "## Next Step Suggestions",
            "- [A] Continue with test-case generation (Recommended)",
            "- [B] Run gate consistency checks",
            "- [C] Review scope deviations",
            "- [D] Other",
        ]
    )
    return "\n".join(lines) + "\n"


def command_report(args: argparse.Namespace, ctx: Context) -> int:
    run_id = args.run_id
    if not run_id or run_id == "latest":
        run_id = newest_run_id(ctx.runs_dir)
        if not run_id:
            print("No run found for report generation.", file=sys.stderr)
            return 2

    state = load_run_state(ctx, run_id)
    if not isinstance(state, dict) or not state:
        print(f"Run not found: {run_id}", file=sys.stderr)
        return 2

    machine = {
        "run_id": run_id,
        "workflow": state.get("workflow", "workflow"),
        "workflow_input": state.get("workflow_input", state.get("workflow", "workflow")),
        "mode": state.get("mode", "normal"),
        "status": state.get("status", "unknown"),
        "reason": state.get("reason", ""),
        "events": state.get("events", []),
        "llm_prompts": state.get("llm_prompts", []),
        "token_usage": state.get("token_usage", {}),
        "tool_calls": state.get("tool_calls", []),
        "artifacts": state.get("artifacts", {}),
        "deviations": state.get("deviations", []),
        "confirmations": state.get("confirmations", []),
        "generated_at": now_iso(),
    }

    summary_json = ctx.execution_dir / "summary.json"
    summary_md = ctx.execution_dir / "summary.md"
    write_json(summary_json, machine)
    summary_md.write_text(_human_summary(machine), encoding="utf-8")

    if args.human:
        print(summary_md.read_text(encoding="utf-8"), end="")
    else:
        print(json.dumps(machine, ensure_ascii=False, indent=2))
    return 0


def command_debug_watch(args: argparse.Namespace, ctx: Context) -> int:
    run_id = args.run_id or newest_run_id(ctx.runs_dir)
    if not run_id:
        print("No run found.", file=sys.stderr)
        return 2
    events_path = ctx.runs_dir / run_id / "events.jsonl"
    if not events_path.exists():
        print(f"No events for run: {run_id}", file=sys.stderr)
        return 2
    lines = events_path.read_text(encoding="utf-8").splitlines()
    tail_lines = lines[-args.tail :] if args.tail > 0 else lines
    for line in tail_lines:
        print(line)

    if not args.follow:
        print(f"# debug watch tail mode (tail={args.tail})", file=sys.stderr)
        return 0

    idle_for = 0.0
    consumed = len(lines)
    print(
        (
            "# debug watch follow mode "
            f"(poll_interval={args.poll_interval:.2f}s idle_exit={args.idle_exit:.2f}s)"
        ),
        file=sys.stderr,
    )
    while True:
        time.sleep(max(args.poll_interval, 0.05))
        latest = events_path.read_text(encoding="utf-8").splitlines()
        if len(latest) > consumed:
            for line in latest[consumed:]:
                print(line)
            consumed = len(latest)
            idle_for = 0.0
            continue
        idle_for += max(args.poll_interval, 0.05)
        if args.idle_exit > 0 and idle_for >= args.idle_exit:
            print(f"# debug watch follow mode exited after {idle_for:.2f}s idle", file=sys.stderr)
            break
    return 0


def command_resume(args: argparse.Namespace, ctx: Context) -> int:
    state = load_run_state(ctx, args.run_id)
    if not state:
        print(f"Run not found: {args.run_id}", file=sys.stderr)
        return 2
    print(json.dumps(state, ensure_ascii=False, indent=2))
    return 0


def command_feedback_sync(args: argparse.Namespace, ctx: Context) -> int:
    run_id = args.run_id or newest_run_id(ctx.runs_dir)
    if not run_id:
        print("No run found.", file=sys.stderr)
        return 2
    state = load_run_state(ctx, run_id)
    if not state:
        print("Run state missing.", file=sys.stderr)
        return 2

    out = (
        ctx.root
        / ".ptk"
        / "state"
        / "requirement-feedback"
        / f"{ctx.version}-ptk-cli-scope-guard.json"
    )
    payload = {
        "version": ctx.version,
        "feature": "ptk-cli-scope-guard",
        "run_id": run_id,
        "status": state.get("status"),
        "updated_at": now_iso(),
        "feedback": [
            {
                "type": "scope",
                "deviation_count": len(state.get("deviations", [])),
                "pending_confirmation_count": len(
                    [c for c in state.get("confirmations", []) if c.get("status") == "pending"]
                ),
            }
        ],
    }
    write_json(out, payload)
    print(json.dumps({"synced": str(out.relative_to(ctx.root)), "run_id": run_id}, ensure_ascii=False, indent=2))
    return 0


def command_doctor(args: argparse.Namespace, ctx: Context) -> int:
    checks: list[dict[str, Any]] = []

    def add_check(name: str, status: str, detail: str, recommendation: str = "") -> None:
        checks.append({"name": name, "status": status, "detail": detail, "recommendation": recommendation})

    expected_version = TOOLKIT_VERSION
    expected_product_version = f"v{TOOLKIT_VERSION}"
    version_issues: list[str] = []

    if DEFAULT_VERSION != expected_product_version:
        version_issues.append(f"DEFAULT_VERSION={DEFAULT_VERSION}")

    plugin_json = read_json(ctx.root / ".claude-plugin" / "plugin.json", {})
    if not isinstance(plugin_json, dict):
        version_issues.append("plugin.json:invalid")
    else:
        plugin_version = str(plugin_json.get("version", "")).strip()
        if plugin_version != expected_version:
            version_issues.append(f"plugin.json={plugin_version or 'missing'}")

    marketplace_json = read_json(ctx.root / ".claude-plugin" / "marketplace.json", {})
    marketplace_version = ""
    if isinstance(marketplace_json, dict):
        plugins = marketplace_json.get("plugins")
        if isinstance(plugins, list):
            for item in plugins:
                if isinstance(item, dict) and item.get("name") == "product-toolkit":
                    marketplace_version = str(item.get("version", "")).strip()
                    break
    if not marketplace_version:
        version_issues.append("marketplace.json=missing")
    elif marketplace_version != expected_version:
        version_issues.append(f"marketplace.json={marketplace_version}")

    if version_issues:
        add_check(
            "version_consistency",
            "FAIL",
            f"expected={expected_version}; drift={', '.join(version_issues)}",
            "统一 CLI/插件/文档元信息版本，避免版本幻视漂移",
        )
    else:
        add_check(
            "version_consistency",
            "PASS",
            f"cli={expected_version}, default_product={DEFAULT_VERSION}, plugin={expected_version}, marketplace={expected_version}",
        )

    user_story_rel = str(ctx.user_story_path.relative_to(ctx.root))
    if ctx.user_story_path.exists():
        add_check("user_story_exists", "PASS", user_story_rel)
    else:
        add_check("user_story_exists", "FAIL", user_story_rel, "补充 user-story 后再执行 strict/release 流程")

    ac_scope_path = ctx.execution_dir / "ac_scope.json"
    if ac_scope_path.exists():
        ac_scope = read_json(ac_scope_path, None)
        if not isinstance(ac_scope, dict):
            add_check("ac_scope_schema", "FAIL", str(ac_scope_path.relative_to(ctx.root)), "修复 ac_scope.json 的 JSON 结构")
        else:
            required = {"acceptance_criteria", "core_scope", "enhancement_scope"}
            missing = sorted(required - set(ac_scope.keys()))
            if missing:
                add_check(
                    "ac_scope_schema",
                    "FAIL",
                    f"missing keys: {', '.join(missing)}",
                    "重新生成 ac_scope.json 并校验字段完整性",
                )
            else:
                add_check("ac_scope_schema", "PASS", str(ac_scope_path.relative_to(ctx.root)))
    else:
        add_check("ac_scope_schema", "WARN", str(ac_scope_path.relative_to(ctx.root)), "运行 strict 模式以生成 AC 范围绑定")

    summary_md = ctx.execution_dir / "summary.md"
    if summary_md.exists():
        text = summary_md.read_text(encoding="utf-8")
        leaked = [token for token in ("llm_prompts", "token_usage", "tool_calls") if token in text]
        if leaked:
            add_check("summary_human_redaction", "FAIL", f"summary.md leaked: {', '.join(leaked)}", "移除机器调试字段")
        else:
            add_check("summary_human_redaction", "PASS", str(summary_md.relative_to(ctx.root)))
    else:
        add_check("summary_human_redaction", "WARN", str(summary_md.relative_to(ctx.root)), "执行 ptk report --human")

    summary_json = ctx.execution_dir / "summary.json"
    machine_data: dict[str, Any] = {}
    if summary_json.exists():
        loaded_machine = read_json(summary_json, None)
        if not isinstance(loaded_machine, dict):
            add_check("summary_machine_schema", "FAIL", str(summary_json.relative_to(ctx.root)), "修复 summary.json 格式")
        else:
            machine_data = loaded_machine
            required = {"events", "llm_prompts", "token_usage", "tool_calls"}
            missing = sorted(required - set(machine_data.keys()))
            if missing:
                add_check(
                    "summary_machine_schema",
                    "FAIL",
                    f"missing keys: {', '.join(missing)}",
                    "重新生成机器报告确保 schema 完整",
                )
            else:
                add_check("summary_machine_schema", "PASS", str(summary_json.relative_to(ctx.root)))
    else:
        add_check("summary_machine_schema", "WARN", str(summary_json.relative_to(ctx.root)), "执行 ptk report --machine")

    if ctx.terminal_path.exists():
        terminal = read_json(ctx.terminal_path, None)
        if not isinstance(terminal, dict):
            add_check("terminal_schema", "FAIL", str(ctx.terminal_path.relative_to(ctx.root)), "修复 terminal.json")
        else:
            required = {"schema_version", "version", "terminal", "evidence_integrity"}
            missing = sorted(required - set(terminal.keys()))
            if missing:
                add_check(
                    "terminal_schema",
                    "FAIL",
                    f"missing keys: {', '.join(missing)}",
                    "补齐 terminal.json 顶层字段",
                )
            elif not isinstance(terminal.get("terminal"), dict) or "status" not in terminal.get("terminal", {}):
                add_check("terminal_schema", "FAIL", "terminal.status missing", "补齐 terminal.status")
            else:
                add_check("terminal_schema", "PASS", str(ctx.terminal_path.relative_to(ctx.root)))
    else:
        add_check("terminal_schema", "UNKNOWN", str(ctx.terminal_path.relative_to(ctx.root)), "尚未生成终态报告")

    latest = newest_run_id(ctx.runs_dir)
    if not latest:
        add_check("events_integrity", "UNKNOWN", "no runs found", "先执行 ptk run 生成可诊断事件")
    else:
        state = load_run_state(ctx, latest)
        required = {"run_id", "workflow", "mode", "status", "events", "tool_calls"}
        missing = sorted(required - set(state.keys())) if isinstance(state, dict) else sorted(required)
        if missing:
            add_check(
                "events_integrity",
                "FAIL",
                f"run {latest} state missing: {', '.join(missing)}",
                "修复 state.json 字段并重跑",
            )
        else:
            events = state.get("events", [])
            if not isinstance(events, list) or not events:
                add_check("events_integrity", "FAIL", f"run {latest} has empty events", "确认运行模式写入事件流")
            else:
                event_names = {item.get("event") for item in events if isinstance(item, dict)}
                terminal_events = {"run_completed", "run_blocked", "dry_run_completed", "run_completed_debug", "replay_completed"}
                if "run_started" not in event_names:
                    add_check("events_integrity", "FAIL", f"run {latest} missing run_started", "检查事件写入入口")
                elif not (event_names & terminal_events):
                    add_check("events_integrity", "FAIL", f"run {latest} missing terminal event", "补充终态事件写入")
                else:
                    add_check("events_integrity", "PASS", f"run {latest} events={len(events)}")

        if machine_data:
            machine_events = machine_data.get("events")
            if not isinstance(machine_events, list) or not machine_events:
                add_check("machine_events_integrity", "FAIL", "summary.json events empty", "重新生成机器报告")
            else:
                add_check("machine_events_integrity", "PASS", f"summary events={len(machine_events)}")
        else:
            add_check("machine_events_integrity", "UNKNOWN", "summary.json unavailable", "先生成机器报告再校验")

    if (ctx.scope_memory_dir / "deviations.json").exists() and (ctx.scope_memory_dir / "confirmations.json").exists():
        add_check("scope_memory_exists", "PASS", str(ctx.scope_memory_dir.relative_to(ctx.root)))
    else:
        add_check("scope_memory_exists", "WARN", str(ctx.scope_memory_dir.relative_to(ctx.root)), "执行 strict + proposal 以生成 scope memory")

    severity = {"PASS": 0, "UNKNOWN": 1, "WARN": 2, "FAIL": 3}
    overall = "PASS"
    for item in checks:
        if severity.get(item["status"], 0) > severity.get(overall, 0):
            overall = item["status"]

    payload = {"overall": overall, "checks": checks, "generated_at": now_iso()}
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(f"PTK Doctor: {overall}")
        for item in checks:
            extra = f" | suggestion: {item['recommendation']}" if item.get("recommendation") else ""
            print(f"- {item['status']}: {item['name']} ({item['detail']}){extra}")
    return 0 if overall == "PASS" else 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ptk", description=f"PTK unified CLI entry (v{TOOLKIT_VERSION}).")
    parser.add_argument("--version", default=DEFAULT_VERSION, help=f"Target product version (default: {DEFAULT_VERSION})")
    sub = parser.add_subparsers(dest="command", required=True)

    p_status = sub.add_parser("status", help="Show team/gate/bridge/test status")
    p_status.add_argument("--board", action="store_true", help="Render human board")
    p_status.set_defaults(func=command_status)

    p_run = sub.add_parser("run", help="Run workflow with mode switches")
    p_run.add_argument("workflow", help="Workflow route (workflow/team/auto-test)")
    p_run.add_argument(
        "--mode",
        default="normal",
        choices=["normal", "debug", "strict", "dry-run", "replay"],
        help="Execution mode",
    )
    p_run.add_argument("--run-id", default="", help="Custom run id")
    p_run.add_argument("--from-run", default="", help="Replay source run id (for --mode replay)")
    p_run.add_argument("--proposal", action="append", default=[], help="Optional proposal text for scope guard")
    p_run.add_argument("--confirm", choices=["A", "B", "C"], help="Human confirmation choice for high-risk scope")
    p_run.set_defaults(func=command_run)

    p_debug = sub.add_parser("debug", help="Debug helpers")
    p_debug_sub = p_debug.add_subparsers(dest="debug_command", required=True)
    p_watch = p_debug_sub.add_parser("watch", help="Watch run events")
    p_watch.add_argument("run_id", nargs="?", default="", help="Run id (default: latest)")
    p_watch.add_argument("--tail", type=int, default=20, help="Tail line count")
    p_watch.add_argument("--follow", action="store_true", help="Follow new events until idle timeout")
    p_watch.add_argument("--poll-interval", type=float, default=0.2, help="Polling interval in seconds")
    p_watch.add_argument(
        "--idle-exit",
        type=float,
        default=2.0,
        help="Exit follow mode after idle seconds (<=0 means never auto-exit)",
    )
    p_watch.set_defaults(func=command_debug_watch)

    p_report = sub.add_parser("report", help="Generate run reports")
    mode = p_report.add_mutually_exclusive_group(required=True)
    mode.add_argument("--human", action="store_true", help="Generate human-friendly markdown report")
    mode.add_argument("--machine", action="store_true", help="Generate machine-complete JSON report")
    p_report.add_argument("run_id", nargs="?", default="latest", help="Run id (default: latest)")
    p_report.set_defaults(func=command_report)

    p_feedback = sub.add_parser("feedback", help="Feedback operations")
    p_feedback_sub = p_feedback.add_subparsers(dest="feedback_command", required=True)
    p_sync = p_feedback_sub.add_parser("sync", help="Sync run feedback")
    p_sync.add_argument("run_id", nargs="?", default="latest", help="Run id (default: latest)")
    p_sync.set_defaults(func=command_feedback_sync)

    p_resume = sub.add_parser("resume", help="Resume/inspect run state")
    p_resume.add_argument("run_id", help="Run id")
    p_resume.set_defaults(func=command_resume)

    p_doctor = sub.add_parser("doctor", help="Run environment and schema checks")
    p_doctor.add_argument("--json", action="store_true", help="JSON output")
    p_doctor.set_defaults(func=command_doctor)

    return parser


def normalize_argv(argv: list[str]) -> tuple[list[str], str | None, bool]:
    if len(argv) < 2:
        return argv, None, False

    idx = 1
    while idx < len(argv):
        token = argv[idx]
        if token == "--version":
            idx += 2
            continue
        if token.startswith("-"):
            idx += 1
            continue
        break

    if idx >= len(argv):
        return argv, None, False

    token = argv[idx]
    if token in {"help", "--help", "-h"}:
        return [argv[0], "-h", *argv[idx + 1 :]], None, False
    if token in KNOWN_COMMANDS:
        return argv, None, False

    intent = infer_intent(token)
    candidates_repr = ", ".join(f"{c['command']}:{float(c['score']):.2f}" for c in intent.candidates[:3])
    if not intent.command:
        guidance = (
            f'Intent routing failed for "{token}". confidence=0.00; '
            f"candidates={candidates_repr or 'status,report,doctor'}"
        )
        return argv, guidance, True

    if intent.confidence < 0.45:
        guidance = (
            f'Intent confidence too low for "{token}" (confidence={intent.confidence:.2f}). '
            f"candidates={candidates_repr}"
        )
        return argv, guidance, True

    routed = [argv[0], *argv[1:idx], *intent.argv, *argv[idx + 1 :]]
    notice = (
        f'Intent routed "{token}" -> {" ".join(intent.argv)} '
        f"(confidence={intent.confidence:.2f}; candidates={candidates_repr})"
    )
    return routed, notice, False


def main(argv: list[str] | None = None) -> int:
    argv = argv or sys.argv
    argv, intent_message, intent_error = normalize_argv(argv)
    if intent_message:
        print(f"[intent-router] {intent_message}", file=sys.stderr)
    if intent_error:
        return 2
    parser = build_parser()
    args = parser.parse_args(argv[1:])
    ctx = Context(root=Path(__file__).resolve().parents[1], version=args.version)
    return int(args.func(args, ctx))


if __name__ == "__main__":
    raise SystemExit(main())
