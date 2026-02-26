#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] && shift || true

TEAM=""
RUNTIME="auto"            # omx|omc|auto
TEAM_RUNTIME="auto"       # file|tmux|auto
TASK_DESC=""
VERSION=""
FEATURE=""
TEST_FILE=""
MANUAL_RESULTS=""
TEST_TYPE="full"
ITERATIONS=""
FRONTEND_CMD=""
FRONTEND_DIR=""
FRONTEND_URL=""
FRONTEND_TIMEOUT=""
NO_FRONTEND_START=false
NO_VERIFY=false
MAX_FIX_LOOPS=""
TERMINAL_STATUS=""
TERMINAL_REASON=""
JSON_OUTPUT=false

SPEC_REVIEWER="pm"
QUALITY_REVIEWER="qa"

RUNTIME_EFFECTIVE=""

STATE_DIR=""
LINK_DIR=""
LINK_FILE=""
GLOBAL_LINK_FILE=""
TEAM_SAFE=""
TEAM_DIR=""
MANIFEST_FILE=""
REVIEW_FILE=""
REPORTS_DIR=""
BRIDGE_EVENT_REASON_CODES=""

usage() {
  cat <<'USAGE'
Usage:
  ralph_bridge.sh <start|resume|status|finalize> --team TEAM [options]

Bridge commands:
  start      Initialize bridge state and start PTK team runtime
  resume     Advance team state machine; when reaching verify stage, run auto-test + review gate + report
  status     Show bridge status
  finalize   Finalize terminal state (or graceful shutdown with explicit terminal status)

Options:
  --project-root PATH
  --team TEAM
  --runtime omx|omc|auto
  --team-runtime file|tmux|auto
  --task "Task description"
  --version VERSION
  --feature FEATURE
  --test-file PATH
  --manual-results PATH
  --test-type smoke|regression|full
  --iterations N
  --frontend-cmd CMD
  --frontend-dir DIR
  --frontend-url URL
  --frontend-timeout SEC
  --no-frontend-start
  --no-verify
  --max-fix-loops N
  --terminal-status Pass|Blocked|Cancelled
  --terminal-reason "human note"
  --json
  -h, --help

Examples:
  ralph_bridge.sh start --team rb-v350 --runtime auto --task "v3.5.0 ralph bridge"
  ralph_bridge.sh resume --team rb-v350 --version v3.5.0 --feature ralph-bridge --test-file docs/product/v3.5.0/qa/test-cases/ralph-bridge.md --manual-results docs/product/v3.5.0/qa/manual-results/v3.5.0-ralph-bridge-pass.json
  ralph_bridge.sh status --team rb-v350
  ralph_bridge.sh finalize --team rb-v350 --terminal-status Pass
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

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

sanitize_name() {
  echo "$1" | sed -E 's/[^A-Za-z0-9._-]+/_/g'
}

runtime_state_dir() {
  local runtime="$1"
  echo "$PROJECT_ROOT/.${runtime}/state"
}

default_runtime_preference() {
  local env_pref="${PTK_BRIDGE_RUNTIME_PREFERENCE:-}"
  if [[ "$env_pref" == "omx" || "$env_pref" == "omc" ]]; then
    echo "$env_pref"
  else
    echo "omx"
  fi
}

resolve_runtime() {
  local requested="$1"
  local pref other candidate

  if [[ "$requested" == "omx" || "$requested" == "omc" ]]; then
    candidate="$requested"
    if [[ -d "$(runtime_state_dir "$candidate")" ]]; then
      RUNTIME_EFFECTIVE="$candidate"
      return 0
    fi
    echo "Error: runtime '$candidate' is not supported in this project (missing $(runtime_state_dir "$candidate"))" >&2
    BRIDGE_EVENT_REASON_CODES="unsupported_runtime"
    return 1
  fi

  if [[ "$requested" != "auto" ]]; then
    echo "Error: --runtime must be omx|omc|auto" >&2
    BRIDGE_EVENT_REASON_CODES="invalid_runtime"
    return 1
  fi

  pref="$(default_runtime_preference)"
  if [[ "$pref" == "omx" ]]; then
    other="omc"
  else
    other="omx"
  fi

  for candidate in "$pref" "$other"; do
    if [[ -d "$(runtime_state_dir "$candidate")" ]]; then
      RUNTIME_EFFECTIVE="$candidate"
      return 0
    fi
  done

  echo "Error: runtime auto resolution failed (neither .omx/state nor .omc/state found)" >&2
  BRIDGE_EVENT_REASON_CODES="unsupported_runtime_auto"
  return 1
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
      --runtime)
        require_value "$1" "${2:-}"
        RUNTIME="$2"
        shift 2
        ;;
      --team-runtime)
        require_value "$1" "${2:-}"
        TEAM_RUNTIME="$2"
        shift 2
        ;;
      --task)
        require_value "$1" "${2:-}"
        TASK_DESC="$2"
        shift 2
        ;;
      --version)
        require_value "$1" "${2:-}"
        VERSION="$2"
        shift 2
        ;;
      --feature)
        require_value "$1" "${2:-}"
        FEATURE="$2"
        shift 2
        ;;
      --test-file)
        require_value "$1" "${2:-}"
        TEST_FILE="$2"
        shift 2
        ;;
      --manual-results)
        require_value "$1" "${2:-}"
        MANUAL_RESULTS="$2"
        shift 2
        ;;
      --test-type)
        require_value "$1" "${2:-}"
        TEST_TYPE="$2"
        shift 2
        ;;
      --iterations)
        require_value "$1" "${2:-}"
        ITERATIONS="$2"
        shift 2
        ;;
      --frontend-cmd)
        require_value "$1" "${2:-}"
        FRONTEND_CMD="$2"
        shift 2
        ;;
      --frontend-dir)
        require_value "$1" "${2:-}"
        FRONTEND_DIR="$2"
        shift 2
        ;;
      --frontend-url)
        require_value "$1" "${2:-}"
        FRONTEND_URL="$2"
        shift 2
        ;;
      --frontend-timeout)
        require_value "$1" "${2:-}"
        FRONTEND_TIMEOUT="$2"
        shift 2
        ;;
      --no-frontend-start)
        NO_FRONTEND_START=true
        shift
        ;;
      --no-verify)
        NO_VERIFY=true
        shift
        ;;
      --max-fix-loops)
        require_value "$1" "${2:-}"
        MAX_FIX_LOOPS="$2"
        shift 2
        ;;
      --terminal-status)
        require_value "$1" "${2:-}"
        TERMINAL_STATUS="$2"
        shift 2
        ;;
      --terminal-reason)
        require_value "$1" "${2:-}"
        TERMINAL_REASON="$2"
        shift 2
        ;;
      --json)
        JSON_OUTPUT=true
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

