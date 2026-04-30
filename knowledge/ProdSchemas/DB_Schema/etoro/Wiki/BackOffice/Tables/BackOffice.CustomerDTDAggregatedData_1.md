# BackOffice.CustomerDTDAggregatedData_1

> Daily financial aggregates per customer per day (Day-To-Date), recording each customer's financial activity broken down by calendar day. Companion table to BackOffice.CustomerAllTimeAggregatedData_1 (lifetime totals) and BackOffice.CustomerMTDAggregatedData_1 (monthly totals).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID, Date) - composite CLUSTERED PK |
| **Partition** | No (stored ON [HISTORY] filegroup with DATA_COMPRESSION=PAGE) |
| **Indexes** | 2 active (1 clustered composite PK + 1 NC on CID) |

---

## 1. Business Meaning

BackOffice.CustomerDTDAggregatedData_1 stores one row per customer per active day - a day being any day on which the customer had financial activity (deposits, trades, bonuses, cashouts, etc.). Together with the AllTime (lifetime) and MTD (monthly) tables, it forms the three-tier aggregation system that powers all BackOffice financial reporting.

The DTD granularity enables day-by-day analysis: how much did a customer deposit on a given day, how many positions did they close, what was their daily trading volume. This feeds daily profitability analysis, deposit velocity risk checks (how much has the customer deposited in the last N days), and trend-based visualizations in the BackOffice UI.

**Naming**: "DTD" = Day-To-Date. The "_1" suffix mirrors BackOffice.CustomerAllTimeAggregatedData_1: the original table was renamed and a view (BackOffice.CustomerDTDAggregatedData) was created on top. All new writes target the _1 table.

9.857M rows as of 2026-03-17 covering 6.736M unique customers across 1,640 unique dates (2013-01-02 to present). Average 1.46 daily rows per customer - the distribution is heavily right-skewed (most customers active on 1-2 days, power users active on hundreds of days).

---

## 2. Business Logic

### 2.1 Single Writer - Same Upsert Pipeline as AllTime

**What**: All daily totals are maintained via the same near-real-time upsert procedure that maintains the AllTime table, processing the same credit event batch.

**Columns Involved**: All `Total*` columns, `Date`, `LastRealizedEquity`

**Rules**:
- `UpsertIntoAggregationTablesAction` is the sole writer. In the same execution that upserts into CustomerAllTimeAggregatedData_1, it also upserts into this table.
- The procedure aggregates credit events by (CID, Date) - where Date = DATEADD(dd,0,DATEDIFF(dd,0,Occurred)), i.e. the calendar day of the event (midnight, UTC).
- Same CreditTypeID -> column mapping as AllTime (see BackOffice.CustomerAllTimeAggregatedData_1 Section 2.1):
  - CreditTypeID=1: TotalDeposit
  - CreditTypeID=2: TotalCashout
  - CreditTypeID=3,13: TotalInvestment
  - CreditTypeID=4: TotalProfit, TotalPositionCount, TotalVolume, TotalLot
  - CreditTypeID=5: TotalChampWin
  - CreditTypeID=6: TotalCompensation
  - CreditTypeID=7: TotalBonus
  - CreditTypeID=8,15 positive: TotalReverseCashout
  - CreditTypeID=9,15 negative: TotalCashoutRequest
  - CreditTypeID=14: TotalEndOfWeekFee
- UPDATE for existing (CID, Date) rows, INSERT for new (CID, Date) combinations.
- Login activity: TotalLoginCount and TotalLoggedTime also updated per day from STS login audit.
- `LastRealizedEquity`: MAX realized equity from Customer.CustomerMoney for that customer in the batch (sourced at upsert time, same logic as AllTime).

**Diagram**:
```
History.ActiveCredit (new CreditIDs since last run)
    |
    v
UpsertIntoAggregationTablesAction
    |-- Group by (CID, Date=calendar day of Occurred)
    |-- Compute deltas per day
    |
    v
UPSERT BackOffice.CustomerDTDAggregatedData_1 (one row per CID per day)
```

