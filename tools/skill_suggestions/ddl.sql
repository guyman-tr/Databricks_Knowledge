-- Skill suggestions storage (AUTONOMOUS AGENT INPUT QUEUE)
-- Target schema: main.de_output
--
-- HARD RULE:
--   This table is scanned by "Corrupted tables maintenance".
--   It MUST remain EXTERNAL and naming/location compliant or it will be dropped.
--
-- Name formula check for this table:
--   LOCATION .../skill_suggestions/  -> expected table name: skill_suggestions
--
-- Before running, set a valid container name used in your workspace.
-- Example: internal-sources (non external-sources container keeps start_index=3).

CREATE SCHEMA IF NOT EXISTS main.de_output;

CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.skill_suggestions (
  id STRING NOT NULL COMMENT 'UUID for submission request',
  submitted_at TIMESTAMP NOT NULL COMMENT 'Request creation timestamp',
  submitter STRING COMMENT 'Human submitter identity',
  request_type STRING NOT NULL COMMENT 'new_skill | correction',
  target_skill STRING COMMENT 'Existing skill id for correction flow',
  title STRING COMMENT 'Short request title',
  body_text STRING COMMENT 'Correction text or inline markdown payload',
  volume_path STRING COMMENT 'Volume folder for uploaded markdown files',
  status STRING NOT NULL COMMENT 'new | processing | pushed | skipped_overlap | error',
  pr_url STRING COMMENT 'Opened DataPlatform PR URL',
  processed_at TIMESTAMP COMMENT 'Completion timestamp',
  agent_notes STRING COMMENT 'Execution diagnostics'
)
USING DELTA
LOCATION 'abfss://<container>@dldataplatformprodwe.dfs.core.windows.net/skill_suggestions/';

CREATE EXTERNAL VOLUME IF NOT EXISTS main.de_output.skill_submissions
COMMENT 'Uploaded markdown bundles for skill suggestion submissions'
LOCATION 'abfss://<container>@dldataplatformprodwe.dfs.core.windows.net/skill_submissions/';

-- Optional: add table to purge whitelist as defense-in-depth.
-- The true fix is still naming + location compliance above.
-- Whitelist format in maintenance notebook: 'de_output.skill_suggestions'
