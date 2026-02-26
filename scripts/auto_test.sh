#!/usr/bin/env bash

# Product Toolkit Automated Test Runner
# - Supports optional frontend startup before browser automation
# - Selects external browser tools by priority: agent-browser -> browser-use
# - Persists test learnings to avoid repeating the same pitfalls

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PTK_DIR="$PROJECT_ROOT/.ptk"
STATE_DIR="$PTK_DIR/state"
MEMORY_DIR="$PTK_DIR/memory"
EVIDENCE_DIR="$PTK_DIR/evidence"

MAX_ITERATIONS=3
TEST_TYPE="full"
TEST_FILE=""
DRY_RUN=false

VERSION=""
FEATURE=""

TOOL_MODE="auto"
TOOL_PRIORITY="agent-browser,browser-use"
SELECTED_TOOL=""

START_FRONTEND=true
FRONTEND_CMD=""
FRONTEND_DIR="$PROJECT_ROOT"
FRONTEND_URL=""
FRONTEND_TIMEOUT=120
FRONTEND_PID=""
BROWSER_HEADED=false
FRONTEND_AUTO_DETECT=true

MANUAL_RESULTS_FILE=""
MANUAL_RESULTS_RESOLVED=""
MANUAL_RESULTS_TEMPLATE_FILE=""

API_BASE_URL=""
API_TIMEOUT=15
API_VARS=""
API_HEADERS=""
API_DEFAULT_METHOD="GET"
API_REQUIRE_EXPECTATION=true
API_LAST_NOTE=""
FEEDBACK_SCRIPT="$SCRIPT_DIR/feedback_from_test.py"

BASE_URL=""
RESULTS_FILE=""

TEST_MEMORY_FILE="$MEMORY_DIR/test-learnings.json"

# SimpleMem-Cross lifecycle artifacts
SESSION_ID=""
SESSION_STARTED_AT=""
SESSION_STOPPED_AT=""
SESSION_DIR="$STATE_DIR/test-sessions"
SESSION_FILE=""
SESSION_EVENTS_FILE=""
SESSION_PLAN_FILE=""
SESSION_METADATA_FILE=""
SESSION_REPEAT_GUARD_THRESHOLD=2
SESSION_STATUS="running"

CASE_PLAN_FILE=""
FEATURE_SAFE=""

LAST_BATCH_BLOCKED=0
FINAL_BLOCKED=0

AGENT_BROWSER_WAIT_MS=800

MEMORY_DELTA_NEW_SIGNATURES=0
MEMORY_DELTA_UPDATED_SIGNATURES=0
MEMORY_DELTA_PLAYBOOK_REUSED=0
MEMORY_DELTA_REPEAT_GUARD=0

CASE_PLAN_HAS_UI=true
CASE_PLAN_HAS_API=false
CASE_PLAN_HAS_MANUAL=false
CASE_PLAN_MODE_SUMMARY="{}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
  cat <<USAGE
Usage: $(basename "$0") [OPTIONS]

Automated test runner for Product Toolkit (Web UI focus)

Required:
  -v, --version VERSION         Product version (e.g. v1.0.0)
  -f, --feature FEATURE         Feature name (e.g. 电商收藏功能)

Test execution:
  -t, --type TYPE               smoke|regression|full (default: full)
  -i, --iterations N            Max retries when failed (default: 3)
      --test-file PATH          Custom test case file path
      --dry-run                 Print planned execution only
      --manual-results PATH     JSON manual result file (for Manual cases)

Tool selection:
      --tool TOOL               auto|agent-browser|browser-use (default: auto)
      --tool-priority LIST      Comma list, e.g. agent-browser,browser-use
      --headed                  Run visible browser (mainly for agent-browser)

Frontend startup:
      --frontend-cmd CMD        Start frontend before tests (e.g. "pnpm dev")
      --frontend-dir DIR        Working directory for frontend cmd
      --frontend-url URL        Health URL / base URL to test (e.g. http://127.0.0.1:5173)
      --frontend-timeout SEC    Wait timeout for frontend URL (default: 120)
      --no-frontend-auto-detect Disable package.json based auto detection
      --no-frontend-start       Do not start frontend process

Memory:
      --memory-file PATH        Override learnings memory file path

API validation:
      --api-base-url URL        Base URL for API cases (default: frontend/base URL)
      --api-timeout SEC         Timeout for API calls (default: 15)
      --api-vars LIST           Placeholder values, e.g. id=1,code=ABC
      --api-headers LIST        Headers separated by ';', e.g. "Authorization: Bearer x;X-Trace: y"
      --api-default-method M    Fallback method for API cases (default: GET)
      --no-api-require-expectation
                                Allow API case without inferred expectation

General:
  -h, --help                    Show this help

Examples:
  $(basename "$0") -v v1.0.0 -f 登录功能 -t smoke
  $(basename "$0") -v v1.0.0 -f 收藏功能 --frontend-cmd "pnpm dev" --frontend-url http://127.0.0.1:5173
  $(basename "$0") -v v1.0.0 -f 收藏功能 --frontend-dir ./apps/web   # auto-detect package.json scripts
  $(basename "$0") -v v1.0.0 -f 购物车 --tool-priority agent-browser,browser-use
USAGE
  exit 1
}

print_header() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Product Toolkit Automated Test Runner${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo -e "${CYAN}Version:${NC}           $VERSION"
  echo -e "${CYAN}Feature:${NC}           $FEATURE"
  echo -e "${CYAN}Test Type:${NC}         $TEST_TYPE"
  echo -e "${CYAN}Max Iterations:${NC}    $MAX_ITERATIONS"
  echo -e "${CYAN}Test File:${NC}         $TEST_FILE"
  echo -e "${CYAN}Tool Mode:${NC}         $TOOL_MODE"
  echo -e "${CYAN}Selected Tool:${NC}     ${SELECTED_TOOL:-pending}"
  echo -e "${CYAN}Browser Headed:${NC}    $BROWSER_HEADED"
  echo -e "${CYAN}Base URL:${NC}          ${BASE_URL:-pending}"
  echo -e "${CYAN}Frontend Start:${NC}    $START_FRONTEND"
  echo -e "${CYAN}Frontend AutoDetect:${NC} $FRONTEND_AUTO_DETECT"
  if [[ -n "$FRONTEND_CMD" ]]; then
    echo -e "${CYAN}Frontend Command:${NC}  $FRONTEND_CMD"
    echo -e "${CYAN}Frontend Dir:${NC}      $FRONTEND_DIR"
  fi
  if [[ -n "$FRONTEND_URL" ]]; then
    echo -e "${CYAN}Frontend URL:${NC}      $FRONTEND_URL (timeout ${FRONTEND_TIMEOUT}s)"
  fi
  if [[ -n "$MANUAL_RESULTS_FILE" ]]; then
    echo -e "${CYAN}Manual Results:${NC}    $MANUAL_RESULTS_FILE"
  fi
  if [[ -n "$MANUAL_RESULTS_TEMPLATE_FILE" ]]; then
    echo -e "${CYAN}Manual Template:${NC}   $MANUAL_RESULTS_TEMPLATE_FILE"
  fi
  echo -e "${CYAN}API Base URL:${NC}      ${API_BASE_URL:-auto(base_url)}"
  echo -e "${CYAN}API Timeout:${NC}       ${API_TIMEOUT}s"
  echo -e "${CYAN}API Default Method:${NC} $API_DEFAULT_METHOD"
  echo -e "${CYAN}API Require Expect:${NC} $API_REQUIRE_EXPECTATION"
  if [[ -n "$CASE_PLAN_MODE_SUMMARY" ]]; then
    echo -e "${CYAN}Case Modes:${NC}        ${CASE_PLAN_MODE_SUMMARY}"
  fi
  echo -e "${CYAN}Memory File:${NC}       $TEST_MEMORY_FILE"
  echo
}

require_value() {
  local key="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo -e "${RED}Error: Missing value for ${key}${NC}"
    usage
  fi
}

sanitize_name() {
  # shell-safe filename segment
  echo "$1" | sed -E 's/[^A-Za-z0-9._-]+/_/g'
}

iso_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

normalize_base_url() {
  if [[ -n "$FRONTEND_URL" ]]; then
    BASE_URL="${FRONTEND_URL%/}"
  else
    BASE_URL="http://localhost:3000"
  fi
}

normalize_api_base_url() {
  if [[ -n "$API_BASE_URL" ]]; then
    API_BASE_URL="${API_BASE_URL%/}"
  else
    API_BASE_URL="$BASE_URL"
  fi
}

guess_frontend_url_from_cmd() {
  local cmd="$1"
  python3 - "$cmd" <<'PY'
import re
import sys

cmd = sys.argv[1] or ""
lower = cmd.lower()

port = None
patterns = [
    r'--port(?:=|\s+)(\d{2,5})',
    r'(?<![\w-])-p(?:=|\s+)(\d{2,5})',
    r'PORT=(\d{2,5})',
]
for p in patterns:
    m = re.search(p, cmd)
    if m:
        port = int(m.group(1))
        break

if port is None:
    if "vite" in lower:
        port = 5173
    elif "astro" in lower:
        port = 4321
    elif "parcel" in lower:
        port = 1234
    elif "next" in lower or "nuxt" in lower or "react-scripts" in lower or "webpack-dev-server" in lower:
        port = 3000
    else:
        port = 3000

print(f"http://127.0.0.1:{port}")
PY
}

detect_frontend_from_package_json() {
  local pkg="$FRONTEND_DIR/package.json"
  [[ -f "$pkg" ]] || return 1

  local detected
  detected="$(python3 - "$pkg" <<'PY'
import json
import re
import sys
from pathlib import Path

pkg_path = Path(sys.argv[1])
root = pkg_path.parent

try:
    data = json.loads(pkg_path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(1)

scripts = data.get("scripts") or {}
if not isinstance(scripts, dict):
    raise SystemExit(1)

script_name = None
for cand in ("dev", "start", "serve", "preview"):
    v = scripts.get(cand)
    if isinstance(v, str) and v.strip():
        script_name = cand
        break

if not script_name:
    raise SystemExit(1)

script_cmd = scripts.get(script_name, "")

pm = None
if (root / "pnpm-lock.yaml").exists():
    pm = "pnpm"
elif (root / "yarn.lock").exists():
    pm = "yarn"
elif (root / "bun.lockb").exists() or (root / "bun.lock").exists():
    pm = "bun"
elif (root / "package-lock.json").exists() or (root / "npm-shrinkwrap.json").exists():
    pm = "npm"
else:
    package_manager = str(data.get("packageManager", ""))
    if package_manager:
        pm = package_manager.split("@", 1)[0]

if pm not in {"pnpm", "yarn", "bun", "npm"}:
    pm = "npm"

if pm == "pnpm":
    cmd = f"pnpm {script_name}"
elif pm == "yarn":
    cmd = f"yarn {script_name}"
elif pm == "bun":
    cmd = f"bun run {script_name}"
else:
    cmd = f"npm run {script_name}"

port = None
patterns = [
    r'--port(?:=|\s+)(\d{2,5})',
    r'(?<![\w-])-p(?:=|\s+)(\d{2,5})',
    r'PORT=(\d{2,5})',
]
for p in patterns:
    m = re.search(p, script_cmd)
    if m:
        port = int(m.group(1))
        break

if port is None:
    lower = script_cmd.lower()
    if "vite" in lower:
        port = 5173
    elif "astro" in lower:
        port = 4321
    elif "parcel" in lower:
        port = 1234
    elif "next" in lower or "nuxt" in lower or "react-scripts" in lower or "webpack-dev-server" in lower:
        port = 3000
    else:
        port = 3000

url = f"http://127.0.0.1:{port}"
print("\t".join([cmd, url, script_name, pm]))
PY
)" || return 1

  local cmd url script_name pm
  IFS=$'\t' read -r cmd url script_name pm <<< "$detected"

  if [[ -n "$cmd" && -z "$FRONTEND_CMD" ]]; then
    FRONTEND_CMD="$cmd"
    echo -e "${CYAN}Auto-detected frontend command:${NC} $FRONTEND_CMD (script=${script_name}, pm=${pm})"
  fi

  if [[ -n "$url" && -z "$FRONTEND_URL" ]]; then
    FRONTEND_URL="$url"
    echo -e "${CYAN}Auto-detected frontend URL:${NC} $FRONTEND_URL"
  fi

  return 0
}

auto_detect_frontend_if_needed() {
  if [[ "$FRONTEND_AUTO_DETECT" != true ]]; then
    return 0
  fi

  if [[ -n "$FRONTEND_CMD" && -n "$FRONTEND_URL" ]]; then
    return 0
  fi

  if detect_frontend_from_package_json; then
    return 0
  fi

  if [[ -n "$FRONTEND_CMD" && -z "$FRONTEND_URL" ]]; then
    FRONTEND_URL="$(guess_frontend_url_from_cmd "$FRONTEND_CMD")"
    echo -e "${CYAN}Guessed frontend URL from command:${NC} $FRONTEND_URL"
    return 0
  fi

  if [[ -z "$FRONTEND_CMD" && -z "$FRONTEND_URL" ]]; then
    echo -e "${YELLOW}No package.json auto-detection result. Use --frontend-cmd/--frontend-url for better accuracy.${NC}"
  fi
}

is_tool_available() {
  local tool="$1"
  case "$tool" in
    agent-browser)
      command_exists agent-browser
      ;;
    browser-use)
      command_exists browser-use || command_exists npx
      ;;
    *)
      return 1
      ;;
  esac
}

attempt_install_tool() {
  local tool="$1"

  [[ "$DRY_RUN" == true ]] && return 0

  case "$tool" in
    agent-browser)
      if command_exists agent-browser; then
        return 0
      fi
      if ! command_exists npm; then
        return 1
      fi
      echo -e "${YELLOW}agent-browser not found. Installing via npm...${NC}"
      if npm install -g agent-browser >/dev/null 2>&1; then
        command_exists agent-browser || return 1
        agent-browser install >/dev/null 2>&1 || true
        return 0
      fi
      return 1
      ;;
    browser-use)
      if command_exists browser-use || command_exists npx; then
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