init_paths() {
  [[ -n "$TEAM" ]] || { echo "Error: --team is required" >&2; exit 1; }
  TEAM_SAFE="$(sanitize_name "$TEAM")"
  STATE_DIR="$PROJECT_ROOT/.ptk/state/bridge"
  LINK_DIR="$STATE_DIR/$TEAM_SAFE"
  LINK_FILE="$LINK_DIR/ralph-link.json"
  GLOBAL_LINK_FILE="$STATE_DIR/ralph-link.json"
  TEAM_DIR="$PROJECT_ROOT/.ptk/state/team/$TEAM"
  MANIFEST_FILE="$TEAM_DIR/manifest.json"
  REVIEW_FILE="$TEAM_DIR/review-gates.json"
  REPORTS_DIR="$TEAM_DIR/reports"
  mkdir -p "$STATE_DIR" "$LINK_DIR"
}

migrate_legacy_link_if_needed() {
  [[ -f "$LINK_FILE" ]] && return 0
  [[ -f "$GLOBAL_LINK_FILE" ]] || return 0

  python3 - "$GLOBAL_LINK_FILE" "$LINK_FILE" "$TEAM" <<'PY'
import json
import sys
from pathlib import Path

legacy = Path(sys.argv[1])
current = Path(sys.argv[2])
team = sys.argv[3]

try:
    data = json.loads(legacy.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

team_node = data.get("team", {}) if isinstance(data.get("team"), dict) else {}
if str(team_node.get("team_name", "")) != team:
    raise SystemExit(0)

current.parent.mkdir(parents=True, exist_ok=True)
current.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

detect_ralph_state() {
  local runtime="$1"
  local out_file="$2"
  python3 - "$runtime" "$PROJECT_ROOT" "$out_file" <<'PY'
import json
import sys
from pathlib import Path

runtime = sys.argv[1]
project_root = Path(sys.argv[2])
out_file = Path(sys.argv[3])
state_dir = project_root / f".{runtime}" / "state"

payload = {
    "runtime": runtime,
    "state_dir": str(state_dir),
    "session_id": "",
    "state_file": "",
    "found": False,
    "active": False,
    "phase": "",
    "iteration": None,
    "max_iterations": None,
    "completed_at": "",
}

if not state_dir.exists():
    out_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    raise SystemExit(0)

session_file = state_dir / "session.json"
session_id = ""
if session_file.exists():
    try:
        s = json.loads(session_file.read_text(encoding="utf-8"))
    except Exception:
        s = {}
    for key in ("session_id", "sessionId", "id"):
        if isinstance(s.get(key), str) and s.get(key).strip():
            session_id = s.get(key).strip()
            break
payload["session_id"] = session_id

state_candidates = []
if session_id:
    state_candidates.append(state_dir / "sessions" / session_id / "ralph-state.json")
state_candidates.append(state_dir / "ralph-state.json")

for candidate in state_candidates:
    if not candidate.exists():
        continue
    try:
        d = json.loads(candidate.read_text(encoding="utf-8"))
    except Exception:
        continue
    payload["found"] = True
    payload["state_file"] = str(candidate)
    payload["active"] = bool(d.get("active", False))
    payload["phase"] = str(d.get("current_phase", "") or "")
    payload["iteration"] = d.get("iteration")
    payload["max_iterations"] = d.get("max_iterations")
    payload["completed_at"] = str(d.get("completed_at", "") or "")
    break

out_file.parent.mkdir(parents=True, exist_ok=True)
out_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

team_phase_from_manifest() {
  python3 - "$MANIFEST_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("")
    raise SystemExit(0)
try:
    d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    print("")
    raise SystemExit(0)
print(str(d.get("current_phase", "")))
PY
}

team_terminal_status_from_manifest() {
  python3 - "$MANIFEST_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("")
    raise SystemExit(0)
try:
    d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    print("")
    raise SystemExit(0)
print(str(d.get("terminal_status", "")))
PY
}

run_team_runtime() {
  local subcommand="$1"
  shift
  "$SCRIPT_DIR/team_runtime.sh" "$subcommand" --project-root "$PROJECT_ROOT" --team "$TEAM" "$@"
}

run_review_gate() {
  "$SCRIPT_DIR/review_gate.sh" --project-root "$PROJECT_ROOT" --team "$TEAM" "$@"
}

find_latest_session_file() {
  local out_file="$1"
  python3 - "$PROJECT_ROOT" "$VERSION" "$FEATURE" "$out_file" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
version = sys.argv[2]
feature = sys.argv[3]
out_path = Path(sys.argv[4])
session_dir = root / ".ptk" / "state" / "test-sessions"

latest = ""
if session_dir.exists():
    files = sorted(session_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    for p in files:
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
        meta = d.get("meta", {}) if isinstance(d.get("meta"), dict) else {}
        if str(meta.get("version", "")) == version and str(meta.get("feature", "")) == feature:
            latest = str(p)
            break
out_path.write_text(latest, encoding="utf-8")
PY
}

run_verify_suite() {
  local verify_file="$1"
  local auto_log
  auto_log="$(mktemp)"
  local latest_session_file_txt
  latest_session_file_txt="$(mktemp)"
  local eval_json_file
  eval_json_file="$(mktemp)"
  local report_json_file
  report_json_file="$(mktemp)"
  local auto_rc auto_status quality_status critical_open
  local reason_codes_csv
  local report_json_path report_md_path
  local verify_failed=0

  if [[ -z "$VERSION" || -z "$FEATURE" ]]; then
    echo "Error: verify stage requires --version and --feature" >&2
    BRIDGE_EVENT_REASON_CODES="missing_verify_inputs"
    return 1
  fi
  if [[ -n "$MANUAL_RESULTS" && ! -f "$MANUAL_RESULTS" ]]; then
    echo "Error: manual results file not found: $MANUAL_RESULTS" >&2
    BRIDGE_EVENT_REASON_CODES="manual_results_not_found"
    return 1
  fi

  local cmd=("$SCRIPT_DIR/auto_test.sh" -v "$VERSION" -f "$FEATURE" -t "$TEST_TYPE")
  [[ -n "$TEST_FILE" ]] && cmd+=(--test-file "$TEST_FILE")
  [[ -n "$MANUAL_RESULTS" ]] && cmd+=(--manual-results "$MANUAL_RESULTS")
  [[ -n "$ITERATIONS" ]] && cmd+=(--iterations "$ITERATIONS")
  [[ -n "$FRONTEND_CMD" ]] && cmd+=(--frontend-cmd "$FRONTEND_CMD")
  [[ -n "$FRONTEND_DIR" ]] && cmd+=(--frontend-dir "$FRONTEND_DIR")
  [[ -n "$FRONTEND_URL" ]] && cmd+=(--frontend-url "$FRONTEND_URL")
  [[ -n "$FRONTEND_TIMEOUT" ]] && cmd+=(--frontend-timeout "$FRONTEND_TIMEOUT")
  [[ "$NO_FRONTEND_START" == true ]] && cmd+=(--no-frontend-start)

  echo "[ralph-bridge] verify: running auto-test"
  set +e
  "${cmd[@]}" >"$auto_log" 2>&1
  auto_rc=$?
  set -e

  find_latest_session_file "$latest_session_file_txt"
  local latest_session_file
  latest_session_file="$(cat "$latest_session_file_txt" 2>/dev/null || true)"

  auto_status="$(python3 - "$auto_rc" "$latest_session_file" <<'PY'
import json
import sys
from pathlib import Path

rc = int(sys.argv[1])
session_file = Path(sys.argv[2]) if sys.argv[2] else None
status = "passed" if rc == 0 else "failed"
if session_file and session_file.exists():
    try:
        d = json.loads(session_file.read_text(encoding="utf-8"))
        life = d.get("lifecycle", {}) if isinstance(d.get("lifecycle"), dict) else {}
        s = str(life.get("status", "")).strip().lower()
        if s in {"passed", "failed", "blocked"}:
            status = s
    except Exception:
        pass
print(status)
PY
)"

  reason_codes_csv="$(python3 - "$latest_session_file" "$auto_status" <<'PY'
import json
import sys
from pathlib import Path

session_file = Path(sys.argv[1]) if sys.argv[1] else None
auto_status = sys.argv[2]
codes = []
if session_file and session_file.exists():
    try:
        d = json.loads(session_file.read_text(encoding="utf-8"))
        gaps = d.get("gaps", {}) if isinstance(d.get("gaps"), dict) else {}
        for c in gaps.get("blocked_reason_codes", []) if isinstance(gaps.get("blocked_reason_codes"), list) else []:
            c = str(c).strip()
            if c and c not in codes:
                codes.append(c)
    except Exception:
        pass
if not codes and auto_status != "passed":
    codes = [f"auto_test_{auto_status}"]
print(",".join(codes))
PY
)"

  if [[ ! -f "$REVIEW_FILE" ]]; then
    run_review_gate init >/dev/null
  fi
  run_review_gate spec --status pass --reviewer "$SPEC_REVIEWER" >/dev/null

  if [[ "$auto_status" == "passed" ]]; then
    quality_status="pass"
    critical_open=0
    run_review_gate quality --status pass --reviewer "$QUALITY_REVIEWER" >/dev/null
  else
    quality_status="blocked"
    critical_open=1
    run_review_gate quality --status blocked --reviewer "$QUALITY_REVIEWER" --reason-codes "${reason_codes_csv:-auto_test_${auto_status}}" >/dev/null || true
    verify_failed=1
  fi

  run_review_gate evaluate --critical-open "$critical_open" --high-open 0 >"$eval_json_file"
  "$SCRIPT_DIR/team_report.sh" --project-root "$PROJECT_ROOT" --team "$TEAM" --format both >"$report_json_file"

  report_json_path="$(python3 - "$report_json_file" <<'PY'
import json,sys
from pathlib import Path
p = Path(sys.argv[1])
try:
  d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
  d = {}
print(str(d.get("json_report","")))
PY
)"
  report_md_path="$(python3 - "$report_json_file" <<'PY'
import json,sys
from pathlib import Path
p = Path(sys.argv[1])
try:
  d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
  d = {}
print(str(d.get("md_report","")))
PY
)"

  python3 - "$verify_file" "$auto_rc" "$auto_status" "$latest_session_file" "$reason_codes_csv" "$quality_status" "$eval_json_file" "$report_json_path" "$report_md_path" "$auto_log" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

(
    verify_file, auto_rc, auto_status, session_file, reason_codes_csv, quality_status,
    eval_json_file, report_json_path, report_md_path, auto_log, now
) = sys.argv[1:]

eval_data = {}
try:
    eval_data = json.loads(Path(eval_json_file).read_text(encoding="utf-8"))
except Exception:
    eval_data = {"status": "Blocked", "reason_codes": ["evaluation_read_failed"]}

reason_codes = [x.strip() for x in reason_codes_csv.split(",") if x.strip()]
payload = {
    "verified_at": now,
    "auto_test": {
        "status": auto_status,
        "exit_code": int(auto_rc),
        "session_file": session_file,
        "blocked_reason_codes": reason_codes,
        "log_file": auto_log,
    },
    "review_gate": {
        "spec_status": "pass",
        "quality_status": quality_status,
        "evaluation_status": str(eval_data.get("status", "Blocked")),
        "reason_codes": eval_data.get("reason_codes", []),
        "critical_open": eval_data.get("critical_open", 0),
        "high_open": eval_data.get("high_open", 0),
    },
    "team_report": {
        "json_report": report_json_path,
        "md_report": report_md_path,
    },
}
payload["overall_status"] = "Pass" if payload["review_gate"]["evaluation_status"] == "Pass" else "Blocked"
Path(verify_file).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

  if [[ "$verify_failed" -eq 1 ]]; then
    BRIDGE_EVENT_REASON_CODES="${reason_codes_csv:-auto_test_not_passed}"
  else
    BRIDGE_EVENT_REASON_CODES=""
  fi
}

