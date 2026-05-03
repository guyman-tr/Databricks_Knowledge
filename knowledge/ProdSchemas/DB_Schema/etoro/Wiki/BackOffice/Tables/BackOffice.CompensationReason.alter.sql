-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.CompensationReason
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_compensationreason
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_compensationreason (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason SET TBLPROPERTIES (
    'comment' = 'Hierarchical catalog of all compensation types used to classify cash adjustments made to customer accounts, carrying tax and accounting flags that drive regulatory reporting and cash-flow classification. Source: etoro.BackOffice.CompensationReason on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.CompensationReason.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'CompensationReason',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN CompensationReasonID COMMENT 'Auto-generated unique identifier. PK referenced by compensation transaction tables. Used as ParentID for child types in the hierarchy. 136 active rows (IDs not sequential - some were deleted). (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN ParentID COMMENT 'Self-referential FK to CompensationReasonID. NULL = root/department category (9 root nodes: 1, 4, 9, 10, 16, 23, 35, 45, 48). Non-NULL = specific compensation type. FK_BCPR_BCPR enforces valid reference. BCPR_NAME index on Name column. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN Name COMMENT 'Internal classification name used by BackOffice staff. Descriptive operational names like "Foreclosure (taking all money)", "Hedge Abuser", "Position Airdrop". Has BCPR_NAME index for fast name lookup. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN DisplayName COMMENT 'Customer-facing label shown in account statement. Decouples internal classification from customer visibility. NULL for 3 types (ID 46, 47, 57) - these may display as empty in statements. Multiple types share "Adjustment", "Promotion", "eToro compensation" as generic labels. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsShownInHistory COMMENT 'Whether this compensation type appears in the customer''s transaction history/statement. 0=hidden from customer view (technical ops, non-cash instrument adjustments). Default 1 (shown). Used by reporting layer to filter customer-visible transactions. Types with 0: Test-Internal, ReopenOperation, Position Airdrop, Stock Split, Spinoff, Stock Dividend, Exchange, Merger, Name Change, Warrants, Rights offer, Staking, REORG Security. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsCashflowForGain COMMENT 'Whether this compensation represents actual cash flowing in/out of the account, relevant for gain/loss calculations and regulatory capital reporting. 0=non-cash event (instrument adjustments, position reopens, airdrops). Default 1. Critical for financial reporting - non-cash corporate actions (splits, mergers) must be 0. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsTaxable COMMENT 'Whether this compensation is a taxable event that must be reported on tax statements (1099 forms, etc.). 0=non-taxable (instrument adjustments like stock splits, mergers, spinoffs that don''t trigger tax obligations). Default 1. Drives tax reporting system - every IsTaxable=1 transaction may appear on the customer''s annual tax document. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
ALTER TABLE main.billing.bronze_etoro_backoffice_compensationreason ALTER COLUMN IsActive COMMENT 'Whether this type is still in active use. 0=deprecated (ID 3=Technical Problems under R&D, ID 26=Satisfaction Bonus under Accounting/Ops). Default 1. Inactive types should not be assigned to new compensations. (Tier 1 - upstream wiki, etoro.BackOffice.CompensationReason)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
