# BI_DB_dbo.Group_LTV_Table

> Static 294-row group-level Lifetime Value lookup table providing cohort-average 8Y Revenue LTV predictions aggregated by first-month equity tier, first-month behavioral cluster, and marketing region. Population: depositors with FTD between January 2022 and June 2024 (Revenue8Y_LTV_New < $1M). Built once by SP_Group_LTV_Table (Jan Iablunovskey, 2024-10-21); on-demand refresh only.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Static lookup) |
| **Production Source** | BI_DB_LTV_BI_Actual (LTV predictions), BI_DB_CID_MonthlyPanel_FullData (first-month equity/cluster), Dim_Country (region), Dim_Customer (verification level) |
| **Refresh** | On-demand only; SP guard clause prevents daily execution (last run: 2024-10-30) |
| **Synapse Distribution** | HASH(Region) |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`Group_LTV_Table` is a static cohort-average LTV lookup table used in eToro's Lifetime Value modeling framework. It provides pre-computed group-level 8-year Revenue LTV predictions for every combination of three segmentation dimensions: first-month equity tier (1/2/3), first-month behavioral cluster (8 values), and marketing region (14 values).

The table was built as a one-time analytical artifact by Jan Iablunovskey (2024-10-21) using the population of depositors whose first deposit fell between January 2022 and June 2024, excluding extreme outliers with Revenue8Y_LTV_New ≥ $1M. Each row represents a unique (equity tier × cluster × region) cohort and stores the average LTV for that cohort along with the customer count.

The primary use case is providing group-level LTV supplements for customers with insufficient individual history — similar to the `LTV_8Y_GroupLevel` concept in `BI_DB_LTV_BI_Actual` but using a different (region-aware, first-month-anchored) segmentation scheme with region-specific equity tier overrides for Arabic, Latam, Spain, USA, and UK markets.

The table contains 294 rows (not all 336 possible combinations exist in the population). LTV values range from $1.10 to $13,744.14, with an average of $901. Client counts per group range from 1 to 31,973. All rows have UpdateDate = 2024-10-30.

---

## 2. Business Logic

### 2.1 First-Month Equity Tier — Region-Specific Bucketing

**What**: Assigns customers to equity tiers (1/2/3) based on their end-of-month equity at Seniority=1 (first funded month), with region-specific overrides that reclassify mid-equity customers into Tier 2 for selected region×cluster combinations.
**Columns Involved**: `First_Month_Equity_Tier`
**Rules**:
- Arabic region, any cluster, EOM_Equity < $500 → Tier 2 (override)
- Latam region, Crypto or Leveraged Traders cluster, EOM_Equity < $500 → Tier 2 (override)
- Spain region, Diversified Traders cluster, EOM_Equity < $500 → Tier 2 (override)
- USA region, Equities Traders cluster, EOM_Equity < $500 → Tier 2 (override)
- UK region, Diversified Traders cluster, EOM_Equity < $500 → Tier 2 (override)
- Otherwise: EOM_Equity < $100 or NULL → Tier 1; $100–$499 → Tier 2; ≥ $500 → Tier 3; else 0
- Distribution: Tier 1 = 90 rows, Tier 2 = 102 rows, Tier 3 = 102 rows

### 2.2 First-Month Cluster — Behavioral Classification at Seniority=1

**What**: Assigns customers to a behavioral cluster based on their first funded month's ClusterDetail from BI_DB_CID_MonthlyPanel_FullData, with fallback categories for unclustered customers.
**Columns Involved**: `First_Month_Cluster`
**Rules**:
- If ClusterDetail is not null at Seniority=1 → use ClusterDetail directly (e.g., Crypto, Equities Traders, Leveraged Traders)
- If ClusterDetail is null but FirstAction is not null AND VerificationLevelID=3 → 'No Cluster - Active'
- Otherwise → 'No Cluster - Inactive'
- 8 distinct values: Crypto, Diversified Traders, Equities Crypto, Equities Investors, Equities Traders, Leveraged Traders, No Cluster - Active, No Cluster - Inactive

### 2.3 Group LTV Computation