select_tool() {
  if [[ "$TOOL_MODE" != "auto" ]]; then
    attempt_install_tool "$TOOL_MODE" || true
    if ! is_tool_available "$TOOL_MODE"; then
      if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}Warning: requested tool '$TOOL_MODE' is unavailable, but continue in dry-run mode${NC}"
        SELECTED_TOOL="$TOOL_MODE"
        return 0
      fi
      echo -e "${RED}Error: requested tool '$TOOL_MODE' is not available${NC}"
      exit 1
    fi
    SELECTED_TOOL="$TOOL_MODE"
    return 0
  fi

  IFS=',' read -r -a priorities <<< "$TOOL_PRIORITY"
  for raw in "${priorities[@]}"; do
    local t
    t="$(echo "$raw" | xargs)"
    [[ -z "$t" ]] && continue
    attempt_install_tool "$t" || true
    if is_tool_available "$t"; then
      SELECTED_TOOL="$t"
      return 0
    fi
  done

  if [[ "$DRY_RUN" == true ]]; then
    SELECTED_TOOL="$(echo "$TOOL_PRIORITY" | cut -d',' -f1 | xargs)"
    [[ -z "$SELECTED_TOOL" ]] && SELECTED_TOOL="agent-browser"
    echo -e "${YELLOW}Warning: no browser tool available; continue with dry-run planned tool '$SELECTED_TOOL'${NC}"
    return 0
  fi

  echo -e "${RED}Error: no browser tool available. Tried: $TOOL_PRIORITY${NC}"
  echo "Install one of: agent-browser, browser-use (or ensure npx is available)."
  exit 1
}

create_dirs() {
  FEATURE_SAFE="$(sanitize_name "$FEATURE")"
  mkdir -p "$STATE_DIR" "$MEMORY_DIR" "$SESSION_DIR" "$EVIDENCE_DIR/$VERSION/$FEATURE/screenshots"
  RESULTS_FILE="$EVIDENCE_DIR/$VERSION/$FEATURE/results.tsv"
  CASE_PLAN_FILE="$EVIDENCE_DIR/$VERSION/$FEATURE/case-plan.json"
  : > "$RESULTS_FILE"
}

ensure_memory_file() {
  mkdir -p "$(dirname "$TEST_MEMORY_FILE")"
  python3 - "$TEST_MEMORY_FILE" "$(iso_now)" <<'PY'
import json
import sys
from collections import defaultdict
from pathlib import Path

path = Path(sys.argv[1])
now = sys.argv[2]

default_playbooks = {
    "frontend_unreachable": [
        "检查 --frontend-cmd / --frontend-url 参数是否正确",
        "确认前端服务端口已监听并可访问",
        "执行服务可达性验证后再继续测试",
    ],
    "navigation_failure": [
        "确认测试用例中的 URL / 路由仍然有效",
        "先打开 BASE_URL，再导航到目标页",
        "对路由重定向场景增加等待与快照校验",
    ],
    "timeout_or_slow_response": [
        "增加页面稳定等待时间（agent-browser wait）",
        "优先检查接口响应与首屏渲染性能",
        "必要时提升 --frontend-timeout 并分离慢用例",
    ],
    "selector_or_dom_changed": [
        "避免模糊文本匹配，使用唯一定位策略",
        "每个关键步骤前先 snapshot -i 校验可交互元素",
        "文本重复时使用更精确文案或结构化定位",
    ],
    "auth_or_permission": [
        "校验测试账号权限与登录态初始化",
        "将登录链路放入 P0 冒烟前置门禁",
        "禁止未授权场景直接进入核心路径",
    ],
    "backend_internal_error": [
        "先检查后端健康接口与错误日志",
        "定位失败 API 并补充回归用例",
        "确认数据准备满足前置条件",
    ],
    "unknown_failure": [
        "阅读失败日志与截图，补充可复用修复建议",
        "将失败模式归类为明确 signature",
        "为该 signature 新增回归测试用例",
    ],
}

data = {}
if path.exists():
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}

pitfalls = data.get("pitfalls") if isinstance(data.get("pitfalls"), list) else []
signatures = data.get("signatures") if isinstance(data.get("signatures"), list) else []
playbooks = data.get("playbooks") if isinstance(data.get("playbooks"), list) else []
sessions = data.get("sessions") if isinstance(data.get("sessions"), list) else []

# Migrate legacy v1 pitfalls -> signatures
if not signatures and pitfalls:
    grouped = defaultdict(lambda: {
        "signature_id": "",
        "signature": "",
        "category": "test_failure_pattern",
        "suggestion": "",
        "count": 0,
        "first_seen": now,
        "last_seen": now,
        "features": set(),
        "test_cases": set(),
        "last_snippet": "",
    })
    for p in pitfalls:
        if not isinstance(p, dict):
            continue
        sig = str(p.get("signature") or "unknown_failure")
        g = grouped[sig]
        g["signature_id"] = sig
        g["signature"] = sig
        g["suggestion"] = str(p.get("suggestion") or "")
        g["count"] += int(p.get("count") or 1)
        g["first_seen"] = min(g["first_seen"], str(p.get("first_seen") or now))
        g["last_seen"] = max(g["last_seen"], str(p.get("last_seen") or now))
        g["features"].add(str(p.get("feature") or ""))
        g["test_cases"].add(str(p.get("test_case") or ""))
        g["last_snippet"] = str(p.get("snippet") or g["last_snippet"])

    signatures = []
    for g in grouped.values():
        signatures.append({
            "signature_id": g["signature_id"],
            "signature": g["signature"],
            "category": g["category"],
            "suggestion": g["suggestion"],
            "count": g["count"],
            "first_seen": g["first_seen"],
            "last_seen": g["last_seen"],
            "features": [x for x in sorted(g["features"]) if x],
            "test_cases": [x for x in sorted(g["test_cases"]) if x],
            "last_snippet": g["last_snippet"],
        })

existing_signature_ids = {str(s.get("signature_id") or s.get("signature") or "") for s in signatures if isinstance(s, dict)}
existing_playbook_sig = {str(p.get("signature_id") or "") for p in playbooks if isinstance(p, dict)}

for sig, steps in default_playbooks.items():
    if sig not in existing_signature_ids:
        signatures.append({
            "signature_id": sig,
            "signature": sig,
            "category": "test_failure_pattern",
            "suggestion": "",
            "count": 0,
            "first_seen": now,
            "last_seen": now,
            "features": [],
            "test_cases": [],
            "last_snippet": "",
        })
    if sig not in existing_playbook_sig:
        playbooks.append({
            "playbook_id": f"pb_{sig}_v1",
            "signature_id": sig,
            "name": f"Auto Playbook - {sig}",
            "steps": steps,
            "success_count": 0,
            "fail_count": 0,
            "confidence": 0.2,
            "auto_apply": True,
            "last_used": "",
        })

data = {
    "version": "2.0",
    "updated_at": now,
    "signatures": signatures[:500],
    "playbooks": playbooks[:500],
    "sessions": sessions[:500],
    # compatibility
    "pitfalls": pitfalls[:500],
}

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

record_event() {
  local kind="$1"
  local case_id="${2:-}"
  local status="${3:-}"
  local message="${4:-}"
  local data_json="${5:-{}}"

  [[ -z "$SESSION_EVENTS_FILE" ]] && return 0

  python3 - "$SESSION_EVENTS_FILE" "$kind" "$case_id" "$status" "$message" "$data_json" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

events_file = Path(sys.argv[1])
kind = sys.argv[2]
case_id = sys.argv[3]
status = sys.argv[4]
message = sys.argv[5]
raw_data = sys.argv[6]
ts = sys.argv[7]

try:
    data = json.loads(raw_data) if raw_data else {}
    if not isinstance(data, dict):
        data = {"raw": raw_data}
except Exception:
    data = {"raw": raw_data}

event = {
    "timestamp": ts,
    "kind": kind,
    "case_id": case_id or None,
    "status": status or None,
    "message": message or None,
    "data": data,
}

events_file.parent.mkdir(parents=True, exist_ok=True)
with events_file.open("a", encoding="utf-8") as f:
    f.write(json.dumps(event, ensure_ascii=False) + "\n")
PY
}

build_case_plan() {
  local mode="$1"
  python3 - "$TEST_FILE" "$mode" "$CASE_PLAN_FILE" "$BASE_URL" <<'PY'
import json
import re
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

test_file = Path(sys.argv[1])
mode = sys.argv[2]
out_file = Path(sys.argv[3])
base_url = sys.argv[4].rstrip("/")

text = test_file.read_text(encoding="utf-8")
lines = text.splitlines()

us_pattern = re.compile(r"^#{2,6}\s*(?:\d+[.)]?\s*)?(US[-_A-Za-z0-9]+)\b", re.IGNORECASE)
case_pattern = re.compile(r"^#{3,6}\s*((?:SMK|SMOKE|TC)-[A-Za-z0-9_-]+)\b", re.IGNORECASE)
table_case_pattern = re.compile(r"^(?:SMK|SMOKE|TC)-[A-Za-z0-9_-]+$", re.IGNORECASE)
summary_count_pattern = re.compile(r"^\|\s*([^|]+?)\s*\|\s*\**\s*([0-9]+)\s*\**\s*\|")
url_pattern = re.compile(r"https?://[^\s)`\"|]+")
path_pattern = re.compile(r"(?<![A-Za-z0-9_])(/[A-Za-z0-9._~/%#?=&:+-]+)")

all_us = []
current_us = "UNKNOWN"
cases = []
seen_case_ids = set()


def normalize_us(raw: str) -> str:
    return str(raw or "").upper().replace("_", "-")


def normalize_case(raw: str) -> str:
    return str(raw or "").upper()


def add_us(us_id: str):
    if us_id and us_id not in all_us:
        all_us.append(us_id)


def should_keep_case(case_id: str) -> bool:
    upper = case_id.upper()
    is_smoke = upper.startswith("SMK-") or upper.startswith("SMOKE-")
    is_tc = upper.startswith("TC-")
    if mode == "smoke":
        return is_smoke
    if mode == "regression":
        return is_tc
    if mode == "full":
        return is_smoke or is_tc
    return False


def parse_execution_mode_tags(raw: str) -> str:
    lower = (raw or "").lower()
    tags = []
    if "agent-browser" in lower:
        tags.append("agent-browser")
    if "browser-use" in lower:
        tags.append("browser-use")
    if "manual" in lower or "手工" in lower or "人工" in lower:
        tags.append("manual")
    if re.search(r"\bapi\b", lower) or "接口" in lower:
        tags.append("api")
    if not tags:
        tags.append("agent-browser")
    return ",".join(sorted(dict.fromkeys(tags)))


def infer_method_hint(raw: str) -> str:
    m = re.search(r"\b(GET|POST|PUT|PATCH|DELETE|OPTIONS|HEAD)\b", str(raw or ""), flags=re.IGNORECASE)
    if m:
        return m.group(1).upper()
    return ""


def infer_expectation(raw: str, execution_mode: str) -> str:
    lower = str(raw or "").lower()
    mode_lower = str(execution_mode or "").lower()
    negative_keywords = [
        "reject", "refuse", "invalid", "forbidden", "denied", "error", "failed", "fail",
        "拒绝", "失败", "无效", "过期", "已用完", "阻止", "禁止", "不可", "不能", "不允许", "报错", "错误", "异常", "未授权", "无权限",
    ]
    positive_keywords = [
        "success", "ok", "created", "updated", "进入", "成功", "可访问", "显示", "刷新", "新增", "跳转", "可继续", "可见",
    ]
    if any(k in lower for k in negative_keywords):
        return "error"
    if any(k in lower for k in positive_keywords):
        return "success"
    if "api" in mode_lower:
        return "unknown"
    return "success"


def extract_target_hint(block_text: str) -> str:
    m_url = url_pattern.search(block_text)
    if m_url:
        return m_url.group(0)
    for m_path in path_pattern.finditer(block_text):
        candidate = m_path.group(1)
        if not candidate.startswith("/product-toolkit"):
            return candidate
    return ""


def extract_ac_ids(block_text: str):
    return sorted(set(re.findall(r"\bAC-[A-Za-z0-9_-]+\b", block_text, flags=re.IGNORECASE)))


# Parse declared summary counts if table exists (strict parser guard)
declared_us_case_counts = {}
declared_total_cases = None
for raw in lines:
    line = raw.strip()
    m = summary_count_pattern.match(line)
    if not m:
        continue
    left = m.group(1).strip()
    count = int(m.group(2))
    if re.search(r"总计|total", left, flags=re.IGNORECASE):
        declared_total_cases = count
        continue
    m_us = re.search(r"(US[-_A-Za-z0-9]+)", left, flags=re.IGNORECASE)
    if m_us:
        us_id = normalize_us(m_us.group(1))
        declared_us_case_counts[us_id] = count
        add_us(us_id)

i = 0
while i < len(lines):
    line = lines[i].strip()

    m_us = us_pattern.match(line)
    if m_us:
        current_us = normalize_us(m_us.group(1))
        add_us(current_us)
        i += 1
        continue

    if line.startswith("|") and current_us != "UNKNOWN":
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 2:
            first_col = normalize_case(cells[0])
            if table_case_pattern.match(first_col):
                case_id = first_col
                if should_keep_case(case_id) and case_id not in seen_case_ids:
                    row_text = "\n".join(cells)
                    execution_mode = parse_execution_mode_tags(cells[-1] if cells else "")
                    step_text = cells[3] if len(cells) > 3 else row_text
                    expected_text = cells[4] if len(cells) > 4 else row_text
                    cases.append({
                        "order": len(cases) + 1,
                        "us_id": current_us,
                        "case_id": case_id,
                        "target_hint": extract_target_hint(row_text),
                        "ac_ids": [ac.upper() for ac in extract_ac_ids(row_text)],
                        "execution_mode": execution_mode,
                        "method_hint": infer_method_hint(step_text),
                        "expectation_hint": infer_expectation(f"{step_text}\n{expected_text}", execution_mode),
                        "source_format": "table",
                    })
                    seen_case_ids.add(case_id)
        i += 1
        continue

    m_case = case_pattern.match(line)
    if not m_case:
        i += 1
        continue

    case_id = normalize_case(m_case.group(1))
    if not should_keep_case(case_id):
        i += 1
        continue

    block = [lines[i]]
    j = i + 1
    while j < len(lines):
        nxt = lines[j].strip()
        if case_pattern.match(nxt) or us_pattern.match(nxt):
            break
        block.append(lines[j])
        j += 1

    block_text = "\n".join(block)
    if case_id not in seen_case_ids:
        execution_mode = parse_execution_mode_tags(block_text)
        cases.append({
            "order": len(cases) + 1,
            "us_id": current_us,
            "case_id": case_id,
            "target_hint": extract_target_hint(block_text),
            "ac_ids": [ac.upper() for ac in extract_ac_ids(block_text)],
            "execution_mode": execution_mode,
            "method_hint": infer_method_hint(block_text),
            "expectation_hint": infer_expectation(block_text, execution_mode),
            "source_format": "heading",
        })
        seen_case_ids.add(case_id)

    i = j
    continue

us_with_cases = {c["us_id"] for c in cases if c["us_id"] != "UNKNOWN"}
missing_test_cases = [u for u in all_us if u not in us_with_cases]
missing_user_stories = sorted({c["case_id"] for c in cases if c["us_id"] == "UNKNOWN"})

parsed_us_case_counts = defaultdict(int)
for c in cases:
    us = c.get("us_id", "UNKNOWN")
    if us and us != "UNKNOWN":
        parsed_us_case_counts[us] += 1

for us in sorted(parsed_us_case_counts.keys()):
    add_us(us)

declared_vs_parsed_match = True
mismatched_us = []
if mode == "full" and declared_us_case_counts:
    for us, declared in declared_us_case_counts.items():
        parsed = int(parsed_us_case_counts.get(us, 0))
        if declared != parsed:
            declared_vs_parsed_match = False
            mismatched_us.append({
                "us_id": us,
                "declared": declared,
                "parsed": parsed,
            })
if mode == "full" and declared_total_cases is not None and declared_total_cases != len(cases):
    declared_vs_parsed_match = False

suspicious_one_to_one = False
if mode == "full":
    us_count = len([u for u, cnt in parsed_us_case_counts.items() if cnt > 0])
    if us_count >= 3 and len(cases) <= us_count:
        suspicious_one_to_one = True
        declared_vs_parsed_match = False

out = {
    "schema_version": "1.0",
    "generated_at": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "mode": mode,
    "test_file": str(test_file),
    "base_url": base_url,
    "all_us": all_us,
    "cases": cases,
    "declared_counts": {
        "us_case_counts": declared_us_case_counts,
        "total_cases": declared_total_cases,
    },
    "parsed_counts": {
        "us_case_counts": dict(parsed_us_case_counts),
        "total_cases": len(cases),
    },
    "strict": {
        "declared_vs_parsed_match": declared_vs_parsed_match,
        "mismatched_us": mismatched_us,
        "suspicious_one_to_one": suspicious_one_to_one,
    },
    "gaps": {
        "missing_test_cases": missing_test_cases,
        "missing_user_story_mapping": missing_user_stories
    }
}

out_file.parent.mkdir(parents=True, exist_ok=True)
out_file.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Case plan generated: {out_file} ({len(cases)} cases)")
PY
}

