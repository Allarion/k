# k-mcp

`k-mcp` is a local, stdio-first MCP server that wraps the existing `k` CLI and adds read-only legacy-note access plus migration assessment helpers.

It is not:
- a redesign of `k`
- a second persistence system
- an embedded LLM client
- a direct writer into target note files

## Why `k` Stays Unchanged

`k-mcp` exists to exercise the current `k` command model, not replace it. All target-side writes must still route through `k`.

That constraint matters because it reveals real capability gaps. Today, `k` can create a draft shell with `k new` and finalize it with `k save`, but it does not yet expose a non-interactive content-bearing create/amend command. `k-mcp` therefore refuses to bypass `k` by writing final note files directly.

## Legacy Notes

Legacy notes are input material only:
- read-only
- never modified or deleted by `k-mcp`
- reviewed and cleaned up later by a human

## Safety Model

- Source access is contained to `LEGACY_SOURCE_ROOT`
- Target path validation is contained to `K_REPO_ROOT`
- `k` subprocess execution uses argument arrays only, never `shell=True`
- Only allowlisted top-level `k` commands can run through `k_run`
- Timeouts and stdout/stderr truncation are enforced
- Failures are returned as structured tool payloads
- Capability-gap escalation is explicit and separate from routine uncertainty

## Tool Surface

v1 exposes these tools:
- `k_help`
- `source_list`
- `source_read`
- `assess_source_note`
- `propose_migration`
- `k_run`
- `k_validate_path`
- `raise_capability_gap`

`k_run` is intentionally transitional. It lets an external orchestrator work against the real `k` CLI while keeping future dedicated wrappers possible once `k` semantics stabilize.

## Migration Review Model

The intended flow is:
1. Read legacy notes
2. Assess them
3. Produce a migration proposal
4. If the target operation is naturally expressible via `k`, execute it through `k`
5. If confidence is lower or ambiguity is high, prefer a draft-plus-review path
6. Final review happens manually via git diff
7. If the system lacks a real capability, record a capability gap instead of faking success

Confidence is not treated as truth. Review level also depends on structural heuristics such as note length, multi-topic shape, TODO markers, and open questions.

## Known v1 Constraint

`k-mcp` can propose migration content, but current `k` semantics do not yet provide a clean non-interactive path to inject that content into a structured draft or final note. `propose_migration` surfaces this explicitly in `suggested_k_action` instead of hiding it.

That is by design: it keeps the integration honest and reviewable.

## Local Usage on arx

Run over stdio:

```bash
python -m k_mcp.app
```

Or install the script entrypoint:

```bash
pip install -e .
k-mcp
```

## Configuration

Environment variables:
- `K_BINARY`: path to the existing `k` executable
- `K_REPO_ROOT`: target repo root used for target path validation
- `LEGACY_SOURCE_ROOT`: configured root for read-only source files
- `LEGACY_NOTES_DIRECTORY`: alias/fallback for `LEGACY_SOURCE_ROOT`
- `K_ALLOWED_COMMANDS`: comma-separated top-level `k` commands allowed via `k_run`
- `K_COMMAND_TIMEOUT_SECONDS`: subprocess timeout
- `K_MAX_STDOUT_BYTES`: stdout truncation limit
- `K_MAX_STDERR_BYTES`: stderr truncation limit
- `K_MCP_FEEDBACK_DIR`: directory for capability-gap records
- `LOG_LEVEL`: Python log level

See `.env.example` in this directory for a starter file.

## Project Layout

```text
k_mcp/
  app/
    server.py
    config.py
    logging_setup.py
    policy.py
    schemas.py
    k_adapter.py
    source_reader.py
    assessment.py
    migration.py
    capability_gap.py
  tests/
```

## Tests

Run:

```bash
python -m unittest discover -s k_mcp/tests -t .
```

## Out Of Scope In v1

- HTTP transport
- authentication
- embedded local LLM client
- semantic search
- embeddings
- OCR
- deleting legacy notes
- auto-git commits
- direct filesystem writes that bypass `k`
- autonomous agent behavior
