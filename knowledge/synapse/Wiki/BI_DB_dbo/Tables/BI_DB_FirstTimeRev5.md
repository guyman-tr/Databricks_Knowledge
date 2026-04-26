# BI_DB_dbo.BI_DB_FirstTimeRev5

> 994K-row revenue milestone table tracking the first position where each customer's cumulative trading commission exceeds $5, sourced daily from DWH_dbo.Dim_Position via SP_FirstTimeRev5 using a running-sum window function. Date range: March 2022 to present. Nearly 1:1 CID-to-row ratio (994,412 distinct CIDs).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Position via `BI_DB_dbo.SP_FirstTimeRev5` |
| **Refresh** | Daily (SB_Daily), delete+insert by DateID |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_FirstTimeRev5 captures the **first moment** each customer (CID) generates a cumulative trading commission exceeding **$5**. Each row represents one customer's revenue milestone event — the specific position and timestamp at which the running commission sum crossed the threshold.

The SP processes positions opened or closed on @Yesterday. For each CID that traded that day (and hasn't already reached the $5 mark on a prior day), it calculates a running sum of commissions across all positions (using CommissionOnClose for closed positions, Commission for open positions), ordered by occurrence time. The first position where the cumulative sum exceeds $5 is recorded. Only positions whose occurrence date matches @Yesterday are inserted, preventing historical backfill artifacts.

**Key metrics**: 994,439 rows, 994,412 distinct CIDs (nearly 1:1), AggregatedCommission range $5.01–$17,264.93 (avg $11.57). Zero NULLs in CID and PositionID.

**Author**: Tal Cohen (2022-04-25). Migrated to Synapse by Chen Largman (2023-06-28).

---

## 2. Business Logic

### 2.1 Revenue Threshold Detection

**What**: Identifies the exact position at which cumulative commission crosses the $5 mark.
**Columns Involved**: CID, PositionID, AggregatedCommission, Timestamp
**Rules**:
- Running sum uses `SUM(...) OVER(PARTITION BY CID ORDER BY Occurred ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`
- Commission source: `CASE WHEN CloseDateID != 0 THEN ISNULL(CommissionOnClose, 0) ELSE ISNULL(Commission, 0) END`
- Only the first crossing event is kept: `ROW_NUMBER() OVER(PARTITION BY CID ORDER BY Occurred) = 1 WHERE AggregatedCommission > 5`
- Position occurrence must fall on @Yesterday: `CAST(Occurred AS DATE) = @Yesterday`

### 2.2 Deduplication Guard

**What**: Prevents duplicate entries for CIDs that already reached the milestone.
**Columns Involved**: CID, DateID
**Rules**:
- Before calculating, CIDs already present in the table (on any DateID other than @d_i) are excluded via LEFT JOIN anti-pattern
- Delete+insert by DateID allows same-day reprocessing without duplicates

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no co-located joins. Clustered index on DateID provides efficient date-range scans. For CID-based lookups, expect full table scan across distributions.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many CIDs reached $5 rev per month? | `SELECT LEFT(DateID, 6) AS YearMonth, COUNT(*) FROM BI_DB_FirstTimeRev5 GROUP BY LEFT(DateID, 6)` |
| What is the typical commission at milestone? | `SELECT AVG(CAST(AggregatedCommission AS float)), PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY AggregatedCommission) OVER() FROM BI_DB_FirstTimeRev5` |
| Did a specific CID reach the milestone? | `SELECT * FROM BI_DB_FirstTimeRev5 WHERE CID = @cid` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Position | PositionID = PositionID | Get full position details (instrument, amount, leverage) |
| DWH_dbo.Dim_Customer | CID = RealCID | Get customer demographics, regulation, country |

### 3.4 Gotchas

- **AggregatedCommission is NOT the total lifetime commission** — it is the cumulative sum at the exact position that crossed $5. It can be much higher if a single large trade pushed the sum well past the threshold.
- **One row per CID** (nearly) — 994,412 distinct CIDs in 994,439 rows. Minor duplicates may exist from same-day reprocessing edge cases.
- **DateID is the processing date**, not necessarily the position open/close date. Timestamp reflects the actual position occurrence time.
- **Historical gap**: Data starts March 2022 despite SP creation in April 2022 — initial backfill run covered earlier dates. Migration to Synapse in June 2023.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | Domain expert input or ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Processing date — the @Yesterday parameter value passed to the SP. Represents the day positions were evaluated for the $5 commission threshold. (Tier 2 — SP_FirstTimeRev5) |
| 2 | Timestamp | datetime | YES | Occurrence datetime of the threshold-crossing position event. CASE: CloseOccurred if position was closed (CloseDateID != 0), else OpenOccurred. This is the exact moment the CID crossed $5 cumulative commission. (Tier 2 — SP_FirstTimeRev5) |
| 3 | CID | int | YES | Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl) |
| 4 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 — Trade.PositionTbl) |
| 5 | AggregatedCommission | money | YES | Cumulative commission at the milestone position. Running SUM of per-position commissions (CommissionOnClose for closed, Commission for open) partitioned by CID ordered by occurrence. Always > $5.00. Range: $5.01–$17,264.93, avg $11.57. (Tier 2 — SP_FirstTimeRev5) |
| 6 | DateID | int | YES | ETL-computed date int (YYYYMMDD) derived from @Yesterday. Used for delete+insert idempotency and clustered index. Range: 20220301–20260412. (Tier 2 — SP_FirstTimeRev5) |
| 7 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_FirstTimeRev5) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | — | — | @Yesterday parameter |
| Timestamp | DWH_dbo.Dim_Position | OpenOccurred / CloseOccurred | CASE by CloseDateID |
| CID | DWH_dbo.Dim_Position | CID | Passthrough |
| PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough |
| AggregatedCommission | DWH_dbo.Dim_Position | Commission, CommissionOnClose | Running SUM window function |
| DateID | — | — | CONVERT(VARCHAR(8), @Yesterday, 112) |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionTbl (production)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_PositionTbl
  |-- SP_Dim_Position_DL_To_Synapse ---|
  v