analyze_case_plan_modes() {
  local summary
  summary="$(python3 - "$CASE_PLAN_FILE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    print("ui=1 api=0 manual=0 summary={}")
    raise SystemExit(0)

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("ui=1 api=0 manual=0 summary={}")
    raise SystemExit(0)

cases = data.get("cases", []) if isinstance(data.get("cases"), list) else []
ui = 0
api = 0
manual = 0
counts = {}

for c in cases:
    mode = str(c.get("execution_mode") or "").lower()
    tags = [x.strip() for x in mode.split(",") if x.strip()]
    if not tags:
        tags = ["agent-browser"]
    for t in tags:
        counts[t] = counts.get(t, 0) + 1
    if "agent-browser" in tags or "browser-use" in tags:
        ui = 1
    if "api" in tags:
        api = 1
    if "manual" in tags:
        manual = 1

print(f"ui={ui} api={api} manual={manual} summary={json.dumps(counts, ensure_ascii=False)}")
PY
)"

  CASE_PLAN_HAS_UI=true
  CASE_PLAN_HAS_API=false
  CASE_PLAN_HAS_MANUAL=false
  CASE_PLAN_MODE_SUMMARY="{}"

  if [[ "$summary" =~ ui=([01]) ]]; then
    [[ "${BASH_REMATCH[1]}" == "1" ]] && CASE_PLAN_HAS_UI=true || CASE_PLAN_HAS_UI=false
  fi
  if [[ "$summary" =~ api=([01]) ]]; then
    [[ "${BASH_REMATCH[1]}" == "1" ]] && CASE_PLAN_HAS_API=true || CASE_PLAN_HAS_API=false
  fi
  if [[ "$summary" =~ manual=([01]) ]]; then
    [[ "${BASH_REMATCH[1]}" == "1" ]] && CASE_PLAN_HAS_MANUAL=true || CASE_PLAN_HAS_MANUAL=false
  fi
  CASE_PLAN_MODE_SUMMARY="${summary#*summary=}"
}

