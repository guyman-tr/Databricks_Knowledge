# BI_DB_dbo.BI_DB_LimitedAccountsWithReasons

> 30,154-row daily snapshot of depositor accounts in non-normal restricted states — capturing customers blocked from deposits, trading, or MIMO, with their current equity, time-since-block, wire cashout status, and Salesforce ticket presence. Refreshed daily via TRUNCATE + INSERT by SP_LimitedAccountsWithReasons (author: Pavlina Masoura, 2024-11-05). Excludes fully blocked (PlayerStatusID=2), blocked upon request (4), and normal (1) accounts; covers CySEC (50%), FCA (23%), FSA Seychelles (10%), and other regulated entities.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_CIDFirstDates + DWH_dbo dimensions (SP_LimitedAccountsWithReasons) |
| **Refresh** | Daily (TRUNCATE + INSERT; SB_Daily, Priority 20) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | ~30,154 (2026-04-13) |
| **Author** | Pavlina Masoura (2024-11-05) |

---

## 1. Business Meaning

`BI_DB_LimitedAccountsWithReasons` is the daily compliance operations snapshot for customers in **limited** account states — neither fully normal (Active) nor permanently blocked. Each row represents one currently-restricted depositor who logged in within the past 12 months, holds positive balance or equity, and is under one of six specific restriction types: Warning (5), Deposit Blocked (10), Trade & MIMO Blocked (9), Copy Block (12), Pending Verification (13), or Block Deposit & Trading (15).

The table drives daily ops monitoring for the Compliance and AM teams: it shows the reason for each restriction (PlayerStatusReason + SubReason), how long the customer has been blocked (TimeBucket), their equity tier (Equity_Level), whether they have a pending wire cashout after the block date, and whether a Salesforce ticket was raised for it.

As of 2026-04-13 there are **30,154 restricted customers**: Block Deposit & Trading accounts dominate (53.5%), followed by Trade & MIMO Blocked (16.4%), Pending Verification (12.3%), Warning (11.4%), and Deposit Blocked (5.4%). The largest share has been blocked for more than 2 months (79.2% in the "Over 2 Months" bucket). CySEC is the largest regulated entity (49.6%), followed by FCA (22.8%).

**Important caveats:**
- Two DDL typos are intentional (stored in column names): `LastLoggeedIn` (extra 'e') and `PlayerStatusReasoon` (extra 'o'). The SP inserts into these exact column names — do NOT rename them in queries without aliasing.
- `Equity` is `Liabilities + ActualNWA` (not Credit). `Balance` is `Credit` (V_Liabilities). These semantics differ from standard equity definitions.
- The commented-out `WHERE DATEADD(MONTH, -6, GETDATE())<=a1.BlockedTime` filter was removed 2024-11-05 — the table now covers all restricted accounts regardless of how long they've been blocked.
- `RiskGroupID` is the **country's** risk group (from Dim_Country), not the customer's personal risk score.

---

## 2. Business Logic

### 2.1 Population Filter — Who Appears in This Table

**What**: Customers who are depositors with positive equity or balance, logged in within 12 months, and in a non-normal, non-blocked restricted state.

**Columns Involved**: `CID`, `PlayerStatusID`, via BI_DB_CIDFirstDates and Dim_Customer

**Rules**:
- IsDepositor=1 AND IsValidCustomer=1 (from Dim_Customer)
- LastLoggedIn >= DATEADD(MONTH, -12, GETDATE())
- Credit > 0 OR (Liabilities + ActualNWA) > 0 (V_Liabilities at @EndDateID = yesterday)
- PlayerStatusID NOT IN (0=N/A, 1=Normal/Active, 2=Blocked, 4=Blocked Upon Request)
- Covered PlayerStatusIDs: 5=Warning, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 12=Copy Block, 13=Pending Verification, 15=Block Deposit & Trading

### 2.2 BlockedTime Calculation

**What**: The most recent date when the customer's PlayerStatusID changed to its current value, derived from SCD history in Fact_SnapshotCustomer.

**Columns Involved**: `BlockedTime`

**Rules**:
- Uses LAG(PlayerStatusID) OVER(PARTITION BY RealCID ORDER BY dr.FromDateID ASC) on Fact_SnapshotCustomer
- Selects rows where PlayerStatusID ≠ Previous_PlayerStatusID (status change events)
- Joins back to Dim_Customer to confirm current PlayerStatusID matches the change event
- BlockedTime = MAX(Change_Date) across all matching change events
- Result: the latest date the customer entered their current restriction state