persist_bridge_state() {
  local event="$1"
  local note="$2"
  local status_override="${3:-}"
  local terminal_override="${4:-}"
  local verify_file="${5:-}"
  local ralph_json_file="${6:-}"

  python3 - "$LINK_FILE" "$GLOBAL_LINK_FILE" "$event" "$note" "$status_override" "$terminal_override" "$BRIDGE_EVENT_REASON_CODES" "$RUNTIME" "$RUNTIME_EFFECTIVE" "$TEAM" "$MANIFEST_FILE" "$REVIEW_FILE" "$verify_file" "$ralph_json_file" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

(
    link_file, global_link_file, event, note, status_override, terminal_override, reason_codes_csv, runtime_requested,
    runtime_effective, team_name, manifest_file, review_file, verify_file, ralph_file, now
) = sys.argv[1:]

link_path = Path(link_file)
global_link_path = Path(global_link_file) if global_link_file else None
manifest_path = Path(manifest_file)
review_path = Path(review_file)
verify_path = Path(verify_file) if verify_file else None
ralph_path = Path(ralph_file) if ralph_file else None

def read_json(path: Path):
    if not path or not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}

if event == "start":
    payload = {}
else:
    payload = read_json(link_path)
    if not isinstance(payload, dict):
        payload = {}

