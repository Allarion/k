from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path


class CapabilityGapRecorder:
    def __init__(self, feedback_dir: Path) -> None:
        self.feedback_dir = feedback_dir.expanduser().resolve()

    def record(
        self,
        *,
        area: str,
        title: str,
        severity: str,
        reason: str,
        source_path: str | None = None,
        suggested_action: str | None = None,
    ) -> dict:
        self.feedback_dir.mkdir(parents=True, exist_ok=True)
        output_file = self.feedback_dir / "capability-gaps.jsonl"
        record = {
            "recorded_at": datetime.now(tz=timezone.utc).isoformat(),
            "area": area,
            "title": title,
            "severity": severity,
            "reason": reason,
            "source_path": source_path,
            "suggested_action": suggested_action,
        }
        with output_file.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, ensure_ascii=True) + "\n")
        return {
            "ok": True,
            "record": record,
            "stored_at": str(output_file),
        }
