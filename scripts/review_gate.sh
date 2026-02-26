#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TEAM=""
COMMAND=""
STATUS_VALUE=""
REVIEWER=""
EVIDENCE=""
REASON_CODES=""
CRITICAL_OPEN=0
HIGH_OPEN=0
MAX_FIX_LOOPS=""
JSON_OUTPUT=false

usage() {
  cat <<'USAGE'
Usage:
  review_gate.sh --team TEAM <command> [options]

Commands:
  init
  spec      --status pass|blocked [--reviewer NAME] [--evidence a,b] [--reason-codes a,b]
  quality   --status pass|blocked [--reviewer NAME] [--evidence a,b] [--reason-codes a,b]
  evaluate  [--critical-open N] [--high-open N]
  status    [--json]

Global options:
  --project-root PATH
  --team TEAM
  --max-fix-loops N
  --json
  -h, --help
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

load_default_max_fix_loops() {
  python3 - "$PROJECT_ROOT/config/workflow.yaml" <<'PY'
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
default = 3
if p.exists():
    text = p.read_text(encoding="utf-8")
    m = re.search(r"^\s*max_fix_loops:\s*(\d+)\s*$", text, flags=re.M)
    if m:
        default = int(m.group(1))
print(default)
PY
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
      --status)
        require_value "$1" "${2:-}"
        STATUS_VALUE="$2"
        shift 2
        ;;
      --reviewer)
        require_value "$1" "${2:-}"
        REVIEWER="$2"
        shift 2
        ;;
      --evidence)
        require_value "$1" "${2:-}"
        EVIDENCE="$2"
        shift 2
        ;;
      --reason-codes)
        require_value "$1" "${2:-}"
        REASON_CODES="$2"
        shift 2
        ;;
      --critical-open)
        require_value "$1" "${2:-}"
        CRITICAL_OPEN="$2"
        shift 2
        ;;
      --high-open)
        require_value "$1" "${2:-}"
        HIGH_OPEN="$2"
        shift 2
        ;;
      --max-fix-loops)
        require_value "$1" "${2:-}"
        MAX_FIX_LOOPS="$2"
        shift 2
        ;;
      --json)
        JSON_OUTPUT=true
        shift
        ;;
      init|spec|quality|evaluate|status)
        COMMAND="$1"
        shift
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

split_csv_py='
def split_csv(raw):
    if not raw:
        return []
    out = []
    seen = set()
    for item in str(raw).split(","):
        item = item.strip()
        if not item or item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out
'

main() {
  parse_args "$@"

  if [[ -z "$TEAM" || -z "$COMMAND" ]]; then
    usage
    exit 1
  fi

  if [[ -z "$MAX_FIX_LOOPS" ]]; then
    MAX_FIX_LOOPS="$(load_default_max_fix_loops)"
  fi

  local team_dir gate_file
  team_dir="$PROJECT_ROOT/.ptk/state/team/$TEAM"
  gate_file="$team_dir/review-gates.json"
  mkdir -p "$team_dir"

  case "$COMMAND" in
    init)
      python3 - "$gate_file" "$TEAM" "$MAX_FIX_LOOPS" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
team = sys.argv[2]
max_fix_loops = int(sys.argv[3])
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

payload = {
    "schema_version": "1.0",
    "team_name": team,
    "created_at": now,
    "updated_at": now,
    "spec_review": {"status": "pending", "updated_at": now},
    "quality_review": {"status": "pending", "updated_at": now},
    "policy": {
        "spec_then_quality": True,
        "critical_high_blocking": True,
        "max_fix_loops": max_fix_loops,
    },
    "evaluation": {
        "status": "Blocked",
        "reason_codes": ["review_not_evaluated"],
        "critical_open": 0,
        "high_open": 0,
    },
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
      ;;
    spec|quality)
      if [[ "$STATUS_VALUE" != "pass" && "$STATUS_VALUE" != "blocked" ]]; then
        echo "Error: --status must be pass|blocked" >&2
        exit 1
      fi
      python3 - "$gate_file" "$COMMAND" "$STATUS_VALUE" "$REVIEWER" "$EVIDENCE" "$REASON_CODES" <<PY
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

$split_csv_py

path = Path(sys.argv[1])
review_key = "spec_review" if sys.argv[2] == "spec" else "quality_review"
status = sys.argv[3]
reviewer = sys.argv[4]
evidence = split_csv(sys.argv[5])
reason_codes = split_csv(sys.argv[6])

if not path.exists():
    raise SystemExit("review-gates file not found. run init first.")

data = json.loads(path.read_text(encoding="utf-8"))
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

if review_key == "quality_review":
    spec_status = ((data.get("spec_review") or {}).get("status") or "").lower()
    if spec_status != "pass":
        raise SystemExit("quality review blocked: spec review must pass first")

node = data.setdefault(review_key, {})
node["status"] = status
if reviewer:
    node["reviewer"] = reviewer
if evidence:
    node["evidence_ref"] = evidence
if reason_codes:
    node["reason_codes"] = reason_codes
node["updated_at"] = now
data["updated_at"] = now

path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({
    "team_name": data.get("team_name"),
    "updated_review": review_key,
    "status": status,
    "reason_codes": reason_codes,
    "updated_at": now,
}, ensure_ascii=False, indent=2))
PY
      ;;
    evaluate)
      python3 - "$gate_file" "$CRITICAL_OPEN" "$HIGH_OPEN" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
critical_open = int(sys.argv[2])
high_open = int(sys.argv[3])

if not path.exists():
    raise SystemExit("review-gates file not found. run init first.")

data = json.loads(path.read_text(encoding="utf-8"))
policy = data.get("policy", {}) if isinstance(data.get("policy"), dict) else {}
spec_status = str((data.get("spec_review") or {}).get("status") or "pending").lower()
quality_status = str((data.get("quality_review") or {}).get("status") or "pending").lower()

reasons = []
if spec_status != "pass":
    reasons.append("spec_not_passed")
if quality_status != "pass":
    reasons.append("quality_not_passed")

if bool(policy.get("critical_high_blocking", True)):
    if critical_open > 0:
        reasons.append("critical_open_items")
    if high_open > 0:
        reasons.append("high_open_items")

status = "Pass" if not reasons else "Blocked"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

data["evaluation"] = {
    "status": status,
    "reason_codes": reasons,
    "critical_open": critical_open,
    "high_open": high_open,
}
data["updated_at"] = now
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps(data["evaluation"], ensure_ascii=False, indent=2))
PY
      ;;
    status)
      if [[ ! -f "$gate_file" ]]; then
        echo "review-gates file not found: $gate_file" >&2
        exit 1
      fi
      if [[ "$JSON_OUTPUT" == true ]]; then
        cat "$gate_file"
      else
        python3 - "$gate_file" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
spec = data.get("spec_review", {}).get("status", "pending")
quality = data.get("quality_review", {}).get("status", "pending")
evaluation = data.get("evaluation", {})
print(f"Team: {data.get('team_name')}")
print(f"Spec review: {spec}")
print(f"Quality review: {quality}")
print(f"Evaluation: {evaluation.get('status', 'Blocked')}")
print(f"Reason codes: {', '.join(evaluation.get('reason_codes', [])) or 'none'}")
print(f"Updated at: {data.get('updated_at')}")
PY
      fi
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
