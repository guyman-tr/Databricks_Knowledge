-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_servertype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.ServerType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_servertype SET TBLPROPERTIES (
    'comment' = 'A lookup table classifying the types of servers in eToro''s trading infrastructure. Each entry represents a distinct server role - from database servers to price providers, hedge servers, and game (trading) servers. eToro''s distributed architecture has many specialized server types. This table provides a standardized classification used by the error messaging system (`Dictionary.ErrorMessage`) and game server configuration (`Dictionary.GameServer`) to categorize messages and instances by their originating server type. Server types are referenced by `Dictionary.ErrorMessage.ServerTypeID` to route error messages to the correct monitoring category, and by `Dictionary.GameServer.ServerTypeID` to classify trading server instances. The `Broker.actDispatcher` procedure also references server types in broker communication routing.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_servertype ALTER COLUMN ServerTypeID COMMENT 'Primary key. Server type identifier. Range: 0-13 (with gaps at 9-12).';
ALTER TABLE main.general.bronze_etoro_dictionary_servertype ALTER COLUMN Name COMMENT 'Fixed-width server type name. Enforced unique by index `DSVT_NAME`. Padded with spaces due to char(20) type.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:23 UTC
-- Statements: 3/3 succeeded
-- ====================
