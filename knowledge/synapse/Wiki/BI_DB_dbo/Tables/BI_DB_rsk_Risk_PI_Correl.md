# BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl

> 35.4M-row pairwise correlation matrix for top Popular Investors (PIs) and Smart Portfolios, storing covariance, Pearson correlation, AUM, risk (STD), and copier counts for every PI pair. Built daily by SP_rsk_RiskCorelation_PIs using instrument covariance from Dim_Instrument_Correlation and NOP weights from BI_DB_rsk_Portfolio. Data from April 2024 to present with 2-year rolling retention.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_rsk_RiskCorelation_PIs (BI_DB_dbo) — Bar Arian 2024-02-14 |
| **Refresh** | Daily — DELETE+INSERT by Date (+ purge >2 years old) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_risk_pi_correl` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export |

---

## 1. Business Meaning

This table provides the daily pairwise correlation matrix for the top ~100-200 Popular Investors (PIs) and Smart Portfolios by AUM or effective copiers. Each row represents one ordered pair (PI1, PI2) on a given date, with the Pearson correlation coefficient computed from their portfolio covariance using instrument-level NOP weights.

The population is the union of top 100 PIs by AUM and top 100 by eCopiers (effective copiers with equity >= $100), partitioned by type (Regular vs Copyfund). For ~200 PIs, this generates up to ~40,000 pairs per day. With ~730 days of data (2-year rolling retention), the table holds approximately 35.4M rows.

This data powers the Risk Dashboard's correlation heatmap, enabling risk managers to identify concentrated portfolio overlap between high-AUM PIs. A high Pearson correlation between two popular PIs means their copiers have similar exposure profiles, amplifying platform-wide systemic risk if both PIs suffer losses simultaneously.

---

## 2. Business Logic

### 2.1 PI Population Selection

**What**: Selects top PIs by AUM or effective copier count, partitioned by copy type.
**Columns Involved**: CID1, CID2, rn_AUM, rn_eCopiers, Type
**Rules**:
- Source: etoroGeneral_History_GuruCopiers (daily snapshot)
- Child filter: IsDepositor=1, IsValidCustomer=1
- eCopiers: copiers with equity >= $100 (Cash + Investment + PnL)
- AUM: Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL
- ROW_NUMBER partitioned by Type (Regular/Copyfund), ordered by AUM or eCopiers DESC
- Include PIs where rn_AUM <= 100 OR rn_eCopiers <= 100
- Additional STD filter: only PIs where RealizedEquity > 0

### 2.2 Covariance Computation

**What**: Pairwise portfolio covariance using instrument-level NOP weights.
**Columns Involved**: COV
**Rules**:
- NOP weights from BI_DB_rsk_Portfolio: Weight = SUM(Net_USD_Vol) / RealizedEquity
- Covariance: SUM(Instrument_Covariance × Weight1_PI1 × Weight2_PI2) across all instrument pairs
- Uses latest Dim_Instrument_Correlation where SampleSize >= 200
- Cross-product of all PIs (Cartesian) — symmetric matrix

### 2.3 Pearson Correlation

**What**: Normalized correlation from covariance and individual STDs.
**Columns Involved**: Pearson
**Rules**:
- Pearson = COV / (STD1 × STD2)
- Only computed where both STD1 > 0 AND STD2 > 0
- Range: typically -1 to +1 (many near 0 due to diverse portfolios)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on [Date]. Filter by Date first. 35.4M rows — moderate size.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Most correlated PI pairs today | `WHERE Date = '2026-04-12' AND CID1 < CID2 ORDER BY Pearson DESC` |
| Specific PI's correlations | `WHERE Date = '2026-04-12' AND CID1 = {pi_cid}` |
| Correlation trend for a pair | `WHERE CID1 = X AND CID2 = Y ORDER BY Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_rsk_Risk_PI_Stats | Date + CID1=ParentCID | Full PI stats |
| DWH_dbo.Dim_Customer | CID1 = RealCID | Customer attributes |

### 3.4 Gotchas

