# BackOffice.CustomerMTDAggregatedData

> Monthly (Month-To-Date) financial aggregates view unifying the standard trading pipeline (_1 table) and the MIMO/eToro Money pipeline per customer per calendar month, with MIMO overlay applied to Year >= 2021 only.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | (CID, Year, Month) - composite key from base tables |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.CustomerMTDAggregatedData` is the unified monthly financial summary for every customer per active calendar month. It is the monthly-grain counterpart to `BackOffice.CustomerDTDAggregatedData` (daily) and `BackOffice.CustomerAllTimeAggregatedData` (lifetime), completing the three-tier aggregation system.

The view combines two physical backing tables via a year-based UNION ALL split (identical pattern to the DTD view):

1. **BackOffice.CustomerMTDAggregatedData_1**: Monthly aggregates for the standard trading payment pipeline. Contains trading and billing metrics. 7.9M rows.

2. **BackOffice.CustomerMIMOMTDAggregatedData**: Monthly aggregates for the MIMO (eToro Money) payment pipeline. Billing totals only.

The same year-based split applies as in the DTD view:
- **Year >= 2021**: standard _1 rows LEFT JOIN MIMO rows on (CID, Year, Month). Billing totals overlaid from MIMO.
- **Year < 2021**: standard _1 rows only. No MIMO overlay (MIMO launched January 2021).

Note: Like the DTD view, there is no MIMO-only branch - customers with only a MIMO monthly record (no _1 row for that year-month) do not appear. `TotalLoginCount` and `TotalLoggedTime` are excluded (removed April 2022 per PAYT-10).

---

## 2. Business Logic

### 2.1 Year-Split UNION ALL with MIMO Overlay

**What**: Applies the MIMO billing overlay only to post-2020 monthly records.

**Columns/Tables Involved**: CustomerMTDAggregatedData_1 (A), CustomerMIMOMTDAggregatedData (M)

**Rules**:
- **Branch 1 (Year >= 2021)**: LEFT JOIN M ON `A.CID = M.CID AND M.Year = A.Year AND M.Month = A.Month`.
  - **Trading metrics** (TotalProfit, TotalInvestment, TotalCommission, TotalVolume, TotalLot, TotalChampWin, TotalGameCount, TotalPositionCount, TotalEndOfWeekFee) from A.
  - **Billing totals** (TotalDeposit, TotalBonus, TotalCashout, TotalCashoutRequest, TotalReverseCashout, TotalCompensation) from M via `ISNULL(M.col, CAST(0 AS MONEY))`.
- **Branch 2 (Year < 2021)**: All columns directly from _1. No MIMO join.
- `TotalLoginCount` and `TotalLoggedTime` removed from both branches (PAYT-10, April 2022).

**Diagram**:
```
Year >= 2021:
  CustomerMTDAggregatedData_1 (A)  +  CustomerMIMOMTDAggregatedData (M)
  LEFT JOIN on (CID, Year, Month)
  Billing totals = ISNULL(M.col, 0)
  Trading metrics = A.col

  UNION ALL

Year < 2021:
  CustomerMTDAggregatedData_1 only (all columns from A)

-> BackOffice.CustomerMTDAggregatedData
   (one row per CID per active calendar month)