prepare_manual_results_artifacts() {
  MANUAL_RESULTS_RESOLVED="$EVIDENCE_DIR/$VERSION/$FEATURE/manual-results-${SESSION_ID}.json"
  MANUAL_RESULTS_TEMPLATE_FILE="$EVIDENCE_DIR/$VERSION/$FEATURE/manual-results-template-${SESSION_ID}.json"

  python3 - "$CASE_PLAN_FILE" "$MANUAL_RESULTS_FILE" "$MANUAL_RESULTS_RESOLVED" "$MANUAL_RESULTS_TEMPLATE_FILE" <<'PY'
import json
import sys
from pathlib import Path

plan_file, manual_results_file, resolved_file, template_file = sys.argv[1:]

plan = {}
try:
    plan = json.loads(Path(plan_file).read_text(encoding="utf-8"))
except Exception:
    plan = {}

cases = plan.get("cases", []) if isinstance(plan.get("cases"), list) else []
manual_api_cases = []
for c in cases:
    mode = str(c.get("execution_mode") or "").lower()
    if "manual" in mode or "api" in mode:
        manual_api_cases.append(c)

template = {}
for c in manual_api_cases:
    cid = str(c.get("case_id") or "")
    if not cid:
        continue
    template[cid] = {
        "status": "pending",
        "note": "",
        "evidence": "",
        "execution_mode": c.get("execution_mode", ""),
    }

provided = {}
if manual_results_file:
    p = Path(manual_results_file)
    if p.exists():
        try:
            raw = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(raw, dict):
                provided = raw
            elif isinstance(raw, list):
                provided = {}
                for item in raw:
                    if isinstance(item, dict) and item.get("case_id"):
                        provided[str(item["case_id"])] = item
        except Exception:
            provided = {}

merged = {}
for cid, item in template.items():
    v = provided.get(cid, {})
    if not isinstance(v, dict):
        v = {}
    status = str(v.get("status", item["status"])).strip().lower()
    if status not in {"passed", "failed", "blocked", "pending"}:
        status = "pending"
    merged[cid] = {
        "status": status,
        "note": str(v.get("note", item["note"] or "")).strip(),
        "evidence": str(v.get("evidence", item["evidence"] or "")).strip(),
        "execution_mode": item.get("execution_mode", ""),
    }

Path(resolved_file).write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")
Path(template_file).write_text(json.dumps(template, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"manual_api_cases={len(manual_api_cases)}")
PY

  if [[ -f "$MANUAL_RESULTS_TEMPLATE_FILE" ]]; then
    echo -e "${CYAN}Manual/API result template:${NC} $MANUAL_RESULTS_TEMPLATE_FILE"
  fi
  if [[ -f "$MANUAL_RESULTS_RESOLVED" ]]; then
    echo -e "${CYAN}Manual/API resolved map:${NC} $MANUAL_RESULTS_RESOLVED"
  fi
}

lookup_manual_case_result() {
  local case_id="$1"
  python3 - "$MANUAL_RESULTS_RESOLVED" "$case_id" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
case_id = sys.argv[2]
obj = {}
if path.exists():
    try:
        obj = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        obj = {}
item = obj.get(case_id, {}) if isinstance(obj, dict) else {}
if not isinstance(item, dict):
    item = {}
status = str(item.get("status", "pending")).strip().lower()
if status not in {"passed", "failed", "blocked", "pending"}:
    status = "pending"
note = str(item.get("note", "")).strip()
evidence = str(item.get("evidence", "")).strip()
print("\x1f".join([status, note, evidence]))
PY
}

resolve_api_target_url() {
  local target_hint="$1"
  python3 - "$target_hint" "$API_BASE_URL" "$API_VARS" <<'PY'
import re
import sys

target_hint, base_url, vars_csv = sys.argv[1:]
base = (base_url or "").rstrip("/")
hint = (target_hint or "").strip()

if hint.startswith("http://") or hint.startswith("https://"):
    url = hint
elif hint.startswith("/"):
    url = f"{base}{hint}"
elif hint:
    url = f"{base}/{hint.lstrip('/')}"
else:
    url = base

vars_map = {}
for pair in (vars_csv or "").split(","):
    pair = pair.strip()
    if not pair or "=" not in pair:
        continue
    k, v = pair.split("=", 1)
    vars_map[k.strip()] = v.strip()

missing = []
def repl(match):
    key = match.group(1)
    if key in vars_map:
        return vars_map[key]
    if key.lower() in vars_map:
        return vars_map[key.lower()]
    missing.append(key)
    return match.group(0)

resolved = re.sub(r":([A-Za-z_][A-Za-z0-9_]*)", repl, url)
missing = sorted(set(missing))
print("\x1f".join([resolved, ",".join(missing)]))
PY
}

run_api_case() {
  local case_id="$1"
  local target_hint="$2"
  local method_hint="$3"
  local expectation_hint="$4"
  local case_log="$5"
  local safe_case="$6"
  local iteration="$7"

  local api_response_file="$EVIDENCE_DIR/$VERSION/$FEATURE/api-${safe_case}-iter${iteration}.response.txt"
  local api_meta_file="$EVIDENCE_DIR/$VERSION/$FEATURE/api-${safe_case}-iter${iteration}.meta.txt"
  local resolved_pair resolved_url missing_vars
  API_LAST_NOTE=""
  resolved_pair="$(resolve_api_target_url "$target_hint")"
  resolved_url="${resolved_pair%%$'\x1f'*}"
  missing_vars="${resolved_pair#*$'\x1f'}"

  if [[ -n "$missing_vars" ]]; then
    echo "API blocked: unresolved placeholders -> $missing_vars" >>"$case_log"
    echo "url=$resolved_url" >"$api_meta_file"
    echo "missing_vars=$missing_vars" >>"$api_meta_file"
    echo "blocked_note=api_placeholders_unresolved:$missing_vars" >>"$api_meta_file"
    API_LAST_NOTE="api_placeholders_unresolved:${missing_vars}"
    return 2
  fi

  local method
  method="$(echo "${method_hint:-}" | tr '[:lower:]' '[:upper:]')"
  [[ -z "$method" ]] && method="$(echo "${API_DEFAULT_METHOD:-GET}" | tr '[:lower:]' '[:upper:]')"
  [[ -z "$method" ]] && method="GET"

  local expectation
  expectation="$(echo "${expectation_hint:-unknown}" | tr '[:upper:]' '[:lower:]')"
  [[ -z "$expectation" ]] && expectation="unknown"
  if [[ "$expectation" == "unknown" && "$API_REQUIRE_EXPECTATION" == true ]]; then
    echo "API blocked: expectation unknown for $case_id" >>"$case_log"
    echo "url=$resolved_url" >"$api_meta_file"
    echo "method=$method" >>"$api_meta_file"
    echo "blocked_note=api_expectation_unknown" >>"$api_meta_file"
    API_LAST_NOTE="api_expectation_unknown"
    return 2
  fi

  local -a header_args=()
  if [[ -n "$API_HEADERS" ]]; then
    IFS=';' read -r -a raw_headers <<<"$API_HEADERS"
    for h in "${raw_headers[@]}"; do
      h="$(echo "$h" | xargs)"
      [[ -z "$h" ]] && continue
      header_args+=(-H "$h")
    done
  fi

  local -a curl_cmd
  curl_cmd=(curl -sS -m "$API_TIMEOUT" -o "$api_response_file" -w "%{http_code}" -X "$method")
  if (( ${#header_args[@]} > 0 )); then
    curl_cmd+=("${header_args[@]}")
  fi
  curl_cmd+=("$resolved_url")

  local http_code
  echo "API request: method=$method url=$resolved_url expectation=$expectation timeout=${API_TIMEOUT}s" >>"$case_log"
  http_code="$("${curl_cmd[@]}" 2>>"$case_log" || echo "000")"
  http_code="$(echo "$http_code" | tr -d '\r\n')"
  echo "url=$resolved_url" >"$api_meta_file"
  echo "method=$method" >>"$api_meta_file"
  echo "expectation=$expectation" >>"$api_meta_file"
  echo "http_code=$http_code" >>"$api_meta_file"

  if [[ "$http_code" == "000" ]]; then
    echo "result=blocked_transport_or_connectivity" >>"$api_meta_file"
    API_LAST_NOTE="api_transport_or_connectivity_failure"
    return 2
  fi

  if [[ "$expectation" == "error" ]]; then
    if [[ "$http_code" =~ ^[45][0-9][0-9]$ ]]; then
      echo "result=passed" >>"$api_meta_file"
      API_LAST_NOTE="api_error_expected_http:${http_code}"
      return 0
    fi
    echo "result=failed" >>"$api_meta_file"
    API_LAST_NOTE="api_expected_error_but_http:${http_code}"
    return 1
  fi

  if [[ "$expectation" == "success" ]]; then
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
      echo "result=passed" >>"$api_meta_file"
      API_LAST_NOTE="api_success_http:${http_code}"
      return 0
    fi
    echo "result=failed" >>"$api_meta_file"
    API_LAST_NOTE="api_expected_success_but_http:${http_code}"
    return 1
  fi

  if [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
    echo "result=passed_unknown_expectation" >>"$api_meta_file"
    API_LAST_NOTE="api_unknown_expectation_http:${http_code}"
    return 0
  fi
  echo "result=blocked_unknown_expectation" >>"$api_meta_file"
  API_LAST_NOTE="api_unknown_expectation_http:${http_code}"
  return 2
}

start_test_session() {
  SESSION_STARTED_AT="$(iso_now)"
  SESSION_ID="${VERSION}-$(sanitize_name "$FEATURE")-$(date -u +%Y%m%dT%H%M%SZ)"
  SESSION_FILE="$SESSION_DIR/${SESSION_ID}.json"
  SESSION_EVENTS_FILE="$EVIDENCE_DIR/$VERSION/$FEATURE/session-events-${SESSION_ID}.ndjson"
  SESSION_PLAN_FILE="$CASE_PLAN_FILE"
  SESSION_METADATA_FILE="$EVIDENCE_DIR/$VERSION/$FEATURE/session-metadata-${SESSION_ID}.json"

  cat > "$SESSION_METADATA_FILE" <<JSON
{
  "session_id": "$SESSION_ID",
  "version": "$VERSION",
  "feature": "$FEATURE",
  "test_type": "$TEST_TYPE",
  "tool": "$SELECTED_TOOL",
  "base_url": "$BASE_URL",
  "api_base_url": "$API_BASE_URL",
  "manual_results_file": "$MANUAL_RESULTS_FILE",
  "started_at": "$SESSION_STARTED_AT",
  "status": "running"
}
JSON

  record_event "session_start" "" "running" "start -> record -> stop -> consolidate" "{\"session_id\":\"$SESSION_ID\"}"
}

resolve_target_url_from_hint() {
  local hint="${1:-}"
  if [[ -z "$hint" ]]; then
    echo "$BASE_URL"
    return 0
  fi

  if [[ "$hint" =~ ^https?:// ]]; then
    echo "$hint"
    return 0
  fi

  if [[ "$hint" == /* ]]; then
    join_base_and_path "$BASE_URL" "$hint"
    return 0
  fi

  echo "$BASE_URL"
}

playbook_exists_for_signature() {
  local signature="$1"
  python3 - "$TEST_MEMORY_FILE" "$signature" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
signature = sys.argv[2]
if not path.exists():
    print("0")
    raise SystemExit(0)
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("0")
    raise SystemExit(0)

for p in data.get("playbooks", []):
    if not isinstance(p, dict):
        continue
    if str(p.get("signature_id")) == signature and bool(p.get("auto_apply", True)):
        print("1")
        raise SystemExit(0)
print("0")
PY
}

count_signature_in_session() {
  local signature="$1"
  python3 - "$SESSION_EVENTS_FILE" "$signature" <<'PY'
import json
import sys
from pathlib import Path

events_file = Path(sys.argv[1])
signature = sys.argv[2]
count = 0
if events_file.exists():
    with events_file.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                e = json.loads(line)
            except Exception:
                continue
            if e.get("kind") == "case_failure" and str((e.get("data") or {}).get("signature")) == signature:
                count += 1
print(count)
PY
}

apply_playbook() {
  local signature="$1"
  local case_id="$2"
  local case_log="$3"

  record_event "fix_attempt" "$case_id" "running" "apply_playbook" "{\"signature\":\"$signature\"}"
  ((MEMORY_DELTA_PLAYBOOK_REUSED += 1))

  case "$signature" in
    timeout_or_slow_response)
      AGENT_BROWSER_WAIT_MS=1800
      echo "Playbook applied: increased AGENT_BROWSER_WAIT_MS to $AGENT_BROWSER_WAIT_MS" >>"$case_log"
      return 0
      ;;
    frontend_unreachable|navigation_failure)
      echo "Playbook applied: re-check frontend reachability" >>"$case_log"
      if verify_server_with_tool; then
        return 0
      fi
      return 1
      ;;
    auth_or_permission)
      echo "Playbook hint: check login flow and permissions before running core cases" >>"$case_log"
      return 0
      ;;
    selector_or_dom_changed)
      echo "Playbook hint: update selectors/interaction strategy in test-case definitions" >>"$case_log"
      return 0
      ;;
    *)
      echo "Playbook hint: generic investigation path executed" >>"$case_log"
      return 0
      ;;
  esac
}

resolve_test_file() {
  if [[ -n "$TEST_FILE" ]]; then
    [[ -f "$TEST_FILE" ]] || {
      echo -e "${RED}Error: test file not found: $TEST_FILE${NC}"
      exit 1
    }
    return 0
  fi

  local candidates=(
    "$PROJECT_ROOT/docs/product/$VERSION/qa/test-cases/${FEATURE}.md"
    "$PROJECT_ROOT/docs/product/test-cases/${FEATURE}.md"
    "$PROJECT_ROOT/docs/product/$VERSION/test-cases/${FEATURE}.md"
  )

  for path in "${candidates[@]}"; do
    if [[ -f "$path" ]]; then
      TEST_FILE="$path"
      return 0
    fi
  done

  echo -e "${RED}Error: no test case file found for feature '$FEATURE'${NC}"
  echo "Checked:"
  printf '  - %s\n' "${candidates[@]}"
  exit 1
}

wait_for_frontend() {
  local url="$1"
  local timeout="$2"

  if ! command_exists curl; then
    echo -e "${YELLOW}Warning: curl not found, skip frontend readiness check${NC}"
    return 0
  fi

  local elapsed=0
  while (( elapsed < timeout )); do
    if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
      echo -e "${GREEN}Frontend is ready: $url${NC}"
      return 0
    fi
    sleep 1
    ((elapsed += 1))
  done

  echo -e "${RED}Error: frontend is not ready within ${timeout}s: $url${NC}"
  return 1
}

start_frontend_if_needed() {
  if [[ "$START_FRONTEND" != true ]]; then
    echo -e "${CYAN}Skip frontend startup (--no-frontend-start)${NC}"
    return 0
  fi

  if [[ -z "$FRONTEND_CMD" ]]; then
    if [[ -n "$FRONTEND_URL" ]]; then
      echo -e "${CYAN}No frontend command provided, only checking existing URL...${NC}"
      wait_for_frontend "$FRONTEND_URL" "$FRONTEND_TIMEOUT"
    else
      echo -e "${CYAN}No frontend startup requested (no --frontend-cmd)${NC}"
    fi
    return 0
  fi

  echo -e "${CYAN}Starting frontend: ${FRONTEND_CMD}${NC}"
  local startup_log="$EVIDENCE_DIR/$VERSION/$FEATURE/frontend-startup.log"
  (
    cd "$FRONTEND_DIR"
    bash -lc "$FRONTEND_CMD"
  ) >"$startup_log" 2>&1 &

  FRONTEND_PID=$!
  echo -e "${CYAN}Frontend PID:${NC} $FRONTEND_PID"

  if [[ -n "$FRONTEND_URL" ]]; then
    wait_for_frontend "$FRONTEND_URL" "$FRONTEND_TIMEOUT"
  else
    sleep 3
  fi
}

verify_server_with_tool() {
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${CYAN}Skip server verification in dry-run mode${NC}"
    return 0
  fi

  if [[ "$CASE_PLAN_HAS_UI" != true ]]; then
    echo -e "${CYAN}Skip UI server verification (no UI cases in plan)${NC}"
    return 0
  fi

  local verify_log="$EVIDENCE_DIR/$VERSION/$FEATURE/server-check.log"
  : > "$verify_log"

  echo -e "${CYAN}Verifying server availability: ${BASE_URL}${NC}"

  if [[ "$SELECTED_TOOL" == "agent-browser" ]]; then
    if [[ "$BROWSER_HEADED" == true ]]; then
      agent-browser --headed open "$BASE_URL" >>"$verify_log" 2>&1 || return 1
      agent-browser --headed snapshot -i --json >>"$verify_log" 2>&1 || return 1
    else
      agent-browser open "$BASE_URL" >>"$verify_log" 2>&1 || return 1
      agent-browser snapshot -i --json >>"$verify_log" 2>&1 || return 1
    fi
    return 0
  fi

  if [[ "$SELECTED_TOOL" == "browser-use" ]]; then
    if command_exists browser-use; then
      browser-use open "$BASE_URL" >>"$verify_log" 2>&1 || return 1
      browser-use state >>"$verify_log" 2>&1 || return 1
    else
      npx -y browser-use open "$BASE_URL" >>"$verify_log" 2>&1 || return 1
      npx -y browser-use state >>"$verify_log" 2>&1 || return 1
    fi
    return 0
  fi

  return 1
}

cleanup() {
  if [[ -n "$FRONTEND_PID" ]] && kill -0 "$FRONTEND_PID" >/dev/null 2>&1; then
    echo -e "${CYAN}Stopping frontend process (PID=$FRONTEND_PID)${NC}"
    kill "$FRONTEND_PID" >/dev/null 2>&1 || true
    wait "$FRONTEND_PID" >/dev/null 2>&1 || true
  fi
}

show_known_pitfalls() {
  ensure_memory_file
  python3 - "$TEST_MEMORY_FILE" "$FEATURE" <<'PY'
import json, sys
from pathlib import Path

path = Path(sys.argv[1])
feature = sys.argv[2]
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("[WARN] 测试记忆文件损坏，已跳过读取")
    raise SystemExit(0)

signatures = data.get("signatures", [])
playbooks = {str(p.get("signature_id")): p for p in data.get("playbooks", []) if isinstance(p, dict)}

matched = []
for s in signatures:
    if not isinstance(s, dict):
        continue
    features = s.get("features") or []
    if feature in features or not features:
        matched.append(s)

matched = sorted(matched, key=lambda x: (x.get("count", 0), x.get("last_seen", "")), reverse=True)
matched = [m for m in matched if int(m.get("count", 0)) > 0][:5]

if not matched:
    print("暂无历史踩坑记录。")
    raise SystemExit(0)

print("历史踩坑提醒（最近 5 条）：")
for s in matched:
    sig = str(s.get("signature") or s.get("signature_id") or "unknown_failure")
    print(f"- [{sig}] x{s.get('count', 0)}")
    if s.get("suggestion"):
        print(f"  建议: {s.get('suggestion')}")
    pb = playbooks.get(str(s.get("signature_id") or sig))
    if pb and isinstance(pb.get("steps"), list) and pb["steps"]:
        print("  Playbook:")
        for step in pb["steps"][:2]:
            print(f"    - {step}")
PY
}

extract_case_ids() {
  local mode="$1"
  local regex=""

  case "$mode" in
    smoke)
      regex='^#{3,4}[[:space:]]*(SMK|SMOKE)-[A-Za-z0-9_-]+'
      ;;
    regression)
      regex='^#{3,4}[[:space:]]*TC-[A-Za-z0-9_-]+'
      ;;
    full)
      regex='^#{3,4}[[:space:]]*(SMK|SMOKE|TC)-[A-Za-z0-9_-]+'
      ;;
    *)
      echo -e "${RED}Unsupported test type: $mode${NC}"
      exit 1
      ;;
  esac

  grep -E "$regex" "$TEST_FILE" 2>/dev/null |
    sed -E 's/^#{3,4}[[:space:]]*([A-Za-z0-9_-]+).*/\1/' |
    awk '!seen[$0]++'
}

extract_case_block() {
  local case_id="$1"
  awk -v id="$case_id" '
    BEGIN { found=0 }
    $0 ~ "^#{3,4}[[:space:]]*" id "([[:space:]]*:|$)" { found=1; print; next }
    found && $0 ~ "^#{3,4}[[:space:]]*(SMK|SMOKE|TC)-" { exit }
    found { print }
  ' "$TEST_FILE"
}

join_base_and_path() {
  local base="$1"
  local path="$2"
  if [[ "$path" == "/" ]]; then
    echo "${base}/"
  else
    echo "${base}${path}"
  fi
}

resolve_case_target_url() {
  local case_id="$1"
  local block
  block="$(extract_case_block "$case_id")"

  local full_url
  full_url="$(printf '%s\n' "$block" | grep -Eo 'https?://[^ )|`"]+' | head -n1 || true)"
  if [[ -n "$full_url" ]]; then
    echo "$full_url"
    return 0
  fi

  local first_path
  first_path="$(printf '%s\n' "$block" | grep -Eo '/[A-Za-z0-9._~/%-]+' | grep -Ev '^/product-toolkit' | head -n1 || true)"
  if [[ -n "$first_path" ]]; then
    join_base_and_path "$BASE_URL" "$first_path"
    return 0
  fi

  echo "$BASE_URL"
}

classify_failure_signature() {
  local log_file="$1"

  if grep -Eiq 'ECONNREFUSED|ERR_CONNECTION_REFUSED|connection refused|Failed to fetch' "$log_file"; then
    echo "frontend_unreachable|前端不可达：检查 --frontend-cmd 与 --frontend-url，确认项目已启动"
    return
  fi

  if grep -Eiq 'page\.goto:|net::ERR_|navigating to' "$log_file"; then
    echo "navigation_failure|页面导航失败：检查目标 URL、路由映射与前端服务可用性"
    return
  fi

  if grep -Eiq 'timeout|timed out|TimeoutError' "$log_file"; then
    echo "timeout_or_slow_response|超时：提高 --frontend-timeout，或优化页面首屏/接口性能"
    return
  fi

  if grep -Eiq 'selector|element not found|No node found|locator' "$log_file"; then
    echo "selector_or_dom_changed|元素定位失败：更新测试步骤中的选择器或页面定位策略"
    return
  fi

  if grep -Eiq '401|403|unauthorized|forbidden|auth' "$log_file"; then
    echo "auth_or_permission|权限/认证失败：确认测试账号权限与登录态初始化流程"
    return
  fi

  if grep -Eiq '500|Internal Server Error|server error' "$log_file"; then
    echo "backend_internal_error|后端错误：先检查关键 API 健康状态与错误日志"
    return
  fi

  echo "unknown_failure|未知失败：查看证据日志并补充可复用修复建议"
}

upsert_test_memory() {
  local case_id="$1"
  local status="$2"
  local log_file="$3"

  [[ "$status" == "failed" ]] || return 0

  local classified
  classified="$(classify_failure_signature "$log_file")"
  local signature suggestion
  signature="${classified%%|*}"
  suggestion="${classified#*|}"
  local snippet
  snippet="$(tail -n 20 "$log_file" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | cut -c1-280)"

  local delta_json
  delta_json="$(python3 - "$TEST_MEMORY_FILE" "$FEATURE" "$VERSION" "$TEST_TYPE" "$case_id" "$SELECTED_TOOL" "$signature" "$suggestion" "$snippet" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

(path, feature, version, test_type, case_id, tool, signature, suggestion, snippet) = sys.argv[1:]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

p = Path(path)
if p.exists():
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}
else:
    data = {}

if data.get("version") != "2.0":
    data = {
        "version": "2.0",
        "updated_at": now,
        "signatures": [],
        "playbooks": [],
        "sessions": [],
        "pitfalls": data.get("pitfalls", []) if isinstance(data.get("pitfalls"), list) else [],
    }

signatures = data.setdefault("signatures", [])
pitfalls = data.setdefault("pitfalls", [])

new_signature = False
updated_signature = False

sig_match = None
for s in signatures:
    if not isinstance(s, dict):
        continue
    if str(s.get("signature_id") or s.get("signature")) == signature:
        sig_match = s
        break

if sig_match is None:
    sig_match = {
        "signature_id": signature,
        "signature": signature,
        "category": "test_failure_pattern",
        "suggestion": suggestion,
        "count": 0,
        "first_seen": now,
        "last_seen": now,
        "features": [],
        "test_cases": [],
        "last_snippet": "",
    }
    signatures.append(sig_match)
    new_signature = True

sig_match["count"] = int(sig_match.get("count", 0)) + 1
sig_match["last_seen"] = now
sig_match["suggestion"] = suggestion
sig_match["last_snippet"] = snippet
features = set(sig_match.get("features") or [])
features.add(feature)
sig_match["features"] = sorted([f for f in features if f])
cases = set(sig_match.get("test_cases") or [])
cases.add(case_id)
sig_match["test_cases"] = sorted([c for c in cases if c])
if not new_signature:
    updated_signature = True

pitfall_match = None
for item in pitfalls:
    if (
        isinstance(item, dict)
        and item.get("feature") == feature
        and item.get("test_case") == case_id
        and item.get("signature") == signature
    ):
        pitfall_match = item
        break

if pitfall_match:
    pitfall_match["count"] = int(pitfall_match.get("count", 1)) + 1
    pitfall_match["last_seen"] = now
    pitfall_match["version"] = version
    pitfall_match["tool"] = tool
    pitfall_match["test_type"] = test_type
    pitfall_match["suggestion"] = suggestion
    pitfall_match["snippet"] = snippet
else:
    pitfalls.append(
        {
            "feature": feature,
            "version": version,
            "test_type": test_type,
            "test_case": case_id,
            "tool": tool,
            "signature": signature,
            "suggestion": suggestion,
            "snippet": snippet,
            "count": 1,
            "first_seen": now,
            "last_seen": now,
        }
    )

pitfalls.sort(key=lambda x: x.get("last_seen", ""), reverse=True)
signatures.sort(key=lambda x: x.get("last_seen", ""), reverse=True)

data["pitfalls"] = pitfalls[:500]
data["signatures"] = signatures[:500]
data["updated_at"] = now

p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

print(json.dumps({
    "signature": signature,
    "suggestion": suggestion,
    "new_signature": new_signature,
    "updated_signature": updated_signature
}, ensure_ascii=False))
PY
)"

  if [[ -n "$delta_json" ]]; then
    if python3 - "$delta_json" <<'PY'
import json,sys
d=json.loads(sys.argv[1])
raise SystemExit(0 if d.get("new_signature") else 1)
PY
    then
      ((MEMORY_DELTA_NEW_SIGNATURES += 1))
    fi
    if python3 - "$delta_json" <<'PY'
import json,sys
d=json.loads(sys.argv[1])
raise SystemExit(0 if d.get("updated_signature") else 1)
PY
    then
      ((MEMORY_DELTA_UPDATED_SIGNATURES += 1))
    fi
  fi

  record_event "case_failure" "$case_id" "failed" "$suggestion" "{\"signature\":\"$signature\",\"log_file\":\"$log_file\"}"
}

update_playbook_outcome() {
  local signature="$1"
  local outcome="$2" # success|fail
  python3 - "$TEST_MEMORY_FILE" "$signature" "$outcome" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
signature = sys.argv[2]
outcome = sys.argv[3]
now = sys.argv[4]

if not path.exists():
    raise SystemExit(0)
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

changed = False
for pb in data.get("playbooks", []):
    if not isinstance(pb, dict):
        continue
    if str(pb.get("signature_id") or "") != signature:
        continue
    if outcome == "success":
        pb["success_count"] = int(pb.get("success_count", 0)) + 1
    else:
        pb["fail_count"] = int(pb.get("fail_count", 0)) + 1
    s = int(pb.get("success_count", 0))
    f = int(pb.get("fail_count", 0))
    total = s + f
    pb["confidence"] = round((s / total), 4) if total else 0.2
    pb["last_used"] = now
    changed = True
    break

if changed:
    data["updated_at"] = now
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

run_agent_browser_cmd() {
  local case_log="$1"
  shift
  local -a cmd=(agent-browser)
  if [[ "$BROWSER_HEADED" == true ]]; then
    cmd+=(--headed)
  fi
  cmd+=("$@")
  "${cmd[@]}" >>"$case_log" 2>&1
}

run_agent_browser_case() {
  local case_id="$1"
  local target_url="$2"
  local case_log="$3"
  local safe_case="$4"
  local iteration="$5"

  # Alignment with compound-engineering test-browser guidance:
  # open -> snapshot -> screenshot -> errors (CLI-first verification loop)
  local screenshot_path="$EVIDENCE_DIR/$VERSION/$FEATURE/screenshots/${safe_case}-iter${iteration}.png"
  local snapshot_json="$EVIDENCE_DIR/$VERSION/$FEATURE/snapshot-${safe_case}-iter${iteration}.json"
  local errors_log="$EVIDENCE_DIR/$VERSION/$FEATURE/errors-${safe_case}-iter${iteration}.log"

  run_agent_browser_cmd "$case_log" errors --clear || true
  run_agent_browser_cmd "$case_log" open "$target_url" || return 1

  if [[ "$AGENT_BROWSER_WAIT_MS" =~ ^[0-9]+$ ]] && (( AGENT_BROWSER_WAIT_MS > 0 )); then
    run_agent_browser_cmd "$case_log" wait "$AGENT_BROWSER_WAIT_MS" || true
  fi

  if [[ "$BROWSER_HEADED" == true ]]; then
    agent-browser --headed snapshot -i --json >"$snapshot_json" 2>>"$case_log" || return 1
  else
    agent-browser snapshot -i --json >"$snapshot_json" 2>>"$case_log" || return 1
  fi

  python3 - "$snapshot_json" >>"$case_log" 2>&1 <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
data = json.loads(p.read_text(encoding="utf-8"))
if not data.get("success", True):
    print("snapshot failed:", data.get("error"))
    raise SystemExit(1)
refs = (data.get("data") or {}).get("refs") or {}
print(f"snapshot refs: {len(refs)}")
PY

  run_agent_browser_cmd "$case_log" screenshot "$screenshot_path" || true
  run_agent_browser_cmd "$case_log" errors >"$errors_log" 2>&1 || true

  if grep -Eiq 'ERR_CONNECTION|ReferenceError|TypeError|SyntaxError|Unhandled|Failed to load resource|net::ERR_|status of 5[0-9]{2}' "$errors_log"; then
    echo "Detected critical browser errors in $errors_log" >>"$case_log"
    return 1
  fi

  return 0
}

run_browser_use_case() {
  local case_id="$1"
  local target_url="$2"
  local case_log="$3"
  local safe_case="$4"
  local iteration="$5"

  local screenshot_path="$EVIDENCE_DIR/$VERSION/$FEATURE/screenshots/${safe_case}-iter${iteration}.png"
  local state_file="$EVIDENCE_DIR/$VERSION/$FEATURE/state-${safe_case}-iter${iteration}.txt"

  local -a bu
  if command_exists browser-use; then
    bu=(browser-use)
  else
    bu=(npx -y browser-use)
  fi

  if [[ "$BROWSER_HEADED" == true ]]; then
    bu+=(--headed)
  fi

  "${bu[@]}" open "$target_url" >>"$case_log" 2>&1 || return 1
  "${bu[@]}" state >"$state_file" 2>>"$case_log" || return 1
  "${bu[@]}" screenshot "$screenshot_path" >>"$case_log" 2>&1 || true
  return 0
}

run_with_tool() {
  local case_id="$1"
  local target_url="$2"
  local case_log="$3"
  local safe_case="$4"
  local iteration="$5"

  case "$SELECTED_TOOL" in
    agent-browser)
      run_agent_browser_case "$case_id" "$target_url" "$case_log" "$safe_case" "$iteration"
      ;;
    browser-use)
      run_browser_use_case "$case_id" "$target_url" "$case_log" "$safe_case" "$iteration"
      ;;
    *)
      echo "Unsupported tool: $SELECTED_TOOL" >"$case_log"
      return 1
      ;;
  esac
}

case_supported_by_tool() {
  local execution_mode="$1"
  local tool="$2"
  local mode_csv
  mode_csv="$(echo "${execution_mode:-}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  [[ -z "$mode_csv" ]] && mode_csv="agent-browser"
  [[ ",${mode_csv}," == *",${tool},"* ]]
}

mode_has_tag() {
  local mode_csv="$1"
  local tag="$2"
  [[ ",${mode_csv}," == *",${tag},"* ]]
}

run_single_case() {
  local case_id="$1"
  local us_id="$2"
  local target_hint="$3"
  local iteration="$4"
  local execution_mode="${5:-agent-browser}"
  local method_hint="${6:-}"
  local expectation_hint="${7:-success}"

  local safe_case
  safe_case="$(sanitize_name "$case_id")"
  local case_log="$EVIDENCE_DIR/$VERSION/$FEATURE/${safe_case}-iter${iteration}.log"
  local mode_norm
  mode_norm="$(echo "${execution_mode:-agent-browser}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  [[ -z "$mode_norm" ]] && mode_norm="agent-browser"

  local requires_ui=0
  local requires_api=0
  local requires_manual=0
  if mode_has_tag "$mode_norm" "agent-browser" || mode_has_tag "$mode_norm" "browser-use"; then
    requires_ui=1
  fi
  mode_has_tag "$mode_norm" "api" && requires_api=1
  mode_has_tag "$mode_norm" "manual" && requires_manual=1
  if (( requires_ui == 0 && requires_api == 0 && requires_manual == 0 )); then
    requires_ui=1
    mode_norm="$SELECTED_TOOL"
    execution_mode="$SELECTED_TOOL"
  fi

  local target_url
  if [[ -n "$target_hint" ]]; then
    target_url="$(resolve_target_url_from_hint "$target_hint")"
  else
    target_url="$(resolve_case_target_url "$case_id")"
  fi
  if (( requires_api == 1 && requires_ui == 0 )); then
    local api_pair api_url
    api_pair="$(resolve_api_target_url "$target_hint")"
    api_url="${api_pair%%$'\x1f'*}"
    [[ -n "$api_url" ]] && target_url="$api_url"
  fi

  echo -e "${CYAN}Running case:${NC} $case_id [${us_id}] (iteration ${iteration}/${MAX_ITERATIONS})"
  echo -e "${CYAN}Execution Mode:${NC} ${execution_mode}"
  echo -e "${CYAN}Target URL:${NC} $target_url"
  [[ -n "$method_hint" ]] && echo -e "${CYAN}Method Hint:${NC} $method_hint"
  [[ -n "$expectation_hint" ]] && echo -e "${CYAN}Expectation Hint:${NC} $expectation_hint"
  record_event "case_start" "$case_id" "running" "case start" "{\"us_id\":\"$us_id\",\"target_url\":\"$target_url\",\"iteration\":$iteration,\"execution_mode\":\"$execution_mode\",\"method_hint\":\"$method_hint\",\"expectation_hint\":\"$expectation_hint\"}"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Tool=$SELECTED_TOOL Case=$case_id URL=$target_url" | tee "$case_log"
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$target_url" "passed" "dry-run" "$us_id" "$execution_mode" >>"$RESULTS_FILE"
    record_event "case_end" "$case_id" "passed" "dry-run passed" "{\"us_id\":\"$us_id\"}"
    return 0
  fi

  local -a detail_notes=()

  # Step 1: UI validation when required
  if (( requires_ui == 1 )); then
    if run_with_tool "$case_id" "$target_url" "$case_log" "$safe_case" "$iteration"; then
      detail_notes+=("ui_ok")
    else
      local classified signature suggestion
      classified="$(classify_failure_signature "$case_log")"
      signature="${classified%%|*}"
      suggestion="${classified#*|}"

      echo -e "${RED}✗ ${case_id} FAILED${NC} (${signature})"
      upsert_test_memory "$case_id" "failed" "$case_log"

      # Try to reuse known playbook once before declaring fail/blocked
      local replayed=0
      local replay_recovered=0
      if [[ "$(playbook_exists_for_signature "$signature")" == "1" ]]; then
        replayed=1
        if apply_playbook "$signature" "$case_id" "$case_log"; then
          if run_with_tool "$case_id" "$target_url" "$case_log" "$safe_case" "$iteration"; then
            replay_recovered=1
            update_playbook_outcome "$signature" "success"
          else
            update_playbook_outcome "$signature" "fail"
          fi
        else
          update_playbook_outcome "$signature" "fail"
        fi
      fi

      if (( replay_recovered == 1 )); then
        detail_notes+=("recovered_by_playbook:${signature}")
      else
        local sig_count
        sig_count="$(count_signature_in_session "$signature")"
        local status="failed"
        local note="see ${safe_case}-iter${iteration}.log"
        if [[ "$sig_count" =~ ^[0-9]+$ ]] && (( sig_count >= SESSION_REPEAT_GUARD_THRESHOLD )); then
          status="blocked"
          note="repeat_signature_guard:${signature}"
          ((MEMORY_DELTA_REPEAT_GUARD += 1))
          record_event "repeat_guard" "$case_id" "blocked" "same signature repeated in session" "{\"signature\":\"$signature\",\"count\":$sig_count}"
        fi
        printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$target_url" "$status" "$note" "$us_id" "$execution_mode" >>"$RESULTS_FILE"
        record_event "case_end" "$case_id" "$status" "$suggestion" "{\"us_id\":\"$us_id\",\"signature\":\"$signature\",\"playbook_replayed\":$replayed}"
        if [[ "$status" == "blocked" ]]; then
          return 2
        fi
        return 1
      fi
    fi
  fi

  # Step 2: API validation when required
  local aggregate_status="passed"
  if (( requires_api == 1 )); then
    if run_api_case "$case_id" "$target_hint" "$method_hint" "$expectation_hint" "$case_log" "$safe_case" "$iteration"; then
      detail_notes+=("${API_LAST_NOTE:-api_ok}")
    else
      local api_rc=$?
      local api_note="${API_LAST_NOTE:-api_validation_failed}"
      if (( api_rc == 2 )); then
        [[ "$aggregate_status" != "failed" ]] && aggregate_status="blocked"
        detail_notes+=("$api_note")
      else
        aggregate_status="failed"
        detail_notes+=("$api_note")
      fi
    fi
  fi

  # Step 3: Manual validation via structured result file
  if (( requires_manual == 1 )); then
    local manual_pair manual_status manual_note manual_evidence
    manual_pair="$(lookup_manual_case_result "$case_id")"
    manual_status="${manual_pair%%$'\x1f'*}"
    local manual_rest="${manual_pair#*$'\x1f'}"
    manual_note="${manual_rest%%$'\x1f'*}"
    manual_evidence="${manual_rest#*$'\x1f'}"

    case "$manual_status" in
      passed)
        if [[ -n "$manual_note" ]]; then
          detail_notes+=("manual_passed:${manual_note}")
        else
          detail_notes+=("manual_passed")
        fi
        ;;
      failed)
        aggregate_status="failed"
        detail_notes+=("manual_failed:${manual_note:-no_note}")
        ;;
      blocked)
        [[ "$aggregate_status" != "failed" ]] && aggregate_status="blocked"
        detail_notes+=("manual_blocked:${manual_note:-no_note}")
        ;;
      pending|"")
        [[ "$aggregate_status" != "failed" ]] && aggregate_status="blocked"
        detail_notes+=("manual_result_missing")
        ;;
      *)
        [[ "$aggregate_status" != "failed" ]] && aggregate_status="blocked"
        detail_notes+=("manual_status_invalid:${manual_status}")
        ;;
    esac
    [[ -n "$manual_evidence" ]] && detail_notes+=("manual_evidence:${manual_evidence}")
  fi

  local final_note="ok"
  if (( ${#detail_notes[@]} > 0 )); then
    final_note="$(IFS=';'; echo "${detail_notes[*]}")"
  fi

  if [[ "$aggregate_status" == "passed" ]]; then
    echo -e "${GREEN}✓ ${case_id} PASSED${NC}"
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$target_url" "passed" "$final_note" "$us_id" "$execution_mode" >>"$RESULTS_FILE"
    record_event "case_end" "$case_id" "passed" "$final_note" "{\"us_id\":\"$us_id\"}"
    return 0
  fi

  if [[ "$aggregate_status" == "blocked" ]]; then
    echo -e "${YELLOW}⚠ ${case_id} BLOCKED${NC} (${final_note})"
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$target_url" "blocked" "$final_note" "$us_id" "$execution_mode" >>"$RESULTS_FILE"
    record_event "case_end" "$case_id" "blocked" "$final_note" "{\"us_id\":\"$us_id\"}"
    return 2
  fi

  echo -e "${RED}✗ ${case_id} FAILED${NC} (${final_note})"
  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$target_url" "failed" "$final_note" "$us_id" "$execution_mode" >>"$RESULTS_FILE"
  record_event "case_end" "$case_id" "failed" "$final_note" "{\"us_id\":\"$us_id\"}"
  return 1
}

LAST_BATCH_PASSED=0
LAST_BATCH_FAILED=0
LAST_BATCH_BLOCKED=0

run_case_batch() {
  local iteration="$1"
  LAST_BATCH_PASSED=0
  LAST_BATCH_FAILED=0
  LAST_BATCH_BLOCKED=0

  local strict_check
  strict_check="$(python3 - "$CASE_PLAN_FILE" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
if not p.exists():
    print("0\tmissing_case_plan")
    raise SystemExit(0)

try:
    d = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    print("0\tinvalid_case_plan_json")
    raise SystemExit(0)

strict = d.get("strict") or {}
mode = str(d.get("mode") or "")
if mode == "full" and strict and strict.get("declared_vs_parsed_match") is False:
    mismatches = strict.get("mismatched_us") or []
    if strict.get("suspicious_one_to_one"):
        reason = "suspicious_one_to_one_us_tc_mapping"
    else:
        reason = f"declared_vs_parsed_mismatch(us={len(mismatches)})"
    print(f"0\t{reason}")
else:
    print("1\tok")
PY
)"
  local strict_ok strict_reason
  strict_ok="${strict_check%%$'\t'*}"
  strict_reason="${strict_check#*$'\t'}"
  if [[ "$strict_ok" != "1" ]]; then
    echo -e "${RED}Error: strict case-plan guard failed (${strict_reason})${NC}"
    LAST_BATCH_BLOCKED=1
    record_event "batch_blocked" "" "blocked" "strict case-plan guard failed" "{\"reason\":\"$strict_reason\"}"
    return 1
  fi

  local has_cases
  has_cases="$(python3 - "$CASE_PLAN_FILE" <<'PY'
import json,sys
from pathlib import Path
p=Path(sys.argv[1])
if not p.exists():
    print(0); raise SystemExit(0)
try:
    d=json.loads(p.read_text(encoding='utf-8'))
except Exception:
    print(0); raise SystemExit(0)
print(len(d.get("cases",[])))
PY
)"
  if ! [[ "$has_cases" =~ ^[0-9]+$ ]] || (( has_cases == 0 )); then
    echo -e "${RED}Error: no test cases found for type '$TEST_TYPE' in $TEST_FILE (strict mode)${NC}"
    LAST_BATCH_BLOCKED=1
    record_event "batch_blocked" "" "blocked" "no cases parsed in strict mode" "{\"test_type\":\"$TEST_TYPE\",\"test_file\":\"$TEST_FILE\"}"
    return 1
  fi

  while IFS=$'\x1f' read -r order us_id case_id target_hint execution_mode method_hint expectation_hint; do
    [[ -z "$case_id" ]] && continue
    local rc=0
    if run_single_case "$case_id" "$us_id" "$target_hint" "$iteration" "$execution_mode" "$method_hint" "$expectation_hint"; then
      ((LAST_BATCH_PASSED += 1))
    else
      rc=$?
      if (( rc == 2 )); then
        ((LAST_BATCH_BLOCKED += 1))
      else
        ((LAST_BATCH_FAILED += 1))
      fi
    fi
  done < <(python3 - "$CASE_PLAN_FILE" <<'PY'
import json,sys
from pathlib import Path
p=Path(sys.argv[1])
try:
    d=json.loads(p.read_text(encoding='utf-8'))
except Exception:
    raise SystemExit(0)
for c in d.get("cases", []):
    cols = [
        str(c.get('order','')),
        str(c.get('us_id','UNKNOWN')),
        str(c.get('case_id','')),
        str(c.get('target_hint','')),
        str(c.get('execution_mode','agent-browser')),
        str(c.get('method_hint','')),
        str(c.get('expectation_hint','')),
    ]
    print("\x1f".join(cols))
PY
)

  echo
  echo "Batch Result: ${LAST_BATCH_PASSED} passed, ${LAST_BATCH_FAILED} failed, ${LAST_BATCH_BLOCKED} blocked"

  [[ $LAST_BATCH_FAILED -eq 0 && $LAST_BATCH_BLOCKED -eq 0 ]]
}