manifest = read_json(manifest_path)
review = read_json(review_path)
verify = read_json(verify_path) if verify_path else {}
ralph = read_json(ralph_path) if ralph_path else {}

phase = str(manifest.get("current_phase", "unknown"))
terminal = str(manifest.get("terminal_status", "Unknown"))
team_status = str(manifest.get("status", "unknown"))

def map_phase(team_phase: str, terminal_status: str, detected_ralph_phase: str) -> str:
    if detected_ralph_phase:
        return detected_ralph_phase
    if team_phase in {"team-plan", "team-prd", "team-exec"}:
        return "executing"
    if team_phase == "team-verify":
        return "verifying"
    if team_phase == "team-fix":
        return "fixing"
    if team_phase == "terminal":
        m = {
            "Pass": "complete",
            "Blocked": "failed",
            "Cancelled": "cancelled",
        }
        return m.get(terminal_status, "cancelled")
    return "executing"

reason_codes = [x.strip() for x in reason_codes_csv.split(",") if x.strip()]
detected_ralph_phase = str(ralph.get("phase", "") or "")
mapped_phase = map_phase(phase, terminal, detected_ralph_phase)

bridge_id = str(payload.get("bridge_session_id", "")).strip()
if event == "start" or not bridge_id:
    bridge_id = f"rb-{now.replace(':','').replace('-','').replace('T','-').replace('Z','')}"

