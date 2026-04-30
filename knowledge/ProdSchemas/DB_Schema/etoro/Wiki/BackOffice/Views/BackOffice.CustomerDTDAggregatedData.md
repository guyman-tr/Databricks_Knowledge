# BackOffice.CustomerDTDAggregatedData

> Daily (Day-To-Date) financial aggregates view unifying the standard trading pipeline (_1 table) and the MIMO/eToro Money pipeline per customer per day, with MIMO overlay applied to post-2021 dates only.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, Date) - composite key from base tables |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.CustomerDTDAggregatedData` is the unified daily financial summary for every customer per active day, combining data from two physical backing tables via a UNION ALL:

1. **BackOffice.CustomerDTDAggregatedData_1**: Daily aggregates for customers in the standard trading payment pipeline. Contains trading metrics (profit, volume, commissions) and billing totals. 9.857M rows covering 2013 to present.

2. **BackOffice.CustomerMIMODTDAggregatedData**: Daily aggregates for customers using the MIMO (eToro Money) payment pipeline. Contains billing totals only (no trading metrics). 5.846M rows covering 2021-01-07 to present.

The view uses a date-based split to handle the MIMO pipeline launch date (2021-01-01):
- **Post-2021 dates** (`Date >= '20210101'`): standard _1 rows LEFT JOIN MIMO rows on (CID, Date). Billing totals overlaid from MIMO; trading metrics from _1.
- **Pre-2021 dates** (`Date < '20210101'`): standard _1 rows only. No MIMO overlay (MIMO did not exist before 2021).

Note: Unlike the AllTime view (`BackOffice.CustomerAllTimeAggregatedData`), there is NO MIMO-only branch - customers who appear only in the MIMO DTD table (no standard _1 row for that day) do not appear in this view.

The view also excludes `TotalLoginCount` and `TotalLoggedTime` (removed April 2022 per PAYT-10).

---

## 2. Business Logic

### 2.1 Date-Split UNION ALL with MIMO Overlay

**What**: Applies the MIMO billing overlay only to post-2021 daily records, leaving pre-2021 records unchanged.

**Columns/Tables Involved**: CustomerDTDAggregatedData_1 (A), CustomerMIMODTDAggregatedData (M)

**Rules**:
- **Branch 1 (post-2021, standard + MIMO overlay)**: `CustomerDTDAggregatedData_1` WHERE `Date >= '20210101'`. LEFT JOIN to `CustomerMIMODTDAggregatedData` M ON `A.CID = M.CID AND M.Date = A.Date`.
  - **Trading metrics** (TotalProfit, TotalInvestment, TotalCommission, TotalVolume, TotalLot, TotalChampWin, TotalGameCount, TotalPositionCount, TotalEndOfWeekFee, LastRealizedEquity) come from A.
  - **Billing totals** (TotalDeposit, TotalBonus, TotalCashout, TotalCashoutRequest, TotalReverseCashout, TotalCompensation) come from M if a matching (CID, Date) row exists, defaulting to 0 via `ISNULL(M.col, CAST(0 AS MONEY))`.
- **Branch 2 (pre-2021, standard only)**: `CustomerDTDAggregatedData_1` WHERE `Date < '20210101'`. All columns sourced directly from _1. No MIMO overlay.
- `TotalLoginCount` and `TotalLoggedTime` are excluded from both branches (commented out, removed per PAYT-10 in April 2022).

**Diagram**:
```
Post-2021 (Date >= 2021-01-01):
  CustomerDTDAggregatedData_1 (A)   CustomerMIMODTDAggregatedData (M)
        9.857M rows                        5.846M rows (MIMO only)
               |                                  |
               +---LEFT JOIN on (CID, Date)--------+
               |
    TotalDeposit = ISNULL(M.TotalDeposit, 0)   <- MIMO billing wins
    TotalProfit  = A.TotalProfit               <- Trading from A
               |
   UNION ALL
               |
Pre-2021 (Date < 2021-01-01):
  CustomerDTDAggregatedData_1 only
  (MIMO did not exist before Jan 2021)
               |
               v
  BackOffice.CustomerDTDAggregatedData
  (one row per CID per active day, all pipelines merged)
