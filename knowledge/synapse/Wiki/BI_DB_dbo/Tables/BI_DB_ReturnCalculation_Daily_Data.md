# BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data

> 10.6B-row daily fact table of per-customer net profit, realized equity, and revenue. One row per CID per date. Incremental DELETE+INSERT (new DateIDs only) via SP_BI_DB_ReturnCalculation Phase 1. Union of three sources: NetProfit from Dim_Position closed positions, RealizedEquity from V_Liabilities, and Revenue from BI_DB_DailyCommisionReport. Feeds into BI_DB_ReturnCalculation for time-window aggregation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position + DWH_dbo.V_Liabilities + BI_DB_dbo.BI_DB_DailyCommisionReport via `SP_BI_DB_ReturnCalculation` |
| **Refresh** | Daily (incremental DELETE+INSERT — new DateIDs since max existing) |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Yarden Sabadra (2024-03-26) |
| **Row Count** | ~10,590,000,000 (as of 2026-04-11) |

---

## 1. Business Meaning

`BI_DB_ReturnCalculation_Daily_Data` stores daily per-customer financial metrics that feed into the return calculation pipeline. Each row represents one customer (RealCID) on one date (DateID), capturing three metrics: net profit from closed trading positions, realized equity from V_Liabilities, and revenue from commissions and rollover fees.

The data is built as a UNION of three separate queries:
1. **NetProfit**: SUM of Dim_Position.NetProfit grouped by CloseDateID and RealCID (closed positions)
2. **RealizedEquity**: From V_Liabilities, with flags for zero and negative equity days
3. **Revenue**: SUM of FullCommissions + RollOverFee from BI_DB_DailyCommisionReport

The table uses incremental loading: only DateIDs newer than the current maximum are loaded, with DELETE+INSERT for overlap handling. DateID=0 serves as a sentinel value for unknown/unresolvable dates (mapped to 1900-01-01).

With 10.6 billion rows across 5.87 million distinct CIDs, this is one of the largest tables in the BI_DB schema.

---

## 2. Business Logic

### 2.1 NetProfit Component

**What**: Daily net profit from closed trading positions.
**Columns Involved**: `NetProfit`
**Rules**:
- SUM(Dim_Position.NetProfit) grouped by CloseDateID and RealCID
- Only closed positions (keyed by CloseDateID from Dim_Position)
- RealizedEquity, IsZeroRealizedEquity, IsNegativeRealizedEquity, Revenue are NULL for these rows

### 2.2 RealizedEquity Component

**What**: Daily realized equity from the liabilities view.
**Columns Involved**: `RealizedEquity`, `IsZeroRealizedEquity`, `IsNegativeRealizedEquity`
**Rules**:
- RealizedEquity sourced directly from V_Liabilities
- IsZeroRealizedEquity = 1 when RealizedEquity = 0 (used to exclude from AVG in ReturnCalculation)
- IsNegativeRealizedEquity = 1 when RealizedEquity < 0 (used to exclude from AVG in ReturnCalculation)
- NetProfit and Revenue are NULL for these rows

### 2.3 Revenue Component

**What**: Daily revenue from commissions and rollover fees.
**Columns Involved**: `Revenue`
**Rules**:
- Revenue = SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport
- Grouped by DateID and RealCID
- NetProfit, RealizedEquity, and equity flags are NULL for these rows

### 2.4 Incremental Load Pattern