update_test_progress() {
  local status="$1"
  local passed="$2"
  local failed="$3"
  local blocked="$4"

  local progress_file="$STATE_DIR/test-progress.json"
  local now
  now="$(iso_now)"

  python3 - "$progress_file" "$VERSION" "$FEATURE" "$status" "$passed" "$failed" "$blocked" "$TEST_TYPE" "$SELECTED_TOOL" "$now" "$SESSION_ID" "$SESSION_FILE" <<'PY'
import json, sys
from pathlib import Path

(progress_file, version, feature, status, passed, failed, blocked, test_type, tool, now, session_id, session_file) = sys.argv[1:]
passed = int(passed)
failed = int(failed)
blocked = int(blocked)

p = Path(progress_file)
if p.exists():
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        data = {"schema_version": "2.0", "project": "product-toolkit", "versions": [], "updated_at": now}
else:
    data = {"schema_version": "2.0", "project": "product-toolkit", "versions": [], "updated_at": now}

versions = data.setdefault("versions", [])
version_obj = next((v for v in versions if v.get("version") == version), None)
if version_obj is None:
    version_obj = {"version": version, "features": []}
    versions.append(version_obj)

features = version_obj.setdefault("features", [])
feature_obj = next((f for f in features if f.get("feature") == feature), None)
if feature_obj is None:
    feature_obj = {
        "feature": feature,
        "last_session_id": session_id,
        "coverage": {},
        "gaps": {},
        "runs": []
    }
    features.append(feature_obj)

coverage = {}
gaps = {}
strict_data = {}
sf = Path(session_file)
if sf.exists():
    try:
        session_data = json.loads(sf.read_text(encoding="utf-8"))
        coverage = session_data.get("coverage", {}) or {}
        gaps = session_data.get("gaps", {}) or {}
        strict_data = session_data.get("strict", {}) or {}
    except Exception:
        pass

feature_obj["last_session_id"] = session_id
feature_obj["coverage"] = coverage
feature_obj["gaps"] = gaps
feature_obj["strict"] = strict_data
feature_obj.setdefault("runs", []).append({
    "session_id": session_id,
    "status": status,
    "passed": passed,
    "failed": failed,
    "blocked": blocked,
    "test_type": test_type,
    "tool": tool,
    "timestamp": now,
})

runs = feature_obj["runs"]
feature_obj["summary"] = {
    "total_runs": len(runs),
    "passed_runs": sum(1 for r in runs if r.get("status") == "passed"),
    "failed_runs": sum(1 for r in runs if r.get("status") == "failed"),
    "blocked_runs": sum(1 for r in runs if r.get("status") == "blocked"),
    "updated_at": now,
}
version_obj["summary"] = {
    "feature_count": len(features),
    "updated_at": now,
}

data["updated_at"] = now

p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
PY

  echo -e "${CYAN}Test progress updated:${NC} $progress_file"
}

