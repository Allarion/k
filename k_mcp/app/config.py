from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


def _parse_csv(value: str | None, default: list[str]) -> list[str]:
    if value is None or not value.strip():
        return default
    return [part.strip() for part in value.split(",") if part.strip()]


@dataclass(frozen=True)
class AppConfig:
    k_binary: str
    k_repo_root: Path
    legacy_source_root: Path
    allowed_commands: tuple[str, ...]
    command_timeout_seconds: int
    max_stdout_bytes: int
    max_stderr_bytes: int
    feedback_dir: Path
    log_level: str

    @classmethod
    def from_env(cls) -> "AppConfig":
        repo_root = Path(
            os.environ.get("K_REPO_ROOT", Path.home() / ".k" / "repo")
        ).expanduser()
        legacy_root = Path(
            os.environ.get(
                "LEGACY_SOURCE_ROOT",
                os.environ.get("LEGACY_NOTES_DIRECTORY", repo_root / "legacy"),
            )
        ).expanduser()
        local_binary = Path(__file__).resolve().parents[2] / "bin" / "k"
        k_binary = os.environ.get(
            "K_BINARY", str(local_binary if local_binary.exists() else "k")
        )
        allowed = _parse_csv(
            os.environ.get("K_ALLOWED_COMMANDS"),
            default=[
                "help",
                "scope",
                "draft",
                "jot",
                "today",
                "resume",
                "new",
                "save",
                "todo",
                "find",
            ],
        )
        feedback_dir = Path(
            os.environ.get("K_MCP_FEEDBACK_DIR", repo_root / ".k-mcp-feedback")
        ).expanduser()
        return cls(
            k_binary=k_binary,
            k_repo_root=repo_root.resolve(),
            legacy_source_root=legacy_root.resolve(),
            allowed_commands=tuple(allowed),
            command_timeout_seconds=int(
                os.environ.get("K_COMMAND_TIMEOUT_SECONDS", "20")
            ),
            max_stdout_bytes=int(os.environ.get("K_MAX_STDOUT_BYTES", "65536")),
            max_stderr_bytes=int(os.environ.get("K_MAX_STDERR_BYTES", "65536")),
            feedback_dir=feedback_dir.resolve(),
            log_level=os.environ.get("LOG_LEVEL", "INFO").upper(),
        )
