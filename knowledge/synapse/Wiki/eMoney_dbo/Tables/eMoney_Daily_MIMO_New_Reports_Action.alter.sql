-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Daily_MIMO_New_Reports_Action
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action SET TBLPROPERTIES (
    'comment' = '`eMoney_Daily_MIMO_New_Reports_Action` is the primary MIMO (Money In / Money Out) KPI table for eToro Money analytics. It provides daily deposit and cashout aggregations across all open eToro Money countries, segmented by the full analyst cut - country, club tier, action type, funding method, customer seniority, corporate flag, and IBAN origin country. **Grain**: One row per (ActionDate × Country × Club × ActionType × FundingType × IsValid × Seniority_daily_FTD_Group × Is_Corporate_Account × Type_of_IBAN). A single action date typically produces ~350-800 rows covering all active dimensions. The table has 3,516,399 rows covering 2022-05-01 to 2026-04-11. **MIMO KPI split**: The core analytical pattern splits actions into two streams based on FundingTypeID: - **eMoney actions** (FundingTypeID=33 = eToroMoney): transfers into/out of eToro Money wallets from the eToro brokerage platform. These are the primary eToro Money adoption metric. - **Other actions** (FundingTypeID != 33): external bank/card/PayPal/crypto ...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action SET TAGS (
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
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `ActionDate` COMMENT 'The date of the deposit or cashout action (CAST(Fact_CustomerAction.Occurred AS DATE)). Grain date for this aggregation - one complete calendar day. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Country` COMMENT 'Country of the customer at the time of action, from eMoney_Dim_Country_Rollout.CountryName. Only eToro Money open countries (RolloutDateID <= ActionDate) appear. 34 distinct countries as of 2026-04-11. (Tier 2 - SP_eMoney_Daily_MIMO via Fact_SnapshotCustomer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Club` COMMENT 'Customer loyalty club tier at the time of action, from DWH_dbo.Dim_PlayerLevel.Name (e.g., Bronze, Silver, Gold, Platinum, Elite). Derived from Fact_SnapshotCustomer.PlayerLevelID at the action date. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_PlayerLevel)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `ActionType` COMMENT 'Type of financial action from DWH_dbo.Dim_ActionType.Name. Only Deposit (ActionTypeID=7) and Cashout (ActionTypeID=8) are included. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_ActionType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `FundingType` COMMENT 'Funding method name from DWH_dbo.Dim_FundingType.Name. Examples: eToroMoney (FundingTypeID=33), CreditCard, PayPal, iDEAL, Przelewy24, Trustly, WireTransfer, eToroCryptoWallet, MoneyBookers. FundingTypeID=33 is the eToro Money split key. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_FundingType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `IsValid` COMMENT '1 if the customer is a valid eToro Money participant (IsValidETM=1 in eMoney_Dim_Account with GCID_Unique_Count=1); defaults to 1 when the customer is not in eMoney_Dim_Account. 0 for explicitly ineligible customers. (Tier 2 - SP_eMoney_Daily_MIMO via eMoney_Dim_Account.IsValidETM)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Seniority_daily_FTD_Group` COMMENT 'Customer deposit seniority bucket based on days since first deposit at the action date. Values: No deposits / 0 / 1-4 / 5-7 / 8-14 / 15-30 / 31-91 / 92-183 / 184-365 / 366-730 / 731+. Computed from DATEDIFF(Dim_Customer.FirstDepositDate, ActionDate). (Tier 2 - SP_eMoney_Daily_MIMO via Dim_Customer.FirstDepositDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Is_Corporate_Account` COMMENT '1 if the customer''s AccountTypeID=2 in DWH_dbo.Dim_Customer; 0 otherwise. Identifies corporate/institutional accounts. (Tier 2 - SP_eMoney_Daily_MIMO via Dim_Customer.AccountTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_TotalActions` COMMENT 'Total count of deposit or cashout actions in this (date × country × club × type × funding × seniority × corporate × IBAN) grouping. Not deduplicated - a customer making 3 deposits counts as 3. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_UniqueGCIDs` COMMENT 'Count of distinct customer GCIDs in this grouping. Represents the number of unique customers who performed actions (vs. total action count in CNT_TotalActions). (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_eMoneyActions` COMMENT 'Count of actions funded via eToroMoney (FundingTypeID=33) - the eToro platform <-> eToro Money wallet transfer. Primary eToro Money adoption count metric. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_OtherActions` COMMENT 'Count of actions funded via external methods (FundingTypeID != 33) - bank wires, credit cards, PayPal, crypto, etc. CNT_TotalActions = CNT_eMoneyActions + CNT_OtherActions. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_OtherActionsByeMoneyClients` COMMENT 'Count of non-eMoney-funded actions (FundingTypeID != 33) performed by customers who are also valid eToro Money participants (LEFT JOIN eMoney_Dim_Account IS NOT NULL). Measures external funding activity of eToro Money customers. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_eMoneyActionsByeMoneyClients` COMMENT 'Count of eMoney-funded actions (FundingTypeID=33) performed by customers who are valid eToro Money participants. Removes actions from customers who happen to use eToroMoney but aren''t eToro Money clients. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_TotalActions` COMMENT 'Total monetary value (in account currency) of all actions in this grouping. Sourced from Fact_CustomerAction.Amount. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_eMoneyActions` COMMENT 'Total value of eMoney-funded actions (FundingTypeID=33). Measures the monetary flow through the eToro <-> eMoney wallet channel. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_OtherActions` COMMENT 'Total value of externally-funded actions (FundingTypeID != 33). (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_OtherActionsByeMoneyClients` COMMENT 'Total value of external-funded actions by customers who are eToro Money participants. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_eMoneyActionsByeMoneyClients` COMMENT 'Total value of eMoney-funded actions by customers who are eToro Money participants. The primary monetary signal for eToro Money platform adoption. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `UpdateDate` COMMENT 'ETL run timestamp - GETDATE() at INSERT time. Indicates when this date''s rows were last computed. (Tier 2 - SP_eMoney_Daily_MIMO)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Type_of_IBAN` COMMENT 'First 2 characters of the customer''s BankAccountIBAN from eMoney_Dim_Account - the IBAN country code (e.g., GB=UK, FR=France, DE=Germany, AU=Australia). NULL for customers without an IBAN or not in eMoney_Dim_Account. Added 2024-09-24. (Tier 2 - SP_eMoney_Daily_MIMO via eMoney_Dim_Account.BankAccountIBAN)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `ActionDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `ActionType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `FundingType` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `IsValid` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Seniority_daily_FTD_Group` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Is_Corporate_Account` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_TotalActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_UniqueGCIDs` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_eMoneyActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_OtherActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_OtherActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `CNT_eMoneyActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_TotalActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_eMoneyActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_OtherActions` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_OtherActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Value_eMoneyActionsByeMoneyClients` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_daily_mimo_new_reports_action ALTER COLUMN `Type_of_IBAN` SET TAGS ('pii' = 'direct');