stop_test_session() {
  local final_status="$1"
  local passed="$2"
  local failed="$3"
  local blocked="$4"

  SESSION_STOPPED_AT="$(iso_now)"
  SESSION_STATUS="$final_status"
  record_event "session_stop" "" "$final_status" "session stop" "{\"passed\":$passed,\"failed\":$failed,\"blocked\":$blocked}"

  python3 - "$SESSION_FILE" "$SESSION_ID" "$SESSION_STARTED_AT" "$SESSION_STOPPED_AT" "$final_status" "$VERSION" "$FEATURE" "$TEST_TYPE" "$SELECTED_TOOL" "$BASE_URL" "$SESSION_PLAN_FILE" "$SESSION_EVENTS_FILE" "$RESULTS_FILE" "$MEMORY_DELTA_NEW_SIGNATURES" "$MEMORY_DELTA_UPDATED_SIGNATURES" "$MEMORY_DELTA_PLAYBOOK_REUSED" "$MEMORY_DELTA_REPEAT_GUARD" <<'PY'
import json
import sys
from pathlib import Path

(
    session_file, session_id, started_at, stopped_at, final_status, version, feature, test_type, tool, base_url,
    plan_file, events_file, results_file,
    delta_new_sig, delta_updated_sig, delta_playbook_reused, delta_repeat_guard
) = sys.argv[1:]

plan = {}
events = []
results_rows = []

pf = Path(plan_file)
if pf.exists():
    try:
        plan = json.loads(pf.read_text(encoding="utf-8"))
    except Exception:
        plan = {}

ef = Path(events_file)
if ef.exists():
    for line in ef.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except Exception:
            pass

rf = Path(results_file)
if rf.exists():
    for line in rf.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) < 5:
            continue
        case_id, url, status, note, us_id = parts[:5]
        execution_mode = parts[5] if len(parts) >= 6 else "agent-browser"
        results_rows.append({
            "case_id": case_id,
            "url": url,
            "status": status,
            "note": note,
            "us_id": us_id,
            "execution_mode": execution_mode,
        })

latest_case = {}
for row in results_rows:
    latest_case[row["case_id"]] = row

cases = plan.get("cases", []) if isinstance(plan.get("cases"), list) else []
all_us = plan.get("all_us", []) if isinstance(plan.get("all_us"), list) else []
plan_gaps = plan.get("gaps", {}) if isinstance(plan.get("gaps"), dict) else {}
plan_strict = plan.get("strict", {}) if isinstance(plan.get("strict"), dict) else {}
declared_counts = plan.get("declared_counts", {}) if isinstance(plan.get("declared_counts"), dict) else {}
declared_total_cases = declared_counts.get("total_cases")
declared_us_case_counts = declared_counts.get("us_case_counts", {}) if isinstance(declared_counts.get("us_case_counts"), dict) else {}

def normalize_mode(mode_value: str) -> str:
    if mode_value is None:
        return "agent-browser"
    parts = [x.strip().lower() for x in str(mode_value).split(",") if x.strip()]
    if not parts:
        return "agent-browser"
    return ",".join(sorted(dict.fromkeys(parts)))

def parse_mode_tags(mode_value: str):
    parts = [x.strip().lower() for x in str(mode_value or "").split(",") if x.strip()]
    if not parts:
        return ["agent-browser"]
    return list(dict.fromkeys(parts))

known_mode_tags = {"agent-browser", "browser-use", "manual", "api"}
ui_mode_tags = {"agent-browser", "browser-use"}

case_meta = {}
for c in cases:
    cid = str(c.get("case_id") or "")
    if not cid:
        continue
    if cid not in case_meta:
        case_meta[cid] = c

tc_total = len(cases)
tc_executed = sum(1 for c in cases if str(c.get("case_id")) in latest_case)
tc_passed = sum(1 for c in cases if latest_case.get(str(c.get("case_id")), {}).get("status") == "passed")
tc_failed = sum(1 for c in cases if latest_case.get(str(c.get("case_id")), {}).get("status") == "failed")
tc_blocked = sum(1 for c in cases if latest_case.get(str(c.get("case_id")), {}).get("status") == "blocked")

us_to_cases = {}
for c in cases:
    us = c.get("us_id", "UNKNOWN")
    us_to_cases.setdefault(us, []).append(c)

us_total = len([u for u in all_us if u]) if all_us else len([u for u in us_to_cases.keys() if u != "UNKNOWN"])
us_executed = 0
us_passed = 0
coverage_by_us = []

ordered_us = [u for u in all_us if u]
for us in sorted(us_to_cases.keys()):
    if us and us not in ordered_us:
        ordered_us.append(us)