```

### 2.2 Login Metrics Removed (PAYT-10)

**What**: `TotalLoginCount` and `TotalLoggedTime` were removed from this view in April 2022.

**Why**: Per PAYT-10 ticket - these daily login metrics were no longer needed at the DTD grain.

**Impact**: Callers expecting these columns will get an error. Use `BackOffice.CustomerAllTimeAggregatedData` for lifetime login counts, or `BackOffice.CustomerAllTimeAggregatedData_1` for the physical column.

---

## 3. Data Overview

- `CustomerDTDAggregatedData_1`: 9.857M rows, 6.736M unique customers, 1,640 unique dates (2013 to present)
- `CustomerMIMODTDAggregatedData`: 5.846M rows, 4.674M customers, 2021-01-07 to present
- View row count: slightly less than _1 row count (pre-2021 rows pass through unchanged; post-2021 rows LEFT JOIN MIMO)

---

## 4. Elements

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| 1 | CID | int | A.CID | CODE-BACKED | Customer ID. Row key together with Date. |
| 2 | Date | date | A.Date | CODE-BACKED | Calendar date of the customer's activity. Composite PK with CID in base table. |
| 3 | TotalProfit | money | A.TotalProfit | CODE-BACKED | Realized profit from closed positions on this date. From CustomerDTDAggregatedData_1. |
| 4 | TotalDeposit | money | ISNULL(M.TotalDeposit, 0) | CODE-BACKED | Total deposit amount on this date via MIMO pipeline. 0 for pre-2021 dates or customers without MIMO activity. From CustomerMIMODTDAggregatedData. |
| 5 | TotalBonus | money | ISNULL(M.TotalBonus, 0) | CODE-BACKED | Total bonus credits on this date from MIMO pipeline. From CustomerMIMODTDAggregatedData. |
| 6 | TotalInvestment | money | A.TotalInvestment | CODE-BACKED | Funds locked into positions on this date. From CustomerDTDAggregatedData_1. |
| 7 | TotalCommission | money | A.TotalCommission | CODE-BACKED | Commission charges on this date. From CustomerDTDAggregatedData_1. |
| 8 | TotalVolume | money | A.TotalVolume | CODE-BACKED | Trading volume on this date. From CustomerDTDAggregatedData_1. |
| 9 | TotalLot | money | A.TotalLot | CODE-BACKED | Lot volume traded on this date. From CustomerDTDAggregatedData_1. |
| 10 | TotalChampWin | money | A.TotalChampWin | CODE-BACKED | Championship winnings on this date. From CustomerDTDAggregatedData_1. |
| 11 | TotalCashout | money | ISNULL(M.TotalCashout, 0) | CODE-BACKED | Cashout/withdrawal amount on this date via MIMO pipeline. From CustomerMIMODTDAggregatedData. |
| 12 | TotalCashoutRequest | money | ISNULL(M.TotalCashoutRequest, 0) | CODE-BACKED | Cashout request amount on this date. From CustomerMIMODTDAggregatedData. |
| 13 | TotalReverseCashout | money | ISNULL(M.TotalReverseCashout, 0) | CODE-BACKED | Reversed cashout amount on this date. From CustomerMIMODTDAggregatedData. |
| 14 | TotalCompensation | money | ISNULL(M.TotalCompensation, 0) | CODE-BACKED | Compensation credits on this date via MIMO pipeline. From CustomerMIMODTDAggregatedData. |
| 15 | TotalGameCount | int | A.TotalGameCount | CODE-BACKED | Number of games/contests on this date. From CustomerDTDAggregatedData_1. |
| 16 | TotalPositionCount | int | A.TotalPositionCount | CODE-BACKED | Number of trading positions on this date. From CustomerDTDAggregatedData_1. |
| 17 | TotalEndOfWeekFee | money | A.TotalEndOfWeekFee | CODE-BACKED | End-of-week inactivity fees on this date. From CustomerDTDAggregatedData_1. |
| 18 | LastRealizedEquity | money | A.LastRealizedEquity | CODE-BACKED | Realized equity snapshot at end of this date. From CustomerDTDAggregatedData_1. |

**Note**: `TotalLoginCount` and `TotalLoggedTime` were removed in April 2022 (PAYT-10) and are not part of the view's result set.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| A | BackOffice.CustomerDTDAggregatedData_1 | Base Table | Daily aggregates for standard pipeline - both branches source from this table |
| M | BackOffice.CustomerMIMODTDAggregatedData | Base Table | LEFT JOIN overlay for post-2021 dates; adds MIMO billing totals per (CID, Date) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertIntoAggregationTablesAction | (indirect - writes to _1 base) | Writer (via base table) | The batch aggregation SP writes to CustomerDTDAggregatedData_1, which feeds this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDTDAggregatedData (view)
+-- BackOffice.CustomerDTDAggregatedData_1 (table)
|     +-- History.ActiveCredit -> UpsertIntoAggregationTablesAction (batch writer)
+-- BackOffice.CustomerMIMODTDAggregatedData (table, post-2021 only)
      +-- BackOffice.UpsertMIMOAggregation (event-driven writer)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDTDAggregatedData_1 | Table | Both branches - all CIDs and dates. Trading metrics and pre-2021 billing totals. |
| BackOffice.CustomerMIMODTDAggregatedData | Table | Post-2021 dates only - LEFT JOIN on (CID, Date) to overlay MIMO billing totals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTablesAction | Stored Procedure | Writes to base table _1; references the view name in comments/audit context |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Index access through base tables:
- `CustomerDTDAggregatedData_1`: Clustered composite PK on (CID, Date), NC on CID
- `CustomerMIMODTDAggregatedData`: Clustered composite PK on (CID, Date), partitioned on Date

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get daily activity for a customer over the past month

```sql
SELECT Date,
       TotalDeposit,
       TotalCashout,
       TotalProfit,
       TotalVolume,
       TotalPositionCount
FROM BackOffice.CustomerDTDAggregatedData WITH (NOLOCK)
WHERE CID = 12345
  AND Date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
ORDER BY Date DESC;
```

### 8.2 Sum deposits for a customer over the last 30 days (deposit velocity)

```sql
SELECT SUM(TotalDeposit) AS Deposits30d
FROM BackOffice.CustomerDTDAggregatedData WITH (NOLOCK)
WHERE CID = 12345
  AND Date >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
```

### 8.3 Inspect pre-2021 vs post-2021 data patterns

```sql
-- Pre-2021: no MIMO overlay, TotalDeposit from standard pipeline or 0
SELECT TOP 5 CID, Date, TotalDeposit, TotalProfit
FROM BackOffice.CustomerDTDAggregatedData WITH (NOLOCK)
WHERE Date < '20210101'
ORDER BY Date DESC;

-- Post-2021: MIMO overlay applied
SELECT TOP 5 CID, Date, TotalDeposit, TotalProfit
FROM BackOffice.CustomerDTDAggregatedData WITH (NOLOCK)
WHERE Date >= '20210101'
ORDER BY Date DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYT-10 (Jira - from code comment) | Jira | TotalLoginCount and TotalLoggedTime removed from DTD view in April 2022 - columns no longer needed at daily grain |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, View Dep Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerDTDAggregatedData | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.CustomerDTDAggregatedData.sql*
