-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Reports_MIMO_Actions
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions SET TBLPROPERTIES (
    'comment' = '`eMoney_Reports_MIMO_Actions` is the historical MIMO (Money In / Money Out) analytics table for eToro Money, covering 2022-05-01 to 2024-10-12 (1,544,381 rows). It was the primary daily MIMO KPI table from the eToro Money Synapse migration in November 2022 until September 2024. **Grain**: One row per (ActionDate × Country × Club × ActionType × FundingType × IsValid × Seniority_daily_FTD_Group × Is_Corporate_Account). This is identical to `eMoney_Daily_MIMO_New_Reports_Action` but without the Type_of_IBAN dimension. The same country, club, action type, and funding type segmentation applies. **Why it was superseded**: On 2024-09-30, Adva Jakobson modified SP_eMoney_Daily_MIMO to (1) add Type_of_IBAN segmentation from eMoney_Dim_Account.BankAccountIBAN and (2) redirect inserts to `eMoney_Daily_MIMO_New_Reports_Action`. The old table is preserved as a historical archive. The "New_Reports_Action" naming reflects this transition. **Complete time series**: To query the full MIMO history from 2022 to present, UNIO...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `ActionDate` COMMENT 'The date of the deposit or cashout action (CAST(Fact_CustomerAction.Occurred AS DATE)). Grain date for this aggregation - one complete calendar day. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Country` COMMENT 'Country of the customer at the time of action, from eMoney_Dim_Country_Rollout.CountryName. Only eToro Money open countries (RolloutDateID <= ActionDate) appear. (Tier 2 - SP_eMoney_Daily_MIMO via Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Club` COMMENT 'Customer loyalty club tier at the time of action, from DWH_dbo.Dim_PlayerLevel.Name (e.g., Bronze, Silver, Gold, Platinum, Elite). Derived from Fact_SnapshotCustomer.PlayerLevelID at the action date. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `ActionType` COMMENT 'Type of financial action from DWH_dbo.Dim_ActionType.Name. Only Deposit (ActionTypeID=7) and Cashout (ActionTypeID=8) are included. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_ActionType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `FundingType` COMMENT 'Funding method name from DWH_dbo.Dim_FundingType.Name. Examples: eToroMoney (FundingTypeID=33), CreditCard, PayPal, iDEAL, Przelewy24, Trustly, WireTransfer, eToroCryptoWallet, MoneyBookers. FundingTypeID=33 is the eToro Money split key. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_FundingType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `IsValid` COMMENT '1 if the customer is a valid eToro Money participant (IsValidETM=1 in eMoney_Dim_Account with GCID_Unique_Count=1); defaults to 1 when the customer is not in eMoney_Dim_Account. 0 for explicitly ineligible customers. (Tier 2 - SP_eMoney_Daily_MIMO via eMoney_Dim_Account.IsValidETM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Seniority_daily_FTD_Group` COMMENT 'Customer deposit seniority bucket based on days since first deposit at the action date. Values: No deposits / 0 / 1-4 / 5-7 / 8-14 / 15-30 / 31-91 / 92-183 / 184-365 / 366-730 / 731+. Computed from DATEDIFF(Dim_Customer.FirstDepositDate, ActionDate). (Tier 2 - SP_eMoney_Daily_MIMO via Dim_Customer.FirstDepositDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Is_Corporate_Account` COMMENT '1 if the customer''s AccountTypeID=2 in DWH_dbo.Dim_Customer; 0 otherwise. Identifies corporate/institutional accounts. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_Customer.AccountTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_TotalActions` COMMENT 'Total count of deposit or cashout actions in this grouping. Not deduplicated - a customer making 3 deposits counts as 3. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_UniqueGCIDs` COMMENT 'Count of distinct customer GCIDs in this grouping. Represents the number of unique customers who performed actions. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_eMoneyActions` COMMENT 'Count of actions funded via eToroMoney (FundingTypeID=33) - the eToro platform <-> eToro Money wallet transfer. Primary eToro Money adoption count metric. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_OtherActions` COMMENT 'Count of actions funded via external methods (FundingTypeID != 33) - bank wires, credit cards, PayPal, crypto, etc. CNT_TotalActions = CNT_eMoneyActions + CNT_OtherActions. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_OtherActionsByeMoneyClients` COMMENT 'Count of non-eMoney-funded actions (FundingTypeID != 33) performed by customers who are also valid eToro Money participants (LEFT JOIN eMoney_Dim_Account IS NOT NULL). Measures external funding activity of eToro Money customers. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_eMoneyActionsByeMoneyClients` COMMENT 'Count of eMoney-funded actions (FundingTypeID=33) performed by customers who are valid eToro Money participants. Removes actions from customers who happen to use eToroMoney but aren''t eToro Money clients. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_TotalActions` COMMENT 'Total monetary value (in account currency) of all actions in this grouping. Sourced from Fact_CustomerAction.Amount. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_eMoneyActions` COMMENT 'Total value of eMoney-funded actions (FundingTypeID=33). Measures the monetary flow through the eToro <-> eMoney wallet channel. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_OtherActions` COMMENT 'Total value of externally-funded actions (FundingTypeID != 33). (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_OtherActionsByeMoneyClients` COMMENT 'Total value of external-funded actions by customers who are eToro Money participants. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_eMoneyActionsByeMoneyClients` COMMENT 'Total value of eMoney-funded actions by customers who are eToro Money participants. The primary monetary signal for eToro Money platform adoption. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `UpdateDate` COMMENT 'ETL run timestamp - GETDATE() at INSERT time. Nullable in this legacy table (vs. NOT NULL in the successor). Last value: 2024-10-13 (day after the last ActionDate). (Tier 2 - SP_eMoney_Daily_MIMO)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `ActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `ActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `FundingType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `IsValid` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Seniority_daily_FTD_Group` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Is_Corporate_Account` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_TotalActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_UniqueGCIDs` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_eMoneyActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_OtherActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_OtherActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `CNT_eMoneyActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_TotalActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_eMoneyActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_OtherActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_OtherActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `Value_eMoneyActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_reports_mimo_actions ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
