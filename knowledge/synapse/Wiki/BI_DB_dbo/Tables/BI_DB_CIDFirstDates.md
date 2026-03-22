# BI_DB_dbo.BI_DB_CIDFirstDates

> Master customer milestone table — tracks the first and last occurrence of every key customer lifecycle event (registration, deposit, trade, login, copy, contact, verification, funded status) with resolved dimension names, serving as the central customer-centric denormalized reference for 32+ downstream BI reports.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple — Dim_Customer (primary identity), Fact_CustomerAction (events), Fact_BillingDeposit (deposit details), Fact_SnapshotCustomer (verification), V_Liabilities (equity), external compliance/appsflyer tables |
| **Refresh** | Daily (SB_Daily) |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_CIDFirstDates` is the BI layer's central customer milestone tracker. For every valid customer, it records **when** each major lifecycle event first (and last) occurred — registration, first login, first deposit, first trade, first copy, first contact, first verification, first funded date — along with resolved dimension names (country, language, channel, club, manager) so downstream reports can filter and segment without additional JOINs.

The table draws from 13+ DWH source tables via `SP_CIDFirstDates` (1,467 lines). The core identity and demographics come from `DWH_dbo.Dim_Customer`, event timestamps from `Fact_CustomerAction` (filtered by ActionTypeID), deposit details from `Fact_BillingDeposit` via the FTDTransactionID link, and verification milestones from `Fact_SnapshotCustomer`. The "funded" status columns use two inline functions (`Function_Population_Funded`, `Function_Population_First_Time_Funded`) that implement the business definition of "funded" — deposited + verified + traded/received IOB + equity > 0.

The SP runs daily as part of the Service Broker `SB_Daily` process at **Priority 90** (final aggregation wave — runs after nearly all other BI_DB SPs). It uses an incremental update pattern: new customers are INSERTed, existing customers are updated only when dimension attributes change (CDC-style change detection), and event dates are updated only when a new earlier (first) or later (last) event is found. Internal/invalid customers (IsValidCustomer=0) are actively DELETEd. There are 29+ legacy/disabled/nullified columns that remain in the DDL but are no longer populated.

---

## 2. Business Logic

### 2.1 Customer Lifecycle Events

**What**: Each "First*" column captures the earliest occurrence of a customer action; each "Last*" column captures the most recent.

**Columns Involved**: `FirstLoggedIn`, `FirstPosOpenDate`, `FirstDepositDate`, `FirstMirrorRegistrationDate`, `FirstCashierLogin`, `FirstStocksOpenDate`, `FirstCashoutDate`, `FirstTimeBeingCopied`, `FirstContactDate`, and their `Last*` counterparts.

**Rules**:
- Events are sourced from `Fact_CustomerAction` filtered by specific ActionTypeIDs
- ActionTypeID mapping: 1=ManualPosOpen, 2=MirrorPosOpen, 7=Deposit, 8=Cashout, 14=Login, 15=LifeStageEvent, 17=MirrorRegistration, 21=PublishPost, 27=DepositAttempt (FirstCustomerAction), 29=CashierLogin, 34=StocksOpen
- First dates update only when NULL or when new event is earlier than existing
- Last dates update to the most recent occurrence
- `registered` = MIN(RegisteredDemo, RegisteredReal) — whichever happened first

**Diagram**:
```
Registration ─→ Login ─→ Deposit Attempt ─→ First Deposit ─→ First Trade ─→ Funded
     │              │              │                │               │           │
     ▼              ▼              ▼                ▼               ▼           ▼
 registered   FirstLoggedIn  FirstDeposit    FirstDeposit   FirstPosOpen  IsFundedNew
                             Attempt         Date/Amount    Date          FirstNewFundedDate
