#!/usr/bin/env python3
"""Write stage handoff notes for Product Toolkit team runtime."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def split_csv(raw: str) -> list[str]:
    if not raw:
        return []
    return [x.strip() for x in raw.split(",") if x.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description="Create stage handoff markdown.")
    parser.add_argument("--project-root", default=str(Path(__file__).resolve().parents[1]))
    parser.add_argument("--team", required=True)
    parser.add_argument("--from-stage", required=True)
    parser.add_argument("--to-stage", required=True)
    parser.add_argument("--decided", default="")
    parser.add_argument("--rejected", default="")
    parser.add_argument("--risks", default="")
    parser.add_argument("--files", default="")
    parser.add_argument("--remaining", default="")
    args = parser.parse_args()

    root = Path(args.project_root).resolve()
    handoff_dir = root / ".ptk" / "handoffs"
    handoff_dir.mkdir(parents=True, exist_ok=True)

    path = handoff_dir / f"{args.team}-{args.from_stage}-to-{args.to_stage}.md"
    decided = split_csv(args.decided)
    rejected = split_csv(args.rejected)
    risks = split_csv(args.risks)
    files = split_csv(args.files)
    remaining = split_csv(args.remaining)

    lines: list[str] = []
    lines.append(f"## Handoff: {args.from_stage} -> {args.to_stage}")
    lines.append(f"- Team: `{args.team}`")
    lines.append(f"- Timestamp: `{iso_now()}`")
    lines.append("")
    lines.append("- **Decided**:")
    lines.extend([f"  - {x}" for x in (decided or ["(none)"])])
    lines.append("- **Rejected**:")
    lines.extend([f"  - {x}" for x in (rejected or ["(none)"])])
    lines.append("- **Risks**:")
    lines.extend([f"  - {x}" for x in (risks or ["(none)"])])
    lines.append("- **Files**:")
    lines.extend([f"  - {x}" for x in (files or ["(none)"])])
    lines.append("- **Remaining**:")
    lines.extend([f"  - {x}" for x in (remaining or ["(none)"])])
    lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
