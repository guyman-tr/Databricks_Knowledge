# eMoney_Risk_Portfolio

**Schema**: eMoney_dbo  |  **Type**: Table  |  **Database**: Synapse DWH

---

## 1. Table Summary

Daily per-customer AML (Anti-Money Laundering) and financial risk profile for the eToro Money (eMoney) card and IBAN programme. Each row captures a comprehensive snapshot of one customer's eMoney account status, trading profile, historical money flows (segmented by transaction channel), and three-tier risk scores on a single report date.

The table combines customer identity from DWH_dbo (regulation, club, player status, KYC data), eMoney account operational status from FiatDwhDB (historical status as of ReportDate), cumulative money movement aggregates from eMoney_Dim_Transaction (by TxType channel), platform-side deposit totals from Fact_CustomerAction, AML screening attributes from BI_DB_dbo, and a final risk composite. The three risk dimensions are:

- **TurnOverRisk**: based on total cumulative money movement (Low <50K USD, Medium 50K–250K USD, High ≥250K USD)
- **MoneyInRisk / MoneyOutRisk**: based on the dominant transaction channel (Low=TP, Medium=banking/external)
- **OverallRiskScore**: maximum of eMoneyRiskScore (combined MIMO risk) and TradingRiskScore (from the BI_DB risk classification data lake)

Populated daily by SP_eMoney_Risk_Portfolio (866 lines) via a WHILE loop incremental pattern starting from 2023-12-01.

---

## 2. Quick Facts

| Attribute | Value |
|-----------|-------|
| **Rows (total)** | ~1.21 B (as of 2026-04-11) |
| **Daily volume** | ~2.0 M rows per day |
| **Date range** | 2023-12-01 → 2026-04-11 |
| **Grain** | 1 row per (ReportDate, RealCID) |
| **Distribution** | HASH(RealCID) |
| **Storage** | CLUSTERED INDEX (ReportDateID ASC) |
| **Writer SP** | SP_eMoney_Risk_Portfolio |
| **ETL pattern** | WHILE loop daily; DELETE + INSERT per date |
| **Author / Created** | Inessa Kontorovich, 2023-11-14 |
| **Watermark start** | 2023-12-01 |
| **UC Target** | _Not_Migrated |

---

## 3. Grain & Lifecycle

**Grain**: One row per `(ReportDate, RealCID)`. Customers are eligible when their eMoney account exists at or before ReportDate: `eMoney_Dim_Account WHERE CurrencyBalanceCreateDate <= @Date AND GCID <> 0`.

**Historical status resolution**: Status fields (CurrencyBalanceStatus, eMoneyAccountStatus) reflect the account's state as of `ReportDate` — not the current state. They are computed from FiatDwhDB status history tables using `ROW_NUMBER() PARTITION BY … ORDER BY EventTimestamp/Created DESC WHERE … < DATEADD(DAY,1,ReportDate)`.

**Money flow aggregates**: Cumulative lifetime totals through `ReportDate` — not period-specific (no 3M window). `HasTrans3MonthsBeforeDate` is the only 3-month windowed indicator.

**ETL lifecycle**:
1. `@MaxDate = MAX(ReportDate)` watermark from table; if NULL starts at '20231201'
2. WHILE loop: `@3MonthsAgo = DATEADD(MONTH,-3,@Date)`, `@NextDate = DATEADD(DAY,1,@Date)`
3. Per iteration: DELETE WHERE ReportDate=@Date, build ~12 temp tables, INSERT from #final
4. `SET @MaxDate = DATEADD(DAY,1,@MaxDate)`

**NULL risk scores**: ~36% of rows (customers with no eMoney transactions) have NULL for MoneyInRisk, MoneyOutRisk, TurnOverRisk, eMoneyRiskScore, and OverallRiskScore. These are customers who have eMoney accounts but have never completed a settled transaction through ReportDate.

---

## 4. Column Elements

### 4.1 Identity & Keys

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | RealCID | int | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. Distribution key (HASH). (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 — dbo.FiatAccount) |
| 29 | CurrencyBalanceID | int | Auto-incrementing surrogate PK. Referenced by FiatTransactions, FiatCurrencyBalancesStatuses, CurrencyBalancesProvidersMapping, PaymentSpecifications, FiatBankAccount, and BalanceReports. (Tier 1 — dbo.FiatCurrencyBalances) |
| 78 | AccountID | int | Auto-incrementing surrogate primary key. Referenced by all child entity tables as the FK to the account. (Tier 1 — dbo.FiatAccount) |

