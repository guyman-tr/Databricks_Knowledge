-- =============================================================================
-- monitoring-genie-logs — DDL for capture + watermark tables
-- =============================================================================
-- Two environments per NamingConvention (de_output / de_output_stg).
-- Storage roots:
--   STG:  abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/...
--   PROD: abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/...
-- ADLS path: DE_OUTPUT/Monitoring/Genie_Logs/{Genie_Gateway|Watermark}/
-- UC name  : de_output_monitoring_genie_logs_{genie_gateway|watermark}
-- =============================================================================
-- Idempotent; safe to re-run. The notebook calls this on startup.
-- =============================================================================

-- ---- STG -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS main.de_output_stg.de_output_monitoring_genie_logs_genie_gateway (
  ts                          TIMESTAMP   COMMENT 'Message creation time from Genie API (created_timestamp), UTC.',
  genie_mode                  STRING      COMMENT 'genie_space | genie_agent | deep_research. Derived from the audit-log action_name family + conversation_type.',
  workspace_id                STRING      COMMENT 'Databricks workspace_id from genie_audit_events.',
  space_id                    STRING      COMMENT 'Genie space identifier.',
  space_name                  STRING      COMMENT 'Genie space display name (joined from main.monitoring.genie_spaces_dim).',
  conversation_id             STRING      COMMENT 'Genie conversation identifier.',
  conversation_type           STRING      COMMENT 'NORMAL | DEEP_RESEARCH (from audit-log createConversation.request_params).',
  message_id                  STRING      COMMENT 'Genie message identifier. Natural key for this row.',
  user_email                  STRING      COMMENT 'Owning user email.',
  nl_prompt                   STRING      COMMENT 'The user-typed natural-language question (Genie API message.content). NULL for assistant messages.',
  nl_response_summary         STRING      COMMENT 'Genie assistant text response (concat of attachments[*].text.content). NULL when only SQL attachments are present.',
  generated_sql               STRING      COMMENT 'Genie-generated SQL (attachments[*].query.query). NULL for text-only answers.',
  query_description           STRING      COMMENT 'Genie attachments[*].query.description, the human-readable explanation of what the SQL does.',
  attachment_count            INT         COMMENT 'Number of attachments on the message.',
  attachment_kinds            STRING      COMMENT 'Comma-joined attachment kinds (e.g. "query,text").',
  message_status              STRING      COMMENT 'Genie message.status (COMPLETED | FAILED | CANCELLED | EXECUTING_QUERY | ...).',
  error_message               STRING      COMMENT 'Genie message.error.error, when present.',
  statement_id                STRING      COMMENT 'system.query.history.statement_id of the executed SQL (single best match by space_id+user+window).',
  total_duration_ms           BIGINT      COMMENT 'Execution time of statement_id from system.query.history.',
  read_rows                   BIGINT      COMMENT 'Rows scanned (system.query.history).',
  produced_rows               BIGINT      COMMENT 'Rows produced (system.query.history).',
  read_bytes                  BIGINT      COMMENT 'Bytes scanned (system.query.history).',
  from_result_cache           BOOLEAN     COMMENT 'True if served from result cache.',
  pruned_files                BIGINT      COMMENT 'Pruned files count.',
  warehouse_id                STRING      COMMENT 'SQL warehouse that executed the query.',
  thumb_up                    BOOLEAN     COMMENT 'User gave thumbs up (from updateConversationMessageFeedback audit events).',
  thumb_down                  BOOLEAN     COMMENT 'User gave thumbs down.',
  feedback_comment            STRING      COMMENT 'Free-text feedback if provided.',
  raw_message_json            STRING      COMMENT 'Full Genie API response for replay / debug (JSON string, may be truncated to 64KB).',
  ingested_at                 TIMESTAMP   COMMENT 'When this row was last written by the capture job.',
  UpdateDate                  TIMESTAMP   COMMENT 'Mandatory DE convention: write-time timestamp set via current_timestamp().'
)
USING DELTA
LOCATION 'abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Genie_Gateway/'
COMMENT 'Daily-captured Genie conversation log. One row per Genie message, joining audit-log enumeration + Genie REST API content + system.query.history execution metrics. Sibling concept to main.config.monitoring_mcp_logs_mcp_gateway. Owner: data-platform. Source: main.monitoring.genie_audit_events + Genie API + system.query.history.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'sla' = 'D+1 09:00 UTC',
  'source_system' = 'genie_audit + genie_api + system.query.history',
  'pii' = 'indirect',
  'certified' = 'silver',
  'data_classification' = 'internal',
  'domain' = 'platform-observability',
  'layer' = 'gateway'
);