**What**: Only new dates are loaded to avoid full table rebuild.
**Rules**:
- SP reads MAX(DateID) from existing table
- Only rows with DateID > MAX(existing) are fetched from sources
- DELETE existing rows where DateID+RealCID overlap with incoming batch (handles late-arriving data)
- INSERT new rows

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) with CLUSTERED INDEX on DateID ASC — optimized for date-range scans. Cross-distribution joins on RealCID are co-located with BI_DB_ReturnCalculation.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily metrics for one customer | `WHERE RealCID = {cid} ORDER BY DateID` |
| Recent daily data | `WHERE DateID >= {yyyymmdd}` (leverages CI on DateID) |
| Net profit for a date range | `WHERE DateID BETWEEN {start} AND {end} AND NetProfit IS NOT NULL` |
| Equity trend for a customer | `WHERE RealCID = {cid} AND RealizedEquity IS NOT NULL ORDER BY DateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_ReturnCalculation | `RealCID = RealCID` | Aggregated return metrics (consumer) |
| DWH_dbo.Dim_Customer | `RealCID = RealCID` | Customer attributes |
| DWH_dbo.Dim_Date | `DateID = DateID` | Calendar attributes |

### 3.4 Gotchas

- **10.6 billion rows**: This is a very large table. Always filter by DateID range or RealCID to avoid full scans
- **UNION structure**: Each row has only one non-NULL metric (NetProfit OR RealizedEquity OR Revenue). The others are NULL. Do not assume all columns are populated per row
- **DateID=0 sentinel**: Represents unknown/unresolvable dates, mapped to Date='1900-01-01'. Filter with `WHERE DateID > 0` if sentinel rows are unwanted
- **CI on DateID, HASH on RealCID**: DateID range scans are efficient within each distribution, but a single-CID query must touch all distributions

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | ETL metadata (system-generated) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | NO | Date as YYYYMMDD integer. Clustered index key. 0 for sentinel/unknown dates. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 2 | Date | date | NO | Calendar date corresponding to DateID. '1900-01-01' for DateID=0. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 3 | RealCID | int | NO | Customer ID. HASH distribution key. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 4 | NetProfit | money | YES | Daily net profit from closed positions. SUM of Dim_Position.NetProfit by CloseDateID. NULL for RealizedEquity and Revenue rows. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 5 | RealizedEquity | money | YES | Daily realized equity from V_Liabilities. NULL for NetProfit and Revenue rows. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 6 | IsZeroRealizedEquity | int | YES | Flag: 1 when RealizedEquity = 0. Used to exclude zero-equity days from average calculation in ReturnCalculation. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 7 | IsNegativeRealizedEquity | int | YES | Flag: 1 when RealizedEquity < 0. Used to exclude negative-equity days from average calculation in ReturnCalculation. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 8 | Revenue | money | YES | Daily revenue: SUM(FullCommissions + RollOverFee) from BI_DB_DailyCommisionReport. NULL for NetProfit and RealizedEquity rows. (Tier 2 — SP_BI_DB_ReturnCalculation) |
| 9 | UpdateDate | datetime2 | NO | ETL execution timestamp. GETDATE() at SP execution time. (Tier 5 — ETL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| DateID | DWH_dbo.Dim_Position | CloseDateID | passthrough (NetProfit rows) |
| DateID | DWH_dbo.V_Liabilities | DateID | passthrough (RealizedEquity rows) |
| DateID | BI_DB_dbo.BI_DB_DailyCommisionReport | DateID | passthrough (Revenue rows) |
| RealCID | DWH_dbo.Dim_Position / V_Liabilities / DailyCommisionReport | RealCID | passthrough |
| NetProfit | DWH_dbo.Dim_Position | NetProfit | SUM by CloseDateID + RealCID |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | passthrough |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | FullCommissions + RollOverFee | SUM per DateID + RealCID |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (closed positions, NetProfit by CloseDateID)
  + DWH_dbo.V_Liabilities (RealizedEquity by DateID)
  + BI_DB_dbo.BI_DB_DailyCommisionReport (FullCommissions + RollOverFee by DateID)
  |
  |-- SP_BI_DB_ReturnCalculation Phase 1 (daily incremental DELETE+INSERT)
  |   Step 1: Read MAX(DateID) from existing Daily_Data
  |   Step 2: UNION of 3 queries (NetProfit, RealizedEquity, Revenue) for new DateIDs
  |   Step 3: DELETE overlapping DateID+RealCID from existing table
  |   Step 4: INSERT new rows
  v
BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data (10.6B rows, HASH(RealCID) CI(DateID))
  |
  v
BI_DB_dbo.BI_DB_ReturnCalculation (consumer — aggregates across time windows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension |
| NetProfit | DWH_dbo.Dim_Position | Closed position net profit |
| RealizedEquity | DWH_dbo.V_Liabilities | Realized equity |
| Revenue | BI_DB_dbo.BI_DB_DailyCommisionReport | Commissions + rollover fees |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| All metrics | BI_DB_dbo.BI_DB_ReturnCalculation | Aggregated return calculation (5 time windows) |

---

## 7. Sample Queries

### 7.1 Daily Metrics for a Customer (Last 30 Days)

```sql
SELECT DateID, Date, NetProfit, RealizedEquity, Revenue
FROM BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data
WHERE RealCID = {target_cid}
  AND DateID >= CONVERT(int, FORMAT(DATEADD(DAY, -30, GETDATE()), 'yyyyMMdd'))
ORDER BY DateID
```

### 7.2 Average Realized Equity Excluding Zero/Negative Days

```sql
SELECT RealCID, AVG(RealizedEquity) AS AvgEquity
FROM BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data
WHERE RealizedEquity IS NOT NULL
  AND ISNULL(IsZeroRealizedEquity, 0) = 0
  AND ISNULL(IsNegativeRealizedEquity, 0) = 0
  AND DateID >= 20250101
GROUP BY RealCID
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 8 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/9, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_ReturnCalculation_Daily_Data | Type: Table | Production Source: Dim_Position + V_Liabilities + DailyCommisionReport via SP_BI_DB_ReturnCalculation*
