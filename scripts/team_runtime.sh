#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] && shift || true

TEAM=""
RUNTIME="auto"
TASK_DESC=""
WORKER_COUNT=""
MAX_FIX_LOOPS=""
TERMINAL_STATUS="Cancelled"
REASON_CODES=""
REASON_NOTE=""
JSON_OUTPUT=false
FORCE_RESUME=false

CONFIG_DEFAULT_RUNTIME="auto"
CONFIG_AUTO_PREFERENCE="file"
CONFIG_WORKERS=3
CONFIG_MAX_FIX_LOOPS=3

usage() {
  cat <<'USAGE'
Usage:
  team_runtime.sh <start|status|resume|shutdown> --team TEAM [options]

Commands:
  start      Start a team runtime session
  status     Show team runtime status
  resume     Advance/continue state machine
  shutdown   Stop runtime and enter terminal state

Options:
  --project-root PATH
  --team TEAM
  --runtime file|tmux|auto
  --task "Task description"
  --workers N
  --max-fix-loops N
  --terminal-status Pass|Blocked|Cancelled
  --reason-codes a,b,c
  --reason "human readable reason"
  --force
  --json
  -h, --help

Examples:
  team_runtime.sh start --team ptk-v340 --runtime file --task "v3.4.0 delivery"
  team_runtime.sh status --team ptk-v340
  team_runtime.sh resume --team ptk-v340
  team_runtime.sh shutdown --team ptk-v340 --terminal-status Pass
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

load_runtime_config() {
  python3 - "$PROJECT_ROOT/config/workflow.yaml" <<'PY'
import json
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
text = p.read_text(encoding="utf-8") if p.exists() else ""

def pick(key, default):
    m = re.search(rf"^\s*{re.escape(key)}:\s*([^\n#]+)", text, flags=re.M)
    if not m:
        return default
    value = m.group(1).strip().strip('"').strip("'")
    return value or default

payload = {
    "default_runtime": pick("default_runtime", "auto"),
    "auto_runtime_preference": pick("auto_runtime_preference", "file"),
    "worker_count": int(pick("worker_count", "3")),
    "max_fix_loops": int(pick("max_fix_loops", "3")),
}
print(json.dumps(payload))
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
      --runtime)
        require_value "$1" "${2:-}"
        RUNTIME="$2"
        shift 2
        ;;
      --task)
        require_value "$1" "${2:-}"
        TASK_DESC="$2"
        shift 2
        ;;
      --workers)
        require_value "$1" "${2:-}"
        WORKER_COUNT="$2"
        shift 2
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
      --reason-codes)
        require_value "$1" "${2:-}"
        REASON_CODES="$2"
        shift 2
        ;;
      --reason)
        require_value "$1" "${2:-}"
        REASON_NOTE="$2"
        shift 2
        ;;
      --json)
        JSON_OUTPUT=true
        shift
        ;;
      --force)
        FORCE_RESUME=true
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

manifest_field() {
  local key="$1"
  python3 - "$MANIFEST_FILE" "$key" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
key = sys.argv[2]
if not p.exists():
    print("")
    raise SystemExit(0)
data = json.loads(p.read_text(encoding="utf-8"))
print(data.get(key, ""))
PY
}

review_evaluation_status() {
  python3 - "$REVIEW_GATES_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("Blocked")
    raise SystemExit(0)
try:
    d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    print("Blocked")
    raise SystemExit(0)
ev = d.get("evaluation", {}) if isinstance(d.get("evaluation"), dict) else {}
print(ev.get("status", "Blocked"))
PY
}

