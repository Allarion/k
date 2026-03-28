from __future__ import annotations


def _string_array_schema(description: str) -> dict:
    return {
        "type": "array",
        "items": {"type": "string"},
        "description": description,
    }


TOOL_SCHEMAS: dict[str, dict] = {
    "k_help": {
        "type": "object",
        "properties": {},
        "additionalProperties": False,
    },
    "source_list": {
        "type": "object",
        "properties": {
            "extensions": _string_array_schema("Optional file extensions such as .md"),
            "pattern": {"type": "string"},
            "directory_prefix": {"type": "string"},
        },
        "additionalProperties": False,
    },
    "source_read": {
        "type": "object",
        "properties": {"source_path": {"type": "string"}},
        "required": ["source_path"],
        "additionalProperties": False,
    },
    "assess_source_note": {
        "type": "object",
        "properties": {"source_path": {"type": "string"}},
        "required": ["source_path"],
        "additionalProperties": False,
    },
    "propose_migration": {
        "type": "object",
        "properties": {"source_path": {"type": "string"}},
        "required": ["source_path"],
        "additionalProperties": False,
    },
    "k_run": {
        "type": "object",
        "properties": {
            "command": {"type": "string"},
            "args": _string_array_schema("Arguments passed to the allowed k command"),
        },
        "required": ["command"],
        "additionalProperties": False,
    },
    "k_validate_path": {
        "type": "object",
        "properties": {"path": {"type": "string"}},
        "required": ["path"],
        "additionalProperties": False,
    },
    "raise_capability_gap": {
        "type": "object",
        "properties": {
            "area": {
                "type": "string",
                "enum": ["k", "k-mcp", "migration", "source"],
            },
            "title": {"type": "string"},
            "severity": {"type": "string", "enum": ["low", "medium", "high"]},
            "source_path": {"type": "string"},
            "reason": {"type": "string"},
            "suggested_action": {"type": "string"},
        },
        "required": ["area", "title", "severity", "reason"],
        "additionalProperties": False,
    },
}


TOOL_DEFINITIONS: list[dict] = [
    {
        "name": "k_help",
        "description": "Describe k-mcp, its tools, safety model, and allowed k commands.",
        "inputSchema": TOOL_SCHEMAS["k_help"],
    },
    {
        "name": "source_list",
        "description": "List legacy note files under the configured legacy source root.",
        "inputSchema": TOOL_SCHEMAS["source_list"],
    },
    {
        "name": "source_read",
        "description": "Read one legacy/source note in a read-only way.",
        "inputSchema": TOOL_SCHEMAS["source_read"],
    },
    {
        "name": "assess_source_note",
        "description": "Assess one source note for migration suitability.",
        "inputSchema": TOOL_SCHEMAS["assess_source_note"],
    },
    {
        "name": "propose_migration",
        "description": "Produce a structured migration proposal without writing via k.",
        "inputSchema": TOOL_SCHEMAS["propose_migration"],
    },
    {
        "name": "k_run",
        "description": "Execute an allowed k subcommand via subprocess argument arrays.",
        "inputSchema": TOOL_SCHEMAS["k_run"],
    },
    {
        "name": "k_validate_path",
        "description": "Validate a path against the configured k repo root.",
        "inputSchema": TOOL_SCHEMAS["k_validate_path"],
    },
    {
        "name": "raise_capability_gap",
        "description": "Record an explicit capability gap for human review.",
        "inputSchema": TOOL_SCHEMAS["raise_capability_gap"],
    },
]
