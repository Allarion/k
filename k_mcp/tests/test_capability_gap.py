from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from k_mcp.app.capability_gap import CapabilityGapRecorder


class CapabilityGapTests(unittest.TestCase):
    def test_recording_works(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            recorder = CapabilityGapRecorder(Path(tmp))

            result = recorder.record(
                area="k",
                title="Missing amend command",
                severity="high",
                reason="Cannot populate draft body non-interactively.",
                source_path="legacy/foo.md",
                suggested_action="Add a dedicated amend command to k.",
            )

            output_file = Path(result["stored_at"])
            self.assertTrue(output_file.exists())
            lines = output_file.read_text(encoding="utf-8").splitlines()
            self.assertEqual(1, len(lines))
            payload = json.loads(lines[0])
            self.assertEqual("k", payload["area"])
            self.assertEqual("high", payload["severity"])
