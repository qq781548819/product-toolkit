#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TEAM=""
FORMAT="both"   # json|md|both
OUTPUT_DIR=""

usage() {
  cat <<'USAGE'
Usage:
  team_report.sh --team TEAM [options]

Options:
  --project-root PATH
  --team TEAM
  --format json|md|both
  --output-dir PATH
  -h, --help

Examples:
  team_report.sh --team ptk-v340
  team_report.sh --team ptk-v340 --format json
USAGE
}

require_value() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "Error: missing value for $key" >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-root)
        require_value "$1" "${2:-}"
        PROJECT_ROOT="$2"
        shift 2
        ;;
      --team)
        require_value "$1" "${2:-}"
        TEAM="$2"
        shift 2
        ;;
      --format)
        require_value "$1" "${2:-}"
        FORMAT="$2"
        shift 2
        ;;
      --output-dir)
        require_value "$1" "${2:-}"
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  [[ -n "$TEAM" ]] || { usage; exit 1; }

  local team_dir manifest review gates reports_dir
  team_dir="$PROJECT_ROOT/.ptk/state/team/$TEAM"
  manifest="$team_dir/manifest.json"
  review="$team_dir/review-gates.json"
  reports_dir="${OUTPUT_DIR:-$team_dir/reports}"
  mkdir -p "$reports_dir"

  [[ -f "$manifest" ]] || { echo "Error: manifest not found: $manifest" >&2; exit 1; }

  python3 - "$manifest" "$review" "$team_dir" "$reports_dir" "$FORMAT" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

manifest_file = Path(sys.argv[1])
review_file = Path(sys.argv[2])
team_dir = Path(sys.argv[3])
reports_dir = Path(sys.argv[4])
fmt = sys.argv[5]

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
manifest = json.loads(manifest_file.read_text(encoding="utf-8"))

review = {}
if review_file.exists():
    try:
        review = json.loads(review_file.read_text(encoding="utf-8"))
    except Exception:
        review = {"evaluation": {"status": "Blocked", "reason_codes": ["invalid_review_file"]}}

tasks = []
for task_file in sorted((team_dir / "tasks").glob("*.json")):
    try:
        tasks.append(json.loads(task_file.read_text(encoding="utf-8")))
    except Exception:
        tasks.append({"task_id": task_file.stem, "status": "invalid"})

mailbox = []
for mail_file in sorted((team_dir / "mailbox").glob("*.json")):
    try:
        mailbox.append(json.loads(mail_file.read_text(encoding="utf-8")))
    except Exception:
        pass

task_status_counts = {}
for t in tasks:
    s = str(t.get("status", "unknown"))
    task_status_counts[s] = task_status_counts.get(s, 0) + 1

reason_codes = set()
ev = review.get("evaluation", {}) if isinstance(review.get("evaluation"), dict) else {}
for code in ev.get("reason_codes", []) if isinstance(ev.get("reason_codes"), list) else []:
    reason_codes.add(str(code))
for code in manifest.get("terminal_reason_codes", []) if isinstance(manifest.get("terminal_reason_codes"), list) else []:
    reason_codes.add(str(code))
for event in mailbox:
    for code in event.get("reason_codes", []) if isinstance(event.get("reason_codes"), list) else []:
        reason_codes.add(str(code))

payload = {
    "schema_version": "1.0",
    "generated_at": now,
    "team_name": manifest.get("team_name"),
    "runtime": manifest.get("runtime"),
    "status": manifest.get("status"),
    "current_phase": manifest.get("current_phase"),
    "terminal_status": manifest.get("terminal_status", "Unknown"),
    "fix_loops": {
        "current": manifest.get("fix_loop_count", 0),
        "max": manifest.get("max_fix_loops", 0),
    },
    "phase_history": manifest.get("phase_history", []),
    "review_gates": {
        "spec_status": ((review.get("spec_review") or {}).get("status") if isinstance(review.get("spec_review"), dict) else "pending"),
        "quality_status": ((review.get("quality_review") or {}).get("status") if isinstance(review.get("quality_review"), dict) else "pending"),
        "evaluation_status": ev.get("status", "Blocked"),
        "reason_codes": ev.get("reason_codes", []),
    },
    "tasks": {
        "total": len(tasks),
        "by_status": task_status_counts,
    },
    "workers": manifest.get("workers", []),
    "mailbox_events": len(mailbox),
    "blocked_reason_codes": sorted([c for c in reason_codes if c]),
}

report_prefix = f"{manifest.get('team_name', 'team')}-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
json_path = reports_dir / f"{report_prefix}.json"
md_path = reports_dir / f"{report_prefix}.md"

if fmt in {"json", "both"}:
    json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

if fmt in {"md", "both"}:
    lines = []
    lines.append(f"# Team Runtime Report: {payload['team_name']}")
    lines.append("")
    lines.append(f"- Generated At: `{payload['generated_at']}`")
    lines.append(f"- Runtime: `{payload['runtime']}`")
    lines.append(f"- Status: `{payload['status']}`")
    lines.append(f"- Current Phase: `{payload['current_phase']}`")
    lines.append(f"- Terminal Status: `{payload['terminal_status']}`")
    lines.append(f"- Fix Loops: `{payload['fix_loops']['current']}/{payload['fix_loops']['max']}`")
    lines.append("")
    lines.append("## Review Gates")
    lines.append("")
    lines.append(f"- Spec: `{payload['review_gates']['spec_status']}`")
    lines.append(f"- Quality: `{payload['review_gates']['quality_status']}`")
    lines.append(f"- Evaluation: `{payload['review_gates']['evaluation_status']}`")
    lines.append(f"- Reason Codes: {', '.join(payload['review_gates']['reason_codes']) or 'none'}")
    lines.append("")
    lines.append("## Phase History")
    lines.append("")
    lines.append("| Phase | Timestamp | Note |")
    lines.append("|---|---|---|")
    for item in payload["phase_history"]:
        lines.append(f"| {item.get('phase','')} | {item.get('timestamp','')} | {item.get('note','')} |")
    lines.append("")
    lines.append("## Tasks")
    lines.append("")
    lines.append(f"- Total: {payload['tasks']['total']}")
    for k, v in sorted(payload["tasks"]["by_status"].items()):
        lines.append(f"- {k}: {v}")
    lines.append("")
    lines.append("## Workers")
    lines.append("")
    lines.append("| Worker | Status | Pane | Updated At |")
    lines.append("|---|---|---|---|")
    for w in payload["workers"]:
        lines.append(f"| {w.get('worker_id','')} | {w.get('status','')} | {w.get('pane_id','')} | {w.get('updated_at','')} |")
    lines.append("")
    lines.append(f"- Mailbox events: {payload['mailbox_events']}")
    lines.append(f"- Blocked reason codes: {', '.join(payload['blocked_reason_codes']) or 'none'}")
    lines.append("")
    md_path.write_text("\n".join(lines), encoding="utf-8")

out = {
    "format": fmt,
    "json_report": str(json_path) if fmt in {"json", "both"} else "",
    "md_report": str(md_path) if fmt in {"md", "both"} else "",
}
print(json.dumps(out, ensure_ascii=False, indent=2))
PY
}

main "$@"
