from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from k_mcp.app.policy import PolicyError, ensure_relative_to


class PolicyTests(unittest.TestCase):
    def test_rejects_traversal_outside_legacy_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "legacy"
            root.mkdir()
            with self.assertRaises(PolicyError):
                ensure_relative_to(root, "../outside.md")

    def test_rejects_traversal_outside_repo_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            root.mkdir()
            with self.assertRaises(PolicyError):
                ensure_relative_to(root, "../../etc/passwd")
