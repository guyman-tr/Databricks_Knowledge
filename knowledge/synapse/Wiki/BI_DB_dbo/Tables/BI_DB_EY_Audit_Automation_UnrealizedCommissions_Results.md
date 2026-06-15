# BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results

> 1,347-row EY audit reconciliation table comparing daily unrealized commission and PnL changes computed by the Synapse audit SP against Client Balance aggregate values, spanning 2023-07-01 to 2025-04-14. Three metric pairs per date: commission, full commission, and PnL. Populated by SP_EY_Audit_Auditor_Unrealized_Calculations.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Fact -- EY audit reconciliation layer) |
| **Production Source** | Derived -- SP_EY_Audit_Auditor_Unrealized_Calculations compares audit-computed metrics vs BI_DB_Client_Balance_Aggregate_Level_New |
| **Refresh** | Daily (DELETE+INSERT per Date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Not confirmed in generic pipeline mapping_ |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results` is the aggregate-level reconciliation output of the EY (Ernst & Young) external audit automation pipeline. For each business date, the SP computes unrealized commission changes, unrealized full commission changes, and unrealized PnL changes from position-level data using an independent calculation methodology, then compares these against the corresponding values from `BI_DB_Client_Balance_Aggregate_Level_New`. The table stores the absolute values of both computations plus the dollar difference and percentage difference.

The table exists to provide auditors with a daily reconciliation check: if the EY-computed unrealized metrics diverge significantly from the client balance aggregates, it signals a potential discrepancy requiring investigation. As of 2025-04-14, the table contains 1,347 rows (3 metric pairs x 449 dates) spanning from 2023-07-01 to 2025-04-14.

The companion table `BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation` stores the same unrealized metrics broken down by regulation and instrument, providing the drill-down detail behind this aggregate comparison.

**Key observations from live data**:
- `Stored_Proc` is always `'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse'` (single value)
- `IsPriceFound` is always NULL in this table (it is a placeholder; the position-level `IsPriceFound` flag lives in the underlying audit tables)
- Typical `Diff_Percentage` ranges from <1% to ~33%, with most days under 5%

---

## 2. Business Logic

### 2.1 Three-Metric Comparison Pattern

**What**: Each date produces exactly 3 rows, one per metric pair comparing EY audit computation (Metric_a) against Client Balance (Metric_b).

**Columns Involved**: `Metric_a`, `Metric_a_Value`, `Metric_b`, `Metric_b_Value`, `Diff`, `Diff_Percentage`

**Rules**:
- Row 1: `Metric_a` = `EY_UnrealizedCommissionChange_Calc` vs `Metric_b` = `CB_UnrealizedCommissionChange`
- Row 2: `Metric_a` = `EY_UnrealizedFullCommissionChange_Calc` vs `Metric_b` = `CB_UnrealizedFullCommissionChange`
- Row 3: `Metric_a` = `EY_UnrealizedPnLChange_Calc` vs `Metric_b` = `CB_UnrealizedPnLChange`
- Both `Metric_a_Value` and `Metric_b_Value` are `ABS(SUM(...))` -- absolute values of the aggregated daily change
- `Diff` = `Metric_a_Value - Metric_b_Value` (can be negative)
- `Diff_Percentage` = `ABS((Metric_a_Value - Metric_b_Value) / Metric_b_Value * 100)`

### 2.2 EY Audit Computation (Metric_a Side)

**What**: The EY-side values are computed from position-level data using an independent PnL and commission calculation methodology.

**Columns Involved**: `Metric_a_Value`

**Rules**:
- Position-level unrealized changes are computed in `#testresults` as `ISNULL(ed.EY_UnrealizedCommission, 0) - ISNULL(sd.EY_UnrealizedCommission, 0)` between end date (@edate) and start date (@sdate = day before)
- PnL calculation branches on `PnLVersion` (1 vs other), `IsBuy`, `SellCurrencyID`, and `BuyCurrencyID` using rate-based formulas with USD conversion
- Commission uses a best-fit selection from three methods: Ask/Bid spread, ReferenceAsk/ReferenceBid, and LastOpPriceRate -- whichever is closest to eToro's recorded commission
- `EY_UnrealizedCommission = EY_Commission_Calc_Final * OutstandingUnitsRatio` where `OutstandingUnitsRatio = Units / InitialUnits`
- IsDiscounted=1 and IsReOpen=1 positions get commission=0

### 2.3 Client Balance Comparison (Metric_b Side)

**What**: The client balance values come directly from the aggregate client balance table.

**Columns Involved**: `Metric_b_Value`

**Rules**:
- `SELECT ABS(SUM(UnrealizedCommissionChange))`, `ABS(SUM(UnrealizedFullCommissionChange))`, or `ABS(SUM(UnrealizedPnLChange))` from `BI_DB_Client_Balance_Aggregate_Level_New WHERE DateID = @edateID`
- These represent the same metrics computed by a different ETL path (SP_Client_Balance_New)

### 2.4 DELETE+INSERT Load Pattern

**What**: The SP replaces data for a single date on each run.

**Rules**:
- `DELETE FROM ... WHERE [Date] = @edate` runs before the 3-row INSERT
- The SP also ensures prerequisite data exists in `BI_DB_EY_Audit_Opened_Positions` for both @sdate and @edate, calling `SP_EY_Audit_Opened_Positions` if needed
- After the main computation, the SP cleans up `BI_DB_EY_Audit_Opened_Positions` rows for dates no longer needed (keeps only @sdate and @edate)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN + HEAP**: With only ~1,347 rows, no index is needed. Full scans are trivial. No partitioning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest reconciliation results | `SELECT * WHERE [Date] = (SELECT MAX([Date]) FROM ...)` |
| Dates with high divergence | `WHERE Diff_Percentage > 5 ORDER BY Diff_Percentage DESC` |
| Trend of PnL divergence over time | `WHERE Metric_a = 'EY_UnrealizedPnLChange_Calc' ORDER BY [Date]` |
| Commission reconciliation for a specific date | `WHERE [Date] = @d AND Metric_a LIKE '%Commission%'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_PerRegulation | ON CAST(CONVERT(VARCHAR(8), [Date], 112) AS INT) = DateID | Drill down to regulation-level detail behind aggregate metrics |
| BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | ON CAST(CONVERT(VARCHAR(8), [Date], 112) AS INT) = DateID | Compare against raw client balance aggregates |

### 3.4 Gotchas

- **Date is a `date` type, not an int**: Unlike most BI_DB tables that use DateID (int YYYYMMDD), this table stores `Date` as a `date` type. Convert when joining to other audit tables: `CAST(CONVERT(VARCHAR(8), [Date], 112) AS INT)`.
- **IsPriceFound is always NULL**: This column is hardcoded to NULL in the INSERT. The position-level price-found flag lives in `BI_DB_EY_Audit_Opened_Positions` and `EY_Audit_Automation_Opened_Positions_End_2022_Baseline`, not in this results table.
- **Values are absolute**: Both Metric_a_Value and Metric_b_Value are wrapped in `ABS()` before insert. Diff can still be negative (a_value - b_value), but the individual metric values are always non-negative.
- **Stored_Proc is a single constant**: Only one value exists (`SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse`). The column exists for provenance tracking but is not a useful filter.
- **3 rows per date**: Always exactly 3 rows per date (one per metric pair). If fewer exist, the SP encountered an error or was not run for that date.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 3 stars | Tier 2 | From Synapse SP code (SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 2 stars | Tier 3 | From MCP live data |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date of the computation end date (@edate). Derived from SP parameter: `CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112)`. Range: 2023-07-01 to 2025-04-14. DELETE+INSERT key. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 2 | Stored_Proc | varchar(200) | YES | Provenance label identifying the SP that produced this row. Always `'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse'` (hardcoded string literal in the INSERT). (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 3 | Metric_a | varchar(200) | YES | Label for the EY audit-computed metric. One of: `'EY_UnrealizedCommissionChange_Calc'`, `'EY_UnrealizedFullCommissionChange_Calc'`, `'EY_UnrealizedPnLChange_Calc'`. Hardcoded in the UNION ALL SELECT blocks of the INSERT. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 4 | Metric_a_Value | decimal(18,4) | YES | Absolute value of the EY audit-computed daily unrealized change. Computed as `ABS(SUM(...))` from `#testresults` (position-level daily change aggregated across all positions). The underlying computation uses rate-based PnL formulas and best-fit commission calculations. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 5 | Metric_b | varchar(200) | YES | Label for the Client Balance comparison metric. One of: `'CB_UnrealizedCommissionChange'`, `'CB_UnrealizedFullCommissionChange'`, `'CB_UnrealizedPnLChange'`. Hardcoded in the UNION ALL SELECT blocks of the INSERT. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 6 | Metric_b_Value | decimal(18,4) | YES | Absolute value of the Client Balance aggregate metric for the same date. Computed as `ABS(SUM(UnrealizedCommissionChange))` (or FullCommission/PnL variant) from `BI_DB_Client_Balance_Aggregate_Level_New WHERE DateID = @edateID`. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 7 | Diff | decimal(18,4) | YES | Dollar difference between EY audit and Client Balance values. Computed as `Metric_a_Value - Metric_b_Value`. Can be negative (when CB value exceeds EY value). (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 8 | Diff_Percentage | decimal(18,4) | YES | Percentage divergence between EY audit and Client Balance values. Computed as `ABS((Metric_a_Value - Metric_b_Value) / Metric_b_Value * 100)`. Always non-negative. Risk of division by zero if Metric_b_Value = 0 (not guarded in SP). (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 9 | IsPriceFound | int | YES | Placeholder column. Hardcoded to `NULL` in the INSERT statement. The position-level IsPriceFound flag exists in `BI_DB_EY_Audit_Opened_Positions` and `EY_Audit_Automation_Opened_Positions_End_2022_Baseline`, not in this aggregate results table. Always NULL. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |
| 10 | UpdateDate | datetime | YES | ETL load timestamp. Set to `GETDATE()` at insert time. All 3 rows for a given Date share the same UpdateDate. Not a business date. (Tier 2 -SP_EY_Audit_Auditor_Unrealized_Calculations) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter @date | @edate | `CONVERT(DATE, CONVERT(VARCHAR(8), ma.DateID), 112)` |
| Stored_Proc | ETL-computed | N/A | Hardcoded: `'SP_EY_Audit_Auditor_Unrealized_Calculations_On_Synapse'` |
| Metric_a | ETL-computed | N/A | Hardcoded label per UNION block |
| Metric_a_Value | #testresults (position-level audit data) | UnrealizedCommissionChange / UnrealizedFullCommissionChange / UnrealizedPnLChange | `ABS(SUM(...))` |
| Metric_b | ETL-computed | N/A | Hardcoded label per UNION block |
| Metric_b_Value | BI_DB_Client_Balance_Aggregate_Level_New | UnrealizedCommissionChange / UnrealizedFullCommissionChange / UnrealizedPnLChange | `ABS(SUM(...)) WHERE DateID = @edateID` |
| Diff | ETL-computed | Metric_a_Value, Metric_b_Value | `Metric_a_Value - Metric_b_Value` |
| Diff_Percentage | ETL-computed | Metric_a_Value, Metric_b_Value | `ABS((Metric_a_Value - Metric_b_Value) / Metric_b_Value * 100)` |
| IsPriceFound | ETL-computed | N/A | Hardcoded `NULL` |
| UpdateDate | ETL-computed | N/A | `GETDATE()` |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (closed commissions)
BI_DB_dbo.BI_DB_EY_Audit_Opened_Positions (daily open position snapshots)
BI_DB_dbo.EY_Audit_Automation_LastOpRate (last op prices)
BI_DB_dbo.EY_Audit_Automation_Opened_Positions_End_2022_Baseline (pre-2023 baseline)
BI_DB_dbo.EY_Audit_Automation_Position_Open_Configs (spread configs)
  |
  |-- SP_EY_Audit_Auditor_Unrealized_Calculations @date
  |   (builds #StartDateReady, #EndDateReady, computes PnL + commissions,
  |    produces #testresults with per-position daily changes)
  |
  v
#testresults → ABS(SUM(...)) by metric ──────────────── Metric_a side
  |
  |-- UNION ALL with ──────────────────────────────────── Metric_b side
  |   BI_DB_Client_Balance_Aggregate_Level_New
  |   (ABS(SUM(UnrealizedCommissionChange/FullCommission/PnL)))
  |
  v
DELETE + INSERT per Date
  |
  v
BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results (~1,347 rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Prerequisite | SP_EY_Audit_Opened_Positions | Ensures open position snapshots exist for @sdate and @edate |
| Source A | #testresults | Position-level unrealized changes (EY audit methodology) |
| Source B | BI_DB_Client_Balance_Aggregate_Level_New | Client balance unrealized aggregates |
| ETL | SP_EY_Audit_Auditor_Unrealized_Calculations (Author: Guy Manova, 2023-12-18) | DELETE+INSERT per Date. 3 UNION ALL blocks produce 3 rows |
| Target | BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results | ~1,347 rows (3 per date) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Metric_b_Value | BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Source of client balance comparison values |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_EY_Audit_Auditor_Unrealized_Calculations | Writer | DELETE+INSERT per Date |

---

## 7. Sample Queries

### 7.1 Latest reconciliation results for all three metrics

```sql
SELECT
    [Date],
    Metric_a,
    Metric_a_Value,
    Metric_b,
    Metric_b_Value,
    Diff,
    Diff_Percentage
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results]
WHERE [Date] = (SELECT MAX([Date]) FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results])
ORDER BY Metric_a;
```

### 7.2 Dates with highest PnL divergence

```sql
SELECT TOP 20
    [Date],
    Metric_a_Value AS EY_PnL,
    Metric_b_Value AS CB_PnL,
    Diff AS Diff_Dollars,
    Diff_Percentage
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results]
WHERE Metric_a = 'EY_UnrealizedPnLChange_Calc'
ORDER BY Diff_Percentage DESC;
```

### 7.3 Monthly average divergence trend for commission

```sql
SELECT
    FORMAT([Date], 'yyyy-MM') AS YearMonth,
    AVG(Diff_Percentage) AS AvgDiffPct,
    MAX(Diff_Percentage) AS MaxDiffPct,
    COUNT(*) AS DayCount
FROM [BI_DB_dbo].[BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results]
WHERE Metric_a = 'EY_UnrealizedCommissionChange_Calc'
GROUP BY FORMAT([Date], 'yyyy-MM')
ORDER BY YearMonth;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in regen harness.)

---

*Generated: 2026-04-29 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_EY_Audit_Automation_UnrealizedCommissions_Results | Type: Table | Production Source: SP_EY_Audit_Auditor_Unrealized_Calculations (derived)*