- **Symmetric matrix**: (CID1, CID2) and (CID2, CID1) both exist — use `WHERE CID1 < CID2` for unique pairs
- **Self-pairs included**: (CID1=CID2) rows exist with Pearson=1.0
- **2-year rolling retention**: Data older than 2 years is purged daily
- **Pearson=0 is common**: Many PI pairs have zero covariance due to non-overlapping instrument portfolios
- **Type column has trailing space**: Type is varchar(8) NOT NULL — 'Regular' (7 chars) and 'Copyfund' (8 chars, exact fit)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — derived from stored procedure logic |
| Tier 5 | ETL metadata | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | datetime | YES | Reporting date. One snapshot per day. Clustered index key. 2-year rolling retention. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 2 | CID1 | bigint | YES | Customer ID of the first PI in the pair. ParentCID from etoroGeneral_History_GuruCopiers. Top 100 by AUM or eCopiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 3 | ParentUserName1 | nvarchar(500) | YES | Display username of PI 1. Passthrough from etoroGeneral_History_GuruCopiers.ParentUserName. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 4 | Type1 | varchar(8) | NOT NULL | Copy type of PI 1. 'Copyfund' if AccountTypeID=9, 'Regular' otherwise. Used for partition in ranking. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 5 | CID2 | bigint | YES | Customer ID of the second PI in the pair. Cross-joined with CID1. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 6 | ParentUserName2 | nvarchar(500) | YES | Display username of PI 2. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 7 | Type2 | varchar(8) | NOT NULL | Copy type of PI 2. Same logic as Type1. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 8 | COV | decimal(38,6) | YES | Pairwise portfolio covariance. SUM(Instrument_Covariance × NOP_Weight_PI1 × NOP_Weight_PI2) across all instrument pairs. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 9 | STD1 | float | YES | Portfolio standard deviation for PI 1. From V_Liabilities.StandardDeviation. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 10 | AUM1 | money | YES | Total AUM for PI 1. SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL) from copiers. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 11 | RealizedAUM1 | money | YES | Realized AUM for PI 1 (excluding unrealized PnL). Cash + Investment + DetachedPosInvestment. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 12 | eCopiers1 | int | YES | Effective copier count for PI 1. Copiers with equity >= $100. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 13 | rn_AUM1 | bigint | YES | AUM rank of PI 1 within their Type (Regular or Copyfund). ROW_NUMBER() PARTITION BY Type ORDER BY AUM DESC. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 14 | rn_eCopiers1 | bigint | YES | eCopiers rank of PI 1 within their Type. ROW_NUMBER() PARTITION BY Type ORDER BY eCopiers DESC. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 15 | STD2 | float | YES | Portfolio standard deviation for PI 2. Same source as STD1. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 16 | AUM2 | money | YES | Total AUM for PI 2. Same computation as AUM1. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 17 | RealizedAUM2 | money | YES | Realized AUM for PI 2. Same as RealizedAUM1. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 18 | eCopiers2 | int | YES | Effective copier count for PI 2. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 19 | rn_AUM2 | bigint | YES | AUM rank of PI 2 within their Type. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 20 | rn_eCopiers2 | bigint | YES | eCopiers rank of PI 2 within their Type. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 21 | Pearson | float | YES | Pearson correlation coefficient between PI 1 and PI 2 portfolios. COV / (STD1 × STD2). Range -1 to +1 (many near 0). Only computed when both STDs > 0. (Tier 2 — SP_rsk_RiskCorelation_PIs) |
| 22 | UpdateDate | datetime | NOT NULL | ETL metadata: row insert timestamp (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CID1, CID2 | etoroGeneral_History_GuruCopiers | ParentCID | Top 100 filter |
| ParentUserName1/2 | etoroGeneral_History_GuruCopiers | ParentUserName | Passthrough |
| Type1/2 | Dim_Customer | AccountTypeID | CASE 9='Copyfund' |
| COV | Dim_Instrument_Correlation + rsk_Portfolio | Covariance × Weights | Pairwise SUM |
| STD1/2 | V_Liabilities | StandardDeviation | Passthrough |
| AUM1/2 | etoroGeneral_History_GuruCopiers | Multiple | SUM with PnL |
| Pearson | Computed | COV/(STD1×STD2) | Division |

### 5.2 ETL Pipeline

```
general.etoroGeneral_History_GuruCopiers (daily copy snapshot)
DWH_dbo.V_Liabilities (equity + STD)
BI_DB_dbo.BI_DB_rsk_Portfolio (per-instrument NOP)
DWH_dbo.Dim_Instrument_Correlation (covariance matrix, SampleSize>=200)
DWH_dbo.Dim_Customer (valid filter, copyfund type)
  |-- SP_rsk_RiskCorelation_PIs @Date (DELETE+INSERT, 2yr retention) ---|
  v
BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl (35.4M rows)
  |-- Generic Pipeline (Gold export, delta) ---|
  v
dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_rsk_risk_pi_correl
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID1, CID2 | DWH_dbo.Dim_Customer | PI customer dimension |
| Date | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

Used by Tableau Risk Dashboard for PI correlation heatmap.

---

## 7. Sample Queries

### 7.1 Top 10 Most Correlated PI Pairs Today

```sql
SELECT CID1, ParentUserName1, Type1, CID2, ParentUserName2, Type2, Pearson, AUM1, AUM2
FROM BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl
WHERE Date = CAST(GETDATE()-1 AS DATE)
  AND CID1 < CID2
ORDER BY Pearson DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
```

### 7.2 Specific PI's Correlation Network

```sql
SELECT CID2, ParentUserName2, Type2, Pearson, AUM2, eCopiers2
FROM BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl
WHERE Date = '2026-04-12' AND CID1 = 44865947
ORDER BY ABS(Pearson) DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4, 1 T5 | Elements: 22/22, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_rsk_Risk_PI_Correl | Type: Table | Production Source: SP_rsk_RiskCorelation_PIs*
