# BI_DB_dbo.BI_DB_LTV_BI_Actual

> Canonical customer-level Lifetime Value (LTV) output table. One row per depositor (~5.84M rows); consolidates three LTV model families: (1) multiplier-model predictions at 1Y/3Y/8Y horizons with volatility smoothing, (2) new-methodology 8Y Revenue LTV variants (with/without group supplement and outlier exclusion), and (3) behavioral segmentation inputs (cluster, equity tier, seniority). Refreshed daily by SP_LTV_BI_Actual (P0, SB_Daily). Primary upstream of BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B row archive) and LTV_FromDB_ToBigQuery export.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_LTV_Predictions, BI_DB_CIDFirstDates, BI_DB_CID_DailyCluster, Fact_SnapshotEquity, Revenue8Y model |
| **Refresh** | Daily; SP_LTV_BI_Actual, Priority 0, SB_Daily process (full replace) |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_LTV_BI_Actual` is eToro's central Lifetime Value prediction store. It holds a current-state snapshot of every depositor's expected cumulative revenue across 1-, 3-, and 8-year horizons, updated daily. Each row represents one customer; the 5.84M rows cover all customers with a FirstDepositDate from 2007 to 2026-03.

The table consolidates two LTV model families:

**1. Multiplier-model predictions** (LTV_1Y/3Y/8Y, VolFix variants, GroupLevel) — from the `SP_LTV_Multiplier_Model` framework (documented in `BI_DB_LTV_Predictions`). These predict LTV by applying revenue multipliers to Current_ACC_Revenue based on the customer's seniority and cohort. Once a customer actually reaches a horizon (Seniority ≥ 12/36/96 months), the prediction column is replaced by the actual accumulated revenue — making these hybrid predicted/actual fields.

**2. Revenue8Y new-methodology predictions** (Revenue8Y_LTV_New and 6 variants) — a newer 2023+ model that produces additional 8Y predictions with group-level supplements and outlier filtering. Revenue8Y_LTV_New_Group_LTV is the recommended primary LTV signal for most downstream analytics.

The table also stores behavioural segmentation attributes (ClusterDetail, EquityTier, Seniority, MonthsSinceLastPosOpen) which are inputs to both LTV model families and enable cohort analysis without additional joins.

**Key downstream consumers**:
- `BI_DB_LTV_BI_Actual_Daily_Snapshot` (SP_D_LTV_BI_Actual_Snapshot, P20): daily timestamped archive (4.54B rows, 865 snapshots, 2023–present)
- `LTV_FromDB_ToBigQuery` (SP_LTV_FromDB_ToBigQuery): BigQuery export for marketing and growth analytics
- 13 total confirmed downstream dependents in BI_DB_dbo

---

## 2. Business Logic

### 2.1 LTV Horizon Family: Predicted vs. Actual Crossover

**What**: LTV_1Y/3Y/8Y are hybrid fields that hold predictions until the customer reaches the milestone, then switch to actuals.
**Columns Involved**: `LTV_1Y`, `LTV_3Y`, `LTV_8Y`, `Seniority`
**Rules**:
- Seniority < 12 months: `LTV_1Y` = multiplier-model prediction of 1Y revenue
- Seniority ≥ 12 months: `LTV_1Y` = actual accumulated revenue at month 12 from BI_DB_CID_MonthlyPanel_FullData
- Same crossover at Seniority ≥ 36 for LTV_3Y, and Seniority ≥ 96 for LTV_8Y
- Implication: querying LTV_1Y for customers with Seniority ≥ 12 returns realized revenue, NOT a forward prediction

### 2.2 Volatility Fix Variants (VolFix)

**What**: LTV_*_VolFix apply a 12-month rolling group average multiplier to smooth cohort-specific noise.
**Columns Involved**: `LTV_1Y_VolFix`, `LTV_3Y_VolFix`, `LTV_8Y_VolFix`
**Rules**:
- Group definition: (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier)
- Smoothing: `LTV_nY_VolFix = LTV_nY × (rolling_group_avg / current_group_avg)`, clamped to [0.5, 2.0]
- VolFix variants are the **preferred LTV values** for downstream revenue modelling — less sensitive to cohort-specific noise than raw predictions
- LTV_8Y_VolFix is the base for the group-level computation (LTV_8Y_GroupLevel)

### 2.3 Group Level LTV

**What**: LTV_8Y_GroupLevel assigns a cohort-average LTV to each customer — useful for thin-history customers.
**Columns Involved**: `LTV_8Y_GroupLevel`
**Rules**:
- = AVG(LTV_8Y_VolFix) across all customers in the same (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) cohort
- Computed via post-INSERT UPDATE across the entire table
- All customers in the same cohort share the identical LTV_8Y_GroupLevel value
- For inactive customers with low Current_ACC_Revenue, LTV_8Y_GroupLevel > Revenue8Y_LTV_New (cohort median > individual zero-revenue estimate)
- **Do not** use as an upper bound for individual predictions — it reflects group median, not potential

### 2.4 Revenue8Y New-Methodology Variants

**What**: Six Revenue8Y variants from the 2023+ model, combining outlier exclusion and group supplement dimensions.
**Columns Involved**: `Revenue8Y_LTV_New`, `Revenue8Y_LTV_NoExtreme_New`, `Revenue8Y_LTV_New_WO_Group_LTV`, `Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV`, `Revenue8Y_LTV_New_Group_LTV`, `Revenue8Y_LTV_NoExtreme_New_Group_LTV`

| Variant | Outliers | Group Supplement | Recommended Use |
|---------|---------|-----------------|-----------------|
| Revenue8Y_LTV_New | Included | No | Individual prediction baseline |
| Revenue8Y_LTV_NoExtreme_New | Excluded | No | Conservative individual |
| Revenue8Y_LTV_New_WO_Group_LTV | Included | No (explicit 0) | Pure individual analysis |
| Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | Excluded | No (explicit 0) | Most conservative individual |
| **Revenue8Y_LTV_New_Group_LTV** | Included | **Yes** | **Recommended for most use cases** |
| Revenue8Y_LTV_NoExtreme_New_Group_LTV | Excluded | Yes | Conservative blended |

- `_WO_Group_LTV` (without group LTV) variants are **0** (not NULL) where group-level assignment was applied — sum-aggregations undercount unless using `_Group_LTV` variants
- `Revenue8Y_LTV_All_Conv_Old`: legacy pre-2023 model; retained for historical comparison only

### 2.5 EquityTier Segmentation

**What**: Integer tier based on current realized equity balance.
**Columns Involved**: `EquityTier`
**Rules**:
- Tier 1: RealizedEquity < $100 OR NULL/missing — low equity / new / inactive (67% of rows)
- Tier 2: $100 ≤ RealizedEquity < $500 — medium equity (10%)
- Tier 3: RealizedEquity ≥ $500 — high equity (22%)
- NULL (~8K rows, <0.2%) — no matching Fact_SnapshotEquity row found
- Source: DWH_dbo.Fact_SnapshotEquity (via BI_DB_LTV_Predictions logic)

---

## 3. Query Advisory

### 3.1 Distribution & Index

`HASH(CID)` on a HEAP — no clustered index. Fast for customer-keyed lookups and full scans (5.84M rows is small enough for analytical aggregations). For large-scale aggregations without a CID filter, performance is still acceptable given the row count.

### 3.2 LTV Variant Selection Guide

| Use Case | Recommended Column |
|----------|-------------------|
| Primary 8Y LTV for all downstream | `Revenue8Y_LTV_New_Group_LTV` |
| Conservative 8Y (exclude outliers, blended) | `Revenue8Y_LTV_NoExtreme_New_Group_LTV` |
| Pure individual prediction (no group fallback) | `Revenue8Y_LTV_New` |
| Multiplier-model 8Y (volatility smoothed) | `LTV_8Y_VolFix` |
| Group-benchmark comparison | `LTV_8Y_GroupLevel` |
| Legacy compatibility | `Revenue8Y_LTV_All_Conv_Old` |

### 3.3 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Average LTV by region and cluster | `SELECT NewMarketingRegion, ClusterDetail, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] WHERE EquityTier = 3 GROUP BY NewMarketingRegion, ClusterDetail ORDER BY AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) DESC` |
| Top 1000 highest LTV customers | `SELECT TOP 1000 CID, Revenue8Y_LTV_New_Group_LTV, ClusterDetail, EquityTier FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] ORDER BY Revenue8Y_LTV_New_Group_LTV DESC` |
| LTV by cohort (first funded month) | `SELECT FirstFundedMonth, COUNT(*) AS cohort_size, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] GROUP BY FirstFundedMonth ORDER BY FirstFundedMonth` |
| Active vs inactive customer LTV | `SELECT CASE WHEN MonthsSinceLastPosOpen = 0 THEN 'Active' ELSE 'Inactive' END AS status, COUNT(*) AS cnt, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual] GROUP BY CASE WHEN MonthsSinceLastPosOpen = 0 THEN 'Active' ELSE 'Inactive' END` |

### 3.4 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `l.CID = dc.RealCID` | Customer demographics (country, registration date) |
| BI_DB_dbo.BI_DB_LTV_BI_Actual_Daily_Snapshot | `l.CID = s.CID AND s.SnapshotDate = @date` | Point-in-time LTV from any past date |
| BI_DB_dbo.BI_DB_LTV_Predictions | `l.CID = p.RealCID` | Cross-validate multiplier-model vs Revenue8Y predictions |

### 3.5 Gotchas

- **LTV_1Y/3Y/8Y switch to actuals at Seniority milestones** — these are NOT forward predictions for customers with Seniority ≥ 12/36/96. For pure forward prediction, use Revenue8Y_LTV_New_Group_LTV.
- **WO_Group_LTV = 0, not NULL** — where group LTV was applied, the WO_Group_LTV variants are 0. SUM(Revenue8Y_LTV_New_WO_Group_LTV) undercounts. Use Revenue8Y_LTV_New_Group_LTV for complete aggregations.
- **Currency = 'Non_USD' / 'USD'** — binary classification, NOT the actual account currency code. Do not use for currency conversion or forex analysis.
- **13% zero LTV_8Y rows** — 742K customers have LTV_8Y = 0 (no prediction generated). These are typically inactive or very recently registered customers. Filter WHERE LTV_8Y > 0 for revenue modelling.
- **HEAP** — no clustered index. Large aggregations without a CID predicate do full scans; acceptable at 5.84M rows but be aware.
- **SP code inaccessible** — SP_LTV_BI_Actual has empty sys.sql_modules definition; some column descriptions are inferred from sibling wikis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from sibling BI_DB_dbo wikis, data sampling, or naming conventions |
| Tier 3 | Inferred from naming conventions or context only |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within eToro DB. NOT NULL; hash distribution key. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NOT NULL. (Tier 1 — Customer.CustomerStatic) |
| 3 | NewMarketingRegion | varchar(50) | YES | Marketing region label. Matches Region in BI_DB_LTV_Predictions (DWH_dbo.Dim_Country.Region via Dictionary.MarketingRegion). Examples: UK (19%), German (15%), French (10%), CEE (8%), Italian (7%), USA (7%). Used as cohort dimension in LTV grouping. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 4 | FirstDepositDate | date | YES | Date of customer's first deposit. Range: 2007-08-29 to 2026-03-12. NULL for customers without deposit. (Tier 2 — BI_DB_CIDFirstDates context + data evidence) |
| 5 | FirstFundedMonth | date | YES | Month-end date of the customer's first funded month: EOMONTH(FirstNewFundedDate). Cohort anchor for group-level LTV averaging and VolFix rolling window. NULL for customers without FirstNewFundedDate (legacy depositors). (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 6 | Seniority | int | YES | Months from FirstFundedMonth to the current SP run date. Key LTV model input. Avg 57 months (4.8 years); max 164 months (13.7 years). Drives the predicted-vs-actual crossover at 12/36/96 months. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 7 | ClusterDetail | varchar(100) | YES | Customer behavioral cluster at the SP run date, from BI_DB_CID_DailyCluster. 7 values: Crypto (26%), Equities Traders (16%), Equities Crypto (14%), NoCluster (18%), Leveraged Traders (11%), Equities Investors (9%), Diversified Traders (6%). LTV model segmentation dimension. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 8 | EquityTier | int | YES | Equity tier from most recent Fact_SnapshotEquity: 1=RealizedEquity<$100 (67%), 2=$100-$500 (10%), 3=≥$500 (22%). NULL for <0.2% where no equity snapshot exists. LTV model segmentation dimension. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 9 | MonthsSinceLastPosOpen | int | YES | Months since this customer last opened a trading position. Inactivity indicator. Avg 37 months; value = 0 for currently active customers. Used in LTV model as recency signal. (Tier 2 — naming + data evidence) |
| 10 | Current_ACC_Revenue | numeric(38,2) | YES | Cumulative revenue this customer has generated for eToro to date. The base value for multiplier-model LTV calculation: LTV_nY = Current_ACC_Revenue / RatioSnapshotTo_nY. Adjusted for underestimation at low seniority (Seniority=1→÷0.80, Seniority=2→÷0.90, Seniority=3→÷0.95). (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 11 | DaysFromFTD | int | YES | Days from FirstDepositDate to the SP run date. Parallel to Seniority (which is in months from funded date); this is in calendar days from first deposit. Avg 1,809 days (~5 years). (Tier 2 — naming + data evidence) |
| 12 | LTV_1Y | money | YES | 1-year LTV: predicted cumulative broker revenue at 12 months from first funding. Switches to actual revenue at month 12 once Seniority ≥ 12. Pre-milestone: multiplier-model prediction. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 13 | LTV_3Y | money | YES | 3-year LTV: same hybrid predicted/actual pattern, crossover at Seniority ≥ 36 months. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 14 | LTV_8Y | money | YES | 8-year LTV: crossover at Seniority ≥ 96 months. Avg $1,266; max $46.5M; 13% zero. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 15 | LTV_1Y_VolFix | money | YES | 1Y LTV with 12-month rolling group average volatility smoothing. Clamped to [0.5, 2.0] × LTV_1Y. Preferred for revenue modelling. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 16 | LTV_3Y_VolFix | money | YES | 3Y LTV with volatility smoothing. Same clamping logic as LTV_1Y_VolFix. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 17 | LTV_8Y_VolFix | money | YES | 8Y LTV with volatility smoothing. **Preferred multiplier-model variant** for downstream analytics. Base for LTV_8Y_GroupLevel computation. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 18 | LTV_8Y_GroupLevel | money | YES | Post-INSERT group average: AVG(LTV_8Y_VolFix) across all customers in the same (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) cohort. All cohort members share the same value. Better for inactive/new customers where individual history is thin. (Tier 2 — BI_DB_LTV_Predictions wiki) |
| 19 | Revenue8Y_LTV_New | money | YES | 8-year cumulative broker revenue prediction, new methodology (2023+). Individual prediction only — may be low for inactive customers. See Section 2.4 for variant selection guide. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 20 | Revenue8Y_LTV_NoExtreme_New | money | YES | 8Y LTV (new methodology) with statistical outliers excluded. Conservative lower bound for individual planning. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 21 | UpdateDate | datetime | NO | ETL metadata: timestamp when SP_LTV_BI_Actual last calculated this customer's LTV. NOT NULL. Note: In BI_DB_LTV_BI_Actual_Daily_Snapshot, this column reflects the LTV model refresh time, not the snapshot time — use Snapshot_UpdateDate there. (P) |
| 22 | Revenue8Y_LTV_New_WO_Group_LTV | money | YES | Individual 8Y LTV without group-level supplement. **Zero** (not NULL) where group-level assignment was applied. Use Revenue8Y_LTV_New_Group_LTV for complete aggregations. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 23 | Revenue8Y_LTV_NoExtreme_New_WO_Group_LTV | money | YES | Outlier-trimmed individual 8Y LTV without group supplement. Most conservative individual estimate. Zero where group LTV applied. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 24 | First_Month_Equity_Tier | int | YES | Customer's equity tier (1/2/3) during their first funded month. Frozen at cohort entry for cohort stability. Distribution: Tier 1 (35%), Tier 2 (28%), Tier 3 (37%). (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 25 | First_Month_Cluster | varchar(100) | YES | Customer's behavioral cluster in their first funded month. Frozen at cohort entry. Enables first-month cohort analysis alongside current ClusterDetail. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 26 | Currency | varchar(300) | YES | Customer account currency classification. Binary values: 'Non_USD' (~67%), 'USD' (~32%), '' empty (~1%). Does NOT store the actual currency code — is a USD vs. non-USD flag used in LTV model calibration. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 27 | Revenue_Change_Percentage_Fixed | float | YES | Fixed calibration multiplier applied to base LTV prediction to adjust for known revenue projection bias. Small positive value (~0.02–0.05 observed). (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 28 | Revenue8Y_LTV_New_Group_LTV | money | YES | Blended 8Y LTV: individual prediction where history is sufficient; group-level supplement applied otherwise. **Recommended for most downstream use cases.** (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 29 | Revenue8Y_LTV_NoExtreme_New_Group_LTV | money | YES | Blended 8Y LTV without outliers. Conservative version of Revenue8Y_LTV_New_Group_LTV. (Tier 2 — BI_DB_LTV_BI_Actual_Daily_Snapshot wiki) |
| 30 | Revenue8Y_LTV_All_Conv_Old | money | YES | Legacy 8Y LTV prediction from pre-2023 methodology. Retained for historical comparison only; not recommended for new analyses. (Tier 2 — naming + data evidence) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID | Passthrough |
| GCID | Customer.CustomerStatic | GCID | Passthrough |
| NewMarketingRegion | DWH_dbo.Dim_Country | Region | Via Dictionary.MarketingRegion |
| FirstDepositDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | Passthrough |
| FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | FirstNewFundedDate | EOMONTH() |
| Seniority | BI_DB_dbo.BI_DB_CIDFirstDates | FirstFundedMonth | Months to run date |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | ClusterDetail | Date-range JOIN |
| EquityTier | DWH_dbo.Fact_SnapshotEquity | RealizedEquity | Tier bucketing |
| MonthsSinceLastPosOpen | DWH positions data | last position date | Months elapsed |
| Current_ACC_Revenue | Revenue aggregation source | cumulative revenue | With seniority correction |
| LTV_1Y/3Y/8Y | BI_DB_LTV_Predictions / actuals | LTV columns | Hybrid predicted/actual |
| LTV_*_VolFix | BI_DB_LTV_Predictions | LTV_*_VolFix | With rolling avg smoothing |
| LTV_8Y_GroupLevel | BI_DB_LTV_Predictions | LTV_8Y_VolFix | Post-INSERT group AVG |
| Revenue8Y_LTV_* | Revenue8Y model (new 2023+) | — | Various blending/filtering |
| UpdateDate | ETL pipeline | — | SP run timestamp |

### 5.2 ETL Pipeline

```
BI_DB_CIDFirstDates (Seniority, FirstFundedMonth, FirstDepositDate)
BI_DB_CID_DailyCluster (ClusterDetail)
Fact_SnapshotEquity (EquityTier)
BI_DB_LTV_Predictions (LTV_1Y/3Y/8Y/VolFix)
Revenue8Y model (Revenue8Y_LTV_New variants)
  |-- SP_LTV_BI_Actual (Daily, SB_Daily, Priority 0 — full table replace) ---|
  v
