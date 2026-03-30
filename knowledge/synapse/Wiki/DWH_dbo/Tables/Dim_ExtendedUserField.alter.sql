-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_ExtendedUserField
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield SET TBLPROPERTIES (
    'comment' = '`Dim_ExtendedUserField` is a 12-row dictionary (FieldIDs 0-11) mapping integer codes to names for jurisdiction-specific KYC (Know Your Customer) and regulatory data fields collected from eToro customers. "Extended user fields" are additional data points collected beyond the standard registration form, required by specific regulatory regimes or payment systems. The fields include address supplements (province, sub-building number), national identity documents (CodeFiscale for Italy, SocialInsuranceNumber for Canada, NIF for Spain), tax identifiers, national PIN numbers, employer information, and suitability/compliance questions. The data originates from `UserApiDB.Dictionary.ExtendedUserField` on the `UserApiDB-REAL` production server. No upstream wiki exists for UserApiDB.Dictionary. The ETL loads from `DWH_staging.UserApiDB_Dictionary_ExtendedUserField` via `SP_Dictionaries_DL_To_Synapse` (TRUNCATE + INSERT pattern). Daily refresh; last updated 2026-03-11 (~8 days stale as of 2026-03-19). The `FieldTypeID...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield SET TAGS (
    'domain' = 'general',
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN FieldID COMMENT 'Primary key. Integer identifier for an extended user field. Values: 0=province, 1=SecondSurname, 2=CodeFiscale, 3=SocialInsuranceNumber, 4=NIF, 5=SubBuildingNumber, 6=TaxId, 7=NationalPin, 8=EmployerName, 9=DepositQuestion, 10=WithdrawQuestion, 11=DedicatedEv. Renamed from `FieldId` in source. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN FieldTypeID COMMENT 'Category code grouping fields by type. Values observed: 0=address fields, 1=name fields, 2=national ID documents, 3=tax ID, 4=national PIN, 5=employment, 6=deposit compliance question, 7=withdrawal compliance question, 9=EV verification. No separate dimension table exists to decode FieldTypeID. Renamed from `FieldTypeId` in source. (Tier 3 - live data sampling)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN ExtendedUserFieldName COMMENT 'Human-readable field name. Renamed from `Name` in source (prefix added). Values are short camelCase identifiers (e.g., province, CodeFiscale, NationalPin). (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() when SP_Dictionaries_DL_To_Synapse runs. Not from source. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN FieldID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN FieldTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN ExtendedUserFieldName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_extendeduserfield ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:21:48 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 10/10 succeeded
-- ====================
