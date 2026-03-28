# k

`k` is a lightweight, git-based CLI system for capturing, structuring, and reusing knowledge.

It is designed to be:
- shell-first
- low-friction for daily use
- file-based and editor-agnostic
- explicit about context through scopes

## Core Idea

`k` is not a database and not a notebook platform.

> `k` is a workflow wrapper around Markdown + Git.

It combines:
- journal notes for raw thinking
- entries for structured knowledge
- todos for concrete next actions
- scopes for explicit context

## Storage Layout

Repository content lives in `~/.k/repo`:

```text
~/.k/repo/
  journal/
  entries/
  drafts/
  todos/
```

Local metadata lives in `~/.k/.knowledge`:

```text
~/.k/.knowledge/
  config
  current_scope
  templates/
```

Repository-level shared metadata lives in `~/.k/repo`:

```text
~/.k/repo/
  scopes.txt
  tags.txt
```

`.knowledge` is local machine-specific state and editor/config metadata.

## Concepts

### Journal

- one file per day
- append-first
- used for quick capture

Example:

```md
## 20:41 [question] [scope:work/project1-work]
How should we model UUID externally and Long internally?
```

### Entries

Structured knowledge entries:

- `problem`
- `solution`
- `insight`
- `decision`
- `idea`
- `project`

Drafts are created first and finalized later.

### Todos

Todos are scope-based and stored separately from the journal.

The current workflow supports:
- `Open`
- `In Progress`
- `Done`

### Scope

Scope is the context anchor for most commands.

Format:

```text
<domain>/<system>
```

Examples:

- `private/project1`
- `work/project1-work`
- `common/git`

## Commands

```bash
k help
k help todo
k completion bash

k setup

k scope list
k scope show
k scope use private/project1
k scope clear

k draft list
k draft list --scope private/project1

k jot "text"
k jot --kind question "text"
k jot --kind todo --scope work/project1-work "text"

k today
k today --edit
k resume
k resume --scope common/git

k new problem "title" --edit
k save --latest
k save --file ~/.k/repo/drafts/2026-03-26-1015-sample.md

k todo add "task"
k todo list
k todo start
k todo done 0
k todo reopen

k wrap
k find query
```

Global verbosity flags:

```bash
k -v setup
k -vv setup
k -vvv setup
```

Shell completion for Bash:

```bash
source <(k completion bash)
```

Or persist it:

```bash
k completion bash > ~/.k-completion.bash
echo 'source ~/.k-completion.bash' >> ~/.bashrc
```

## Current Workflow

### Setup

`k setup` creates the canonical repository at `~/.k/repo` and local metadata at `~/.k/.knowledge`.

During setup, `k` currently:
- prepares the repository structure
- optionally initializes Git
- optionally configures the `origin` remote
- sets the environment name
- optionally sets a default scope
- installs default templates

### Capture

Use `jot` for low-friction capture:

```bash
k jot "Quick thought"
k jot --kind question "Why does this fail?"
k jot --kind todo "Check middleware name"
```

### Structured Knowledge

Create a draft entry and finalize it later:

```bash
k new problem "Traefik auth does not apply" --edit
k draft list
k save --latest --tags infra,traefik,auth
```

### Todo Workflow

The current todo flow is:

```bash
k todo add "Investigate auth issue"
k todo start
k todo done
k todo reopen
```

If no index is given, `0` is treated as the default and resolves to the first item in the relevant section.

### Resume

`k resume` currently shows:
- the active scope
- todo counts
- recent journal lines for the scope from today
- in-progress todos
- open todos
- matching drafts
- the latest matching finalized entry
- the latest wrap from today

This is the current implementation, not a full historical context reconstruction yet.

## Templates

Templates are stored in:

```text
~/.k/.knowledge/templates/
```

The default set is:
- `header.md`
- `problem.md`
- `solution.md`
- `insight.md`
- `decision.md`
- `idea.md`
- `project.md`

Templates are combined when creating a draft entry, not included dynamically at render time.

## Design Principles

1. Minimal structure, enough to stay useful.
2. Capture first, curate later.
3. Git handles history and sync.
4. Markdown stays readable without `k`.
5. Scope is explicit context, not hidden magic.

## Current Limits

- no GUI
- no database
- no cloud sync
- no AI integration
- no advanced task management
- `find` is plain text search over repository content
- `resume` is centered on the current day, not full history

## Testing

Run the local smoke tests with:

```bash
bash tests/test_cli.sh
```

## Future Developments

Potential next steps:
- filtered search by kind and scope
- metadata-aware search for tags and frontmatter
- guided scope suggestions and shell completion
- promotion flows from journal to entry

## Summary

`k` is a lightweight CLI knowledge system centered on Markdown, Git, scopes, and low-friction daily use.