```

### 2.2 Funded Status Definition

**What**: The business definition of "funded" — a customer who has deposited, is verified, has traded (or received IOB/options trade), and has positive equity.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- `IsFundedNew` = 1 if `Function_Population_Funded(@dateINT)` returns the RealCID. The function checks: depositor (IsDepositor=1) + verified (VerificationLevelID=3) + has activity (trade OR IOB/interest OR options trade) + equity > 0 (from BI_DB_Client_Balance_CID_Level_New + eMoneyClientBalance + Options)
- `FirstNewFundedDate` = GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)) — the latest of the three qualifying criteria
- `LastNewFundedDate` = MAX(Date) from DDR_Customer_Daily_Status WHERE IsFunded=1, coalesced with yesterday's funded check
- "Bad FTDs" (2025-08-18 to 2025-08-20 with Amount=1 and single deposit) are excluded

### 2.3 Deposit Flow (Alias-Level Attribution)

**What**: First deposit details are split across two source paths depending on which column.

**Columns Involved**: `FirstDepositDate`, `FirstDepositAmount`, `FirstDepositProcessor`, `FirstDepositFundingType`

**Rules**:
- `FirstDepositDate` and `FirstDepositAmount` are read **directly from Dim_Customer** (alias `dc` in SP line 604/607). Dim_Customer sources these from `CustomerFinanceDB.Customer.FirstTimeDeposits` with FTDRecoveryDate override logic.
- `FirstDepositProcessor` and `FirstDepositFundingType` are **join-enriched** from `Dim_BillingDepot` and `Dim_FundingType` respectively, via `Fact_BillingDeposit` matched using `dc.FTDTransactionID = CAST(D.DepositID AS NVARCHAR(4000))`.
- These are distinct source paths despite appearing in the same SELECT block — the JOIN to Fact_BillingDeposit serves the processor/funding columns, not the date/amount columns.

### 2.4 Change Detection (SCD Update)

**What**: Dimension attributes are only updated when they actually change.

**Columns Involved**: `Club`, `Language`, `CommunicationLanguage`, `Blocked`, `Email`, `BirthDate`, `Gender`, `PotentialDesk`, `Region`, `CountryID`, `State`, `PrivacyPolicyID`, `SubAffiliateID`, `SerialID`, `LabelName`, `Channel`, `SubChannel`, `Verified`, `Manager`, `RegulationID`

**Rules**:
- A `#updatenew` temp table compares every dimension column between the current BI_DB row and the freshly-resolved #CustomerData
- Uses `ISNULL(old,'') <> ISNULL(new,'') COLLATE Latin1_General_BIN` for string comparisons
- Only customers with at least one changed attribute are updated
- `UpdateDate` is set to `GETDATE()` on every modification

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `CID` with a CLUSTERED INDEX on `CID`. Always include `CID` in WHERE clauses or JOINs for optimal Synapse query performance. JOINs to other CID-distributed tables (like BI_DB_Client_Balance_CID_Level_New) will be co-located.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer funnel conversion rates | Filter by `registered` date range, count non-NULL milestone dates (FirstDepositDate, FirstPosOpenDate, etc.) |
| FTD cohort analysis | `WHERE YEAR(FirstDepositDate) != 1900 AND FirstDepositDate BETWEEN @start AND @end` |
| Active funded customers | `WHERE IsFundedNew = 1` |
| Time-to-deposit from registration | `DATEDIFF(DAY, registered, FirstDepositDate) WHERE YEAR(FirstDepositDate) != 1900` |
| Customers never deposited | `WHERE FirstDepositDate IS NULL OR YEAR(FirstDepositDate) = 1900` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | ON CID = CID | Daily balance and P&L metrics |
| BI_DB_dbo.BI_DB_PositionPnL | ON CID = CID | Position-level P&L |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer attributes not in this table |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Country details (already resolved as Country column) |
| DWH_dbo.Dim_Regulation | ON RegulationID = RegulationID | Regulation name |

### 3.4 Gotchas

