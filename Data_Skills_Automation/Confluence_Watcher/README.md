# Confluence Delta Watcher

Diff-driven autonomous flow: detect new / changed Confluence pages by **version**
and, for pages that back a skill (or are otherwise tracked), conditionally amend
the skill and push. Deliberately **not** a spray-and-pray Rovo search -- it acts
only on genuine version deltas, and only tracked/skill-backing pages produce a
push.

Built on the shared engine in [tools/auto_kb/](../../tools/auto_kb).

## MCP-session dependency (read this first)

Atlassian access is via the **interactive Atlassian MCP**, which is not available
to a headless python process. So this watcher is **snapshot-file-driven**:

1. Inside Cursor (MCP connected), export current page metadata:
   - `searchConfluenceUsingCql` with a `lastmodified >= <watermark>` clause over
     the watched space(s),
   - `getConfluencePage` per hit to capture `version` + `title`,
   - write `{"pages":[{page_id,space_key,title,version,last_modified,url,tracked_skill?}]}`.
2. Run this watcher with `--current <that snapshot>`.

There is no `--current`-less live mode; omitting it exits with guidance. If
maintaining the MCP export step is not worth it, this is the app to skip -- the
other three run headlessly.

## Value gate

| Page | Outcome |
|---|---|
| tracked (`tracked_skill` set) + changed/new | `done` -- amend skill + conditional push |
| untracked | `skipped` -- logged only, never blindly ingested |

## State

| What | Where |
|---|---|
| current | `--current <json>` (MCP-produced metadata snapshot) -- REQUIRED |
| baseline snapshot | `Data_Skills_Automation/Confluence_Watcher/state/snapshot.json` |
| evidence cache | `knowledge/confluence/_corpus/<domain>/<page_id>.json` |
| run-log | `main.de_output.de_output_auto_kb_confluence_runs` (external, anti-purge compliant) |

## Run

Dry-run (offline):

```bash
python Data_Skills_Automation/Confluence_Watcher/watch.py \
    --current Data_Skills_Automation/Confluence_Watcher/fixtures/current_pages.json \
    --snapshot Data_Skills_Automation/Confluence_Watcher/fixtures/_tmp_snapshot.json \
    --dry-run --no-notify --no-runlog \
    --manifest-out Data_Skills_Automation/Confluence_Watcher/out/manifest.json
```

Live (requires the Atlassian MCP session + `CURSOR_API_KEY`):

```bash
python Data_Skills_Automation/Confluence_Watcher/watch.py \
    --current <mcp_metadata_snapshot.json> --workspace-cwd .
```

## Schedule

Daily, gated on the MCP metadata export step. The snapshot advances only on a
fully successful live run.
