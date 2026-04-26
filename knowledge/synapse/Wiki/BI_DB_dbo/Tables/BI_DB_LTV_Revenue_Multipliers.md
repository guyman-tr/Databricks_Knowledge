# BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers

> Monthly-snapshot revenue multiplier matrix for the LTV model (10 cols, ~233K rows, updated monthly). Written by `SP_M_LTV_Multipliers` from `BI_DB_CID_MonthlyPanel_FullData`. Stores pre-computed ratios of current accumulated revenue to 1Y/3Y/8Y milestone revenue for each (Seniority × MonthsSinceLastActive) cohort bucket. Consumed by `SP_LTV_Multiplier_Model` to project CID-level LTV predictions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — revenue milestones and activity state |
| **Refresh** | Monthly (DELETE WHERE Date = @date + INSERT, only on EOMONTH dates) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no index) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Bradley Roberts (2022-07-11) |
| **Row Count** | ~233K (232,848 rows; 49 monthly snapshots as of 2026-03-31) |

---

## 1. Business Meaning

`BI_DB_LTV_Revenue_Multipliers` is a **pre-computed lookup table** for the Revenue Multiplier LTV Model. It answers the question: *"Given a customer at Seniority X months from first funding, who was last active Y months ago, what fraction of their eventual 1Y/3Y/8Y revenue have they accumulated so far?"*

Each row is a (Date × Seniority × MonthsSinceLastActive) triple with the corresponding revenue ratios, computed by aggregating actual historical revenue data from `BI_DB_CID_MonthlyPanel_FullData` across all qualifying customers in that bucket.

**How it's used**: `SP_LTV_Multiplier_Model` queries this table to project forward from a customer's `Current_ACC_Revenue`:
```
LTV_1Y = Current_ACC_Revenue / RatioSnapshotTo1Y
LTV_3Y = Current_ACC_Revenue / RatioSnapshotTo3Y
LTV_8Y = Current_ACC_Revenue / RatioSnapshotTo8Y
```
The SP always uses the most recent snapshot: `WHERE Date = MAX(Date)`.

The table accumulates monthly snapshots from 2022-07-17 to the present (49 snapshots as of 2026-03-31). With 96 Seniority levels × up to 96 MonthsSinceLastActive levels = up to 9,216 combinations per monthly snapshot.

---

## 2. Business Logic

### 2.1 Monthly Cadence: EOMONTH Gate

**What**: The SP only runs on the last day of each month, controlled by a WHILE loop.

**Columns Involved**: Date, UpdateDate

**Rules**:
- SP condition: `WHILE @date = EOMONTH(@date)` — the loop only executes when `@date` is the last day of its month
- DELETE pattern: `DELETE FROM BI_DB_LTV_Revenue_Multipliers WHERE @date = Date` — removes existing rows for this date before re-inserting
- This means each monthly snapshot can be regenerated idempotently: re-running the SP for the same month-end date replaces the existing snapshot
- Despite OpsDB listing this as `SB_Daily` (process name), the WHILE loop ensures it only actually writes on month-end dates
- `Date` in all inserted rows = the @date parameter (the last day of the month)

### 2.2 Three-Cohort Model Construction

**What**: Ratios are computed from different customer cohorts depending on seniority range, using the most recent customers available for each.

**Columns Involved**: Seniority, MonthsSinceLastActive, all ratio columns

**Rules**:
- **Seniority 1–12 (1Y model)**: Uses customers with FTDdate ≥ 3 years ago AND Seniority ≥ 12. Ratios computed against these "recent enough" cohorts for shorter horizons.
- **Seniority 13–36 (3Y model)**: Uses customers with FTDdate ≥ 5 years ago AND Seniority ≥ 36. RatioSnapshotTo8Y extrapolated using `Ratio3Y8Y` from the 8Y matrix.
- **Seniority 37–96 (8Y model)**: Uses customers with FTDdate ≥ 10 years ago AND Seniority ≥ 96 — the oldest etoro cohort available.
- The cascading approach ensures shorter-horizon ratios use fresher behavioral data, while long-horizon ratios necessarily rely on older (but seniority-qualified) cohorts.
- `MonthsSinceLastActive = Seniority - MAX(Seniority WHERE ActiveOpen=1)` — months since the customer last had any open position.

### 2.3 Ratio Semantics

**What**: Each ratio cell represents the cross-cohort average relationship between accumulated revenue at a seniority snapshot and the milestone total.