for us in ordered_us:
    case_objs = us_to_cases.get(us, [])
    cid_list = [str(c.get("case_id") or "") for c in case_objs if c.get("case_id")]
    if us == "UNKNOWN":
        declared_count = 0
    else:
        declared_count = int(declared_us_case_counts.get(us, 0)) if isinstance(declared_us_case_counts, dict) else 0
    statuses = [latest_case.get(cid, {}).get("status", "pending") for cid in cid_list if cid]
    if any(s != "pending" for s in statuses):
        if us != "UNKNOWN":
            us_executed += 1
    if statuses and all(s == "passed" for s in statuses):
        if us != "UNKNOWN":
            us_passed += 1

    passed_count = sum(1 for s in statuses if s == "passed")
    failed_count = sum(1 for s in statuses if s == "failed")
    blocked_count = sum(1 for s in statuses if s == "blocked")
    pending_cases = [cid for cid in cid_list if latest_case.get(cid, {}).get("status", "pending") == "pending"]

    coverage_by_us.append({
        "us_id": us,
        "declared_total": declared_count,
        "expected": len(cid_list),
        "executed": len(cid_list) - len(pending_cases),
        "passed": passed_count,
        "failed": failed_count,
        "blocked": blocked_count,
        "pending": len(pending_cases),
        "pending_cases": pending_cases,
    })

all_ac = set()
covered_ac = set()
for c in cases:
    acs = [str(x).upper() for x in (c.get("ac_ids") or [])]
    cid = c.get("case_id")
    all_ac.update(acs)
    if cid in latest_case and latest_case[cid].get("status") in {"passed", "failed", "blocked"}:
        covered_ac.update(acs)

mode_expected = {}
mode_results = {}
for c in cases:
    cid = str(c.get("case_id") or "")
    mode_key = normalize_mode(c.get("execution_mode") or "agent-browser")
    mode_expected[mode_key] = mode_expected.get(mode_key, 0) + 1
    mode_results.setdefault(mode_key, {"expected": 0, "executed": 0, "passed": 0, "failed": 0, "blocked": 0})
    mode_results[mode_key]["expected"] += 1
    row = latest_case.get(cid)
    if row:
        mode_results[mode_key]["executed"] += 1
        status = row.get("status")
        if status in {"passed", "failed", "blocked"}:
            mode_results[mode_key][status] += 1

coverage_by_mode = []
for mode_key in sorted(mode_results.keys()):
    item = {"mode": mode_key}
    item.update(mode_results[mode_key])
    coverage_by_mode.append(item)

unexecuted_test_cases = [c.get("case_id") for c in cases if c.get("case_id") not in latest_case]
failed_test_cases = [c.get("case_id") for c in cases if latest_case.get(c.get("case_id"), {}).get("status") == "failed"]
blocked_test_cases = [c.get("case_id") for c in cases if latest_case.get(c.get("case_id"), {}).get("status") == "blocked"]
blocked_reason_counts = {}
for c in cases:
    cid = c.get("case_id")
    row = latest_case.get(cid, {})
    if row.get("status") != "blocked":
        continue
    note = str(row.get("note") or "").strip()
    tokens = [t.strip() for t in note.split(";") if t.strip()]
    if not tokens:
        blocked_reason_counts["blocked_unknown"] = blocked_reason_counts.get("blocked_unknown", 0) + 1
        continue
    for t in tokens:
        key = t.split(":", 1)[0]
        blocked_reason_counts[key] = blocked_reason_counts.get(key, 0) + 1

blocked_reason_codes = []
for key in sorted(blocked_reason_counts.keys()):
    if key and key not in blocked_reason_codes:
        blocked_reason_codes.append(key)

for event in events:
    kind = str(event.get("kind") or "")
    msg = str(event.get("message") or "")
    data = event.get("data", {}) if isinstance(event.get("data"), dict) else {}
    if kind == "repeat_guard" and "repeat_guard" not in blocked_reason_codes:
        blocked_reason_codes.append("repeat_guard")
    if kind == "batch_blocked":
        reason = str(data.get("reason") or "")
        if "strict case-plan guard failed" in msg:
            code = "strict_case_plan_guard_failed"
        elif "no cases parsed in strict mode" in msg:
            code = "strict_no_cases_parsed"
        elif reason:
            code = f"strict_case_plan_guard_failed:{reason}"
        else:
            code = "batch_blocked_unknown"
        if code not in blocked_reason_codes:
            blocked_reason_codes.append(code)

non_automatable_all = []
for c in cases:
    cid = c.get("case_id")
    tags = set(parse_mode_tags(c.get("execution_mode") or "agent-browser"))
    unknown_tags = sorted(t for t in tags if t not in known_mode_tags)
    if unknown_tags:
        non_automatable_all.append(cid)
        continue
    if tags & ui_mode_tags and tool not in ui_mode_tags:
        non_automatable_all.append(cid)

non_automatable_test_cases = []
for cid in non_automatable_all:
    status = latest_case.get(cid, {}).get("status", "pending")
    if status in {"blocked", "pending"}:
        non_automatable_test_cases.append(cid)
declared_mismatches = plan_strict.get("mismatched_us") if isinstance(plan_strict.get("mismatched_us"), list) else []

gaps = {
    "missing_user_stories": plan_gaps.get("missing_user_story_mapping", []),
    "missing_test_cases": plan_gaps.get("missing_test_cases", []),
    "unexecuted_test_cases": unexecuted_test_cases,
    "failed_test_cases": failed_test_cases,
    "blocked_test_cases": blocked_test_cases,
    "blocked_reason_counts": blocked_reason_counts,
    "blocked_reason_codes": blocked_reason_codes,
    "non_automatable_test_cases": non_automatable_test_cases,
    "declared_count_mismatches": declared_mismatches,
}

if final_status == "blocked" and not gaps.get("blocked_reason_codes"):
    gaps["blocked_reason_codes"] = ["blocked_unknown"]

us_completeness_passed = all(
    (item.get("pending", 0) == 0 and item.get("failed", 0) == 0 and item.get("blocked", 0) == 0)
    for item in coverage_by_us
    if item.get("us_id") != "UNKNOWN"
)

declared_match = bool(plan_strict.get("declared_vs_parsed_match", True))
has_structural_gaps = any([
    bool(gaps.get("missing_user_stories")),
    bool(gaps.get("missing_test_cases")),
    bool(gaps.get("unexecuted_test_cases")),
    bool(gaps.get("declared_count_mismatches")),
])

strict = {
    "declared_vs_parsed_match": declared_match,
    "declared_total_cases": declared_total_cases,
    "parsed_total_cases": tc_total,
    "suspicious_one_to_one": bool(plan_strict.get("suspicious_one_to_one", False)),
    "us_completeness_passed": us_completeness_passed,
    "non_automatable_pending": len(non_automatable_test_cases),
    "completeness_passed": (
        tc_total > 0
        and tc_total == tc_executed
        and tc_failed == 0
        and tc_blocked == 0
        and not has_structural_gaps
        and declared_match
    ),
}

coverage = {
    "us_total": us_total,
    "us_executed": us_executed,
    "us_passed": us_passed,
    "tc_total": tc_total,
    "tc_executed": tc_executed,
    "tc_passed": tc_passed,
    "tc_failed": tc_failed,
    "tc_blocked": tc_blocked,
    "ac_total": len(all_ac),
    "ac_covered": len(covered_ac),
    "by_us": coverage_by_us,
    "by_mode": coverage_by_mode,
}

session_obj = {
    "schema_version": "1.0",
    "session_id": session_id,
    "meta": {
      "version": version,
      "feature": feature,
      "test_type": test_type,
      "tool": tool,
      "base_url": base_url,
    },
    "lifecycle": {
      "started_at": started_at,
      "stopped_at": stopped_at,
      "consolidated_at": stopped_at,
      "status": final_status,
      "model": "start-record-stop-consolidate",
    },
    "plan": {
      "source_test_file": plan.get("test_file", ""),
      "ordered_cases": cases,
    },
    "events": events,
    "results": {
      "cases": list(latest_case.values()),
      "attempts": results_rows,
    },
    "coverage": coverage,
    "strict": strict,
    "gaps": gaps,
    "memory_delta": {
      "new_signatures": int(delta_new_sig),
      "updated_signatures": int(delta_updated_sig),
      "playbook_reused": int(delta_playbook_reused),
      "repeat_guard_triggered": int(delta_repeat_guard),
    }
}