bridge_status = "terminal" if phase == "terminal" else "active"
if status_override:
    bridge_status = status_override
if terminal_override:
    terminal = terminal_override

payload.update({
    "schema_version": "1.0",
    "bridge_session_id": bridge_id,
    "runtime_requested": runtime_requested,
    "runtime_effective": runtime_effective,
    "status": bridge_status,
    "terminal_status": terminal,
    "team": {
        "team_name": team_name,
        "status": team_status,
        "current_phase": phase,
        "terminal_status": str(manifest.get("terminal_status", "Unknown")),
        "fix_loop_count": manifest.get("fix_loop_count", 0),
        "max_fix_loops": manifest.get("max_fix_loops", 0),
        "manifest_file": str(manifest_path),
        "review_file": str(review_path),
    },
    "ralph": {
        "runtime": str(ralph.get("runtime", runtime_effective)),
        "session_id": str(ralph.get("session_id", "")),
        "state_file": str(ralph.get("state_file", "")),
        "found": bool(ralph.get("found", False)),
        "active": bool(ralph.get("active", False)),
        "phase": detected_ralph_phase,
        "iteration": ralph.get("iteration"),
        "max_iterations": ralph.get("max_iterations"),
        "completed_at": str(ralph.get("completed_at", "")),
    },
    "mapping": {
        "team_phase": phase,
        "mapped_ralph_phase": mapped_phase,
    },
    "review_gate": {
        "evaluation_status": ((review.get("evaluation") or {}).get("status") if isinstance(review.get("evaluation"), dict) else "Blocked"),
        "reason_codes": ((review.get("evaluation") or {}).get("reason_codes") if isinstance(review.get("evaluation"), dict) else []),
    },
    "updated_at": now,
})