**Rules**:
- Formula: `RatioSnapshotTo1Y = SUM(SnapshotACCRevenue) / SUM(Rev1Y)` across all customers in the (Seniority, MonthsSinceLastActive) bucket
- A ratio of 0.185 (Seniority=1, MSLA=0) means customers at month 1 have accumulated ~18.5% of their eventual 1Y revenue
- Lower ratios = further from the milestone total (early seniority, highly active)
- Dividing current revenue by the ratio projects forward: `LTV = CurrentRevenue / 0.185 = ~5.4× current`
- NULLIF(SUM(...), 0) guards against division-by-zero — cohort buckets with no qualifying customers produce NULL ratios
- NULL rows: SP_LTV_Multiplier_Model handles NULL via `ISNULL(..., 0)` — no LTV projection possible for those cells

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN. HEAP (no index). At ~233K rows, full-table scans are fast. The key access pattern is point lookup: `WHERE Date = MAX(Date) AND Seniority = @s AND MonthsSinceLastActive = @m`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Latest multiplier for a given cohort | `SELECT * WHERE Date = (SELECT MAX(Date) FROM ...) AND Seniority = 12 AND MonthsSinceLastActive = 0` |
| How many cohort buckets exist in latest snapshot | `SELECT COUNT(*) WHERE Date = (SELECT MAX(Date) FROM ...)` |
| How ratios change over time for one cohort | `SELECT Date, RatioSnapshotTo8Y WHERE Seniority = 12 AND MonthsSinceLastActive = 0 ORDER BY Date` |
| LTV model cold check (inactive-customer multiplier) | `SELECT Seniority, MonthsSinceLastActive, RatioSnapshotTo8Y WHERE Date = MAX(Date) AND MonthsSinceLastActive = Seniority ORDER BY Seniority` |

### 3.3 Gotchas

