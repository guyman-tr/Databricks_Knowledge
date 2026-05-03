# BI_DB_dbo.Rev_Cluster_Dict

> 36-row static dictionary table mapping combinations of three KYC questionnaire dimension indices — age at registration, liquid assets (Q11), and trading experience (Q33/Q35/Q2) — to a cluster number (1–10). Consumed by SP_KYC_Score_CID_Level via LEFT JOIN. Manually maintained; last updated 2023-11-14.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Static Clustering Dictionary) |
| **Production Source** | Unknown (dormant) — manually maintained, no writer SP |
| **Refresh** | Manual (ad-hoc INSERT; no automated ETL) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |

---

## 1. Business Meaning

`Rev_Cluster_Dict` is a **static clustering dictionary** with 36 rows that assigns a cluster number to every valid combination of three KYC (Know Your Customer) questionnaire dimensions:

1. **Age at Registration** — 3 brackets: up to 26, 27–34, above 35
2. **Liquid Assets (Q11)** — 3 brackets: Up to $10K, $10K–$50K & $1M–$5M, $50K–$1M
3. **Trading Experience (Q33/Q35/Q2)** — 4 levels: Never traded, 0–10 times, 10–20/10–40 times, Above 20/40 times

The 3 × 3 × 4 = 36 combinations each map to a `Combined_Answer_clustered` value (1–10), producing a revenue-risk cluster used in downstream KYC scoring (BI_DB_KYC_Score_CID_Level).

The table was created on 2022-09-15 by Tal Buhnik and last updated on 2023-11-14 by Yarden (adding answers 210/211 to the trading experience dimension). It is **not refreshed by any SP** — it is loaded manually and serves as a reference lookup.

---

## 2. Business Logic

### 2.1 Three-Dimension Clustering

**What**: Each row represents one combination of three grouped KYC dimension indices, mapping to a cluster number.
**Columns Involved**: Age_On_Reg_grouped_Index, max_33_35_Index, Q11_AnswerText_grouped_Index, Combined_Answer_clustered
**Rules**:
- The table is a complete Cartesian product of 3 age brackets × 3 asset brackets × 4 experience levels = 36 rows
- Each combination is assigned a cluster number from 1 to 10
- Cluster values are not evenly distributed: cluster 3 and 4 have 7 rows each; cluster 10 has only 1 row

### 2.2 Index-to-Label Pairing

**What**: Each dimension has both a numeric index and a human-readable text label stored side by side.
**Columns Involved**: Age_On_Reg_grouped_Index/Age_On_Reg_grouped, max_33_35_Index/max_33_35, Q11_AnswerText_grouped_Index/Q11_AnswerText_grouped
**Rules**:
- Index values are tinyint (1-based for age/Q11, 1–4 for experience)
- Text labels match the CASE expressions in SP_KYC_Score_CID_Level
- No NULL or 99 ("Not_Answered") values exist in this dictionary — those are handled as "No Cluster" in the consumer SP

### 2.3 Consumption Pattern

