# BI_DB_dbo.V_BI_DB_KYC_Score_CID_Level

> ~19.7M-row passthrough view over `BI_DB_dbo.BI_DB_KYC_Score_CID_Level` — one row per `RealCID` carrying the customer's KYC-derived risk/wealth segmentation: Q11 wealth-bracket answer, age-on-registration bucket, MAX(33,35) score band, last-30-days revenue, and a final `Cluster` 1-10 (or `'No Cluster'`) used by risk and revenue-modelling pipelines. Two columns are renamed in the view: `[Max(33,35)_IND]` → `MAX_33_35_IND`, `[Max(33,35)]` → `MAX_33_25` (the latter rename appears to be a typo — see Gotchas).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | View (passthrough over BI_DB_KYC_Score_CID_Level) |
| **Production Source** | `BI_DB_dbo.BI_DB_KYC_Score_CID_Level` (writer SP TBD) |
| **Refresh** | Inherits from base table — typically daily |
| **Row Count** | ~19,732,000 |
| **Grain** | One row per `RealCID` (per refresh) |
| | |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export of the view (generic pipeline materializes views as tables) |

---

## 1. Business Meaning

`V_BI_DB_KYC_Score_CID_Level` is the **per-customer KYC scoring** snapshot. Each row is a single `RealCID` summarized along the three dimensions that drive eToro's customer-segmentation model:

1. **Q11 wealth bracket** (`Q11_Answer_Grouped`, `Q11_Answer_Grouped_IND`) — the KYC questionnaire's net-worth question, bucketed into 4 ordinal levels.
2. **Age-on-registration bucket** (`Age_On_Reg_Grouped`, `Age_On_Reg_Grouped_IND`) — age bracket at the time of customer registration.
3. **Score band** (`MAX_33_35_IND`, `MAX_33_25`) — the larger of two internal score rules (questionnaire fields 33 and 35), bucketed into a few bands. Higher = stronger wealth/sophistication signal.

These three are combined (in the upstream writer SP) with **30-day revenue** (`Revenue30days`) and other features into a final `Cluster` 1-10. UC sample (2026-05-07) shows clear monotonic alignment between cluster and avg revenue:

| Cluster | Rows | Avg Revenue30days |
|---------|------|-------------------|
| 1 | 5.86M | $26 |
| 2 | 4.15M | $40 |
| 3 | 2.58M | $50 |
| 4 | 2.60M | $70 |
| 5 | 0.76M | $102 |
| 6 | 0.98M | $110 |
| 7 | 0.56M | $106 |
| 8 | 0.30M | $127 |
| 9 | 0.55M | $178 |
| 10 | 0.46M | $208 |
| `'No Cluster'` | 0.91M | $6 (mostly inactive) |

The Q11 wealth distribution sample (~19.7M total):

| Q11_IND | Q11_Answer_Grouped | Rows |
|---------|---------------------|------|
| 1 | Up to $10K | 9.97M |
| 2 | $10K-$50K & $1M-$5M | 6.19M |
| 3 | $50K-$1M | 3.56M |
| 99 | Not_Answered | 471 |

---

## 2. Query Advisory

### 2.1 Common Patterns

| Question | Approach |
|----------|----------|
| Customer segment for a CID | `WHERE RealCID = ...` (returns 1 row) |
| Cluster size | `GROUP BY Cluster ORDER BY COUNT(*) DESC` |
| Wealth bracket cohort | `WHERE Q11_Answer_Grouped_IND = 1` (Up-to-10K) |
| Avg revenue by cluster | `GROUP BY Cluster, AVG(Revenue30days)` |

### 2.2 Gotchas

- **`MAX_33_25` looks like a typo** — the underlying source column is `[Max(33,35)]` (max of fields 33 and 35), but the view aliases it as `MAX_33_25`. Treat the alias as opaque; the value is `MAX(field_33, field_35)`.
- **Q11 grouped value `'$10K-$50K & $1M-$5M'`** is a single bracket — odd label combining two non-adjacent ranges.
- **`'No Cluster'`** is a real `Cluster` value (string) for ~0.91M low-activity customers. Filter explicitly if you want only numeric clusters.
- **Q11 = 99** = "Not_Answered". Only 471 customers; safe to either include or exclude.
- **`Reg_Date` may be NULL** for legacy/edge customers.
- **Revenue30days = 0 OR NULL** for inactive customers — both are valid ("nothing earned").

---