### 2.2 Relationship to AllTime and MTD

**What**: The three aggregation tables serve the same data at different temporal resolutions.

**Rules**:
- AllTime (CustomerAllTimeAggregatedData_1): Lifetime total per CID. One row per customer.
- DTD (CustomerDTDAggregatedData_1): Per-day total per CID. One row per customer per active day.
- MTD (CustomerMTDAggregatedData_1): Per-month total per CID. One row per customer per active month.
- All three are updated in the same atomic transaction by UpsertIntoAggregationTablesAction.
- A SUM of all DTD rows for a CID = the AllTime row for that CID (within rounding).
- A SUM of all DTD rows for a CID within a month = the MTD row for that CID/month.
- Use DTD when: day-level granularity needed, trend analysis, per-day deposit limits.
- Use MTD when: monthly reporting, monthly bonus calculations.
- Use AllTime when: lifetime customer value, customer header display, SF CRM sync.

---

## 3. Data Overview

| CID | Date | TotalDeposit | TotalProfit | Pattern |
|-----|------|-------------|-------------|---------|
| (any) | 2013-01-02 | varies | varies | Earliest daily data (2013 backfill) |
| (any) | 2026-03-17 | varies | varies | Most recent day (today) |
| (high-activity CID) | multiple dates | per-day amounts | per-day P&L | Power users have hundreds of rows |
| (single-event CID) | 1 date | deposit amount | 0 | Most customers have 1-2 daily rows |

Scale (2026-03-17):
- 9.857M rows total
- 6.736M unique CIDs (one or more rows each)
- 1,640 unique dates spanning 2013-01-02 to 2026-03-17
- Average 1.46 daily rows per customer (heavily right-skewed)
- Average daily deposit amount (when > 0): ~$26,597

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Part of composite PK. Implicit FK to Customer.CustomerStatic.CID. |
| 2 | Date | datetime | NO | - | VERIFIED | Calendar day of the financial activity (midnight UTC). Part of composite PK. Stored as datetime but always at midnight (time = 00:00:00). Range: 2013-01-02 to present. |
| 3 | TotalProfit | decimal(34,4) | NO | 0 | VERIFIED | Net realized profit from closed positions on this day (CreditTypeID=4 events). |
| 4 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | Total deposit amount on this day (CreditTypeID=1). |
| 5 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | Total bonus credits received on this day (CreditTypeID=7). |
| 6 | TotalInvestment | decimal(34,4) | NO | 0 | VERIFIED | Total funds locked into positions on this day (CreditTypeID=3,13). |
| 7 | TotalCommission | decimal(34,4) | NO | 0 | VERIFIED | Total commissions charged on closed positions on this day. |
| 8 | TotalVolume | decimal(34,6) | YES | 0 | VERIFIED | Total trading volume in units on this day. Nullable for legacy/pre-volume-tracking rows. |
| 9 | TotalLot | decimal(34,6) | YES | 0 | VERIFIED | Total lots traded on this day. Nullable for legacy rows. |
| 10 | TotalChampWin | decimal(34,4) | NO | 0 | VERIFIED | Championship prize payouts received on this day (CreditTypeID=5). |
| 11 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | Total successful withdrawal payments on this day (CreditTypeID=2). |
| 12 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | Total withdrawal requests submitted on this day (CreditTypeID=9,15 negative). |
| 13 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | Total reversed withdrawals on this day (CreditTypeID=8,15 positive). |
| 14 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | Total compensation payments received on this day (CreditTypeID=6). |
| 15 | TotalGameCount | bigint | NO | 0 | CODE-BACKED | Game/contest count for this day. Always 0 in current code (game tracking inactive). |
| 16 | TotalPositionCount | bigint | NO | 0 | VERIFIED | Number of positions closed on this day (CreditTypeID=4 events). |
| 17 | TotalLoginCount | bigint | NO | 0 | VERIFIED | Number of logins on this day. From STS login audit. |
| 18 | TotalLoggedTime | bigint | YES | 0 | CODE-BACKED | Total seconds logged in on this day. Nullable; 0 where not tracked. |
| 19 | TotalEndOfWeekFee | decimal(34,4) | NO | 0 | VERIFIED | End-of-week fees charged on this day (CreditTypeID=14). |
| 20 | LastRealizedEquity | decimal(15,2) | YES | - | VERIFIED | Customer's realized equity as of the most recent upsert for this day. Sourced from Customer.CustomerMoney.RealizedEquity at upsert time. NULL if no realized equity data captured. Note: this is a snapshot of realized equity from the upsert run, not an end-of-day balance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Account scope |
| CID (at upsert time) | Customer.CustomerMoney | Implicit | LastRealizedEquity source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerDTDAggregatedData | (CID, Date) | VIEW WRAPPER | View wrapping this table for backward compatibility |
| BackOffice.UpsertIntoAggregationTablesAction | (CID, Date) | WRITER/MODIFIER | Sole data population mechanism |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDTDAggregatedData_1 (table)
- No FK constraints (leaf table)
- Written by same pipeline as BackOffice.CustomerAllTimeAggregatedData_1
- See that table's dependency chain for full source lineage
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | CID scope via upsert pipeline |
| Customer.CustomerMoney | Table | LastRealizedEquity source at upsert time |
| History.ActiveCredit | Table | Event source for all daily financial deltas |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDTDAggregatedData | View | WRAPPER - exposes table to legacy readers |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | WRITER - sole population mechanism |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BOCDTDAD_New | CLUSTERED PK | CID ASC, Date ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |
| CustomerDTDAggregatedData_CUSTOMER_New | NC | CID ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |

**Storage**: All data on [HISTORY] filegroup with DATA_COMPRESSION=PAGE. FILLFACTOR=90 on all indexes.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BOCDTDAD_New | PK | (CID, Date) - one row per customer per day |
| BOCDTDAD_TOTALPROFIT_New through BOCDTDAD_TOTALENDOFWEEKFEE_New | DEFAULT | All Total* columns default to 0 |

---

## 8. Sample Queries

### 8.1 Get a customer's daily activity for the last 30 days
```sql
SELECT
    d.Date,
    d.TotalDeposit,
    d.TotalCashout,
    d.TotalProfit,
    d.TotalPositionCount,
    d.TotalBonus,
    d.TotalCompensation
FROM BackOffice.CustomerDTDAggregatedData_1 d WITH (NOLOCK)
WHERE d.CID = 12345
  AND d.Date >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY d.Date DESC
```

### 8.2 Check deposit velocity - total deposited in last 7 days (risk check)
```sql
SELECT
    d.CID,
    SUM(d.TotalDeposit) AS DepositLast7Days,
    COUNT(*) AS ActiveDays
FROM BackOffice.CustomerDTDAggregatedData_1 d WITH (NOLOCK)
WHERE d.CID = 12345
  AND d.Date >= DATEADD(DAY, -7, CAST(GETUTCDATE() AS DATE))
GROUP BY d.CID
```

### 8.3 Platform-wide daily deposit totals (trend analysis)
```sql
SELECT
    d.Date,
    SUM(d.TotalDeposit) AS TotalPlatformDeposits,
    COUNT(DISTINCT d.CID) AS DepositingCustomers,
    SUM(d.TotalPositionCount) AS PositionsClosed
FROM BackOffice.CustomerDTDAggregatedData_1 d WITH (NOLOCK)
WHERE d.Date >= DATEADD(DAY, -30, CAST(GETUTCDATE() AS DATE))
  AND d.TotalDeposit > 0
GROUP BY d.Date
ORDER BY d.Date DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to CustomerDTDAggregatedData. See BackOffice.CustomerAllTimeAggregatedData_1 for related Confluence and DWH pipeline context.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.2/10, Relationships: 8.8/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerDTDAggregatedData_1 | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerDTDAggregatedData_1.sql*
