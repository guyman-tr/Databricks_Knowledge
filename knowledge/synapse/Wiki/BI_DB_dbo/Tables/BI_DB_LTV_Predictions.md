# BI_DB_dbo.BI_DB_LTV_Predictions

> CID-level lifetime value (LTV) predictions for all active depositors (16 cols, ~5.84M rows, updated daily). Written by `SP_LTV_Multiplier_Model` using a revenue multiplier model with volatility smoothing. Stores 1Y/3Y/8Y LTV projections per customer, switching to actuals once the customer reaches the corresponding seniority milestone. Group-level averages (LTV_8Y_GroupLevel) are computed post-insert across (FirstFundedMonth × Region × ClusterDetail × EquityTier).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `Customer.CustomerStatic` via `DWH_dbo.Dim_Customer`; revenue from `BI_DB_CID_DailyPanel_FullData` / `BI_DB_CID_MonthlyPanel_FullData` |
| **Refresh** | Daily SB_Daily (rolling DELETE + INSERT per 30-day customer milestone) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (RealCID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Author** | Bradley Roberts (2022-07-11) |
| **Row Count** | ~5.84M (5,838,143 as of 2026-04-12) |

---

## 1. Business Meaning

`BI_DB_LTV_Predictions` stores the expected lifetime revenue for every active eToro depositor, computed by the Revenue Multiplier LTV Model built by Bradley Roberts. Each row is a snapshot of a customer's LTV prediction **at their most recent 30-day funded anniversary**, making the table a continuously-updated register of forward-looking revenue expectations.

Three LTV horizons are provided per customer:
- **LTV_1Y**: expected total revenue at 12 months from first funding
- **LTV_3Y**: expected total revenue at 36 months from first funding  
- **LTV_8Y**: expected total revenue at 96 months from first funding

Each horizon has two variants: the raw prediction (`LTV_1Y`, `LTV_3Y`, `LTV_8Y`) and a **volatility-adjusted version** (`LTV_1Y_VolFix`, `LTV_3Y_VolFix`, `LTV_8Y_VolFix`) that smooths predictions using a 12-month rolling group average multiplier.

**Key design**: once a customer actually reaches a milestone (Seniority ≥ 12/36/96 months), the prediction is replaced by the **actual accumulated revenue** at that point — making the LTV column a hybrid predicted/actual field.

`LTV_8Y_GroupLevel` provides the group-level mean of `LTV_8Y_VolFix` for the customer's cohort (FirstFundedMonth × Region × ClusterDetail × EquityTier), computed via a post-INSERT UPDATE.

With 5.84M rows spanning customers funded since October 2012, this is one of the largest customer-attribute tables in BI_DB_dbo.

---

## 2. Business Logic

### 2.1 30-Day Cadence: Rolling DELETE + INSERT

**What**: The SP processes only customers whose seniority is a multiple of 30 days on the run date. It deletes their existing row and re-inserts an updated prediction.

**Columns Involved**: RealCID, Seniority, FirstFundedMonth, UpdateDate

**Rules**:
- A customer is processed on their run date `@date` if: `DATEDIFF(day, FirstNewFundedDate, @date) % 30 = 0` AND `FirstNewFundedDate <= @date - 30 days`
- OR if `FirstDepositDate <= @date - 30 days` AND `FirstNewFundedDate IS NULL` (legacy depositors without a funded date)
- The SP excludes customers whose `FirstNewFundedDate > @date - 30 days` (too new to have a 30-day milestone)
- On each qualifying run: their existing row is deleted then a fresh prediction is inserted
- This means `UpdateDate` reflects the customer's most recent 30-day anniversary processing date, NOT today's date for all rows
- Rows can be months old for customers who haven't hit a 30-day milestone recently (UpdateDate range: 2023-08-07 to 2026-04-12 in production)
- **This is NOT a full refresh** — the table accumulates rows for all customers ever processed. Do not use `MAX(UpdateDate)` as a freshness check for all customers.

### 2.2 Revenue Multiplier Prediction Model

**What**: LTV projections are derived by dividing the customer's current accumulated revenue by the historical ratio of current-to-future revenue for their cohort.

**Columns Involved**: Current_ACC_Revenue, LTV_1Y, LTV_3Y, LTV_8Y, Seniority, MonthsSinceLastPosOpen

**Rules**:
- Prediction formula: `LTV_nY = Current_ACC_Revenue / RatioSnapshotTo_nY`
- `RatioSnapshotTo_nY` comes from `BI_DB_LTV_Revenue_Multipliers` — the pre-computed ratio of revenue at the customer's current seniority to expected revenue at 1Y/3Y/8Y, for customers with the same `Seniority` and `MonthsSinceLastActive`
- Current_ACC_Revenue applies a seniority-based correction for underestimation in monthly aggregations: Seniority=1 → divide by 0.80; Seniority=2 → divide by 0.90; Seniority=3 → divide by 0.95; Seniority≥4 → no adjustment
- Once a customer reaches Seniority ≥ 12 months, `LTV_1Y` is replaced by the **actual** accumulated revenue at month 12 from `BI_DB_CID_MonthlyPanel_FullData`. Same logic applies at 36 months for LTV_3Y and 96 months for LTV_8Y.
- `ISNULL(rtd.ACC_Revenue_Total, 0)` — customers with no revenue data get LTV = 0

### 2.3 Volatility Fix: 12-Month Rolling Group Average

**What**: Adjusts raw LTV predictions using a moving average ratio to smooth period-specific model noise.

**Columns Involved**: LTV_1Y_VolFix, LTV_3Y_VolFix, LTV_8Y_VolFix

**Rules**:
- Group definition: (FirstFundedMonth × Region × ClusterDetail × EquityTier)
- For each group, compute: rolling sum of LTV over the last 12 funded months (C) / current funded-month group average LTV (B)
- Apply adjustment: `LTV_nY_VolFix = LTV_nY × (C / B)`, clamped to [0.5, 2.0]
  - If ratio < 0.5: cap at 0.5 (prevents extreme downward adjustments)
  - If ratio > 2.0: cap at 2.0 (prevents extreme upward adjustments)
  - If B is NULL or 0: ratio defaults to 1.0 (no adjustment)
- The VolFix variants are the **preferred LTV values** for downstream analytics — they are less sensitive to cohort-specific noise than the raw predictions.
- VolFix adjustments are computed using the **previous production run** of `BI_DB_LTV_Predictions` (the SP self-reads the table in `#MovingAVGPerGroup`), meaning the first run for a new cohort group has no rolling average context.

### 2.4 EquityTier Segmentation

**What**: Customers are bucketed into three equity tiers based on their current realized equity.

**Columns Involved**: EquityTier

**Rules**:
- `EquityTier = 1`: `RealizedEquity < $100` OR `RealizedEquity IS NULL` — low equity / new / inactive
- `EquityTier = 2`: `$100 ≤ RealizedEquity < $500` — medium equity
- `EquityTier = 3`: `RealizedEquity ≥ $500` — high equity
- Equity is sourced from `DWH_dbo.Fact_SnapshotEquity` joined on the active `Dim_Range` date range
- NULL EquityTier (~8K rows) occurs when no matching `Fact_SnapshotEquity` row is found for the customer

### 2.5 LTV_8Y_GroupLevel Post-INSERT Calculation

**What**: After all predictions are inserted, the table is updated to fill `LTV_8Y_GroupLevel` with the group average of `LTV_8Y_VolFix`.

**Columns Involved**: LTV_8Y_GroupLevel, LTV_8Y_VolFix, FirstFundedMonth, Region, ClusterDetail, EquityTier

**Rules**:
- `LTV_8Y_GroupLevel = AVG(LTV_8Y_VolFix)` grouped by (FirstFundedMonth, Region, ClusterDetail, EquityTier), computed across ALL rows currently in the table (not just the rows inserted today)
- A second UPDATE sets LTV_8Y_GroupLevel = 0 where NULL (groups with no matching other rows)
- All rows in the same group share the identical LTV_8Y_GroupLevel value — it is a group-level attribute, not a customer-level prediction

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

Distribution: ROUND_ROBIN. Clustered on RealCID — optimized for customer-level lookups. At 5.84M rows, date or region scans will be full-table. Join to Dim_Customer on RealCID = RealCID for customer enrichment.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Customer's current LTV prediction | `SELECT RealCID, LTV_8Y_VolFix, LTV_8Y_GroupLevel WHERE RealCID = @cid` |
| Group average LTV by region and cluster | `SELECT Region, ClusterDetail, AVG(LTV_8Y_VolFix) WHERE EquityTier = 3 GROUP BY Region, ClusterDetail ORDER BY AVG(LTV_8Y_VolFix) DESC` |
| High-value customers (LTV_8Y_VolFix > $1000) | `SELECT RealCID, Region, ClusterDetail, EquityTier, LTV_8Y_VolFix WHERE LTV_8Y_VolFix > 1000 ORDER BY LTV_8Y_VolFix DESC` |
| LTV distribution by equity tier | `SELECT EquityTier, COUNT(RealCID) Customers, AVG(LTV_8Y_VolFix) AvgLTV, SUM(LTV_8Y_VolFix) TotalLTV GROUP BY EquityTier` |
| Freshness per customer cohort | `SELECT FirstFundedMonth, MAX(UpdateDate) LastUpdated WHERE FirstFundedMonth >= '2025-01-01' GROUP BY FirstFundedMonth ORDER BY FirstFundedMonth` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer profile enrichment |
| BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers | Seniority = Seniority, MonthsSinceLastPosOpen = MonthsSinceLastActive | Multiplier lookup (reverse tracing) |

### 3.4 Gotchas

- **UpdateDate is NOT a global freshness marker**: Each customer is updated on their own 30-day milestone. A row with `UpdateDate = 2023-08-07` is not stale — it was last updated at that customer's most recent 30-day anniversary. Use `Seniority` and `FirstFundedMonth` to understand temporal context.
- **LTV = 0 for NULL-revenue customers**: `ISNULL(ACC_Revenue_Total, 0)` means customers with no revenue in the panel tables will have all LTV fields = 0.0, not NULL. Do not interpret 0 as "no prediction available" without checking Current_ACC_Revenue.
- **Actuals replace predictions at milestones**: When `Seniority ≥ 12` for LTV_1Y (similarly 36 for LTV_3Y, 96 for LTV_8Y), the value is the actual cumulative revenue, not a prediction. The column semantics shift from "expected" to "realized" — these are not comparable across Seniority bands without accounting for this.
- **LTV_8Y_GroupLevel reflects ALL rows, not just today's inserts**: Because the post-INSERT UPDATE runs across the entire table, a newly-inserted row's LTV_8Y_GroupLevel is influenced by millions of other rows in the same group. The group average will shift daily as new customers are added.
- **Self-referential volatility fix**: The SP reads the production table to compute #MovingAVGPerGroup. If the table is empty or recently truncated, the first run produces LTV_*_VolFix = LTV_* (no adjustment, ratio defaults to 1.0).
- **EquityTier NULL rows (~8K)**: Customers with no Fact_SnapshotEquity match have NULL EquityTier. These will be excluded from GROUP BY queries on EquityTier unless NULL is handled explicitly.
- **MonthsSinceLastPosOpen is capped at Seniority**: `CASE WHEN DATEDIFF(day, MAX(dp.OpenOccurred), @date) / 30 > c.Seniority THEN c.Seniority ELSE ... END`. A customer who has never traded since month 1 will show MonthsSinceLastPosOpen = Seniority, not an unbounded large number. NULL for customers with no Dim_Position records.
- **BI_DB_LTV_Revenue_Multipliers dependency**: If the multipliers table is empty or lacks a row for a given (Seniority, MonthsSinceLastActive), the LTV prediction will be NULL then coalesced to 0 by ISNULL. Check BI_DB_LTV_Revenue_Multipliers for coverage gaps when LTV values appear unexpectedly as 0.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production source wiki — passthrough column |
| Tier 2 | From ETL SP code, DWH dimension JOIN, or revenue model computation |
| Propagation | Canonical ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Primary join key to Dim_Customer. One row per customer in this table (the most recent 30-day milestone prediction). (Tier 1 — Customer.CustomerStatic) |
| 2 | FirstFundedMonth | date | YES | Month-end date of the customer's first new funded month: `EOMONTH(FirstNewFundedDate)`. Used as the cohort anchor for group-level LTV averaging and the volatility fix rolling window. NULL for customers without a FirstNewFundedDate (legacy depositors). (Tier 2 — SP_LTV_Multiplier_Model via BI_DB_CIDFirstDates.FirstNewFundedDate) |
| 3 | Seniority | int | YES | Months since the customer's first new funded date: `DATEDIFF(day, FirstNewFundedDate, @date) / 30`. Increments in steps of 1 on each 30-day milestone. Range: 1–164 months (earliest funded: 2012-10-31). Drives the multiplier model lookup and determines which LTV actuals are available. NULL for legacy depositors without FirstNewFundedDate. (Tier 2 — SP_LTV_Multiplier_Model) |
| 4 | Region | varchar(50) | YES | Marketing region label from `DWH_dbo.Dim_Country.Region`, sourced from `etoro.Dictionary.MarketingRegion.Name`. 21 distinct values (e.g., 'UK', 'German', 'French', 'Italian', 'USA', 'Eastern Europe', 'Crypto'). Used as a segmentation dimension in the LTV model and volatility fix. NOT the manual marketing override (MarketingRegionManualName). (Tier 2 — Dim_Country.Region via SP_Dictionaries_Country_DL_To_Synapse) |
| 5 | ClusterDetail | varchar(50) | YES | Behavioral cluster label from `BI_DB_CID_DailyCluster`, resolved at the run date. 7 values: 'Crypto', 'NoCluster', 'Equities Traders', 'Equities Crypto', 'Leveraged Traders', 'Equities Investors', 'Diversified Traders'. 'NoCluster' is the ISNULL fallback for customers with no active cluster. Segmentation dimension in the LTV model. (Tier 2 — BI_DB_CID_DailyCluster) |
| 6 | EquityTier | int | YES | Realized equity bucket from `DWH_dbo.Fact_SnapshotEquity`: 1 = <$100 or NULL, 2 = $100–$499, 3 = ≥$500. Distribution: Tier 1=66.9%, Tier 2=10.5%, Tier 3=22.4%, NULL=0.1%. Segmentation dimension in the LTV model and volatility fix. (Tier 2 — SP_LTV_Multiplier_Model via Fact_SnapshotEquity) |
| 7 | MonthsSinceLastPosOpen | int | YES | Months since the customer last opened a position in any asset: `DATEDIFF(day, MAX(Dim_Position.OpenOccurred), @date) / 30`, capped at Seniority. NULL for customers with no Dim_Position records. Used as the second lookup key in BI_DB_LTV_Revenue_Multipliers. (Tier 2 — SP_LTV_Multiplier_Model via DWH_dbo.Dim_Position) |
| 8 | Current_ACC_Revenue | decimal(12,2) | YES | Accumulated net revenue from first funded date to run date, with an early-seniority correction: Seniority=1 → ÷0.80, Seniority=2 → ÷0.90, Seniority=3 → ÷0.95, Seniority≥4 → raw. Sourced from BI_DB_CID_DailyPanel_FullData (recent customers) or BI_DB_CID_MonthlyPanel_FullData (older customers). The base value used to project all LTV horizons. (Tier 2 — SP_LTV_Multiplier_Model via BI_DB_CID_DailyPanel_FullData / BI_DB_CID_MonthlyPanel_FullData) |
| 9 | LTV_1Y | float | YES | Expected (or realized) total revenue at 12 months from first funding. **For Seniority ≥ 12**: replaced by actual accumulated revenue at the Seniority=12 snapshot from BI_DB_CID_MonthlyPanel_FullData. **For Seniority < 12**: `Current_ACC_Revenue / RatioSnapshotTo1Y` from BI_DB_LTV_Revenue_Multipliers. ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 10 | LTV_3Y | float | YES | Expected (or realized) total revenue at 36 months from first funding. Same hybrid predicted/actual logic as LTV_1Y, switching to actuals at Seniority=36. ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 11 | LTV_8Y | float | YES | Expected (or realized) total revenue at 96 months from first funding. Switches to actuals at Seniority=96. ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 12 | LTV_1Y_VolFix | float | YES | Volatility-adjusted 1-year LTV. `LTV_1Y × clamp([0.5, 2.0], MovingAvgLTV1Y_12mo / CurrentGroupAvgLTV1Y)`. Smooths cohort-specific model noise using a 12-month rolling window per group. The preferred 1Y LTV for downstream analytics. ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 13 | LTV_3Y_VolFix | float | YES | Volatility-adjusted 3-year LTV. Same formula as LTV_1Y_VolFix applied to the 3Y horizon. The preferred 3Y LTV for downstream analytics. ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 14 | LTV_8Y_VolFix | float | YES | Volatility-adjusted 8-year LTV. Same formula applied to the 8Y horizon. The preferred 8Y LTV for downstream analytics, and the input for LTV_8Y_GroupLevel. Note: as of 2023-12-18, LTV_8Y_GroupLevel now uses LTV_8Y_VolFix (not LTV_8Y). ISNULL coerced to 0. (Tier 2 — SP_LTV_Multiplier_Model) |
| 15 | LTV_8Y_GroupLevel | float | YES | Group-level average of LTV_8Y_VolFix for the customer's cohort (FirstFundedMonth × Region × ClusterDetail × EquityTier). Computed via post-INSERT UPDATE across the entire table. All customers in the same group share the same value. 0 where no group average is available (NULL). Used to compare a customer's LTV_8Y_VolFix against their cohort average. (Tier 2 — SP_LTV_Multiplier_Model post-INSERT UPDATE) |
| 16 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline (the customer's most recent 30-day milestone run). Not a global table freshness timestamp — each row reflects its own processing date. Range: 2023-08-07 to 2026-04-12. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | Via Dim_Customer.RealCID |
| Region | etoro.Dictionary.MarketingRegion | Name | Via Dim_Country.Region on CountryID |
| Seniority | BI_DB_CIDFirstDates | FirstNewFundedDate | DATEDIFF(day,...)/30 |
| FirstFundedMonth | BI_DB_CIDFirstDates | FirstNewFundedDate | EOMONTH() |
| ClusterDetail | BI_DB_CID_DailyCluster | ClusterDetail | Date-range JOIN |
| EquityTier | Fact_SnapshotEquity | RealizedEquity | CASE buckets: 1/<100, 2/100-499, 3/500+ |
| MonthsSinceLastPosOpen | DWH_dbo.Dim_Position | OpenOccurred | MAX DATEDIFF / 30, capped at Seniority |
| Current_ACC_Revenue | BI_DB_CID_DailyPanel_FullData / MonthlyPanel | Revenue_Total / ACC_Revenue_Total | Aggregation + Seniority correction factor |
| LTV_1Y/3Y/8Y | BI_DB_LTV_Revenue_Multipliers | RatioSnapshotTo_nY | Current_ACC_Revenue / ratio; replaced by actual at milestone |
| LTV_*_VolFix | BI_DB_LTV_Predictions (self) | LTV_nY (previous run) | × clamp([0.5,2.0], 12mo rolling avg / group avg) |
| LTV_8Y_GroupLevel | BI_DB_LTV_Predictions (self) | LTV_8Y_VolFix | AVG per group — post-INSERT UPDATE |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsDepositor=1, IsValidCustomer=1)
  + BI_DB_CIDFirstDates (FirstNewFundedDate → Seniority, FirstFundedMonth)
  + Dim_Country (CountryID → Region)
  + BI_DB_CID_DailyCluster (ClusterDetail at run date)
  + Fact_SnapshotEquity (RealizedEquity → EquityTier)
  + Dim_Position (last open → MonthsSinceLastPosOpen)
  + BI_DB_CID_DailyPanel_FullData / BI_DB_CID_MonthlyPanel_FullData (→ Current_ACC_Revenue)
  + BI_DB_LTV_Revenue_Multipliers (Seniority × MonthsSinceLastActive → ratios)
  + BI_DB_LTV_Predictions [self] (12-mo rolling group avg → VolFix)
         |-- SP_LTV_Multiplier_Model @date (daily) ---|
         |   DELETE CIDs at their 30-day milestone     |
         |   INSERT new predictions                    |
         |   UPDATE LTV_8Y_GroupLevel across all rows  |
         v
BI_DB_dbo.BI_DB_LTV_Predictions (~5.84M rows, accumulating)
  |-- (No UC target — Not Migrated) ---|
```

---

## 6. Relationships

### 6.1 References To (this object reads from)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer.RealCID | Customer eligibility and CountryID |
| Region | DWH_dbo.Dim_Country.Region | Marketing region label |
| EquityTier | DWH_dbo.Fact_SnapshotEquity | Realized equity source |
| MonthsSinceLastPosOpen | DWH_dbo.Dim_Position | Last open position date |
| Seniority, FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | First funded date anchor |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | Behavioral segment |
| Current_ACC_Revenue, actuals | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData, BI_DB_CID_MonthlyPanel_FullData | Revenue aggregates |
| LTV ratios | BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers | Multiplier matrix per (Seniority, MonthsSinceLastActive) |
| VolFix baseline | BI_DB_dbo.BI_DB_LTV_Predictions (self) | Previous run's group averages |

### 6.2 Referenced By (other objects read from this)

| Object | How Used |
|--------|----------|
| BI_DB_dbo.SP_LTV_Multiplier_Model | Self-reference: reads this table for #MovingAVGPerGroup volatility fix baseline |
| Acquisition / CRM / Finance dashboards | Primary source for CID-level LTV analytics and customer segmentation by predicted revenue |

---

## 7. Sample Queries

### 7.1 Top 20 highest-LTV customers (volatility-adjusted 8Y prediction)
```sql
SELECT TOP 20 RealCID, Region, ClusterDetail, EquityTier,
              Seniority, Current_ACC_Revenue,
              LTV_8Y_VolFix, LTV_8Y_GroupLevel
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions]
WHERE LTV_8Y_VolFix > 0
ORDER BY LTV_8Y_VolFix DESC;
```

### 7.2 Group-level average LTV by cluster and equity tier
```sql
SELECT ClusterDetail, EquityTier,
       COUNT(RealCID) AS Customers,
       AVG(LTV_8Y_VolFix) AS AvgLTV_8Y,
       SUM(LTV_8Y_VolFix) AS TotalLTV_8Y,
       AVG(Current_ACC_Revenue) AS AvgCurrentRevenue
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions]
WHERE EquityTier IS NOT NULL
  AND LTV_8Y_VolFix > 0
