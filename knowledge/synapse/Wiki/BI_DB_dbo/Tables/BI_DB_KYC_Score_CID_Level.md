# BI_DB_dbo.BI_DB_KYC_Score_CID_Level

> 19.57M-row KYC scoring table assigning each verified customer (VerificationLevelID>=2) to a behavioral cluster based on three KYC dimensions: liquid assets (Q11), age at registration, and trading experience (Q33/Q35/Q2). 11 cluster values (1-10 + 'No Cluster'). One row per RealCID. Daily TRUNCATE+INSERT via SP_KYC_Score_CID_Level.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (KYC Behavioral Scoring -- CID Level) |
| **Production Source** | BI_DB_KYC_Panel + Rev_Cluster_Dict by SP_KYC_Score_CID_Level |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (UpdateDate ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_KYC_Score_CID_Level` is a **KYC behavioral scoring table** that classifies each verified customer into one of 11 clusters based on three KYC questionnaire dimensions. The table holds 19.57M rows (one per RealCID) for customers with VerificationLevelID >= 2 (intermediate or fully verified).

The SP groups customers along three axes:
1. **Liquid Assets (Q11)**: Customer's declared liquid assets, grouped into 3 brackets
2. **Age at Registration**: Customer's age when they registered, grouped into 3 brackets
3. **Trading Experience (Q33/Q35/Q2)**: Maximum experience level across equities/CFDs/crypto/general trading questions, mapped to 4 levels

These three grouped indices are then matched against `Rev_Cluster_Dict` (a static dictionary table) to assign a cluster number (1-10). Customers not matching any combination get 'No Cluster' (4.3% of rows).

### Author and History
Created by Tal Buhnik (2022-09-04). Maintained by Yarden Sabadra — added answer IDs 210/211, removed date condition, changed to TRUNCATE.

---

## 2. Business Logic

### 2.1 Liquid Assets Grouping (Q11)

**What**: Groups Q11 answer IDs into 3 liquid asset brackets.
**Columns Involved**: Q11_Answer_Grouped_IND, Q11_Answer_Grouped
**Rules**:
- IND=1 / 'Up to $10K': AnswerID IN (34, 28)
- IND=2 / '$10K-$50K & $1M-$5M': AnswerID IN (35, 81, 29, 30, 33, 38)
- IND=3 / '$50K-$1M': AnswerID IN (36, 79, 80, 31, 32, 37)
- IND=99 / 'Not_Answered': All others

### 2.2 Age at Registration Grouping

**What**: Groups customer age at registration into 3 brackets.
**Columns Involved**: Age_On_Reg_Grouped_IND, Age_On_Reg_Grouped
**Rules**:
- IND=1 / 'up to 26': Age <= 26
- IND=2 / 'between 27 and 34': Age 27-34
- IND=3 / 'Above 35': Age >= 35
- IND=99 / 'Not_Answered': NULL age

### 2.3 Trading Experience Grouping (Q33/Q35/Q2)

**What**: Takes the maximum experience level across equities (Q33), CFDs (Q35), and general (Q2).
**Columns Involved**: Max(33,35)_IND, Max(33,35)
**Rules**:
- IND=1 / 'Never traded': AnswerID 49
- IND=2 / '0-10 times / Less than 1 Year': AnswerID 122 or Q2=50/2
- IND=3 / '10-20 Or 10-40 times / Between 1-3 Years': AnswerID 123/210 or Q2=3
- IND=4 / 'Above 20 Or 40 times / More than 3 years': AnswerID 124/211 or Q2=4
- IND=99 / 'Not_Answered': None of the above

### 2.4 Cluster Assignment

**What**: Maps 3-way index combination to a cluster number.
**Columns Involved**: Cluster
**Rules**:
- LEFT JOIN to Rev_Cluster_Dict on (Q11_IND, Age_IND, Max33_35_IND)
- 11 distinct clusters: 1-10 + 'No Cluster'
- Cluster 1 is the largest (5.85M, 30%), Cluster 2 (4.14M, 21%)
- 'No Cluster' = 833K (4.3%) -- index combinations not in dictionary

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(RealCID) with CLUSTERED INDEX on UpdateDate ASC. Efficient for single-customer lookups on RealCID (hash-distributed). Note: CI on UpdateDate is unusual for a TRUNCATE table -- all rows share the same UpdateDate.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Cluster distribution | `SELECT Cluster, COUNT(*) GROUP BY Cluster ORDER BY cnt DESC` |
| Revenue by cluster | `SELECT Cluster, AVG(Revenue30days) GROUP BY Cluster` |
| Young high-asset customers | `WHERE Age_On_Reg_Grouped_IND = 1 AND Q11_Answer_Grouped_IND = 3` |
| Customers without cluster | `WHERE Cluster = 'No Cluster'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_KYC_Panel | RealCID | Full KYC Q&A data |
| BI_DB_dbo.Rev_Cluster_Dict | 3-way key | Cluster definition details |

### 3.4 Gotchas

- **Cluster is a string, not int**: Despite clusters being numbered 1-10, the Cluster column is nvarchar(50) and includes 'No Cluster'. Cast to int only after filtering out 'No Cluster'
- **Revenue30days NULL**: Many customers have NULL Revenue30days (no trading activity in last 30 days)
- **99 = Not_Answered**: Sentinel for all three grouping INDs when the corresponding Q&A is missing
- **CI on UpdateDate**: All rows have identical UpdateDate (TRUNCATE+INSERT). The index provides no selectivity
- **Q11 bracket overlap in label**: '$10K-$50K & $1M-$5M' label groups two non-contiguous ranges

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID. One row per customer. FK to Dim_Customer.RealCID. Distribution key. (Tier 2 -SP_KYC_Score_CID_Level via BI_DB_KYC_Panel) |
| 2 | Q11_Answer_Grouped_IND | int | NO | Liquid assets group index from KYC Q11 (Liquid Assets). 1='Up to $10K', 2='$10K-$50K & $1M-$5M', 3='$50K-$1M', 99='Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 3 | Q11_Answer_Grouped | varchar(19) | NO | Liquid assets group label. Maps from Q11_Answer_Grouped_IND. Values: 'Up to $10K', '$10K-$50K & $1M-$5M', '$50K-$1M', 'Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 4 | Age_On_Reg_Grouped_IND | int | NO | Age at registration group index. 1='up to 26', 2='between 27 and 34', 3='Above 35', 99='Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 5 | Age_On_Reg_Grouped | varchar(17) | NO | Age at registration group label. Maps from Age_On_Reg_Grouped_IND. Values: 'up to 26', 'between 27 and 34', 'Above 35', 'Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 6 | Max(33,35)_IND | int | NO | Trading experience group index. MAX across Q33 (Equities experience), Q35 (CFDs experience), Q2 (general). 1='Never traded', 2='0-10 times/Less than 1 Year', 3='10-20/10-40 times/1-3 Years', 4='Above 20/40 times/3+ years', 99='Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 7 | Max(33,35) | varchar(50) | YES | Trading experience group label. Values: 'Never traded', '0-10 times / Less than 1 Year', '10-20 Or 10-40 times / Between 1-3 Years', 'Above 20 Or 40 times / More than 3 years', 'Not_Answered'. (Tier 2 -SP_KYC_Score_CID_Level) |
| 8 | Revenue30days | decimal(38,2) | YES | Customer's 30-day revenue from BI_DB_KYC_Panel. In USD. NULL if no trading activity. (Tier 2 -SP_KYC_Score_CID_Level via BI_DB_KYC_Panel) |
| 9 | Reg_Date | date | YES | Customer registration date from BI_DB_KYC_Panel. (Tier 2 -SP_KYC_Score_CID_Level via BI_DB_KYC_Panel) |
| 10 | Cluster | nvarchar(50) | NO | Behavioral cluster assignment. Looked up from Rev_Cluster_Dict via 3-way key (Q11_IND, Age_IND, Max33_35_IND). Values: '1'-'10' or 'No Cluster'. Cluster 1 largest (30%). (Tier 2 -SP_KYC_Score_CID_Level via Rev_Cluster_Dict) |
| 11 | UpdateDate | datetime | NO | ETL metadata: timestamp of last TRUNCATE+INSERT. All rows share the same value. Set to GETDATE(). (Tier 5 -SP_KYC_Score_CID_Level) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| RealCID | BI_DB_KYC_Panel | RealCID | Passthrough |
| Q11_Answer_Grouped_IND/Grouped | BI_DB_KYC_Panel | Q11_AnswerID | CASE grouping into 3 brackets |
| Age_On_Reg_Grouped_IND/Grouped | BI_DB_KYC_Panel | Age_On_Reg | CASE grouping into 3 brackets |
| Max(33,35)_IND/Max(33,35) | BI_DB_KYC_Panel | Q33/Q35/Q2 AnswerIDs | CASE max experience across 3 questions |
| Revenue30days | BI_DB_KYC_Panel | Revenue30days | Passthrough |
| Reg_Date | BI_DB_KYC_Panel | Reg_Date | Passthrough |
| Cluster | Rev_Cluster_Dict | Combined_Answer_clustered | LEFT JOIN on 3-way key |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_KYC_Panel (full KYC Q&A data, VerificationLevelID >= 2)
  |-- SP_KYC_Score_CID_Level (daily, TRUNCATE+INSERT) ---|
  |   Step 1: #KYC_result = filter BI_DB_KYC_Panel       |
  |   Step 2: #KYC_grouped_Result = CASE groupings on    |
  |           Q11, Age_On_Reg, Q33/Q35/Q2                |
  |   Step 3: LEFT JOIN Rev_Cluster_Dict on 3-way key    |
  |           → Cluster assignment (1-10 or 'No Cluster') |
  v
BI_DB_dbo.BI_DB_KYC_Score_CID_Level (19.57M rows)
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer profile |
| All data | BI_DB_dbo.BI_DB_KYC_Panel | Source KYC data |
| Cluster | BI_DB_dbo.Rev_Cluster_Dict | Cluster assignment dictionary |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Cluster Size and Average Revenue

```sql
SELECT Cluster,
       COUNT(*) AS customers,
       AVG(Revenue30days) AS avg_revenue,
       SUM(Revenue30days) AS total_revenue
FROM [BI_DB_dbo].[BI_DB_KYC_Score_CID_Level]
GROUP BY Cluster
ORDER BY customers DESC
```

### 7.2 Experience Distribution by Age Group

```sql
SELECT Age_On_Reg_Grouped,
       [Max(33,35)],
       COUNT(*) AS customers
FROM [BI_DB_dbo].[BI_DB_KYC_Score_CID_Level]
WHERE Cluster != 'No Cluster'
GROUP BY Age_On_Reg_Grouped, [Max(33,35)]
ORDER BY Age_On_Reg_Grouped, [Max(33,35)]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4, 1 T5 | Elements: 11/11, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_KYC_Score_CID_Level | Type: Table | Production Source: BI_DB_KYC_Panel + Rev_Cluster_Dict*