## 3. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| *** | Tier 1 | DDL + view definition + UC sample |
| ** | Tier 2 | UC value distribution audit (2026-05-07) |
| * | Tier 3 | Inferred from name [UNVERIFIED] |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | bigint | YES | Real customer identifier — FK to `DWH_dbo.Dim_Customer.RealCID`. Primary join key out of this view. (Tier 1 — DDL) |
| 2 | Q11_Answer_Grouped_IND | int | NO | Numeric ordinal of the wealth bucket: 1, 2, 3, or 99 (Not_Answered). Use this for ordering/numeric calculations. (Tier 2 — UC distribution) |
| 3 | Q11_Answer_Grouped | varchar(19) | NO | Wealth bucket label: `'Up to $10K'`, `'$10K-$50K & $1M-$5M'`, `'$50K-$1M'`, or `'Not_Answered'`. (Tier 2 — UC distribution) |
| 4 | Age_On_Reg_Grouped_IND | int | NO | Numeric ordinal of the age-on-registration bucket. (Tier 1 — DDL) |
| 5 | Age_On_Reg_Grouped | varchar(17) | NO | Age-on-registration bucket label (typical 5-10-year ranges). (Tier 1 — DDL) |
| 6 | MAX_33_35_IND | int | NO | Numeric ordinal of the MAX(field_33, field_35) score band. The underlying source name is `Max(33,35)_IND`; renamed for UC compatibility. (Tier 1 — view definition) |
| 7 | MAX_33_25 | varchar(50) | YES | MAX(field_33, field_35) score band label. Source column is `[Max(33,35)]` — alias `MAX_33_25` appears to be a typo (the alias name). The value is the MAX of fields 33 AND 35, not 33 and 25. (Tier 1 — view definition + suspected naming bug) |
| 8 | Revenue30days | decimal(38,2) | YES | Revenue (USD) generated by the customer in the trailing 30 days. Used by the cluster algorithm and downstream revenue-modelling. NULL or 0 for inactive customers. (Tier 1 — DDL) |
| 9 | Reg_Date | date | YES | Customer registration date (when the eToro account was opened). FK-equivalent to `Dim_Customer.Reg_Date`. (Tier 1 — DDL) |
| 10 | Cluster | nvarchar(100) | NO | Final segmentation cluster: integer string `'1'`-`'10'` or `'No Cluster'` for inactive customers. Higher integer = higher avg 30-day revenue (cluster 10 ≈ $208 avg vs cluster 1 ≈ $26). (Tier 2 — UC distribution audit, 2026-05-07) |
| 11 | UpdateDate | datetime | NO | Timestamp of the most recent ETL touch on this row. (Tier 1 — DDL) |

---

## 4. Lineage

### 4.1 View Definition

```sql
CREATE VIEW BI_DB_dbo.V_BI_DB_KYC_Score_CID_Level AS
SELECT [RealCID]
     , [Q11_Answer_Grouped_IND]
     , [Q11_Answer_Grouped]
     , [Age_On_Reg_Grouped_IND]
     , [Age_On_Reg_Grouped]
     , [Max(33,35)_IND] AS MAX_33_35_IND
     , [Max(33,35)]     AS MAX_33_25         -- suspected typo: should be MAX_33_35
     , [Revenue30days]
     , [Reg_Date]
     , [Cluster]
     , [UpdateDate]
FROM   BI_DB_dbo.BI_DB_KYC_Score_CID_Level
```

### 4.2 Pipeline

```
KYC questionnaire + Revenue rollup → BI_DB_dbo.BI_DB_KYC_Score_CID_Level (writer SP TBD)
                                  ↓
                   V_BI_DB_KYC_Score_CID_Level (alias view)
                                  ↓ Generic Pipeline (gold export)
        main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level
```

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Description |
|---------|----------------|-------------|
| RealCID | `DWH_dbo.Dim_Customer.RealCID` | Customer identity |
| Reg_Date | `DWH_dbo.Dim_Date.FullDate` (logical) | Registration date |

### 5.2 Referenced By

KYC scoring is consumed by risk and marketing models, segmentation reports, and Tableau cluster dashboards.

---

## 6. Sample Queries

### 6.1 Cluster size + avg revenue

```sql
SELECT Cluster, COUNT(*) AS rows_cnt, AVG(Revenue30days) AS avg_rev30
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level
GROUP  BY Cluster
ORDER  BY rows_cnt DESC
```

### 6.2 High-value customer segment

```sql
SELECT *
FROM   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_kyc_score_cid_level
WHERE  Cluster IN ('9','10')
  AND  Q11_Answer_Grouped_IND = 3   -- $50K-$1M wealth
```

---

*Generated: 2026-05-07 | Wave 2 systematic NO_WIKI fill-in*
*Source: View definition + UC sample (Cluster + Q11 distributions, 2026-05-07)*
*Object: BI_DB_dbo.V_BI_DB_KYC_Score_CID_Level | Type: View | Base: BI_DB_KYC_Score_CID_Level*