GROUP BY ClusterDetail, EquityTier
ORDER BY AvgLTV_8Y DESC;
```

### 7.3 Customer's LTV vs. their cohort group average
```sql
SELECT p.RealCID,
       p.Region, p.ClusterDetail, p.EquityTier,
       p.LTV_8Y_VolFix AS Customer_LTV_8Y,
       p.LTV_8Y_GroupLevel AS Cohort_Avg_LTV_8Y,
       p.LTV_8Y_VolFix - p.LTV_8Y_GroupLevel AS Delta_vs_Cohort
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions] p
WHERE p.RealCID = @cid;
```

### 7.4 LTV distribution by seniority band
```sql
SELECT Seniority / 12 AS YearsSinceFunded,
       COUNT(RealCID) AS Customers,
       AVG(LTV_8Y_VolFix) AS AvgLTV_8Y,
       AVG(Current_ACC_Revenue) AS AvgRevToDate
FROM [BI_DB_dbo].[BI_DB_LTV_Predictions]
WHERE Seniority IS NOT NULL
GROUP BY Seniority / 12
ORDER BY Seniority / 12;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this table.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Batch: 52*
*Tiers: 1 T1, 14 T2, 0 T3, 0 T4, 1 Propagation | Elements: 16/16, Logic: 5 subsections*
*Object: BI_DB_dbo.BI_DB_LTV_Predictions | Type: Table | Source: Customer.CustomerStatic + revenue panels + Revenue Multiplier model*