BI_DB_dbo.BI_DB_LTV_BI_Actual (5.84M rows, HEAP, HASH(CID))
  |-- SP_D_LTV_BI_Actual_Snapshot (P20) → BI_DB_LTV_BI_Actual_Daily_Snapshot (4.54B rows)
  |-- SP_LTV_FromDB_ToBigQuery → LTV_FromDB_ToBigQuery (BigQuery export)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | Customer.CustomerStatic (CID) | Customer reference |
| GCID | Customer.CustomerStatic (GCID) | Global customer reference |
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer demographics |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | Behavioral cluster source |
| Seniority/FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates | Customer lifecycle dates |
| LTV_1Y/3Y/8Y/VolFix | BI_DB_dbo.BI_DB_LTV_Predictions | Multiplier-model LTV source |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual_Daily_Snapshot | Daily timestamped archive — SP_D_LTV_BI_Actual_Snapshot reads current state |
| BI_DB_dbo.LTV_FromDB_ToBigQuery | BigQuery export — SP_LTV_FromDB_ToBigQuery reads for external analytics |
| (11 additional downstream BI_DB_dbo objects) | Various LTV-derived reports and models |

---

## 7. Sample Queries

### Top 10 LTV customers by blended 8Y prediction

```sql
SELECT TOP 10
    CID,
    NewMarketingRegion,
    ClusterDetail,
    EquityTier,
    Seniority,
    Revenue8Y_LTV_New_Group_LTV AS ltv_8y_blended,
    LTV_8Y_VolFix AS ltv_8y_vol_fixed
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE Revenue8Y_LTV_New_Group_LTV > 0
ORDER BY Revenue8Y_LTV_New_Group_LTV DESC;
```

