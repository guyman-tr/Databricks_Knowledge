# BI_DB_dbo.BI_DB_CIDFirstDates

> Customer lifecycle milestone table — one row per customer (CID), tracking registration, first/last dates for key activities (deposit, login, position open, copy-trade, cashout), demographic attributes, acquisition channel, verification status, and regulatory assignment.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multiple sources (DWH_dbo.Dim_Customer, DWH_dbo.Fact_CustomerAction, DWH_dbo.Fact_BillingDeposit, and others) |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX on CID |
| | |
| **UC Target** | `pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates` |
| **UC Format** | Delta |
| **UC Partitioned By** | None |
| **UC Table Type** | MANAGED |

---

## 1. Business Meaning

**BI_DB_CIDFirstDates** is the primary customer lifecycle milestone table for eToro's BI layer. Each row represents a single validated customer (CID) and captures the full journey from registration through deposit, trading, copy-trading, social engagement, and verification milestones. It answers: "When did this customer first (and last) perform each key activity?" along with their current demographic and acquisition attributes.

The data originates from multiple DWH dimension and fact tables. The primary customer profile comes from **DWH_dbo.Dim_Customer** (demographics, regulation, verification), activity milestones from **DWH_dbo.Fact_CustomerAction** (login, position open, deposit, cashout, copy-trade, etc.), deposit details from **DWH_dbo.Fact_BillingDeposit**, copy-trade data from **DWH_dbo.Dim_Mirror**, verification snapshots from **DWH_dbo.Fact_SnapshotCustomer**, contact tracking from **BI_DB_dbo.BI_DB_UsageTracking_SF**, and KYC mode from **ComplianceStateDB**. See the upstream production wiki at `DB_Schema/etoro/Wiki/` for full column-level documentation of source tables.

Data is refreshed **daily** via `SP_CIDFirstDates`, which runs with an `@date` parameter (typically yesterday). The SP uses incremental logic — new customers are INSERTed, existing customers are UPDATEd only when attribute values change or new milestones are reached. Credit/RealizedEquity are only updated when `@date` equals yesterday. Internal/test customers (IsValidCustomer=0) are actively deleted from the table.

---

## 2. Business Logic

### 2.1 Customer Validation & Internal Account Exclusion

**What**: Only validated external customers are kept; internal/test accounts are purged.

**Columns Involved**: `CID`

**Rules**:
- Dim_Customer.IsValidCustomer = 0 → customer is deleted from this table
- This means every row in BI_DB_CIDFirstDates represents a real external customer

### 2.2 Blocked Status Derivation

**What**: The Blocked flag is computed from PlayerStatusID, not a direct copy.

**Columns Involved**: `Blocked`

**Rules**:
- PlayerStatusID IN (2, 4, 6, 7, 8, 9) → Blocked = 1
- All other PlayerStatusID values → Blocked = 0
- PlayerStatus 2 = Blocked, 4 = Blocked Upon Request, 6-9 = various restricted states

### 2.3 Registration Date Logic

**What**: The `registered` column takes the earliest of demo or real registration.

**Columns Involved**: `registered`

**Rules**:
- `registered = MIN(RegisteredDemo, RegisteredReal)` from Dim_Customer
- This captures the customer's first-ever interaction with the platform, whether they started on demo or real

### 2.4 First-Time Deposit (FTD) Fast-Track Flag

**What**: Identifies customers who deposited within their first week.

**Columns Involved**: `FTDIsLessThanAWeek`, `registered`, `FirstDepositDate`, `FirstDepositAmount`

**Rules**:
- `DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0` → FTDIsLessThanAWeek = 1
- Otherwise → 0
- Only recalculated for customers registered in the last 10 days

### 2.5 Funded Status (IsFundedNew)

**What**: Whether the customer is currently "funded" — an active depositor meeting business criteria.

**Columns Involved**: `IsFundedNew`, `FirstNewFundedDate`, `LastNewFundedDate`