**What**: Computes cohort-average LTV by grouping the filtered population along three dimensions and taking AVG of the individual LTV predictions.
**Columns Involved**: `Revenue8Y_LTV_New_Group_LTV`, `Revenue8Y_LTV_NoExtreme_New_Group_LTV`, `Clients`
**Rules**:
- Population filter: FirstDepositDate between 2022-01-01 and 2024-06-30, Revenue8Y_LTV_New < $1,000,000
- Revenue8Y_LTV_New_Group_LTV = AVG(Revenue8Y_LTV_New) per (First_Month_Equity_Tier × First_Month_Cluster × Region)
- Revenue8Y_LTV_NoExtreme_New_Group_LTV = AVG(Revenue8Y_LTV_NoExtreme_New) per group
- Clients = COUNT(*) per group

### 2.4 SP Guard Clause — Static Table Protection

**What**: The SP contains a date guard that prevents execution after 2024-10-30.
**Columns Involved**: All
**Rules**:
- `IF CAST(GETDATE() AS DATE) <= '2024-10-30'` — SP body only executes within this window
- The table is TRUNCATE + INSERT on each SP run (full replace)
- Designed for on-demand refresh; the guard ensures no accidental daily execution

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(Region) on a HEAP — 294 rows. Trivial for any query pattern. The region-based hash means same-region rows are co-located, which is optimal for region-filtered lookups.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Group LTV for a specific region | `SELECT * FROM [BI_DB_dbo].[Group_LTV_Table] WHERE Region = 'UK' ORDER BY First_Month_Equity_Tier, First_Month_Cluster` |
| Highest-LTV cohort groups | `SELECT TOP 20 * FROM [BI_DB_dbo].[Group_LTV_Table] ORDER BY Revenue8Y_LTV_New_Group_LTV DESC` |
| Average LTV by equity tier | `SELECT First_Month_Equity_Tier, AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_group_ltv, SUM(Clients) AS total_clients FROM [BI_DB_dbo].[Group_LTV_Table] GROUP BY First_Month_Equity_Tier` |
| Compare with/without extreme exclusion | `SELECT *, CAST(Revenue8Y_LTV_New_Group_LTV - Revenue8Y_LTV_NoExtreme_New_Group_LTV AS float) AS extreme_impact FROM [BI_DB_dbo].[Group_LTV_Table] ORDER BY extreme_impact DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual | Match on First_Month_Equity_Tier, First_Month_Cluster, NewMarketingRegion=Region | Assign group LTV to individual customers |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Match on ClusterDetail, NewMarketingRegion, equity tier logic | Cross-reference monthly panel attributes |

### 3.4 Gotchas

- **Static table**: All 294 rows have UpdateDate = 2024-10-30. This table is NOT refreshed daily. The SP guard prevents execution after that date. Values reflect the Jan 2022–Jun 2024 cohort only.
- **First_Month_Equity_Tier is nvarchar(300)**: Despite storing integer values (1/2/3), the column is nvarchar(300). Cast to INT for numeric operations or ordering.
- **Region-specific equity tier overrides**: Tier 2 can include customers with equity < $500 (not just $100–$500) for Arabic, Latam (Crypto/Leveraged), Spain (Diversified), USA (Equities Traders), and UK (Diversified) cohorts. The tier boundaries are NOT uniform across regions.
- **Not all combinations exist**: 294 of 336 possible (3 × 8 × 14) combinations are present. Missing combinations had zero qualifying customers in the population window.
- **Revenue8Y_LTV_New_Group_LTV vs BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New_Group_LTV**: Different computation. This table uses first-month-anchored segmentation with region-specific overrides; BI_DB_LTV_BI_Actual uses (FirstFundedMonth × NewMarketingRegion × ClusterDetail × EquityTier) without region-specific tier overrides.
- **Outlier exclusion**: Population excludes customers with Revenue8Y_LTV_New ≥ $1M. This affects high-LTV cohort averages.
- **'Unknown' region**: 1 row with Region='Unknown' — customers whose country had no MarketingRegionManualName mapping.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code, data sampling, or ETL logic |
| P | Propagation metadata (ETL timestamp) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | First_Month_Equity_Tier | nvarchar(300) | YES | Customer equity tier (1/2/3) assigned during their first funded month (Seniority=1), with region-specific overrides. Tier 1: EOM_Equity < $100 or NULL. Tier 2: $100–$500 (or < $500 for Arabic, Latam Crypto/Leveraged, Spain Diversified, USA Equities Traders, UK Diversified). Tier 3: ≥ $500. Stored as nvarchar despite integer values. 3 distinct values across 294 rows. (Tier 2 — BI_DB_CID_MonthlyPanel_FullData / Dim_Country) |
| 2 | First_Month_Cluster | nvarchar(300) | YES | Customer behavioral cluster during their first funded month. Uses ClusterDetail from BI_DB_CID_MonthlyPanel_FullData at Seniority=1; falls back to 'No Cluster - Active' (FirstAction not null and VerificationLevelID=3) or 'No Cluster - Inactive'. 8 distinct values: Crypto, Diversified Traders, Equities Crypto, Equities Investors, Equities Traders, Leveraged Traders, No Cluster - Active, No Cluster - Inactive. (Tier 2 — BI_DB_CID_MonthlyPanel_FullData / Dim_Customer) |
| 3 | Region | nvarchar(300) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName (renamed via NewMarketingRegion → Region). 14 distinct values: Australia, Nordics, ROW, French, German, Italian, CEE, SEA, Spain, UK, Latam, USA, Arabic, Unknown. HASH distribution key. (Tier 1 — Ext_Dim_Country) |
| 4 | Revenue8Y_LTV_New_Group_LTV | money | YES | Group-average 8-year Revenue LTV prediction (new methodology, with outliers included). AVG(Revenue8Y_LTV_New) across all customers in the same (First_Month_Equity_Tier × First_Month_Cluster × Region) cohort. Population: FTD Jan 2022–Jun 2024, Revenue8Y_LTV_New < $1M. Range: $1.10–$13,744.14; average $901. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 5 | Revenue8Y_LTV_NoExtreme_New_Group_LTV | money | YES | Group-average 8-year Revenue LTV prediction with statistical outliers excluded from the individual predictions before averaging. AVG(Revenue8Y_LTV_NoExtreme_New) per cohort group. Conservative lower bound. Range: $1.10–$9,225.47. (Tier 2 — BI_DB_LTV_BI_Actual) |
| 6 | Clients | int | YES | Number of customers in this cohort group used to compute the group-average LTV. COUNT(*) per (First_Month_Equity_Tier × First_Month_Cluster × Region). Range: 1–31,973; average 4,355. Higher client counts indicate more statistically reliable group LTV estimates. (Tier 2 — SP_Group_LTV_Table) |
| 7 | UpdateDate | date | NOT NULL | ETL metadata: date when SP_Group_LTV_Table last populated this row. All rows = 2024-10-30 (static table). (P) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| First_Month_Equity_Tier | BI_DB_CID_MonthlyPanel_FullData / Dim_Country | EOM_Equity, ClusterDetail, MarketingRegionManualName | CASE: region-specific equity tier bucketing at Seniority=1 |
| First_Month_Cluster | BI_DB_CID_MonthlyPanel_FullData / Dim_Customer | ClusterDetail, FirstAction, VerificationLevelID | CASE: cluster assignment with fallback for unclustered |
| Region | Dim_Country | MarketingRegionManualName | Rename passthrough via GROUP BY |
| Revenue8Y_LTV_New_Group_LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New | AVG() per cohort group |
| Revenue8Y_LTV_NoExtreme_New_Group_LTV | BI_DB_LTV_BI_Actual | Revenue8Y_LTV_NoExtreme_New | AVG() per cohort group |
| Clients | — | — | COUNT(*) per cohort group |
| UpdateDate | — | — | GETDATE() at SP execution |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_LTV_BI_Actual (5.84M rows, CID, Revenue8Y_LTV_New, Revenue8Y_LTV_NoExtreme_New)
  + DWH_dbo.Dim_Customer (GCID, CountryID, VerificationLevelID)
  + DWH_dbo.Dim_Country (MarketingRegionManualName)
  + BI_DB_dbo.BI_DB_CIDFirstDates (GCID join)
  + BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (EOM_Equity, ClusterDetail, FirstAction at Seniority=1)
    |
    |-- Filter: FTD 2022-01 to 2024-06, Revenue8Y_LTV_New < $1M
    |-- Compute: First_Month_Equity_Tier (region-specific CASE), First_Month_Cluster (CASE)
    |-- #Temp1 (per-customer with computed tiers)
    |
    |-- GROUP BY (First_Month_Equity_Tier, First_Month_Cluster, Region)
    |-- AVG(Revenue8Y_LTV_New), AVG(Revenue8Y_LTV_NoExtreme_New), COUNT(*)
    |-- #GLTV_Model (294 cohort groups)
    |
    |-- SP_Group_LTV_Table (TRUNCATE + INSERT, on-demand, guard: <= 2024-10-30)
    v
  BI_DB_dbo.Group_LTV_Table (294 rows, HEAP, HASH(Region))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Region | DWH_dbo.Dim_Country.MarketingRegionManualName | Marketing region classification |
| First_Month_Equity_Tier | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData.EOM_Equity | Equity tier derived from first-month equity |
| First_Month_Cluster | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData.ClusterDetail | Behavioral cluster from first funded month |
| Revenue8Y_LTV_New_Group_LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual.Revenue8Y_LTV_New | Source of individual LTV predictions averaged into group LTV |
| Revenue8Y_LTV_NoExtreme_New_Group_LTV | BI_DB_dbo.BI_DB_LTV_BI_Actual.Revenue8Y_LTV_NoExtreme_New | Source of outlier-excluded individual LTV predictions |

### 6.2 Referenced By (other objects point to this)

| Object | How Used |
|--------|----------|
| BI_DB_dbo.BI_DB_LTV_BI_Actual (potential) | Group LTV lookup for customers needing cohort-level LTV supplement |

---

## 7. Sample Queries

### Group LTV by equity tier

```sql
SELECT
    First_Month_Equity_Tier,
    COUNT(*) AS group_count,
    SUM(Clients) AS total_clients,
    AVG(CAST(Revenue8Y_LTV_New_Group_LTV AS float)) AS avg_group_ltv,
    AVG(CAST(Revenue8Y_LTV_NoExtreme_New_Group_LTV AS float)) AS avg_group_ltv_noextreme
