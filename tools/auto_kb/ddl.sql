-- auto_kb run-log tables (AUTONOMOUS WATCHER OUTPUT, one row per processed delta)
-- Target schema: main.de_output
--
-- HARD RULE:
--   These tables are scanned by "Corrupted tables maintenance".
--   They MUST remain EXTERNAL and naming/location compliant or they will be dropped.
--   Purge formula: table name == location path segments under the analysis
--   container joined by '_', lowercased. Validate every table below with:
--     python tools/skill_suggestions/validate_external_name.py \
--       --schema de_output --table-name <name> --location <abfss...> --json
--   (or programmatically via tools.auto_kb.runlog.assert_naming_compliant)
--
-- Uses the existing de_output external location parent:
--   abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/...

CREATE SCHEMA IF NOT EXISTS main.de_output;

-- App 1: Genie Spaces Watcher
--   LOCATION .../DE_OUTPUT/Auto_Kb/Genie_Runs/ -> de_output_auto_kb_genie_runs
CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_auto_kb_genie_runs (
  run_id       STRING    NOT NULL COMMENT 'Cycle run identifier',
  app          STRING    NOT NULL COMMENT 'Watcher app key (genie)',
  item_id      STRING    NOT NULL COMMENT 'Deterministic item id (app:kind:key)',
  item_kind    STRING             COMMENT 'genie_new | genie_changed',
  title        STRING             COMMENT 'Human-readable item title',
  detected_at  TIMESTAMP          COMMENT 'When the delta was detected',
  status       STRING    NOT NULL COMMENT 'new | processing | done | skipped | error',
  artifact_ref STRING             COMMENT 'Skill id / domain / wiki path touched',
  pr_url       STRING             COMMENT 'Opened DataPlatform PR URL, if any',
  notes        STRING             COMMENT 'Execution diagnostics',
  processed_at TIMESTAMP          COMMENT 'Completion timestamp'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Genie_Runs/';

-- App 2: Unity Catalog Object + Pipeline Watcher
--   LOCATION .../DE_OUTPUT/Auto_Kb/Uc_Object_Runs/ -> de_output_auto_kb_uc_object_runs
CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_auto_kb_uc_object_runs (
  run_id       STRING    NOT NULL COMMENT 'Cycle run identifier',
  app          STRING    NOT NULL COMMENT 'Watcher app key (uc_object)',
  item_id      STRING    NOT NULL COMMENT 'Deterministic item id (app:kind:key)',
  item_kind    STRING             COMMENT 'uc_new_object | uc_changed_object',
  title        STRING             COMMENT 'Human-readable item title (catalog.schema.table)',
  detected_at  TIMESTAMP          COMMENT 'When the delta was detected',
  status       STRING    NOT NULL COMMENT 'new | processing | done | skipped | error',
  artifact_ref STRING             COMMENT 'Wiki path / skill id / domain touched',
  pr_url       STRING             COMMENT 'Opened DataPlatform PR URL, if any',
  notes        STRING             COMMENT 'Execution diagnostics',
  processed_at TIMESTAMP          COMMENT 'Completion timestamp'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Uc_Object_Runs/';

-- App 3: DB-Schema Lake Wiki Watcher
--   LOCATION .../DE_OUTPUT/Auto_Kb/Dbschema_Runs/ -> de_output_auto_kb_dbschema_runs
CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_auto_kb_dbschema_runs (
  run_id       STRING    NOT NULL COMMENT 'Cycle run identifier',
  app          STRING    NOT NULL COMMENT 'Watcher app key (dbschema)',
  item_id      STRING    NOT NULL COMMENT 'Deterministic item id (app:kind:key)',
  item_kind    STRING             COMMENT 'dbschema_new_wiki | dbschema_changed_wiki',
  title        STRING             COMMENT 'Human-readable item title (DB.Schema.Object)',
  detected_at  TIMESTAMP          COMMENT 'When the delta was detected',
  status       STRING    NOT NULL COMMENT 'new | processing | done | skipped | error',
  artifact_ref STRING             COMMENT 'Skill id / domain / lake FQN touched',
  pr_url       STRING             COMMENT 'Opened DataPlatform PR URL, if any',
  notes        STRING             COMMENT 'Execution diagnostics',
  processed_at TIMESTAMP          COMMENT 'Completion timestamp'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Dbschema_Runs/';

-- App 4: Confluence Delta Watcher
--   LOCATION .../DE_OUTPUT/Auto_Kb/Confluence_Runs/ -> de_output_auto_kb_confluence_runs
CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_auto_kb_confluence_runs (
  run_id       STRING    NOT NULL COMMENT 'Cycle run identifier',
  app          STRING    NOT NULL COMMENT 'Watcher app key (confluence)',
  item_id      STRING    NOT NULL COMMENT 'Deterministic item id (app:kind:key)',
  item_kind    STRING             COMMENT 'confluence_new_page | confluence_changed_page',
  title        STRING             COMMENT 'Human-readable item title (page title)',
  detected_at  TIMESTAMP          COMMENT 'When the delta was detected',
  status       STRING    NOT NULL COMMENT 'new | processing | done | skipped | error',
  artifact_ref STRING             COMMENT 'Skill id / domain / evidence path touched',
  pr_url       STRING             COMMENT 'Opened DataPlatform PR URL, if any',
  notes        STRING             COMMENT 'Execution diagnostics',
  processed_at TIMESTAMP          COMMENT 'Completion timestamp'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Confluence_Runs/';

-- App 5: Questions Watcher
--   LOCATION .../DE_OUTPUT/Auto_Kb/Questions_Runs/ -> de_output_auto_kb_questions_runs
CREATE EXTERNAL TABLE IF NOT EXISTS main.de_output.de_output_auto_kb_questions_runs (
  run_id       STRING    NOT NULL COMMENT 'Cycle run identifier',
  app          STRING    NOT NULL COMMENT 'Watcher app key (questions)',
  item_id      STRING    NOT NULL COMMENT 'Deterministic item id (app:kind:intent-signature)',
  item_kind    STRING             COMMENT 'questions_new_intent | questions_changed_intent',
  title        STRING             COMMENT 'Human-readable intent label + coverage status',
  detected_at  TIMESTAMP          COMMENT 'When the delta was detected',
  status       STRING    NOT NULL COMMENT 'new | processing | done | skipped | error',
  artifact_ref STRING             COMMENT 'Gap dossier path / proposed domain / skill id touched',
  pr_url       STRING             COMMENT 'Opened DataPlatform PR URL, if any (tracker proposes only)',
  notes        STRING             COMMENT 'Execution diagnostics (denoised intent only, no PII)',
  processed_at TIMESTAMP          COMMENT 'Completion timestamp'
)
USING DELTA
LOCATION 'abfss://analysis@dldataplatformprodwe.dfs.core.windows.net/DE_OUTPUT/Auto_Kb/Questions_Runs/';
