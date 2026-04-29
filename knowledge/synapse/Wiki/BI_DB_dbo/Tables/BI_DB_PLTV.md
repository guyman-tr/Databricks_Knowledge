# BI_DB_dbo.BI_DB_PLTV

> 5.9K-row predicted Lifetime Value (PLTV) lookup table by country, age bucket, and KYC questionnaire answers. Two-part UNION: granular predictions (country + age + Q11 + MAX(Q33/Q35)) from 2-8 month FTD cohort, plus regional fallback averages by MarketingRegion. TRUNCATE+INSERT via SP_BI_DB_PLTV.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_dbo.BI_DB_LTV_BI_Actual + BI_DB_KYC_Score_CID_Level + BI_DB_KYC_Panel + DWH_dbo.Dim_Customer via `SP_BI_DB_PLTV` |
| **Refresh** | Daily (TRUNCATE+INSERT, no date parameter) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Nitsan Sharabi (2024-05-03) |
| **Row Count** | ~5,915 (as of 2026-04-01) |

---

## 1. Business Meaning

`BI_DB_PLTV` is a Predicted Lifetime Value lookup table used by the data science team to forecast customer LTV at lead/registration time. The model segments customers by four dimensions: country (CountryID), age at registration (3 buckets), KYC knowledge assessment answer (Q11_AnswerID), and maximum of two financial literacy answers (MAX(Q33, Q35)).

The table has two parts (UNION ALL):
1. **Granular predictions**: Average Revenue8Y_LTV_New from BI_DB_LTV_BI_Actual for customers who made their first deposit 2-8 months ago, have a KYC cluster assignment, and VerificationLevelID >= 2. Grouped by country + age bucket + Q11 + MAX(Q33/Q35).
2. **Regional fallback**: Average Revenue8Y_LTV_New by MarketingRegionManualName, with Min_Age=999, Max_Age=999, Q11=999, MaxQ33/Q35=999 as sentinel values. This provides a fallback when the granular dimensions don't have enough data.

The LeadScore column was removed on 2024-10-25 (always NULL) but remains in the DDL.

As of 2026-04-01: 5,915 rows. PLTV values range from near 0 to several thousand dollars.

---

## 2. Business Logic

### 2.1 Age Bucketing

**What**: Customer age at registration is bucketed into three tiers.
**Columns Involved**: `Min_Age`, `Max_Age`
**Rules**:
- 18-26: Young adults (Min_Age=18, Max_Age=26)
- 27-35: Mid-career (Min_Age=27, Max_Age=35) — note Max_Age=35 overlaps with Min_Age=35
- 35+: Mature (Min_Age=35, Max_Age=999)
- 999/999: Regional fallback rows (no age segmentation)
- Age = DATEDIFF(YEAR, BirthDate, RegisteredReal) — age at registration, not current age

### 2.2 KYC Answer Segmentation

**What**: Financial literacy answers from the KYC questionnaire segment customer sophistication.
**Columns Involved**: `Q11_AnswerID`, `MaxQ33/MaxQ35`
**Rules**:
- Q11_AnswerID: KYC knowledge assessment question 11 answer
- MaxQ33/MaxQ35: MAX(Q33_AnswerID, Q35_AnswerID) — takes the higher of two financial literacy indicators
- If Q33 <= Q35 → use Q35; if Q33 > Q35 → use Q33; else 999
- 999 = regional fallback (no KYC segmentation)

### 2.3 PLTV Calculation

