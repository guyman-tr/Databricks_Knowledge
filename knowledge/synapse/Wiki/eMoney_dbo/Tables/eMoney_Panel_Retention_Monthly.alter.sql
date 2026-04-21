-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Panel_Retention_Monthly
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Report_Month` COMMENT 'Calendar month identifier in YYYYMM format (e.g., 202604). Computed as `year(Report_Date)*100+month(Report_Date)` from the #RelDays temp table in SP_eMoney_Panel_Retention. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Date_for_Report` COMMENT 'The actual date from which the row was extracted; the end-of-month (EOM) snapshot date, i.e., `MAX(Report_Date)` within the Report_Month in eMoney_Panel_Retention_Daily. For completed months this is the last day of the month present in Daily; for the current month it is the latest loaded date. Passthrough from eMoney_Panel_Retention_Daily.Report_Date. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `GCID` COMMENT 'Global Customer ID; the eToro platform master customer identifier. Passthrough from eMoney_Panel_Retention_Daily. See Daily wiki for full description. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CID` COMMENT 'Customer ID; primary eToro customer identifier. Distribution key (HASH). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `ClubID` COMMENT 'eToro Club tier numeric ID from DWH_dbo.Dim_PlayerLevel. 1=Bronze, 2=Platinum, 3=Gold, 5=Silver, 6=Platinum Plus, 7=Diamond. Reflects the customer''s club status on Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Club` COMMENT 'Club tier display name. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `ClubCategory` COMMENT 'Coarse club bracket: NoClub (ClubID=1), LowClub (ClubID IN (3,5)), HighClub (ClubID IN (2,6,7)), Internal (ClubID=4). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CountryID` COMMENT 'Customer country of residence numeric ID from DWH_dbo.Dim_Country as of Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Country` COMMENT 'Country display name. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_TP_RegDate` COMMENT 'Days elapsed from eToro trading platform registration date to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_TP_FTDDate` COMMENT 'Days elapsed from first eToro trading deposit (FTD) to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_eMoney_AccCreatedDate` COMMENT 'Days elapsed from eMoney account creation date to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_eMoney_FMIDate` COMMENT 'Days elapsed from first eMoney MIMO action (FMI) to Date_for_Report. Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT` COMMENT 'Lifetime total MIMO transaction volume (USD), all funding types, ActionTypeID IN (7,8). Passthrough from eMoney_Panel_Retention_Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT` COMMENT 'Lifetime eMoney MIMO volume (USD); FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT` COMMENT 'Lifetime non-eMoney MIMO volume (USD); FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M` COMMENT 'MIMO volume (USD) in trailing 3-month window, all funding types. As of Date_for_Report (EOM). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M` COMMENT 'eMoney MIMO volume (USD) in trailing 3-month window; FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M` COMMENT 'Non-eMoney MIMO volume (USD) in trailing 3-month window; FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M_CO` COMMENT 'Cancellation/withdrawal volume (USD) in trailing 3-month window, all funding types, ActionTypeID=8. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M_CO` COMMENT 'eMoney cancellation/withdrawal volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M_CO` COMMENT 'Non-eMoney cancellation/withdrawal volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M_Deposits` COMMENT 'Deposit volume (USD) in trailing 3-month window, all funding types, ActionTypeID=7. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M_Deposits` COMMENT 'eMoney deposit volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M_Deposits` COMMENT 'Non-eMoney deposit volume (USD) in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT_CO` COMMENT 'Lifetime total cancellation/withdrawal volume (USD), all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT_CO` COMMENT 'Lifetime eMoney cancellation/withdrawal volume (USD). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT_CO` COMMENT 'Lifetime non-eMoney cancellation/withdrawal volume (USD). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT_Deposits` COMMENT 'Lifetime total deposit volume (USD), all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT_Deposits` COMMENT 'Lifetime eMoney deposit volume (USD). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT_Deposits` COMMENT 'Lifetime non-eMoney deposit volume (USD). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT` COMMENT 'Lifetime total MIMO transaction count, all funding types, ActionTypeID IN (7,8). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT` COMMENT 'Lifetime eMoney MIMO transaction count; FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT` COMMENT 'Lifetime non-eMoney MIMO transaction count; FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M` COMMENT 'MIMO transaction count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M` COMMENT 'eMoney MIMO count in trailing 3-month window; FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M` COMMENT 'Non-eMoney MIMO count in trailing 3-month window; FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M_CO` COMMENT 'Cancellation/withdrawal count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M_CO` COMMENT 'eMoney cancellation/withdrawal count in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M_CO` COMMENT 'Non-eMoney cancellation/withdrawal count in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M_Deposits` COMMENT 'Deposit count in trailing 3-month window, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M_Deposits` COMMENT 'eMoney deposit count in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M_Deposits` COMMENT 'Non-eMoney deposit count in trailing 3-month window. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT_CO` COMMENT 'Lifetime total cancellation/withdrawal count, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT_CO` COMMENT 'Lifetime eMoney cancellation/withdrawal count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT_CO` COMMENT 'Lifetime non-eMoney cancellation/withdrawal count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT_Deposits` COMMENT 'Lifetime total deposit count, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT_Deposits` COMMENT 'Lifetime eMoney deposit count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT_Deposits` COMMENT 'Lifetime non-eMoney deposit count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT` COMMENT 'Lifetime eMoney activity tier by transaction volume. eMoney_Inactive (eMoneyActions_LT=0), Low_Active (eMoney share <= 80%), High_Active (eMoney share > 80%). Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M` COMMENT 'Trailing 3-month eMoney tier by volume. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_3M. Passthrough from Daily as of EOM date. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT` COMMENT 'Lifetime eMoney tier by transaction count. Same logic as Amount_Tier_LT on CNT columns. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M` COMMENT 'Trailing 3-month eMoney tier by count. Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_3M. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT_Deposits` COMMENT 'Lifetime eMoney tier by deposit-only volume. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M_Deposits` COMMENT 'Trailing 3-month eMoney tier by deposit volume; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT_Deposits` COMMENT 'Lifetime eMoney tier by deposit count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M_Deposits` COMMENT 'Trailing 3-month eMoney tier by deposit count; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT_CO` COMMENT 'Lifetime eMoney tier by cancellation/withdrawal volume. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M_CO` COMMENT 'Trailing 3-month eMoney tier by CO volume; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT_CO` COMMENT 'Lifetime eMoney tier by CO count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M_CO` COMMENT 'Trailing 3-month eMoney tier by CO count; adds No_MIMO_3M. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly` COMMENT 'Total MIMO volume (USD) in the calendar month of Report_Month; all funding types. In the Monthly table this captures the full month''s activity as of Date_for_Report. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly` COMMENT 'eMoney MIMO volume (USD) for the calendar month; FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly` COMMENT 'Non-eMoney MIMO volume (USD) for the calendar month; FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly` COMMENT 'Total MIMO transaction count for the calendar month, all funding types. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly` COMMENT 'eMoney transaction count for the calendar month; FundingTypeID=33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly` COMMENT 'Non-eMoney transaction count for the calendar month; FundingTypeID<>33. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly_Deposits` COMMENT 'Total deposit volume (USD) for the calendar month; ActionTypeID=7. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly_Deposits` COMMENT 'eMoney deposit volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly_Deposits` COMMENT 'Non-eMoney deposit volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly_Deposits` COMMENT 'Total deposit count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly_Deposits` COMMENT 'eMoney deposit count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly_Deposits` COMMENT 'Non-eMoney deposit count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly_CO` COMMENT 'Total cancellation/withdrawal volume (USD) for the calendar month; ActionTypeID=8. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly_CO` COMMENT 'eMoney cancellation/withdrawal volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly_CO` COMMENT 'Non-eMoney cancellation/withdrawal volume (USD) for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly_CO` COMMENT 'Total cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly_CO` COMMENT 'eMoney cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly_CO` COMMENT 'Non-eMoney cancellation/withdrawal count for the calendar month. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly` COMMENT 'Calendar-month eMoney activity tier by volume. In the Monthly table, this captures the full-month tier as of Date_for_Report (EOM). Values: eMoney_Inactive, Low_Active, High_Active, No_MIMO_Monthly. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly` COMMENT 'Calendar-month eMoney tier by transaction count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly_Deposits` COMMENT 'Calendar-month eMoney tier by deposit volume; adds No_MIMO_Monthly. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly_Deposits` COMMENT 'Calendar-month eMoney tier by deposit count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly_CO` COMMENT 'Calendar-month eMoney tier by CO volume; adds No_MIMO_Monthly. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly_CO` COMMENT 'Calendar-month eMoney tier by CO count. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `UpdateDate` COMMENT 'ETL batch timestamp; set to GETDATE() at SP execution time. Passthrough from Daily. (Tier 2 - SP_eMoney_Panel_Retention)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Report_Month` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Date_for_Report` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `ClubID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `ClubCategory` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_TP_RegDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_TP_FTDDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_eMoney_AccCreatedDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Seniority_eMoney_FMIDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_LT_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_3M_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_TotalActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_eMoneyActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Value_OtherActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_TotalActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_eMoneyActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `CNT_OtherActions_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly_Deposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `Amount_Tier_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `TX_Tier_Monthly_CO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_panel_retention_monthly ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