### 4.2 Customer DWH Profile

| # | Column | Type | Description |
|---|--------|------|-------------|
| 5 | Regulation | varchar(50) | Regulation display name resolved from DWH_dbo.Dim_Regulation. Reflects the customer's regulatory jurisdiction on ReportDate (via Fact_SnapshotCustomer). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 6 | KYC_Country | varchar(50) | Country of residence display name (KYC-verified) from DWH_dbo.Dim_Country, resolved via CountryID from Fact_SnapshotCustomer on ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 7 | Club | varchar(50) | eToro Club tier display name from DWH_dbo.Dim_PlayerLevel, resolved via PlayerLevelID from Fact_SnapshotCustomer on ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 8 | PlayerStatus | varchar(50) | Trading account compliance status display name from DWH_dbo.Dim_PlayerStatus, resolved via PlayerStatusID from Fact_SnapshotCustomer on ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 9 | PlayerStatusID | int | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Active/Registered; other values indicate restricted, closed, banned, or special states. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 10 | PlayerLevelID | int | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Renamed from PlayerLevelID. Production column name; renamed to ClubID in eMoney_Dim_Account. (Tier 1 — Customer.CustomerStatic) |
| 11 | PlayerStatusReason | varchar(50) | Reason for the customer's PlayerStatus (e.g., account closure reason). Resolved from DWH_dbo.Dim_PlayerStatusReasons via Fact_SnapshotCustomer. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 12 | PlayerStatusSubReasonName | varchar(50) | Sub-reason for the customer's PlayerStatus (further granularity below PlayerStatusReason). Resolved from DWH_dbo Dim_PlayerStatusSubReasons. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 13 | VerificationLevelID | int | Customer identity verification level from the trading-side DWH (DWH_dbo.Dim_Customer or Fact_SnapshotCustomer). Indicates KYC/AML verification completeness. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 14 | IsValidCustomer | int | DWH-computed: 1 when not Popular Investor (PlayerLevelID≠4), not label 30/26, and not CountryID=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 — SP_Dim_Customer) |
| 15 | IsDepositor | bit | 1 if the customer has at least one settled platform deposit (Fact_BillingDeposit WHERE IsFTD=1 AND PaymentStatusID=2). Identifies customers who have funded their eToro trading account. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 18 | ScreeningStatus | varchar(255) | AML sanctions and PEP (Politically Exposed Person) screening status from the customer's trading profile. Source unclear from SP code — likely from DWH_dbo.Dim_Customer or an AML system external table. (Tier 4 — SP_eMoney_Risk_Portfolio) |

### 4.3 Customer Demographics & PII