### Average LTV by region × cluster × equity tier

```sql
SELECT
    NewMarketingRegion,
    ClusterDetail,
    EquityTier,
    COUNT(*) AS customer_count,
    AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv_8y,
    SUM(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS total_ltv_8y
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE Revenue8Y_LTV_New_Group_LTV > 0
GROUP BY NewMarketingRegion, ClusterDetail, EquityTier
ORDER BY avg_ltv_8y DESC;
```

### LTV distribution by cohort (first funded month, recent)

```sql
SELECT
    FirstFundedMonth,
    COUNT(*) AS cohort_size,
    AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_ltv_8y,
    AVG(CAST(LTV_8Y_VolFix AS float)) AS avg_ltv_8y_volfix
FROM [BI_DB_dbo].[BI_DB_LTV_BI_Actual]
WHERE FirstFundedMonth >= '2024-01-01'
GROUP BY FirstFundedMonth
ORDER BY FirstFundedMonth;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP_LTV_BI_Actual author details unavailable. LTV model documentation available from sibling wikis: BI_DB_LTV_Predictions (multiplier model logic) and BI_DB_LTV_BI_Actual_Daily_Snapshot (LTV variant descriptions, authored Jan Iablunovskey 2023-09-07).

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 2 T1, 28 T2, 0 T3, 0 T4, 1 P (counted once for UpdateDate) | Elements: 30/30, Logic: 9/10, Data Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_LTV_BI_Actual | Type: Table | Production Source: BI_DB_LTV_Predictions + Revenue8Y model + segmentation inputs via SP_LTV_BI_Actual*