if event == "start" or not payload.get("created_at"):
    payload["created_at"] = now

if verify:
    payload["verification"] = verify

if reason_codes:
    payload["last_reason_codes"] = reason_codes

history = [] if event == "start" else payload.get("history", [])
if not isinstance(history, list):
    history = []
history.append({
    "timestamp": now,
    "event": event,
    "note": note,
    "team_phase": phase,
    "mapped_ralph_phase": mapped_phase,
    "reason_codes": reason_codes,
})
payload["history"] = history[-200:]

link_path.parent.mkdir(parents=True, exist_ok=True)
link_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

if global_link_path:
    global_link_path.parent.mkdir(parents=True, exist_ok=True)
    global_link_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

show_bridge_status() {
  if [[ "$JSON_OUTPUT" == true ]]; then
    if [[ -f "$LINK_FILE" ]]; then
      cat "$LINK_FILE"
      return 0
    fi
    echo "{}"
    return 0
  fi
  python3 - "$LINK_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("Bridge state not found.")
    raise SystemExit(0)

d = json.loads(p.read_text(encoding="utf-8"))
team = d.get("team", {}) if isinstance(d.get("team"), dict) else {}
ralph = d.get("ralph", {}) if isinstance(d.get("ralph"), dict) else {}
mapping = d.get("mapping", {}) if isinstance(d.get("mapping"), dict) else {}
review_gate = d.get("review_gate", {}) if isinstance(d.get("review_gate"), dict) else {}
verification = d.get("verification", {}) if isinstance(d.get("verification"), dict) else {}

print(f"Bridge Session: {d.get('bridge_session_id')}")
print(f"Runtime: {d.get('runtime_effective')} (requested={d.get('runtime_requested')})")
print(f"Status: {d.get('status')} / Terminal: {d.get('terminal_status')}")
print(f"Team: {team.get('team_name')} phase={team.get('current_phase')} fix={team.get('fix_loop_count')}/{team.get('max_fix_loops')}")
print(f"Mapped Ralph Phase: {mapping.get('mapped_ralph_phase')}")
print(f"Detected Ralph: phase={ralph.get('phase') or 'n/a'} active={ralph.get('active')} session={ralph.get('session_id') or 'n/a'}")
print(f"Review Gate: {review_gate.get('evaluation_status')} ({', '.join(review_gate.get('reason_codes', []) or []) or 'none'})")
if verification:
    auto = verification.get("auto_test", {}) if isinstance(verification.get("auto_test"), dict) else {}
    print(f"Last Verify: {verification.get('overall_status')} auto_test={auto.get('status')} session={auto.get('session_file') or 'n/a'}")
print(f"Updated At: {d.get('updated_at')}")
PY
}