DWH_dbo.Dim_Position
  |-- SP_FirstTimeRev5 @Yesterday ---|
  |   (running SUM commission > $5, ROW_NUMBER=1)
  v
BI_DB_dbo.BI_DB_FirstTimeRev5 (994K rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| CID | DWH_dbo.Dim_Position.CID | Customer who reached the commission milestone |
| PositionID | DWH_dbo.Dim_Position.PositionID | The specific position that crossed the $5 threshold |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the BI_DB_dbo codebase.

---

## 7. Sample Queries

### 7.1 Monthly Revenue Milestone Trend

```sql
SELECT LEFT(CAST(DateID AS VARCHAR), 6) AS YearMonth,
       COUNT(*) AS NewMilestoneCIDs,
       AVG(CAST(AggregatedCommission AS FLOAT)) AS AvgCommAtMilestone
FROM BI_DB_dbo.BI_DB_FirstTimeRev5
GROUP BY LEFT(CAST(DateID AS VARCHAR), 6)
ORDER BY YearMonth DESC
```

### 7.2 Milestone CIDs With Customer Details

```sql
SELECT f.CID, f.Date, f.AggregatedCommission,
       dc.RegulationID, dc.CountryByIP
FROM BI_DB_dbo.BI_DB_FirstTimeRev5 f
JOIN DWH_dbo.Dim_Customer dc ON f.CID = dc.RealCID
WHERE f.DateID >= 20260101
ORDER BY f.AggregatedCommission DESC
```

### 7.3 Position Details for Milestone Events

```sql
SELECT f.CID, f.PositionID, f.AggregatedCommission,
       dp.InstrumentID, dp.Amount, dp.Leverage, dp.IsBuy
FROM BI_DB_dbo.BI_DB_FirstTimeRev5 f
JOIN DWH_dbo.Dim_Position dp ON f.PositionID = dp.PositionID
WHERE f.DateID = 20260412
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 7/7, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_FirstTimeRev5 | Type: Table | Production Source: DWH_dbo.Dim_Position via SP_FirstTimeRev5*
