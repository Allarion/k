from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from k_mcp.app.policy import PolicyError
from k_mcp.app.source_reader import SourceReader


class SourceReaderTests(unittest.TestCase):
    def test_source_read_does_not_modify_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            note = root / "note.md"
            original = "# Title\nBody\n"
            note.write_text(original, encoding="utf-8")
            before = note.stat().st_mtime_ns
            reader = SourceReader(root)

            result = reader.read_file("note.md")

            after = note.stat().st_mtime_ns
            self.assertEqual(original, result["content"])
            self.assertEqual(before, after)

    def test_source_list_rejects_outside_prefix(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            reader = SourceReader(root)
            with self.assertRaises(PolicyError):
                reader.list_files(directory_prefix="../outside")
