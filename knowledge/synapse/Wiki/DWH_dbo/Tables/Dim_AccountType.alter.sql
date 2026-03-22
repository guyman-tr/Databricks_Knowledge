-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_AccountType
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype SET TBLPROPERTIES (
    'comment' = 'Dim_AccountType is the DWH version of etoro.Dictionary.AccountType. It classifies every eToro account into one of 18 categories based on ownership structure and operational purpose. This classification drives which platform features are available, what regulatory rules apply, how fees are calculated, and how accounts are monitored for compliance. Source: etoro.Dictionary.AccountType on etoroDB-REAL. The production table is exported daily to Bronze/etoro/Dictionary/AccountType/ and staged into DWH_staging.etoro_Dictionary_AccountType. SP_Dictionaries_DL_To_Synapse loads from that staging table using a TRUNCATE + INSERT pattern. The DWH table has 19 rows: IDs 0-18. ID=0 (N/A) is a DWH placeholder row from the production source itself (no separate placeholder insert in the SP). DWHAccountTypeID is set equal to AccountTypeID by the ETL and carries no additional information. StatusID is hardcoded to 1. UpdateDate and InsertDate are both set to GETDATE() at load time. Account types are assigned at customer regis...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN AccountTypeID COMMENT 'Primary key identifying the account classification. 0=N/A (DWH placeholder), 1=Private, 2=Corporate, 3=IB Account, 4=Joint Account, 5=White Label, 6=Affiliate Private, 7=Employee, 8=Custodian, 9=Fund, 10=eToro Group, 11=News, 12=White List, 13=Analyst, 14=SMSF, 15=Affiliate Corporate, 16=Administrated, 17=Funded Employee, 18=Trust. Controls feature access, regulatory treatment, fee structures, and compliance monitoring level. Referenced by Dim_Customer.AccountTypeID. (Tier 1 - upstream wiki, Dictionary.AccountType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN Name COMMENT 'Human-readable account type label. Maps to Dictionary.AccountType.AccountTypeName in production (renamed in DWH). Used in reporting to display account classification. (Tier 1 - upstream wiki, Dictionary.AccountType)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN DWHAccountTypeID COMMENT 'ETL surrogate key. Set equal to AccountTypeID by SP_Dictionaries_DL_To_Synapse (SELECT AccountTypeID AS DWHAccountTypeID). Carries no additional information beyond AccountTypeID. Present for DWH schema consistency with other Dim_ tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN StatusID COMMENT 'ETL-internal active-row indicator. Hardcoded to 1 by SP_Dictionaries_DL_To_Synapse for all rows. Not from the production source; carries no business meaning. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. Does not reflect when the production value changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN InsertDate COMMENT 'ETL load timestamp for row (re-)insertion. Set to GETDATE() on every reload (TRUNCATE + INSERT pattern). Always equals UpdateDate on this table. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN DWHAccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
