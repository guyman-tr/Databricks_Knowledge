# BI_DB_dbo.DWH_GainDaily

> 6.25B-row daily multi-horizon portfolio gain table storing compound returns (daily, weekly, monthly, quarterly, half-yearly, yearly, MTD, YTD, QTD) for every customer — pivoted from the TradeGain Ranking service's External_TradeGain_Ranking_Compound_Gain_Completed table, covering Jan 2013 to present. The largest table in BI_DB_dbo. Refreshed daily by SP_DWH_GainDaily via DELETE+INSERT by Date. Not migrated to Unity Catalog.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by `BI_DB_dbo.SP_DWH_GainDaily` from External_TradeGain_Ranking_Compound_Gain_Completed |
| **Refresh** | Daily — DELETE WHERE Date=@gain_dt + INSERT. Accumulating by date. |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP (PK on Date, CID — NOT ENFORCED) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

This table provides **multi-horizon compound portfolio returns** for every eToro customer, calculated daily by the production TradeGain Ranking service. For each customer and date, it stores 9 different gain metrics covering intervals from 1 day to 1 year, plus to-date metrics (MTD, QTD, YTD).

The 6.25B rows cover daily snapshots from Jan 2013 to Apr 2026 — making this the **largest table in BI_DB_dbo**. The SP performs a simple pivot: the source (Compound_Gain_Completed) stores one row per (CID, IntervalTypeID, Gain), and the SP pivots 9 interval types into 9 columns per CID.

The TradeGain Ranking service runs externally (tracked by External_TradeGain_Ranking_Execution, ObjectID=4). The SP finds the latest completed execution for the given date and pivots its results.

