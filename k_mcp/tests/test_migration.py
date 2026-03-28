from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from k_mcp.app.assessment import AssessmentEngine
from k_mcp.app.migration import MigrationPlanner
from k_mcp.app.source_reader import SourceReader


class MigrationTests(unittest.TestCase):
    def test_proposal_is_structured_and_honest_about_gaps(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            note = root / "auth-issue.md"
            note.write_text(
                "# Auth issue\n"
                "Problem: middleware name mismatch in Traefik auth chain.\n"
                "Potential fix: align middleware names.\n",
                encoding="utf-8",
            )
            planner = MigrationPlanner(SourceReader(root), AssessmentEngine())

            result = planner.propose("auth-issue.md")

            self.assertEqual("auth-issue.md", result["source_path"])
            self.assertIn("proposed_target_kind", result)
            self.assertIn("proposed_body", result)
            self.assertIn("assessment", result)
            self.assertIn("suggested_k_action", result)
            self.assertFalse(result["suggested_k_action"]["supported_by_current_k"])
            self.assertIn(
                "cannot non-interactively populate",
                result["suggested_k_action"]["blocked_reason"],
            )