- **SP runs only on EOMONTH dates**: The WHILE loop condition means the table is updated only once per month, on the last calendar day. Do not expect daily updates despite the SB_Daily process name in OpsDB.
- **Accumulating by Date**: Old monthly snapshots are preserved. The table contains 49 historical snapshots. `SP_LTV_Multiplier_Model` always reads `MAX(Date)`. Do not read from this table without filtering on `Date = MAX(Date)` to avoid mixing snapshots.
- **NULL ratios are valid data**: If no customers exist in a given (Seniority, MonthsSinceLastActive) bucket, ratios are NULL. This produces LTV=0 in SP_LTV_Multiplier_Model after ISNULL coercion.
- **HEAP distribution**: No index means all lookups are full scans. For the ~233K row table this is acceptable, but JOIN to large customer tables should use the indexed customer table as the driving side.
- **RatioSnapshotTo8Y for Seniority 13–36 is extrapolated**: For the 3Y cohort, `RatioSnapshotTo8Y = RatioSnapshotTo3Y × AVG(Ratio3Y8Y_from_8Y_cohort)`. It is not computed from direct 8Y actuals — it inherits the 8Y ratio from older cohorts. This extrapolation adds model uncertainty for mid-seniority customers.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | SP-computed statistical aggregate from BI_DB_CID_MonthlyPanel_FullData |
| Propagation | Canonical ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Month-end date of this multiplier snapshot. All rows from one monthly SP run share the same Date = EOMONTH(@date). The consumer table `SP_LTV_Multiplier_Model` always reads `WHERE Date = MAX(Date)`. Range: 2022-07-17 to 2026-03-31 (49 snapshots). (Tier 2 — SP_M_LTV_Multipliers run date) |
| 2 | Seniority | int | YES | Months since the customer's first new funded date — the snapshot seniority dimension. Range: 1–96. Lookup key in `SP_LTV_Multiplier_Model` matching against the customer's current Seniority. (Tier 2 — SP_M_LTV_Multipliers) |
| 3 | MonthsSinceLastActive | int | YES | Months since the customer last had any open position, at the seniority snapshot. Range: 0–96. A value of 0 means the customer was actively trading at that seniority point. Higher values indicate dormancy. Second lookup key in `SP_LTV_Multiplier_Model`. (Tier 2 — SP_M_LTV_Multipliers via BI_DB_CID_MonthlyPanel_FullData.ActiveOpen) |
| 4 | RatioSnapshotTo1Y | decimal(12,5) | YES | Ratio of accumulated revenue at this snapshot (SnapshotACCRevenue) to total 1-year accumulated revenue (Rev1Y), averaged across the cohort: `SUM(SnapshotACCRevenue) / SUM(Rev1Y)`. Used to project LTV_1Y: `LTV_1Y = Current_ACC_Revenue / RatioSnapshotTo1Y`. Example: 0.18540 at Seniority=1, MSLA=0 — a 1-month customer has 18.5% of their eventual 1Y revenue. (Tier 2 — SP_M_LTV_Multipliers) |
| 5 | RatioSnapshotTo3Y | decimal(12,5) | YES | Same as RatioSnapshotTo1Y but against 3-year accumulated revenue (Rev3Y). Used to project LTV_3Y. For Seniority 13–36 (3Y cohort), computed directly from 3Y actuals. For Seniority 1–12 (1Y cohort), extrapolated via `RatioSnapshotTo1Y × AVG(Ratio1Y3Y)`. (Tier 2 — SP_M_LTV_Multipliers) |
| 6 | RatioSnapshotTo8Y | decimal(12,5) | YES | Same as RatioSnapshotTo1Y but against 8-year accumulated revenue (Rev8Y). Used to project LTV_8Y. For Seniority 37–96: computed from direct 8Y actuals. For Seniority 13–36: extrapolated via Ratio3Y8Y from 8Y cohort. For Seniority 1–12: double-extrapolated via Ratio1Y3Y and Ratio3Y8Y. (Tier 2 — SP_M_LTV_Multipliers) |
| 7 | Ratio1Y3Y | decimal(12,5) | YES | Ratio of total 1-year revenue to total 3-year revenue for this cohort: `SUM(Rev1Y) / SUM(Rev3Y)`. Expresses how much of 3Y revenue is earned in the first year. Used to extrapolate RatioSnapshotTo3Y for the 1Y cohort. (Tier 2 — SP_M_LTV_Multipliers) |
| 8 | Ratio1Y8Y | decimal(12,5) | YES | Ratio of total 1-year revenue to total 8-year revenue for this cohort: `SUM(Rev1Y) / SUM(Rev8Y)`. Expresses how much of 8Y revenue is earned in the first year. (Tier 2 — SP_M_LTV_Multipliers) |
| 9 | Ratio3Y8Y | decimal(12,5) | YES | Ratio of total 3-year revenue to total 8-year revenue for this cohort: `SUM(Rev3Y) / SUM(Rev8Y)`. Expresses how much of 8Y revenue is earned in the first 3 years. Used in the 3Y cohort to extrapolate RatioSnapshotTo8Y and in the volatility fix of `SP_LTV_Multiplier_Model`. (Tier 2 — SP_M_LTV_Multipliers) |
| 10 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the SP run. Set to GETDATE(). (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| All ratio columns | BI_DB_CID_MonthlyPanel_FullData | ACC_Revenue_Total, ActiveOpen, Seniority | SUM aggregation per (Seniority, MonthsSinceLastActive) bucket |
| Date | ETL parameter | @date | EOMONTH date of the SP run |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData
  → Revenue milestones (Rev1Y at Seniority=12, Rev3Y at 36, Rev8Y at 96)
  → MonthsSinceLastActive (last Seniority where ActiveOpen=1)
  → Three cohort populations:
      #Clients1Y: FTD ≥ 3 years ago, Seniority ≥ 12 → ActivityMatrix1Y (Seniority 1-12)
      #Clients3Y: FTD ≥ 5 years ago, Seniority ≥ 36 → ActivityMatrix3Y (Seniority 13-36)
      #Clients8Y: FTD ≥ 10 years ago, Seniority ≥ 96 → ActivityMatrix8Y (Seniority 37-96)
  → SUM aggregation per (SnapshotSeniority, MonthsSinceLastActive)
         |-- SP_M_LTV_Multipliers @date=EOMONTH (monthly) ---|
         |   DELETE WHERE Date=@date; INSERT all three ranges  |
         v
BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers (~233K rows, 49 snapshots accumulated)
  → Consumed by SP_LTV_Multiplier_Model: WHERE Date = MAX(Date)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| All ratios | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Only data source — revenue and activity per month per customer |

### 6.2 Referenced By

| Object | How Used |
|--------|----------|
| BI_DB_dbo.SP_LTV_Multiplier_Model | Reads latest snapshot (Date = MAX(Date)) to project CID LTV from Current_ACC_Revenue |
| BI_DB_dbo.BI_DB_LTV_Predictions | Indirect — predictions are derived using these multipliers |

---

## 7. Sample Queries

### 7.1 Latest multiplier matrix for a specific cohort
```sql
SELECT Seniority, MonthsSinceLastActive,
       RatioSnapshotTo1Y, RatioSnapshotTo3Y, RatioSnapshotTo8Y
FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers]
WHERE Date = (SELECT MAX(Date) FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers])
  AND Seniority BETWEEN 1 AND 12
ORDER BY Seniority, MonthsSinceLastActive;
```

### 7.2 Track how multiplier changed over monthly snapshots for one cohort
```sql
SELECT Date, RatioSnapshotTo8Y, Ratio3Y8Y
FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers]
WHERE Seniority = 12 AND MonthsSinceLastActive = 0
ORDER BY Date DESC;
```

### 7.3 Coverage check: which (Seniority, MSLA) cells are missing in latest snapshot
```sql
SELECT Date, COUNT(DISTINCT Seniority) AS SeniorityLevels,
       COUNT(DISTINCT MonthsSinceLastActive) AS MSLALevels,
       COUNT(*) AS TotalRows,
       SUM(CASE WHEN RatioSnapshotTo8Y IS NULL THEN 1 ELSE 0 END) AS NullRatio8Y
FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers]
WHERE Date = (SELECT MAX(Date) FROM [BI_DB_dbo].[BI_DB_LTV_Revenue_Multipliers])
GROUP BY Date;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.9/10 | Batch: 52*
*Tiers: 0 T1, 9 T2, 0 T3, 0 T4, 1 Propagation | Elements: 10/10, Logic: 3 subsections*
*Object: BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers | Type: Table | Source: BI_DB_CID_MonthlyPanel_FullData (LTV multiplier lookup matrix)*