```

---

## 3. Data Overview

- `CustomerMTDAggregatedData_1`: 7.9M rows, per-customer-per-month
- `CustomerMIMOMTDAggregatedData`: monthly MIMO aggregates, 2021 to present
- View is the authoritative monthly aggregates source for all downstream consumers

---

## 4. Elements

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| 1 | CID | int | A.CID | CODE-BACKED | Customer ID. Part of composite row key (CID, Year, Month). |
| 2 | Year | int | A.Year | CODE-BACKED | Calendar year of the activity month. 4-digit year. |
| 3 | Month | int | A.Month | CODE-BACKED | Calendar month number (1-12) of the activity. |
| 4 | TotalProfit | money | A.TotalProfit | CODE-BACKED | Total realized profit from closed positions in this month. From CustomerMTDAggregatedData_1. |
| 5 | TotalDeposit | money | ISNULL(M.TotalDeposit, 0) | CODE-BACKED | Total deposits in this month via MIMO pipeline. 0 for Year < 2021 or no MIMO activity. From CustomerMIMOMTDAggregatedData. |
| 6 | TotalBonus | money | ISNULL(M.TotalBonus, 0) | CODE-BACKED | Total bonus credits this month via MIMO. From CustomerMIMOMTDAggregatedData. |
| 7 | TotalInvestment | money | A.TotalInvestment | CODE-BACKED | Funds locked into positions in this month. From CustomerMTDAggregatedData_1. |
| 8 | TotalCommission | money | A.TotalCommission | CODE-BACKED | Commission charges in this month. From CustomerMTDAggregatedData_1. |
| 9 | TotalVolume | money | A.TotalVolume | CODE-BACKED | Trading volume in this month. From CustomerMTDAggregatedData_1. |
| 10 | TotalLot | money | A.TotalLot | CODE-BACKED | Lot volume in this month. From CustomerMTDAggregatedData_1. |
| 11 | TotalChampWin | money | A.TotalChampWin | CODE-BACKED | Championship winnings in this month. From CustomerMTDAggregatedData_1. |
| 12 | TotalCashout | money | ISNULL(M.TotalCashout, 0) | CODE-BACKED | Approved cashouts this month via MIMO. From CustomerMIMOMTDAggregatedData. |
| 13 | TotalCashoutRequest | money | ISNULL(M.TotalCashoutRequest, 0) | CODE-BACKED | Cashout requests this month via MIMO. From CustomerMIMOMTDAggregatedData. |
| 14 | TotalReverseCashout | money | ISNULL(M.TotalReverseCashout, 0) | CODE-BACKED | Reversed cashouts this month via MIMO. From CustomerMIMOMTDAggregatedData. |
| 15 | TotalCompensation | money | ISNULL(M.TotalCompensation, 0) | CODE-BACKED | Compensation credits this month via MIMO. From CustomerMIMOMTDAggregatedData. |
| 16 | TotalGameCount | int | A.TotalGameCount | CODE-BACKED | Number of game/contest participations this month. From CustomerMTDAggregatedData_1. |
| 17 | TotalPositionCount | int | A.TotalPositionCount | CODE-BACKED | Number of trading positions opened this month. From CustomerMTDAggregatedData_1. |
| 18 | TotalEndOfWeekFee | money | A.TotalEndOfWeekFee | CODE-BACKED | End-of-week inactivity fees in this month. From CustomerMTDAggregatedData_1. |

**Note**: `TotalLoginCount` and `TotalLoggedTime` were removed in April 2022 (PAYT-10) and are not part of the view's result set.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| A | BackOffice.CustomerMTDAggregatedData_1 | Base Table | Monthly aggregates for standard pipeline - both branches source from this table |
| M | BackOffice.CustomerMIMOMTDAggregatedData | Base Table | LEFT JOIN overlay for Year >= 2021; adds MIMO billing totals per (CID, Year, Month) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpsertIntoAggregationTablesAction | (indirect - writes to _1 base) | Writer (via base table) | Batch SP writes to CustomerMTDAggregatedData_1, which feeds this view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerMTDAggregatedData (view)
+-- BackOffice.CustomerMTDAggregatedData_1 (table)
|     +-- History.ActiveCredit -> UpsertIntoAggregationTablesAction (batch writer)
+-- BackOffice.CustomerMIMOMTDAggregatedData (table, Year >= 2021 only)
      +-- BackOffice.UpsertMIMOAggregation (event-driven writer)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerMTDAggregatedData_1 | Table | Both branches - all CIDs and year-months. Trading metrics and pre-2021 billing totals. |
| BackOffice.CustomerMIMOMTDAggregatedData | Table | Year >= 2021 only - LEFT JOIN on (CID, Year, Month) to overlay MIMO billing totals |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpsertIntoAggregationTablesAction | Stored Procedure | Writes to base table _1; may reference view in comments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Base table indexes:
- `CustomerMTDAggregatedData_1`: Clustered composite PK on (CID, Year, Month), NC on CID
- `CustomerMIMOMTDAggregatedData`: Clustered composite PK on (CID, Year, Month)

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get monthly deposit and profit history for a customer

```sql
SELECT Year, Month, TotalDeposit, TotalProfit, TotalVolume
FROM BackOffice.CustomerMTDAggregatedData WITH (NOLOCK)
WHERE CID = 12345
ORDER BY Year DESC, Month DESC;
```

### 8.2 Sum deposits for a customer over the last 3 months

```sql
SELECT SUM(TotalDeposit) AS Deposits3m
FROM BackOffice.CustomerMTDAggregatedData WITH (NOLOCK)
WHERE CID = 12345
  AND (Year * 100 + Month) >= (YEAR(DATEADD(MONTH, -3, GETDATE())) * 100 + MONTH(DATEADD(MONTH, -3, GETDATE())));
```

### 8.3 Monthly deposit totals for a cohort (e.g., March 2026)

```sql
SELECT CID, TotalDeposit, TotalCashout, TotalProfit
FROM BackOffice.CustomerMTDAggregatedData WITH (NOLOCK)
WHERE Year = 2026 AND Month = 3
  AND TotalDeposit > 0
ORDER BY TotalDeposit DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYT-10 (Jira - from code comment) | Jira | TotalLoginCount and TotalLoggedTime removed from MTD view in April 2022 (same change as DTD view - PAYT-10 removed login metrics from both daily and monthly aggregation views) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, View Dep Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerMTDAggregatedData | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.CustomerMTDAggregatedData.sql*