### 2.3 TimeBucket — Aging Categories

**What**: Bucket showing how long the customer has been in their current restricted state since BlockedTime.

**Columns Involved**: `TimeBucket`

**Rules**:
- Under 24h: DATEDIFF(HOUR, BlockedTime, GETDATE()) <= 24
- Under 48h: DATEDIFF(HOUR, BlockedTime, GETDATE()) <= 48
- 5 days: DATEDIFF(DAY, BlockedTime, GETDATE()) <= 5
- 10 days: DATEDIFF(DAY, BlockedTime, GETDATE()) <= 10
- 15 days: DATEDIFF(DAY, BlockedTime, GETDATE()) <= 15
- 1 month: DATEDIFF(MONTH, BlockedTime, GETDATE()) <= 1
- 2 months: DATEDIFF(MONTH, BlockedTime, GETDATE()) <= 2
- Over 2 Months: all remaining (79.2% of population)

### 2.4 Equity Level Segmentation

**What**: Categorizes the customer's total equity into operational bands for prioritization.

**Columns Involved**: `Equity_Level`, `Equity`

**Rules**:
- A:0-5 — Equity < $5 (low-value, 20.0% of restricted customers)
- B:5-50 — Equity $5–$50 (20.8%)
- C:50-500 — Equity $50–$500 (27.9%)
- D:500+ — Equity ≥ $500 (high-value, 31.3%)
- ISNULL(TotalEquity, 0) used for NULL protection

### 2.5 FinalGrouping — Hierarchical Label

**What**: Human-readable concatenation of status + reason + sub-reason for grouping reports.

**Columns Involved**: `FinalGrouping`, `PlayerStatus`, `PlayerStatusReasoon`, `PlayerStatusSubReason`

**Rules**:
- AML reason → "Status - AML - SubReason" (e.g., "Block Deposit & Trading - AML - AML Trigger")
- Selfie sub-reason → "Status - Reason - SubReason" (e.g., "Deposit Blocked - AML - Selfie")
- All others → "Status - Reason" (e.g., "Warning - Overpayment")
- COLLATE Latin1_General_100_BIN ensures deterministic sort for concatenation

### 2.6 Cashout Detection — Wire Cashouts After Block

**What**: Flags whether the restricted customer has an open wire cashout request submitted AFTER the block date.

**Columns Involved**: `Cashouts`, `CashoutRequestDate`, `CashoutStatus`

**Rules**:
- Source: Fact_BillingWithdraw WHERE FundingTypeID_Withdraw=19 OR FundingTypeID_Funding=19 (wire transfers only)
- HAVING MIN(RequestDate) >= BlockedTime — only cashouts submitted after the block event
- CashoutRequestDate = MIN(RequestDate) of the post-block wire cashout
- CashoutStatus = Dim_CashoutStatus.Name for that cashout
- Cashouts='No' for the large majority (no wire cashout after block, including all 10 sampled rows)

### 2.7 Ticket Detection — Salesforce Cases

**What**: Flags whether a Salesforce case was created after the wire cashout request date.

**Columns Involved**: `Tickets`

