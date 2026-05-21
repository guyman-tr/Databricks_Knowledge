# BI_DB_dbo.BI_DB_MarketingCloudDaily

> 47.1M-row CRM enrichment table providing a one-row-per-customer (CID) daily snapshot of cross-platform activity, financial metrics, KYC attributes, eMoney card/fiat data, watchlist behavior, gain performance, life stage, cluster assignment, ISA portfolio status, and RAF (Refer-a-Friend) data — assembled by SP_MarketingCloudDaily from 20+ DWH/BI_DB/eMoney sources and uploaded to Salesforce Marketing Cloud via SFTP. Refreshed daily via SB_Daily (Priority 0). Data spans from 2022-01-18 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source aggregation via SP_MarketingCloudDaily (Ben Einav, 2023-08-23) |
| **Refresh** | Daily incremental merge (UPDATE existing + INSERT new CIDs per column-group). SB_Daily, Priority 0 |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX(UpdateDate ASC) |
| **UC Target** | _Not_Migrated (no Generic Pipeline mapping) |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~47.1M |
| **Date Range** | UpdateDate 2022-01-18 to 2026-04-12 |
| **Author** | Ben Einav (created 2023-08-23), Katy F, Eti Rozilio, Irina K |

---

## 1. Business Meaning

This table serves as the **daily CRM enrichment dataset for Salesforce Marketing Cloud**. Each row represents a single customer (CID) with the latest known values across ~98 attributes covering:

- **Trading activity**: watchlist adds by asset class, gain metrics (week/month/quarter/half/year), last ETF position open, cluster assignment
- **Financial position**: unrealized equity, max equity (1-year and 1-week), credit balance, cashout amounts, total deposits (USD/EUR/GBP), current balances (USD/EUR/GBP), global deposits/balance/equity
- **eMoney/fiat**: IBAN type, local currency, EOD balance, last withdrawal/deposit/transfer/card transaction dates, 3-month retention tiers, card spend/cashback metrics
- **KYC/Compliance**: KYC flow name, lead score, experience level, planned investment amount, CFD level, planned investment answers (Stocks/Crypto/FX)
- **Lifecycle**: life stage definition (LSD), stocks lending status, IOB (Interest on Balance) opt-in, privacy policy version, club upgrade amount
- **ISA portfolios**: T&Cs acceptance date, portfolio created/first deposit dates for DIY/Cash/Managed types, defunded status
- **RAF**: inviter GCID, last cashout date from RAF program
- **Identity**: Salesforce AccountId, AirdropCustomerID (Dim_Customer GUID)

The SP uses a **column-group-at-a-time merge pattern**: for each feature group, it creates a temp table from the source, UPDATEs existing CIDs where values changed, then INSERTs rows for CIDs not yet in the table. This means the table **accumulates customers over time** — once a CID enters, it is never deleted. Columns not relevant to a CID remain NULL.

**Legacy columns**: eMoneyIsInRollout, eMoneyIsInRolloutDate, AirDropRemainder, AirdropServeyDate, AirdropPotentialUpdateDate are no longer populated by the current SP version (all NULL in live data).

---

## 2. Business Logic

### 2.1 Column-Group Merge Pattern

**What**: Each column-group is independently sourced and merged into the table.
**Columns Involved**: All 98 columns (grouped into ~25 independent blocks in the SP).
**Rules**:
- UPDATE existing CIDs where the source value differs from the current value (ISNULL comparisons prevent unnecessary updates)
- INSERT new CIDs not yet in the table (only the columns for that block are populated; others remain NULL)
- UpdateDate is set to GETDATE() on every UPDATE/INSERT

### 2.2 KYC CFD Level Computation

**What**: Classifies customers into CFD trading experience tiers based on KYC questionnaire answers.
**Columns Involved**: KYC_CFD_Level, KYC_Experience_Level, KYC_PlannedInvestment_FX, Total_KYC_PlannedInvestment_Answers
**Rules**:
- Level_0: Is_PI_FX=0 (no FX planned investment)
- Level_1: Experience='Non' AND Is_PI_FX=1 AND Total_PI_Answers>1
- Level_2: (Experience!='Non' AND Is_PI_FX=1) OR (Experience='Non' AND Is_PI_FX=1 AND Total_PI_Answers=1)
- NULL: Experience='N/A' or any input is NULL

### 2.3 Club Upgrade Amount Calculation

**What**: Computes the USD amount needed to reach the next eToro Club tier.
**Columns Involved**: AmountToClubUpgrade
**Rules**:
- Club members: AmountToUpgrade from BI_DB_CID_DailyPanel_Club
- Non-club members: gap from current realized equity (from ClubService_Clubs_UserBalances) to next tier threshold: $5K → $10K → $25K → $50K → $250K
- FULL OUTER JOIN merges both populations

### 2.4 eMoney Monthly Card Metrics (First-of-Month Only)