**What**: Average predicted LTV from recent FTD cohort.
**Columns Involved**: `PLTV`
**Rules**:
- Part 1 (granular): SUM(Revenue8Y_LTV_New) / COUNT(RealCID) for the segment
- Part 2 (regional): AVG(Revenue8Y_LTV_New) by MarketingRegionManualName
- Cohort: FirstDepositDate between 8 months ago and 2 months ago (2-8 month observation window)
- Filters: Revenue8Y_LTV_New IS NOT NULL, Cluster != 'No Cluster', VerificationLevelID >= 2, IsValidCustomer = 1

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — small lookup table. Full scans are fast.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| PLTV for a specific country/age/KYC combo | `WHERE CountryID = X AND Min_Age = Y AND Q11_AnswerID = Z AND [MaxQ33/MaxQ35] = W` |
| Regional fallback values | `WHERE Min_Age = 999` (sentinel rows) |
| Highest PLTV segments | `ORDER BY PLTV DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Country | `CountryID = CountryID` | Country name resolution |

### 3.4 Gotchas

- **Column with slash**: `[MaxQ33/MaxQ35]` requires square brackets in queries
- **LeadScore is always NULL**: Column was functionally removed 2024-10-25 but DDL retained
- **999 sentinels**: Min_Age=999, Max_Age=999, Q11=999, MaxQ33/MaxQ35=999 are regional fallback rows, not data errors
- **Column count**: DDL has 8 columns, batch assignment said 7
- **Age overlap**: Max_Age=35 in bucket 2 and Min_Age=35 in bucket 3 — the SP CASE uses `>34` for bucket 3, so age 35 goes to bucket 3

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (verbatim or with DWH note) |
| Tier 2 | Derived from SP code analysis |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CountryID | int | NO | Country identifier. FK to Dim_Country.CountryID. In Part 1: direct from Dim_Country via customer's CountryID. In Part 2: from Dim_Country joined via MarketingRegionManualName. (Tier 1 — Dictionary.Country) |
| 2 | Min_Age | int | YES | Lower bound of the age-at-registration bucket. Values: 18, 27, 35, or 999 (regional fallback). (Tier 2 — SP_BI_DB_PLTV) |
| 3 | Max_Age | int | YES | Upper bound of the age-at-registration bucket. Values: 26, 35, 999 (999 = no upper limit or regional fallback). (Tier 2 — SP_BI_DB_PLTV) |
| 4 | Q11_AnswerID | int | YES | KYC questionnaire Q11 answer ID from BI_DB_KYC_Panel. Segmentation dimension for financial knowledge. 999 = regional fallback. (Tier 2 — SP_BI_DB_PLTV, BI_DB_KYC_Panel) |
| 5 | MaxQ33/MaxQ35 | int | YES | Maximum of Q33_AnswerID and Q35_AnswerID from BI_DB_KYC_Panel. Financial literacy segmentation. 999 = regional fallback or ELSE branch. (Tier 2 — SP_BI_DB_PLTV, BI_DB_KYC_Panel) |
| 6 | LeadScore | int | YES | DEPRECATED — always NULL since 2024-10-25 removal. Column retained in DDL but no longer populated. (Tier 2 — SP_BI_DB_PLTV) |
| 7 | PLTV | float | YES | Predicted Lifetime Value in USD. Part 1: SUM(Revenue8Y_LTV_New)/COUNT(RealCID) for the segment. Part 2: AVG(Revenue8Y_LTV_New) by marketing region. (Tier 2 — SP_BI_DB_PLTV, BI_DB_LTV_BI_Actual) |
| 8 | updateDate | datetime | YES | ETL execution timestamp. GETDATE() at SP execution time. (Tier 2 — SP_BI_DB_PLTV) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| CountryID | Dictionary.Country | CountryID | passthrough via Dim_Country |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_KYC_Score_CID_Level (cluster assignment, exclude 'No Cluster')
  + BI_DB_dbo.BI_DB_KYC_Panel (Q11, Q33, Q35 answers, VL>=2)
  + BI_DB_dbo.BI_DB_LTV_BI_Actual (Revenue8Y_LTV_New, FTD 2-8 months ago)
  + DWH_dbo.Dim_Customer (age at registration, IsValidCustomer)
  + DWH_dbo.Dim_Country (CountryID, MarketingRegionManualName)
  |
  |-- SP_BI_DB_PLTV (TRUNCATE+INSERT)
  |   Part 1: Granular — GROUP BY CountryID, AgeBucket, Q11, MAX(Q33/Q35)
  |   Part 2: Regional fallback — AVG by MarketingRegionManualName
  |   UNION ALL → TRUNCATE + INSERT
  v
BI_DB_dbo.BI_DB_PLTV (5.9K rows, ROUND_ROBIN HEAP)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CountryID | DWH_dbo.Dim_Country (CountryID) | Country dimension |
| PLTV | BI_DB_dbo.BI_DB_LTV_BI_Actual | Revenue8Y_LTV_New source |
| Q11_AnswerID, MaxQ33/MaxQ35 | BI_DB_dbo.BI_DB_KYC_Panel | KYC questionnaire answers |

### 6.2 Referenced By (other objects point to this)

No known consumers in the current wiki inventory.

---

## 7. Sample Queries

### 7.1 PLTV Lookup for a Customer Profile

```sql
SELECT CountryID, Min_Age, Max_Age, Q11_AnswerID, [MaxQ33/MaxQ35], PLTV
FROM BI_DB_dbo.BI_DB_PLTV
WHERE CountryID = 9  -- Australia
  AND Min_Age = 27
  AND Q11_AnswerID = 35
ORDER BY PLTV DESC
```

### 7.2 Regional Fallback Values

```sql
SELECT p.CountryID, dc.Name AS Country, p.PLTV
FROM BI_DB_dbo.BI_DB_PLTV p
JOIN DWH_dbo.Dim_Country dc ON p.CountryID = dc.CountryID
WHERE p.Min_Age = 999
ORDER BY p.PLTV DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search unavailable due to permissions).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 8/10, Lineage: 7/10*
*Object: BI_DB_dbo.BI_DB_PLTV | Type: Table | Production Source: BI_DB_LTV_BI_Actual + KYC_Score_CID_Level + KYC_Panel via SP_BI_DB_PLTV*
