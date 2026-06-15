# monitoring-genie-logs

Sibling-to-MCP-logs Genie conversation capture. Logs every Genie message — NL prompt, generated SQL,
execution metrics — into a UC Delta table, runs daily.

## Why

`main.config.monitoring_mcp_logs_mcp_gateway` already captures every MCP call (NL prompt → tool result).
For Genie there was no equivalent: `system.query.history` shows only the **generated SQL** with
`client_application IN ('Databricks SQL Genie Space','DatabricksGenie')`, never the natural-language
question the user actually typed.

This job fixes that by stitching three sources together:

| Source | Provides |
|---|---|
| `main.monitoring.genie_audit_events` | Complete enumeration of every `(space_id, conversation_id, message_id)` tuple that exists |
| Genie REST API (`w.genie.get_message`) | NL prompt, generated SQL, text responses, attachments, status, errors |
| `system.query.history` | Execution metrics (latency, rows, bytes, warehouse, result-cache) joined on `statement_id` |

Result: one row per Genie message in `main.de_output.de_output_monitoring_genie_logs_genie_gateway` (PROD)
or `main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway` (STG).

## Layout

```
dab/monitoring-genie-logs/
├── databricks.yml                          # bundle + targets (stg, prod)
├── resources/
│   └── jobs.yml                            # daily-capture job definition
├── notebooks/
│   └── genie_logs_daily_capture.py         # the actual notebook (cell-formatted .py)
├── sql/
│   └── 01_create_tables.sql                # standalone DDL (notebook also self-bootstraps)
└── README.md                               # this file
```

## Naming (per `_de_existing/NamingConvention`)

| Object | UC FQN | ADLS location |
|---|---|---|
| Gateway STG  | `main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway` | `abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Genie_Gateway/` |
| Gateway PROD | `main.de_output.de_output_monitoring_genie_logs_genie_gateway`     | `abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Genie_Gateway/` |
| Watermark STG  | `main.de_output_stg.de_output_monitoring_genie_logs_watermark` | `.../DE_OUTPUT/Monitoring/Genie_Logs/Watermark/` (stgdpdlwe) |
| Watermark PROD | `main.de_output.de_output_monitoring_genie_logs_watermark`     | `.../DE_OUTPUT/Monitoring/Genie_Logs/Watermark/` (dldataplatformprodwe) |

All persistent tables include the mandatory `UpdateDate TIMESTAMP` column per the DE convention.

## Deploy

From `dab/monitoring-genie-logs/`. Set `DATABRICKS_BUNDLE_ENGINE=direct` to bypass the
Terraform engine (the bundled Terraform key is expired on CLI 0.295.x); deploys use
the direct-API path instead.

### STG (current state — already deployed)

```bash
$env:DATABRICKS_BUNDLE_ENGINE = "direct"
databricks bundle validate --profile guyman -t stg
databricks bundle deploy   --profile guyman -t stg
databricks bundle run monitoring_genie_logs_daily_capture --profile guyman -t stg --no-wait
```

STG schedule fires daily at 06:00 UTC. Last verified run: 1,225 messages captured in ~4.5 min,
1,197 NL prompts, 524 generated SQL, 470 fully joined to `system.query.history`.

### PROD (NOT YET DEPLOYED — opt-in)

Production is intentionally **not** deployed yet. To roll out:

```bash
$env:DATABRICKS_BUNDLE_ENGINE = "direct"
databricks bundle validate --profile guyman -t prod
databricks bundle deploy   --profile guyman -t prod
databricks bundle run monitoring_genie_logs_daily_capture --profile guyman -t prod --no-wait
```

To roll back / take down a deployed target:

```bash
databricks bundle destroy  --profile guyman -t prod --auto-approve
```

The prod schedule (in `resources/jobs.yml`) fires at 06:30 UTC daily — that only matters
once you actually deploy it.

## Parameters

The notebook accepts four widgets (overridable per run):

| Widget | Default | Meaning |
|---|---|---|
| `env` | `stg` | Target environment (controls schema + ADLS path). |
| `backfill_days` | `7` | Only used on first run (when watermark table is empty). |
| `max_messages` | `5000` | Per-run safety cap. |
| `dry_run` | `false` | If `true`, skip MERGE and watermark write. |

## Modes captured

Each row gets a `genie_mode` value:

| Mode | Meaning | `client_application` in query.history |
|---|---|---|
| `genie_space` | Classic Genie space UI | `Databricks SQL Genie Space` |
| `genie_agent` | Genie called via SDK / Agent Bricks | `DatabricksGenie` |
| `deep_research` | Conversation started with `conversation_type = DEEP_RESEARCH` | varies |

## Caveats

1. **Permissions.** The job runs as the deploying user. They need:
   - SELECT on `main.monitoring.genie_audit_events`, `main.monitoring.genie_spaces_dim`, `system.query.history`
   - USE CATALOG `main` + USE SCHEMA `de_output[_stg]` + CREATE / MODIFY on the gateway + watermark tables
   - READ FILES + WRITE FILES on the ADLS path (`DE_OUTPUT/Monitoring/Genie_Logs/...`)
   - Workspace-level access to every Genie space whose messages we fetch. **Spaces the user can't read will surface as `api_errors`** in the watermark row; check the run summary to triage.
2. **Audit-log retention.** `genie_audit_events` may have its own retention policy. If audit-log retention < backfill window, older messages are unreachable.
3. **Statement-id linkage.** Today we use `query_result_metadata.statement_id` (when the Genie API returns it). If a message has no executed SQL (text-only Genie response, error, or canceled), `statement_id` is NULL — this is normal.
4. **Idempotency.** MERGE on `message_id`. Safe to re-run the same window; rows are updated in place.

## Source-of-truth for the audit-log schema

`DESCRIBE TABLE main.monitoring.genie_audit_events` — these are the columns we lean on:

```
event_date date  PARTITION KEY
event_time timestamp
event_id   string
workspace_id string
user_email string
action_name string         -- createConversation, createConversationMessage, getMessageAttachmentQueryResult, ...
space_id   string
conversation_id string
message_id string
feedback_rating string
response_status int
request_params map<string,string>  -- carries space_id / conversation_id / conversation_type / attachment_id but NOT NL prompt content
```
