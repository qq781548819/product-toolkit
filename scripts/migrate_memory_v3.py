#!/usr/bin/env python3
"""
Memory migration helper for Product Toolkit (M1).

Goals:
- normalize memory entries with a unified metadata envelope
- keep backward compatibility with existing data structures
- provide dry-run and rollback support
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


def iso_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


@dataclass
class FileMigrationResult:
    path: Path
    changed: bool
    entries_touched: int
    note: str = ""


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON: {path}: {exc}") from exc


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def first_non_empty(entry: dict, keys: Iterable[str]) -> str | None:
    for key in keys:
        value = entry.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


def normalize_entry(
    entry: dict,
    *,
    entry_type: str,
    id_candidates: list[str],
    created_candidates: list[str],
    updated_candidates: list[str],
    default_source: str,
) -> bool:
    changed = False
    if not isinstance(entry, dict):
        return changed

    existing_id = first_non_empty(entry, ["memory_id", *id_candidates])
    if not existing_id:
        existing_id = str(uuid.uuid4())
    if entry.get("memory_id") != existing_id:
        entry["memory_id"] = existing_id
        changed = True

    if entry.get("type") != entry_type:
        entry["type"] = entry_type
        changed = True

    source_session_id = first_non_empty(entry, ["source_session_id", "session_id"]) or "system"
    if entry.get("source_session_id") != source_session_id:
        entry["source_session_id"] = source_session_id
        changed = True

    source = first_non_empty(entry, ["source"]) or default_source
    if entry.get("source") != source:
        entry["source"] = source
        changed = True

    created_at = first_non_empty(entry, created_candidates) or iso_now()
    updated_at = first_non_empty(entry, updated_candidates) or created_at
    if entry.get("created_at") != created_at:
        entry["created_at"] = created_at
        changed = True
    if entry.get("updated_at") != updated_at:
        entry["updated_at"] = updated_at
        changed = True

    if "confidence" not in entry:
        entry["confidence"] = 0.7 if entry_type.startswith("test_") else 0.8
        changed = True

    if "tags" not in entry or not isinstance(entry.get("tags"), list):
        tags: list[str] = []
        category = entry.get("category")
        if isinstance(category, str) and category.strip():
            tags.append(category.strip())
        if entry_type.startswith("test_"):
            tags.append("test-memory")
        entry["tags"] = sorted(set(tags))
        changed = True

    if "evidence_ref" not in entry:
        evidence = None
        for key in ("log_file", "trace_file", "detail_file"):
            value = entry.get(key)
            if isinstance(value, str) and value.strip():
                evidence = value.strip()
                break
        entry["evidence_ref"] = evidence or []
        changed = True

    return changed


def migrate_insights(path: Path) -> FileMigrationResult:
    data = read_json(path)
    if not data:
        return FileMigrationResult(path, False, 0, "file missing or empty")

    items = data.get("insights")
    if not isinstance(items, list):
        return FileMigrationResult(path, False, 0, "no insights array")

    changed = False
    touched = 0
    for item in items:
        touched += 1
        changed |= normalize_entry(
            item,
            entry_type="insight",
            id_candidates=["id"],
            created_candidates=["created_at"],
            updated_candidates=["updated_at", "created_at"],
            default_source="remember",
        )

    if changed:
        data["schema_version"] = "3.0"
        data["updated_at"] = iso_now()
        write_json(path, data)
    return FileMigrationResult(path, changed, touched)


def migrate_decisions(path: Path) -> FileMigrationResult:
    data = read_json(path)
    if not data:
        return FileMigrationResult(path, False, 0, "file missing or empty")

    items = data.get("decisions")
    if not isinstance(items, list):
        return FileMigrationResult(path, False, 0, "no decisions array")

    changed = False
    touched = 0
    for item in items:
        touched += 1
        changed |= normalize_entry(
            item,
            entry_type="decision",
            id_candidates=["id"],
            created_candidates=["created_at", "decided_at"],
            updated_candidates=["updated_at", "decided_at", "created_at"],
            default_source="remember",
        )

    if changed:
        data["schema_version"] = "3.0"
        data["updated_at"] = iso_now()
        write_json(path, data)
    return FileMigrationResult(path, changed, touched)


def migrate_vocabulary(path: Path) -> FileMigrationResult:
    data = read_json(path)
    if not data:
        return FileMigrationResult(path, False, 0, "file missing or empty")

    items = data.get("terms")
    if not isinstance(items, list):
        return FileMigrationResult(path, False, 0, "no terms array")

    changed = False
    touched = 0
    for item in items:
        touched += 1
        changed |= normalize_entry(
            item,
            entry_type="vocabulary",
            id_candidates=["id", "term"],
            created_candidates=["created_at"],
            updated_candidates=["updated_at", "created_at"],
            default_source="remember",
        )

    if changed:
        data["schema_version"] = "3.0"
        data["updated_at"] = iso_now()
        write_json(path, data)
    return FileMigrationResult(path, changed, touched)


def migrate_test_learnings(path: Path) -> FileMigrationResult:
    data = read_json(path)
    if not data:
        return FileMigrationResult(path, False, 0, "file missing or empty")

    changed = False
    touched = 0

    signatures = data.get("signatures")
    if isinstance(signatures, list):
        for item in signatures:
            touched += 1
            changed |= normalize_entry(
                item,
                entry_type="test_signature",
                id_candidates=["signature_id", "signature"],
                created_candidates=["created_at", "first_seen"],
                updated_candidates=["updated_at", "last_seen", "first_seen"],
                default_source="auto-test",
            )

    playbooks = data.get("playbooks")
    if isinstance(playbooks, list):
        for item in playbooks:
            touched += 1
            changed |= normalize_entry(
                item,
                entry_type="test_playbook",
                id_candidates=["playbook_id", "signature_id"],
                created_candidates=["created_at", "last_used", "updated_at"],
                updated_candidates=["updated_at", "last_used", "created_at"],
                default_source="auto-test",
            )

    sessions = data.get("sessions")
    if isinstance(sessions, list):
        for item in sessions:
            touched += 1
            changed |= normalize_entry(
                item,
                entry_type="test_session",
                id_candidates=["session_id"],
                created_candidates=["created_at", "started_at"],
                updated_candidates=["updated_at", "stopped_at", "started_at"],
                default_source="auto-test",
            )

    if changed:
        # Keep version=2.0 for runtime backward compatibility in auto_test.sh
        data["schema_version"] = "3.0"
        data["updated_at"] = iso_now()
        write_json(path, data)

    return FileMigrationResult(path, changed, touched)


def create_backup(files: list[Path], backup_root: Path) -> Path:
    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    backup_dir = backup_root / f"memory-migration-{ts}"
    backup_dir.mkdir(parents=True, exist_ok=True)
    for src in files:
        if src.exists():
            rel_name = src.name
            shutil.copy2(src, backup_dir / rel_name)
    return backup_dir


def rollback_from_backup(memory_dir: Path, backup_dir: Path) -> int:
    if not backup_dir.exists() or not backup_dir.is_dir():
        raise FileNotFoundError(f"Backup directory not found: {backup_dir}")
    restored = 0
    for src in backup_dir.glob("*.json"):
        dst = memory_dir / src.name
        shutil.copy2(src, dst)
        restored += 1
    return restored


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate Product Toolkit memory files to unified envelope metadata.")
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[1]), help="Project root (default: script parent)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be migrated without writing changes")
    parser.add_argument("--rollback", help="Restore memory files from a backup directory")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    memory_dir = root / ".ptk" / "memory"
    backup_root = root / ".ptk" / "backups"

    if args.rollback:
        restored = rollback_from_backup(memory_dir, Path(args.rollback).expanduser().resolve())
        print(json.dumps({"mode": "rollback", "restored_files": restored}, ensure_ascii=False, indent=2))
        return 0

    targets = [
        memory_dir / "project-insights.json",
        memory_dir / "decisions.json",
        memory_dir / "vocabulary.json",
        memory_dir / "test-learnings.json",
    ]

    migrators = {
        "project-insights.json": migrate_insights,
        "decisions.json": migrate_decisions,
        "vocabulary.json": migrate_vocabulary,
        "test-learnings.json": migrate_test_learnings,
    }

    existing_targets = [p for p in targets if p.exists()]
    backup_dir = create_backup(existing_targets, backup_root) if existing_targets else None

    results: list[FileMigrationResult] = []
    for path in targets:
        migrator = migrators[path.name]
        if args.dry_run:
            # simulate by reading only
            try:
                result = migrator(path)
            except Exception as exc:  # pragma: no cover
                result = FileMigrationResult(path, False, 0, f"error: {exc}")
            # rollback immediately if dry run wrote anything
            if result.changed and backup_dir:
                shutil.copy2(backup_dir / path.name, path)
                result = FileMigrationResult(path, True, result.entries_touched, "would change")
            elif not path.exists():
                result = FileMigrationResult(path, False, 0, "file missing")
            results.append(result)
            continue

        results.append(migrator(path))

    payload = {
        "mode": "dry-run" if args.dry_run else "migrate",
        "root": str(root),
        "backup_dir": str(backup_dir) if backup_dir else "",
        "results": [
            {
                "file": str(r.path),
                "changed": r.changed,
                "entries_touched": r.entries_touched,
                "note": r.note,
            }
            for r in results
        ],
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
