-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_errormessage
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ErrorMessage.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_errormessage SET TBLPROPERTIES (
    'comment' = 'A configuration table storing parameterized message templates for server-side logging and error reporting, organized by server type and message ID. Rather than hardcoding log messages in server code, message templates are stored centrally. Each server component uses its server type + message ID pair to look up the appropriate template, then fills in parameters at runtime. This enables consistent logging formats and makes it possible to update message text without redeploying server binaries. Referenced by `History.ErrorLogAdd` (writes error log entries using these templates) and `Broker.actDispatcher` (dispatches messages based on server type and message ID). The `ServerTypeID` FK points to `Dictionary.ServerType` which identifies the source server component.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_errormessage ALTER COLUMN ErrorMessageID COMMENT 'Primary key. Global sequential message identifier (1-98 with gaps).';
ALTER TABLE main.general.bronze_etoro_dictionary_errormessage ALTER COLUMN ServerTypeID COMMENT 'FK to Dictionary.ServerType. Identifies which server component owns this message template. Values: 2 (Distributor), 6 (HedgeServer), 7 (PriceServer), 8 (PriceProviders), 13 (PriceDetector).';
ALTER TABLE main.general.bronze_etoro_dictionary_errormessage ALTER COLUMN ServerMessageID COMMENT 'Server-local message sequence number. Unique within each ServerTypeID. Range varies per server (1-46 for HedgeServer, 1-24 for PriceServer).';
ALTER TABLE main.general.bronze_etoro_dictionary_errormessage ALTER COLUMN MessageText COMMENT 'Parameterized message template with `{placeholder}` syntax for runtime substitution.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:07 UTC
-- Statements: 5/5 succeeded
-- ====================
