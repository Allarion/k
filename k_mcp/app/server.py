from __future__ import annotations

import json
import logging
import sys
from dataclasses import dataclass
from typing import Any

from .assessment import AssessmentEngine, AssessmentInput
from .capability_gap import CapabilityGapRecorder
from .config import AppConfig
from .k_adapter import KAdapter
from .logging_setup import configure_logging
from .migration import MigrationPlanner
from .policy import PolicyError, ensure_relative_to
from .schemas import TOOL_DEFINITIONS
from .source_reader import SourceReader


LOGGER = logging.getLogger(__name__)


@dataclass
class AppContext:
    config: AppConfig
    source_reader: SourceReader
    assessor: AssessmentEngine
    migration_planner: MigrationPlanner
    k_adapter: KAdapter
    capability_gap_recorder: CapabilityGapRecorder


def build_context() -> AppContext:
    config = AppConfig.from_env()
    configure_logging(config.log_level)
    source_reader = SourceReader(config.legacy_source_root)
    assessor = AssessmentEngine()
    return AppContext(
        config=config,
        source_reader=source_reader,
        assessor=assessor,
        migration_planner=MigrationPlanner(source_reader, assessor),
        k_adapter=KAdapter(config),
        capability_gap_recorder=CapabilityGapRecorder(config.feedback_dir),
    )


class McpStdioServer:
    def __init__(self, context: AppContext) -> None:
        self.context = context

    def run(self) -> None:
        while True:
            request = self._read_message()
            if request is None:
                return
            response = self._handle_request(request)
            if response is not None:
                self._write_message(response)

    def _read_message(self) -> dict[str, Any] | None:
        headers: dict[str, str] = {}
        while True:
            line = sys.stdin.buffer.readline()
            if not line:
                return None
            if line in {b"\r\n", b"\n"}:
                break
            key, _, value = line.decode("utf-8").partition(":")
            headers[key.strip().lower()] = value.strip()
        content_length = int(headers.get("content-length", "0"))
        if content_length <= 0:
            return None
        payload = sys.stdin.buffer.read(content_length)
        return json.loads(payload.decode("utf-8"))

    def _write_message(self, payload: dict[str, Any]) -> None:
        encoded = json.dumps(payload).encode("utf-8")
        sys.stdout.buffer.write(f"Content-Length: {len(encoded)}\r\n\r\n".encode("ascii"))
        sys.stdout.buffer.write(encoded)
        sys.stdout.buffer.flush()

    def _handle_request(self, request: dict[str, Any]) -> dict[str, Any] | None:
        method = request.get("method")
        request_id = request.get("id")
        params = request.get("params", {})
        LOGGER.info("mcp request method=%s id=%s", method, request_id)
        if method == "initialize":
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {"name": "k-mcp", "version": "0.1.0"},
                },
            }
        if method == "notifications/initialized":
            return None
        if method == "tools/list":
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {"tools": TOOL_DEFINITIONS},
            }
        if method == "tools/call":
            name = params.get("name")
            arguments = params.get("arguments", {})
            result, is_error = self._call_tool(name, arguments)
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps(result, indent=2)}],
                    "structuredContent": result,
                    "isError": is_error,
                },
            }
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {"code": -32601, "message": f"method not found: {method}"},
        }

    def _call_tool(self, name: str, arguments: dict[str, Any]) -> tuple[dict[str, Any], bool]:
        try:
            if name == "k_help":
                result = {
                    "server_name": "k-mcp",
                    "available_tools": [tool["name"] for tool in TOOL_DEFINITIONS],
                    "allowed_k_commands": list(self.context.config.allowed_commands),
                    "guardrails": [
                        "k itself remains unchanged; writes must route through k.",
                        "legacy source access is read-only and root-contained.",
                        "k subprocess calls use argument arrays, timeouts, and output limits.",
                        "capability-gap escalation is explicit and separate from routine uncertainty.",
                    ],
                }
                return result, False
            if name == "source_list":
                result = self.context.source_reader.list_files(
                    extensions=arguments.get("extensions"),
                    pattern=arguments.get("pattern"),
                    directory_prefix=arguments.get("directory_prefix"),
                )
                return result, False
            if name == "source_read":
                result = self.context.source_reader.read_file(arguments["source_path"])
                return result, False
            if name == "assess_source_note":
                source_note = self.context.source_reader.read_file(arguments["source_path"])
                result = self.context.assessor.assess(
                    AssessmentInput(
                        source_path=source_note["source_path"],
                        content=source_note["content"],
                    )
                )
                return result, False
            if name == "propose_migration":
                result = self.context.migration_planner.propose(arguments["source_path"])
                return result, False
            if name == "k_run":
                result = self.context.k_adapter.run(
                    arguments["command"], arguments.get("args", [])
                )
                return result, not result["ok"]
            if name == "k_validate_path":
                resolved = ensure_relative_to(
                    self.context.config.k_repo_root, arguments["path"]
                )
                return {
                    "ok": True,
                    "input_path": arguments["path"],
                    "normalized_absolute_path": str(resolved),
                    "repo_root": str(self.context.config.k_repo_root),
                }, False
            if name == "raise_capability_gap":
                result = self.context.capability_gap_recorder.record(
                    area=arguments["area"],
                    title=arguments["title"],
                    severity=arguments["severity"],
                    reason=arguments["reason"],
                    source_path=arguments.get("source_path"),
                    suggested_action=arguments.get("suggested_action"),
                )
                return result, False
            return {"ok": False, "error": f"unknown tool: {name}"}, True
        except PolicyError as exc:
            LOGGER.warning("tool policy rejection tool=%s error=%s", name, exc)
            return {"ok": False, "error": "policy_error", "message": str(exc)}, True
        except FileNotFoundError as exc:
            LOGGER.warning("tool file not found tool=%s error=%s", name, exc)
            return {"ok": False, "error": "not_found", "message": str(exc)}, True
        except Exception as exc:  # pragma: no cover
            LOGGER.exception("tool failed tool=%s", name)
            return {"ok": False, "error": "internal_error", "message": str(exc)}, True


def main() -> None:
    context = build_context()
    McpStdioServer(context).run()


if __name__ == "__main__":
    main()
