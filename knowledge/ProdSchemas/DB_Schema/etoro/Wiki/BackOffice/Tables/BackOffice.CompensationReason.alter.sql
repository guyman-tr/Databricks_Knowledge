-- =============================================================================
-- Databricks ALTER Script: main.billing.bronze_etoro_backoffice_compensationreason  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN CompensationReasonID COMMENT 'Auto-generated unique identifier. PK referenced by compensation transaction tables. Used as ParentID for child types in the hierarchy. 136 active rows (IDs not sequential - some were deleted).';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN ParentID COMMENT 'Self-referential FK to CompensationReasonID. NULL = root/department category (9 root nodes: 1, 4, 9, 10, 16, 23, 35, 45, 48). Non-NULL = specific compensation type. FK_BCPR_BCPR enforces valid reference. BCPR_NAME index on Name column.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN Name COMMENT 'Internal classification name used by BackOffice staff. Descriptive operational names like "Foreclosure (taking all money)", "Hedge Abuser", "Position Airdrop". Has BCPR_NAME index for fast name lookup.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN DisplayName COMMENT 'Customer-facing label shown in account statement. Decouples internal classification from customer visibility. NULL for 3 types (ID 46, 47, 57) - these may display as empty in statements. Multiple types share "Adjustment", "Promotion", "eToro compensation" as generic labels.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsShownInHistory COMMENT 'Whether this compensation type appears in the customer''s transaction history/statement. 0=hidden from customer view (technical ops, non-cash instrument adjustments). Default 1 (shown). Used by reporting layer to filter customer-visible transactions. Types with 0: Test-Internal, ReopenOperation, Position Airdrop, Stock Split, Spinoff, Stock Dividend, Exchange, Merger, Name Change, Warrants, Rights offer, Staking, REORG Security.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsCashflowForGain COMMENT 'Whether this compensation represents actual cash flowing in/out of the account, relevant for gain/loss calculations and regulatory capital reporting. 0=non-cash event (instrument adjustments, position reopens, airdrops). Default 1. Critical for financial reporting - non-cash corporate actions (splits, mergers) must be 0.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsTaxable COMMENT 'Whether this compensation is a taxable event that must be reported on tax statements (1099 forms, etc.). 0=non-taxable (instrument adjustments like stock splits, mergers, spinoffs that don''t trigger tax obligations). Default 1. Drives tax reporting system - every IsTaxable=1 transaction may appear on the customer''s annual tax document.';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsActive COMMENT 'Whether this type is still in active use. 0=deprecated (ID 3=Technical Problems under R&D, ID 26=Satisfaction Bonus under Accounting/Ops). Default 1. Inactive types should not be assigned to new compensations.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:28:04 UTC
-- Statements: 8/8 succeeded
-- ====================
