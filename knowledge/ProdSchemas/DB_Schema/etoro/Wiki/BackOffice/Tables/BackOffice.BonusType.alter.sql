-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.BonusType
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md
-- Layer: bronze
-- UC Target: main.bi_db.bronze_etoro_backoffice_bonustype
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_etoro_backoffice_bonustype (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype SET TBLPROPERTIES (
    'comment' = 'Hierarchical catalog of all bonus categories used to classify credit adjustments issued to customers, organized by the department that manages them (Sales, Marketing, Retention, Accounting, R&D). Source: etoro.BackOffice.BonusType on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Tables/BackOffice.BonusType.md).'
);

ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'BonusType',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN BonusTypeID COMMENT 'Auto-generated unique identifier for each bonus type. PK referenced by BackOffice.Bonus (BonusTypeID FK) and BackOffice.CampaignToBonusType. Also used as ParentID for child types in the hierarchy. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN ParentID COMMENT 'Self-referential FK to BonusTypeID. NULL = root/department category (9 root nodes). Non-NULL = specific bonus program under a department. FK constraint FK_BBNT_BBNT enforces referential integrity. Has BBNT_PARENT index for efficient children lookups. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN Name COMMENT 'Internal name used by BackOffice staff for identification, reporting, and operational routing. Shown in the BackOffice UI dropdowns. NOT the customer-visible name - see DisplayName. Examples: "Dormant Fee", "Hedge Abuser", "Request for Documents", "Cashout Fee Reimbursment" (note: typo in production data). Has BBNT_NAME index. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN Configuration COMMENT 'XML configuration payload for parameterized bonus types. Only one active bonus type has this populated (BonusTypeID=2: <DepositBonus/>). Intended for deposit bonus configuration rules but largely unused - 69 of 70 types have NULL configuration. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN IsWithdrawable COMMENT 'Whether the bonus amount can be withdrawn by the customer. Currently 0 (false) for ALL 70 active bonus types - this field is either a planned feature or bonus withdrawability is controlled elsewhere in the bonus lifecycle. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN IsActive COMMENT 'Whether this bonus type is still in active use. 0=deprecated (should not be assigned to new bonuses). Active=0 types: 17=Refill-Negative Balance, 23=Championship Winner Demo. All other 68 types are IsActive=1. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN HideFromAffwiz COMMENT 'Controls visibility in the Affiliate Wizard (AffWiz) portal used by affiliate partners. 1=hide from affiliates (internal operational types not relevant to affiliate programs). 0 or NULL=visible. NULL represents rows created before this column was added. Types with HideFromAffwiz=1 include operational adjustments (Dormant Fee, Foreclosure, Hedge Abuser, P&L Adjustment, Merge Accounts) that affiliates should not access. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN DisplayName COMMENT 'Customer-facing label shown in the customer''s account statement for this bonus type. Decouples internal classification from customer-visible text. Examples: "eToro credits adjustment" (generic ops adjustment), "Account maintenance fee" (Dormant Fee), "Withdraw Fee Reimbursement" (Cashout Fee Reimbursement), "Trading credits" (R&D technical bonus). Multiple bonus types share the same DisplayName (e.g., many types show "eToro credits adjustment"). (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
ALTER TABLE main.bi_db.bronze_etoro_backoffice_bonustype ALTER COLUMN IsDepositRelated COMMENT 'Whether this bonus type is triggered by or associated with a customer deposit event. 1=deposit-related (first deposit promos, retention deposit bonuses, NWA adjustment, referral-when-invited bonuses). 0=non-deposit operational credit or promotional grant. Used in reporting to distinguish promotional deposit incentives from operational adjustments. (Tier 1 - upstream wiki, etoro.BackOffice.BonusType)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
