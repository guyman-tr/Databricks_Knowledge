-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_MarketingCloudDaily
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_MarketingCloudDaily > 47.1M-row CRM enrichment table providing a one-row-per-customer (CID) daily snapshot of cross-platform activity, financial metrics, KYC attributes, eMoney card/fiat data, watchlist behavior, gain performance, life stage, cluster assignment, ISA portfolio status, and RAF (Refer-a-Friend) data - assembled by SP_MarketingCloudDaily from 20+ DWH/BI_DB/eMoney sources and uploaded to Salesforce Marketing Cloud via SFTP. Refreshed daily via SB_Daily (Priority 0). Data spans from 2022-01-18 to present. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Multi-source aggregation via SP_MarketingCloudDaily (Ben Einav, 2023-08-23) | | **Refresh** | Daily incremental merge (UPDATE existing + INSERT new CIDs per column-group). SB_Daily, Priority 0 | | **Synapse Distribution** | HASH(CID) | | *'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AccountId COMMENT 'Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Passthrough from Dim_Customer.SalesForceAccountID. (Tier 1 - BackOffice.Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. One row per CID. Each column-group block inserts new CIDs from its own source. Distribution key. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MobileAppLastLogin COMMENT 'Last mobile app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (104,105,110,111) AND ActionTypeID=14. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedETF COMMENT 'Last date an ETF instrument was added to this customer''s watchlist. MAX(ItemAddedDate) where InstrumentTypeID=6. Source: CopyFromLake.WatchListDB. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCrypto COMMENT 'Last date a crypto instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=10. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedStocks COMMENT 'Last date a stock instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=5. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCommodities COMMENT 'Last date a commodity instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=2. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedIndecies COMMENT 'Last date an index instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=4. Note: column name typo ("Indecies" instead of "Indices") preserved from DDL. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedPI COMMENT 'Last date a Popular Investor (GuruStatusID>=2) was added to watchlist. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCopyPortfolio COMMENT 'Last date a CopyPortfolio (AccountTypeID=9 post-2016 or 6 hardcoded RealCIDs) was added to watchlist. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedNonPIUser COMMENT 'Last date a non-PI, non-CopyPortfolio user was added to watchlist. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastDateID COMMENT 'Date key (YYYYMMDD) of the most recent watchlist add across all types. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainThisWeek COMMENT 'Customer''s portfolio gain percentage for the current week. From DWH_GainDaily.Gain_w where Date=@date. Zero if no open positions. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainOneMonthAgo COMMENT 'Portfolio gain percentage over the last month. From DWH_GainDaily.Gain_m. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainThreeMonthsAgo COMMENT 'Portfolio gain percentage over the last 3 months. From DWH_GainDaily.Gain_q. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainSixMonthsAgo COMMENT 'Portfolio gain percentage over the last 6 months. From DWH_GainDaily.Gain_h. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainOneYearAgo COMMENT 'Portfolio gain percentage over the last year. From DWH_GainDaily.Gain_y. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainLastDate COMMENT 'Date of the most recent gain calculation. Retained from prior run if no new gain data available. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainExecutionID COMMENT 'Execution batch ID from DWH_GainDaily. Retained from prior run if no new gain data. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN UpdateDate COMMENT 'ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on every column-group UPDATE/INSERT. (Tier 5 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyIsInRollout COMMENT 'Legacy column - no longer populated by current SP. All NULL. Originally indicated eMoney gradual rollout status. (Tier 4 - legacy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyIsInRolloutDate COMMENT 'Legacy column - no longer populated by current SP. All NULL. Originally date of eMoney rollout flag. (Tier 4 - legacy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirDropRemainder COMMENT 'Legacy column - no longer populated by current SP. All NULL. Originally airdrop token remainder. (Tier 4 - legacy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN VerificationLevel3Date COMMENT 'Date when the customer reached Verification Level 3 (full KYC). From BI_DB_CIDFirstDates.VerificationLevel3Date. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropServeyDate COMMENT 'Legacy column - no longer populated by current SP. All NULL. Note: column name typo ("Servey" instead of "Survey"). (Tier 4 - legacy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropPotentialUpdateDate COMMENT 'Legacy column - no longer populated by current SP. All NULL. (Tier 4 - legacy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WalletLastLogin COMMENT 'Last crypto wallet app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (118,119,120) AND ActionTypeID=14. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyExternalTransferToIBANLastDate COMMENT 'Last date of a completed external IBAN transfer (TransactionTypeId=7, StatusId=2). From eMoney_dbo.FiatTransactions. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyDepositToPlatformLastDate COMMENT 'Last date of a completed deposit to trading platform from eMoney (TransactionTypeId=6, StatusId=2). (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyWithrawalFromPlatformLastDate COMMENT 'Last date of a completed withdrawal from trading platform to eMoney (TransactionTypeId=5, StatusId=2). Note: column name typo ("Withrawal"). (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyEODBalanceAmount COMMENT 'eMoney end-of-day balance amount for the latest available date. From eMoney_dbo.CustomerEODBalance. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyEODBalanceDate COMMENT 'Date of the eMoney EOD balance snapshot. MAX(EODBalanceDate) per GCID. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyCardTransactionLastDate COMMENT 'Last settled card transaction date (TransactionCategory=1, excluding refunds/fees TransactionTypeId NOT IN (9,10), StatusId=2). (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYCFlowName COMMENT 'KYC flow short name from ComplianceStateDB. Normal=standard KYC, VBT=Video-Based Telephony, VBD=Video-Based Digital, HRC=High Risk Check. 4 distinct values. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYCLeadScore COMMENT 'Behavioral lead score cluster label from BI_DB_KYC_Score_CID_Level. Renamed from source column ''Cluster''. Values: 1-5 or ''No Cluster''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropCustomerID COMMENT 'System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). Passthrough from Dim_Customer.ID where IsValidCustomer=1. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Credit COMMENT 'Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. From V_Liabilities.Credit where DateID=@dateID. (Tier 1 - Fact_SnapshotEquity via V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN FirstTimeCopiedDate COMMENT 'Earliest date this customer was first copied (as a Popular Investor). MIN(Dim_Mirror.OpenOccurred) where MirrorTypeID<>4 (excludes Fund mirrors), joined on ParentCID. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN PrivacyPolicyID COMMENT 'Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LSD COMMENT 'Life Stage Definition label. Latest active status from BI_DB_CID_LifeStageDefinition (ToDateID=99991231). Values include: Dump Lead, Dump Churn, Lead, Holder, No Activity - Not Funded, Active Open Club, Active Open, Churn over 60 days, Active Open 30-90 days, Holder Club. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LSDDate COMMENT 'Date of the current life stage assignment. From BI_DB_CID_LifeStageDefinition.Date for the latest active record. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M COMMENT 'eMoney 3-month transaction tier. From eMoney_Panel_Retention_Daily. Values: No_MIMO_3M, High_Active, eMoney_Inactive, Low_Active. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M COMMENT 'eMoney 3-month amount tier. From eMoney_Panel_Retention_Daily. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M_Deposits COMMENT 'eMoney 3-month deposit transaction tier. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M_CO COMMENT 'eMoney 3-month cashout transaction tier. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M_CO COMMENT 'eMoney 3-month cashout amount tier. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M_Deposits COMMENT 'eMoney 3-month deposit amount tier. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AccountSubProgram COMMENT 'eMoney card/IBAN sub-program type. From eMoney_Dim_Account where AccountProgramID=1 AND IsValidETM=1. Values: Card Standard UK, Card Black EU, Card Premium UK, Card Green EU, IBAN EU Black, IBAN EU Green, IBAN LIMITED EU, Card Premium UAE. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CardCreateDate COMMENT 'Date the eMoney card was created. From eMoney_Dim_Account.CardCreateDate. Same filters as AccountSubProgram. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_Experience_Level COMMENT 'Customer''s self-reported trading experience from KYC questionnaire. From BI_DB_KYC_Panel.Experience_Level. Values: Non, Low, N/A, High, Med. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_Planned_Invested_Amount COMMENT 'Customer''s planned investment amount from KYC Q14. From BI_DB_KYC_Panel.Q14_AnswerText. Values: Up to $1k, $1k-$5k, Up to $20K, $20k-$50k, Above $1M, etc. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_CFD_Level COMMENT 'CFD experience classification computed from KYC answers. Level_0=no FX interest, Level_1=novice with FX+multi-answer, Level_2=experienced with FX or single-answer, NULL=incomplete data. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IOB_Opt_In COMMENT 'Interest on Balance consent status. Latest ConsentStatusID per CID from External_Interest_Trade_InterestConsent. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IOB_Opt_In_ValidFrom COMMENT 'Effective date of the IOB consent status. From External_Interest_Trade_InterestConsent.ValidFrom. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AmountToClubUpgrade COMMENT 'USD amount needed to reach next eToro Club tier. Club members: from CID_DailyPanel_Club.AmountToUpgrade. Non-club: gap to next threshold ($5K/$10K/$25K/$50K/$250K) from ClubService realized equity. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN UnRealizedEquity COMMENT 'Unrealized equity = Liabilities + ActualNWA from V_Liabilities at @dateID. Represents the customer''s total equity including unrealized P&L. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MaxEquity_LastYear COMMENT 'Maximum unrealized equity (Liabilities+ActualNWA) over the trailing 1 year from V_Liabilities. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MaxEquity_LastWeek COMMENT 'Maximum unrealized equity over the trailing 7 days from V_Liabilities. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CashoutAmount_LastWeek COMMENT 'Total cashout (withdrawal) amount in the last 7 days. SUM(Amount) from Fact_CustomerAction where ActionTypeID=8. Zero if no cashouts (LEFT JOIN with ISNULL). (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CashoutAmount_InProcess COMMENT 'Sum of pending withdrawal amounts not yet finalized. Direct from V_Liabilities.InProcessCashouts where DateID=@dateID. (Tier 1 - Fact_SnapshotEquity via V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TotalDepositsAmount_LastYear COMMENT 'Total deposit amount in the trailing 1 year. SUM(Amount) from Fact_CustomerAction where ActionTypeID=7. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_Stocks COMMENT 'Whether the customer indicated planned stock investment in KYC. From BI_DB_KYC_Panel.Is_PI_Stocks. 1=yes, 0=no. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_Crypto COMMENT 'Whether the customer indicated planned crypto investment. From BI_DB_KYC_Panel.Is_PI_Crypto. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_FX COMMENT 'Whether the customer indicated planned FX investment. From BI_DB_KYC_Panel.Is_PI_FX. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_KYC_PlannedInvestment_Answers COMMENT 'Count of distinct planned investment categories selected in KYC. From BI_DB_KYC_Panel.Total_PI_Answers. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN StocksLendingStatusID COMMENT 'Stocks lending consent status. Only populated where StocksLendingStatusID=1 (opted in) from Ext_Dim_Customer_StocksLending via Dim_Customer GCID join. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN StocksLendingOptInDate COMMENT 'Date of stocks lending opt-in consent. From Ext_Dim_Customer_StocksLending.ConsentDateTime where StocksLendingStatusID=1. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eTM_IBAN_Type COMMENT 'IBAN country code prefix (first 2 characters of BankAccountIBAN). From eMoney_Dim_Account where IsValidETM=1 AND GCID_Unique_Count=1. E.g., MT, DE, GB. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eTM_AccountName_LocalCurrency COMMENT 'eMoney account local currency description. From eMoney_Dim_Account.CurrencyBalanceISODesc. E.g., EUR, GBP. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cluster COMMENT 'Customer behavioral cluster assignment. From BI_DB_CID_DailyCluster.ClusterDetail. 6 values: Crypto, Equities Investors, Equities Crypto, Equities Traders, Leveraged Traders, Diversified Traders. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN ClusterDate COMMENT 'Date of the cluster assignment. From BI_DB_CID_DailyCluster.FromDate. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN PositionOpen_LastDate_ETF COMMENT 'Date of the last ETF position opened by this customer. MAX(Dim_Position.OpenOccurred) where Dim_Instrument.InstrumentTypeID=6, MirrorID=0 (non-copy), IsPartialCloseChild=0, IsAirDrop=0. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Rewarded_LastMonth_eMoney COMMENT 'Month reference for the eMoney card cashback calculation. DATEFROMPARTS of prior month. Only updated on the 1st of each month. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_CardSpent_eMoney COMMENT 'Total card spend for the prior month (HolderAmount * -1). Only updated on the 1st of each month. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_RewardedChashBack_eMoney COMMENT 'Cashback amount rewarded for the prior month. 4% of eligible spend, capped at 1500. Only updated on the 1st of each month. Note: column name typo ("Chash" instead of "Cash"). (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_CardEligibleCashBack_eMoney COMMENT 'Eligible card spend for cashback (excludes gambling/crypto/money transfer MCCs). Only updated on the 1st of each month. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN FirstDepositDateGlobal COMMENT 'First deposit date across all platforms (trading + IBAN). From Function_MIMO_First_Deposit_All_Platforms(1). Only populated for CIDs whose first deposit was on @date. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DepositsUSD_Global COMMENT 'Cumulative deposit amount in USD across all platforms. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOAction=''Deposit'' AND IsInternalTransfer=0. Updated for CIDs with a deposit on @date. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN BalanceGlobal COMMENT 'Global balance = CreditTP + IBANBalance from DDR_Fact_AUM at @dateID. Combines trading platform and eMoney balances. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN EquityGlobal COMMENT 'Global equity from DDR_Fact_AUM.EquityGlobal at @dateID. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_USD COMMENT 'Cumulative trading platform deposits in USD. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOPlatform=''TradingPlatform''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_EUR COMMENT 'Cumulative eMoney deposits in EUR. SUM(AmountOrigCurrency) where MIMOPlatform=''eMoney'' AND CurrencyID=2. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_GBP COMMENT 'Cumulative eMoney deposits in GBP. SUM(AmountOrigCurrency) where MIMOPlatform=''eMoney'' AND CurrencyID=3. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_USD COMMENT 'Current trading platform USD balance. From DDR_Fact_AUM.CreditTP at @dateID. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_EUR COMMENT 'Current eMoney EUR balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=978 AND GCID_Unique_Count=1. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_GBP COMMENT 'Current eMoney GBP balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=826 AND GCID_Unique_Count=1. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LastTransactionDate COMMENT 'Last settled eMoney card transaction date. MAX(eMoney_Panel_FirstDates.LastCardSettledTXDate) where IsValidETM=1. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AcceptedTnCs_Date COMMENT 'Date the customer accepted ISA Terms & Conditions. From BI_OUTPUT_Customer_External_Table_ISA. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DIY_PortfolioCreatedDate COMMENT 'ISA execution-only (DIY) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code=''isa-execution-only''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DIY_FirstDepositDate COMMENT 'First deposit date into the DIY ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code=''isa-execution-only''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cash_PortfolioCreatedDate COMMENT 'ISA cash portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code=''isa-cash''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cash_FirstDepositDate COMMENT 'First deposit date into the cash ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code=''isa-cash''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Managed_PortfolioCreatedDate COMMENT 'ISA discretionary (managed) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code=''isa-discretionary''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Managed_FirstDepositDate COMMENT 'First deposit date into the managed ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code=''isa-discretionary''. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IsDefunded_across_all_portfolios COMMENT 'Whether ALL of the customer''s ISA portfolios are defunded. 1=all defunded, 0=at least one funded. MIN(CASE WHEN PortfolioDefunded=1 THEN 1 ELSE 0 END) across all portfolios. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN RAF_Inviter COMMENT 'GCID of the person who invited this customer via Refer-a-Friend. From BI_DB_RAF_Invitees_KPIs.Inviter -> Dim_Customer.GCID. Note: stored as decimal, not int. (Tier 2 - SP_MarketingCloudDaily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN RAF_LastCashoutDate COMMENT 'Last cashout date from the RAF program for this invitee. MAX(LastCashoutDate) from BI_DB_RAF_Invitees_KPIs. (Tier 2 - SP_MarketingCloudDaily)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MobileAppLastLogin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedETF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCrypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedStocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCommodities SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedIndecies SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedPI SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedCopyPortfolio SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastAddedNonPIUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WatchlistLastDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainThisWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainOneMonthAgo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainThreeMonthsAgo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainSixMonthsAgo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainOneYearAgo SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN GainExecutionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyIsInRollout SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyIsInRolloutDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirDropRemainder SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN VerificationLevel3Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropServeyDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropPotentialUpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN WalletLastLogin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyExternalTransferToIBANLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyDepositToPlatformLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyWithrawalFromPlatformLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyEODBalanceAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyEODBalanceDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eMoneyCardTransactionLastDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYCFlowName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYCLeadScore SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AirdropCustomerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Credit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN FirstTimeCopiedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN PrivacyPolicyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LSDDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M_Deposits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TX_Tier_3M_CO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M_CO SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Amount_Tier_3M_Deposits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AccountSubProgram SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CardCreateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_Experience_Level SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_Planned_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_CFD_Level SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IOB_Opt_In SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IOB_Opt_In_ValidFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AmountToClubUpgrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN UnRealizedEquity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MaxEquity_LastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN MaxEquity_LastWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CashoutAmount_LastWeek SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN CashoutAmount_InProcess SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN TotalDepositsAmount_LastYear SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_Stocks SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_Crypto SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN KYC_PlannedInvestment_FX SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_KYC_PlannedInvestment_Answers SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN StocksLendingStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN StocksLendingOptInDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eTM_IBAN_Type SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN eTM_AccountName_LocalCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cluster SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN ClusterDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN PositionOpen_LastDate_ETF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Rewarded_LastMonth_eMoney SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_CardSpent_eMoney SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_RewardedChashBack_eMoney SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Monthly_CardEligibleCashBack_eMoney SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN FirstDepositDateGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DepositsUSD_Global SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN BalanceGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN EquityGlobal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_EUR SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Total_Deposit_GBP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_EUR SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Current_Balance_GBP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN LastTransactionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN AcceptedTnCs_Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DIY_PortfolioCreatedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN DIY_FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cash_PortfolioCreatedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Cash_FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Managed_PortfolioCreatedDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN Managed_FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN IsDefunded_across_all_portfolios SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN RAF_Inviter SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily ALTER COLUMN RAF_LastCashoutDate SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:02:45 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 196/196 succeeded
-- ====================
