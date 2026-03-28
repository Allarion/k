from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .assessment import AssessmentEngine, AssessmentInput
from .source_reader import SourceReader


@dataclass(frozen=True)
class MigrationProposalContext:
    source_path: str
    source_note: dict
    assessment: dict


class MigrationPlanner:
    def __init__(self, source_reader: SourceReader, assessor: AssessmentEngine) -> None:
        self.source_reader = source_reader
        self.assessor = assessor

    def propose(self, source_path: str) -> dict:
        source_note = self.source_reader.read_file(source_path)
        assessment = self.assessor.assess(
            AssessmentInput(
                source_path=source_note["source_path"],
                content=source_note["content"],
            )
        )
        context = MigrationProposalContext(
            source_path=source_note["source_path"],
            source_note=source_note,
            assessment=assessment,
        )
        proposed_title = self._infer_title(source_note["content"], source_note["source_path"])
        proposed_kind = self._infer_kind(source_note["content"])
        proposed_tags = self._infer_tags(
            source_note["content"], source_note["source_path"]
        )
        proposed_body = source_note["content"].strip()
        action = self._suggest_k_action(context, proposed_kind, proposed_title, proposed_tags)
        return {
            "source_path": source_note["source_path"],
            "normalized_source_path": source_note["normalized_absolute_path"],
            "proposed_target_kind": proposed_kind,
            "proposed_title": proposed_title,
            "proposed_tags": proposed_tags,
            "proposed_body": proposed_body,
            "proposed_metadata": {
                "legacy_read_only": True,
                "source_reference": source_note["source_path"],
                "source_suffix": source_note["metadata"]["suffix"],
            },
            "assessment": assessment,
            "suggested_k_action": action,
            "notes_for_human_review": action["notes_for_human_review"],
        }

    def _infer_title(self, content: str, source_path: str) -> str:
        for line in content.splitlines():
            stripped = line.strip()
            if stripped.startswith("#"):
                return stripped.lstrip("#").strip()[:80] or Path(source_path).stem
            if stripped:
                return stripped[:80]
        return Path(source_path).stem.replace("-", " ").replace("_", " ").title()

    def _infer_kind(self, content: str) -> str:
        lowered = content.lower()
        if "decision" in lowered:
            return "decision"
        if any(token in lowered for token in ("why", "error", "fail", "issue", "problem")):
            return "problem"
        if any(token in lowered for token in ("solution", "resolved", "fix", "steps")):
            return "solution"
        if any(token in lowered for token in ("idea", "maybe", "explore")):
            return "idea"
        return "insight"

    def _infer_tags(self, content: str, source_path: str) -> list[str]:
        candidates = {
            "git": "git",
            "bash": "bash",
            "python": "python",
            "java": "java",
            "quarkus": "quarkus",
            "auth": "auth",
            "traefik": "traefik",
            "linux": "linux",
        }
        lowered = f"{source_path} {content}".lower()
        return [tag for keyword, tag in candidates.items() if keyword in lowered]

    def _suggest_k_action(
        self,
        context: MigrationProposalContext,
        proposed_kind: str,
        proposed_title: str,
        proposed_tags: list[str],
    ) -> dict:
        source_ref = context.source_path
        tags_csv = ",".join(proposed_tags)
        blocked_reason = (
            "Current k CLI can create a draft template (`k new`) and finalize a draft "
            "(`k save`), but it cannot non-interactively populate or amend structured "
            "draft body content through a dedicated command. k-mcp therefore avoids "
            "bypassing k with direct target file writes."
        )
        review_note = (
            "Human review via git diff remains required. This proposal is structured, "
            "but current k semantics do not yet expose a safe content-bearing create/amend command."
        )

        if context.assessment["suggested_strategy"] == "blocked":
            return {
                "strategy": "blocked",
                "supported_by_current_k": False,
                "commands": [],
                "blocked_reason": "Source note is too weak for reliable migration.",
                "notes_for_human_review": [
                    "Assessment blocked automatic migration planning.",
                    review_note,
                ],
            }

        base_commands = [
            {
                "command": "new",
                "args": [proposed_kind, proposed_title]
                + (["--tags", tags_csv] if tags_csv else []),
                "reason": "Create the initial structured draft via k.",
            }
        ]
        if context.assessment["suggested_strategy"] == "draft_plus_todo":
            base_commands.append(
                {
                    "command": "todo",
                    "args": [
                        "add",
                        (
                            "Review migrated draft for legacy source "
                            f"{source_ref}; k lacks a non-interactive amend path."
                        ),
                    ],
                    "reason": "Create a manual review todo through k.",
                }
            )

        return {
            "strategy": context.assessment["suggested_strategy"],
            "supported_by_current_k": False,
            "commands": base_commands,
            "blocked_reason": blocked_reason,
            "notes_for_human_review": [
                review_note,
                f"Legacy source is read-only: {source_ref}",
            ],
        }