CREATE TABLE IF NOT EXISTS main.de_output_stg.de_output_monitoring_genie_logs_watermark (
  env                         STRING      COMMENT 'stg | prod — which target the run wrote to.',
  run_id                      STRING      COMMENT 'Unique id for this run (job_run_id or notebook timestamp).',
  run_start                   TIMESTAMP   COMMENT 'Run start.',
  run_end                     TIMESTAMP   COMMENT 'Run end.',
  audit_low_watermark         TIMESTAMP   COMMENT 'Earliest event_time considered by this run.',
  audit_high_watermark        TIMESTAMP   COMMENT 'Latest event_time considered by this run. Next run uses this as its low watermark.',
  messages_seen               INT         COMMENT 'Distinct message_ids in the audit-log window.',
  messages_fetched            INT         COMMENT 'message_ids successfully fetched from Genie API.',
  messages_skipped            INT         COMMENT 'message_ids skipped (already current or out-of-scope mode).',
  api_errors                  INT         COMMENT 'message_ids that returned an error from the Genie API.',
  rows_merged                 INT         COMMENT 'Rows MERGEd into the gateway table.',
  notes                       STRING      COMMENT 'Free-form notes (failed conversation_ids, etc.).',
  UpdateDate                  TIMESTAMP   COMMENT 'Mandatory DE convention.'
)
USING DELTA
LOCATION 'abfss://analysis@stgdpdlwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Watermark/'
COMMENT 'Per-run watermarks for monitoring-genie-logs capture job. Last successful run controls the next run''s low watermark.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'source_system' = 'job-internal',
  'pii' = 'none',
  'certified' = 'bronze',
  'data_classification' = 'internal'
);