**What**: Monthly card spend, cashback, and eligible cashback calculated from settled transactions.
**Columns Involved**: Rewarded_LastMonth_eMoney, Monthly_CardSpent_eMoney, Monthly_RewardedChashBack_eMoney, Monthly_CardEligibleCashBack_eMoney
**Rules**:
- Only runs when @date equals the first day of the month
- Filters: IsValidETM=1, IsValidCustomer=1, IsTestAccount=0, AccountSubProgramID IN (2,1,4,6,7,9,12,11), TxTypeID IN (1,2,3,4), TxStatusID IN (1,2), IsTxSettled=1
- Eligible cashback excludes specific MCCs (gambling, crypto, money transfer: 4829,7273,5122,5169,5933,5960,5962,5966,5967,5968,6051,6010,6012,6211,6540,7299,7800,7801,7802,8999,7994,7995,9754)
- Cashback rate: 4% of eligible spend, capped at 1500
- Negative amounts flipped to positive (HolderAmount * -1)

### 2.5 Watchlist Instrument Type Classification

**What**: Maps watchlist item adds to asset class buckets via Dim_Instrument.InstrumentTypeID.
**Columns Involved**: WatchlistLastAdded* (8 columns)
**Rules**:
- ETF=6, Crypto=10, Stocks=5, Commodities=2, Indices=4
- User watchlist items: PI (GuruStatusID>=2), CopyPortfolio (AccountTypeID=9 after 2016-01-01 + 6 hardcoded RealCIDs), NonPIUser (remainder)
- Source migrated from DWH_watchlists to CopyFromLake.WatchListDB_* tables (Katy F, 2024-05-27)

### 2.6 ISA Portfolio Type PIVOT

**What**: Pivots ISA portfolio data by product type into separate column pairs.
**Columns Involved**: DIY_PortfolioCreatedDate, DIY_FirstDepositDate, Cash_*, Managed_*
**Rules**:
- DIY = ProductName_Code 'isa-execution-only'
- Cash = ProductName_Code 'isa-cash'
- Managed = ProductName_Code 'isa-discretionary'
- IsDefunded_across_all_portfolios = 1 only if MIN(PortfolioDefunded)=1 across ALL customer portfolios

### 2.7 RAF Inviter Resolution