write_worker_status() {
  local worker_id="$1"
  local status="$2"
  local pane_id="${3:-}"
  local worker_dir="$WORKERS_DIR/$worker_id"
  local status_file="$worker_dir/status.json"
  mkdir -p "$worker_dir"
  python3 - "$status_file" "$worker_id" "$status" "$pane_id" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
worker_id = sys.argv[2]
status = sys.argv[3]
pane_id = sys.argv[4]
now = sys.argv[5]

payload = {
    "worker_id": worker_id,
    "status": status,
    "updated_at": now,
}
if pane_id:
    payload["pane_id"] = pane_id

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

set_all_workers_status() {
  local status="$1"
  python3 - "$WORKERS_DIR" "$status" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

workers_dir = Path(sys.argv[1])
status = sys.argv[2]
now = sys.argv[3]
for status_file in sorted(workers_dir.glob("*/status.json")):
    try:
        data = json.loads(status_file.read_text(encoding="utf-8"))
    except Exception:
        data = {"worker_id": status_file.parent.name}
    data["status"] = status
    data["updated_at"] = now
    status_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

write_manifest_start() {
  python3 - "$MANIFEST_FILE" "$TEAM" "$RUNTIME_EFFECTIVE" "$TASK_DESC" "$MAX_FIX_LOOPS" "$TMUX_SESSION" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
team = sys.argv[2]
runtime = sys.argv[3]
task = sys.argv[4]
max_fix_loops = int(sys.argv[5])
tmux_session = sys.argv[6]
now = sys.argv[7]

workers = []
workers_dir = manifest_path.parent / "workers"
for status_file in sorted(workers_dir.glob("*/status.json")):
    try:
        workers.append(json.loads(status_file.read_text(encoding="utf-8")))
    except Exception:
        workers.append({
            "worker_id": status_file.parent.name,
            "status": "unknown",
            "updated_at": now,
        })

payload = {
    "schema_version": "1.0",
    "team_name": team,
    "runtime": runtime,
    "status": "active",
    "terminal_status": "Unknown",
    "current_phase": "team-plan",
    "phase_history": [
        {"phase": "team-plan", "timestamp": now, "note": "team start"}
    ],
    "task": task or "team task",
    "max_fix_loops": max_fix_loops,
    "fix_loop_count": 0,
    "workers": workers,
    "created_at": now,
    "updated_at": now,
}
if runtime == "tmux":
    payload["tmux"] = {"session_name": tmux_session, "window_name": "workers"}

manifest_path.parent.mkdir(parents=True, exist_ok=True)
manifest_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

update_manifest_transition() {
  local to_phase="$1"
  local note="$2"
  local terminal_status="${3:-}"
  local increment_fix="${4:-false}"
  local reason_codes="${5:-}"
  local reason_note="${6:-}"
  python3 - "$MANIFEST_FILE" "$to_phase" "$note" "$terminal_status" "$increment_fix" "$reason_codes" "$reason_note" "$(iso_now)" <<PY
import json
import sys
from pathlib import Path

$split_csv_py

manifest_path = Path(sys.argv[1])
to_phase = sys.argv[2]
note = sys.argv[3]
terminal_status = sys.argv[4]
increment_fix = sys.argv[5].lower() == "true"
reason_codes = split_csv(sys.argv[6])
reason_note = sys.argv[7]
now = sys.argv[8]

if not manifest_path.exists():
    raise SystemExit("manifest not found")

data = json.loads(manifest_path.read_text(encoding="utf-8"))
history = data.get("phase_history", []) if isinstance(data.get("phase_history"), list) else []

if increment_fix:
    data["fix_loop_count"] = int(data.get("fix_loop_count", 0)) + 1

if to_phase == "terminal":
    data["status"] = "terminal"
    data["current_phase"] = "terminal"
    data["terminal_status"] = terminal_status or data.get("terminal_status") or "Unknown"
    if reason_codes:
        data["terminal_reason_codes"] = reason_codes
    if reason_note:
        data["terminal_reason_note"] = reason_note
else:
    data["status"] = "active"
    data["current_phase"] = to_phase

history.append({"phase": data.get("current_phase"), "timestamp": now, "note": note})
data["phase_history"] = history

workers = []
workers_dir = manifest_path.parent / "workers"
for status_file in sorted(workers_dir.glob("*/status.json")):
    try:
        workers.append(json.loads(status_file.read_text(encoding="utf-8")))
    except Exception:
        workers.append({"worker_id": status_file.parent.name, "status": "unknown", "updated_at": now})
data["workers"] = workers
data["updated_at"] = now

manifest_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

append_mailbox_event() {
  local kind="$1"
  local status="$2"
  local message="$3"
  local reason_codes="${4:-}"
  local ts
  ts="$(iso_now)"
  local safe_ts
  safe_ts="$(echo "$ts" | tr -d ':-' | tr 'T' '_' | tr -d 'Z')"
  local event_file="$MAILBOX_DIR/${safe_ts}-${kind}.json"
  python3 - "$event_file" "$kind" "$status" "$message" "$reason_codes" "$ts" <<PY
import json
import sys
from pathlib import Path

$split_csv_py

path = Path(sys.argv[1])
kind = sys.argv[2]
status = sys.argv[3]
message = sys.argv[4]
reason_codes = split_csv(sys.argv[5])
ts = sys.argv[6]

payload = {
    "timestamp": ts,
    "kind": kind,
    "status": status,
    "message": message,
    "reason_codes": reason_codes,
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

write_handoff() {
  local from_phase="$1"
  local to_phase="$2"
  local note="$3"
  local script="$SCRIPT_DIR/team_handoff.py"
  [[ -f "$script" ]] || return 0
  python3 "$script" \
    --project-root "$PROJECT_ROOT" \
    --team "$TEAM" \
    --from-stage "$from_phase" \
    --to-stage "$to_phase" \
    --decided "$note" >/dev/null 2>&1 || true
}

initialize_file_workers() {
  local count="$1"
  local i
  for ((i=1; i<=count; i++)); do
    local worker_id
    worker_id="$(printf "worker-%02d" "$i")"
    write_worker_status "$worker_id" "idle"
  done
}

start_tmux_workers() {
  local count="$1"
  if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux not found but runtime=tmux requested" >&2
    exit 1
  fi

  if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    tmux kill-session -t "$TMUX_SESSION"
  fi

  tmux new-session -d -s "$TMUX_SESSION" -n workers
  local i
  for ((i=2; i<=count; i++)); do
    tmux split-window -t "$TMUX_SESSION:workers" -d
    tmux select-layout -t "$TMUX_SESSION:workers" tiled >/dev/null
  done

  local panes=()
  while IFS= read -r pane; do
    panes+=("$pane")
  done < <(tmux list-panes -t "$TMUX_SESSION:workers" -F "#{pane_id}")
  for ((i=1; i<=count; i++)); do
    local worker_id pane_id
    worker_id="$(printf "worker-%02d" "$i")"
    pane_id="${panes[$((i-1))]:-}"
    if [[ -n "$pane_id" ]]; then
      tmux send-keys -t "$pane_id" "printf '[ptk-team:%s] %s ready\n' '$TEAM' '$worker_id'; while true; do sleep 300; done" C-m
    fi
    write_worker_status "$worker_id" "running" "$pane_id"
  done
}

ensure_tmux_workers_on_resume() {
  local count="$1"
  if ! command -v tmux >/dev/null 2>&1; then
    echo "Error: tmux not found" >&2
    exit 1
  fi
  if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    start_tmux_workers "$count"
    return
  fi
  local panes=()
  while IFS= read -r pane; do
    panes+=("$pane")
  done < <(tmux list-panes -t "$TMUX_SESSION:workers" -F "#{pane_id}")
  local i
  for ((i=1; i<=count; i++)); do
    local worker_id pane_id
    worker_id="$(printf "worker-%02d" "$i")"
    pane_id="${panes[$((i-1))]:-}"
    write_worker_status "$worker_id" "running" "$pane_id"
  done
}

print_status() {
  if [[ "$JSON_OUTPUT" == true ]]; then
    cat "$MANIFEST_FILE"
    return
  fi
  python3 - "$MANIFEST_FILE" "$REVIEW_GATES_FILE" "$HANDOFF_DIR" <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
review_file = Path(sys.argv[2])
handoff_dir = Path(sys.argv[3])

evaluation = "n/a"
reason_codes = []
if review_file.exists():
    try:
        review = json.loads(review_file.read_text(encoding="utf-8"))
        ev = review.get("evaluation", {}) if isinstance(review.get("evaluation"), dict) else {}
        evaluation = ev.get("status", "Blocked")
        reason_codes = ev.get("reason_codes", []) if isinstance(ev.get("reason_codes"), list) else []
    except Exception:
        evaluation = "invalid"

latest_handoff = ""
handoffs = list(handoff_dir.glob(f"{manifest.get('team_name')}-*.md"))
if handoffs:
    latest_handoff = str(max(handoffs, key=lambda p: p.stat().st_mtime))

print(f"Team: {manifest.get('team_name')}")
print(f"Runtime: {manifest.get('runtime')}")
print(f"Status: {manifest.get('status')}")
print(f"Current phase: {manifest.get('current_phase')}")
print(f"Terminal status: {manifest.get('terminal_status', 'Unknown')}")
print(f"Fix loops: {manifest.get('fix_loop_count', 0)}/{manifest.get('max_fix_loops', 0)}")
print(f"Review evaluation: {evaluation}")
print(f"Review reason codes: {', '.join(reason_codes) if reason_codes else 'none'}")
print(f"Updated at: {manifest.get('updated_at')}")
if latest_handoff:
    print(f"Latest handoff: {latest_handoff}")

workers = manifest.get("workers", [])
if workers:
    print("Workers:")
    for w in workers:
        pane = f" ({w.get('pane_id')})" if w.get("pane_id") else ""
        print(f"  - {w.get('worker_id')}: {w.get('status')}{pane}")
PY
}

main() {
  if [[ -z "$COMMAND" || "$COMMAND" == "-h" || "$COMMAND" == "--help" ]]; then
    usage
    exit 0
  fi

  local cfg_json
  cfg_json="$(load_runtime_config)"
  CONFIG_DEFAULT_RUNTIME="$(python3 - <<PY
import json
print(json.loads('''$cfg_json''').get("default_runtime", "auto"))
PY
)"
  CONFIG_AUTO_PREFERENCE="$(python3 - <<PY
import json
print(json.loads('''$cfg_json''').get("auto_runtime_preference", "file"))
PY
)"
  CONFIG_WORKERS="$(python3 - <<PY
import json
print(int(json.loads('''$cfg_json''').get("worker_count", 3)))
PY
)"
  CONFIG_MAX_FIX_LOOPS="$(python3 - <<PY
import json
print(int(json.loads('''$cfg_json''').get("max_fix_loops", 3)))
PY
)"

  parse_args "$@"

  [[ -n "$TEAM" ]] || { echo "Error: --team is required"; exit 1; }

  if [[ -z "$WORKER_COUNT" ]]; then
    WORKER_COUNT="$CONFIG_WORKERS"
  fi
  if [[ -z "$MAX_FIX_LOOPS" ]]; then
    MAX_FIX_LOOPS="$CONFIG_MAX_FIX_LOOPS"
  fi
  if ! [[ "$WORKER_COUNT" =~ ^[0-9]+$ ]] || (( WORKER_COUNT < 1 )); then
    echo "Error: --workers must be a positive integer" >&2
    exit 1
  fi
  if ! [[ "$MAX_FIX_LOOPS" =~ ^[0-9]+$ ]] || (( MAX_FIX_LOOPS < 1 )); then
    echo "Error: --max-fix-loops must be a positive integer" >&2
    exit 1
  fi
  if [[ "$RUNTIME" == "auto" ]]; then
    RUNTIME="$CONFIG_DEFAULT_RUNTIME"
  fi

  local team_safe
  team_safe="$(sanitize_name "$TEAM")"
  TEAM_DIR="$PROJECT_ROOT/.ptk/state/team/$TEAM"
  TASKS_DIR="$TEAM_DIR/tasks"
  WORKERS_DIR="$TEAM_DIR/workers"
  MAILBOX_DIR="$TEAM_DIR/mailbox"
  REPORTS_DIR="$TEAM_DIR/reports"
  HANDOFF_DIR="$PROJECT_ROOT/.ptk/handoffs"
  MANIFEST_FILE="$TEAM_DIR/manifest.json"
  REVIEW_GATES_FILE="$TEAM_DIR/review-gates.json"
  TMUX_SESSION="ptk-${team_safe}"

  mkdir -p "$TASKS_DIR" "$WORKERS_DIR" "$MAILBOX_DIR" "$REPORTS_DIR" "$HANDOFF_DIR"

  case "$COMMAND" in
    start)
      if [[ -f "$MANIFEST_FILE" ]]; then
        echo "Error: team already initialized. Use status/resume/shutdown." >&2
        exit 1
      fi

      if [[ "$RUNTIME" == "auto" ]]; then
        if [[ "$CONFIG_AUTO_PREFERENCE" == "tmux" && "$(command -v tmux >/dev/null 2>&1; echo $?)" -eq 0 ]]; then
          RUNTIME_EFFECTIVE="tmux"
        else
          RUNTIME_EFFECTIVE="file"
        fi
      elif [[ "$RUNTIME" == "tmux" ]]; then
        RUNTIME_EFFECTIVE="tmux"
      else
        RUNTIME_EFFECTIVE="file"
      fi

      if [[ "$RUNTIME_EFFECTIVE" == "tmux" ]]; then
        start_tmux_workers "$WORKER_COUNT"
      else
        initialize_file_workers "$WORKER_COUNT"
      fi

      if [[ -z "$TASK_DESC" ]]; then
        TASK_DESC="team task"
      fi
      python3 - "$TASKS_DIR/task-001.json" "$TASK_DESC" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

task_file = Path(sys.argv[1])
task = sys.argv[2]
now = sys.argv[3]
payload = {
    "task_id": "task-001",
    "title": task,
    "status": "pending",
    "created_at": now,
    "updated_at": now,
}
task_file.parent.mkdir(parents=True, exist_ok=True)
task_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

      write_manifest_start
      if [[ -x "$SCRIPT_DIR/review_gate.sh" ]]; then
        "$SCRIPT_DIR/review_gate.sh" --project-root "$PROJECT_ROOT" --team "$TEAM" init >/dev/null || true
      fi
      append_mailbox_event "start" "active" "team runtime started" ""
      write_handoff "bootstrap" "team-plan" "runtime started"
      print_status
      ;;
    status)
      [[ -f "$MANIFEST_FILE" ]] || { echo "Error: manifest not found: $MANIFEST_FILE" >&2; exit 1; }
      print_status
      ;;
    resume)
      [[ -f "$MANIFEST_FILE" ]] || { echo "Error: manifest not found: $MANIFEST_FILE" >&2; exit 1; }
      local current_phase runtime_now next_phase note from_phase
      current_phase="$(manifest_field current_phase)"
      runtime_now="$(manifest_field runtime)"
      from_phase="$current_phase"

      if [[ "$current_phase" == "terminal" && "$FORCE_RESUME" != true ]]; then
        echo "Error: team is already terminal; use --force to resume anyway." >&2
        exit 1
      fi
      if [[ "$current_phase" == "terminal" && "$FORCE_RESUME" == true ]]; then
        current_phase="team-fix"
        update_manifest_transition "team-fix" "force resume from terminal" "" "false" "" ""
        from_phase="terminal"
      fi

      if [[ "$runtime_now" == "tmux" ]]; then
        ensure_tmux_workers_on_resume "$WORKER_COUNT"
      else
        set_all_workers_status "running"
      fi

      case "$current_phase" in
        team-plan)
          next_phase="team-prd"
          note="plan completed, move to prd"
          update_manifest_transition "$next_phase" "$note" "" "false" "" ""
          ;;
        team-prd)
          next_phase="team-exec"
          note="prd completed, move to execution"
          update_manifest_transition "$next_phase" "$note" "" "false" "" ""
          ;;
        team-exec)
          next_phase="team-verify"
          note="execution completed, move to verification"
          update_manifest_transition "$next_phase" "$note" "" "false" "" ""
          ;;
        team-verify)
          local review_status
          review_status="$(review_evaluation_status)"
          if [[ "$review_status" == "Pass" ]]; then
            next_phase="terminal"
            note="spec->quality gate pass"
            set_all_workers_status "done"
            update_manifest_transition "terminal" "$note" "Pass" "false" "" ""
          else
            next_phase="team-fix"
            note="review gate not pass, move to fix"
            update_manifest_transition "$next_phase" "$note" "" "false" "review_gate_blocked" ""
          fi
          ;;
        team-fix)
          local current_fix max_fix next_fix
          current_fix="$(manifest_field fix_loop_count)"
          max_fix="$(manifest_field max_fix_loops)"
          current_fix="${current_fix:-0}"
          max_fix="${max_fix:-$MAX_FIX_LOOPS}"
          next_fix=$((current_fix + 1))
          if (( next_fix >= max_fix )); then
            next_phase="terminal"
            note="max fix loops reached"
            set_all_workers_status "failed"
            update_manifest_transition "terminal" "$note" "Blocked" "true" "max_fix_loops_exceeded" "fix loops ${next_fix}/${max_fix}"
          else
            next_phase="team-verify"
            note="fix loop completed, re-enter verify"
            update_manifest_transition "$next_phase" "$note" "" "true" "" ""
          fi
          ;;
        *)
          echo "Error: unsupported current phase: $current_phase" >&2
          exit 1
          ;;
      esac

      append_mailbox_event "resume" "active" "$note" ""
      write_handoff "$from_phase" "${next_phase:-$current_phase}" "$note"
      print_status
      ;;
    shutdown)
      [[ -f "$MANIFEST_FILE" ]] || { echo "Error: manifest not found: $MANIFEST_FILE" >&2; exit 1; }
      local runtime_now current_phase note reason_codes_use
      case "$TERMINAL_STATUS" in
        Pass|Blocked|Cancelled) ;;
        *)
          echo "Error: --terminal-status must be Pass|Blocked|Cancelled" >&2
          exit 1
          ;;
      esac
      runtime_now="$(manifest_field runtime)"
      current_phase="$(manifest_field current_phase)"
      reason_codes_use="${REASON_CODES:-manual_shutdown}"
      note="${REASON_NOTE:-runtime shutdown}"

      if [[ "$runtime_now" == "tmux" ]] && command -v tmux >/dev/null 2>&1; then
        if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
          tmux kill-session -t "$TMUX_SESSION"
        fi
      fi

      set_all_workers_status "stopped"
      update_manifest_transition "terminal" "$note" "$TERMINAL_STATUS" "false" "$reason_codes_use" "$note"
      append_mailbox_event "shutdown" "terminal" "$note" "$reason_codes_use"
      write_handoff "${current_phase:-unknown}" "terminal" "$note"
      print_status
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