| # | Column | Type | Description |
|---|--------|------|-------------|
| 3 | FirstName | nvarchar(50) | Customer first name. PII field from DWH_dbo.Dim_Customer. Masked or restricted in analytics environments. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 4 | LastName | nvarchar(50) | Customer last name. PII field from DWH_dbo.Dim_Customer. Masked or restricted in analytics environments. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 16 | CitizenshipCountry | varchar(50) | Customer's country of citizenship (nationality), distinct from country of residence (KYC_Country). From DWH_dbo.Dim_Customer. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 17 | POB_Country | varchar(50) | Customer's country of birth. From DWH_dbo.Dim_Customer. Relevant for AML risk assessment (high-risk country of origin). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 19 | RegisteredReal | datetime | eToro trading platform registration timestamp. From DWH_dbo.Dim_Customer (registered datetime field). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 23 | EvMatchStatus | int | Electronic verification match status integer code from DWH_dbo.Dim_Customer. Score or outcome from automated identity verification vendors. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 24 | EvMatch | varchar(30) | Electronic verification match result display name from DWH_dbo.Dim_Customer. (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.4 Platform Deposit History

| # | Column | Type | Description |
|---|--------|------|-------------|
| 20 | PlatformFTD | datetime | Datetime of the customer's first settled eToro trading platform deposit. From DWH_dbo.Fact_BillingDeposit WHERE IsFTD=1 AND PaymentStatusID=2. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 21 | PlatformFTDUSD | decimal | Amount in USD of the customer's first settled eToro trading platform deposit. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 22 | PlatformFTDFundingType | varchar(50) | FundingType name (payment method) of the first settled platform deposit. From DWH_dbo.Fact_BillingDeposit. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 42 | PlatformTotalDepositUSD | decimal | Cumulative total of all settled platform deposits in USD through ReportDate. Aggregated from DWH_dbo.Fact_CustomerAction WHERE ActionTypeID=7. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 43 | PlatformTotalDepositEUR | decimal | Cumulative total of all settled platform deposits converted to EUR: PlatformTotalDepositUSD × USD_EUR_Rate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 44 | USD_EUR_Rate | decimal | USD to EUR exchange rate used for EUR conversion. From DWH_dbo.Fact_CurrencyPriceWithSplit WHERE InstrumentID=2 on or near ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 45 | USD_EUR_RateDate | date | Date of the exchange rate record used for USD_EUR_Rate. May differ from ReportDate if no rate is available for that exact date. (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.5 eMoney Account Status & Identity

| # | Column | Type | Description |
|---|--------|------|-------------|
| 25 | AccountSubProgram | varchar(50) | Current eMoney account sub-program name (e.g., Card Premium UK, IBAN EU Green). Resolved from eMoney_dbo.SubPrograms via eMoney_Dim_Account. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 26 | ProviderHolderID | int | Provider-side account holder identifier from FiatDwhDB (AccountsProviderHoldersMapping). Identifies the customer's account at the card/IBAN provider (Tribe). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 27 | ProviderCurrencyBalanceID | int | Provider-side currency balance identifier from CurrencyBalancesProvidersMapping via eMoney_Account_Mappings. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 28 | eMoneyAccountCreateDate | date | Date the customer's eMoney currency balance account was created. Corresponds to CurrencyBalanceCreateDate in eMoney_Dim_Account. Used as the eligibility start date for this table (CurrencyBalanceCreateDate <= @Date). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 30 | CurrencyBalanceCreateDate | date | Date the currency balance was created in FiatDwhDB (CAST of CurrencyBalanceCreateTime). Duplicate of eMoneyAccountCreateDate in this table. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 31 | CurrencyBalanceStatus | varchar(50) | Currency balance operational status display name as of ReportDate. Resolved from eMoney_Dictionary_CurrencyBalanceStatus via CurrencyBalanceStatusID. Values: Active, Suspended, Blocked, SpendOnly, ReceiveOnly. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 32 | AccountStatusID | int | Current account lifecycle status: 0=Active, 1=Suspended, 2=Deleted. Latest StatusType from FiatAccountStatuses (RNDesc=1 by Created). DWH note: in eMoney_Risk_Portfolio, reflects state as of ReportDate (WHERE Created < DATEADD(DAY,1,ReportDate)). (Tier 1 — dbo.FiatAccountStatuses) |
| 33 | eMoneyAccountStatus | varchar(50) | Account lifecycle status display name for AccountStatusID, resolved from eMoney_Dictionary_AccountStatus. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 34 | eMoneyAccountStatusDate | date | Date of the latest account status change event before ReportDate (FiatAccountStatuses.Created cast to date). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 35 | CurrencyBalanceStatusID | int | Currency balance operational status code as of ReportDate: 0=Active, 1=ReceiveOnly, 2=SpendOnly, 3=Suspended, 4=Blocked. From FiatCurrencyBalancesStatuses WHERE EventTimestamp < DATEADD(DAY,1,ReportDate) (RNDesc=1). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 36 | CurrencyBalanceStatusDate | date | Date of the latest CurrencyBalance status change event before ReportDate (FiatCurrencyBalancesStatuses.EventTimestamp cast to date). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 37 | StatusChangeSourceId | int | Source ID indicating what triggered the latest CurrencyBalance status change (e.g., manual, automated). FK to FiatDwhDB Dictionary_StatusChangeSources. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 38 | StatusChangeReasonId | int | Reason ID for the latest CurrencyBalance status change. FK to FiatDwhDB Dictionary_StatusChangeReasons. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 39 | CurrencyBalanceStatusChangeSource | varchar(50) | Display name for StatusChangeSourceId, resolved from External_FiatDwhDB_Dictionary_StatusChangeSources. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 40 | CurrencyBalanceStatusChangeReason | varchar(50) | Display name for StatusChangeReasonId, resolved from External_FiatDwhDB_Dictionary_StatusChangeReasons. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 41 | IsTestAccount | int | 1 if GCID appears in the Fivetran Google Sheets test-user list (eMoney_google_sheets.emoney_test_users); 0 otherwise. Exclude from all production analytics. (Tier 2 — SP_eMoney_Dim_Account) |
| 77 | IsEU | int | 1 if the customer's eMoney account currency is EUR (CurrencyBalanceISOCode=978 in eMoney_Dim_Account); 0 otherwise. Distinguishes Malta-entity (EUR) customers from UK (GBP) and AUS (AUD). (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.6 KYC & AML Attributes

| # | Column | Type | Description |
|---|--------|------|-------------|
| 46 | HasProofOfIncome | int | 1 if the customer has submitted a proof-of-income document (DocumentTypeID=7 or SuggestedDocumentTypeID=7) in BI_DB_dbo.External_etoro_BackOffice_CustomerDocument; 0 otherwise. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 47 | Occupation | varchar(200) | Customer's self-reported occupation from the KYC questionnaire (Q18 answer text). Source: BI_DB_dbo.BI_DB_KYC_Panel. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 48 | HasAnyTransUpToDate | int | 1 if the customer has any settled eMoney transaction (TxStatusID=2) with TxStatusModificationDateID <= ReportDateID; 0 otherwise. Indicates whether the eMoney account has ever been used through ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 49 | HasTrans3MonthsBeforeDate | int | 1 if the customer has any settled eMoney transaction in the 3-month window ending at ReportDate (DATEADD(MONTH,-3,ReportDate) to ReportDate). Indicates recent eMoney activity. (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.7 eMoney First Transaction (FTD)

| # | Column | Type | Description |
|---|--------|------|-------------|
| 50 | eMoneyFTDTxType | varchar(50) | Transaction type name of the customer's first settled eMoney transaction (TxStatusID=2, ROW_NUMBER=1 ordered by TxStatusModificationTime ASC per CurrencyBalanceID). E.g., MoneyInFromTP (TxTypeID=5) or BankingPaymentsIN (TxTypeID=7). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 51 | CountryOneMoneyFTD | varchar(50) | Country associated with the eMoney FTD transaction. Exact derivation unclear from SP summary. May represent provider country or customer country at FTD time. (Tier 4 — SP_eMoney_Risk_Portfolio) |
| 52 | eMoneyFTDAmount | numeric | Amount of the first settled eMoney transaction in the account's native currency. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 53 | eMoneyFTDDate | date | Date of the first settled eMoney transaction (TxStatusModificationTime cast to date). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 54 | eMoneyDepositType | varchar(17) | Inflow type of the eMoney first transaction: `BankingPaymentsIN` (TxTypeID=7, IBAN-based inflow) or `MoneyInFromTP` (TxTypeID=5, transfer from eToro Trading Platform). (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.8 Cumulative Money Flow Aggregates

All money flow columns represent **cumulative totals through ReportDate** (not period-specific).

TxTypeID mappings used in SP:
- 5 = MoneyInFromTP (inflow from eToro Trading Platform)
- 6 = MoneyOutToTP (outflow to eToro Trading Platform)
- 7 = MoneyInBankingPayments (IBAN inflow)
- 8 = MoneyOutBankingPayments (IBAN outflow)
- Other TxTypeIDs classified as External or Other

| # | Column | Type | Description |
|---|--------|------|-------------|
| 55 | MoneyOutToTP | numeric | Cumulative amount moved OUT to eToro Trading Platform (TxTypeID=6) through ReportDate. From eMoney_Dim_Transaction (TxStatusID=2 settled). (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 56 | MoneyOutExternal | numeric | Cumulative amount moved OUT through external channels (non-TP, non-banking TxTypes) through ReportDate. Exact TxTypeID scope unclear from SP summary. (Tier 4 — SP_eMoney_Risk_Portfolio) |
| 57 | MoneyOutBankingPayments | numeric | Cumulative amount moved OUT via IBAN / banking payments (TxTypeID=8) through ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 58 | MoneyOutOther | numeric | Cumulative amount moved OUT through residual / other transaction channels through ReportDate. Exact TxTypeID scope unclear. (Tier 4 — SP_eMoney_Risk_Portfolio) |
| 59 | MoneyOutTotal | numeric | Total cumulative outflow: MoneyOutToTP + MoneyOutBankingPayments + MoneyOutExternal + MoneyOutOther. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 60 | MoneyInFromTP | numeric | Cumulative amount moved IN from eToro Trading Platform (TxTypeID=5) through ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 61 | MoneyInExternal | numeric | Cumulative amount moved IN from external sources (non-TP, non-banking TxTypes) through ReportDate. Exact TxTypeID scope unclear. (Tier 4 — SP_eMoney_Risk_Portfolio) |
| 62 | MoneyInBankingPayments | numeric | Cumulative amount moved IN via IBAN / banking payments (TxTypeID=7) through ReportDate. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 63 | MoneyInOther | numeric | Cumulative amount moved IN through residual / other transaction channels through ReportDate. Exact TxTypeID scope unclear. (Tier 4 — SP_eMoney_Risk_Portfolio) |
| 64 | MoneyInTotal | numeric | Total cumulative inflow: MoneyInFromTP + MoneyInBankingPayments + MoneyInExternal + MoneyInOther. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 65 | TurnOver | numeric | Total cumulative money movement: MoneyInTotal + MoneyOutTotal. Primary input to TurnOverRisk. NULL if no settled transactions. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 68 | MainIn | numeric | Dominant inflow channel amount: MAX(MoneyInFromTP, MoneyInBankingPayments, MoneyInExternal, MoneyInOther). Used to determine MoneyInRisk channel classification. (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.9 Risk Scoring

| # | Column | Type | Description |
|---|--------|------|-------------|
| 66 | MoneyOutRisk | varchar(6) | Outflow channel risk classification. Low if MoneyOutToTP is the dominant outflow channel (TP-back preferred); Medium if banking payments or other channels dominate. NULL if MoneyOutTotal=0. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 67 | MoneyInRisk | varchar(6) | Inflow channel risk classification. Low if MoneyInFromTP is the dominant inflow channel; Medium if banking payments or other channels dominate. NULL if MoneyInTotal=0. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 69 | TurnOverRisk | varchar(6) | Cumulative turnover risk tier: Low (TurnOver < 50,000 USD), Medium (50,000–250,000 USD), High (≥250,000 USD). NULL if no settled transactions. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 72 | TradingRiskScore | nvarchar(4000) | Risk score from the eToro trading risk classification system. Sourced from BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake (RiskScoreName). Values: Low, Medium, High. NULL if customer has no trading risk classification. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 73 | eMoneyRiskScore | varchar(6) | Composite eMoney risk score combining MoneyOutRisk and MoneyInRisk: Low if both Low; High if either High; Medium otherwise. NULL if no eMoney transactions. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 74 | OverallRiskScore | nvarchar(4000) | Overall risk score: the higher of eMoneyRiskScore and TradingRiskScore (High > Medium > Low). NULL if both are NULL. Distribution 2026-04-11: Medium 88%, NULL 9%, High 2%, Low <1%. (Tier 2 — SP_eMoney_Risk_Portfolio) |

### 4.10 Balance & ETL Metadata

| # | Column | Type | Description |
|---|--------|------|-------------|
| 70 | SettledBalance | float | Customer's settled eMoney account balance as of ReportDate. From eMoney_dbo.ETL_AccountSnapshot WHERE DateID = MAX snapshot DateID ≤ ReportDateID. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 71 | SettledBalanceDate | date | Date of the ETL_AccountSnapshot row used for SettledBalance. May be earlier than ReportDate if no snapshot exists on that exact date. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 75 | ReportDate | date | The report calendar date. Loop variable @Date in SP_eMoney_Risk_Portfolio. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 76 | ReportDateID | int | Integer date surrogate key in YYYYMMDD format. Derived as CONVERT(int, @Date, 112). FK to DWH_dbo.Dim_Date. Clustered index key — queries filtered by date are efficient. (Tier 2 — SP_eMoney_Risk_Portfolio) |
| 79 | UpdateDate | datetime | ETL batch timestamp; set to GETDATE() at SP execution time. (Tier 2 — SP_eMoney_Risk_Portfolio) |

---

## 5. Business Logic

### Risk Scoring Architecture

The table implements a three-layer risk model:

**Layer 1: Channel Risk (MoneyInRisk, MoneyOutRisk)**
Classifies the customer's primary transaction channel. TP-to-TP movement (funds cycling between eToro trading account and eMoney card) is considered lower risk than external banking payments (IBAN-in / IBAN-out). Logic: compare MainIn vs. channel totals; if MoneyInFromTP is the dominant source → Low; if MoneyInBankingPayments or MoneyInExternal dominates → Medium.

**Layer 2: Turnover Risk (TurnOverRisk)**
Thresholds on cumulative lifetime eTM account activity:
- Low: TurnOver < 50,000 USD
- Medium: 50,000 ≤ TurnOver < 250,000 USD
- High: TurnOver ≥ 250,000 USD

**Layer 3: Composite Risk (eMoneyRiskScore, OverallRiskScore)**
- `eMoneyRiskScore` = CASE combining MoneyOutRisk + MoneyInRisk (both Low → Low; any High → High; otherwise Medium)
- `OverallRiskScore` = max(eMoneyRiskScore, TradingRiskScore) — High takes precedence; combines eMoney channel behaviour with the trading-side risk classification from BI_DB

### Historical Status Resolution

Status fields (AccountStatusID, eMoneyAccountStatus, CurrencyBalanceStatus, CurrencyBalanceStatusID) reflect the account's state **as of ReportDate**, not the current live state. This is achieved via ROW_NUMBER() over status history tables WHERE event_time < DATEADD(DAY,1,ReportDate). This means a customer who was Suspended on 2024-01-15 will show Suspended for all rows where ReportDate ≥ 2024-01-15 (until the next status change).

### NULL Handling

~36% of rows (customers with eMoney accounts but no settled transactions as of ReportDate) have NULL values for:
- All MoneyIn/MoneyOut/TurnOver columns
- MoneyInRisk, MoneyOutRisk, TurnOverRisk, eMoneyRiskScore, OverallRiskScore
- eMoneyFTDTxType, CountryOneMoneyFTD, eMoneyFTDAmount, eMoneyFTDDate, eMoneyDepositType
- HasAnyTransUpToDate = 0 (not NULL)

### TxTypeID Money Channel Mapping

| TxTypeID | Direction | Description |
|---------|-----------|-------------|
| 5 | MoneyIn | MoneyInFromTP — transfer from eToro Trading Platform to eMoney wallet |
| 6 | MoneyOut | MoneyOutToTP — transfer from eMoney wallet to eToro Trading Platform |
| 7 | MoneyIn | MoneyInBankingPayments — IBAN / Faster Payments inbound |
| 8 | MoneyOut | MoneyOutBankingPayments — IBAN / Faster Payments outbound |
| Other | Both | Classified as MoneyInExternal/MoneyOutExternal or MoneyInOther/MoneyOutOther |

---

## 6. ETL Orchestration

| Attribute | Detail |
|-----------|--------|
| **Writer SP** | SP_eMoney_Risk_Portfolio |
| **Author** | Inessa Kontorovich |
| **Created** | 2023-11-14 |
| **Lines** | 866 |
| **Pattern** | WHILE loop daily; watermark from MAX(ReportDate) |
| **Watermark start** | '20231201' (if table is empty) |
| **Loop condition** | WHILE @MaxDate <= GETDATE() (processes through today) |
| **Per iteration** | DELETE WHERE ReportDate=@Date; build 12 temp tables; INSERT from #final |

**SP Processing Steps (summarised)**:
1. `#currency_balance_status` — latest CurrencyBalance status per account as of @NextDate (FiatCurrencyBalancesStatuses)
2. `#account_status` — latest FiatAccount status as of @NextDate (FiatAccountStatuses)
3. `#eMoneyprep` — eMoney account base: eMoney_Dim_Account WHERE CurrencyBalanceCreateDate<=@Date AND GCID<>0; computes IsEU
4. `#eMoneyMalta` — joins status tables; applies default CurrencyBalanceStatus='Active' if NULL; deduplicates blocked (StatusID=4) CurrencyBalances where CID appears >1 time
5. `#eMoneyTXDB` — settled eMoney transactions through @DateID (TxStatusID=2, TxStatusModificationDateID<=@DateID)
6. `#eMoneyFTD` — ROW_NUMBER per CurrencyBalanceID by TxStatusModificationTime → first settled transaction per account
7. `#popprep` — DWH customer enrichment: Fact_SnapshotCustomer JOIN Dim_Range/Country/Regulation/PlayerStatus/PlayerLevel; LEFT JOIN PlayerStatusReasons/SubReasons
8. `#mop` — platform FTD from Fact_BillingDeposit (IsFTD=1, PaymentStatusID=2)
9. `#risk` — TradingRiskScore from BI_DB_dbo risk classification DataLake view
10. `#deposit` — PlatformTotalDepositUSD/EUR from Fact_CustomerAction (ActionTypeID=7) × Fact_CurrencyPriceWithSplit
11. `#occupation` / `#income2` — KYC occupation (Q18) and proof-of-income flag from BI_DB_dbo
12. `#eMoneyBalance` — settled balance from ETL_AccountSnapshot (MAX snapshot date ≤ @DateID)
13. `#eMoneyTXprep` — MoneyIn/MoneyOut aggregates by TxTypeID
14. `#final` — joins all temp tables; computes TurnOver, MainIn, risk tier CASE logic

---

## 7. Data Quality

| Check | Observation |
|-------|-------------|
| **Row count** | ~1.21B total; ~2M per day (2026-04-11) |
| **Date range** | 2023-12-01 → 2026-04-11 |
| **NULL risk scores** | ~36% NULL (customers with no eMoney transactions as of ReportDate) |
| **OverallRiskScore distribution (2026-04-11)** | Medium=88%, NULL=9%, High=2%, Low<1% |
| **eMoneyRiskScore distribution** | Low=59%, NULL=36%, Medium=3%, High=0.5% |
| **eMoneyAccountStatus** | Active=99%; ~1% have NULL eMoneyAccountStatus (no FiatAccountStatuses record before ReportDate) |
| **CurrencyBalanceStatus** | Active=91%, Suspended=7%, Blocked=1%, SpendOnly/ReceiveOnly <1% |
| **Duplicate check** | SP deduplicates customers with multiple Blocked CurrencyBalances (keeps most recent) |
| **SettledBalanceDate** | May lag ReportDate if ETL_AccountSnapshot hasn't been populated for that exact date |

---

## 8. Usage Notes

- **Primary use case**: AML risk monitoring, regulatory reporting, and customer risk profiling for the eToro Money card and IBAN programme.
- **Current state vs. historical**: Status fields (AccountStatusID, CurrencyBalanceStatus, etc.) reflect the historical state as of ReportDate — not the live current state. For current state, query eMoney_Dim_Account directly.
- **NULL customers**: ~36% of rows have no eMoney transaction data. These customers have eMoney accounts but have never transacted. Use `HasAnyTransUpToDate = 1` to filter to active transactors only.
- **Risk score interpretation**: OverallRiskScore=Medium is the most common outcome (~88%). High (~2%) warrants AML review. The eMoneyRiskScore is eMoney-specific; OverallRiskScore incorporates the trading-side TradingRiskScore as well.
- **PII fields**: FirstName, LastName, CitizenshipCountry, POB_Country, Occupation, BankAccountIBAN-equivalent fields are PII. Apply appropriate access controls in queries.
- **TurnOver thresholds**: The 50K/250K USD thresholds for TurnOverRisk are hardcoded in SP_eMoney_Risk_Portfolio and may change with AML policy updates.
- **No Tier 1 columns for risk/AML logic**: The risk scoring columns (TurnOverRisk, MoneyInRisk, MoneyOutRisk, eMoneyRiskScore, OverallRiskScore) are all SP-computed with no upstream wiki. Only identity and status columns have Tier 1 descriptions inherited from FiatDwhDB/Customer.CustomerStatic via eMoney_Dim_Account.
- **isEU usage**: IsEU=1 identifies Malta-entity customers (EUR currency balance). Use alongside Regulation='CySEC' for CySEC-regulated AML compliance queries.
