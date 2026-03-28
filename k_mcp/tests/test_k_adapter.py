from __future__ import annotations

import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

from k_mcp.app.config import AppConfig
from k_mcp.app.k_adapter import KAdapter
from k_mcp.app.policy import PolicyError


class KAdapterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.config = AppConfig(
            k_binary="/usr/bin/k",
            k_repo_root=Path("/tmp/repo"),
            legacy_source_root=Path("/tmp/legacy"),
            allowed_commands=("help", "todo", "new", "save"),
            command_timeout_seconds=3,
            max_stdout_bytes=16,
            max_stderr_bytes=12,
            feedback_dir=Path("/tmp/feedback"),
            log_level="INFO",
        )
        self.adapter = KAdapter(self.config)

    def test_rejects_disallowed_subcommands(self) -> None:
        with self.assertRaises(PolicyError):
            self.adapter.run("setup", [])

    @patch("k_mcp.app.k_adapter.subprocess.run")
    def test_uses_argument_arrays_without_shell(self, mock_run) -> None:
        mock_run.return_value = subprocess.CompletedProcess(
            args=["/usr/bin/k", "help"], returncode=0, stdout="ok", stderr=""
        )

        result = self.adapter.run("help", [])

        self.assertTrue(result["ok"])
        _, kwargs = mock_run.call_args
        self.assertFalse(kwargs["shell"])
        self.assertEqual(["/usr/bin/k", "help"], mock_run.call_args.args[0])

    @patch("k_mcp.app.k_adapter.subprocess.run")
    def test_timeout_handling(self, mock_run) -> None:
        mock_run.side_effect = subprocess.TimeoutExpired(
            cmd=["/usr/bin/k", "help"],
            timeout=3,
            output="partial stdout",
            stderr="partial stderr",
        )

        result = self.adapter.run("help", [])

        self.assertFalse(result["ok"])
        self.assertEqual("timeout", result["error"])
        self.assertIn("timed out", result["message"])

    @patch("k_mcp.app.k_adapter.subprocess.run")
    def test_stdout_stderr_truncation(self, mock_run) -> None:
        mock_run.return_value = subprocess.CompletedProcess(
            args=["/usr/bin/k", "help"],
            returncode=0,
            stdout="x" * 100,
            stderr="y" * 100,
        )

        result = self.adapter.run("help", [])

        self.assertIn("[truncated", result["stdout"])
        self.assertIn("[truncated", result["stderr"])