**What**: Maps each invitee CID to the inviter's GCID for Marketing Cloud targeting.
**Columns Involved**: RAF_Inviter, RAF_LastCashoutDate
**Rules**:
- RAF_Inviter: Invitee.CID → Inviter.RealCID → Dim_Customer.GCID (stored as decimal, not int)
- RAF_LastCashoutDate: MAX(LastCashoutDate) from BI_DB_RAF_Invitees_KPIs per invitee

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **HASH(CID)**: optimal for single-customer lookups and CID-based JOINs. All rows for a CID are co-located.
- **CLUSTERED INDEX(UpdateDate ASC)**: efficient for filtering by recency (WHERE UpdateDate >= '2026-01-01').
- One row per CID — no date dimension. To track history, you need to snapshot externally.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get latest CRM snapshot for a CID | `WHERE CID = @cid` (single-row return) |
| Find customers in a cluster | `WHERE Cluster = 'Equities Traders'` |
| Find customers by life stage | `WHERE LSD = 'Active Open Club'` |
| Active eMoney users | `WHERE TX_Tier_3M != 'No_MIMO_3M' AND TX_Tier_3M IS NOT NULL` |
| ISA customers with funded portfolios | `WHERE IsDefunded_across_all_portfolios = 0 AND AcceptedTnCs_Date IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = Dim_Customer.RealCID | Full customer attributes (regulation, country, registration date) |
| DWH_dbo.V_Liabilities | CID = V_Liabilities.CID AND V_Liabilities.DateID = target date | Point-in-time equity/balance |
| BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | CID | Full daily panel metrics |

### 3.4 Gotchas

- **One row per CID, no history**: The table only stores the latest known value for each column. No date dimension — UpdateDate reflects the last time ANY column was modified for that CID.
- **Sparse NULLs**: Most columns are NULL for most CIDs. A CID only gets a value for a column when the corresponding source has data for them. Don't interpret NULL as "zero" — it means "no data from that source."
- **Legacy columns all NULL**: eMoneyIsInRollout, eMoneyIsInRolloutDate, AirDropRemainder, AirdropServeyDate, AirdropPotentialUpdateDate are never populated by the current SP. Ignore them.
- **Column typo**: WatchlistLastAddedIndecies (should be "Indices") — preserved from DDL, do not rename.
- **Column typo**: eMoneyWithrawalFromPlatformLastDate (should be "Withdrawal") — preserved from DDL.
- **Monthly-only columns**: Rewarded_LastMonth_eMoney, Monthly_CardSpent_eMoney, Monthly_RewardedChashBack_eMoney, Monthly_CardEligibleCashBack_eMoney are only updated on the 1st of each month.
- **RAF_Inviter is a GCID stored as decimal(16,6)**: Not a CID. It is the GCID of the person who invited this customer. Use Dim_Customer to resolve.
- **CashoutAmount_LastWeek uses LEFT JOIN with ISNULL(,0)**: Customers with no cashouts in the last 7 days get their value zeroed out, not left NULL.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream production wiki — description copied verbatim |
| Tier 2 | Derived from SP code analysis — column logic traced through ETL |
| Tier 3 | Inferred from data sampling and column name patterns |
| Tier 4 | Best available knowledge — limited confidence |
| Tier 5 | Standard ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AccountId | nvarchar(18) | YES | Salesforce CRM Account record ID (18-char Salesforce ID). Links the trading account to the SF Account. NULL if not yet synced. Passthrough from Dim_Customer.SalesForceAccountID. (Tier 1 — BackOffice.Customer) |
| 2 | CID | int | NO | Customer ID — platform-internal primary key. One row per CID. Each column-group block inserts new CIDs from its own source. Distribution key. (Tier 2 — SP_MarketingCloudDaily) |
| 3 | MobileAppLastLogin | datetime | YES | Last mobile app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (104,105,110,111) AND ActionTypeID=14. (Tier 2 — SP_MarketingCloudDaily) |
| 4 | WatchlistLastAddedETF | datetime | YES | Last date an ETF instrument was added to this customer's watchlist. MAX(ItemAddedDate) where InstrumentTypeID=6. Source: CopyFromLake.WatchListDB. (Tier 2 — SP_MarketingCloudDaily) |
| 5 | WatchlistLastAddedCrypto | datetime | YES | Last date a crypto instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=10. (Tier 2 — SP_MarketingCloudDaily) |
| 6 | WatchlistLastAddedStocks | datetime | YES | Last date a stock instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=5. (Tier 2 — SP_MarketingCloudDaily) |
| 7 | WatchlistLastAddedCommodities | datetime | YES | Last date a commodity instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=2. (Tier 2 — SP_MarketingCloudDaily) |
| 8 | WatchlistLastAddedIndecies | datetime | YES | Last date an index instrument was added to watchlist. MAX(ItemAddedDate) where InstrumentTypeID=4. Note: column name typo ("Indecies" instead of "Indices") preserved from DDL. (Tier 2 — SP_MarketingCloudDaily) |
| 9 | WatchlistLastAddedPI | datetime | YES | Last date a Popular Investor (GuruStatusID>=2) was added to watchlist. (Tier 2 — SP_MarketingCloudDaily) |
| 10 | WatchlistLastAddedCopyPortfolio | datetime | YES | Last date a CopyPortfolio (AccountTypeID=9 post-2016 or 6 hardcoded RealCIDs) was added to watchlist. (Tier 2 — SP_MarketingCloudDaily) |
| 11 | WatchlistLastAddedNonPIUser | datetime | YES | Last date a non-PI, non-CopyPortfolio user was added to watchlist. (Tier 2 — SP_MarketingCloudDaily) |
| 12 | WatchlistLastDateID | int | YES | Date key (YYYYMMDD) of the most recent watchlist add across all types. (Tier 2 — SP_MarketingCloudDaily) |
| 13 | GainThisWeek | decimal(16,4) | YES | Customer's portfolio gain percentage for the current week. From DWH_GainDaily.Gain_w where Date=@date. Zero if no open positions. (Tier 2 — SP_MarketingCloudDaily) |
| 14 | GainOneMonthAgo | decimal(16,4) | YES | Portfolio gain percentage over the last month. From DWH_GainDaily.Gain_m. (Tier 2 — SP_MarketingCloudDaily) |
| 15 | GainThreeMonthsAgo | decimal(16,4) | YES | Portfolio gain percentage over the last 3 months. From DWH_GainDaily.Gain_q. (Tier 2 — SP_MarketingCloudDaily) |
| 16 | GainSixMonthsAgo | decimal(16,4) | YES | Portfolio gain percentage over the last 6 months. From DWH_GainDaily.Gain_h. (Tier 2 — SP_MarketingCloudDaily) |
| 17 | GainOneYearAgo | decimal(16,4) | YES | Portfolio gain percentage over the last year. From DWH_GainDaily.Gain_y. (Tier 2 — SP_MarketingCloudDaily) |
| 18 | GainLastDate | date | YES | Date of the most recent gain calculation. Retained from prior run if no new gain data available. (Tier 2 — SP_MarketingCloudDaily) |
| 19 | GainExecutionID | int | YES | Execution batch ID from DWH_GainDaily. Retained from prior run if no new gain data. (Tier 2 — SP_MarketingCloudDaily) |
| 20 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on every column-group UPDATE/INSERT. (Tier 5 — SP_MarketingCloudDaily) |
| 21 | eMoneyIsInRollout | int | YES | Legacy column — no longer populated by current SP. All NULL. Originally indicated eMoney gradual rollout status. (Tier 4 — legacy) |
| 22 | eMoneyIsInRolloutDate | datetime | YES | Legacy column — no longer populated by current SP. All NULL. Originally date of eMoney rollout flag. (Tier 4 — legacy) |
| 23 | AirDropRemainder | int | YES | Legacy column — no longer populated by current SP. All NULL. Originally airdrop token remainder. (Tier 4 — legacy) |
| 24 | VerificationLevel3Date | date | YES | Date when the customer reached Verification Level 3 (full KYC). From BI_DB_CIDFirstDates.VerificationLevel3Date. (Tier 2 — SP_MarketingCloudDaily) |
| 25 | AirdropServeyDate | date | YES | Legacy column — no longer populated by current SP. All NULL. Note: column name typo ("Servey" instead of "Survey"). (Tier 4 — legacy) |
| 26 | AirdropPotentialUpdateDate | date | YES | Legacy column — no longer populated by current SP. All NULL. (Tier 4 — legacy) |
| 27 | WalletLastLogin | datetime | YES | Last crypto wallet app login timestamp. MAX(Occurred) from Fact_CustomerAction where PlatformID IN (118,119,120) AND ActionTypeID=14. (Tier 2 — SP_MarketingCloudDaily) |
| 28 | eMoneyExternalTransferToIBANLastDate | datetime | YES | Last date of a completed external IBAN transfer (TransactionTypeId=7, StatusId=2). From eMoney_dbo.FiatTransactions. (Tier 2 — SP_MarketingCloudDaily) |
| 29 | eMoneyDepositToPlatformLastDate | datetime | YES | Last date of a completed deposit to trading platform from eMoney (TransactionTypeId=6, StatusId=2). (Tier 2 — SP_MarketingCloudDaily) |
| 30 | eMoneyWithrawalFromPlatformLastDate | datetime | YES | Last date of a completed withdrawal from trading platform to eMoney (TransactionTypeId=5, StatusId=2). Note: column name typo ("Withrawal"). (Tier 2 — SP_MarketingCloudDaily) |
| 31 | eMoneyEODBalanceAmount | money | YES | eMoney end-of-day balance amount for the latest available date. From eMoney_dbo.CustomerEODBalance. (Tier 2 — SP_MarketingCloudDaily) |
| 32 | eMoneyEODBalanceDate | datetime | YES | Date of the eMoney EOD balance snapshot. MAX(EODBalanceDate) per GCID. (Tier 2 — SP_MarketingCloudDaily) |
| 33 | eMoneyCardTransactionLastDate | datetime | YES | Last settled card transaction date (TransactionCategory=1, excluding refunds/fees TransactionTypeId NOT IN (9,10), StatusId=2). (Tier 2 — SP_MarketingCloudDaily) |
| 34 | KYCFlowName | varchar(50) | YES | KYC flow short name from ComplianceStateDB. Normal=standard KYC, VBT=Video-Based Telephony, VBD=Video-Based Digital, HRC=High Risk Check. 4 distinct values. (Tier 2 — SP_MarketingCloudDaily) |
| 35 | KYCLeadScore | nvarchar(50) | YES | Behavioral lead score cluster label from BI_DB_KYC_Score_CID_Level. Renamed from source column 'Cluster'. Values: 1-5 or 'No Cluster'. (Tier 2 — SP_MarketingCloudDaily) |
| 36 | AirdropCustomerID | uniqueidentifier | YES | System GUID for REST API identity. Default=newsequentialid() (sequential for index performance). Passthrough from Dim_Customer.ID where IsValidCustomer=1. (Tier 1 — Customer.CustomerStatic) |
| 37 | Credit | money | YES | Outstanding credit/bonus balance from History.ActiveCredit. Last credit event per CID per day. From V_Liabilities.Credit where DateID=@dateID. (Tier 2 — Fact_SnapshotEquity via V_Liabilities) |
| 38 | FirstTimeCopiedDate | datetime | YES | Earliest date this customer was first copied (as a Popular Investor). MIN(Dim_Mirror.OpenOccurred) where MirrorTypeID<>4 (excludes Fund mirrors), joined on ParentCID. (Tier 2 — SP_MarketingCloudDaily) |
| 39 | PrivacyPolicyID | int | YES | Version of the privacy policy the customer has accepted. FK to Dictionary.PrivacyPolicy. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 40 | LSD | varchar(200) | YES | Life Stage Definition label. Latest active status from BI_DB_CID_LifeStageDefinition (ToDateID=99991231). Values include: Dump Lead, Dump Churn, Lead, Holder, No Activity - Not Funded, Active Open Club, Active Open, Churn over 60 days, Active Open 30-90 days, Holder Club. (Tier 2 — SP_MarketingCloudDaily) |
| 41 | LSDDate | date | YES | Date of the current life stage assignment. From BI_DB_CID_LifeStageDefinition.Date for the latest active record. (Tier 2 — SP_MarketingCloudDaily) |
| 42 | TX_Tier_3M | varchar(100) | YES | eMoney 3-month transaction tier. From eMoney_Panel_Retention_Daily. Values: No_MIMO_3M, High_Active, eMoney_Inactive, Low_Active. (Tier 2 — SP_MarketingCloudDaily) |
| 43 | Amount_Tier_3M | varchar(100) | YES | eMoney 3-month amount tier. From eMoney_Panel_Retention_Daily. (Tier 2 — SP_MarketingCloudDaily) |
| 44 | TX_Tier_3M_Deposits | varchar(100) | YES | eMoney 3-month deposit transaction tier. (Tier 2 — SP_MarketingCloudDaily) |
| 45 | TX_Tier_3M_CO | varchar(100) | YES | eMoney 3-month cashout transaction tier. (Tier 2 — SP_MarketingCloudDaily) |
| 46 | Amount_Tier_3M_CO | varchar(100) | YES | eMoney 3-month cashout amount tier. (Tier 2 — SP_MarketingCloudDaily) |
| 47 | Amount_Tier_3M_Deposits | varchar(100) | YES | eMoney 3-month deposit amount tier. (Tier 2 — SP_MarketingCloudDaily) |
| 48 | AccountSubProgram | varchar(100) | YES | eMoney card/IBAN sub-program type. From eMoney_Dim_Account where AccountProgramID=1 AND IsValidETM=1. Values: Card Standard UK, Card Black EU, Card Premium UK, Card Green EU, IBAN EU Black, IBAN EU Green, IBAN LIMITED EU, Card Premium UAE. (Tier 2 — SP_MarketingCloudDaily) |
| 49 | CardCreateDate | date | YES | Date the eMoney card was created. From eMoney_Dim_Account.CardCreateDate. Same filters as AccountSubProgram. (Tier 2 — SP_MarketingCloudDaily) |
| 50 | KYC_Experience_Level | varchar(50) | YES | Customer's self-reported trading experience from KYC questionnaire. From BI_DB_KYC_Panel.Experience_Level. Values: Non, Low, N/A, High, Med. (Tier 2 — SP_MarketingCloudDaily) |
| 51 | KYC_Planned_Invested_Amount | varchar(100) | YES | Customer's planned investment amount from KYC Q14. From BI_DB_KYC_Panel.Q14_AnswerText. Values: Up to $1k, $1k-$5k, Up to $20K, $20k-$50k, Above $1M, etc. (Tier 2 — SP_MarketingCloudDaily) |
| 52 | KYC_CFD_Level | varchar(50) | YES | CFD experience classification computed from KYC answers. Level_0=no FX interest, Level_1=novice with FX+multi-answer, Level_2=experienced with FX or single-answer, NULL=incomplete data. (Tier 2 — SP_MarketingCloudDaily) |
| 53 | IOB_Opt_In | int | YES | Interest on Balance consent status. Latest ConsentStatusID per CID from External_Interest_Trade_InterestConsent. (Tier 2 — SP_MarketingCloudDaily) |
| 54 | IOB_Opt_In_ValidFrom | datetime | YES | Effective date of the IOB consent status. From External_Interest_Trade_InterestConsent.ValidFrom. (Tier 2 — SP_MarketingCloudDaily) |
| 55 | AmountToClubUpgrade | money | YES | USD amount needed to reach next eToro Club tier. Club members: from CID_DailyPanel_Club.AmountToUpgrade. Non-club: gap to next threshold ($5K/$10K/$25K/$50K/$250K) from ClubService realized equity. (Tier 2 — SP_MarketingCloudDaily) |
| 56 | UnRealizedEquity | money | YES | Unrealized equity = Liabilities + ActualNWA from V_Liabilities at @dateID. Represents the customer's total equity including unrealized P&L. (Tier 2 — SP_MarketingCloudDaily) |
| 57 | MaxEquity_LastYear | money | YES | Maximum unrealized equity (Liabilities+ActualNWA) over the trailing 1 year from V_Liabilities. (Tier 2 — SP_MarketingCloudDaily) |
| 58 | MaxEquity_LastWeek | money | YES | Maximum unrealized equity over the trailing 7 days from V_Liabilities. (Tier 2 — SP_MarketingCloudDaily) |
| 59 | CashoutAmount_LastWeek | decimal(11,2) | YES | Total cashout (withdrawal) amount in the last 7 days. SUM(Amount) from Fact_CustomerAction where ActionTypeID=8. Zero if no cashouts (LEFT JOIN with ISNULL). (Tier 2 — SP_MarketingCloudDaily) |
| 60 | CashoutAmount_InProcess | money | YES | Sum of pending withdrawal amounts not yet finalized. Direct from V_Liabilities.InProcessCashouts where DateID=@dateID. (Tier 1 — Fact_SnapshotEquity via V_Liabilities) |
| 61 | TotalDepositsAmount_LastYear | decimal(11,2) | YES | Total deposit amount in the trailing 1 year. SUM(Amount) from Fact_CustomerAction where ActionTypeID=7. (Tier 2 — SP_MarketingCloudDaily) |
| 62 | KYC_PlannedInvestment_Stocks | int | YES | Whether the customer indicated planned stock investment in KYC. From BI_DB_KYC_Panel.Is_PI_Stocks. 1=yes, 0=no. (Tier 2 — SP_MarketingCloudDaily) |
| 63 | KYC_PlannedInvestment_Crypto | int | YES | Whether the customer indicated planned crypto investment. From BI_DB_KYC_Panel.Is_PI_Crypto. (Tier 2 — SP_MarketingCloudDaily) |
| 64 | KYC_PlannedInvestment_FX | int | YES | Whether the customer indicated planned FX investment. From BI_DB_KYC_Panel.Is_PI_FX. (Tier 2 — SP_MarketingCloudDaily) |
| 65 | Total_KYC_PlannedInvestment_Answers | int | YES | Count of distinct planned investment categories selected in KYC. From BI_DB_KYC_Panel.Total_PI_Answers. (Tier 2 — SP_MarketingCloudDaily) |
| 66 | StocksLendingStatusID | int | YES | Stocks lending consent status. Only populated where StocksLendingStatusID=1 (opted in) from Ext_Dim_Customer_StocksLending via Dim_Customer GCID join. (Tier 2 — SP_MarketingCloudDaily) |
| 67 | StocksLendingOptInDate | date | YES | Date of stocks lending opt-in consent. From Ext_Dim_Customer_StocksLending.ConsentDateTime where StocksLendingStatusID=1. (Tier 2 — SP_MarketingCloudDaily) |
| 68 | eTM_IBAN_Type | varchar(50) | YES | IBAN country code prefix (first 2 characters of BankAccountIBAN). From eMoney_Dim_Account where IsValidETM=1 AND GCID_Unique_Count=1. E.g., MT, DE, GB. (Tier 2 — SP_MarketingCloudDaily) |
| 69 | eTM_AccountName_LocalCurrency | varchar(50) | YES | eMoney account local currency description. From eMoney_Dim_Account.CurrencyBalanceISODesc. E.g., EUR, GBP. (Tier 2 — SP_MarketingCloudDaily) |
| 70 | Cluster | varchar(50) | YES | Customer behavioral cluster assignment. From BI_DB_CID_DailyCluster.ClusterDetail. 6 values: Crypto, Equities Investors, Equities Crypto, Equities Traders, Leveraged Traders, Diversified Traders. (Tier 2 — SP_MarketingCloudDaily) |
| 71 | ClusterDate | date | YES | Date of the cluster assignment. From BI_DB_CID_DailyCluster.FromDate. (Tier 2 — SP_MarketingCloudDaily) |
| 72 | PositionOpen_LastDate_ETF | date | YES | Date of the last ETF position opened by this customer. MAX(Dim_Position.OpenOccurred) where Dim_Instrument.InstrumentTypeID=6, MirrorID=0 (non-copy), IsPartialCloseChild=0, IsAirDrop=0. (Tier 2 — SP_MarketingCloudDaily) |
| 73 | Rewarded_LastMonth_eMoney | date | YES | Month reference for the eMoney card cashback calculation. DATEFROMPARTS of prior month. Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily) |
| 74 | Monthly_CardSpent_eMoney | numeric(32,4) | YES | Total card spend for the prior month (HolderAmount * -1). Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily) |
| 75 | Monthly_RewardedChashBack_eMoney | numeric(32,4) | YES | Cashback amount rewarded for the prior month. 4% of eligible spend, capped at 1500. Only updated on the 1st of each month. Note: column name typo ("Chash" instead of "Cash"). (Tier 2 — SP_MarketingCloudDaily) |
| 76 | Monthly_CardEligibleCashBack_eMoney | numeric(30,6) | YES | Eligible card spend for cashback (excludes gambling/crypto/money transfer MCCs). Only updated on the 1st of each month. (Tier 2 — SP_MarketingCloudDaily) |
| 77 | FirstDepositDateGlobal | datetime | YES | First deposit date across all platforms (trading + IBAN). From Function_MIMO_First_Deposit_All_Platforms(1). Only populated for CIDs whose first deposit was on @date. (Tier 2 — SP_MarketingCloudDaily) |
| 78 | DepositsUSD_Global | decimal(16,6) | YES | Cumulative deposit amount in USD across all platforms. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOAction='Deposit' AND IsInternalTransfer=0. Updated for CIDs with a deposit on @date. (Tier 2 — SP_MarketingCloudDaily) |
| 79 | BalanceGlobal | decimal(16,6) | YES | Global balance = CreditTP + IBANBalance from DDR_Fact_AUM at @dateID. Combines trading platform and eMoney balances. (Tier 2 — SP_MarketingCloudDaily) |
| 80 | EquityGlobal | decimal(16,6) | YES | Global equity from DDR_Fact_AUM.EquityGlobal at @dateID. (Tier 2 — SP_MarketingCloudDaily) |
| 81 | Total_Deposit_USD | decimal(20,6) | YES | Cumulative trading platform deposits in USD. SUM(AmountUSD) from DDR_Fact_MIMO_AllPlatforms where MIMOPlatform='TradingPlatform'. (Tier 2 — SP_MarketingCloudDaily) |
| 82 | Total_Deposit_EUR | decimal(20,6) | YES | Cumulative eMoney deposits in EUR. SUM(AmountOrigCurrency) where MIMOPlatform='eMoney' AND CurrencyID=2. (Tier 2 — SP_MarketingCloudDaily) |
| 83 | Total_Deposit_GBP | decimal(20,6) | YES | Cumulative eMoney deposits in GBP. SUM(AmountOrigCurrency) where MIMOPlatform='eMoney' AND CurrencyID=3. (Tier 2 — SP_MarketingCloudDaily) |
| 84 | Current_Balance_USD | decimal(16,6) | YES | Current trading platform USD balance. From DDR_Fact_AUM.CreditTP at @dateID. (Tier 2 — SP_MarketingCloudDaily) |
| 85 | Current_Balance_EUR | decimal(16,6) | YES | Current eMoney EUR balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=978 AND GCID_Unique_Count=1. (Tier 2 — SP_MarketingCloudDaily) |
| 86 | Current_Balance_GBP | decimal(16,6) | YES | Current eMoney GBP balance. SUM(eMoneyClientBalance.ClosingBalanceBO) where CurrencyBalanceISOCode=826 AND GCID_Unique_Count=1. (Tier 2 — SP_MarketingCloudDaily) |
| 87 | LastTransactionDate | datetime | YES | Last settled eMoney card transaction date. MAX(eMoney_Panel_FirstDates.LastCardSettledTXDate) where IsValidETM=1. (Tier 2 — SP_MarketingCloudDaily) |
| 88 | AcceptedTnCs_Date | datetime | YES | Date the customer accepted ISA Terms & Conditions. From BI_OUTPUT_Customer_External_Table_ISA. (Tier 2 — SP_MarketingCloudDaily) |
| 89 | DIY_PortfolioCreatedDate | datetime | YES | ISA execution-only (DIY) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-execution-only'. (Tier 2 — SP_MarketingCloudDaily) |
| 90 | DIY_FirstDepositDate | datetime | YES | First deposit date into the DIY ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-execution-only'. (Tier 2 — SP_MarketingCloudDaily) |
| 91 | Cash_PortfolioCreatedDate | datetime | YES | ISA cash portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-cash'. (Tier 2 — SP_MarketingCloudDaily) |
| 92 | Cash_FirstDepositDate | datetime | YES | First deposit date into the cash ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-cash'. (Tier 2 — SP_MarketingCloudDaily) |
| 93 | Managed_PortfolioCreatedDate | datetime | YES | ISA discretionary (managed) portfolio creation date. MAX(PortfolioCreatedDate) where ProductName_Code='isa-discretionary'. (Tier 2 — SP_MarketingCloudDaily) |
| 94 | Managed_FirstDepositDate | datetime | YES | First deposit date into the managed ISA portfolio. MAX(PortfolioFirstDepositDate) where ProductName_Code='isa-discretionary'. (Tier 2 — SP_MarketingCloudDaily) |
| 95 | IsDefunded_across_all_portfolios | bit | YES | Whether ALL of the customer's ISA portfolios are defunded. 1=all defunded, 0=at least one funded. MIN(CASE WHEN PortfolioDefunded=1 THEN 1 ELSE 0 END) across all portfolios. (Tier 2 — SP_MarketingCloudDaily) |
| 96 | RAF_Inviter | decimal(16,6) | YES | GCID of the person who invited this customer via Refer-a-Friend. From BI_DB_RAF_Invitees_KPIs.Inviter → Dim_Customer.GCID. Note: stored as decimal, not int. (Tier 2 — SP_MarketingCloudDaily) |
| 97 | RAF_LastCashoutDate | datetime | YES | Last cashout date from the RAF program for this invitee. MAX(LastCashoutDate) from BI_DB_RAF_Invitees_KPIs. (Tier 2 — SP_MarketingCloudDaily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column Group | Production Source | Source Column(s) | Transform |
|---------------------|-----------------|-----------------|-----------|
| AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Direct passthrough |
| Watchlist* (8 cols) | CopyFromLake.WatchListDB | WatchlistItems + Watchlists | PIVOT by InstrumentTypeID / PI/CP/User classification |
| Gain* (7 cols) | BI_DB_dbo.DWH_GainDaily | Gain_w/m/q/h/y, Date, ExecutionID | Direct for @date |
| eMoney fiat (6 cols) | eMoney_dbo.FiatTransactions + CustomerEODBalance | TransactionOccured, EODBalanceAmount | MAX by transaction type |
| KYC (8 cols) | BI_DB_dbo.BI_DB_KYC_Panel | Experience_Level, Q14, Is_PI_*, Total_PI | Direct + CASE for CFD Level |
| Equity/Balance (6 cols) | DWH_dbo.V_Liabilities | Liabilities, ActualNWA, Credit, InProcessCashouts | SUM/MAX over time windows |
| Deposits (4 cols) | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | AmountUSD, AmountOrigCurrency | SUM filtered by platform/currency |
| ISA (8 cols) | BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA | PortfolioCreatedDate, PortfolioFirstDepositDate, etc. | PIVOT by ProductName_Code |
| RAF (2 cols) | BI_DB_dbo.BI_DB_RAF_Invitees_KPIs | Inviter, LastCashoutDate | Invitee→Inviter GCID resolution |

### 5.2 ETL Pipeline

```
Multiple DWH/BI_DB/eMoney sources (20+ tables)
  |-- SP_MarketingCloudDaily @date (column-group merge) ---|
  v