-- ---- PROD ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS main.de_output.de_output_monitoring_genie_logs_genie_gateway (
  ts                          TIMESTAMP   COMMENT 'Message creation time from Genie API (created_timestamp), UTC.',
  genie_mode                  STRING      COMMENT 'genie_space | genie_agent | deep_research. Derived from the audit-log action_name family + conversation_type.',
  workspace_id                STRING      COMMENT 'Databricks workspace_id from genie_audit_events.',
  space_id                    STRING      COMMENT 'Genie space identifier.',
  space_name                  STRING      COMMENT 'Genie space display name (joined from main.monitoring.genie_spaces_dim).',
  conversation_id             STRING      COMMENT 'Genie conversation identifier.',
  conversation_type           STRING      COMMENT 'NORMAL | DEEP_RESEARCH (from audit-log createConversation.request_params).',
  message_id                  STRING      COMMENT 'Genie message identifier. Natural key for this row.',
  user_email                  STRING      COMMENT 'Owning user email.',
  nl_prompt                   STRING      COMMENT 'The user-typed natural-language question (Genie API message.content). NULL for assistant messages.',
  nl_response_summary         STRING      COMMENT 'Genie assistant text response (concat of attachments[*].text.content). NULL when only SQL attachments are present.',
  generated_sql               STRING      COMMENT 'Genie-generated SQL (attachments[*].query.query). NULL for text-only answers.',
  query_description           STRING      COMMENT 'Genie attachments[*].query.description, the human-readable explanation of what the SQL does.',
  attachment_count            INT         COMMENT 'Number of attachments on the message.',
  attachment_kinds            STRING      COMMENT 'Comma-joined attachment kinds (e.g. "query,text").',
  message_status              STRING      COMMENT 'Genie message.status (COMPLETED | FAILED | CANCELLED | EXECUTING_QUERY | ...).',
  error_message               STRING      COMMENT 'Genie message.error.error, when present.',
  statement_id                STRING      COMMENT 'system.query.history.statement_id of the executed SQL (single best match by space_id+user+window).',
  total_duration_ms           BIGINT      COMMENT 'Execution time of statement_id from system.query.history.',
  read_rows                   BIGINT      COMMENT 'Rows scanned (system.query.history).',
  produced_rows               BIGINT      COMMENT 'Rows produced (system.query.history).',
  read_bytes                  BIGINT      COMMENT 'Bytes scanned (system.query.history).',
  from_result_cache           BOOLEAN     COMMENT 'True if served from result cache.',
  pruned_files                BIGINT      COMMENT 'Pruned files count.',
  warehouse_id                STRING      COMMENT 'SQL warehouse that executed the query.',
  thumb_up                    BOOLEAN     COMMENT 'User gave thumbs up.',
  thumb_down                  BOOLEAN     COMMENT 'User gave thumbs down.',
  feedback_comment            STRING      COMMENT 'Free-text feedback if provided.',
  raw_message_json            STRING      COMMENT 'Full Genie API response for replay / debug (JSON string, may be truncated to 64KB).',
  ingested_at                 TIMESTAMP   COMMENT 'When this row was last written by the capture job.',
  UpdateDate                  TIMESTAMP   COMMENT 'Mandatory DE convention.'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Genie_Gateway/'
COMMENT 'Daily-captured Genie conversation log. One row per Genie message, joining audit-log enumeration + Genie REST API content + system.query.history execution metrics. Sibling concept to main.config.monitoring_mcp_logs_mcp_gateway. Owner: data-platform.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'sla' = 'D+1 09:00 UTC',
  'source_system' = 'genie_audit + genie_api + system.query.history',
  'pii' = 'indirect',
  'certified' = 'silver',
  'data_classification' = 'internal',
  'domain' = 'platform-observability',
  'layer' = 'gateway'
);

CREATE TABLE IF NOT EXISTS main.de_output.de_output_monitoring_genie_logs_watermark (
  env                         STRING      COMMENT 'stg | prod — which target the run wrote to.',
  run_id                      STRING      COMMENT 'Unique id for this run (job_run_id or notebook timestamp).',
  run_start                   TIMESTAMP   COMMENT 'Run start.',
  run_end                     TIMESTAMP   COMMENT 'Run end.',
  audit_low_watermark         TIMESTAMP   COMMENT 'Earliest event_time considered by this run.',
  audit_high_watermark        TIMESTAMP   COMMENT 'Latest event_time considered by this run.',
  messages_seen               INT         COMMENT 'Distinct message_ids in the audit-log window.',
  messages_fetched            INT         COMMENT 'message_ids successfully fetched from Genie API.',
  messages_skipped            INT         COMMENT 'message_ids skipped (already current).',
  api_errors                  INT         COMMENT 'message_ids that returned an error from the Genie API.',
  rows_merged                 INT         COMMENT 'Rows MERGEd into the gateway table.',
  notes                       STRING      COMMENT 'Free-form notes.',
  UpdateDate                  TIMESTAMP   COMMENT 'Mandatory DE convention.'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Monitoring/Genie_Logs/Watermark/'
COMMENT 'Per-run watermarks for monitoring-genie-logs capture job.'
TBLPROPERTIES (
  'refresh_frequency' = 'daily',
  'source_system' = 'job-internal',
  'pii' = 'none',
  'certified' = 'bronze',
  'data_classification' = 'internal'
);
