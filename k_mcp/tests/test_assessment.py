from __future__ import annotations

import unittest

from k_mcp.app.assessment import AssessmentEngine, AssessmentInput


class AssessmentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = AssessmentEngine()

    def test_high_confidence_note_gets_non_mandatory_review(self) -> None:
        note = AssessmentInput(
            source_path="legacy/git-notes.md",
            content=(
                "# Git fetch behavior\n"
                "Git fetch updates remote refs without touching the working tree. "
                "Use it before reviewing remote changes locally. "
                "It is a safe first step when you want fresh remote state before deciding "
                "whether to merge, rebase, or inspect differences in detail. "
                "This note is intentionally focused on one concept and has enough context "
                "to migrate as a compact insight.\n"
            ),
        )

        result = self.engine.assess(note)

        self.assertGreaterEqual(result["confidence"], 0.7)
        self.assertIn(result["review_level"], {"low", "recommended"})

    def test_ambiguous_note_escalates_review_level(self) -> None:
        note = AssessmentInput(
            source_path="legacy/mixed.md",
            content=(
                "# Topic one\nTODO check auth?\n"
                "# Topic two\nWhy does this fail?\n"
                "Maybe also move the CI pipeline.\n"
            ),
        )

        result = self.engine.assess(note)

        self.assertIn(result["review_level"], {"high", "mandatory"})
        self.assertIn(result["suggested_strategy"], {"draft_plus_todo", "blocked"})
