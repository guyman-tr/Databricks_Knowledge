-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_BonusType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype SET TBLPROPERTIES (
    'comment' = 'Dim_BonusType is a simplified DWH version of etoro.BackOffice.BonusType -- the master catalog of bonus categories. Every credit adjustment (bonus) issued to a customer references a BonusTypeID to classify what kind of promotion or operational adjustment it represents. Types span sales-driven first-deposit promotions, retention loyalty programs, accounting/ops fee adjustments, R&D technical credits, and MT4 platform fund transfers. Source: etoro.BackOffice.BonusType on etoroDB-REAL. Exported daily to Bronze/etoro/BackOffice/BonusType/ and staged into DWH_staging.etoro_BackOffice_BonusType. SP_Dictionaries_DL_To_Synapse loads using a TRUNCATE + INSERT pattern. **Important**: The DWH loads only 4 of 9 production columns. Excluded: ParentID (departmental hierarchy), DisplayName (customer-facing label), IsDepositRelated, HideFromAffwiz, Configuration. Analysts cannot reconstruct the bonus type hierarchy in DWH without the ParentID column. 66 rows: IDs 0-71 with gaps at 60-65. All IsWithdrawable=False. IsActive=...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype SET TAGS (
    'domain' = 'general',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'CLUSTERED INDEX (BonusTypeID)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN BonusTypeID COMMENT 'Primary key identifying the bonus category. 0=N/A (DWH placeholder), 1=First Registration Bonus, 2=Sales First Deposit Bonus, 3=Custom, ... 71=Credit Line. 66 rows, IDs 0-71 with gaps 60-65. Smallint in DWH vs int IDENTITY in production. (Tier 1 - upstream wiki, BackOffice.BonusType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN Name COMMENT 'Internal BackOffice name for the bonus type. Used by BackOffice staff for reporting and operational routing. This is NOT the customer-facing label -- production also has a DisplayName column (excluded from DWH). Note: some names contain typos from production (e.g., "Cashout Fee Reimbursment" - misspelling of "Reimbursement"). (Tier 1 - upstream wiki, BackOffice.BonusType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN IsWithdrawable COMMENT 'Whether the bonus amount can be withdrawn by the customer. False (0) for ALL 66 rows in the DWH -- this field is either a planned feature not yet activated or withdrawability is controlled elsewhere in the bonus lifecycle. (Tier 1 - upstream wiki, BackOffice.BonusType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN IsActive COMMENT 'Whether this bonus type is still in active use. False for IDs 0 (N/A placeholder), 17 (Refill-Negative Balance), and 23 (Championship Winner Demo). True for all other 63 types. (Tier 1 - upstream wiki, BackOffice.BonusType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN DWHBonusTypeID COMMENT 'ETL surrogate key. Set equal to BonusTypeID by SP_Dictionaries_DL_To_Synapse (SELECT BonusTypeID AS DWHBonusTypeID). Always equals BonusTypeID; carries no additional information. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN StatusID COMMENT 'ETL-internal active-row indicator. Hardcoded to 1 for all rows by SP_Dictionaries_DL_To_Synapse. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload. Monitor for freshness -- live data shows last load 2026-03-11. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN InsertDate COMMENT 'ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN BonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN IsWithdrawable SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN IsActive SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN DWHBonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_bonustype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
