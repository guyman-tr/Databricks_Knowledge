# BI_DB_dbo.BI_DB_MarketingCloudDaily_V

> UC-facing Gold view exposing BI_DB_MarketingCloudDaily rows where AccountId is populated (Salesforce linkage present), plus Lakehouse partition keys etr_*.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | View |
| **Production Source** | BI_DB_MarketingCloudDaily (multi-source merges via SP_MarketingCloudDaily -- see base wiki) |
| **Refresh** | Follows BI_DB_MarketingCloudDaily merge + UC Gold ingestion |
| | |
| **Synapse Distribution** | N/A |
| **Synapse Index** | N/A |
| | |
| **UC Target** | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v |
| **UC View definition** | SELECT * FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily WHERE AccountId IS NOT NULL |

---

## 1. Business Meaning

Databricks DESCRIBE TABLE EXTENDED surfaced the verbatim View Text above during the speckit run on 2026 May 14. Consumers who need **only CRM-linked customers** should read this view rather than the Synapse table, because the predicate eliminates NULL AccountId rows prior to Lakehouse export.

---

## 2. Business Logic

### 2.1 Predicate

**What**: Enforce AccountId presence before Gold export.

**Columns Involved**: AccountId.

**Rules**:
- WHERE AccountId IS NOT NULL (verbatim UC view DDL).

### 2.2 All other columns

Defer to Sections 2.1-2.7 inside Tables/BI_DB_MarketingCloudDaily.md; no recomputation occurs in the view projection.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Synapse workloads still execute against BI_DB_MarketingCloudDaily (HASH(CID)); UC view inherits metadata only indirectly.

### 3.1b UC partitioning

Leverage filters on etr_y, etr_ym, etr_ymd identical to sibling Gold tables.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| CRM-linked cohort only | SELECT from this _v object |
| Entire CID panel incl. Salesforce gaps | Use base Gold table Synapse parity |

### 3.3 Common JOINs

Match base wiki join roadmap (Dim_Customer, BI_DB_CID_DailyCluster, DDR_Fact_AUM, eMoney satellites).

### 3.4 Gotchas

Filtered row counts omit customers lacking Salesforce linkage; denominators diverge versus base aggregates.

---

## 4. Elements

### Confidence Tier Legend