**What**: SP_KYC_Score_CID_Level LEFT JOINs to this table to assign cluster numbers to each customer.
**Columns Involved**: All index columns (join keys), Combined_Answer_clustered (output)
**Rules**:
- JOIN condition: `Q11_Answer_Grouped_IND = Q11_AnswerText_grouped_Index AND Age_On_Reg_Grouped_IND = Age_On_Reg_grouped_Index AND Max(33,35)_IND = max_33_35_Index`
- LEFT JOIN means unmatched customers get NULL → cast to 'No Cluster' string via ISNULL

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. With only 36 rows, distribution strategy is irrelevant. The table fits in a single data page on every distribution.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| What cluster does a given dimension combination map to? | `SELECT Combined_Answer_clustered FROM BI_DB_dbo.Rev_Cluster_Dict WHERE Age_On_Reg_grouped_Index = @age AND max_33_35_Index = @exp AND Q11_AnswerText_grouped_Index = @assets` |
| How many dimension combos per cluster? | `SELECT Combined_Answer_clustered, COUNT(*) FROM BI_DB_dbo.Rev_Cluster_Dict GROUP BY Combined_Answer_clustered` |
| What are all clusters for a given age bracket? | `SELECT * FROM BI_DB_dbo.Rev_Cluster_Dict WHERE Age_On_Reg_grouped_Index = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_KYC_Score_CID_Level | `ON Q11_Answer_Grouped_IND = Q11_AnswerText_grouped_Index AND Age_On_Reg_Grouped_IND = Age_On_Reg_grouped_Index AND [Max(33,35)_IND] = max_33_35_Index` | Assign cluster number to each customer |

### 3.4 Gotchas

- The table has **no primary key or unique constraint** — uniqueness of the 3-index combination is maintained by convention only
- Column name `max_33_35` contains parentheses in the consumer SP (`Max(33,35)`) but is stored without them in this dictionary
- The Q11 bracket "$10K-$50K & $1M-$5M" is a single bucket combining two non-contiguous ranges — this is intentional per the KYC questionnaire design
- UpdateDate has only 3 distinct values (2022-09-15 and two timestamps on 2023-11-14), confirming manual maintenance

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | No traceable upstream; grounded in DDL + consumer SP context |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Age_On_Reg_grouped_Index | tinyint | NO | Numeric index for the age-at-registration bracket. 1=up to 26, 2=between 27 and 34, 3=above 35. Corresponds to the Age_On_Reg_Grouped_IND CASE expression in SP_KYC_Score_CID_Level. (Tier 3 — manually maintained dictionary, no writer SP; semantics confirmed from SP_KYC_Score_CID_Level CASE logic) |
| 2 | max_33_35_Index | tinyint | NO | Numeric index for the trading experience bracket derived from KYC questions Q33/Q35/Q2. 1=Never traded, 2=0-10 times, 3=10-20 Or 10-40 times, 4=Above 20 Or 40 times. Corresponds to the Max(33,35)_IND CASE expression in SP_KYC_Score_CID_Level. (Tier 3 — manually maintained dictionary, no writer SP; semantics confirmed from SP_KYC_Score_CID_Level CASE logic) |
| 3 | Q11_AnswerText_grouped_Index | tinyint | NO | Numeric index for the liquid assets bracket from KYC question Q11. 1=Up to $10K, 2=$10K-$50K & $1M-$5M, 3=$50K-$1M. Corresponds to the Q11_Answer_Grouped_IND CASE expression in SP_KYC_Score_CID_Level. (Tier 3 — manually maintained dictionary, no writer SP; semantics confirmed from SP_KYC_Score_CID_Level CASE logic) |
| 4 | Age_On_Reg_grouped | nvarchar(50) | NO | Human-readable label for the age-at-registration bracket. Values: 'up to 26', 'between 27 and 34', 'above 35'. Paired with Age_On_Reg_grouped_Index. (Tier 3 — manually maintained dictionary, no writer SP; values confirmed from live data) |
| 5 | Q11_AnswerText_grouped | nvarchar(50) | NO | Human-readable label for the liquid assets bracket from KYC question Q11. Values: 'Up to $10K', '$10K-$50K & $1M-$5M', '$50K-$1M'. Paired with Q11_AnswerText_grouped_Index. (Tier 3 — manually maintained dictionary, no writer SP; values confirmed from live data) |
| 6 | max_33_35 | nvarchar(50) | NO | Human-readable label for the trading experience bracket from KYC questions Q33/Q35/Q2. Values: 'Never traded', '0-10 times', '10-20 Or 10-40 times', 'Above 20 Or 40 times'. Paired with max_33_35_Index. (Tier 3 — manually maintained dictionary, no writer SP; values confirmed from live data) |
| 7 | Combined_Answer_clustered | tinyint | NO | Revenue-risk cluster number assigned to this particular 3-dimension combination. Values range from 1 to 10 across the 36 rows. Used by SP_KYC_Score_CID_Level to classify each verified customer into a behavioral cluster. (Tier 3 — manually maintained dictionary, no writer SP; cluster assignments are business-defined mappings) |
| 8 | UpdateDate | datetime | NO | Timestamp of when this row was last inserted or updated. 3 distinct values in live data: 2022-09-15 (original load) and 2023-11-14 (Yarden's update adding answers 210/211). (Tier 3 — manually maintained dictionary, no writer SP; values confirmed from live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Age_On_Reg_grouped_Index | (manual dictionary) | — | Manually defined bracket index |
| max_33_35_Index | (manual dictionary) | — | Manually defined bracket index |
| Q11_AnswerText_grouped_Index | (manual dictionary) | — | Manually defined bracket index |
| Age_On_Reg_grouped | (manual dictionary) | — | Manually defined bracket label |
| Q11_AnswerText_grouped | (manual dictionary) | — | Manually defined bracket label |
| max_33_35 | (manual dictionary) | — | Manually defined bracket label |
| Combined_Answer_clustered | (manual dictionary) | — | Business-defined cluster assignment |
| UpdateDate | (manual dictionary) | — | Manual insert timestamp |

### 5.2 ETL Pipeline

```
(No automated ETL — manually maintained static dictionary)

Manual INSERT (ad-hoc, by BI team)
  |
  v
BI_DB_dbo.Rev_Cluster_Dict (36 rows, static)
  |-- LEFT JOIN by SP_KYC_Score_CID_Level ---|
  v
BI_DB_dbo.BI_DB_KYC_Score_CID_Level (19.57M rows, daily refresh)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None — this is a standalone dictionary table with no FK dependencies.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Age_On_Reg_grouped_Index, max_33_35_Index, Q11_AnswerText_grouped_Index | BI_DB_dbo.BI_DB_KYC_Score_CID_Level | SP_KYC_Score_CID_Level LEFT JOINs on all 3 index columns to assign cluster |
| Combined_Answer_clustered | BI_DB_dbo.BI_DB_KYC_Score_CID_Level | Provides the Cluster value (cast to NVARCHAR, with ISNULL fallback to 'No Cluster') |

---

## 7. Sample Queries

### 7.1 View the Full Cluster Mapping

```sql
SELECT *
FROM BI_DB_dbo.Rev_Cluster_Dict
ORDER BY Combined_Answer_clustered, Age_On_Reg_grouped_Index, max_33_35_Index, Q11_AnswerText_grouped_Index;
```

### 7.2 Count Dimension Combinations per Cluster

```sql
SELECT Combined_Answer_clustered,
       COUNT(*) AS combos
FROM BI_DB_dbo.Rev_Cluster_Dict
GROUP BY Combined_Answer_clustered
ORDER BY Combined_Answer_clustered;
```

### 7.3 Find Cluster for a Specific Customer Profile

```sql
-- Young customer, low assets, no trading experience
SELECT Combined_Answer_clustered
FROM BI_DB_dbo.Rev_Cluster_Dict
WHERE Age_On_Reg_grouped_Index = 1   -- up to 26
  AND Q11_AnswerText_grouped_Index = 1  -- Up to $10K
  AND max_33_35_Index = 1;              -- Never traded
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this static dictionary table.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 8 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 7/10, Lineage: 6/10*
*Object: BI_DB_dbo.Rev_Cluster_Dict | Type: Table (Static Dictionary) | Production Source: Unknown (dormant)*
