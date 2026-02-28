import json
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PTK = ROOT / "ptk"


def run_ptk(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(PTK), *args],
        cwd=str(ROOT),
        text=True,
        capture_output=True,
        check=False,
    )


class PtkCliTests(unittest.TestCase):
    def test_status_json(self) -> None:
        proc = run_ptk("status")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        payload = json.loads(proc.stdout)
        self.assertIn("team", payload)
        self.assertIn("gate", payload)

    def test_run_strict_and_report_machine(self) -> None:
        proc = run_ptk(
            "--version",
            "v3.7.0",
            "run",
            "workflow",
            "--mode",
            "strict",
            "--proposal",
            "重写权限模型",
            "--confirm",
            "A",
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        payload = json.loads(proc.stdout)
        run_id = payload["run_id"]

        report = run_ptk("--version", "v3.7.0", "report", "--machine", run_id)
        self.assertEqual(report.returncode, 0, report.stderr)
        machine = json.loads(report.stdout)
        self.assertEqual(machine["run_id"], run_id)
        self.assertIn("events", machine)

    def test_intent_router(self) -> None:
        proc = run_ptk("看看")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("PTK Status Board", proc.stdout)
        self.assertIn("confidence", proc.stderr)

        proc_with_version = run_ptk("--version", "v3.7.0", "状态")
        self.assertEqual(proc_with_version.returncode, 0, proc_with_version.stderr)
        self.assertIn("PTK Status Board", proc_with_version.stdout)

    def test_run_route_wrappers(self) -> None:
        for route in ("team", "auto-test"):
            proc = run_ptk("--version", "v3.7.0", "run", route, "--mode", "dry-run")
            self.assertEqual(proc.returncode, 0, f"{route}: {proc.stderr}")
            payload = json.loads(proc.stdout)
            self.assertEqual(payload["status"], "completed")
            self.assertEqual(payload["reason"], "dry-run")

    def test_run_id_is_unique_for_back_to_back_runs(self) -> None:
        first = run_ptk("--version", "v3.7.0", "run", "workflow", "--mode", "dry-run")
        second = run_ptk("--version", "v3.7.0", "run", "workflow", "--mode", "dry-run")
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        first_id = json.loads(first.stdout)["run_id"]
        second_id = json.loads(second.stdout)["run_id"]
        self.assertNotEqual(first_id, second_id)

    def test_debug_follow_mode(self) -> None:
        run_proc = run_ptk("--version", "v3.7.0", "run", "workflow", "--mode", "debug")
        self.assertEqual(run_proc.returncode, 0, run_proc.stderr)
        run_id = json.loads(run_proc.stdout)["run_id"]

        watch_proc = run_ptk(
            "--version",
            "v3.7.0",
            "debug",
            "watch",
            run_id,
            "--tail",
            "1",
            "--follow",
            "--idle-exit",
            "0.2",
            "--poll-interval",
            "0.1",
        )
        self.assertEqual(watch_proc.returncode, 0, watch_proc.stderr)
        self.assertIn("debug watch follow mode", watch_proc.stderr)
        self.assertIn(run_id, watch_proc.stdout)

    def test_replay_mode_differs_from_normal(self) -> None:
        base_proc = run_ptk("--version", "v3.7.0", "run", "workflow", "--mode", "normal")
        self.assertEqual(base_proc.returncode, 0, base_proc.stderr)
        base_run_id = json.loads(base_proc.stdout)["run_id"]

        replay_proc = run_ptk(
            "--version",
            "v3.7.0",
            "run",
            "workflow",
            "--mode",
            "replay",
            "--from-run",
            base_run_id,
        )
        self.assertEqual(replay_proc.returncode, 0, replay_proc.stderr)
        replay_run_id = json.loads(replay_proc.stdout)["run_id"]

        report = run_ptk("--version", "v3.7.0", "report", "--machine", replay_run_id)
        self.assertEqual(report.returncode, 0, report.stderr)
        payload = json.loads(report.stdout)
        self.assertEqual(payload["mode"], "replay")
        self.assertTrue(any(event.get("event") == "replay_completed" for event in payload.get("events", [])))
        self.assertNotEqual(payload.get("reason", ""), "")

    def test_strict_missing_user_story_is_friendly(self) -> None:
        proc = run_ptk("--version", "v9.9.9", "run", "workflow", "--mode", "strict")
        self.assertNotEqual(proc.returncode, 0)
        self.assertIn("Strict mode requires user-story file", proc.stderr)
        self.assertNotIn("Traceback", proc.stderr)

    def test_doctor_levels_and_integrity_checks(self) -> None:
        proc = run_ptk("--version", "v3.7.0", "doctor", "--json")
        self.assertIn(proc.returncode, (0, 2), proc.stderr)
        payload = json.loads(proc.stdout)
        statuses = {item["status"] for item in payload.get("checks", [])}
        self.assertTrue(statuses.issubset({"PASS", "WARN", "FAIL", "UNKNOWN"}))
        check_names = {item["name"] for item in payload.get("checks", [])}
        self.assertIn("events_integrity", check_names)
        self.assertIn("version_consistency", check_names)


if __name__ == "__main__":
    unittest.main()
