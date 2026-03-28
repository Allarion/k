from __future__ import annotations

from datetime import datetime, timezone
from fnmatch import fnmatch
from pathlib import Path

from .policy import ensure_relative_to


class SourceReader:
    def __init__(self, root: Path) -> None:
        self.root = root.expanduser().resolve()

    def list_files(
        self,
        extensions: list[str] | None = None,
        pattern: str | None = None,
        directory_prefix: str | None = None,
    ) -> dict:
        search_root = (
            ensure_relative_to(self.root, directory_prefix)
            if directory_prefix
            else self.root
        )
        normalized_ext = {
            ext if ext.startswith(".") else f".{ext}" for ext in (extensions or [])
        }
        files: list[dict] = []
        for path in sorted(search_root.rglob("*")):
            if not path.is_file():
                continue
            resolved = path.resolve()
            relative_path = resolved.relative_to(self.root).as_posix()
            if normalized_ext and resolved.suffix not in normalized_ext:
                continue
            if pattern and not fnmatch(relative_path, pattern):
                continue
            stat = resolved.stat()
            files.append(
                {
                    "source_path": relative_path,
                    "normalized_absolute_path": str(resolved),
                    "size_bytes": stat.st_size,
                    "modified_at": datetime.fromtimestamp(
                        stat.st_mtime, tz=timezone.utc
                    ).isoformat(),
                }
            )
        return {
            "root": str(self.root),
            "count": len(files),
            "files": files,
        }

    def read_file(self, source_path: str) -> dict:
        resolved = ensure_relative_to(self.root, source_path)
        stat = resolved.stat()
        content = resolved.read_text(encoding="utf-8", errors="replace")
        return {
            "source_path": Path(source_path).as_posix(),
            "normalized_absolute_path": str(resolved),
            "metadata": {
                "size_bytes": stat.st_size,
                "modified_at": datetime.fromtimestamp(
                    stat.st_mtime, tz=timezone.utc
                ).isoformat(),
                "suffix": resolved.suffix,
                "stem": resolved.stem,
            },
            "content": content,
        }
