-- =============================================================================
-- Databricks ALTER Script: bronze etoro.BackOffice.CustomerAllTimeAggregatedData
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata SET TBLPROPERTIES (
    'comment' = 'Canonical lifetime financial and activity aggregates view unifying the standard trading pipeline (_1 table) and the MIMO/eToro Money pipeline, presenting a single all-time summary row per customer regardless of which payment channels they use. Source: etoro.BackOffice.CustomerAllTimeAggregatedData on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.md).'
);

ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'BackOffice',
    'source_table' = 'CustomerAllTimeAggregatedData',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN CID COMMENT 'Customer ID - the row key. From _1 table in Branch 1, from MIMO table in Branch 2. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalProfit COMMENT 'Lifetime realized profit from all closed trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalDeposit COMMENT 'Lifetime total deposits from the MIMO pipeline. For standard-only customers (no MIMO record) this is 0. Sourced from CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalBonus COMMENT 'Lifetime total bonus credits from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalInvestment COMMENT 'Total funds locked into open trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalCommission COMMENT 'Total commission charges paid. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalVolume COMMENT 'Total trading volume (sum of position sizes) in USD. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalLot COMMENT 'Total lot volume traded. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalChampWin COMMENT 'Total championship winnings. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalCashout COMMENT 'Lifetime approved cashouts (withdrawals) from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalCashoutRequest COMMENT 'Total value of cashout requests (including pending). From CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalReverseCashout COMMENT 'Total reversed cashout amounts. From CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalCompensation COMMENT 'Total compensation credits from MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalGameCount COMMENT 'Total number of games/contests participated in. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalPositionCount COMMENT 'Total number of trading positions opened lifetime. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalLoginCount COMMENT 'Total number of platform logins. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalLoggedTime COMMENT 'Total time spent logged in (seconds or minutes). From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN TotalEndOfWeekFee COMMENT 'Total end-of-week inactivity fees charged. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN LastUpdate COMMENT 'Most recent update timestamp from either pipeline. CASE WHEN A.LastUpdate > ISNULL(M.LastUpdate,''01-01-2000'') THEN A.LastUpdate ELSE M.LastUpdate END. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN FirstTimeCashierLoginDate COMMENT 'Date customer first accessed the cashier/deposit flow. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN FirstTimeDepositAttemptDate COMMENT 'Date of customer''s first deposit attempt via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN FirstTimeDepositSuccessDate COMMENT 'Date of customer''s first successful deposit via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN LastOccurredTriggerToSF COMMENT 'Most recent SalesForce sync trigger timestamp. Takes the later of A and M values. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN LastLoggedInOn COMMENT 'Most recent login timestamp. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN LastClientIp COMMENT 'IP address from most recent login. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN RealizedEquityLastChange COMMENT 'Timestamp of last change to LastRealizedEquity. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';
ALTER TABLE main.billing.bronze_etoro_backoffice_customeralltimeaggregateddata ALTER COLUMN LastRealizedEquity COMMENT 'Most recent snapshot of customer''s realized equity balance. 0 for MIMO-only customers. From CustomerAllTimeAggregatedData_1. (Tier 1 - upstream wiki, etoro.BackOffice.CustomerAllTimeAggregatedData)';

