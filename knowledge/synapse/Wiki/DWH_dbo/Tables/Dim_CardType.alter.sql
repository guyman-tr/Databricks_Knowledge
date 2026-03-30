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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 5 COMMENT 'Domain expert confirmed';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 1 COMMENT 'Upstream production wiki verbatim';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 2 COMMENT 'Synapse SP code or migration DDL';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 3 COMMENT 'Live data sampling or DDL structure';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 4 COMMENT 'Inferred from column name only';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CardTypeID COMMENT 'Card network identifier. Active brands (IsActive=1 as of 2019): 0=None (unknown/fallback), 1=Visa, 2=Master Card, 3=Diners. Inactive: 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro (active in production today), 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. DWH note: snapshot covers IDs 0-17 only; production has 32 types including newer IDs. (Tier 1 - upstream wiki, Dictionary.CardType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CarTypeName COMMENT 'Card brand name. DDL note: column has a typo ("Car" instead of "Card") - historical artifact from legacy DWH SQL Server migration. Key values: Visa, Master Card, MasterCard, Diners, Amex, American Express, Maestro, Discover, China Union Pay. (Tier 1 - upstream wiki, Dictionary.CardType, column: Name)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN IsActive COMMENT 'Whether this card brand was accepted for deposits as of the 2019 migration snapshot: 1=active, 0=inactive. DWH note: production uses bit type; DWH uses int. This snapshot may not reflect current production acceptance (e.g., Maestro/ID=8 is active in production but shows 0 here). (Tier 1 - upstream wiki, Dictionary.CardType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN UpdateDate COMMENT 'ETL migration timestamp. All 18 rows = 2019-06-30 - the date this table was migrated from the legacy DWH SQL Server. Not a production field from Dictionary.CardType (which has no UpdateDate). (Tier 2 - DWH_Migration.Dim_CardType)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 5 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 1 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 2 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 3 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN Tier 4 SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CardTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN CarTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cardtype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
