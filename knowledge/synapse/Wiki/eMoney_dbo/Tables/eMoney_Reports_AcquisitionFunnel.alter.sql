-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Reports_AcquisitionFunnel
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel SET TBLPROPERTIES (
    'comment' = '`eMoney_Reports_AcquisitionFunnel` is the primary eToro Money acquisition analytics table. Each row represents one verified eToro depositor (IsVerifiedFTD=1) who lives in a country where eToro Money is live, tagged with a set of boolean indicators capturing their current eMoney funnel stage. As of 2026-04-12 there are **3,672,801** customer rows. The eligible population is restricted to: verified FTD customers, in active eMoney markets (from `eMoney_Dim_Country_Rollout`), with a valid customer status (PlayerStatusID NOT IN 2,4,14,15). Key funnel metrics from live data: - IsVerifiedFTDPlus2Weeks: 3,659,851 (99.6%) - nearly all depositors are 2+ weeks old - IseMoneyAccount: 1,726,054 (47%) - roughly half have an eMoney account - IsFMI: 1,201,484 (32.7%) - have completed First Money In - IsFMO: 1,160,237 (31.6%) - have completed First Money Out - IsActiveMIMO: 449,123 (12.2%) - active in last 91 days (MIMO actions 7 or 8) - IsCardCreated: 89,823 (2.4%) - have an eToro Money card - IsCardActivated: 26,079 (0.7...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel SET TAGS (
    'domain' = 'marketing',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `Country` COMMENT 'Customer''s eMoney-registered country name. Derived as ISNULL(eMoney_Dim_Account.RegCountry, eMoney_Dim_Country_Rollout.CountryName) - eMoney account''s registered country takes precedence over the current eToro trading country. Scoped to eMoney-eligible markets only. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `Club` COMMENT 'Customer''s current eToro loyalty club tier at time of refresh. 6 values: Bronze=84%, Silver=5.9%, Gold=5.4%, Platinum=2.6%, Platinum Plus=1.9%, Diamond=0.2%. Sourced from DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsValidForFunnel` COMMENT '1 if the customer is eligible for the eToro Money funnel, 0 if excluded. Derived from ISNULL(eMoney_Dim_Account.IsValidETM, 1). Defaults to 1 when no eMoney account exists (customer is potentially eligible). 0 indicates an invalid eMoney enrollment (710 rows = 0.02%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsVerifiedFTD` COMMENT 'Always 1 - all rows in this table are verified eToro FTD depositors (IsDepositor=1, VerificationLevelID=3 filter applied during SP execution). Serves as an eligibility label confirming funnel entry criteria. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsVerifiedFTDPlus2Weeks` COMMENT '1 if the customer''s first deposit was more than 14 days ago (DATEDIFF(DAY, FirstDepositDate, yesterday) > 14). Measures 2-week post-FTD maturation used in some cohort definitions. 3,659,851 rows = 1 (99.6%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsActiveMIMO` COMMENT '1 if the customer performed at least one MIMO action (ActionTypeID IN [7, 8] in DWH_dbo.Fact_CustomerAction) within the last 91 days (rolling window from yesterday). 449,123 rows = 1 (12.2%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IseMoneyAccount` COMMENT '1 if the customer has a row in eMoney_Panel_FirstDates (GCID IS NOT NULL after LEFT JOIN). Indicates the customer has an active eMoney account represented in the first-dates panel. 1,726,054 rows = 1 (47.0%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsFMI` COMMENT '1 if the customer''s FMI_Date IS NOT NULL in eMoney_Panel_FirstDates - they have received their first settled incoming eToro Money transfer (First Money In). 1,201,484 rows = 1 (32.7%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsFMO` COMMENT '1 if the customer''s FMO_Date IS NOT NULL in eMoney_Panel_FirstDates - they have made their first settled outgoing eToro Money transfer (First Money Out). 1,160,237 rows = 1 (31.6%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardCreated` COMMENT '1 if eMoney_Dim_Account.CardCreateTime IS NOT NULL - an eToro Money physical or virtual card has been issued for this customer. 89,823 rows = 1 (2.4%). (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardActivated` COMMENT '1 if eMoney_Panel_FirstDates.CardActivationTime IS NOT NULL - the customer''s card has reached Active status (CardStatusID=1). 26,079 rows = 1 (0.7%). Always <= IsCardCreated. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardFirstTx` COMMENT '1 if eMoney_Panel_FirstDates.FirstCardSettledTXDate IS NOT NULL - the customer has made at least one settled card transaction. 23,690 rows = 1 (0.6%). The final stage of the card adoption funnel. (Tier 2 - SP_eMoney_Reports_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `UpdateDate` COMMENT 'Timestamp of the most recent SP refresh. Set to GETDATE() at insert time; all rows share the same value per daily refresh. Last observed: 2026-04-12 06:45:41. (Tier 2 - SP_eMoney_Reports_Daily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsValidForFunnel` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsVerifiedFTD` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsVerifiedFTDPlus2Weeks` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsActiveMIMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IseMoneyAccount` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsFMI` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsFMO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardCreated` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardActivated` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `IsCardFirstTx` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_acquisitionfunnel ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:24:15 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 1
-- Statements: 32/32 succeeded
-- ====================