command_start() {
  local note="bridge start"
  local ralph_tmp
  ralph_tmp="$(mktemp)"

  if [[ ! -f "$MANIFEST_FILE" ]]; then
    local args=(--runtime "$TEAM_RUNTIME")
    [[ -n "$TASK_DESC" ]] && args+=(--task "$TASK_DESC")
    [[ -n "$MAX_FIX_LOOPS" ]] && args+=(--max-fix-loops "$MAX_FIX_LOOPS")
    run_team_runtime start "${args[@]}" >/dev/null
  else
    note="bridge start (reuse existing team manifest)"
  fi

  run_team_runtime status --json > /dev/null
  detect_ralph_state "$RUNTIME_EFFECTIVE" "$ralph_tmp"
  BRIDGE_EVENT_REASON_CODES=""
  persist_bridge_state "start" "$note" "" "" "" "$ralph_tmp"
  show_bridge_status
}

command_resume() {
  local phase_before phase_after note
  local ralph_tmp verify_tmp
  ralph_tmp="$(mktemp)"
  verify_tmp="$(mktemp)"
  : >"$verify_tmp"

  [[ -f "$MANIFEST_FILE" ]] || { echo "Error: team manifest not found. Run start first." >&2; BRIDGE_EVENT_REASON_CODES="team_not_initialized"; return 1; }

  phase_before="$(team_phase_from_manifest)"
  if [[ "$phase_before" == "team-verify" && "$NO_VERIFY" != true ]]; then
    run_verify_suite "$verify_tmp"
  fi

  run_team_runtime resume >/dev/null
  phase_after="$(team_phase_from_manifest)"

  if [[ "$phase_after" == "team-verify" && "$NO_VERIFY" != true ]]; then
    run_verify_suite "$verify_tmp"
    run_team_runtime resume >/dev/null
    phase_after="$(team_phase_from_manifest)"
  fi

  detect_ralph_state "$RUNTIME_EFFECTIVE" "$ralph_tmp"
  note="resume ${phase_before:-unknown} -> ${phase_after:-unknown}"
  persist_bridge_state "resume" "$note" "" "" "$verify_tmp" "$ralph_tmp"
  show_bridge_status
}

command_status() {
  local ralph_tmp
  ralph_tmp="$(mktemp)"
  detect_ralph_state "$RUNTIME_EFFECTIVE" "$ralph_tmp"
  persist_bridge_state "status" "bridge status refresh" "" "" "" "$ralph_tmp"
  show_bridge_status
}

command_finalize() {
  local phase terminal_now note
  local ralph_tmp
  ralph_tmp="$(mktemp)"
  [[ -f "$MANIFEST_FILE" ]] || { echo "Error: team manifest not found. Run start first." >&2; BRIDGE_EVENT_REASON_CODES="team_not_initialized"; return 1; }

  phase="$(team_phase_from_manifest)"
  terminal_now="$(team_terminal_status_from_manifest)"

  if [[ "$phase" != "terminal" ]]; then
    [[ -n "$TERMINAL_STATUS" ]] || { echo "Error: finalize on non-terminal team requires --terminal-status Pass|Blocked|Cancelled" >&2; BRIDGE_EVENT_REASON_CODES="finalize_requires_terminal_status"; return 1; }
    local shutdown_args=(--terminal-status "$TERMINAL_STATUS")
    [[ -n "$TERMINAL_REASON" ]] && shutdown_args+=(--reason "$TERMINAL_REASON")
    run_team_runtime shutdown "${shutdown_args[@]}" >/dev/null
    phase="$(team_phase_from_manifest)"
    terminal_now="$(team_terminal_status_from_manifest)"
  fi

  detect_ralph_state "$RUNTIME_EFFECTIVE" "$ralph_tmp"
  note="finalize -> ${terminal_now:-Unknown}"
  persist_bridge_state "finalize" "$note" "terminal" "${terminal_now:-Unknown}" "" "$ralph_tmp"
  show_bridge_status
}

main() {
  if [[ -z "$COMMAND" || "$COMMAND" == "-h" || "$COMMAND" == "--help" ]]; then
    usage
    exit 0
  fi

  parse_args "$@"
  init_paths
  migrate_legacy_link_if_needed

  if ! resolve_runtime "$RUNTIME"; then
    exit 1
  fi

  case "$COMMAND" in
    start)
      command_start
      ;;
    resume)
      command_resume
      ;;
    status)
      command_status
      ;;
    finalize)
      command_finalize
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
