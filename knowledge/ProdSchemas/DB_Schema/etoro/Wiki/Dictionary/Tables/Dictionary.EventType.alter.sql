-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_eventtype
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.EventType.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_eventtype SET TBLPROPERTIES (
    'comment' = 'A lookup table defining customer lifecycle event types that trigger automated actions (such as notifications, messages, or internal workflows) within the platform. The platform tracks significant customer milestones - registration, first deposit, first trade, etc. - to trigger automated engagement (welcome messages, promotional offers, re-engagement campaigns). This table defines the event catalog and tracks which events are currently active in the system. Referenced by `Customer.SendEvent` (triggers event processing for a customer), `BackOffice.SendBirthDayMessage` (birthday-specific events), and `Maintenance.EventEdit` (enables/disables events). The `IsActive` flag controls whether the event type is currently operational.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_eventtype ALTER COLUMN EventTypeID COMMENT 'Primary key. Event type identifier (1-29 with gaps).';
ALTER TABLE main.general.bronze_etoro_dictionary_eventtype ALTER COLUMN IsActive COMMENT 'Whether the event type is currently operational. Active=1 means the system processes this event; Inactive=0 means it is ignored.';
ALTER TABLE main.general.bronze_etoro_dictionary_eventtype ALTER COLUMN Name COMMENT 'Human-readable event description. Unique index ensures no duplicates.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:09 UTC
-- Statements: 4/4 succeeded
-- ====================
