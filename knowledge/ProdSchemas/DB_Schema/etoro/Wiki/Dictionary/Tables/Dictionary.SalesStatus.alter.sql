-- =============================================================================
-- Databricks ALTER Script: main.general.bronze_etoro_dictionary_salesstatus
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Dictionary/Tables/Dictionary.SalesStatus.md
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.bronze_etoro_dictionary_salesstatus SET TBLPROPERTIES (
    'comment' = 'A lookup table defining the sales pipeline status for customer accounts. Tracks where a customer stands in the sales/account management lifecycle - from initial registration through follow-up to closure. eToro''s BackOffice customer management system assigns each customer a sales status to track CRM pipeline progression. This enables sales teams and account managers to filter and report on customers by their engagement state. The status is stored on `BackOffice.Customer.SalesStatusID` and displayed in registration reports. When a customer registers, they receive the default "New" status (ID 0). Account managers update the status as they engage with the customer. The `BackOffice.GetRegistrationReport` procedure joins this table to display the human-readable sales status name alongside customer registration data.'
);

-- ---- Column Comments ----
ALTER TABLE main.general.bronze_etoro_dictionary_salesstatus ALTER COLUMN SalesStatusID COMMENT 'Primary key. Sales pipeline status identifier: 0=New, 1=Follow Up, 2=Close, 3=New-NA.';
ALTER TABLE main.general.bronze_etoro_dictionary_salesstatus ALTER COLUMN Name COMMENT 'Unique human-readable status label displayed in BackOffice registration reports and CRM views. Enforced unique by index `DSLS_NAME`.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- These tables have ZERO existing UC metadata, but blanket-tagging every column
-- 'pii=none' would risk silently misclassifying columns like PaymentReference,
-- which the source wiki documents as PII-masked. Run the dedicated PII classifier
-- afterwards to populate tags correctly.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 12:41:16 UTC
-- Statements: 3/3 succeeded
-- ====================
