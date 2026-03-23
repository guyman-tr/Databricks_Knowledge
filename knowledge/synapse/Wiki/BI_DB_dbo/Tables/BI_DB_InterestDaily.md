# BI_DB_dbo.BI_DB_InterestDaily

> Daily per-customer interest accrual record from the eToro Club "Interest on Balance" programme — stores the computed daily interest amount, eligible funds, applicable rates, and customer context for each interest-eligible customer per day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact — daily snapshot) |
| **Production Source** | Interest DB: `interest-west.database.windows.net` → `Interest.Trade.InterestDaily` |
| **Refresh** | Daily — DELETE for @date + INSERT via external table (SP_InterestDaily @date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`BI_DB_InterestDaily` captures the daily interest accrual for each customer enrolled in the **eToro Club "Interest on Balance"** programme. The eToro Club offers tiered interest rates on customer balances — the higher the club tier (Bronze → Silver → Gold → Platinum → Platinum+ → Diamond), the higher the annual interest rate.

The daily interest payment is calculated once per day at a specific time. The eligible balance (`FundsForInterest`) is computed as the customer's available cash minus pending cashout requests, credit adjustments, and bonus amounts. The interest rate is determined by the customer's `PlayerLevelID` (club tier) at the time of calculation.

Key business context (from Confluence "Interest on Balance"):
- Interest is calculated daily but **paid monthly** (accumulated daily amounts are summed)
- Rate is determined by customer's club tier at the time of daily calculation
- Clients who upgrade their club tier mid-month receive the higher rate from the day of upgrade
- The Interest DB is an external Azure SQL database (`interest-west.database.windows.net`) — data is pulled daily via Synapse elastic query external table

This table is consumed by multiple regulatory reporting SPs (CMR Automation for EU, FSA, US, FSRA, ASIC) and the Monthly Interest Payment Dashboard.

Created: 2024-04-01 by Artyom Bogomolsky.

---

## 2. Business Logic

### 2.1 Daily Interest Calculation

**What**: Each row represents one customer's interest accrual for one day.

**Columns Involved**: `DailyInterest`, `FundsForInterest`, `DailyInterestPercentage`, `YearlyInterestPercentage`

**Rules**:
- `YearlyInterestPercentage` is determined by the customer's `PlayerLevelID` (club tier) at calculation time
- `DailyInterestPercentage` = `YearlyInterestPercentage` / 365 (approximately)
- `DailyInterest` = `FundsForInterest` × `DailyInterestPercentage`
- `FundsForInterest` represents the eligible balance for interest (computed in the Interest service)

### 2.2 Customer Context Snapshot

**What**: Customer attributes captured at the time of interest calculation.

**Columns Involved**: `CountryID`, `PlayerLevelID`, `AccountTypeID`, `RegulationID`, `StatusID`

**Rules**:
- These are snapshot values — they reflect the customer's state at the time of the daily interest calculation, not the current state
- `PlayerLevelID` determines the interest rate tier (from `DWH_dbo.Dim_PlayerLevel`)

### 2.3 Balance Components

**What**: The financial components used to determine eligible funds.

**Columns Involved**: `MinRealMoney`, `SumOfPendingCashoutRequests`, `Credit`, `RealizedEquity`, `Bonus`

**Rules**:
- These represent the customer's financial snapshot at calculation time
- `FundsForInterest` is derived from these components (exact formula is in the Interest service)
- `MinRealMoney` appears to be a minimum real money threshold for eligibility
- `SumOfPendingCashoutRequests` reduces the eligible balance

### 2.4 Tax

**What**: Monthly tax rate applied to interest payments.

**Columns Involved**: `MonthlyTaxPercentage`

**Rules**:
- Tax rate varies by regulation/jurisdiction
- Applied to the monthly accumulated interest at payment time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: No single distribution key — the table is accessed primarily by date-range scans. Not co-located with customer tables.

**CLUSTERED INDEX (DateID ASC)**: Efficient for date-range queries. Always filter on DateID.

### 3.1b UC (Databricks) Storage & Partitioning

_Pending — resolved during write-objects._

### 3.2 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID | Customer details, real CID resolution |
| DWH_dbo.Dim_PlayerLevel | ON PlayerLevelID | Club tier name (Bronze, Silver, Gold, etc.) |
| DWH_dbo.Dim_Country | ON CountryID | Country name |
| DWH_dbo.Dim_Regulation | ON RegulationID | Regulation name |
| DWH_dbo.Dim_Date | ON DateID | Calendar attributes |

### 3.3 Gotchas

- **External source**: Data comes from the Interest microservice DB, not the main eToro production DB. Schema changes in the Interest DB may affect this table without DWH team awareness.
- **One row per CID per day**: Each customer who is interest-eligible gets one row per DayOfInterest.
- **Monthly payment vs daily accrual**: This table stores daily accruals. Monthly payments are accumulated from these daily rows by consumer SPs.
- **ROUND_ROBIN distribution**: JOINs to customer-dimension tables will trigger data movement (broadcast/shuffle). For large joins, consider filtering on DateID first.
- **Regulatory reporting dependency**: Multiple CMR Automation SPs depend on this table for client interest reports across jurisdictions.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — Synapse SP code | (Tier 2 — SP_InterestDaily) |
| ★ | Tier 4 — Inferred | (Tier 4 — [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NULL | Customer ID. Passthrough from Interest.Trade.InterestDaily. (Tier 2 — SP_InterestDaily) |
| 2 | DailyInterest | numeric(15,6) | NULL | Computed daily interest amount in USD for the customer. FundsForInterest × DailyInterestPercentage. (Tier 2 — SP_InterestDaily) |
| 3 | FundsForInterest | money | NULL | Eligible balance for interest calculation — cash available after deducting pending cashouts, credit adjustments, and bonus. (Tier 2 — SP_InterestDaily) |
| 4 | DailyInterestPercentage | numeric(15,6) | NULL | Daily interest rate applied (≈ YearlyInterestPercentage / 365). (Tier 2 — SP_InterestDaily) |
| 5 | DayOfInterest | date | NULL | The calendar date for which interest was calculated. (Tier 2 — SP_InterestDaily) |
| 6 | DateID | int | NULL | YYYYMMDD integer from DayOfInterest. Clustered index key — always filter on this. ETL-computed: CONVERT(VARCHAR, DayOfInterest, 112). (Tier 2 — SP_InterestDaily) |
| 7 | CountryID | int | NULL | Customer's country at the time of interest calculation. FK to Dim_Country. (Tier 2 — SP_InterestDaily) |
| 8 | PlayerLevelID | int | NULL | eToro Club tier at calculation time (Bronze=1, Silver=2, Gold=3, Platinum=4, etc.). Determines the interest rate. FK to Dim_PlayerLevel. (Tier 4 — [UNVERIFIED]) |
| 9 | AccountTypeID | int | NULL | Account type at calculation time. FK to Dim_AccountType. (Tier 2 — SP_InterestDaily) |
| 10 | RegulationID | int | NULL | Regulatory jurisdiction at calculation time (EU, FSA, ASIC, US, FSRA). FK to Dim_Regulation. (Tier 2 — SP_InterestDaily) |
| 11 | Interest | money | NULL | Accumulated interest amount. Meaning requires clarification — may be month-to-date running total or total accrued. (Tier 4 — [UNVERIFIED]) |
| 12 | MinRealMoney | money | NULL | Minimum real money balance threshold for interest eligibility. (Tier 4 — [UNVERIFIED]) |
| 13 | SumOfPendingCashoutRequests | money | NULL | Total pending cashout/withdrawal requests at calculation time. Reduces eligible funds for interest. (Tier 2 — SP_InterestDaily) |
| 14 | Credit | money | NULL | Credit balance on the account at calculation time. (Tier 2 — SP_InterestDaily) |
| 15 | RealizedEquity | money | NULL | Realized equity at calculation time. The base value from which eligible funds are derived. (Tier 2 — SP_InterestDaily) |
| 16 | Bonus | money | NULL | Bonus amount on the account at calculation time. Excluded from interest-eligible balance. (Tier 2 — SP_InterestDaily) |
| 17 | YearlyInterestPercentage | numeric(5,2) | NULL | Annual interest rate percentage for the customer's club tier. Determines DailyInterestPercentage. (Tier 2 — SP_InterestDaily) |
| 18 | StatusID | tinyint | NULL | Customer status at calculation time. FK to status dimension. (Tier 4 — [UNVERIFIED]) |
| 19 | MonthlyTaxPercentage | numeric(5,2) | NULL | Tax rate applied to the monthly interest payment. Varies by regulation/jurisdiction. (Tier 4 — [UNVERIFIED]) |
| 20 | UpdateDate | datetime | NULL | ETL load timestamp — GETDATE(). (Tier 2 — SP_InterestDaily) |

---

## 5. Lineage

### 5.1 Pipeline

```
Interest DB (interest-west.database.windows.net)
  → Interest.Trade.InterestDaily
    │
    └─ SP_InterestDaily(@date)
        ├─ EXEC SP_Create_External_Interest_Trade_InterestDaily @date, 'Daily_Data'
        │   (creates external table via elastic query)
        ├─ DELETE WHERE DayOfInterest = @date
        └─ INSERT (all columns passthrough + DateID computed + UpdateDate = GETDATE())
```

### 5.2 Key Source Tables

| Source | Columns Used |
|--------|-------------|
| Interest.Trade.InterestDaily (external) | All 18 business columns (CID through MonthlyTaxPercentage) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Customer | CID | Customer details |
| DWH_dbo.Dim_PlayerLevel | PlayerLevelID | Club tier name |
| DWH_dbo.Dim_Country | CountryID | Country |
| DWH_dbo.Dim_Regulation | RegulationID | Regulatory jurisdiction |
| DWH_dbo.Dim_Date | DateID | Calendar date |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_Monthly_InterestPayment_Dashboard | DateID, CID | Monthly payment dashboard |
| SP_CMR_Automation_EU_ClientInterestReport | DateID, RegulationID | EU regulatory interest report |
| SP_CMR_Automation_FSA_ClientInterestReport | DateID, RegulationID | FSA regulatory interest report |
| SP_CMR_Automation_US_ClientInterestReport | DateID, RegulationID | US regulatory interest report |
| SP_CMR_Automation_FSRA_ClientInterestReport | DateID, RegulationID | FSRA regulatory interest report |
| SP_CMR_Automation_ASIC_ASICG_ClientInterestReport | DateID, RegulationID | ASIC regulatory interest report |
| SP_CID_DailyPanel_Club | DateID, CID | CID daily panel with club-level metrics |

---

## 7. Sample Queries

### 7.1 Daily interest by club tier

```sql
SELECT  pl.PlayerLevelName,
        COUNT(DISTINCT i.CID) AS Customers,
        SUM(i.DailyInterest) AS TotalDailyInterest,
        AVG(i.YearlyInterestPercentage) AS AvgYearlyRate
FROM    [BI_DB_dbo].[BI_DB_InterestDaily] i
JOIN    DWH_dbo.Dim_PlayerLevel pl ON i.PlayerLevelID = pl.PlayerLevelID
WHERE   i.DateID = 20260320
GROUP BY pl.PlayerLevelName
ORDER BY TotalDailyInterest DESC;
```

### 7.2 Monthly interest accrual for a customer

```sql
SELECT  CID,
        SUM(DailyInterest) AS MonthlyInterest,
        AVG(FundsForInterest) AS AvgEligibleBalance,
        MIN(DayOfInterest) AS PeriodStart,
        MAX(DayOfInterest) AS PeriodEnd
FROM    [BI_DB_dbo].[BI_DB_InterestDaily]
WHERE   DateID BETWEEN 20260301 AND 20260331
  AND   CID = 12345678
GROUP BY CID;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Interest on balance](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12000395552) | Confluence | Business rules — daily calculation timing, club tier-based rates, monthly payment |
| [Interest on Balance (detailed)](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11998659473) | Confluence | Interest formula, Club Dashboard display logic |
| [How to connect to Interest DB PROD](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11996102671) | Confluence | Source DB connection details (interest-west.database.windows.net) |
| [Payments in Non-USD — Interest](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14039384103) | Confluence | Multi-currency interest architecture, trading-interest-service details |
| [eToro Club Tiers / Levels](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12191989805) | Confluence | Club tier definitions and eligibility thresholds |

---

*Generated: 2026-03-22 | Quality: 8.0/10 (★★★★☆) | Phases: 12/14 (P2,P3 skipped — Synapse MCP unavailable)*
*Tiers: 0 T1, 15 T2, 0 T3, 5 T4 [UNVERIFIED] (PlayerLevelID values, Interest meaning, MinRealMoney, StatusID, MonthlyTaxPercentage), 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_InterestDaily | Type: Table | Source: Interest.Trade.InterestDaily (interest-west.database.windows.net)*