out = Path(session_file)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(session_obj, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

consolidate_test_memory() {
  local final_status="$1"
  local passed="$2"
  local failed="$3"
  local blocked="$4"

  python3 - "$TEST_MEMORY_FILE" "$SESSION_ID" "$VERSION" "$FEATURE" "$TEST_TYPE" "$final_status" "$SESSION_STARTED_AT" "$SESSION_STOPPED_AT" "$passed" "$failed" "$blocked" "$(iso_now)" <<'PY'
import json
import sys
from pathlib import Path

(
    memory_file, session_id, version, feature, test_type, status,
    started_at, stopped_at, passed, failed, blocked, now
) = sys.argv[1:]

p = Path(memory_file)
if not p.exists():
    raise SystemExit(0)
try:
    data = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    raise SystemExit(0)

sessions = data.setdefault("sessions", [])
sessions = [s for s in sessions if s.get("session_id") != session_id]
sessions.append({
    "session_id": session_id,
    "version": version,
    "feature": feature,
    "test_type": test_type,
    "status": status,
    "started_at": started_at,
    "stopped_at": stopped_at,
    "passed": int(passed),
    "failed": int(failed),
    "blocked": int(blocked),
})
sessions = sorted(sessions, key=lambda x: x.get("stopped_at", ""), reverse=True)[:500]
data["sessions"] = sessions
data["updated_at"] = now
p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

emit_test_progress_artifacts() {
  local final_status="$1"
  local passed="$2"
  local failed="$3"
  local blocked="$4"

  local out_dir="$PROJECT_ROOT/docs/product/$VERSION"
  local qa_dir="$out_dir/qa/test-progress"
  mkdir -p "$qa_dir"

  local detail_json="$qa_dir/${FEATURE_SAFE}-${SESSION_ID}.json"
  local detail_md="$qa_dir/${FEATURE_SAFE}-${SESSION_ID}.md"
  local summary_md="$out_dir/test-progress.md"

  cp "$SESSION_FILE" "$detail_json"

  python3 - "$SESSION_FILE" "$detail_md" "$summary_md" "$SESSION_ID" <<'PY'
import json
import sys
from pathlib import Path

session_file, detail_md, summary_md, session_id = sys.argv[1:]
s = json.loads(Path(session_file).read_text(encoding="utf-8"))

meta = s.get("meta", {})
life = s.get("lifecycle", {})
cov = s.get("coverage", {})
gaps = s.get("gaps", {})
strict = s.get("strict", {})
memory_delta = s.get("memory_delta", {})
results = s.get("results", {}).get("cases", [])
ordered_cases = s.get("plan", {}).get("ordered_cases", []) or []
result_map = {str(r.get("case_id")): r for r in results}

lines = []
lines.append(f"# 测试进度详情: {meta.get('version')} / {meta.get('feature')}")
lines.append("")
lines.append(f"- Session ID: `{session_id}`")
lines.append(f"- 生命周期: `{life.get('model')}`")
lines.append(f"- 开始: {life.get('started_at')}")
lines.append(f"- 结束: {life.get('stopped_at')}")
lines.append(f"- 结论: **{life.get('status')}**")
lines.append("")
lines.append("## US → TC 顺序执行结果")
lines.append("")
lines.append("| 顺序 | US | TC | 执行方式 | Method | 期望 | 状态 | 备注 |")
lines.append("|---:|---|---|---|---|---|---|---|")
for case in sorted(ordered_cases, key=lambda x: int(x.get("order", 0) or 0)):
    cid = str(case.get("case_id") or "")
    row = result_map.get(cid, {})
    status = row.get("status", "pending")
    note = row.get("note", "pending")
    lines.append(
        f"| {case.get('order','')} | {case.get('us_id','UNKNOWN')} | {cid} | "
        f"{case.get('execution_mode','agent-browser')} | {case.get('method_hint','')} | "
        f"{case.get('expectation_hint','')} | {status} | {note} |"
    )

lines.append("")
lines.append("## 覆盖率")
lines.append("")
lines.append(f"- US: {cov.get('us_executed',0)}/{cov.get('us_total',0)}，通过 {cov.get('us_passed',0)}")
lines.append(f"- TC: {cov.get('tc_executed',0)}/{cov.get('tc_total',0)}，通过 {cov.get('tc_passed',0)}，失败 {cov.get('tc_failed',0)}，阻塞 {cov.get('tc_blocked',0)}")
lines.append(f"- AC: {cov.get('ac_covered',0)}/{cov.get('ac_total',0)}")

by_us = cov.get("by_us", []) if isinstance(cov.get("by_us"), list) else []
if by_us:
    lines.append("")
    lines.append("### US 完整性矩阵")
    lines.append("")
    lines.append("| US | 声明用例数 | 计划用例数 | 已执行 | 通过 | 失败 | 阻塞 | 待执行 |")
    lines.append("|---|---:|---:|---:|---:|---:|---:|---:|")
    for item in by_us:
        lines.append(
            f"| {item.get('us_id','UNKNOWN')} | {item.get('declared_total',0)} | {item.get('expected',0)} | "
            f"{item.get('executed',0)} | {item.get('passed',0)} | {item.get('failed',0)} | "
            f"{item.get('blocked',0)} | {item.get('pending',0)} |"
        )

by_mode = cov.get("by_mode", []) if isinstance(cov.get("by_mode"), list) else []
if by_mode:
    lines.append("")
    lines.append("### 执行方式覆盖")
    lines.append("")
    lines.append("| 执行方式 | 计划 | 已执行 | 通过 | 失败 | 阻塞 |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for item in by_mode:
        lines.append(
            f"| {item.get('mode','unknown')} | {item.get('expected',0)} | {item.get('executed',0)} | "
            f"{item.get('passed',0)} | {item.get('failed',0)} | {item.get('blocked',0)} |"
        )

lines.append("")
lines.append("## 缺口")
lines.append("")
lines.append(f"- 缺失用户故事映射: {', '.join(gaps.get('missing_user_stories', [])) or '无'}")
lines.append(f"- 缺失测试用例的 US: {', '.join(gaps.get('missing_test_cases', [])) or '无'}")
lines.append(f"- 未执行用例: {', '.join(gaps.get('unexecuted_test_cases', [])) or '无'}")
lines.append(f"- 阻塞用例: {', '.join(gaps.get('blocked_test_cases', [])) or '无'}")
lines.append(f"- 非当前工具可自动执行用例: {', '.join(gaps.get('non_automatable_test_cases', [])) or '无'}")
if gaps.get("declared_count_mismatches"):
    lines.append(f"- 声明/解析数量不一致: {json.dumps(gaps.get('declared_count_mismatches', []), ensure_ascii=False)}")
else:
    lines.append("- 声明/解析数量不一致: 无")

blocked_reason_counts = gaps.get("blocked_reason_counts", {}) if isinstance(gaps.get("blocked_reason_counts"), dict) else {}
blocked_reason_codes = gaps.get("blocked_reason_codes", []) if isinstance(gaps.get("blocked_reason_codes"), list) else []
if blocked_reason_counts:
    reason_labels = {
        "manual_result_missing": "Manual 用例未回填结果（需要 --manual-results）",
        "manual_blocked": "Manual 执行被人工标记阻塞",
        "api_transport_or_connectivity_failure": "API 请求不可达/连接失败",
        "api_placeholders_unresolved": "API URL 占位符未替换（需 --api-vars）",
        "api_expectation_unknown": "API 预期未识别（可补充 expectation 或放宽参数）",
    }
    lines.append("")
    lines.append("### 阻塞原因分布")
    lines.append("")
    lines.append("| 原因代码 | 次数 | 含义 |")
    lines.append("|---|---:|---|")
    for k in sorted(blocked_reason_counts.keys()):
        lines.append(f"| {k} | {blocked_reason_counts.get(k,0)} | {reason_labels.get(k, '见用例备注 note 字段')} |")
if blocked_reason_codes:
    lines.append(f"- 阻塞原因代码列表: {', '.join(blocked_reason_codes)}")

lines.append("")
lines.append("## Strict Gate")
lines.append("")
lines.append(f"- declared_vs_parsed_match: **{strict.get('declared_vs_parsed_match', True)}**")
lines.append(f"- suspicious_one_to_one: **{strict.get('suspicious_one_to_one', False)}**")
lines.append(f"- us_completeness_passed: **{strict.get('us_completeness_passed', False)}**")
lines.append(f"- non_automatable_pending: **{strict.get('non_automatable_pending', 0)}**")
lines.append(f"- completeness_passed: **{strict.get('completeness_passed', False)}**")
lines.append("")
lines.append("## Memory Delta")
lines.append("")
lines.append(f"- 新增签名: {memory_delta.get('new_signatures',0)}")
lines.append(f"- 更新签名: {memory_delta.get('updated_signatures',0)}")
lines.append(f"- Playbook 复用: {memory_delta.get('playbook_reused',0)}")
lines.append(f"- 重复坑拦截: {memory_delta.get('repeat_guard_triggered',0)}")
lines.append("")

Path(detail_md).write_text("\n".join(lines) + "\n", encoding="utf-8")

summary = []
if Path(summary_md).exists():
    summary.append(Path(summary_md).read_text(encoding="utf-8").rstrip())

summary.append(f"\n## {meta.get('feature')} / {session_id}\n")
summary.append(f"- 结论: **{life.get('status')}**")
summary.append(f"- TC: {cov.get('tc_passed',0)} passed / {cov.get('tc_failed',0)} failed / {cov.get('tc_blocked',0)} blocked")
summary.append(f"- Strict: completeness_passed={strict.get('completeness_passed', False)}")
summary.append(f"- 详情: `qa/test-progress/{Path(detail_md).name}`")

Path(summary_md).write_text("\n".join([x for x in summary if x]) + "\n", encoding="utf-8")
PY

  echo -e "${CYAN}Test progress artifacts:${NC}"
  echo "  - $detail_json"
  echo "  - $detail_md"
  echo "  - $summary_md"
}

generate_requirement_feedback_if_needed() {
  if [[ ! -f "$SESSION_FILE" ]]; then
    return 0
  fi
  if [[ ! -f "$FEEDBACK_SCRIPT" ]]; then
    echo -e "${YELLOW}Warning: feedback generator not found: $FEEDBACK_SCRIPT${NC}"
    return 0
  fi

  local should_generate
  should_generate="$(python3 - "$SESSION_FILE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    s = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    print("0")
    raise SystemExit(0)

gaps = s.get("gaps", {}) if isinstance(s.get("gaps"), dict) else {}
memory_delta = s.get("memory_delta", {}) if isinstance(s.get("memory_delta"), dict) else {}

missing_user_stories = gaps.get("missing_user_stories", [])
missing_test_cases = gaps.get("missing_test_cases", [])
repeat_guard_triggered = int(memory_delta.get("repeat_guard_triggered", 0))

should = bool(missing_user_stories) or bool(missing_test_cases) or repeat_guard_triggered > 0
print("1" if should else "0")
PY
)"

  if [[ "$should_generate" != "1" ]]; then
    echo -e "${CYAN}No requirement feedback triggers detected.${NC}"
    return 0
  fi

  echo -e "${CYAN}Generating requirement feedback artifacts...${NC}"
  if ! python3 "$FEEDBACK_SCRIPT" --session-file "$SESSION_FILE" --project-root "$PROJECT_ROOT"; then
    echo -e "${YELLOW}Warning: feedback generation failed${NC}"
    return 0
  fi
}

generate_report() {
  local final_status="$1"
  local passed="$2"
  local failed="$3"
  local blocked="$4"
  local total
  total=$((passed + failed + blocked))

  local coverage=0
  if (( total > 0 )); then
    coverage=$((passed * 100 / total))
  fi

  cat <<REPORT

========================================
Test Report: $VERSION - $FEATURE
========================================
Tool:          $SELECTED_TOOL
Test Type:     $TEST_TYPE
Total Cases:   $total
Passed:        $passed
Failed:        $failed
Blocked:       $blocked
Coverage:      ${coverage}%
Status:        $final_status
Evidence Dir:  $EVIDENCE_DIR/$VERSION/$FEATURE/
Memory File:   $TEST_MEMORY_FILE
Session File:  $SESSION_FILE
REPORT

  if [[ -s "$RESULTS_FILE" ]]; then
    echo
    echo "Case Results:"
    printf "%-18s %-10s %-18s %-45s %-8s %s\n" "CASE" "US" "MODE" "URL" "STATUS" "NOTES"
    printf "%-18s %-10s %-18s %-45s %-8s %s\n" "------------------" "----------" "------------------" "---------------------------------------------" "--------" "-----"
    while IFS=$'\t' read -r cid curl cstatus cnote cus cmode; do
      printf "%-18s %-10s %-18s %-45s %-8s %s\n" "$cid" "${cus:-UNKNOWN}" "${cmode:-agent-browser}" "$curl" "$cstatus" "$cnote"
    done < "$RESULTS_FILE"
  fi

  if [[ "$final_status" == "passed" ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
  elif [[ "$final_status" == "blocked" ]]; then
    echo -e "${YELLOW}⚠ TESTS BLOCKED${NC}"
  else
    echo -e "${RED}✗ TESTS FAILED${NC}"
    echo -e "${YELLOW}已记录失败记忆，后续执行会自动提示历史踩坑。${NC}"
  fi
}

validate_args() {
  [[ -n "$VERSION" ]] || { echo -e "${RED}Error: --version is required${NC}"; usage; }
  [[ -n "$FEATURE" ]] || { echo -e "${RED}Error: --feature is required${NC}"; usage; }

  case "$TEST_TYPE" in
    smoke|regression|full) ;;
    *)
      echo -e "${RED}Error: invalid --type '$TEST_TYPE' (expected smoke|regression|full)${NC}"
      exit 1
      ;;
  esac

  if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || (( MAX_ITERATIONS < 1 )); then
    echo -e "${RED}Error: --iterations must be a positive integer${NC}"
    exit 1
  fi

  if ! [[ "$FRONTEND_TIMEOUT" =~ ^[0-9]+$ ]] || (( FRONTEND_TIMEOUT < 1 )); then
    echo -e "${RED}Error: --frontend-timeout must be a positive integer${NC}"
    exit 1
  fi

  if ! [[ "$API_TIMEOUT" =~ ^[0-9]+$ ]] || (( API_TIMEOUT < 1 )); then
    echo -e "${RED}Error: --api-timeout must be a positive integer${NC}"
    exit 1
  fi

  if [[ -n "$FRONTEND_CMD" && ! -d "$FRONTEND_DIR" ]]; then
    echo -e "${RED}Error: frontend dir not found: $FRONTEND_DIR${NC}"
    exit 1
  fi

  case "$TOOL_MODE" in
    auto|agent-browser|browser-use) ;;
    *)
      echo -e "${RED}Error: invalid --tool '$TOOL_MODE'${NC}"
      exit 1
      ;;
  esac

  if [[ -n "$MANUAL_RESULTS_FILE" && ! -f "$MANUAL_RESULTS_FILE" ]]; then
    echo -e "${RED}Error: manual results file not found: $MANUAL_RESULTS_FILE${NC}"
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--version)
        require_value "$1" "${2:-}"
        VERSION="$2"
        shift 2
        ;;
      -f|--feature)
        require_value "$1" "${2:-}"
        FEATURE="$2"
        shift 2
        ;;
      -t|--type)
        require_value "$1" "${2:-}"
        TEST_TYPE="$2"
        shift 2
        ;;
      -i|--iterations)
        require_value "$1" "${2:-}"
        MAX_ITERATIONS="$2"
        shift 2
        ;;
      --test-file)
        require_value "$1" "${2:-}"
        TEST_FILE="$2"
        shift 2
        ;;
      --manual-results)
        require_value "$1" "${2:-}"
        MANUAL_RESULTS_FILE="$2"
        shift 2
        ;;
      --tool)
        require_value "$1" "${2:-}"
        TOOL_MODE="$2"
        shift 2
        ;;
      --tool-priority)
        require_value "$1" "${2:-}"
        TOOL_PRIORITY="$2"
        shift 2
        ;;
      --headed)
        BROWSER_HEADED=true
        shift
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
      --no-frontend-auto-detect)
        FRONTEND_AUTO_DETECT=false
        shift
        ;;
      --no-frontend-start)
        START_FRONTEND=false
        shift
        ;;
      --memory-file)
        require_value "$1" "${2:-}"
        TEST_MEMORY_FILE="$2"
        shift 2
        ;;
      --api-base-url)
        require_value "$1" "${2:-}"
        API_BASE_URL="$2"
        shift 2
        ;;
      --api-timeout)
        require_value "$1" "${2:-}"
        API_TIMEOUT="$2"
        shift 2
        ;;
      --api-vars)
        require_value "$1" "${2:-}"
        API_VARS="$2"
        shift 2
        ;;
      --api-headers)
        require_value "$1" "${2:-}"
        API_HEADERS="$2"
        shift 2
        ;;
      --api-default-method)
        require_value "$1" "${2:-}"
        API_DEFAULT_METHOD="$2"
        shift 2
        ;;
      --no-api-require-expectation)
        API_REQUIRE_EXPECTATION=false
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}"
        usage
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  auto_detect_frontend_if_needed
  validate_args

  normalize_base_url
  normalize_api_base_url
  create_dirs
  ensure_memory_file
  resolve_test_file
  select_tool
  build_case_plan "$TEST_TYPE"
  analyze_case_plan_modes
  start_test_session
  prepare_manual_results_artifacts

  trap cleanup EXIT INT TERM

  print_header
  show_known_pitfalls
  echo

  start_frontend_if_needed
  if ! verify_server_with_tool; then
    echo -e "${RED}Server verification failed for ${BASE_URL}${NC}"
    echo "Please ensure frontend is running and reachable, then retry."
    exit 1
  fi

  local iteration=1
  local final_status="failed"
  local final_passed=0
  local final_failed=0
  local final_blocked=0

  while (( iteration <= MAX_ITERATIONS )); do
    echo
    echo -e "${BLUE}=== Iteration ${iteration}/${MAX_ITERATIONS} ===${NC}"
    record_event "iteration_start" "" "running" "iteration start" "{\"iteration\":$iteration,\"max_iterations\":$MAX_ITERATIONS}"

    if run_case_batch "$iteration"; then
      final_status="passed"
      final_passed="$LAST_BATCH_PASSED"
      final_failed="$LAST_BATCH_FAILED"
      final_blocked="$LAST_BATCH_BLOCKED"
      record_event "iteration_end" "" "passed" "iteration passed" "{\"iteration\":$iteration,\"passed\":$LAST_BATCH_PASSED,\"failed\":$LAST_BATCH_FAILED,\"blocked\":$LAST_BATCH_BLOCKED}"
      break
    fi

    final_passed="$LAST_BATCH_PASSED"
    final_failed="$LAST_BATCH_FAILED"
    final_blocked="$LAST_BATCH_BLOCKED"

    if (( LAST_BATCH_BLOCKED > 0 )); then
      final_status="blocked"
      record_event "iteration_end" "" "blocked" "iteration blocked by repeat guard" "{\"iteration\":$iteration,\"passed\":$LAST_BATCH_PASSED,\"failed\":$LAST_BATCH_FAILED,\"blocked\":$LAST_BATCH_BLOCKED}"
      break
    fi

    final_status="failed"
    record_event "iteration_end" "" "failed" "iteration failed" "{\"iteration\":$iteration,\"passed\":$LAST_BATCH_PASSED,\"failed\":$LAST_BATCH_FAILED,\"blocked\":$LAST_BATCH_BLOCKED}"

    if (( iteration < MAX_ITERATIONS )); then
      echo -e "${YELLOW}Iteration failed. Retrying...${NC}"
    fi

    ((iteration += 1))
  done

  stop_test_session "$final_status" "$final_passed" "$final_failed" "$final_blocked"
  consolidate_test_memory "$final_status" "$final_passed" "$final_failed" "$final_blocked"
  update_test_progress "$final_status" "$final_passed" "$final_failed" "$final_blocked"
  emit_test_progress_artifacts "$final_status" "$final_passed" "$final_failed" "$final_blocked"
  generate_requirement_feedback_if_needed
  generate_report "$final_status" "$final_passed" "$final_failed" "$final_blocked"

  if [[ "$final_status" != "passed" ]]; then
    exit 1
  fi
}

main "$@"