Gain values represent percentage returns as decimals (e.g., 0.0216 = 2.16% gain, -0.2485 = 24.85% loss). NULL values indicate the interval is not available for that customer on that date (e.g., weekly gain may be NULL if the customer hasn't been active for a full week).

---

## 2. Business Logic

### 2.1 IntervalTypeID to Column Mapping

**What**: Pivots row-based interval gains into columnar format.
**Columns Involved**: All Gain_* columns
**Rules**:
- IntervalTypeID 1 → Gain_d (daily)
- IntervalTypeID 7 → Gain_w (weekly, trailing 7 days)
- IntervalTypeID 101 → Gain_MTD (month-to-date)
- IntervalTypeID 102 → Gain_QTD (quarter-to-date)
- IntervalTypeID 103 → Gain_YTD (year-to-date)
- IntervalTypeID 106 → Gain_m (monthly, trailing 30 days)
- IntervalTypeID 108 → Gain_q (quarterly, trailing 90 days)
- IntervalTypeID 109 → Gain_h (half-yearly, trailing 180 days)
- IntervalTypeID 110 → Gain_y (yearly, trailing 365 days)

### 2.2 Execution Selection

**What**: Only uses the latest completed execution for the given date.
**Columns Involved**: ExecutionID
**Rules**:
- Source: External_TradeGain_Ranking_Execution WHERE Completed=1 AND ObjectID=4 AND MaxDate <= @gain_dt_today
- Takes MAX(ExecutionID) from qualifying executions
- All gain rows for a CID on a date come from the same ExecutionID

### 2.3 Zero Gain Exclusion

**What**: Customers with Gain=0 for all intervals are excluded.
**Columns Involved**: All Gain_* columns
**Rules**:
- WHERE g.Gain <> 0 in source filter
- A customer with no non-zero gains on a date has no row in this table

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(CID) distribution — co-located JOINs with other CID-distributed tables. HEAP with NOT ENFORCED PK. **6.25B rows — ALWAYS filter by Date or CID.**

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer's latest gains | `WHERE CID = X AND Date = (SELECT MAX(Date) FROM DWH_GainDaily WHERE CID = X)` |
| Best performing customers today | `WHERE Date = @today ORDER BY Gain_d DESC` |
| Yearly return for all customers | `WHERE Date = @today AND Gain_y IS NOT NULL` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile |
| BI_DB_dbo.BI_DB_MonthlyGain | CID + date alignment | Cross-reference monthly gain aggregation |

### 3.4 Gotchas

- **6.25B rows**: The LARGEST table in BI_DB_dbo. ALWAYS filter by Date. Queries without a Date filter will timeout.
- **NULL gain columns**: A NULL Gain_w doesn't mean 0% return — it means the weekly interval was not available (insufficient history). Use COALESCE only if you understand this distinction.
- **Gain values are decimals, not percentages**: 0.0216 = 2.16% gain. Multiply by 100 for display.
- **HASH(CID) distribution**: This table is uniquely HASH-distributed among BI_DB tables. JOINs on CID with this table are co-located if the other table is also HASH(CID).
- **ExecutionID**: Multiple execution IDs may exist for the same date (retries/corrections). The SP always takes the latest completed one.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis — high confidence |
| Tier 5 | ETL infrastructure column — canonical description |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | NO | Snapshot date for which gains were calculated. PK component (NOT ENFORCED). Used as DELETE+INSERT key. (Tier 2 — SP_DWH_GainDaily) |
| 2 | CID | int | NO | Customer ID. FK to Dim_Customer.RealCID. One row per customer per day. PK component (NOT ENFORCED). HASH distribution key. (Tier 2 — SP_DWH_GainDaily) |
| 3 | Gain_w | float | YES | Trailing 7-day (weekly) compound portfolio return as a decimal. 0.05 = 5% gain. NULL if insufficient trading history. IntervalTypeID=7 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 4 | Gain_m | float | YES | Trailing 30-day (monthly) compound portfolio return as a decimal. IntervalTypeID=106 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 5 | Gain_q | float | YES | Trailing 90-day (quarterly) compound portfolio return as a decimal. IntervalTypeID=108 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 6 | Gain_h | float | YES | Trailing 180-day (half-yearly) compound portfolio return as a decimal. IntervalTypeID=109 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 7 | Gain_y | float | YES | Trailing 365-day (yearly) compound portfolio return as a decimal. IntervalTypeID=110 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 8 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_DWH_GainDaily. (Tier 5 — ETL infrastructure) |
| 9 | Gain_MTD | float | YES | Month-to-date compound portfolio return as a decimal. From first of current month to Date. IntervalTypeID=101 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 10 | Gain_YTD | float | YES | Year-to-date compound portfolio return as a decimal. From Jan 1 to Date. IntervalTypeID=103 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 11 | Gain_d | float | YES | Daily compound portfolio return as a decimal. Single-day gain for this Date. IntervalTypeID=1 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 12 | Gain_QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. From first of current quarter to Date. IntervalTypeID=102 from TradeGain service. (Tier 2 — SP_DWH_GainDaily) |
| 13 | ExecutionID | int | YES | TradeGain Ranking service execution ID that produced these gains. Links to External_TradeGain_Ranking_Execution. Multiple executions may exist per date; SP uses the latest completed one (ObjectID=4). (Tier 2 — SP_DWH_GainDaily) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | SP parameter | @gain_dt | passthrough |
| CID | TradeGain_Ranking_Compound_Gain_Completed | CID | passthrough |
| Gain_* (9 columns) | TradeGain_Ranking_Compound_Gain_Completed | Gain | pivot by IntervalTypeID |
| UpdateDate | — | — | GETDATE() |
| ExecutionID | TradeGain_Ranking_Compound_Gain_Completed | ExecutionID | passthrough (latest completed) |

### 5.2 ETL Pipeline

```
TradeGain Ranking Service (production, external)
  |-- Produces compound gains by IntervalTypeID
  |-- Tracked by External_TradeGain_Ranking_Execution (ObjectID=4)
  v
BI_DB_dbo.External_TradeGain_Ranking_Compound_Gain_Completed
BI_DB_dbo.External_TradeGain_Ranking_Execution
  |
  |-- SP_DWH_GainDaily @gain_dt (daily)
  |   Find latest completed ExecutionID
  |   Pivot 9 IntervalTypeIDs into 9 gain columns
  |   DELETE WHERE Date=@gain_dt + INSERT
  v
BI_DB_dbo.DWH_GainDaily (6.25B rows, accumulating daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| — | — | Likely consumed by reporting/Popular Investor leaderboards (no SSDT SP references found) |

---

## 7. Sample Queries

### 7.1 Top Performers This Week

```sql
SELECT TOP 20 CID, Gain_w, Gain_m, Gain_y
FROM BI_DB_dbo.DWH_GainDaily
WHERE Date = CAST(GETDATE()-1 AS DATE)
  AND Gain_w IS NOT NULL
ORDER BY Gain_w DESC
```

---

## 8. Atlassian Knowledge Sources

No direct Confluence/Jira pages found. Context: TradeGain Ranking is a production service that calculates compound portfolio returns; data surfaces in Popular Investor leaderboards and performance dashboards.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 12 T2, 0 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.DWH_GainDaily | Type: Table | Production Source: SP_DWH_GainDaily (pivot from TradeGain Ranking Compound Gain)*