**Rules**:
- Determined by `Function_Population_Funded(@dateINT)` — a complex UDF evaluating deposit, verification, and position activity
- IsFundedNew = 1 if the function returns the customer's RealCID; 0 otherwise
- FirstNewFundedDate comes from `Function_Population_First_Time_Funded()` — set once, never overwritten
- LastNewFundedDate is the most recent date the customer was funded (from DDR daily status or yesterday's function)

### 2.6 Verification Level Cascade

**What**: Verification dates backfill — achieving a higher level retroactively fills lower levels.

**Columns Involved**: `VerificationLevel1Date`, `VerificationLevel2Date`, `VerificationLevel3Date`

**Rules**:
- If VerificationLevel3Date is set and Level2 is NULL → Level2 = Level3 date
- If VerificationLevel2Date is set and Level1 is NULL → Level1 = Level2 date
- This ensures a customer who reaches Level 3 always has Level 1 and 2 dates filled

### 2.7 Sentinel Date Convention

**What**: The date `1900-01-01` is used as a sentinel meaning "no event" or "not applicable."

**Columns Involved**: `FirstDepositDate`, `FirstLeadDate`, `SuitabilityTestCompletedAt`, `PEPCreatedTime`, `PEPStatusUpdatedDate`, `BirthDate`

**Rules**:
- `1900-01-01 00:00:00` means the event never occurred — treat as NULL in analytics
- `1900-01-02` in BirthDate means unknown birth date
- When filtering for "has deposited," use `FirstDepositDate IS NOT NULL AND YEAR(FirstDepositDate) != 1900`

### 2.8 Deprecated/Discontinued Columns

**What**: Several columns are no longer updated by the ETL but retain historical values.

**Columns Involved**: `KYC`, `SuitabilityTestCompletedAt`, `PassedSuitabilityTest`, `PEPCreatedTime`, `PEPStatusUpdatedDate`, `isPassedPEP`, `PEPStatusID`, `FirstLeadDate`, `Bankruptcy`, `RiskGroup`, `DepositGroup`, `SocialConnect`, `FirstTimeSocialConnect`, `FirstEngagementDate`, `LastEngagementDate`, `FirstWallEngagement`

**Rules**:
- KYC, Suitability, PEP columns: nullified in a one-time script (2022-02-22), no longer updated
- RiskGroup, DepositGroup: ETL section disabled (2023-05-09)
- SocialConnect: source table not updated since Sep 2018
- Engagement dates: ETL section commented out
- These columns may still contain historical values for older customers but should not be relied upon for current analysis

### 2.9 ActionTypeID Mapping (from Fact_CustomerAction)

**What**: The SP uses specific ActionTypeIDs to populate milestone dates.

**Columns Involved**: Multiple First*/Last* date columns

**Rules**:
```
ActionTypeID   Meaning              Populates
1              Manual Position Open  FirstMenualPosOpenDate, FirstPosOpenDate, LastMenualPosOpenDate, LastPosOpenDate
2              Copy Position Open    FirstMirrorPosOpenDate, FirstPosOpenDate, LastMirrorPosOpenDate, LastPosOpenDate
7              Deposit/Credit        Deposit-related columns (via #hc)
8              Cashout/Withdrawal    FirstCashoutDate, LastCashoutDate
14             Login                 FirstLoggedIn, LastLoggedIn
17             Mirror Registration   FirstMirrorRegistrationDate, LastMirrorRegistrationDate
21             Published Post        LastPublishedPostDate
29             Cashier Login         FirstCashierLogin, LastCashierLogin
34             Stocks Open           FirstStocksOpenDate
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is HASH-distributed on `CID` with a CLUSTERED INDEX on `CID`. Always include `CID` in WHERE clauses or JOINs for optimal query performance. Queries filtering by other columns (e.g., `Country`, `RegulationID`) will require cross-distribution data movement.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table is stored as Delta (MANAGED) at `pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates`. It is NOT partitioned. For large analytical queries, filter on `CID` when possible. A masked version exists at `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` with PII columns redacted.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer profile lookup | `WHERE CID = @cid` — single-row lookup, fastest pattern |
| All depositors in a regulation | `WHERE FirstDepositDate IS NOT NULL AND YEAR(FirstDepositDate) != 1900 AND RegulationID = @reg` |
| FTD conversion funnel | Compare `registered` → `FirstDepositDate` → `FirstPosOpenDate` date gaps |
| Currently funded customers | `WHERE IsFundedNew = 1` |
| Acquisition channel analysis | `GROUP BY Channel, SubChannel` — no date filter needed |
| Customers registered in date range | `WHERE registered BETWEEN @start AND @end` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `ON CID = dc.RealCID` | Get additional customer attributes not in this table (AccountTypeID, MifidCategorizationID, etc.) |
| DWH_dbo.Dim_Country | `ON CountryID = dc.CountryID` | Resolve CountryID to ISO codes, risk group, EU membership |
| DWH_dbo.Dim_Regulation | `ON RegulationID = dr.ID` | Resolve RegulationID to regulation name and cluster |
| BI_DB_dbo.BI_DB_DDR_CID_Level | `ON CID = ddr.CID AND ddr.DateID = @dateID` | Get daily-level activity metrics (funded status, equity, etc.) |
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | `ON CID = cb.CID AND cb.DateID = @dateID` | Get daily financial position (equity, commission, exposure) |
| DWH_dbo.Dim_EvMatchStatus | `ON EvMatchStatus = des.EvMatchStatusID` | Resolve electronic verification status to name |

### 3.4 Gotchas

- **Sentinel dates**: `1900-01-01` means "never happened" — always filter with `YEAR(col) != 1900` or `col > '1901-01-01'`
- **Blocked != account closed**: Blocked=1 means the account is restricted, not necessarily permanently closed. Check Dim_Customer.PendingClosureStatusID for closure status
- **Verified is NOT boolean**: Values 0-3 map to DWH_dbo.Dim_VerificationLevel (0=Unverified through 3=Fully Verified). Do NOT treat as 0/1
- **FirstMenualPosOpenDate**: Note the typo — "Menual" should be "Manual." This is the first manually opened position (not copy-trade)
- **RiskGroup and DepositGroup**: These columns are no longer updated (disabled 2023-05-09). Do not use for current analysis
- **PII table**: This table contains PII (Email, IP, BirthDate, UserName). Use the masked UC version for non-privileged access
- **No date column for time-series**: This is a panel/SCD table with one row per CID. For daily snapshots, use BI_DB_DDR_CID_Level instead

---

## 4. Elements

### Confidence Tier Legend

| Tier | Stars | Source | Meaning |
|------|-------|--------|---------|
| Tier 1 | ★★★★ | Upstream production wiki (verbatim) | Validated through full code-is-king pipeline on production sources |
| Tier 2 | ★★★ | Synapse SP code / CASE patterns | Derived from direct analysis of SP_CIDFirstDates logic |
| Tier 3 | ★★ | Live data distribution | Inferred from value distribution analysis in Phase 3 |
| Tier 4 | ★ | Column name inference | Educated guess from naming conventions — flagged [UNVERIFIED] |
| Tier 5 | ★★★★★ | Domain expert confirmed | Highest confidence — overrides all other tiers |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — the primary identifier for a customer in the eToro platform. Maps to Dim_Customer.RealCID. This is the distribution key; always filter/join on CID. (Tier 2 — SP code, Dim_Customer) |
| 2 | GCID | int | YES | Global Customer ID — a globally unique customer identifier across all eToro entities. Sourced from Dim_Customer.GCID. Used for cross-system joins (e.g., ComplianceStateDB uses GCID). (Tier 2 — SP code, Dim_Customer) |
| 3 | OriginalCID | int | YES | Original CID before account merge or migration. From Dim_Customer.OriginalCID. Useful for tracking customers who were merged from other accounts. (Tier 2 — SP code, Dim_Customer) |
| 4 | UserName | varchar(500) | YES | Customer's eToro username (display name on the platform). From Dim_Customer.UserName. (Tier 2 — SP code, Dim_Customer) |
| 5 | Club | varchar(500) | YES | Customer's eToro Club tier level. Resolved from Dim_PlayerLevel.Name via PlayerLevelID. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Updated daily when tier changes. (Tier 2 — SP code, Dim_PlayerLevel) |
| 6 | SerialID | int | YES | Affiliate serial ID. Sourced from Dim_Customer.AffiliateID. Identifies the affiliate partner who referred this customer. 0 = no affiliate. (Tier 2 — SP code, Dim_Customer) |
| 7 | Channel | nvarchar(500) | NO | Marketing acquisition channel. Resolved from Dim_Channel via Dim_Affiliate.SubChannelID. Values include: Direct, Affiliate, SEM, SEO, Mobile Acquisition, Media Performance, Friend Referral, and others. Default 'Direct' when NULL. (Tier 2 — SP code, Dim_Channel) |
| 8 | SubChannel | nvarchar(500) | NO | Sub-channel within the acquisition channel. Resolved from Dim_Channel. Values include: Direct Mobile, Affiliate, Direct, SEO, Mobile CPA, Google UAC, Google Brand, FB, YT, ASA, etc. Default 'Direct' when NULL. (Tier 2 — SP code, Dim_Channel) |
| 9 | LabelName | varchar(500) | YES | Platform brand/label the customer registered under. Resolved from Dim_Label.Name via LabelID. Values: eToro (dominant ~97%), eToroRussia, ICMarkets, eToroChina, Royal-CM, eToroUSA, etc. (Tier 2 — SP code, Dim_Label) |
| 10 | Country | varchar(500) | YES | Customer's country of registration. Resolved from Dim_Country.Name via CountryID. (Tier 2 — SP code, Dim_Country) |
| 11 | Language | char(500) | YES | Customer's platform language preference. Resolved from Dim_Language.Name via LanguageID. (Tier 2 — SP code, Dim_Language) |
| 12 | Region | nvarchar(500) | NO | Geographic region for business reporting. Resolved from Dim_Country.Region. Values: UK, French, German, Italian, Other Asia, USA, Spanish, Eastern Europe, etc. (Tier 2 — SP code, Dim_Country) |
| 13 | PotentialDesk | varchar(8000) | YES | Sales desk assignment. Resolved from Dim_Country.Desk. Indicates which sales/support desk handles this customer's region. (Tier 2 — SP code, Dim_Country) |
| 14 | Email | varchar(500) | YES | Customer's email address. PII — use masked UC table for non-privileged access. From Dim_Customer.Email. (Tier 2 — SP code, Dim_Customer) |
| 15 | Credit | money | YES | Current credit balance (USD). From V_Liabilities. Updated only when @date = yesterday. Represents available trading credit including bonuses. (Tier 2 — SP code, V_Liabilities) |
| 16 | RealizedEquity | money | YES | Current realized equity (USD). From V_Liabilities. Updated only when @date = yesterday. Represents deposits + realized P&L - withdrawals. (Tier 2 — SP code, V_Liabilities) |
| 17 | SocialConnect | int | YES | **DEPRECATED** — Whether customer connected a social account. 1 = connected, NULL = not connected. Source table not updated since Sep 2018. (Tier 2 — SP code, deprecated) |
| 18 | Verified | int | YES | Customer verification level ID. Resolved from Dim_VerificationLevel via DWHVerificationLevelID. Values: 0 = Unverified (~47%), 1 = Level 1 (~11%), 2 = Level 2 (~21%), 3 = Fully Verified (~21%). NOT a boolean. (Tier 2 — SP code, Dim_VerificationLevel) |
| 19 | KYC | int | YES | **DEPRECATED** — KYC status. Nullified 2022-02-22. All values are NULL. Do not use. (Tier 2 — SP code, deprecated) |
| 20 | DocsOK | int | YES | Whether customer's documents have been approved. 1 = approved, NULL = not yet approved. Mostly NULL (~99.9%). (Tier 3 — live data) |
| 21 | Blocked | int | YES | Whether customer account is blocked/restricted. 0 = active (~83%), 1 = blocked (~17%). Computed from PlayerStatusID IN (2,4,6,7,8,9). (Tier 2 — SP code, Dim_PlayerStatus) |
| 22 | IsSales | int | YES | Whether customer is flagged as a sales account. 0 = not sales, 1 = sales. Mostly NULL (~94%). (Tier 3 — live data) |
| 23 | HasPic | int | YES | Whether customer has a profile picture. 1 = has picture, 0 = no picture. Mostly NULL (~98.6%). (Tier 3 — live data) |
| 24 | Bankruptcy | int | YES | **DEPRECATED** — Bankruptcy flag. Nullified 2022-02-22. All values are NULL. Do not use. (Tier 2 — SP code, deprecated) |
| 25 | FunnelName | varchar(500) | YES | Registration funnel name. Resolved from Dim_Funnel.Name via FunnelID. Values: Retoro, reToroiOS, reToroAndroid, Web Trader, etc. Indicates which app/platform was used for registration. (Tier 2 — SP code, Dim_Funnel) |
| 26 | DownloadID | int | YES | Download tracking ID from customer acquisition. From Dim_Customer.DownloadID. Typically 0. (Tier 2 — SP code, Dim_Customer) |
| 27 | registered | datetime | NO | Customer registration date — the earlier of RegisteredDemo and RegisteredReal from Dim_Customer. This is the customer's first-ever interaction with the platform. (Tier 2 — SP code, Dim_Customer) |
| 28 | FirstTimeUser | datetime | YES | [UNVERIFIED] First time the user engaged with the platform as a new user. Rarely populated — not updated by current SP. (Tier 4 — column name inference) |
| 29 | FirstLoggedIn | datetime | YES | First real-money login timestamp. From Fact_CustomerAction where ActionTypeID=14. Set once, never overwritten (uses MIN logic). (Tier 2 — SP code, Fact_CustomerAction) |
| 30 | FirstDemoLoggedIn | datetime | YES | [UNVERIFIED] First demo account login timestamp. Not updated by current SP code. May contain historical values only. (Tier 4 — column name inference) |
| 31 | FirstDemoPosOpenDate | datetime | YES | [UNVERIFIED] First demo position open date. Not updated by current SP code. May contain historical values only. (Tier 4 — column name inference) |
| 32 | FirstDemoMirrorRegistrationDate | datetime | YES | [UNVERIFIED] First demo copy-trade registration date. Not updated by current SP code. (Tier 4 — column name inference) |
| 33 | LastDemoMirrorRegistrationDate | datetime | YES | [UNVERIFIED] Last demo copy-trade registration date. Not updated by current SP code. (Tier 4 — column name inference) |
| 34 | FirstDemoMirrorPosOpenDate | datetime | YES | [UNVERIFIED] First demo copy-trade position open date. Not updated by current SP code. (Tier 4 — column name inference) |
| 35 | FirstCashierLogin | datetime | YES | First cashier page login. From Fact_CustomerAction where ActionTypeID=29 (MIN). Indicates first time customer visited the deposit/cashier page. (Tier 2 — SP code, Fact_CustomerAction) |
| 36 | FirstDepositAttempt | datetime | YES | First deposit attempt timestamp (regardless of success). From Fact_FirstCustomerAction where ActionTypeID=27. (Tier 2 — SP code, Fact_FirstCustomerAction) |
| 37 | FirstDepositAttemptAmount | numeric(36,12) | YES | Amount of the first deposit attempt in USD. Computed as Amount * ExchangeRate. (Tier 2 — SP code) |
| 38 | FirstDepositAttemptProcessor | varchar(500) | YES | Payment processor for the first deposit attempt. Currently set to 'NA' (not available from current data source). (Tier 2 — SP code) |
| 39 | FirstDepositAttemptFundingType | varchar(500) | YES | Funding type for the first deposit attempt. Currently set to 'NA' (not available from current data source). (Tier 2 — SP code) |
| 40 | FirstDepositDate | datetime | YES | First successful deposit date. From Dim_Customer.FirstDepositDate via Fact_BillingDeposit. 1900-01-01 means no deposit (sentinel). Filter with YEAR(FirstDepositDate) != 1900. (Tier 2 — SP code, Fact_BillingDeposit) |
| 41 | FirstDepositProcessor | varchar(500) | YES | Payment processor for the first deposit. Resolved from Dim_BillingDepot.Name via DepotID. (Tier 2 — SP code, Dim_BillingDepot) |
| 42 | FirstDepositFundingType | varchar(500) | YES | Funding type for the first deposit. Resolved from Dim_FundingType.Name via FundingTypeID. Values: CreditCard, Wire, PayPal, eToroMoney, IXOPAY-Nuvei, etc. (Tier 2 — SP code, Dim_FundingType) |
| 43 | FirstDepositAmount | money | YES | Amount of the first successful deposit in USD. Default 0. From Dim_Customer.FirstDepositAmount. (Tier 2 — SP code, Dim_Customer) |
| 44 | FirstEngagementDate | datetime | YES | **DEPRECATED** — First social engagement date. ETL section commented out. May contain historical values. (Tier 2 — SP code, deprecated) |
| 45 | FirstPosOpenDate | datetime | YES | First position open date (manual or copy-trade). From Fact_CustomerAction where ActionTypeID IN (1,2). Uses MIN logic. (Tier 2 — SP code, Fact_CustomerAction) |
| 46 | FirstMirrorRegistrationDate | datetime | YES | First copy-trade (mirror) registration date. From Fact_CustomerAction where ActionTypeID=17. (Tier 2 — SP code, Fact_CustomerAction) |
| 47 | LastMirrorRegistrationDate | datetime | YES | Most recent copy-trade registration date. From Fact_CustomerAction where ActionTypeID=17 (MAX). (Tier 2 — SP code, Fact_CustomerAction) |
| 48 | FirstMirrorPosOpenDate | datetime | YES | First copy-trade position open date. From Fact_CustomerAction where ActionTypeID=2. (Tier 2 — SP code, Fact_CustomerAction) |
| 49 | FirstLeadDate | datetime | YES | **DEPRECATED** — First lead date. Nullified 2022-02-22. 1900-01-01 = sentinel for older records. Do not use. (Tier 2 — SP code, deprecated) |
| 50 | FirstDepositAmountExtended | money | YES | [UNVERIFIED] Extended first deposit amount — may include bonuses or promotions. Not updated by current SP. (Tier 4 — column name inference) |
| 51 | ReferralID | int | YES | CID of the customer who referred this customer. 0 = no referral. From Dim_Customer.ReferralID. (Tier 2 — SP code, Dim_Customer) |
| 52 | LastDemoLoggedIn | datetime | YES | [UNVERIFIED] Last demo login date. Not updated by current SP. (Tier 4 — column name inference) |
| 53 | LastDemoMirrorPosOpenDate | datetime | YES | [UNVERIFIED] Last demo copy-trade position date. Not updated by current SP. (Tier 4 — column name inference) |
| 54 | LastDemoPosOpenDate | datetime | YES | [UNVERIFIED] Last demo position open date. Not updated by current SP. (Tier 4 — column name inference) |
| 55 | LastEngagementDate | datetime | YES | **DEPRECATED** — Last social engagement date. ETL section commented out. (Tier 2 — SP code, deprecated) |
| 56 | LastLoggedIn | datetime | YES | Most recent real-money login timestamp. From Fact_CustomerAction where ActionTypeID=14 (MAX). (Tier 2 — SP code, Fact_CustomerAction) |
| 57 | LastMirrorPosOpenDate | datetime | YES | Most recent copy-trade position open date. From Fact_CustomerAction where ActionTypeID=2 (MAX). (Tier 2 — SP code, Fact_CustomerAction) |
| 58 | LastPosOpenDate | datetime | YES | Most recent position open date (manual or copy). From Fact_CustomerAction where ActionTypeID IN (1,2) (MAX). (Tier 2 — SP code, Fact_CustomerAction) |
| 59 | CertifiedGuru | int | YES | Whether the customer is a certified Popular Investor (guru). 1 = certified, NULL = not certified. Very rare (~515 out of 45M). (Tier 3 — live data) |
| 60 | FirstTimeBeingCopied | datetime | YES | First time another customer copied this customer's trades. From Dim_Mirror.OpenOccurred (MIN for this CID as ParentCID). (Tier 2 — SP code, Dim_Mirror) |
| 61 | LastTimeBeingCopied | datetime | YES | Most recent time another customer copied this customer's trades. From Dim_Mirror.OpenOccurred (MAX for this CID as ParentCID). (Tier 2 — SP code, Dim_Mirror) |
| 62 | Gender | char(1) | YES | Customer gender. Values: M = Male (~51%), F = Female (~11%), U = Unknown (<0.1%), NULL = not provided (~38%). (Tier 2 — SP code, Dim_Customer) |
| 63 | CountryID | int | YES | Country ID — FK to Dim_Country.CountryID. Use Dim_Country for country name, region, regulation mapping, and risk group. (Tier 2 — SP code, Dim_Customer) |
| 64 | FirstMenualPosOpenDate | datetime | YES | First manually opened position date (NOT copy-trade). From Fact_CustomerAction where ActionTypeID=1. Note: "Menual" is a typo for "Manual." (Tier 2 — SP code, Fact_CustomerAction) |
| 65 | BirthDate | datetime | YES | Customer's date of birth. PII. 1900-01-02 = unknown/not provided. From Dim_Customer.BirthDate. (Tier 2 — SP code, Dim_Customer) |
| 66 | CommunicationLanguage | varchar(500) | YES | Customer's preferred communication language (for emails, notifications). Resolved from Dim_Language.Name via CommunicationLanguageID. May differ from platform Language. (Tier 2 — SP code, Dim_Language) |
| 67 | LastMenualPosOpenDate | datetime | YES | Most recent manually opened position date. From Fact_CustomerAction where ActionTypeID=1 (MAX). Note: "Menual" is a typo for "Manual." (Tier 2 — SP code, Fact_CustomerAction) |
| 68 | FirstTimeSocialConnect | datetime | YES | **DEPRECATED** — First social account connection date. Source not updated since 2018. (Tier 2 — SP code, deprecated) |
| 69 | LastCashierLogin | datetime | YES | Most recent cashier page login. From Fact_CustomerAction where ActionTypeID=29 (MAX). (Tier 2 — SP code, Fact_CustomerAction) |
| 70 | FirstCashoutDate | datetime | YES | First withdrawal/cashout date. From Fact_CustomerAction where ActionTypeID=8 (MIN). (Tier 2 — SP code, Fact_CustomerAction) |
| 71 | FunnelFromName | varchar(500) | YES | Name of the originating marketing funnel. Resolved from Dim_Funnel.Name via FunnelFromID. Often shows the specific landing page or campaign funnel (e.g., "eToro Homepage", "Stocks Offering", "reToroiOS"). (Tier 2 — SP code, Dim_Funnel) |
| 72 | BannerID | int | YES | Affiliate banner ID. From Dim_Customer.BannerID. 0 = no banner/direct. (Tier 2 — SP code, Dim_Customer) |
| 73 | SubAffiliateID | nvarchar(1024) | YES | Sub-affiliate tracking ID. From Dim_Customer.SubSerialID. Can contain URLs, campaign tags, or partner codes (e.g., "ShortURL_WS_CP", affiliate URLs). Free-text. (Tier 2 — SP code, Dim_Customer) |
| 74 | FirstCampaignID | nvarchar(1024) | YES | ID of the first marketing campaign the customer received. From History.Credit.CampaignID (via External_etoro_History_Credit). (Tier 2 — SP code, History.Credit) |
| 75 | FirstCampaignDate | datetime | YES | Date of the first marketing campaign received. (Tier 2 — SP code, History.Credit) |
| 76 | FirstCampaignAmount | money | YES | Amount of the first campaign payment/credit received (USD). (Tier 2 — SP code, History.Credit) |
| 77 | FirstStocksOpenDate | datetime | YES | First date the customer opened a real stocks position. From Fact_CustomerAction where ActionTypeID=34. (Tier 2 — SP code, Fact_CustomerAction) |
| 78 | SevenDayRetained | int | YES | [UNVERIFIED] Whether customer was retained at day 7 after first deposit. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 — column name inference) |
| 79 | FirstToSevenDayRetained | int | YES | [UNVERIFIED] Whether customer was retained between first deposit and day 7. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 — column name inference) |
| 80 | FirstDateRetained | int | YES | [UNVERIFIED] Whether customer was retained on first-date basis. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 — column name inference) |
| 81 | LastContactAttemptDate_ByPhone | datetime | YES | Most recent phone contact attempt date. From BI_DB_UsageTracking_SF — Salesforce usage tracking. (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 82 | LastContactDate | datetime | YES | Most recent successful contact date (any channel). From BI_DB_UsageTracking_SF where ActionName IN ('Completed_Contact_Email__c', 'Phone_Call_Succeed__c'). (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 83 | LastContactAttemptDate | datetime | YES | Most recent contact attempt date (any channel). From BI_DB_UsageTracking_SF. (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 84 | LastContactDate_ByPhone | datetime | YES | Most recent successful phone contact date. From BI_DB_UsageTracking_SF where ActionName = 'Phone_Call_Succeed__c'. (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 85 | FirstContactAttemptDate | datetime | YES | First contact attempt date (any channel). From BI_DB_UsageTracking_SF (MIN). (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 86 | FirstContactAttemptDate_ByPhone | timestamp | YES | [UNVERIFIED] First phone contact attempt date. Not explicitly set in current SP code. (Tier 4 — column name inference) |
| 87 | FirstContactDate | datetime | YES | First successful contact date (any channel). From BI_DB_UsageTracking_SF (MIN). (Tier 2 — SP code, BI_DB_UsageTracking_SF) |
| 88 | FirstContactDate_ByPhone | datetime | YES | [UNVERIFIED] First successful phone contact date. Not explicitly set in current SP code. (Tier 4 — column name inference) |
| 89 | PremiumAccount | int | YES | [UNVERIFIED] Whether customer has a premium account type. Entirely NULL in current data — not populated. (Tier 4 — column name inference) |
| 90 | Evangelist | int | YES | Whether customer is an eToro evangelist/ambassador. 1 = evangelist, NULL = not. Very rare (~208). (Tier 3 — live data) |
| 91 | FirstToThirtyDayRetained | int | YES | [UNVERIFIED] Whether customer was retained between first deposit and day 30. 1 = retained, 0 = not retained, NULL = not yet evaluated. (Tier 4 — column name inference) |
| 92 | FirstWallEngagement | datetime | YES | **DEPRECATED** — First social wall engagement date. ETL section commented out. (Tier 2 — SP code, deprecated) |
| 93 | FeedUnBlocked | tinyint | YES | [UNVERIFIED] Whether the customer's social feed is unblocked. Entirely NULL in current data — not populated by current SP. (Tier 4 — column name inference) |
| 94 | PrivacyPolicyID | tinyint | YES | Privacy policy version accepted by the customer. Values: 1 (~47%), 2 (~53%). From Dim_Customer.PrivacyPolicyID. (Tier 2 — SP code, Dim_Customer) |
| 95 | IP | bigint | YES | Customer's IP address (as numeric). PII. From Dim_Customer.IP. Mostly NULL in recent records. (Tier 2 — SP code, Dim_Customer) |
| 96 | FeedUnlocked | tinyint | YES | Whether the customer has unlocked their social feed. 0 = locked (~15.5%), 1 = unlocked (~0.2%), NULL = not evaluated (~84.3%). (Tier 3 — live data) |
| 97 | Follow5UsersDate | datetime | YES | [UNVERIFIED] Date when the customer followed 5 users (social onboarding milestone). Not populated in current data. (Tier 4 — column name inference) |
| 98 | NumberOfUsersFollowed | int | YES | [UNVERIFIED] Number of users this customer is following on the social feed. Not populated in current data. (Tier 4 — column name inference) |
| 99 | PopularInvestor | int | YES | Whether customer is part of the Popular Investor program. 1 = yes, NULL = no. Very rare (~360). (Tier 3 — live data) |
| 100 | Manager | nvarchar(500) | YES | Account manager's full name (FirstName + LastName). Resolved from Dim_Manager via AccountManagerID. 'System' = no assigned manager. (Tier 2 — SP code, Dim_Manager) |
| 101 | SuitabilityTestCompletedAt | datetime | YES | **DEPRECATED** — Suitability test completion date. Nullified 2022-02-22. 1900-01-01 = sentinel in older records. (Tier 2 — SP code, deprecated) |
| 102 | PassedSuitabilityTest | int | YES | **DEPRECATED** — Whether customer passed the suitability test. Nullified 2022-02-22. All NULL. (Tier 2 — SP code, deprecated) |
| 103 | Model_FTDsOTDs | float | YES | [UNVERIFIED] Machine learning model score predicting FTD (First Time Deposit) / OTD conversion probability. Not populated by current SP. (Tier 4 — column name inference) |
| 104 | Model_Leads | float | YES | [UNVERIFIED] Machine learning model score for lead quality/conversion. Not populated by current SP. (Tier 4 — column name inference) |
| 105 | LastDepositDate | datetime | YES | Most recent deposit date. From Fact_BillingDeposit via #fundingLast (ModificationDate). Updated daily for new deposits. (Tier 2 — SP code, Fact_BillingDeposit) |
| 106 | LastDepositAmount | money | YES | Amount of the most recent deposit in USD. From Fact_BillingDeposit (Amount * ExchangeRate). (Tier 2 — SP code, Fact_BillingDeposit) |
| 107 | LastDepositFundingType | varchar(500) | YES | Funding type of the most recent deposit. Resolved from Dim_FundingType.Name. Values: CreditCard, Wire, PayPal, eToroMoney, etc. (Tier 2 — SP code, Dim_FundingType) |
| 108 | Model_ReDepositor | money | YES | [UNVERIFIED] Machine learning model score predicting re-deposit probability. Not populated by current SP. (Tier 4 — column name inference) |
| 109 | RegulationID | int | YES | Regulatory entity ID. FK to Dim_Regulation.ID. Values: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI (dominant ~80%), 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA. (Tier 2 — SP code, Dim_Regulation) |
| 110 | RiskGroup | varchar(500) | YES | **DEPRECATED** — Customer risk classification. A/B/C. ETL disabled 2023-05-09. Historical values only for ~4.6% of customers. (Tier 2 — SP code, deprecated) |
| 111 | DepositGroup | varchar(500) | YES | **DEPRECATED** — Customer deposit tier. Low/Mid/High. ETL disabled 2023-05-09. Historical values only for ~4.6% of customers. (Tier 2 — SP code, deprecated) |
| 112 | UpdateDate | datetime | YES | Last ETL update timestamp for this row. Set to GETDATE() on every INSERT or UPDATE. Use to verify data freshness. (Tier 2 — SP code) |
| 113 | VerificationLevel1Date | datetime | YES | Date customer first reached Verification Level 1. From Fact_SnapshotCustomer (MIN date where VerificationLevelID=1). May be backfilled from higher levels. (Tier 2 — SP code, Fact_SnapshotCustomer) |
| 114 | VerificationLevel2Date | datetime | YES | Date customer first reached Verification Level 2. From Fact_SnapshotCustomer (MIN date where VerificationLevelID=2). Backfilled from Level 3 if NULL. (Tier 2 — SP code, Fact_SnapshotCustomer) |
| 115 | VerificationLevel3Date | datetime | YES | Date customer first reached Verification Level 3 (fully verified). From Fact_SnapshotCustomer (MIN date where VerificationLevelID=3). (Tier 2 — SP code, Fact_SnapshotCustomer) |
| 116 | EmailVerifiedDate | date | YES | Date customer's email was verified. From Fact_SnapshotCustomer (MIN date where IsEmailVerified=1). (Tier 2 — SP code, Fact_SnapshotCustomer) |
| 117 | FirstInstallDate | datetime | YES | First mobile app install date. From BI_DB_AppFlyer_Reports (EventName='install') via AppsFlyer tracking. (Tier 2 — SP code, BI_DB_AppFlyer_Reports) |
| 118 | EvMatchStatusDate | datetime | YES | Date customer reached EvMatchStatus=2 (Verified) for electronic verification. From Fact_SnapshotCustomer. (Tier 2 — SP code, Fact_SnapshotCustomer) |
| 119 | State | varchar(100) | YES | Customer's state/province. Resolved from Dim_State_and_Province.Name via RegionByIP_ID. Populated for US, Italy, and select countries. (Tier 2 — SP code, Dim_State_and_Province) |
| 120 | PhoneVerifiedDate | datetime | YES | Date customer's phone was verified. From History.BackOfficeCustomer where PhoneVerifiedID IN (1=AutomaticallyVerified, 2=ManuallyVerified). (Tier 2 — SP code, History.BackOfficeCustomer) |
| 121 | KycModeID | int | YES | KYC verification mode. Values: 1 (~48%), 2 (~9%), 3 (~0.3%), 4 (~6%), NULL (~37%). From ComplianceStateDB.Compliance.CustomerKycMode. Joined on GCID. (Tier 2 — SP code, ComplianceStateDB) |
| 122 | PEPCreatedTime | datetime | YES | **DEPRECATED** — PEP (Politically Exposed Person) check creation time. Nullified 2022-02-22. 1900-01-01 = sentinel. (Tier 2 — SP code, deprecated) |
| 123 | PEPStatusUpdatedDate | datetime | YES | **DEPRECATED** — PEP status last update date. Nullified 2022-02-22. (Tier 2 — SP code, deprecated) |
| 124 | isPassedPEP | tinyint | YES | **DEPRECATED** — Whether customer passed PEP screening. Nullified 2022-02-22. All NULL. (Tier 2 — SP code, deprecated) |
| 125 | PEPStatusID | int | YES | **DEPRECATED** — PEP screening status ID. Nullified 2022-02-22. All NULL. (Tier 2 — SP code, deprecated) |
| 126 | EvMatchStatus | int | YES | Electronic verification match status. FK to Dim_EvMatchStatus.EvMatchStatusID. Values: 0=None (~65%), 1=PartiallyVerified (~1.8%), 2=Verified (~16.5%), 3=NotVerified (~5.3%). Updated from Dim_Customer.EvMatchStatus. (Tier 2 — SP code, Dim_EvMatchStatus) |
| 127 | FTDIsLessThanAWeek | int | YES | Whether first deposit occurred within 7 days of registration AND deposit amount > 0. 1 = fast depositor (~8%), 0 = slower or no deposit (~92%). Computed: DATEDIFF(DAY, registered, FirstDepositDate) < 8 AND FirstDepositAmount > 0. (Tier 2 — SP code) |
| 128 | DesignatedRegulationID | int | YES | Designated regulation entity ID. FK to Dim_Regulation.ID. Same value map as RegulationID. May differ from RegulationID when a customer's designated regulation differs from their current operating regulation. Updated from Dim_Customer.DesignatedRegulationID. (Tier 2 — SP code, Dim_Customer) |
| 129 | ProfessionalApplicationDate | date | YES | Date the customer applied for professional (non-retail) classification. From ComplianceStateDB.Compliance.CustomerProfessionalQuestionnaireResult. (Tier 2 — SP code, ComplianceStateDB) |
| 130 | LastCampaignSentDate | datetime | YES | Date of the most recent marketing campaign sent to this customer. (Tier 2 — SP code) |
| 131 | NewMarketingRegion | varchar(100) | YES | Updated marketing region classification. Resolved from Dim_Country.MarketingRegionManualName. Values: SEA, UK, French, Latam, German, CEE, Arabic, USA, Italian, ROW, Nordics, Spain, Australia. (Tier 2 — SP code, Dim_Country) |
| 132 | IsFundedNew | tinyint | YES | Whether customer is currently "funded" — meeting active depositor criteria. 1 = funded (~8%), 0 = not funded (~92%). Determined by Function_Population_Funded. (Tier 2 — SP code, Function_Population_Funded) |
| 133 | FirstNewFundedDate | date | YES | First date the customer became "funded." From Function_Population_First_Time_Funded. Set once, never overwritten. (Tier 2 — SP code, Function_Population_First_Time_Funded) |
| 134 | LastNewFundedDate | date | YES | Most recent date the customer was in "funded" status. From DDR daily status and Function_Population_Funded. Updated daily. (Tier 2 — SP code) |
| 135 | IsAirDropBefore | tinyint | YES | Whether customer received a crypto airdrop in the last 30 days AND has deposited. 1 = received airdrop. From Fact_CustomerAction (ActionTypeID=1, IsAirDrop=1, InstrumentTypeID=5). (Tier 2 — SP code, Fact_CustomerAction) |
| 136 | SignedW8Date | date | YES | [UNVERIFIED] Date the customer signed the W-8BEN tax form (for non-US customers trading US securities). Not populated by current SP (section disabled). (Tier 4 — column name inference) |
| 137 | LastCashoutDate | datetime | YES | Most recent withdrawal/cashout date. From Fact_CustomerAction where ActionTypeID=8 (MAX, rn_desc=1). (Tier 2 — SP code, Fact_CustomerAction) |
| 138 | LastPublishedPostDate | date | YES | Most recent date the customer published a post on the social feed. From Fact_CustomerAction where ActionTypeID=21 (MAX date for current date's actions). (Tier 2 — SP code, Fact_CustomerAction) |
| 139 | LastActionDateForLifeStage | date | YES | Most recent date of a "life stage" action (manual pos open, mirror pos open, mirror registration, or cashout). From Fact_CustomerAction where ActionTypeID IN (1,15,17) (MAX date). Used for customer lifecycle stage classification. (Tier 2 — SP code, Fact_CustomerAction) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Dim_Customer | RealCID | Direct |
| GCID, OriginalCID, Gender, Email, BirthDate, IP | Dim_Customer | Same names | Direct |
| Club | Dim_PlayerLevel | Name (via PlayerLevelID) | Lookup |
| Channel, SubChannel | Dim_Channel | Channel, SubChannel (via Dim_Affiliate.SubChannelID) | Multi-hop lookup |
| Country, Region, PotentialDesk, NewMarketingRegion | Dim_Country | Name, Region, Desk, MarketingRegionManualName | Lookup via CountryID |
| Language, CommunicationLanguage | Dim_Language | Name (via LanguageID, CommunicationLanguageID) | Lookup |
| Blocked | Dim_Customer | PlayerStatusID | CASE WHEN IN (2,4,6,7,8,9) THEN 1 ELSE 0 |
| registered | Dim_Customer | RegisteredDemo, RegisteredReal | MIN(demo, real) |
| Verified | Dim_VerificationLevel | ID (via DWHVerificationLevelID) | Lookup |
| Manager | Dim_Manager | FirstName + LastName (via AccountManagerID) | Concatenation |
| First*/Last* dates | Fact_CustomerAction | Occurred (filtered by ActionTypeID) | MIN/MAX aggregation |
| FirstDeposit* | Fact_BillingDeposit + Dim_FundingType + Dim_BillingDepot | Various | Multi-table join |
| Credit, RealizedEquity | V_Liabilities | Credit, RealizedEquity | Direct (yesterday only) |
| Verification dates | Fact_SnapshotCustomer + Dim_Range | VerificationLevelID with date conversion | MIN aggregation with cascade |
| KycModeID | ComplianceStateDB.CustomerKycMode | KycModeID (via GCID) | Direct |
| EvMatchStatus, DesignatedRegulationID | Dim_Customer | Same names | Direct (differential update) |
| IsFundedNew | Function_Population_Funded | RealCID exists | Boolean |

Full production documentation: see upstream wiki `DB_Schema/etoro/Wiki/` (source configured in dwh-semantic-doc-config.json)

### 5.2 ETL Pipeline

```
Multiple DWH sources -> SP_CIDFirstDates(@date) -> BI_DB_CIDFirstDates -> Generic Pipeline -> UC (pii_data catalog)
```

| Step | Object | Description |
|------|--------|-------------|
| Sources | DWH_dbo.Dim_Customer, Fact_CustomerAction, Fact_BillingDeposit, V_Liabilities, Dim_Mirror, Fact_SnapshotCustomer, and others | Multiple dimension and fact tables from the DWH layer |
| ETL | BI_DB_dbo.SP_CIDFirstDates | Daily SP with @date parameter. INSERT new customers, UPDATE changed attributes, DELETE internal accounts |
| Target | BI_DB_dbo.BI_DB_CIDFirstDates | Final BI-layer milestone table |
| Lake Export | Generic Pipeline (ID: 457) | Daily full override export to Delta lake (SynapseParquet → Delta) |
| UC (PII) | pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates | Full PII version — restricted access |
| UC (Masked) | bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked | PII-masked version — general access |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Primary customer dimension — full profile, current status |
| GCID | ComplianceStateDB.CustomerKycMode | Global customer ID — compliance and KYC data |
| CountryID | DWH_dbo.Dim_Country | Country details, region, regulation mapping, risk group |
| RegulationID | DWH_dbo.Dim_Regulation (ID) | Regulatory entity (CySEC, FCA, ASIC, etc.) |
| DesignatedRegulationID | DWH_dbo.Dim_Regulation (ID) | Designated regulatory entity |
| EvMatchStatus | DWH_dbo.Dim_EvMatchStatus (EvMatchStatusID) | Electronic verification match status name |
| ReferralID | DWH_dbo.Dim_Customer (RealCID) | The referring customer |
| SerialID | DWH_dbo.Dim_Affiliate (AffiliateID) | Affiliate partner |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_CIDFirstDates | N/A | The SP that populates and maintains this table |
| BI_DB_dbo.SP_CIDFirstDates_HistoricalRun | N/A | Historical backfill variant of the SP |
| Various BI_DB views and reports | CID | Used as a customer dimension in BI reporting (DDR, dashboards) |

---

## 7. Sample Queries

### 7.1 Customer lifecycle funnel — registration to first deposit to first trade

```sql
SELECT
    YEAR(registered) AS reg_year,
    COUNT(*) AS total_registered,
    COUNT(CASE WHEN FirstDepositDate IS NOT NULL AND YEAR(FirstDepositDate) != 1900 THEN 1 END) AS deposited,
    COUNT(CASE WHEN FirstPosOpenDate IS NOT NULL THEN 1 END) AS traded,
    CAST(COUNT(CASE WHEN FirstDepositDate IS NOT NULL AND YEAR(FirstDepositDate) != 1900 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS deposit_rate_pct
FROM BI_DB_dbo.BI_DB_CIDFirstDates
WHERE Blocked = 0
GROUP BY YEAR(registered)
ORDER BY reg_year DESC
```

### 7.2 Currently funded customers by regulation with country breakdown

```sql
SELECT
    r.Name AS Regulation,
    fd.Country,
    COUNT(*) AS funded_customers,
    AVG(fd.FirstDepositAmount) AS avg_first_deposit
FROM BI_DB_dbo.BI_DB_CIDFirstDates fd
JOIN DWH_dbo.Dim_Regulation r ON fd.RegulationID = r.ID
WHERE fd.IsFundedNew = 1
  AND fd.Blocked = 0
GROUP BY r.Name, fd.Country
ORDER BY funded_customers DESC
```

### 7.3 Acquisition channel performance — FTD conversion by channel and region

```sql
SELECT
    fd.Channel,
    fd.SubChannel,
    fd.NewMarketingRegion,
    COUNT(*) AS registered,
    COUNT(CASE WHEN fd.FirstDepositDate IS NOT NULL AND YEAR(fd.FirstDepositDate) != 1900 THEN 1 END) AS depositors,
    COUNT(CASE WHEN fd.FTDIsLessThanAWeek = 1 THEN 1 END) AS fast_depositors,
    AVG(CASE WHEN fd.FirstDepositAmount > 0 THEN fd.FirstDepositAmount END) AS avg_ftd_amount
FROM BI_DB_dbo.BI_DB_CIDFirstDates fd
WHERE fd.registered >= '2025-01-01'
  AND fd.Blocked = 0
GROUP BY fd.Channel, fd.SubChannel, fd.NewMarketingRegion
ORDER BY depositors DESC
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | Confirms purpose: "Contains key milestone dates per client, such as registration date, first deposit date, first logged-in, first deposit funding type, etc." CID-level, no date filter needed, updated as of yesterday. |
| [CRM To Dataplatform (ADL) Process](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/12451546445/CRM+To+Dataplatform+ADL+Process) | Confluence | Confirms CIDFirstDates is part of "daily DWH and BI CIDFirstDates processes" — Gold layer table with logic and datatype transformation. |

---

*Generated: 2026-03-15 | Quality: 8.5/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 100 T2, 6 T3, 18 T4 [UNVERIFIED], 0 T5 | Elements: 8.7/10, Logic: 10/10, Relationships: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_CIDFirstDates | Type: Table | Production Source: Multiple (Dim_Customer, Fact_CustomerAction, Fact_BillingDeposit)*
