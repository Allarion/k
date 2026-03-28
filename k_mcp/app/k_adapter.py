from __future__ import annotations

import logging
import subprocess
import time

from .config import AppConfig
from .policy import PolicyError, truncate_text, validate_args, validate_command_name


LOGGER = logging.getLogger(__name__)


class KAdapter:
    def __init__(self, config: AppConfig) -> None:
        self.config = config

    def run(self, command: str, args: list[str] | None = None) -> dict:
        started = time.perf_counter()
        clean_command = validate_command_name(command, self.config.allowed_commands)
        clean_args = validate_args(args or [])
        argv = [self.config.k_binary, clean_command, *clean_args]
        try:
            completed = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                timeout=self.config.command_timeout_seconds,
                shell=False,
                check=False,
            )
            duration_ms = int((time.perf_counter() - started) * 1000)
            stdout = truncate_text(completed.stdout, self.config.max_stdout_bytes)
            stderr = truncate_text(completed.stderr, self.config.max_stderr_bytes)
            result = {
                "ok": completed.returncode == 0,
                "exit_code": completed.returncode,
                "duration_ms": duration_ms,
                "invoked": {
                    "binary": self.config.k_binary,
                    "command": clean_command,
                    "args": clean_args,
                },
                "stdout": stdout,
                "stderr": stderr,
                "error": None,
                "message": "command completed",
            }
            LOGGER.info(
                "k_run command=%s exit_code=%s duration_ms=%s",
                clean_command,
                completed.returncode,
                duration_ms,
            )
            return result
        except subprocess.TimeoutExpired as exc:
            duration_ms = int((time.perf_counter() - started) * 1000)
            stdout = truncate_text(exc.stdout or "", self.config.max_stdout_bytes)
            stderr = truncate_text(exc.stderr or "", self.config.max_stderr_bytes)
            LOGGER.warning(
                "k_run timeout command=%s duration_ms=%s", clean_command, duration_ms
            )
            return {
                "ok": False,
                "exit_code": None,
                "duration_ms": duration_ms,
                "invoked": {
                    "binary": self.config.k_binary,
                    "command": clean_command,
                    "args": clean_args,
                },
                "stdout": stdout,
                "stderr": stderr,
                "error": "timeout",
                "message": f"command timed out after {self.config.command_timeout_seconds}s",
            }
        except FileNotFoundError:
            duration_ms = int((time.perf_counter() - started) * 1000)
            LOGGER.error("k binary not found: %s", self.config.k_binary)
            return {
                "ok": False,
                "exit_code": None,
                "duration_ms": duration_ms,
                "invoked": {
                    "binary": self.config.k_binary,
                    "command": clean_command,
                    "args": clean_args,
                },
                "stdout": "",
                "stderr": "",
                "error": "binary_not_found",
                "message": f"k binary not found: {self.config.k_binary}",
            }
        except PolicyError:
            raise
        except Exception as exc:  # pragma: no cover
            duration_ms = int((time.perf_counter() - started) * 1000)
            LOGGER.exception("k_run failed unexpectedly")
            return {
                "ok": False,
                "exit_code": None,
                "duration_ms": duration_ms,
                "invoked": {
                    "binary": self.config.k_binary,
                    "command": clean_command,
                    "args": clean_args,
                },
                "stdout": "",
                "stderr": "",
                "error": "execution_failed",
                "message": str(exc),
            }