BI_DB_dbo.BI_DB_MarketingCloudDaily (47.1M rows, one per CID)
  |-- SFTP upload to Salesforce Marketing Cloud ---|
  v
Salesforce Marketing Cloud (CRM targeting)
```

Key source tables:
```
DWH_dbo.Dim_Customer .............. AccountId, AirdropCustomerID, PrivacyPolicyID
DWH_dbo.V_Liabilities ............ Credit, UnRealizedEquity, MaxEquity*, CashoutAmount_InProcess
DWH_dbo.Fact_CustomerAction ....... MobileAppLastLogin, WalletLastLogin, CashoutAmount_LastWeek, TotalDepositsAmount_LastYear
DWH_dbo.Dim_Position + Dim_Instrument .. PositionOpen_LastDate_ETF
DWH_dbo.Dim_Mirror ............... FirstTimeCopiedDate
BI_DB_dbo.DWH_GainDaily .......... Gain* (7 cols)
BI_DB_dbo.BI_DB_KYC_Panel ........ KYC_* (8 cols)
BI_DB_dbo.BI_DB_CID_DailyCluster . Cluster, ClusterDate
BI_DB_dbo.BI_DB_CID_LifeStageDefinition . LSD, LSDDate
BI_DB_dbo.BI_DB_CIDFirstDates .... VerificationLevel3Date
BI_DB_dbo.BI_DB_KYC_Score_CID_Level . KYCLeadScore
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms . Deposits*, DepositsUSD_Global
BI_DB_dbo.BI_DB_DDR_Fact_AUM ..... BalanceGlobal, EquityGlobal, Current_Balance_USD
BI_DB_dbo.BI_OUTPUT_Customer_External_Table_ISA . ISA portfolio* (8 cols)
BI_DB_dbo.BI_DB_RAF_Invitees_KPIs  RAF_Inviter, RAF_LastCashoutDate
eMoney_dbo.* ..................... eMoney fiat/card/retention/balance (14 cols)
CopyFromLake.WatchListDB_* ....... Watchlist* (9 cols)
External_* ....................... KYCFlow, IOB, ClubService
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Customer dimension lookup |
| PrivacyPolicyID | Dictionary.PrivacyPolicy | Privacy policy version |
| AccountId | Salesforce Account | External CRM link |
| KYCLeadScore | BI_DB_dbo.BI_DB_KYC_Score_CID_Level | Behavioral cluster source |
| LSD | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | Life stage classification |
| Cluster | BI_DB_dbo.BI_DB_CID_DailyCluster | Behavioral cluster source |