Inherited from BI_DB_MarketingCloudDaily (Tier 1-5 mixture); see canonical wiki star mapping.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountId | nvarchar(18) | YES | AccountId projected from BI_DB_MarketingCloudDaily (see base table wiki). Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Passthrough from Dim_Customer.SalesForceAccountID. (Tier 1 — BackOffice.Customer) |
| 2 | CID | int | NO | CID projected from BI_DB_MarketingCloudDaily (see base table wiki). Customer ID — platform-internal primary key. One row per CID. Each column-group block inserts new CIDs from its own source. Distribution key. (Tier 2 — SP_MarketingCloudDaily)|
| 3 | MobileAppLastLogin | datetime | YES | MobileAppLastLogin projected from BI_DB_MarketingCloudDaily (see base table wiki). Last mobile app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (104,105,110,111) AND ActionTypeID=14. (Tier 2 — SP_MarketingCloudDaily)|
| 4 | WatchlistLastAddedETF | datetime | YES | WatchlistLastAddedETF projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date an ETF instrument was added to this customer's watchlist. MAX(ItemAddedDate) where InstrumentTypeID=6. Source: CopyFromLake.WatchListDB. (Tier 2 — SP_MarketingCloudDaily)|
| 5 | WatchlistLastAddedCrypto | datetime | YES | WatchlistLastAddedCrypto projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a crypto instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=10. (Tier 2 — SP_MarketingCloudDaily)|
| 6 | WatchlistLastAddedStocks | datetime | YES | WatchlistLastAddedStocks projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a stock instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=5. (Tier 2 — SP_MarketingCloudDaily)|
| 7 | WatchlistLastAddedCommodities | datetime | YES | WatchlistLastAddedCommodities projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a commodity instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=2. (Tier 2 — SP_MarketingCloudDaily)|
| 8 | WatchlistLastAddedIndecies | datetime | YES | WatchlistLastAddedIndecies projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date an index instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=4. Note: column name typo ("Indecies" instead of "Indices") preserved from DDL. (Tier 2 — SP_MarketingCloudDaily)|
| 9 | WatchlistLastAddedPI | datetime | YES | WatchlistLastAddedPI projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a Popular Investor (GuruStatusID>=2) was added to watchlist. (Tier 2 — SP_MarketingCloudDaily)|
| 10 | WatchlistLastAddedCopyPortfolio | datetime | YES | WatchlistLastAddedCopyPortfolio projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a CopyPortfolio (AccountTypeID=9 post-2016 or 6 hardcoded RealCIDs) was added to watchlist. (Tier 2 — SP_MarketingCloudDaily)|
| 11 | WatchlistLastAddedNonPIUser | datetime | YES | WatchlistLastAddedNonPIUser projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date a non-PI, non-CopyPortfolio user was added to watchlist. (Tier 2 — SP_MarketingCloudDaily)|
| 12 | WatchlistLastDateID | int | YES | WatchlistLastDateID projected from BI_DB_MarketingCloudDaily (see base table wiki). Date key (YYYYMMDD) of the most recent watchlist add across all types. (Tier 2 — SP_MarketingCloudDaily)|
| 13 | GainThisWeek | decimal(16,4) | YES | GainThisWeek projected from BI_DB_MarketingCloudDaily (see base table wiki). Customer's portfolio gain percentage for the current week. From DWH_GainDaily.Gain_w where Date=@date. Zero if no open positions. (Tier 2 — SP_MarketingCloudDaily)|
| 14 | GainOneMonthAgo | decimal(16,4) | YES | GainOneMonthAgo projected from BI_DB_MarketingCloudDaily (see base table wiki). Portfolio gain percentage over the last month. From DWH_GainDaily.Gain_m. (Tier 2 — SP_MarketingCloudDaily)|
| 15 | GainThreeMonthsAgo | decimal(16,4) | YES | GainThreeMonthsAgo projected from BI_DB_MarketingCloudDaily (see base table wiki). Portfolio gain percentage over the last 3 months. From DWH_GainDaily.Gain_q. (Tier 2 — SP_MarketingCloudDaily)|
| 16 | GainSixMonthsAgo | decimal(16,4) | YES | GainSixMonthsAgo projected from BI_DB_MarketingCloudDaily (see base table wiki). Portfolio gain percentage over the last 6 months. From DWH_GainDaily.Gain_h. (Tier 2 — SP_MarketingCloudDaily)|
| 17 | GainOneYearAgo | decimal(16,4) | YES | GainOneYearAgo projected from BI_DB_MarketingCloudDaily (see base table wiki). Portfolio gain percentage over the last year. From DWH_GainDaily.Gain_y. (Tier 2 — SP_MarketingCloudDaily)|
| 18 | GainLastDate | date | YES | GainLastDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of the most recent gain calculation. Retained from prior run if no new gain data available. (Tier 2 — SP_MarketingCloudDaily)|
| 19 | GainExecutionID | int | YES | GainExecutionID projected from BI_DB_MarketingCloudDaily (see base table wiki). Execution batch ID from DWH_GainDaily. Retained from prior run if no new gain data. (Tier 2 — SP_MarketingCloudDaily)|
| 20 | UpdateDate | datetime | NO | UpdateDate projected from BI_DB_MarketingCloudDaily (see base table wiki). ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on every column-group UPDATE/INSERT. (Tier 5 — SP_MarketingCloudDaily)|
| 21 | eMoneyIsInRollout | int | YES | eMoneyIsInRollout projected from BI_DB_MarketingCloudDaily (see base table wiki). Legacy column — no longer populated by current SP. All NULL. Originally indicated eMoney gradual rollout status. (Tier 4 — legacy)|
| 22 | eMoneyIsInRolloutDate | datetime | YES | eMoneyIsInRolloutDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Legacy column — no longer populated by current SP. All NULL. Originally date of eMoney rollout flag. (Tier 4 — legacy)|
| 23 | AirDropRemainder | int | YES | AirDropRemainder projected from BI_DB_MarketingCloudDaily (see base table wiki). Legacy column — no longer populated by current SP. All NULL. Originally airdrop token remainder. (Tier 4 — legacy)|
| 24 | VerificationLevel3Date | date | YES | VerificationLevel3Date projected from BI_DB_MarketingCloudDaily (see base table wiki). Date when the customer reached Verification Level 3 (full KYC). From BI_DB_CIDFirstDates.VerificationLevel3Date. (Tier 2 — SP_MarketingCloudDaily)|
| 25 | AirdropServeyDate | date | YES | AirdropServeyDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Legacy column — no longer populated by current SP. All NULL. Note: column name typo ("Servey" instead of "Survey"). (Tier 4 — legacy)|
| 26 | AirdropPotentialUpdateDate | date | YES | AirdropPotentialUpdateDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Legacy column — no longer populated by current SP. All NULL. (Tier 4 — legacy)|
| 27 | WalletLastLogin | datetime | YES | WalletLastLogin projected from BI_DB_MarketingCloudDaily (see base table wiki). Last crypto wallet app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (118,119,120) AND ActionTypeID=14. (Tier 2 — SP_MarketingCloudDaily)|
| 28 | eMoneyExternalTransferToIBANLastDate | datetime | YES | eMoneyExternalTransferToIBANLastDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date of a completed external IBAN transfer (TransactionTypeId=7, StatusId=2). From eMoney_dbo.FiatTransactions. (Tier 2 — SP_MarketingCloudDaily)|
| 29 | eMoneyDepositToPlatformLastDate | datetime | YES | eMoneyDepositToPlatformLastDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date of a completed deposit to trading platform from eMoney (TransactionTypeId=6, StatusId=2). (Tier 2 — SP_MarketingCloudDaily)|
| 30 | eMoneyWithrawalFromPlatformLastDate | datetime | YES | eMoneyWithrawalFromPlatformLastDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last date of a completed withdrawal from trading platform to eMoney (TransactionTypeId=5, StatusId=2). Note: column name typo ("Withrawal"). (Tier 2 — SP_MarketingCloudDaily)|
| 31 | eMoneyEODBalanceAmount | money | YES | eMoneyEODBalanceAmount projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney end-of-day balance amount for the latest available date. From eMoney_dbo.CustomerEODBalance. (Tier 2 — SP_MarketingCloudDaily)|
| 32 | eMoneyEODBalanceDate | datetime | YES | eMoneyEODBalanceDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of the eMoney EOD balance snapshot. MAX(EODBalanceDate) per GCID. (Tier 2 — SP_MarketingCloudDaily)|
| 33 | eMoneyCardTransactionLastDate | datetime | YES | eMoneyCardTransactionLastDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last settled card transaction date (TransactionCategory=1, excluding refunds/fees TransactionTypeId NOT IN (9,10), StatusId=2). (Tier 2 — SP_MarketingCloudDaily)|
| 34 | KYCFlowName | varchar(50) | YES | KYCFlowName projected from BI_DB_MarketingCloudDaily (see base table wiki). KYC flow short name from ComplianceStateDB. Normal=standard KYC, VBT=Video-Based Telephony, VBD=Video-Based Digital, HRC=High Risk Check. 4 distinct values. (Tier 2 — SP_MarketingCloudDaily)|
| 35 | KYCLeadScore | nvarchar(50) | YES | KYCLeadScore projected from BI_DB_MarketingCloudDaily (see base table wiki). Behavioral lead score cluster label from BI_DB_KYC_Score_CID_Level. Renamed from source column 'Cluster'. Values: 1-5 or 'No Cluster'. (Tier 2 — SP_MarketingCloudDaily)|
| 36 | AirdropCustomerID | uniqueidentifier | YES | AirdropCustomerID projected from BI_DB_MarketingCloudDaily (see base table wiki). System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). Passthrough from Dim_Customer.ID where IsValidCustomer=1. (Tier 1 — Customer.CustomerStatic)|
| 37 | Credit | money | YES | Credit projected from BI_DB_MarketingCloudDaily (see base table wiki). Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. From V_Liabilities.Credit where DateID=@dateID. (Tier 2 — Fact_SnapshotEquity via V_Liabilities)|
| 38 | FirstTimeCopiedDate | datetime | YES | FirstTimeCopiedDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Earliest date this customer was first copied (as a Popular Investor). MIN(Dim_Mirror.OpenOccurred) where MirrorTypeID<>4 (excludes Fund mirrors), joined on ParentCID. (Tier 2 — SP_MarketingCloudDaily)|
| 39 | PrivacyPolicyID | int | YES | PrivacyPolicyID projected from BI_DB_MarketingCloudDaily (see base table wiki). Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic)|
| 40 | LSD | varchar(200) | YES | LSD projected from BI_DB_MarketingCloudDaily (see base table wiki). Life Stage Definition label. Latest active status from BI_DB_CID_LifeStageDefinition (ToDateID=99991231). Values include: Dump Lead, Dump Churn, Lead, Holder, No Activity - Not Funded, Active Open Club, Active Open, Churn over 60 days, Active Open 30-90 days, Holder Club. (Tier 2 — SP_MarketingCloudDaily)|
| 41 | LSDDate | date | YES | LSDDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of the current life stage assignment. From BI_DB_CID_LifeStageDefinition.Date for the latest active record. (Tier 2 — SP_MarketingCloudDaily)|
| 42 | TX_Tier_3M | varchar(100) | YES | TX_Tier_3M projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month transaction tier. From eMoney_Panel_Retention_Daily. Values: No_MIMO_3M, High_Active, eMoney_Inactive, Low_Active. (Tier 2 — SP_MarketingCloudDaily)|
| 43 | Amount_Tier_3M | varchar(100) | YES | Amount_Tier_3M projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month amount tier. From eMoney_Panel_Retention_Daily. (Tier 2 — SP_MarketingCloudDaily)|
| 44 | TX_Tier_3M_Deposits | varchar(100) | YES | TX_Tier_3M_Deposits projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month deposit transaction tier. (Tier 2 — SP_MarketingCloudDaily)|
| 45 | TX_Tier_3M_CO | varchar(100) | YES | TX_Tier_3M_CO projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month cashout transaction tier. (Tier 2 — SP_MarketingCloudDaily)|
| 46 | Amount_Tier_3M_CO | varchar(100) | YES | Amount_Tier_3M_CO projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month cashout amount tier. (Tier 2 — SP_MarketingCloudDaily)|
| 47 | Amount_Tier_3M_Deposits | varchar(100) | YES | Amount_Tier_3M_Deposits projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney 3-month deposit amount tier. (Tier 2 — SP_MarketingCloudDaily)|
| 48 | AccountSubProgram | varchar(100) | YES | AccountSubProgram projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney card/IBAN sub-program type. From eMoney_Dim_Account where AccountProgramID=1 AND IsValidETM=1. Values: Card Standard UK, Card Black EU, Card Premium UK, Card Green EU, IBAN EU Black, IBAN EU Green, IBAN LIMITED EU, Card Premium UAE. (Tier 2 — SP_MarketingCloudDaily)|
| 49 | CardCreateDate | date | YES | CardCreateDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date the eMoney card was created. From eMoney_Dim_Account.CardCreateDate. Same filters as AccountSubProgram. (Tier 2 — SP_MarketingCloudDaily)|
| 50 | KYC_Experience_Level | varchar(50) | YES | KYC_Experience_Level projected from BI_DB_MarketingCloudDaily (see base table wiki). Customer's self-reported trading experience from KYC questionnaire. From BI_DB_KYC_Panel.Experience_Level. Values: Non, Low, N/A, High, Med. (Tier 2 — SP_MarketingCloudDaily)|
| 51 | KYC_Planned_Invested_Amount | varchar(100) | YES | KYC_Planned_Invested_Amount projected from BI_DB_MarketingCloudDaily (see base table wiki). Customer's planned investment amount from KYC Q14. From BI_DB_KYC_Panel.Q14_AnswerText. Values: Up to $1k, $1k-$5k, Up to $20K, $20k-$50k, Above $1M, etc. (Tier 2 — SP_MarketingCloudDaily)|
| 52 | KYC_CFD_Level | varchar(50) | YES | KYC_CFD_Level projected from BI_DB_MarketingCloudDaily (see base table wiki). CFD experience classification computed from KYC answers. Level_0=no FX interest, Level_1=novice with FX+multi-answer, Level_2=experienced with FX or single-answer, NULL=incomplete data. (Tier 2 — SP_MarketingCloudDaily)|
| 53 | IOB_Opt_In | int | YES | IOB_Opt_In projected from BI_DB_MarketingCloudDaily (see base table wiki). Interest on Balance consent status. Latest ConsentStatusID per CID from External_Interest_Trade_InterestConsent. (Tier 2 — SP_MarketingCloudDaily)|
| 54 | IOB_Opt_In_ValidFrom | datetime | YES | IOB_Opt_In_ValidFrom projected from BI_DB_MarketingCloudDaily (see base table wiki). Effective date of the IOB consent status. From External_Interest_Trade_InterestConsent.ValidFrom. (Tier 2 — SP_MarketingCloudDaily)|
| 55 | AmountToClubUpgrade | money | YES | AmountToClubUpgrade projected from BI_DB_MarketingCloudDaily (see base table wiki). USD amount needed to reach next eToro Club tier. Club members: from CID_DailyPanel_Club.AmountToUpgrade. Non-club: gap to next threshold ($5K/$10K/$25K/$50K/$250K) from ClubService realized equity. (Tier 2 — SP_MarketingCloudDaily)|
| 56 | UnRealizedEquity | money | YES | UnRealizedEquity projected from BI_DB_MarketingCloudDaily (see base table wiki). Unrealized equity = Liabilities + ActualNWA from V_Liabilities at @dateID. Represents the customer's total equity including unrealized P&L. (Tier 2 — SP_MarketingCloudDaily)|
| 57 | MaxEquity_LastYear | money | YES | MaxEquity_LastYear projected from BI_DB_MarketingCloudDaily (see base table wiki). Maximum unrealized equity (Liabilities+ActualNWA) over the trailing 1 year from V_Liabilities. (Tier 2 — SP_MarketingCloudDaily)|
| 58 | MaxEquity_LastWeek | money | YES | MaxEquity_LastWeek projected from BI_DB_MarketingCloudDaily (see base table wiki). Maximum unrealized equity over the trailing 7 days from V_Liabilities. (Tier 2 — SP_MarketingCloudDaily)|
| 59 | CashoutAmount_LastWeek | decimal(11,2) | YES | CashoutAmount_LastWeek projected from BI_DB_MarketingCloudDaily (see base table wiki). Total cashout (withdrawal) amount in the last 7 days. SUM(Amount) from Fact_CustomerAction where ActionTypeID=8. Zero if no cashouts (LEFT JOIN with ISNULL). (Tier 2 — SP_MarketingCloudDaily)|
| 60 | CashoutAmount_InProcess | money | YES | CashoutAmount_InProcess projected from BI_DB_MarketingCloudDaily (see base table wiki). Sum of pending withdrawal amounts not yet finalized. Direct from V_Liabilities.InProcessCashouts where DateID=@dateID. (Tier 1 — Fact_SnapshotEquity via V_Liabilities)|
| 61 | TotalDepositsAmount_LastYear | decimal(11,2) | YES | TotalDepositsAmount_LastYear projected from BI_DB_MarketingCloudDaily (see base table wiki). Total deposit amount in the trailing 1 year. SUM(Amount) from Fact_CustomerAction where ActionTypeID=7. (Tier 2 — SP_MarketingCloudDaily)|
| 62 | KYC_PlannedInvestment_Stocks | int | YES | KYC_PlannedInvestment_Stocks projected from BI_DB_MarketingCloudDaily (see base table wiki). Whether the customer indicated planned stock investment in KYC. From BI_DB_KYC_Panel.Is_PI_Stocks. 1=yes, 0=no. (Tier 2 — SP_MarketingCloudDaily)|
| 63 | KYC_PlannedInvestment_Crypto | int | YES | KYC_PlannedInvestment_Crypto projected from BI_DB_MarketingCloudDaily (see base table wiki). Whether the customer indicated planned crypto investment. From BI_DB_KYC_Panel.Is_PI_Crypto. (Tier 2 — SP_MarketingCloudDaily)|
| 64 | KYC_PlannedInvestment_FX | int | YES | KYC_PlannedInvestment_FX projected from BI_DB_MarketingCloudDaily (see base table wiki). Whether the customer indicated planned FX investment. From BI_DB_KYC_Panel.Is_PI_FX. (Tier 2 — SP_MarketingCloudDaily)|
| 65 | Total_KYC_PlannedInvestment_Answers | int | YES | Total_KYC_PlannedInvestment_Answers projected from BI_DB_MarketingCloudDaily (see base table wiki). Count of distinct planned investment categories selected in KYC. From BI_DB_KYC_Panel.Total_PI_Answers. (Tier 2 — SP_MarketingCloudDaily)|
| 66 | StocksLendingStatusID | int | YES | StocksLendingStatusID projected from BI_DB_MarketingCloudDaily (see base table wiki). Stocks lending consent status. Only populated where StocksLendingStatusID=1 (opted in) from Ext_Dim_Customer_StocksLending via Dim_Customer GCID join. (Tier 2 — SP_MarketingCloudDaily)|
| 67 | StocksLendingOptInDate | date | YES | StocksLendingOptInDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of stocks lending opt-in consent. From Ext_Dim_Customer_StocksLending.ConsentDateTime where StocksLendingStatusID=1. (Tier 2 — SP_MarketingCloudDaily)|
| 68 | eTM_IBAN_Type | varchar(50) | YES | eTM_IBAN_Type projected from BI_DB_MarketingCloudDaily (see base table wiki). IBAN country code prefix (first 2 characters of BankAccountIBAN). From eMoney_Dim_Account where IsValidETM=1 AND GCID_Unique_Count=1. E.g., MT, DE, GB. (Tier 2 — SP_MarketingCloudDaily)|
| 69 | eTM_AccountName_LocalCurrency | varchar(50) | YES | eTM_AccountName_LocalCurrency projected from BI_DB_MarketingCloudDaily (see base table wiki). eMoney account local currency description. From eMoney_Dim_Account.CurrencyBalanceISODesc. E.g., EUR, GBP. (Tier 2 — SP_MarketingCloudDaily)|
| 70 | Cluster | varchar(50) | YES | Cluster projected from BI_DB_MarketingCloudDaily (see base table wiki). Customer behavioral cluster assignment. From BI_DB_CID_DailyCluster.ClusterDetail. 6 values: Crypto, Equities Investors, Equities Crypto, Equities Traders, Leveraged Traders, Diversified Traders. (Tier 2 — SP_MarketingCloudDaily)|
| 71 | ClusterDate | date | YES | ClusterDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of the cluster assignment. From BI_DB_CID_DailyCluster.FromDate. (Tier 2 — SP_MarketingCloudDaily)|
| 72 | PositionOpen_LastDate_ETF | date | YES | PositionOpen_LastDate_ETF projected from BI_DB_MarketingCloudDaily (see base table wiki). Date of the last ETF position opened by this customer. MAX(Dim_Position.OpenOccurred) where Dim_Instrument.InstrumentTypeID=6, MirrorID=0 (non-copy), IsPartialCloseChild=0, IsAirDrop=0. (Tier 2 — SP_MarketingCloudDaily)|
| 73 | Rewarded_LastMonth_eMoney | date | YES | Rewarded_LastMonth_eMoney projected from BI_DB_MarketingCloudDaily (see base table wiki). Month reference for the eMoney card cashback calculation. DATEFROMPARTS of prior month. Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily)|
| 74 | Monthly_CardSpent_eMoney | numeric(32,4) | YES | Monthly_CardSpent_eMoney projected from BI_DB_MarketingCloudDaily (see base table wiki). Total card spend for the prior month (HolderAmount * -1). Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily)|
| 75 | Monthly_RewardedChashBack_eMoney | numeric(32,4) | YES | Monthly_RewardedChashBack_eMoney projected from BI_DB_MarketingCloudDaily (see base table wiki). Cashback amount rewarded for the prior month. 4% of eligible spend, capped at 1500. Only updated on the 1st of each month. Note: column name typo ("Chash" instead of "Cash"). (Tier 2 — SP_MarketingCloudDaily)|
| 76 | Monthly_CardEligibleCashBack_eMoney | numeric(30,6) | YES | Monthly_CardEligibleCashBack_eMoney projected from BI_DB_MarketingCloudDaily (see base table wiki). Eligible card spend for cashback (excludes gambling/crypto/money transfer MCCs). Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily)|
| 77 | FirstDepositDateGlobal | datetime | YES | FirstDepositDateGlobal projected from BI_DB_MarketingCloudDaily (see base table wiki). First deposit date across all platforms (trading + IBAN). From Function_MIMO_First_Deposit_All_Platforms(1). Only populated for CIDs whose first deposit was on @date. (Tier 2 — SP_MarketingCloudDaily)|
| 78 | DepositsUSD_Global | decimal(16,6) | YES | DepositsUSD_Global projected from BI_DB_MarketingCloudDaily (see base table wiki). Cumulative deposit amount in USD across all platforms. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOAction='Deposit' AND IsInternalTransfer=0. Updated for CIDs with a deposit on @date. (Tier 2 — SP_MarketingCloudDaily)|
| 79 | BalanceGlobal | decimal(16,6) | YES | BalanceGlobal projected from BI_DB_MarketingCloudDaily (see base table wiki). Global balance = CreditTP + IBANBalance from DDR_Fact_AUM at @dateID. Combines trading platform and eMoney balances. (Tier 2 — SP_MarketingCloudDaily)|
| 80 | EquityGlobal | decimal(16,6) | YES | EquityGlobal projected from BI_DB_MarketingCloudDaily (see base table wiki). Global equity from DDR_Fact_AUM.EquityGlobal at @dateID. (Tier 2 — SP_MarketingCloudDaily)|
| 81 | Total_Deposit_USD | decimal(20,6) | YES | Total_Deposit_USD projected from BI_DB_MarketingCloudDaily (see base table wiki). Cumulative trading platform deposits in USD. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOPlatform='TradingPlatform'. (Tier 2 — SP_MarketingCloudDaily)|
| 82 | Total_Deposit_EUR | decimal(20,6) | YES | Total_Deposit_EUR projected from BI_DB_MarketingCloudDaily (see base table wiki). Cumulative eMoney deposits in EUR. SUM(AmountOrigCurrency) where MIMOPlatform='eMoney' AND CurrencyID=2. (Tier 2 — SP_MarketingCloudDaily)|
| 83 | Total_Deposit_GBP | decimal(20,6) | YES | Total_Deposit_GBP projected from BI_DB_MarketingCloudDaily (see base table wiki). Cumulative eMoney deposits in GBP. SUM(AmountOrigCurrency) where MIMOPlatform='eMoney' AND CurrencyID=3. (Tier 2 — SP_MarketingCloudDaily)|
| 84 | Current_Balance_USD | decimal(16,6) | YES | Current_Balance_USD projected from BI_DB_MarketingCloudDaily (see base table wiki). Current trading platform USD balance. From DDR_Fact_AUM.CreditTP at @dateID. (Tier 2 — SP_MarketingCloudDaily)|
| 85 | Current_Balance_EUR | decimal(16,6) | YES | Current_Balance_EUR projected from BI_DB_MarketingCloudDaily (see base table wiki). Current eMoney EUR balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=978 AND GCID_Unique_Count=1. (Tier 2 — SP_MarketingCloudDaily)|
| 86 | Current_Balance_GBP | decimal(16,6) | YES | Current_Balance_GBP projected from BI_DB_MarketingCloudDaily (see base table wiki). Current eMoney GBP balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=826 AND GCID_Unique_Count=1. (Tier 2 — SP_MarketingCloudDaily)|
| 87 | LastTransactionDate | datetime | YES | LastTransactionDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last settled eMoney card transaction date. MAX(eMoney_Panel_FirstDates.LastCardSettledTXDate) where IsValidETM=1. (Tier 2 — SP_MarketingCloudDaily)|
| 88 | AcceptedTnCs_Date | datetime | YES | AcceptedTnCs_Date projected from BI_DB_MarketingCloudDaily (see base table wiki). Date the customer accepted ISA Terms & Conditions. From BI_OUTPUT_Customer_External_Table_ISA. (Tier 2 — SP_MarketingCloudDaily)|
| 89 | DIY_PortfolioCreatedDate | datetime | YES | DIY_PortfolioCreatedDate projected from BI_DB_MarketingCloudDaily (see base table wiki). ISA execution-only (DIY) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-execution-only'. (Tier 2 — SP_MarketingCloudDaily)|
| 90 | DIY_FirstDepositDate | datetime | YES | DIY_FirstDepositDate projected from BI_DB_MarketingCloudDaily (see base table wiki). First deposit date into the DIY ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-execution-only'. (Tier 2 — SP_MarketingCloudDaily)|
| 91 | Cash_PortfolioCreatedDate | datetime | YES | Cash_PortfolioCreatedDate projected from BI_DB_MarketingCloudDaily (see base table wiki). ISA cash portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-cash'. (Tier 2 — SP_MarketingCloudDaily)|
| 92 | Cash_FirstDepositDate | datetime | YES | Cash_FirstDepositDate projected from BI_DB_MarketingCloudDaily (see base table wiki). First deposit date into the cash ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-cash'. (Tier 2 — SP_MarketingCloudDaily)|
| 93 | Managed_PortfolioCreatedDate | datetime | YES | Managed_PortfolioCreatedDate projected from BI_DB_MarketingCloudDaily (see base table wiki). ISA discretionary (managed) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-discretionary'. (Tier 2 — SP_MarketingCloudDaily)|
| 94 | Managed_FirstDepositDate | datetime | YES | Managed_FirstDepositDate projected from BI_DB_MarketingCloudDaily (see base table wiki). First deposit date into the managed ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-discretionary'. (Tier 2 — SP_MarketingCloudDaily)|
| 95 | IsDefunded_across_all_portfolios | bit | YES | IsDefunded_across_all_portfolios projected from BI_DB_MarketingCloudDaily (see base table wiki). Whether ALL of the customer's ISA portfolios are defunded. 1=all defunded, 0=at least one funded. MIN(CASE WHEN PortfolioDefunded=1 THEN 1 ELSE 0 END) across all portfolios. (Tier 2 — SP_MarketingCloudDaily)|
| 96 | RAF_Inviter | decimal(16,6) | YES | RAF_Inviter projected from BI_DB_MarketingCloudDaily (see base table wiki). GCID of the person who invited this customer via Refer-a-Friend. From BI_DB_RAF_Invitees_KPIs.Inviter → Dim_Customer.GCID. Note: stored as decimal, not int. (Tier 2 — SP_MarketingCloudDaily)|
| 97 | RAF_LastCashoutDate | datetime | YES | RAF_LastCashoutDate projected from BI_DB_MarketingCloudDaily (see base table wiki). Last cashout date from the RAF program for this invitee. MAX(LastCashoutDate) from BI_DB_RAF_Invitees_KPIs. (Tier 2 — SP_MarketingCloudDaily)|
| 98 | etr_y | varchar(8) | YES | Lakehouse partition column (year). UC Gold view adds partition keys to base table export. (Tier 2 — Gold export)|
| 99 | etr_ym | varchar(16) | YES | Lakehouse partition column (year-month). (Tier 2 — Gold export)|
| 100 | etr_ymd | varchar(32) | YES | Lakehouse partition column (year-month-day). (Tier 2 — Gold export) |

---

## 5. Lineage

### 5.1 Notes

 Predicate AccountId IS NOT NULL is the sole delta vs base lineage.

### 5.2 ETL ASCII

```text
Multi-source ingestion -> SP_MarketingCloudDaily -> BI_DB_MarketingCloudDaily -> UC Gold base -> UC VIEW _v (+ etr_*)
```

```text
UPSTREAM SEARCH LOG — BI_DB_MarketingCloudDaily_V:
  BI_DB_MarketingCloudDaily
    knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_MarketingCloudDaily.md -> FOUND Read tool: YES
```

---

## 6. Relationships

Same relationship graph as BI_DB_MarketingCloudDaily (Section 6 in base wiki).

---

## 7. Sample Queries

### 7.1 CRM-linked pull
```sql
SELECT CID, AccountId, UpdateDate
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v
WHERE etr_ym = '2026-05'
LIMIT 200;
```

### 7.2 Compare counts vs base predicate
```sql
SELECT COUNT(*) AS filtered
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily_v;

SELECT COUNT(*) AS manual_filter
FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_marketingclouddaily
WHERE AccountId IS NOT NULL;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian lookups in condensed speckit pass.

---

*Generated: 2026-05-14 | Quality: 9.0/10 | Elements 100*