FROM [BI_DB_dbo].[Group_LTV_Table]
GROUP BY First_Month_Equity_Tier
ORDER BY CAST(First_Month_Equity_Tier AS int);
```

### Top cohort groups by LTV

```sql
SELECT TOP 20
    First_Month_Equity_Tier,
    First_Month_Cluster,
    Region,
    Revenue8Y_LTV_New_Group_LTV,
    Revenue8Y_LTV_NoExtreme_New_Group_LTV,
    Clients
FROM [BI_DB_dbo].[Group_LTV_Table]
WHERE Clients >= 100
ORDER BY Revenue8Y_LTV_New_Group_LTV DESC;
```

### Region-level LTV summary (weighted by client count)

```sql
SELECT
    Region,
    SUM(Clients) AS total_clients,
    SUM(CAST(Revenue8Y_LTV_New_Group_LTV AS float) * Clients) / SUM(Clients) AS weighted_avg_ltv
FROM [BI_DB_dbo].[Group_LTV_Table]
GROUP BY Region
ORDER BY weighted_avg_ltv DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP author: Jan Iablunovskey (2024-10-21). Related LTV model documentation available in sibling wikis: BI_DB_LTV_BI_Actual (LTV variant descriptions and model framework).

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 1 T1, 5 T2, 0 T3, 0 T4, 1 P | Elements: 7/7, Logic: 9/10, Data Evidence: 9/10*
*Object: BI_DB_dbo.Group_LTV_Table | Type: Table | Production Source: BI_DB_LTV_BI_Actual + BI_DB_CID_MonthlyPanel_FullData + Dim_Country + Dim_Customer via SP_Group_LTV_Table*
