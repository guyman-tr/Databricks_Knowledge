-- Skills automation user submission storage (AUTONOMOUS AGENT INPUT QUEUE)
-- Target schema: main.de_output
--
-- HARD RULE:
--   This table is scanned by "Corrupted tables maintenance".
--   It MUST remain EXTERNAL and naming/location compliant or it will be dropped.
--
-- Name formula check for this table:
--   LOCATION .../DE_OUTPUT/Skills_Automation/User_Suggestions_Agent/
--   -> expected table name: de_output_skills_automation_user_suggestions_agent
--
-- Uses existing de_output external location parent:
--   abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/...

CREATE SCHEMA IF NOT EXISTS main.de_output;

CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_skills_automation_user_suggestions_agent (
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
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Skills_Automation/User_Suggestions_Agent/';

CREATE EXTERNAL VOLUME IF NOT EXISTS main.de_output.skills_automation_user_suggestions_agent_files
COMMENT 'Uploaded markdown bundles for skill suggestion submissions'
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Skills_Automation/User_Suggestions_Agent_Files/';

-- Optional: add table to purge whitelist as defense-in-depth.
-- The true fix is still naming + location compliance above.
-- Whitelist format in maintenance notebook:
-- 'de_output.de_output_skills_automation_user_suggestions_agent'