### 6.2 Referenced By (other objects point to this)

No DWH/BI_DB objects reference this table. It is a **terminal CRM export** table — data flows in from DWH sources, then out to Salesforce Marketing Cloud via SFTP.

---

## 7. Sample Queries

### 7.1 Active eMoney Users with High Card Spend

```sql
SELECT CID, AccountSubProgram, Monthly_CardSpent_eMoney, Monthly_RewardedChashBack_eMoney, Cluster
FROM [BI_DB_dbo].[BI_DB_MarketingCloudDaily]
WHERE Monthly_CardSpent_eMoney > 1000
  AND TX_Tier_3M = 'High_Active'
ORDER BY Monthly_CardSpent_eMoney DESC
```

### 7.2 ISA Customers by Portfolio Type

```sql
SELECT CID, AcceptedTnCs_Date,
       DIY_PortfolioCreatedDate, DIY_FirstDepositDate,
       Cash_PortfolioCreatedDate, Cash_FirstDepositDate,
       Managed_PortfolioCreatedDate, Managed_FirstDepositDate,
       IsDefunded_across_all_portfolios
FROM [BI_DB_dbo].[BI_DB_MarketingCloudDaily]
WHERE AcceptedTnCs_Date IS NOT NULL
ORDER BY AcceptedTnCs_Date DESC
```

### 7.3 RAF Program — Invitees with Recent Cashouts

```sql
SELECT mc.CID, mc.RAF_Inviter, mc.RAF_LastCashoutDate, mc.LSD, mc.Cluster
FROM [BI_DB_dbo].[BI_DB_MarketingCloudDaily] mc
WHERE mc.RAF_Inviter IS NOT NULL
  AND mc.RAF_LastCashoutDate >= '2026-01-01'
ORDER BY mc.RAF_LastCashoutDate DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 5 T1, 82 T2, 0 T3, 5 T4, 1 T5 | Elements: 97/97 (excl. legacy note row), Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_MarketingCloudDaily | Type: Table | Production Source: SP_MarketingCloudDaily (multi-source aggregation)*
