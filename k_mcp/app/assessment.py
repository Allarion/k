from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class AssessmentInput:
    source_path: str
    content: str


class AssessmentEngine:
    def assess(self, note: AssessmentInput) -> dict:
        text = note.content.strip()
        lines = [line.strip() for line in note.content.splitlines()]
        non_empty_lines = [line for line in lines if line]
        headings = [line for line in lines if line.startswith("#")]
        question_lines = [line for line in lines if "?" in line]
        todo_markers = [
            line
            for line in lines
            if any(token in line.lower() for token in ("todo", "fixme", "tbd"))
        ]
        code_fences = note.content.count("```")
        words = len(text.split())

        risks: list[str] = []
        warnings: list[str] = []
        confidence = 0.92

        if not text:
            risks.append("source note is empty")
            confidence = 0.0
        if words < 40:
            risks.append("note is short and may lack migration context")
            confidence -= 0.18
        if len(headings) > 2:
            risks.append("multiple headings suggest multiple topics")
            confidence -= 0.12
        if len(question_lines) >= 2:
            warnings.append("contains multiple open questions")
            confidence -= 0.08
        if todo_markers:
            warnings.append("contains TODO-like markers")
            confidence -= 0.10
        if code_fences >= 2:
            warnings.append("contains substantial code snippets")
            confidence -= 0.08
        if len(non_empty_lines) > 60:
            risks.append("note is long and may need decomposition")
            confidence -= 0.10

        confidence = max(0.0, min(round(confidence, 2), 1.0))
        complexity = "low"
        if len(non_empty_lines) > 25 or code_fences >= 2 or len(headings) > 1:
            complexity = "medium"
        if len(non_empty_lines) > 60 or len(headings) > 3:
            complexity = "high"

        transferability = "good"
        if not text or words < 20:
            transferability = "poor"
        elif warnings or complexity != "low":
            transferability = "partial"

        review_level = "low"
        if confidence < 0.55 or transferability == "poor":
            review_level = "mandatory"
        elif confidence < 0.8 or complexity == "high":
            review_level = "high"
        elif warnings or complexity == "medium":
            review_level = "recommended"

        if confidence == 0.0:
            strategy = "blocked"
        elif confidence >= 0.8 and review_level in {"low", "recommended"}:
            strategy = "direct_note"
        else:
            strategy = "draft_plus_todo"

        summary = self._build_summary(
            source_path=note.source_path,
            confidence=confidence,
            complexity=complexity,
            strategy=strategy,
        )
        return {
            "source_path": note.source_path,
            "confidence": confidence,
            "complexity": complexity,
            "review_level": review_level,
            "transferability": transferability,
            "migration_risks": risks,
            "warnings": warnings,
            "summary": summary,
            "suggested_strategy": strategy,
        }

    @staticmethod
    def _build_summary(
        source_path: str, confidence: float, complexity: str, strategy: str
    ) -> str:
        filename = Path(source_path).name
        return (
            f"{filename}: confidence={confidence:.2f}, "
            f"complexity={complexity}, suggested_strategy={strategy}"
        )