- **Sentinel dates**: `1900-01-01` means "never happened." Always filter with `YEAR(column) != 1900` or `column IS NOT NULL AND column > '1900-01-02'`.
- **29+ dead columns**: Many columns (Demo*, Social*, Model_*, Risk/DepositGroup, PEP*, Retention*, Feed*, etc.) are no longer populated. They remain in the DDL but contain only NULL or stale data. See the "Not Populated / Disabled / Nullified" section in the lineage file.
- **FirstDepositAttemptProcessor/FundingType**: Always contain 'NA' — these are not actually resolved despite the column names. Only the actual first deposit columns (FirstDepositProcessor, FirstDepositFundingType) have real values.
- **Credit/RealizedEquity**: Only updated when @date = @yesterday (the SP's date parameter). These reflect yesterday's V_Liabilities snapshot, not a historical value for the customer.
- **Blocked**: 1 if PlayerStatusID IN (2,4,6,7,8,9), not a direct flag from production.
- **PII columns**: Email, BirthDate, UserName, Gender, IP are PII. Email and IP have dynamic data masking. UC PII table: `pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag | `[UNVERIFIED]`? |
|-------|-------|-----|-----------------|
| 5 stars | Tier 5 (domain expert / glossary) | `(Tier 5 — domain expert)` | No |
| 4 stars | Tier 1 (upstream wiki verbatim) | `(Tier 1 — ...)` | No |
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` | No |
| 2 stars | Tier 3 (live data / sampling) | `(Tier 3 — ...)` | No |
| 1.5 stars | Tier 4-Atlassian | `(Tier 4 — Confluence/Jira)` | No |
| 1 star | Tier 4-Inferred | `[UNVERIFIED] (Tier 4 — inferred)` | **Yes** |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts. (Tier 1 — Customer.CustomerStatic) |
| 3 | OriginalCID | int | YES | Original customer ID from the source provider. Together with OriginalProviderID, enables tracing of migrated accounts. Default=0. (Tier 1 — Customer.CustomerStatic) |
| 4 | UserName | varchar(500) | YES | Customer login username. PII — dynamic data masking in UC. (Tier 1 — Customer.CustomerStatic) |
| 5 | Club | varchar(500) | YES | Customer experience tier name. Resolved from Dim_PlayerLevel.Name via PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Diamond, etc. (Tier 2 — SP_CIDFirstDates, Dim_PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate (partner) ID under which the customer was acquired. Sourced from Dim_Customer.AffiliateID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Marketing acquisition channel. Resolved from Dim_Channel.Channel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Marketing sub-channel. Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. (Tier 2 — SP_CIDFirstDates, Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | Internal segment label name. Resolved from Dim_Label.Name via LabelID. (Tier 2 — SP_CIDFirstDates, Dim_Label) |
| 10 | Country | varchar(500) | YES | Country of residence name. Resolved from Dim_Country.Name via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 11 | Language | char(500) | YES | Platform language name. Resolved from Dim_Language.Name via LanguageID. (Tier 2 — SP_CIDFirstDates, Dim_Language) |
| 12 | Region | nvarchar(500) | NO | Geographic region name. Resolved from Dim_Country.Region via CountryID. Values: North Europe, French, Eastern Europe, Other EU, LATAM, etc. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales desk assignment. Resolved from Dim_Country.Desk via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 14 | Email | varchar(500) | YES | Customer email address. PII — masked with `FUNCTION = 'default()'`. (Tier 1 — Customer.CustomerStatic) |
| 15 | Credit | money | YES | Customer credit balance (yesterday's snapshot). From V_Liabilities.Credit, ISNULL(,0). Only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) |
| 16 | RealizedEquity | money | YES | Customer realized equity (yesterday's snapshot). From V_Liabilities.RealizedEquity, ISNULL(,0). Only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) |
| 17 | SocialConnect | int | YES | Social media connection flag. **Disabled** — linked server source removed. Contains stale/NULL data. (Tier 3b — DDL structure, disabled) |
| 18 | Verified | int | YES | Verification level ID. Resolved from Dim_VerificationLevel.ID via VerificationLevelID. Values: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. (Tier 2 — SP_CIDFirstDates, Dim_VerificationLevel) |
| 19 | KYC | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 20 | DocsOK | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 21 | Blocked | int | YES | Account blocked flag. CASE WHEN PlayerStatusID IN (2,4,6,7,8,9) THEN 1 ELSE 0. 2=Suspended, 4=AccountClosed, 6=BlockedByBO, 7=BlockedByRisk, 8=BlockedByPayment, 9=BlockedByCompliance. (Tier 2 — SP_CIDFirstDates) |
| 22 | IsSales | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 23 | HasPic | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 24 | Bankruptcy | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 25 | FunnelName | varchar(500) | YES | Registration funnel name. Resolved from Dim_Funnel.Name via FunnelID. (Tier 2 — SP_CIDFirstDates, Dim_Funnel) |
| 26 | DownloadID | int | YES | Platform download source ID. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 27 | registered | datetime | NO | Customer registration date. MIN(RegisteredDemo, RegisteredReal) — whichever happened first. (Tier 2 — SP_CIDFirstDates) |
| 28 | FirstTimeUser | datetime | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 29 | FirstLoggedIn | datetime | YES | First platform login date. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 30 | FirstDemoLoggedIn | datetime | YES | **Disabled** — demo step disabled 2017-01-26. Contains stale/NULL data. (Tier 3b — DDL structure, disabled) |
| 31 | FirstDemoPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 32 | FirstDemoMirrorRegistrationDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 33 | LastDemoMirrorRegistrationDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 34 | FirstDemoMirrorPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 35 | FirstCashierLogin | datetime | YES | First cashier (deposit page) login. MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID=29. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 36 | FirstDepositAttempt | datetime | YES | First deposit attempt date. From Fact_FirstCustomerAction.FirstOccurred WHERE ActionTypeID=27. (Tier 2 — SP_CIDFirstDates, Fact_FirstCustomerAction) |
| 37 | FirstDepositAttemptAmount | numeric(36,12) | YES | First deposit attempt amount (USD). Amount*ExchangeRate from Fact_FirstCustomerAction WHERE ActionTypeID=27. (Tier 2 — SP_CIDFirstDates, Fact_FirstCustomerAction) |
| 38 | FirstDepositAttemptProcessor | varchar(500) | YES | First deposit attempt processor. Always 'NA' — not actually resolved. (Tier 2 — SP_CIDFirstDates) |
| 39 | FirstDepositAttemptFundingType | varchar(500) | YES | First deposit attempt funding type. Always 'NA' — not actually resolved. (Tier 2 — SP_CIDFirstDates) |
| 40 | FirstDepositDate | datetime | YES | First successful deposit date. Read directly from Dim_Customer.FirstDepositDate (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (GlobalFTD service) with FTDRecoveryDate override logic in SP_Dim_Customer. 1900-01-01 means no deposit (sentinel). Filter with `YEAR(FirstDepositDate) != 1900`. (Tier 2 — SP_Dim_Customer ← CustomerFinanceDB.FirstTimeDeposits) |
| 41 | FirstDepositProcessor | varchar(500) | YES | Payment processor for the first deposit. Resolved from Dim_BillingDepot.Name (alias `dbd`) via Fact_BillingDeposit.DepotID, matched to the FTD record using Dim_Customer.FTDTransactionID = CAST(Fact_BillingDeposit.DepositID AS NVARCHAR(4000)). (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_BillingDepot) |
| 42 | FirstDepositFundingType | varchar(500) | YES | Funding type for the first deposit. Resolved from Dim_FundingType.Name (alias `F`) via Fact_BillingDeposit.FundingTypeID, matched to the FTD record using Dim_Customer.FTDTransactionID = CAST(Fact_BillingDeposit.DepositID AS NVARCHAR(4000)). Values: CreditCard, Wire, PayPal, eToroMoney, IXOPAY-Nuvei, etc. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_FundingType) |
| 43 | FirstDepositAmount | money | YES | Amount of first successful deposit in USD. Read directly from Dim_Customer.FirstDepositAmount (alias `dc`), which is sourced from CustomerFinanceDB.Customer.FirstTimeDeposits (FTDAmountInUsd). Default 0. (Tier 2 — SP_Dim_Customer ← CustomerFinanceDB.FirstTimeDeposits) |
| 44 | FirstEngagementDate | datetime | YES | **Disabled** — engagement section commented out. (Tier 3b — DDL structure, disabled) |
| 45 | FirstPosOpenDate | datetime | YES | First position open date (manual or copy). MIN(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2) AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 46 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade registration date. Occurred from Fact_CustomerAction WHERE ActionTypeID=17 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 47 | LastMirrorRegistrationDate | datetime | YES | Last copy-trade registration date. MAX(Occurred) WHERE ActionTypeID=17. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 48 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=2 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 49 | FirstLeadDate | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 50 | FirstDepositAmountExtended | money | YES | **Not populated** by SP. Legacy extended deposit amount. (Tier 3b — DDL structure, not populated) |
| 51 | ReferralID | int | YES | Referral CID — the customer who referred this customer (for RAF program tracking). (Tier 1 — Customer.CustomerStatic) |
| 52 | LastDemoLoggedIn | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 53 | LastDemoMirrorPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 54 | LastDemoPosOpenDate | datetime | YES | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) |
| 55 | LastEngagementDate | datetime | YES | **Disabled** — engagement section commented out. (Tier 3b — DDL structure, disabled) |
| 56 | LastLoggedIn | datetime | YES | Last platform login date. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 57 | LastMirrorPosOpenDate | datetime | YES | Last copy-trade position open date. MAX(Occurred) WHERE ActionTypeID=2. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 58 | LastPosOpenDate | datetime | YES | Last position open date (manual or copy). MAX(Occurred) WHERE ActionTypeID IN (1,2). (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 59 | CertifiedGuru | int | YES | **Not populated** by SP. Legacy Popular Investor flag. (Tier 3b — DDL structure, not populated) |
| 60 | FirstTimeBeingCopied | datetime | YES | First time this customer was copied by another. MIN(OpenOccurred) from Dim_Mirror GROUP BY ParentCID. (Tier 2 — SP_CIDFirstDates, Dim_Mirror) |
| 61 | LastTimeBeingCopied | datetime | YES | Last time this customer was copied. MAX(OpenOccurred) from Dim_Mirror GROUP BY ParentCID. (Tier 2 — SP_CIDFirstDates, Dim_Mirror) |
| 62 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). PII. (Tier 1 — Customer.CustomerStatic) |
| 63 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. (Tier 1 — Customer.CustomerStatic) |
| 64 | FirstMenualPosOpenDate | datetime | YES | First manual (non-copy) position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=1 AND rn=1. Note: column name has typo "Menual". (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 65 | BirthDate | datetime | YES | Customer date of birth. PII. (Tier 1 — Customer.CustomerStatic) |
| 66 | CommunicationLanguage | varchar(500) | YES | Language for customer communications. Resolved from Dim_Language.Name via CommunicationLanguageID. (Tier 2 — SP_CIDFirstDates, Dim_Language) |
| 67 | LastMenualPosOpenDate | datetime | YES | Last manual position open date. MAX(Occurred) WHERE ActionTypeID=1. Note: column name has typo "Menual". (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 68 | FirstTimeSocialConnect | datetime | YES | **Disabled** — social connect section disabled (linked server removed). (Tier 3b — DDL structure, disabled) |
| 69 | LastCashierLogin | datetime | YES | Last cashier (deposit page) login. MAX(Occurred) WHERE ActionTypeID=29. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 70 | FirstCashoutDate | datetime | YES | First withdrawal date. Occurred from Fact_CustomerAction WHERE ActionTypeID=8 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 71 | FunnelFromName | varchar(500) | YES | Source funnel variant name. Resolved from Dim_Funnel.Name via FunnelFromID. (Tier 2 — SP_CIDFirstDates, Dim_Funnel) |
| 72 | BannerID | int | YES | Advertising banner ID that led to registration. Legacy acquisition tracking. (Tier 1 — Customer.CustomerStatic) |
| 73 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate identifier string. Sourced from Dim_Customer.SubSerialID (renamed). (Tier 1 — Customer.CustomerStatic) |
| 74 | FirstCampaignID | nvarchar(1024) | YES | First campaign ID. From External_etoro_History_Credit.CampaignID, ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Occurred)=1. (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 75 | FirstCampaignDate | datetime | YES | First campaign occurrence date. From External_etoro_History_Credit.Occurred (first by date). (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 76 | FirstCampaignAmount | money | YES | First campaign payment amount. From External_etoro_History_Credit.Payment (first by date). (Tier 2 — SP_CIDFirstDates, etoro.History.Credit) |
| 77 | FirstStocksOpenDate | datetime | YES | First real stock position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=34 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 78 | SevenDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 79 | FirstToSevenDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 80 | FirstDateRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 81 | LastContactAttemptDate_ByPhone | datetime | YES | Last phone contact attempt date. PII — masked. **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 82 | LastContactDate | datetime | YES | Last successful contact date (email or phone). MAX(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 83 | LastContactAttemptDate | datetime | YES | **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 84 | LastContactDate_ByPhone | datetime | YES | Last successful phone contact date. PII — masked. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 85 | FirstContactAttemptDate | datetime | YES | **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 86 | FirstContactAttemptDate_ByPhone | datetime | YES | **Not directly populated** by SP. PII — masked. Legacy column. (Tier 3b — DDL structure, not populated) |
| 87 | FirstContactDate | datetime | YES | First successful contact date (email or phone). MIN(CreatedDate_SF) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Completed_Contact_Email__c','Phone_Call_Succeed__c'). (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) |
| 88 | FirstContactDate_ByPhone | datetime | YES | **Not directly populated** by SP. PII — masked. Legacy column. (Tier 3b — DDL structure, not populated) |
| 89 | PremiumAccount | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 90 | Evangelist | int | YES | **Not populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) |
| 91 | FirstToThirtyDayRetained | int | YES | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) |
| 92 | FirstWallEngagement | datetime | YES | **Not populated** by SP. Legacy social wall metric. (Tier 3b — DDL structure, not populated) |
| 93 | FeedUnBlocked | tinyint | YES | **Not populated** by SP. Legacy social feed flag. (Tier 3b — DDL structure, not populated) |
| 94 | PrivacyPolicyID | tinyint | YES | Version of the privacy policy the customer has accepted. (Tier 1 — Customer.CustomerStatic) |
| 95 | IP | bigint | YES | Registration IP address (stored as bigint). PII — masked. (Tier 1 — Customer.CustomerStatic) |
| 96 | FeedUnlocked | tinyint | YES | **Not populated** by SP. Legacy social feed flag. (Tier 3b — DDL structure, not populated) |
| 97 | Follow5UsersDate | datetime | YES | **Not populated** by SP. Legacy social onboarding metric. (Tier 3b — DDL structure, not populated) |
| 98 | NumberOfUsersFollowed | int | YES | **Not populated** by SP. Legacy social metric. (Tier 3b — DDL structure, not populated) |
| 99 | PopularInvestor | int | YES | **Not populated** by SP. Legacy Popular Investor flag. (Tier 3b — DDL structure, not populated) |
| 100 | Manager | nvarchar(500) | YES | Account manager full name. Resolved from Dim_Manager: FirstName+' '+LastName via AccountManagerID. (Tier 2 — SP_CIDFirstDates, Dim_Manager) |
| 101 | SuitabilityTestCompletedAt | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 102 | PassedSuitabilityTest | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 103 | Model_FTDsOTDs | float | YES | **Not populated** by SP. Legacy ML model prediction score. (Tier 3b — DDL structure, not populated) |
| 104 | Model_Leads | float | YES | **Not populated** by SP. Legacy ML model prediction score. (Tier 3b — DDL structure, not populated) |
| 105 | LastDepositDate | datetime | YES | Last deposit date. Fact_BillingDeposit.ModificationDate from #fundingLast WHERE rn_desc=1 (latest by Occurred). (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit) |
| 106 | LastDepositAmount | money | YES | Last deposit amount in USD. Amount*ExchangeRate from Fact_BillingDeposit via #fundingLast WHERE rn_desc=1. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit) |
| 107 | LastDepositFundingType | varchar(500) | YES | Last deposit funding type. Resolved from Dim_FundingType.Name via Fact_BillingDeposit.FundingTypeID from #fundingLast. (Tier 2 — SP_CIDFirstDates, Fact_BillingDeposit → Dim_FundingType) |
| 108 | Model_ReDepositor | money | YES | **Not populated** by SP. Legacy ML model prediction. (Tier 3b — DDL structure, not populated) |
| 109 | RegulationID | int | YES | Regulatory entity governing this account. FK to Dictionary.Regulation. Top values: CySEC, BVI, FCA. (Tier 1 — BackOffice.Customer) |
| 110 | RiskGroup | varchar(500) | YES | **Disabled** — risk group section disabled 2023-05-09. Contains stale data. (Tier 3b — DDL structure, disabled) |
| 111 | DepositGroup | varchar(500) | YES | **Disabled** — deposit group section disabled 2023-05-09. Contains stale data. (Tier 3b — DDL structure, disabled) |
| 112 | UpdateDate | datetime | YES | ETL load timestamp — set to GETDATE() on each row insert or update. (Tier 2 — SP_CIDFirstDates) |
| 113 | VerificationLevel1Date | datetime | YES | First date customer reached verification level 1. MIN(FromDateID) from Fact_SnapshotCustomer WHERE VerificationLevelID=1 via Dim_Range. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 114 | VerificationLevel2Date | datetime | YES | First date customer reached verification level 2. MIN(FromDateID) WHERE VerificationLevelID=2. Backfilled from level 3 if level 2 not found. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 115 | VerificationLevel3Date | datetime | YES | First date customer reached verification level 3 (fully verified). MIN(FromDateID) WHERE VerificationLevelID=3. Backfills levels 1 and 2 if not already set. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 116 | EmailVerifiedDate | date | YES | First email verification date. MIN(FromDateID) from Fact_SnapshotCustomer WHERE IsEmailVerified=1 via Dim_Range. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 117 | FirstInstallDate | datetime | YES | First mobile app install date. MIN(EventTime) from BI_DB_AppFlyer_Reports WHERE EventName='install', linked via AppsFlyerID from External_MarketPerformance_Tracking_Customer. (Tier 2 — SP_CIDFirstDates, BI_DB_AppFlyer_Reports) |
| 118 | EvMatchStatusDate | datetime | YES | First electronic verification match date (EvMatchStatus=2). MIN(FromDateID) from Fact_SnapshotCustomer WHERE EvMatchStatus=2 via Dim_Range. (Tier 2 — SP_CIDFirstDates, Fact_SnapshotCustomer) |
| 119 | State | varchar(100) | YES | US state or province name. Resolved from Dim_State_and_Province.Name via RegionID=RegionByIP_ID. (Tier 2 — SP_CIDFirstDates, Dim_State_and_Province) |
| 120 | PhoneVerifiedDate | datetime | YES | First phone verification date. MIN(ValidFrom) from History.BackOfficeCustomer WHERE PhoneVerifiedID IN (1,2). 1=AutomaticallyVerified, 2=ManuallyVerified. (Tier 2 — SP_CIDFirstDates, etoro.History.BackOfficeCustomer) |
| 121 | KycModeID | int | YES | KYC mode. From External_ComplianceStateDB_Compliance_CustomerKycMode.KycModeID via GCID. (Tier 2 — SP_CIDFirstDates, ComplianceStateDB) |
| 122 | PEPCreatedTime | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 123 | PEPStatusUpdatedDate | datetime | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 124 | isPassedPEP | tinyint | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 125 | PEPStatusID | int | YES | **Nullified** — discontinued 2022-02-22. Contains only NULL. (Tier 3b — DDL structure, nullified) |
| 126 | EvMatchStatus | int | YES | Electronic verification match result. Synced from Dim_Customer.EvMatchStatus with change detection (only updated when value differs). (Tier 1 — BackOffice.Customer) |
| 127 | FTDIsLessThanAWeek | int | YES | Fast FTD flag. CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0 THEN 1 ELSE 0. Only computed for customers registered in the last 10 days. (Tier 2 — SP_CIDFirstDates) |
| 128 | DesignatedRegulationID | int | YES | Secondary/override regulation for accounts subject to multiple jurisdictions. Synced from Dim_Customer.DesignatedRegulationID with change detection. (Tier 1 — BackOffice.Customer) |
| 129 | ProfessionalApplicationDate | date | YES | Date the customer applied for professional investor status. From External_ComplianceStateDB_Compliance_CustomerProfessionalQuestionnaireResult.ApplicationDate via GCID. (Tier 2 — SP_CIDFirstDates, ComplianceStateDB) |
| 130 | LastCampaignSentDate | datetime | YES | **Not populated** by SP. Legacy marketing column. (Tier 3b — DDL structure, not populated) |
| 131 | NewMarketingRegion | varchar(100) | YES | Manual marketing region override. Resolved from Dim_Country.MarketingRegionManualName via CountryID. (Tier 2 — SP_CIDFirstDates, Dim_Country) |
| 132 | IsFundedNew | tinyint | YES | Funded status flag. 1 if Function_Population_Funded(@dateINT) returns RealCID (depositor + verified to level 3 + has activity [trade/IOB/options] + equity > 0), else 0. Updated daily for all customers. (Tier 2 — SP_CIDFirstDates, Function_Population_Funded) |
| 133 | FirstNewFundedDate | date | YES | First time funded date. From Function_Population_First_Time_Funded(): GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Only set once (WHERE FirstNewFundedDate IS NULL). (Tier 2 — SP_CIDFirstDates, Function_Population_First_Time_Funded) |
| 134 | LastNewFundedDate | date | YES | Last known funded date. COALESCE of yesterday's Function_Population_Funded result and MAX(Date) from BI_DB_DDR_Customer_Daily_Status WHERE IsFunded=1. (Tier 2 — SP_CIDFirstDates, BI_DB_DDR_Customer_Daily_Status) |
| 135 | IsAirDropBefore | tinyint | YES | Received crypto airdrop before depositing flag. 1 if CID exists in Fact_CustomerAction WHERE IsAirDrop=1 AND ActionTypeID=1 AND InstrumentTypeID=5 (real stock) AND FirstDepositDate IS NOT NULL. Only checked in 30-day window. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 136 | SignedW8Date | date | YES | **Disabled** — W8 signing section disabled 2022-02-29. (Tier 3b — DDL structure, disabled) |
| 137 | LastCashoutDate | datetime | YES | Last withdrawal date. Occurred from Fact_CustomerAction WHERE ActionTypeID=8 AND rn_desc=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 138 | LastPublishedPostDate | date | YES | Last social post published date. MAX(CAST(Occurred AS DATE)) from Fact_CustomerAction WHERE ActionTypeID=21. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |
| 139 | LastActionDateForLifeStage | date | YES | Last life-stage qualifying action date. MAX(CAST(Occurred AS DATE)) from Fact_CustomerAction WHERE ActionTypeID IN (1,15,17). Used for customer lifecycle segmentation. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) |

---

## 5. Lineage

### 5.1 Production Sources

| Source Type | Object | Columns Fed |
|------------|--------|-------------|
| DWH Dimension | Dim_Customer | CID, GCID, OriginalCID, UserName, Gender, BirthDate, Email, CountryID, RegulationID, ReferralID, DownloadID, BannerID, PrivacyPolicyID, IP, SubAffiliateID, SerialID, FirstDepositDate, FirstDepositAmount, EvMatchStatus, DesignatedRegulationID |
| DWH Fact | Fact_CustomerAction | All First*/Last* event dates (login, deposit, trade, cashout, copy reg, stocks, post, lifestage) |
| DWH Fact | Fact_BillingDeposit | FirstDepositProcessor, FirstDepositFundingType, LastDeposit* columns |
| DWH Fact | Fact_FirstCustomerAction | FirstDepositAttempt* columns |
| DWH Snapshot | Fact_SnapshotCustomer | Verification*Date, EmailVerifiedDate, EvMatchStatusDate |
| DWH View | V_Liabilities | Credit, RealizedEquity |
| DWH Dimension | Dim_Mirror | FirstTimeBeingCopied, LastTimeBeingCopied |
| BI_DB Internal | BI_DB_UsageTracking_SF | Contact tracking columns |
| External Table | etoro.History.Credit | Campaign columns |
| External Table | History.BackOfficeCustomer | PhoneVerifiedDate |
| External Table | ComplianceStateDB | KycModeID, ProfessionalApplicationDate |
| BI_DB Internal | BI_DB_AppFlyer_Reports | FirstInstallDate |
| BI_DB Function | Function_Population_Funded | IsFundedNew |
| BI_DB Function | Function_Population_First_Time_Funded | FirstNewFundedDate |
| BI_DB Internal | BI_DB_DDR_Customer_Daily_Status | LastNewFundedDate |

Full lineage details: see `BI_DB_CIDFirstDates.lineage.md`

### 5.2 ETL Pipeline

```
Dim_Customer + Fact_CustomerAction + 11 other DWH tables
    │
    ▼
SP_CIDFirstDates (Priority 90, SB_Daily — runs after nearly all BI_DB SPs)
    │  Pattern: Incremental INSERT (new CIDs) + CDC UPDATE (changed dimensions) + event date accumulation
    │
    ▼
BI_DB_CIDFirstDates (one row per valid customer)
    │
    ▼
32+ downstream reader SPs (AML, Compliance, Marketing, Affiliate, Retention reports)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Core customer dimension |
| CountryID | DWH_dbo.Dim_Country | Country of residence |
| RegulationID | DWH_dbo.Dim_Regulation | Regulatory entity |
| DesignatedRegulationID | DWH_dbo.Dim_Regulation | Secondary regulation |
| GCID | DWH_dbo.Dim_Customer (GCID) | Cross-product identity |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_CID_DailyPanel_FullData | CID | Daily panel customer attributes |
| BI_DB_dbo.SP_CID_MonthlyPanel_FullData | CID | Monthly panel customer attributes |
| BI_DB_dbo.SP_BI_AMLPeriodicReview | CID | AML periodic review |
| BI_DB_dbo.SP_AML_KYC_Process | CID | KYC compliance process |
| BI_DB_dbo.SP_MarketingCloudDaily | CID | Marketing cloud daily feed |
| BI_DB_dbo.SP_Compliance_Forbidden_Trades | CID | Compliance trade monitoring |
| BI_DB_dbo.SP_AffiliateFTDsAndURLS | CID | Affiliate FTD attribution |
| BI_DB_dbo.SP_Vulnerable_Customers | CID | Vulnerable customer detection |
| BI_DB_dbo.SP_OPS_MultipleAccounts | CID | Duplicate account detection |

---

## 7. Sample Queries

### 7.1 FTD Cohort Conversion Funnel

```sql
SELECT
    CAST(registered AS DATE) AS reg_date,
    COUNT(*) AS registrations,
    SUM(CASE WHEN FirstLoggedIn IS NOT NULL THEN 1 ELSE 0 END) AS logged_in,
    SUM(CASE WHEN YEAR(FirstDepositDate) != 1900 AND FirstDepositDate IS NOT NULL THEN 1 ELSE 0 END) AS deposited,
    SUM(CASE WHEN FirstPosOpenDate IS NOT NULL THEN 1 ELSE 0 END) AS traded,
    SUM(CASE WHEN IsFundedNew = 1 THEN 1 ELSE 0 END) AS funded
FROM BI_DB_dbo.BI_DB_CIDFirstDates
WHERE registered >= '2025-01-01'
GROUP BY CAST(registered AS DATE)
ORDER BY reg_date
```

### 7.2 Time-to-Deposit Analysis by Country

```sql
SELECT
    Country,
    COUNT(*) AS depositors,
    AVG(DATEDIFF(DAY, registered, FirstDepositDate)) AS avg_days_to_ftd,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(DAY, registered, FirstDepositDate)) OVER (PARTITION BY Country) AS median_days_to_ftd
FROM BI_DB_dbo.BI_DB_CIDFirstDates
WHERE YEAR(FirstDepositDate) != 1900
  AND FirstDepositDate IS NOT NULL
  AND registered >= '2024-01-01'
GROUP BY Country
HAVING COUNT(*) >= 100
ORDER BY avg_days_to_ftd
```

### 7.3 Currently Funded Customers by Region and Regulation

```sql
SELECT
    cfd.Region,
    cfd.RegulationID,
    COUNT(*) AS funded_customers,
    SUM(cfd.RealizedEquity) AS total_equity
FROM BI_DB_dbo.BI_DB_CIDFirstDates cfd
WHERE cfd.IsFundedNew = 1
GROUP BY cfd.Region, cfd.RegulationID
ORDER BY funded_customers DESC
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PII data mapping for DL](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11908645178) | Confluence | PII columns: Email, BirthDate, UserName, Gender, IP. UC path: internal-sources/Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_CIDFirstDates |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862) | Confluence | BI_DB tables are aggregation/report layer on top of DWH facts and dimensions |
| [ONBRD-7033: Fix FirstTradeEventDate](https://etoro-jira.atlassian.net/browse/ONBRD-7033) | Jira | User Activation used BI_DB_CIDFirstDates.FirstPosOpenDate as source for FirstTradeEventDate migration fix |
| [DSR-6273: Fix Databricks job TR_MIFIR_PIN_Check](https://etoro-jira.atlassian.net/browse/DSR-6273) | Jira | UC table reference: pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates |
| [DS-1404: Migration data BI_DB Step 1](https://etoro-jira.atlassian.net/browse/DS-1404) | Jira | Original migration of BI_DB_CIDFirstDates to Synapse |
| [DS-1216: UPDATE dbo.BI_DB_CIDFirstDates](https://etoro-jira.atlassian.net/browse/DS-1216) | Jira | Historical data fix request |

---

*Generated: 2026-03-20 | Quality: 9.5/10 (★★★★★) | Phases: P1,P2,P5,P8,P9,P9B,P10,P10.5,P13,P11*
*Tiers: 12 T1, 81 T2, 0 T3, 46 T3b, 0 T4, 0 T5 | Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 10/10*
*Object: BI_DB_dbo.BI_DB_CIDFirstDates | Type: Table | Production Source: Multiple (Dim_Customer primary)*
