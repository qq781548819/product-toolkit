from __future__ import annotations

import unittest
from pathlib import Path

import sys


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import ptk_cli  # noqa: E402


class TestPtkCli(unittest.TestCase):
    def test_parse_acceptance_criteria(self) -> None:
        user_story = ROOT / "docs" / "product" / "v3.7.0" / "user-story" / "ptk-cli-scope-guard.md"
        data = ptk_cli.parse_acceptance_criteria(user_story)
        self.assertIn("acceptance_criteria", data)
        self.assertGreaterEqual(len(data["acceptance_criteria"]), 10)
        self.assertTrue(any(item["id"] == "US3701-AC01" for item in data["acceptance_criteria"]))

    def test_classify_proposal(self) -> None:
        user_story = ROOT / "docs" / "product" / "v3.7.0" / "user-story" / "ptk-cli-scope-guard.md"
        ac_scope = ptk_cli.parse_acceptance_criteria(user_story)
        t1, r1 = ptk_cli.classify_proposal("add workflow status board", ac_scope)
        t2, r2 = ptk_cli.classify_proposal("rewrite execution engine and drop schema", ac_scope)
        self.assertIn(t1, {"in-scope", "enhancement-proposal"})
        self.assertEqual(r2, "high")
        self.assertEqual(t2, "out-of-scope")

    def test_human_summary_hides_machine_fields(self) -> None:
        machine = {
            "run_id": "run-1",
            "workflow": "workflow",
            "mode": "strict",
            "status": "completed",
            "events": [{"event": "run_completed"}],
            "llm_prompts": ["secret prompt"],
            "token_usage": {"prompt_tokens": 1},
            "tool_calls": [{"name": "x"}],
            "artifacts": {"summary": "docs/product/v3.7.0/execution/summary.md"},
            "confirmations": [],
        }
        text = ptk_cli._human_summary(machine)
        self.assertIn("PTK Human Summary", text)
        self.assertNotIn("secret prompt", text)
        self.assertNotIn("token_usage", text)

    def test_resolve_workflow_route_aliases(self) -> None:
        self.assertEqual(ptk_cli.resolve_workflow_route("workflow")["key"], "workflow")
        self.assertEqual(ptk_cli.resolve_workflow_route("team")["key"], "team")
        self.assertEqual(ptk_cli.resolve_workflow_route("auto_test")["key"], "auto-test")
        self.assertIsNone(ptk_cli.resolve_workflow_route("unknown"))

    def test_infer_intent_has_confidence_and_candidates(self) -> None:
        intent = ptk_cli.infer_intent("看看")
        self.assertEqual(intent.command, "status")
        self.assertGreaterEqual(intent.confidence, 0.45)
        self.assertGreaterEqual(len(intent.candidates), 1)
        self.assertIn("score", intent.candidates[0])

    def test_normalize_argv_unknown_intent_returns_guidance(self) -> None:
        argv, notice, is_error = ptk_cli.normalize_argv(["ptk", "随机指令"])
        self.assertEqual(argv[1], "随机指令")
        self.assertIsNotNone(notice)
        self.assertIn("confidence", notice or "")
        self.assertTrue(is_error)


if __name__ == "__main__":
    unittest.main()
