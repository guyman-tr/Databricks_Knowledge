-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CID_DailyPanel_Club
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CID_DailyPanel_Club > Daily per-customer panel for eToro Club loyalty members (Silver - Diamond tiers, plus customers who downgraded back to Bronze). Each row captures a customer''s current tier, tier-change history, equity, revenue, MIMO, credit line, interest, and Moneyfarm/eMoney balances for one calendar day. 67 columns. Covers 1.6B rows from 2020-01-01 to present across 1.1M distinct Club-eligible customers. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | BI_DB_ClubChangeLogProduct (primary) + DWH_dbo.V_Liabilities, BI_DB_DepositWithdrawFee, BI_DB_DailyCommisionReport, BI_DB_Daily_CreditLine, eMoney_dbo.CustomerEODBalance, External Moneyfarm / Interest tables | | **Refresh** | Daily - DELETE WHERE DateID = @ddINT + INSERT (SP_CID_DailyPanel_Club, SB_Daily process, Priority 0) | | | | | **Synapse '
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DateID COMMENT 'ETL date key in YYYYMMDD format. Identifies the report date as an integer. CLUSTERED INDEX key - always filter on DateID for performance. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Date COMMENT 'Calendar date corresponding to DateID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CID COMMENT 'Customer identifier (RealCID). FK into DWH_dbo.Dim_Customer. One row per CID per DateID; scope is Club-eligible members only (see Business Meaning). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TierChangeDate COMMENT 'Date of the customer''s most recent club tier change event (from BI_DB_ClubChangeLogProduct.Date). Static per CID until the next change event. (T1 - BI_DB_ClubChangeLogProduct wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TierChangeType COMMENT 'Type of most recent tier change: ''Upgrade'' (moved to higher tier), ''Downgrade'' (moved to lower tier), ''First Club'' (legacy first tier assignment), ''FirstClub'' (current first tier assignment). Dual spelling for first-assignment - filter using IN (''FirstClub'', ''First Club''). (T1 - BI_DB_ClubChangeLogProduct wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsUpgrade COMMENT '1 if this CID was upgraded on this specific DateID (TierChangeDate = Date AND TierChangeType IN (''Upgrade'',''First Club'') AND CurrentTier > 1); 0 otherwise. Day-specific flag for CRM upgrade events. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsDowngrade COMMENT '1 if this CID was downgraded on this specific DateID; 0 otherwise. Day-specific flag for CRM downgrade communications. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CurrentTier COMMENT 'PlayerLevelID of the customer''s current club tier as of DateID. Non-sequential: 1=Bronze, 5=Silver, 3=Gold, 2=Platinum, 6=Platinum Plus, 7=Diamond. Use JOIN to Dim_PlayerLevel for display names. (T1 - DWH_dbo.Dim_PlayerLevel wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN LastTier COMMENT 'PlayerLevelID of the customer''s tier before their most recent change (BI_DB_ClubChangeLogProduct.OldTier). NULL for first-ever club assignment. Same non-sequential ID mapping as CurrentTier. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN MaxTier COMMENT 'PlayerLevelID of the highest tier the customer has ever achieved. Derived from MAX(CurrentSort) OVER (PARTITION BY CID) -> Dim_PlayerLevel.PlayerLevelID via Sort. Useful for identifying loyal/lapsed high-value customers. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CountryID COMMENT 'Customer''s country of residence. FK into DWH_dbo.Dim_Country. Sourced from Dim_Country via Fact_SnapshotCustomer.CountryID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RegulationID COMMENT 'Regulatory entity governing the customer. 1=CySEC (EU), and other values for other regulators. Used to determine credit line eligibility (IsCreditEligible requires RegulationID=1). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsProCustomer COMMENT '1 if customer is classified as a MiFID Professional (MifidCategorizationID IN (2,3) in Fact_SnapshotCustomer); 0 otherwise. Professional customers have different trading limits and protections. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Classification COMMENT '**DEPRECATED - always NULL.** Previously held a cluster/segment classification (CID_DailyCluster). Removed 2022-01-03 (Tom Boksenbojm). Do not use. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN FTDDate COMMENT 'First Time Deposit date (Dim_Customer.FirstDepositDate). The date the customer made their first ever deposit. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN FTCDate COMMENT 'First Time Club date - the date of the customer''s first-ever promotion above Bronze (IsFTC=1 in BI_DB_ClubChangeLogProduct). NULL if the customer has not yet been promoted above Bronze. (T1 - BI_DB_ClubChangeLogProduct wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFTC COMMENT '1 if the customer''s FTCDate falls on this DateID (i.e., they are being promoted above Bronze for the first time on this date); 0 otherwise. Note: can be NULL in older data for customers whose FTC was before the start of the table. (T1 - BI_DB_ClubChangeLogProduct wiki)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysTillFTC COMMENT 'Number of days between FTDDate and FTCDate (DATEDIFF DAY). Measures how long it took the customer to reach Club status after first deposit. NULL if FTCDate is NULL. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysFromFTD COMMENT 'Number of days between FTDDate and DateID (DATEDIFF DAY). Customer age since first deposit. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysInClub COMMENT 'Number of days between FTCDate and DateID (DATEDIFF DAY). How long the customer has been a Club member (any tier above Bronze). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysInCurrentClub COMMENT 'Number of days between TierChangeDate and DateID (DATEDIFF DAY). How long the customer has been at their current tier level. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquity COMMENT 'Customer''s total account equity including CFD open positions (from DWH_dbo.V_Liabilities). Used for tier evaluation in pre-2023 data. Post-2023, RealizedEquityClub is the tier-qualification metric. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Equity COMMENT 'Net equity = V_Liabilities.Liabilities + V_Liabilities.ActualNWA. Includes open position market value. Used for IsFunded and IsCreditEligible thresholds. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Revenue COMMENT 'Daily revenue earned by the customer. Post-2023-08-23: SUM(RollOverFee + FullCommissions) from BI_DB_DailyCommisionReport. Pre-2023: from Fact_CustomerAction (open commissions + close commissions + rollover). Revenue methodology changed on 2023-08-23 - cross-date trends should account for this. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN InvestedAmount COMMENT 'Total notional USD opened in new trading positions on DateID. Pre-2023-08-23: -1 * SUM(Amount WHERE ActionTypeID IN (1,2,3,39)) from Fact_CustomerAction. Post-2023-01-01: SUM(MoneyIn WHERE ActionTypeID IN (1,15,17)). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFundedCurrentTier COMMENT '1 if the customer''s RealizedEquityClub (post-2023) or RealizedEquity (pre-2023) falls within the LowerBound - UpperBound for their CurrentTier. 0 if not funded at tier level. Key metric for downgrade risk assessment. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFunded COMMENT '1 if Equity > 25 (minimal "has money" threshold). Broad flag distinguishing customers with meaningful account balance from empty accounts. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AmountToUpgrade COMMENT 'USD amount needed to qualify for the next higher tier: next tier''s LowerBound - RealizedEquityClub. 0 for Diamond customers (already at highest tier). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AmountToRemain COMMENT 'USD amount the customer is below their current tier''s LowerBound (if negative equity position): LowerBound - RealizedEquityClub when below threshold, else 0. Non-zero values indicate downgrade risk. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsExpectedDowngrade COMMENT '**DEPRECATED - hardcoded 0.** Previously populated from ClubService downgrade-risk external table. External table service decommissioned. Do not use. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradePlayerLevelID COMMENT '**DEPRECATED - hardcoded 0.** See IsExpectedDowngrade. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsOptInInterest COMMENT '1 if the customer has active Interest on Balance (IOB) consent as of DateID (ConsentStatusID=1 in External_Interest_Trade_InterestConsent). 0 if no consent or opted-out. Available post-2023-08-23; 0 for historical dates. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN OptInDate COMMENT 'Date the customer''s most recent IOB consent took effect (ValidFrom of most recent consent record). ''1900-01-01'' if not opted in or historical data. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositAmount COMMENT 'Total deposit amount in USD on DateID from BI_DB_DepositWithdrawFee (TransactionType=''Deposit''). 0 if no deposits. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositTransactions COMMENT 'Count of distinct deposit transactions on DateID (COUNT DISTINCT DepositWithdrawID WHERE Deposit). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositAmountWireTransfer COMMENT 'Deposit amount via Wire Transfer payment method on DateID. Subset of DepositAmount. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositWireTransferTransactions COMMENT 'Count of deposit transactions via Wire Transfer on DateID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositConversionFee COMMENT 'Currency conversion fee applied on deposits: SUM((BaseExchangeRate - ExchangeRate) * Amount). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositConversionFeeExemption COMMENT 'Wire Transfer conversion fee exemption value for Platinum/Platinum Plus (0.25%) and Diamond (0.5%) customers. Amount the customer was not charged due to their Club tier benefit. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmount COMMENT 'Total withdrawal amount in USD on DateID (-1 * AmountUSD WHERE TransactionType=''Withdraw''). 0 if no withdrawals. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmountWireTransfer COMMENT 'Withdrawal amount via Wire Transfer on DateID. Subset of WithdrawAmount. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawTransactions COMMENT 'Count of distinct withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawWireTransferTransactions COMMENT 'Count of Wire Transfer withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmountWallet COMMENT 'Withdrawal amount to eToro Crypto Wallet on DateID (PaymentMethod=''eToroCryptoWallet''). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawWalletTransactions COMMENT 'Count of Crypto Wallet withdrawal transactions on DateID. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawConversionFee COMMENT 'Currency conversion fee on withdrawals: SUM((BaseExchangeRate - ExchangeRate) * Amount) WHERE Withdraw. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawConversionFeeExemption COMMENT 'Wire Transfer conversion fee exemption value for Platinum/Platinum Plus (0.25%) and Diamond (0.5%) customers on withdrawals. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CashoutFeeExemption COMMENT 'Cashout flat-fee exemption value for Platinum/Platinum Plus/Diamond customers (PlayerLevelID IN (2,6,7)): COUNT(Withdrawals) * PotentialFee (25 USD pre-2020-02-19, 5 USD after). Amount not charged due to Club tier. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CashoutFeePaid COMMENT 'Actual cashout processing fee paid by the customer on DateID (MAX(Fee) per WithdrawID from DWH_dbo.Fact_BillingWithdraw). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TotalCLAmount COMMENT 'Total outstanding credit line balance (USD) from BI_DB_Daily_CreditLine. 0 if no credit line. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DailyFee COMMENT 'Daily accruing fee on the customer''s outstanding credit line balance. From BI_DB_Daily_CreditLine. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsOpenCreditLine COMMENT '1 if the customer has an open credit line (DateReceive IS NOT NULL in BI_DB_Daily_CreditLine). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsClosedCreditLine COMMENT '1 if the customer''s credit line has been closed (DateDeduct IS NOT NULL AND TotalCLAmount <= 0). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsCreditLineCustomer COMMENT '1 if the customer currently has an active credit line balance (TotalCLAmount > 0). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsCreditEligible COMMENT '1 if the customer meets criteria for credit line eligibility: Equity >= 10,000 USD AND RegulationID = 1 (CySEC) AND Dim_PlayerLevel.Sort > 1 (above Bronze). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DailyCalculationInterest COMMENT 'Daily interest earned on eligible cash balance under the Interest on Balance (IOB) program. From External_Interest_Trade_InterestDaily_CID_DailyPanelClub. 0 if not opted in or external table missing. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN MonthlyInterestPayments COMMENT '**DEPRECATED - hardcoded 0.** Previously tracked monthly interest payment count. Removed from active SP logic. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last inserted by SP_CID_DailyPanel_Club (GETDATE() at INSERT time). (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeDate COMMENT '**DEPRECATED - hardcoded ''1900-01-01''.** External downgrade-risk service decommissioned. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeTierLT COMMENT '**DEPRECATED - hardcoded 0.** See ExpectedDowngradeDate. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AccountManagerID COMMENT 'Assigned Account Manager ID from Fact_SnapshotCustomer. FK into AM dimension. Used by AM teams to associate Club members with their designated manager. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquityNoCFD COMMENT 'Equity from real (non-leveraged, non-CFD) assets only: V_Liabilities.TotalRealStocks + TotalRealCrypto + TotalCash. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Moneyfarm COMMENT 'Customer''s total Moneyfarm investment value in USD (SUM(CalculatedAmountInUSD) by GCID from External_MoneyFarm_CID_DailyPanelClub). 0 if no Moneyfarm investment or external table missing. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN eMoneyBalance COMMENT 'Customer''s eToro Money wallet balance in USD (eMoney_dbo.CustomerEODBalance.EODBalanceAmount_USD, most recent EOD balance by GCID as of DateID). 0 if no eMoney account. Component of RealizedEquityClub. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquityClub COMMENT '**Club-eligible equity** used for tier qualification (post-2023): RealizedEquityNoCFD + eMoneyBalance + Moneyfarm. Excludes CFD positions. This is the metric against which tier thresholds are evaluated: IsFundedCurrentTier, AmountToUpgrade, AmountToRemain. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeStartDate COMMENT '**DEPRECATED - hardcoded ''1900-01-01''.** See ExpectedDowngradeDate. (T2 - SP_CID_DailyPanel_Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN LastContacted COMMENT 'Timestamp of the customer''s most recent successful contact by an Account Manager, sourced from BI_DB_UsageTracking_SF (Salesforce). Considers only ActionName IN (''Phone_Call_Succeed__c'', ''Completed_Contact_Email__c''). NULL if never contacted. (T2 - SP_CID_DailyPanel_Club)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TierChangeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TierChangeType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsUpgrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsDowngrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CurrentTier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN LastTier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN MaxTier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CountryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsProCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Classification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN FTDDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN FTCDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFTC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysTillFTC SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysFromFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysInClub SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DaysInCurrentClub SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Equity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Revenue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN InvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFundedCurrentTier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsFunded SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AmountToUpgrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AmountToRemain SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsExpectedDowngrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradePlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsOptInInterest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN OptInDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositAmountWireTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositWireTransferTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositConversionFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DepositConversionFeeExemption SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmountWireTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawWireTransferTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawAmountWallet SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawWalletTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawConversionFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN WithdrawConversionFeeExemption SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CashoutFeeExemption SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN CashoutFeePaid SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN TotalCLAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DailyFee SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsOpenCreditLine SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsClosedCreditLine SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsCreditLineCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN IsCreditEligible SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN DailyCalculationInterest SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN MonthlyInterestPayments SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeTierLT SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN AccountManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquityNoCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN Moneyfarm SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN eMoneyBalance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN RealizedEquityClub SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN ExpectedDowngradeStartDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN LastContacted SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:27:16 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 136/136 succeeded
-- ====================
