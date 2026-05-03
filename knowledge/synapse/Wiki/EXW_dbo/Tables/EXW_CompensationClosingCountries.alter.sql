-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_CompensationClosingCountries
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries
-- Resolved via: Wiki property table
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries SET TBLPROPERTIES (
    'comment' = 'EXW_CompensationClosingCountries is the central registry of wallet users who were compensated as part of regulatory country-closure or AML-driven wallet termination events. With 140,638 rows covering 59,207 users, it stores one record per GCID × CryptoId × Project, capturing the crypto balance at time of compensation, the exchange rate used, and the closure date. The table covers two categories of events: 1. **Country closures** (compliance events): Large-scale regulatory exits from specific jurisdictions where eToro was required to close wallet accounts - e.g., FrenchTerr (51,101 rows, 11,520 users), Germany_Tangany_AirDrop (47,021 rows, 31,123 users), Russia (17,421 rows), Netherlands (8,034 rows). These were loaded via legacy ETL processes and are not updated by the current SP. 2. **AML compensations** (individual enforcement): Users compensated due to anti-money-laundering enforcement actions. Currently loaded via Fivetran from Google Sheets: AML (2,664 rows, 2,311 users), AML_US (470 rows, 377 users),...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'EXW_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (GCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CID` COMMENT 'Platform customer ID (RealCID equivalent). Sourced from Google Sheet column `cid`; sanitized for non-breaking space characters before CAST to INT. May be NULL for rows where the source sheet omits CID. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `GCID` COMMENT 'Wallet customer identifier. Sourced from Google Sheet column `gcid`; sanitized for NBSP then CAST to INT. Distribution key. Used for AMLClosureEvent check in SP_EXW_FinanceReportsBalancesNew. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Rate` COMMENT 'Exchange rate (crypto-to-USD) used at time of compensation. Sourced from Google Sheet column `exchange_rate`. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `RateDate` COMMENT 'Date of the exchange rate used for compensation calculation. Sourced from Google Sheet column `exchange_date`. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CryptoName` COMMENT 'Human-readable name of the cryptocurrency compensated (e.g., BTC, ETH, XRP). Sourced from Google Sheet column `crypto`. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CryptoId` COMMENT 'Cryptocurrency identifier. Sourced from Google Sheet column `crypto_id`; ISNUMERIC guard applied for AML_US/AML_EEA sheets. NULL if source value is non-numeric. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `FinalBalance` COMMENT 'Crypto balance at time of compensation, in native crypto units. Sourced from Google Sheet column `units`; CAST as FLOAT. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `USD_FinalBalance` COMMENT 'USD value of compensation: FinalBalance × Rate at RateDate. Sourced from Google Sheet column `compensation_amount_usd`; CAST as FLOAT. Used as uniqueness key in UPSERT logic (ROUND to 8 decimal places). (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `WalletId` COMMENT 'Customer''s wallet GUID for the compensated CryptoId. Lookup from EXW_Wallet.EXW_CustomerWalletsView.Id by GCID + CryptoId. NULL if no matching wallet found. (Tier 2 - SP_EXW_CompensationClosingCountries via EXW_Wallet.EXW_CustomerWalletsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Address` COMMENT 'Blockchain address of the customer''s wallet for the compensated crypto. Lookup from EXW_Wallet.EXW_CustomerWalletsView.Address by GCID + CryptoId. NULL if no wallet found. (Tier 2 - SP_EXW_CompensationClosingCountries via EXW_Wallet.EXW_CustomerWalletsView)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Country` COMMENT 'Country name of the user at time of compensation. Sourced from Google Sheet column `country`. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CountryID` COMMENT 'Country identifier. Sourced from Google Sheet column `country_id`; CAST to INT. FK to DWH_dbo.Dim_Country. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `ReportFromDate` COMMENT 'Start date of the balance report period used in legacy compensation calculations. NULL for all AML*, AML_US, and AML_EEA rows (hardcoded by current SP). May have date values for legacy country-closure project rows. (Tier 2 - SP_EXW_CompensationClosingCountries)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `ReportId` COMMENT 'Report identifier from legacy balance report runs. NULL for all AML*, AML_US, and AML_EEA rows (hardcoded by current SP). May have values for legacy country-closure project rows. (Tier 2 - SP_EXW_CompensationClosingCountries)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Project` COMMENT 'Regulatory compensation project identifier. Discriminates the reason for user inclusion. Current SP produces: ''AML'', ''AML_US'', ''AML_EEA''. 15 additional legacy values: FrenchTerr, Germany_Tangany_AirDrop, Germany_Tangany_Cash_Compensation, Germany_Tangany_Cash_Compensation2, Russia ALL regulations..., Russia ASIC+ASIC GAML, Russia_Sanctions, Netherlands, GroupAB, Philippines, XtokensClosure, XtokensClosureFixMissing, SSN Closure -US, Angola/Eritrea/Rwanda/Senegal, Manual Adjustment. (Tier 2 - SP_EXW_CompensationClosingCountries)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CompensationDate` COMMENT 'Date the compensation was calculated or recorded. Sourced from Google Sheet column `compensation_date`. Used as the join key in EXW_ReimbursementFollowUp (CompensationDate = EXW_WalletEntity.Date). (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Regulation` COMMENT 'Regulation name at time of compensation (e.g., CySEC, FCA, FinCEN). Sourced from Google Sheet column `regulation`. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `RegulationID` COMMENT 'Regulation identifier. Sourced from Google Sheet column `regulation_id`; ISNUMERIC guard applied for AML_US/AML_EEA. FK to DWH_dbo.Dim_Regulation. NULL if source is non-numeric. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the most recent INSERT or UPDATE of this row. Set to GETDATE() by the SP. (Tier 2 - SP_EXW_CompensationClosingCountries)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Reason` COMMENT 'Textual reason for the compensation or closure. Sourced from `reason` column for AML/AML_US; from `sub_reason` column for AML_EEA. May differ in granularity across project types. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `AMLStatus` COMMENT 'Status of the AML enforcement action. Sourced from Google Sheet column `status`. Key values used by downstream SP: ''compensated'', ''reimbursed'', ''completed'' (active records); other values indicate in-progress or excluded cases. NULL for legacy non-AML project rows. (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `DateClosure` COMMENT 'Date the user''s wallet was formally closed as part of this regulatory event. Sourced from Google Sheet column `date_of_closure`; CAST(DATE). (Tier 2 - SP_EXW_CompensationClosingCountries via Fivetran)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Rate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `RateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CryptoName` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CryptoId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `FinalBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `USD_FinalBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `WalletId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Address` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `ReportFromDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `ReportId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Project` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `CompensationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Regulation` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `RegulationID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `Reason` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `AMLStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_compensationclosingcountries ALTER COLUMN `DateClosure` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:31:38 UTC
-- Batch deploy resume: EXW_dbo deploy batch 1
-- Statements: 46/46 succeeded
-- ====================