**Rules**:
- Source: BI_DB_SF_Cases WHERE CID matches AND CreatedDate >= CashoutRequestDate
- 'Yes' = SF case exists for this customer after cashout request; 'No' = no case
- Only evaluated for customers who have Cashouts='Yes' (#sf temp table is joined only to #CASHOUTS)
- Effectively: Tickets='Yes' only if both Cashouts='Yes' AND SF case exists

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

| Property | Value |
|----------|-------|
| Distribution | ROUND_ROBIN — data scattered across nodes, no distribution key |
| Index | HEAP — no physical ordering; full scans on all queries |
| Advisory | ROUND_ROBIN + HEAP is fast for small tables (30K rows). No special optimization needed — the table is refreshed daily and small enough to scan in milliseconds. JOIN on CID with DWH_dbo.Dim_Customer (HASH-distributed) will trigger data movement. |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Restricted accounts by status today | `SELECT PlayerStatusID, PlayerStatus, COUNT(*) FROM BI_DB_LimitedAccountsWithReasons GROUP BY PlayerStatusID, PlayerStatus` |
| Long-blocked high-equity accounts | `WHERE TimeBucket='Over 2 Months' AND Equity_Level='D:500+' ORDER BY Equity DESC` |
| Wire cashout pending (compliance priority) | `WHERE Cashouts='Yes' AND Tickets='No'` — cashout with no SF case = needs attention |
| AML cases by regulation | `WHERE PlayerStatusReasoon='AML' GROUP BY Regulation ORDER BY COUNT(*) DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON dc.RealCID = a.CID | Enrich with customer details |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON f.CID = a.CID | FTD date, acquisition context |

### 3.4 Gotchas

- **Typos in column names**: `LastLoggeedIn` (extra 'e') and `PlayerStatusReasoon` (extra 'o') are the actual DDL column names — SQL queries must use these exact spellings.
- **Equity ≠ standard equity**: `Equity` = `Liabilities + ActualNWA`; `Balance` = `Credit` (available cash). Not interchangeable.
- **RiskGroupID is country risk**: This is Dim_Country.RiskGroupID, not a customer-level risk score. It reflects the country's regulatory risk tier (0=None, 3=FATF, etc.).
- **BlockedTime may be NULL**: If a customer's restriction predates the Fact_SnapshotCustomer history, BlockedTime will be NULL and TimeBucket will not have a value.
- **Cashouts='No' does not mean no cashouts ever**: It means no wire cashout (FundingTypeID=19) submitted AFTER the BlockedTime. Other cashout types and pre-block cashouts are excluded.
- **TimeBucket 'Under 24h' rare but present**: Only 25 rows in this bucket on any given day (0.08%); these are fresh blocks not yet resolved.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from production database upstream wiki — highest confidence |
| Tier 2 | Derived from SP code analysis, DWH dimension JOINs, or staging table structure |
| Tier 3 | Inferred from column name, context, or business domain knowledge |
| Tier 4 | Best available — limited or no direct evidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | LastLoggeedIn | datetime | YES | Last platform login date. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID=14, sourced from BI_DB_CIDFirstDates. **DDL typo**: extra 'e' ('ee') — use this exact spelling in queries. Passthrough from BI_DB_CIDFirstDates. (Tier 2 — SP_CIDFirstDates) |
| 3 | Regulation | varchar(30) | YES | Regulatory entity name for this customer. Loaded via Dim_Regulation.Name joined on Dim_Customer.RegulationID. Values: CySEC, FCA, FSA Seychelles, FinCEN+FINRA, FSRA, ASIC & GAML, ASIC, MAS, BVI, FinCEN. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 4 | Balance | money | YES | Available cash balance (Credit). Sourced from DWH_dbo.V_Liabilities.Credit at @EndDateID (yesterday's date). This is NOT total equity — it is the customer's credit/cash amount only. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 5 | Equity | money | YES | Total equity = Liabilities + ActualNWA from V_Liabilities at @EndDateID. This is the full position-inclusive equity, not cash. Note naming inversion: 'Balance' = cash (Credit), 'Equity' = total equity (Liabilities+ActualNWA). (Tier 2 — SP_LimitedAccountsWithReasons) |
| 6 | PlayerStatusID | int | YES | Compliance and trading account status. FK to Dictionary.PlayerStatus. 1=Normal (97.5% of accounts); other values indicate restricted, closed, banned, or special states. Default=0. This table contains only restricted values: 5=Warning, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 12=Copy Block, 13=Pending Verification, 15=Block Deposit & Trading. (Tier 1 — Customer.CustomerStatic) |
| 7 | PlayerStatus | varchar(max) | YES | Text label for PlayerStatusID. Loaded via Dim_PlayerStatus.Name. Trailing spaces present in source (e.g., "Warning" has trailing whitespace). Values: Block Deposit & Trading, Trade & MIMO Blocked, Pending Verification, Warning, Deposit Blocked, Copy Block. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 8 | PlayerStatusReasoon | varchar(max) | YES | Reason behind the player status restriction. Loaded via Dim_PlayerStatusReasons.Name. **DDL typo**: extra 'o' ('oo') — use this exact spelling in queries. Values observed: AML, KYC, Overpayment, Screening - Possible Match, Selfie, etc. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 9 | PlayerStatusSubReason | varchar(max) | YES | Sub-reason providing more granular detail on the restriction. Loaded via Dim_PlayerStatusSubReasons.PlayerStatusSubReasonName via Dim_Customer.PlayerStatusSubReasonID. NULL when no sub-reason applies. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 10 | TimeBucket | varchar(30) | YES | Aging bucket: time elapsed since BlockedTime. Computed via DATEDIFF. Values: Under 24h, Under 48h, 5 days, 10 days, 15 days, 1 month, 2 months, Over 2 Months (majority of restricted accounts). NULL if BlockedTime is NULL. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 11 | PendingClosureStatus | varchar(max) | YES | Account closure workflow status. Loaded via Dim_PendingClosureStatus.PendingClosureStatusName joined on Dim_Customer.PendingClosureStatusID. 'No' when PendingClosureStatusID is NULL (majority). Values: No, Approved for Closure (and potentially others). (Tier 2 — SP_LimitedAccountsWithReasons) |
| 12 | BlockedTime | datetime | YES | Most recent date the customer's PlayerStatusID changed to its current restricted value. Derived from Fact_SnapshotCustomer + Dim_Range using LAG(PlayerStatusID) window function: MAX(FromDateID) where status changed. NULL if restriction predates SCD history. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 13 | Equity_Level | varchar(max) | YES | Portfolio size tier based on Equity (Liabilities+ActualNWA). A:0-5 = <$5, B:5-50 = $5–$50, C:50-500 = $50–$500, D:500+ = ≥$500. Computed via CASE WHEN with ISNULL protection. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 14 | Cashouts | varchar(30) | YES | Flag: 'Yes' if a wire cashout (FundingTypeID=19) was submitted after BlockedTime, 'No' otherwise. Sourced from Fact_BillingWithdraw HAVING MIN(RequestDate) >= BlockedTime. Majority are 'No'. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 15 | CashoutRequestDate | datetime | YES | Earliest wire cashout RequestDate after BlockedTime. NULL when Cashouts='No'. From Fact_BillingWithdraw.RequestDate (FundingTypeID=19). (Tier 2 — SP_LimitedAccountsWithReasons) |
| 16 | CashoutStatus | varchar(max) | YES | Status of the post-block wire cashout. Loaded via Dim_CashoutStatus.Name on CashoutStatusID_Withdraw. NULL when Cashouts='No'. Values: Pending, Approved, Rejected, etc. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 17 | Tickets | varchar(30) | YES | Flag: 'Yes' if a Salesforce case in BI_DB_SF_Cases was created with CreatedDate >= CashoutRequestDate, 'No' otherwise. Only 'Yes' possible when Cashouts='Yes'. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 18 | RiskGroupID | int | YES | Granular country risk classification. 0=None, 1=High risk country, 2=High risk for new clients, 3=High risk FATF country, 4=Verified before deposit. More nuanced than binary IsHighRiskCountry. IsHighRiskCountry is derived from this column. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 19 | FinalGrouping | varchar(max) | YES | Hierarchical restriction label combining status, reason, and sub-reason. Format: AML → "Status - AML - SubReason"; Selfie → "Status - Reason - SubReason"; others → "Status - Reason". Used for grouping in compliance dashboards. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 20 | Region | varchar(50) | YES | Marketing region label for the customer's registered country. Loaded from Dim_Country.Region (= etoro.Dictionary.MarketingRegion.Name). NOT the geographic region. 22 distinct values (e.g., "Eastern Europe", "UK", "ROW", "South & Central America"). (Tier 2 — SP_Dictionaries_Country_DL_To_Synapse) |
| 21 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name. (Tier 1 — Dictionary.Country) |
| 22 | AccountType | varchar(50) | YES | Customer account classification name. Loaded via Dim_AccountType.Name on Dim_Customer.AccountTypeID. Typical values: Private, Corporate. (Tier 2 — SP_LimitedAccountsWithReasons) |
| 23 | UpdateDate | datetime | YES | ETL run timestamp (GETDATE() at load time). All rows share the same timestamp within a daily run. Used to verify data freshness. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Table | Source Column | Transform |
|--------|-------------|---------------|-----------|
| CID | BI_DB_CIDFirstDates | CID | passthrough |
| LastLoggeedIn | BI_DB_CIDFirstDates | LastLoggedIn | rename (typo) |
| Regulation | Dim_Regulation | Name | lookup |
| Balance | V_Liabilities | Credit | passthrough |
| Equity | V_Liabilities | Liabilities + ActualNWA | SUM |
| PlayerStatusID | Dim_Customer | PlayerStatusID | passthrough |
| PlayerStatus | Dim_PlayerStatus | Name | lookup |
| PlayerStatusReasoon | Dim_PlayerStatusReasons | Name | lookup (typo in col) |
| PlayerStatusSubReason | Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | lookup |
| TimeBucket | — | BlockedTime | CASE DATEDIFF aging |
| PendingClosureStatus | Dim_PendingClosureStatus | PendingClosureStatusName | lookup + ISNULL='No' |
| BlockedTime | Fact_SnapshotCustomer + Dim_Range | FromDateID | LAG MAX |
| Equity_Level | — | Equity | CASE tier |
| Cashouts | Fact_BillingWithdraw | CID | 'Yes'/'No' flag |
| CashoutRequestDate | Fact_BillingWithdraw | RequestDate | MIN post-block |
| CashoutStatus | Dim_CashoutStatus | Name | lookup |
| Tickets | BI_DB_SF_Cases | CID | 'Yes'/'No' flag |
| RiskGroupID | Dim_Country | RiskGroupID | passthrough |
| FinalGrouping | — | PlayerStatus + Reason + SubReason | concat |
| Region | Dim_Country | Region | passthrough |
| Country | Dim_Country | Name | rename |
| AccountType | Dim_AccountType | Name | lookup |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Customer.CustomerStatic (production)
etoro.Dictionary.Country (production)
  |-- Generic Pipeline (Bronze export) --|
  v
DWH_dbo.Dim_Customer  (player status, regulation, account type)
DWH_dbo.Dim_Country   (country name, region, risk group)
DWH_dbo.V_Liabilities (balance, equity at @EndDateID)
DWH_dbo.Fact_SnapshotCustomer + Dim_Range  (block time history)
DWH_dbo.Fact_BillingWithdraw + Dim_CashoutStatus (wire cashouts)
BI_DB_dbo.BI_DB_CIDFirstDates (depositor filter, last login)
BI_DB_dbo.BI_DB_SF_Cases (Salesforce tickets)
  |-- SP_LimitedAccountsWithReasons (TRUNCATE + INSERT daily) --|
  v
BI_DB_dbo.BI_DB_LimitedAccountsWithReasons (~30K rows)
  |-- V_BI_DB_LimitedAccountsWithReasons_COPY_BI_DB (passthrough view) --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | BI_DB_dbo.BI_DB_CIDFirstDates | Base population — depositors filtered by last login, valid status, positive equity |
| PlayerStatusID | DWH_dbo.Dim_Customer | Player status and account attributes |
| RiskGroupID | DWH_dbo.Dim_Country | Country-level risk classification |
| BlockedTime | DWH_dbo.Fact_SnapshotCustomer | SCD history for restriction date derivation |
| Balance, Equity | DWH_dbo.V_Liabilities | Yesterday's financial position |
| CashoutRequestDate | DWH_dbo.Fact_BillingWithdraw | Wire cashout history |
| Tickets | BI_DB_dbo.BI_DB_SF_Cases | Salesforce case tracking |

### 6.2 Referenced By

| Object | Reference Type | Description |
|--------|---------------|-------------|
| BI_DB_dbo.V_BI_DB_LimitedAccountsWithReasons_COPY_BI_DB | View (SELECT *) | Passthrough view exposing all columns for cross-database access |

---

## 7. Sample Queries

### Restricted accounts by PlayerStatus today

```sql
SELECT
    PlayerStatusID,
    PlayerStatus,
    COUNT(*) AS CustomerCount,
    SUM(CASE WHEN Cashouts = 'Yes' THEN 1 ELSE 0 END) AS WithPendingCashout
FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasons]
GROUP BY PlayerStatusID, PlayerStatus
ORDER BY CustomerCount DESC;
```

### High-equity AML-blocked accounts needing attention (no SF ticket yet)

```sql
SELECT
    CID,
    Country,
    Regulation,
    Equity,
    Equity_Level,
    BlockedTime,
    TimeBucket,
    PlayerStatusReasoon,
    PlayerStatusSubReason,
    CashoutRequestDate,
    CashoutStatus
FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasons]
WHERE PlayerStatusReasoon = 'AML'
  AND Equity_Level = 'D: 500+'
  AND Cashouts = 'Yes'
  AND Tickets = 'No'
ORDER BY Equity DESC;
```

### Aging distribution by regulation

```sql
SELECT
    Regulation,
    TimeBucket,
    COUNT(*) AS CustomerCount
FROM [BI_DB_dbo].[BI_DB_LimitedAccountsWithReasons]
GROUP BY Regulation, TimeBucket
ORDER BY Regulation, CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources retrieved. SP header (Pavlina Masoura, 2024-11-05) and change history (removed 6-month filter) provide primary documentation context.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 13/14 (P10 Atlassian skipped)*
*Tiers: 4 T1, 18 T2, 0 T3, 0 T4, 1 T5 | Elements: 23/23 | Logic: 9/10 | ETL: Full trace*
*Object: BI_DB_dbo.BI_DB_LimitedAccountsWithReasons | Type: Table | Production Source: BI_DB_CIDFirstDates + DWH dimensions*
