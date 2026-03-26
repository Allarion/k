# Projekt: k – CLI Knowledge System

## Überblick

**k** ist ein leichtgewichtiges, git-basiertes CLI-Tool zur Erfassung, Strukturierung und Wiederverwendung von Wissen.

Ziel ist es, ein System zu schaffen, das:
- im Alltag tatsächlich benutzt wird
- minimale Reibung beim Erfassen hat
- Kontextverlust reduziert
- vollständig dateibasiert und tool-agnostisch ist

---

## Kernidee

k ist kein neues Datenbanksystem und kein Notion-Klon.

> k ist ein Workflow-Wrapper um Markdown + Git.

Es kombiniert:
- Journal (Denken)
- Entries (Wissen)
- Todos (Handlung)
- Scope (Kontext)

---

## Ziele

### Primär

- Schnelles Erfassen von Gedanken (\`k jot\`)
- Kontext wiederfinden (\`k resume\`)
- Tagesabschluss erzwingen (\`k wrap\`)
- Wissen strukturiert ablegen (\`k new\` + \`k save\`)

### Sekundär

- Shell-first Nutzung
- Editor-agnostisch
- Git als Historie
- Offline-first

---

## Nicht-Ziele (v1)

- Keine GUI
- Keine Datenbank
- Keine Cloud-Synchronisation
- Keine AI-Integration
- Kein komplexes Task-Management

---

## Konzepte

### 1. Journal

- global pro Tag
- append-only
- enthält rohe Gedanken

Beispiel:

```md
## 20:41 [question] [scope:work/bgprevent]
Wie modellieren wir UUID außen und Long innen?
```

---

### 2. Entries

Strukturierte Wissenseinträge:

- problem
- solution
- insight
- decision
- idea
- project

Diese sind:
- kuratiert
- versioniert
- wiederverwendbar

---

### 3. Todos

- scope-basiert
- konkrete nächste Schritte
- getrennt vom Journal

---

### 4. Scope

Kontextanker für alles.

Format:

```text
<domain>/<system>
```

Beispiele:

- private/arx
- work/bgprevent
- shared/git

---

## Architektur

### Dateibasiert

Alle Daten liegen als Markdown im Repository.

```text
knowledge/
  journal/
  entries/
  drafts/
  todos/
  .knowledge/
```

---

### Git als Backbone

Git übernimmt:
- Historie
- Versionierung
- Sync

k übernimmt:
- Struktur
- Defaults
- Workflow

---

## CLI Design

### Prinzipien

- kurze Befehle
- wenig Argumente
- sinnvolle Defaults
- shell-friendly

---

### Kernbefehle

```bash
k scope use private/arx
k resume
k jot "text"
k new problem "title"
k save
k todo add "task"
k wrap
k today
k find query
```

---

## Templates

Templates liegen in:

```text
.knowledge/templates/
```

Bestehend aus:
- header.md
- problem.md
- solution.md
- insight.md
- decision.md
- idea.md
- project.md

Templates werden **zur Erstellungszeit kombiniert**, nicht zur Laufzeit inkludiert.

---

## Workflow

### Einstieg

```bash
k resume
```

### Während der Arbeit

```bash
k jot "Gedanke"
k jot --kind todo "Task"
```

### Wissen festhalten

```bash
k new problem "..."
k save
```

### Tagesabschluss

```bash
k wrap
```

---

## Designprinzipien

### 1. Minimalismus

So wenig Struktur wie möglich, so viel wie nötig.

### 2. Append-first

Erst erfassen, später strukturieren.

### 3. Git-first

Keine eigene Historie bauen.

### 4. Tool-agnostisch

Markdown bleibt lesbar ohne k.

### 5. Kontext statt Magie

Scope ersetzt implizite Intelligenz.

---

## Erweiterungen (später)

- Journal → Entry Promotion
- bessere Suche
- automatische Vorschläge
- Analyse über Journal-Daten
- optionale UI (z. B. Obsidian)

---

## Fazit

k ist:

> ein leichtgewichtiges, git-basiertes CLI-System zur Erfassung und Strukturierung von Wissen mit Fokus auf tatsächliche Nutzung.

Nicht mehr.
Nicht weniger.

