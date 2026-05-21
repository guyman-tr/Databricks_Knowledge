-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_CardType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.Dim_CardType is a lookup table defining payment card network brands accepted by the eToro platform for deposits. Each row represents a card type (Visa, MasterCard, Diners, etc.) with its active/inactive status. When a customer makes a card deposit, the card''s BIN (Bank Identification Number) resolves to a CardTypeID - this dimension decodes that ID to the human-readable brand name. The DWH version is a frozen 2019 snapshot migrated from the legacy DWH SQL Server. It contains 18 card types (IDs 0-17), while the current production `etoro.Dictionary.CardType` has grown to 32 entries. New card types added after 2019-06-30 do not appear in this DWH table. The production table also has an `Is3dsOn` flag (3D Secure requirement) that was dropped during the DWH migration. Note: The column `CarTypeName` is a typo in the original DDL (should be "CardTypeName") - this is a historical artifact from the legacy DWH. Synapse: REPLICATE, CLUSTERED INDEX (CardTypeID ASC).'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (CardTypeID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CardTypeID COMMENT 'Card network identifier. Active brands (IsActive=1): 1=Visa, 2=MasterCard, 3=Diners, 8=Maestro. Inactive (IsActive=0): 0=None (fallback), 4=Amex, 5=FirePay, 6=JCB, 7=American Express, 9=Laser, 10=Switch, 11=UK Local, 12=Discover, 13=Local Card, 14=China UnionPay, 15=Solo, 16=Cirrus, 17=GE Capital. DWH snapshot covers IDs 0 - 17; production has 32 types.';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CarTypeName COMMENT 'Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. (Tier 1 - Dictionary.CardType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN IsActive COMMENT 'Whether this card brand is currently accepted for deposits: 1=accepted, 0=rejected. Type widened from bit to int in DWH. Only 4 of 32 are currently active in production. DWH note: DWH snapshot values may differ from current production state. (Tier 1 - Dictionary.CardType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN UpdateDate COMMENT 'ETL metadata timestamp recording when the row was loaded into the DWH. All 18 rows show 2019-06-30 00:22:57, indicating a single bulk migration load. (Tier 2 - DWH_Migration load)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CardTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CarTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:26:48 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 10/10 succeeded
-- ====================
