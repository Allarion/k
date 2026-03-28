from __future__ import annotations

from pathlib import Path


class PolicyError(ValueError):
    """Raised when policy validation fails."""


def ensure_relative_to(root: Path, candidate: str | Path) -> Path:
    root_resolved = root.expanduser().resolve()
    candidate_path = Path(candidate).expanduser()
    resolved = (
        candidate_path.resolve()
        if candidate_path.is_absolute()
        else (root_resolved / candidate_path).resolve()
    )
    try:
        resolved.relative_to(root_resolved)
    except ValueError as exc:
        raise PolicyError(f"path escapes configured root: {candidate}") from exc
    return resolved


def validate_command_name(command: str, allowed_commands: tuple[str, ...]) -> str:
    normalized = command.strip()
    if not normalized:
        raise PolicyError("command must not be empty")
    if normalized not in allowed_commands:
        raise PolicyError(f"command is not allowed: {normalized}")
    return normalized


def validate_args(args: list[str]) -> list[str]:
    validated: list[str] = []
    for arg in args:
        if not isinstance(arg, str):
            raise PolicyError("all args must be strings")
        if "\x00" in arg:
            raise PolicyError("args must not contain NUL bytes")
        validated.append(arg)
    return validated


def truncate_text(value: str, max_bytes: int) -> str:
    encoded = value.encode("utf-8", errors="replace")
    if len(encoded) <= max_bytes:
        return value
    clipped = encoded[:max_bytes].decode("utf-8", errors="ignore")
    return f"{clipped}\n...[truncated to {max_bytes} bytes]"
