#!/usr/bin/env python3
"""
Generate requirement feedback artifacts from auto-test session output.

Outputs:
- .ptk/state/requirement-feedback/{version}-{feature}.json
- docs/product/{version}/feedback/{feature}.json
- docs/product/{version}/feedback/{feature}.md
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slugify(name: str) -> str:
    s = (name or "").strip()
    s = re.sub(r"[^\w.\-]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.strip("_") or "feature"


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise ValueError(f"Invalid json file: {path}: {exc}") from exc


def unique_keep_order(items: list[str]) -> list[str]:
    out: list[str] = []
    seen = set()
    for item in items:
        if not isinstance(item, str):
            continue
        key = item.strip()
        if not key or key in seen:
            continue
        seen.add(key)
        out.append(key)
    return out


def collect_blocked_reason_codes(gaps: dict) -> list[str]:
    explicit = [str(x) for x in gaps.get("blocked_reason_codes", []) if str(x).strip()]
    from_counts = []
    counts = gaps.get("blocked_reason_counts", {})
    if isinstance(counts, dict):
        from_counts = [str(k) for k in counts.keys() if str(k).strip()]
    return unique_keep_order([*explicit, *from_counts])


def build_open_questions(session: dict) -> list[dict]:
    gaps = session.get("gaps", {}) if isinstance(session.get("gaps"), dict) else {}
    meta = session.get("meta", {}) if isinstance(session.get("meta"), dict) else {}
    session_id = str(session.get("session_id", "unknown-session"))

    missing_us = [str(x) for x in gaps.get("missing_user_stories", []) if str(x).strip()]
    missing_tc = [str(x) for x in gaps.get("missing_test_cases", []) if str(x).strip()]
    blocked_reason_codes = collect_blocked_reason_codes(gaps)
    repeat_guard_triggered = int(
        (session.get("memory_delta", {}) or {}).get("repeat_guard_triggered", 0)
    )

    questions: list[dict] = []
    idx = 1
    for us in missing_us:
        questions.append(
            {
                "id": f"oq-missing-us-{idx}",
                "question": f"用例 {us} 缺少用户故事映射，需补充 US 归属与验收边界。",
                "reason": "missing_user_stories",
                "priority": "high",
                "blocking": True,
                "owner": "product-pm",
                "status": "open",
                "close_criteria": "补齐 US 映射并更新 AC→TC 覆盖矩阵。",
                "source": "auto-test-feedback",
                "evidence_ref": [f"session:{session_id}", f"version:{meta.get('version','')}"],
            }
        )
        idx += 1

    idx = 1
    for us in missing_tc:
        questions.append(
            {
                "id": f"oq-missing-tc-{idx}",
                "question": f"用户故事 {us} 缺少测试用例，需补充对应 TC。",
                "reason": "missing_test_cases",
                "priority": "high",
                "blocking": True,
                "owner": "qa-engineer",
                "status": "open",
                "close_criteria": "新增 TC 并通过 Gate 覆盖校验。",
                "source": "auto-test-feedback",
                "evidence_ref": [f"session:{session_id}", f"version:{meta.get('version','')}"],
            }
        )
        idx += 1

    if repeat_guard_triggered > 0:
        questions.append(
            {
                "id": "oq-repeat-guard",
                "question": f"同类失败模式重复触发 {repeat_guard_triggered} 次，需完善 playbook 与回归策略。",
                "reason": "repeat_guard_triggered",
                "priority": "medium",
                "blocking": False,
                "owner": "tech-lead",
                "status": "open",
                "close_criteria": "完成 playbook 改进并验证下轮重复触发下降。",
                "source": "auto-test-feedback",
                "evidence_ref": [f"session:{session_id}"],
            }
        )

    for code in blocked_reason_codes:
        questions.append(
            {
                "id": f"oq-reason-{code}",
                "question": f"阻塞原因 `{code}` 需要在需求/用例中闭环处理。",
                "reason": "blocked_reason_code",
                "priority": "medium",
                "blocking": False,
                "owner": "qa-engineer",
                "status": "open",
                "close_criteria": f"处理 `{code}` 并在后续会话中验证不再触发。",
                "source": "auto-test-feedback",
                "evidence_ref": [f"session:{session_id}"],
            }
        )

    return questions


def build_payload(session: dict) -> dict:
    meta = session.get("meta", {}) if isinstance(session.get("meta"), dict) else {}
    gaps = session.get("gaps", {}) if isinstance(session.get("gaps"), dict) else {}
    memory_delta = session.get("memory_delta", {}) if isinstance(session.get("memory_delta"), dict) else {}
    lifecycle = session.get("lifecycle", {}) if isinstance(session.get("lifecycle"), dict) else {}
    version = str(meta.get("version", "unknown-version"))

    blocked_reason_codes = collect_blocked_reason_codes(gaps)

    payload = {
        "schema_version": "1.0",
        "generated_at": iso_now(),
        "source": {
            "session_id": str(session.get("session_id", "")),
            "version": str(meta.get("version", "")),
            "feature": str(meta.get("feature", "")),
            "test_type": str(meta.get("test_type", "")),
            "tool": str(meta.get("tool", "")),
            "status": str(lifecycle.get("status", "")),
        },
        "signals": {
            "missing_user_stories": [str(x) for x in gaps.get("missing_user_stories", []) if str(x).strip()],
            "missing_test_cases": [str(x) for x in gaps.get("missing_test_cases", []) if str(x).strip()],
            "repeat_guard_triggered": int(memory_delta.get("repeat_guard_triggered", 0)),
            "blocked_reason_codes": blocked_reason_codes,
        },
        "open_questions": build_open_questions(session),
        "actions": [
            {
                "type": "sync_open_questions",
                "description": "将反馈同步到下一轮 think 的 open questions ledger",
                "target": "skills/think -> open_questions",
                "blocking": True,
            },
            {
                "type": "update_user_story",
                "description": "把缺口回写到用户故事与 AC 覆盖矩阵",
                "target": f"docs/product/{version}/user-story",
                "blocking": True,
            },
            {
                "type": "update_test_cases",
                "description": "补齐缺失测试用例并重新执行 auto-test",
                "target": f"docs/product/{version}/qa/test-cases",
                "blocking": True,
            },
        ],
    }
    return payload


def render_markdown(payload: dict) -> str:
    source = payload.get("source", {})
    signals = payload.get("signals", {})
    open_questions = payload.get("open_questions", [])

    lines: list[str] = []
    lines.append(f"# Requirement Feedback: {source.get('version')} / {source.get('feature')}")
    lines.append("")
    lines.append(f"- Session ID: `{source.get('session_id')}`")
    lines.append(f"- Test Type: `{source.get('test_type')}`")
    lines.append(f"- Tool: `{source.get('tool')}`")
    lines.append(f"- Status: `{source.get('status')}`")
    lines.append(f"- Generated At: `{payload.get('generated_at')}`")
    lines.append("")
    lines.append("## Signals")
    lines.append("")
    lines.append(f"- missing_user_stories: {', '.join(signals.get('missing_user_stories', [])) or '无'}")
    lines.append(f"- missing_test_cases: {', '.join(signals.get('missing_test_cases', [])) or '无'}")
    lines.append(f"- repeat_guard_triggered: {signals.get('repeat_guard_triggered', 0)}")
    lines.append(f"- blocked_reason_codes: {', '.join(signals.get('blocked_reason_codes', [])) or '无'}")
    lines.append("")
    lines.append("## Open Questions to Inject")
    lines.append("")
    if not open_questions:
        lines.append("- 无需新增 open questions。")
    else:
        for q in open_questions:
            lines.append(f"- [{q.get('priority','medium')}] ({'blocking' if q.get('blocking') else 'non-blocking'}) {q.get('id')}: {q.get('question')}")
            lines.append(f"  - reason: {q.get('reason')}")
            lines.append(f"  - owner: {q.get('owner')}")
            lines.append(f"  - close_criteria: {q.get('close_criteria')}")
    lines.append("")
    lines.append("## Recommended Next Actions")
    lines.append("")
    for a in payload.get("actions", []):
        lines.append(f"- {a.get('type')}: {a.get('description')} -> `{a.get('target')}`")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate requirement feedback from auto-test session artifact.")
    parser.add_argument("--session-file", required=True, help="Path to test session json")
    parser.add_argument("--project-root", default=str(Path(__file__).resolve().parents[1]), help="Product toolkit root")
    parser.add_argument("--state-dir", default=".ptk/state/requirement-feedback", help="State output directory")
    parser.add_argument("--docs-root", default="docs/product", help="Docs output root")
    args = parser.parse_args()

    project_root = Path(args.project_root).resolve()
    session_file = Path(args.session_file).resolve()
    state_dir = (project_root / args.state_dir).resolve()
    docs_root = (project_root / args.docs_root).resolve()

    session = load_json(session_file)
    payload = build_payload(session)

    source = payload.get("source", {})
    version = str(source.get("version") or "unknown-version")
    feature = str(source.get("feature") or "feature")
    feature_safe = slugify(feature)

    state_dir.mkdir(parents=True, exist_ok=True)
    state_json = state_dir / f"{version}-{feature_safe}.json"
    state_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    feedback_dir = docs_root / version / "feedback"
    feedback_dir.mkdir(parents=True, exist_ok=True)
    feedback_json = feedback_dir / f"{feature_safe}.json"
    feedback_md = feedback_dir / f"{feature_safe}.md"
    feedback_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    feedback_md.write_text(render_markdown(payload), encoding="utf-8")

    shared_feedback_dir = docs_root / "feedback"
    shared_feedback_dir.mkdir(parents=True, exist_ok=True)
    shared_feedback_json = shared_feedback_dir / f"{version}-{feature_safe}.json"
    shared_feedback_md = shared_feedback_dir / f"{version}-{feature_safe}.md"
    shared_feedback_json.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    shared_feedback_md.write_text(render_markdown(payload), encoding="utf-8")

    print(
        json.dumps(
            {
                "session_file": str(session_file),
                "state_json": str(state_json),
                "feedback_json": str(feedback_json),
                "feedback_md": str(feedback_md),
                "shared_feedback_json": str(shared_feedback_json),
                "shared_feedback_md": str(shared_feedback_md),
                "open_questions": len(payload.get("open_questions", [])),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
