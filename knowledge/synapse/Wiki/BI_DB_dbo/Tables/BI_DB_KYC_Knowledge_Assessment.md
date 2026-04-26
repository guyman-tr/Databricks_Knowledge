# BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment

> 15.56M-row KYC knowledge assessment results table tracking customer responses to Question 23 ("Trading Knowledge Assessment") across three assessment versions: 142-146 (new, 5-question scored), 101-104 (old, single correct answer), and 84-87 (oldest, 4-answer boolean). 76% of customers passed at least one version. One row per GCID. Incremental DELETE+INSERT by GCID via SP_KYC_Panel.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (KYC Knowledge Assessment Results) |
| **Production Source** | BI_DB_KYC_Questions_Answers_Row_Data aggregated by SP_KYC_Panel |
| **Refresh** | Daily incremental DELETE+INSERT by GCID (SB_Daily) |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX (GCID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_KYC_Knowledge_Assessment` stores the results of the **Question 23 ("Trading Knowledge Assessment")** from the eToro KYC questionnaire. This assessment tests whether customers understand basic trading concepts (leverage, margin calls) as part of regulatory appropriateness requirements.

The table holds 15.56M rows (one per GCID). Three versions of the assessment have existed over the platform's lifetime:

1. **Version 142-146 (newest, 7.1M customers)**: Five true/false questions scored at +2 (correct) or -2 (incorrect) each. Total score range: -10 to +10. Pass threshold: total > -3. Used from ~2022 onward.
2. **Version 101-104 (intermediate, 8.4M customers)**: Single-select answer. Pass if AnswerID = 102 ("Opening a trade with $100 and 20x leverage will equate to a $2000 investment"). Used from ~2020-2022.
3. **Version 84-87 (oldest, 32K customers)**: Four boolean answers. Pass if AnswerID 84=1 AND 87=1 AND 85=0 AND 86=0. Legacy version from pre-2020.

The overall pass rate is 76% (11.86M passed). The SP processes only incremental changes (new answers since last run date) and merges via DELETE+INSERT by GCID.

### Author and History
Created by Zvika Solomon (2020-10-05), maintained by Yarden Sabadra with major revisions including new assessment versions, answer 127 addition, and syntax optimization.

---

## 2. Business Logic

### 2.1 Three Assessment Versions

**What**: Each customer may have taken one or more assessment versions over time.
**Columns Involved**: Assessment_*_Ind, Is_Assessment_*_Pass, OccurredAt_*
**Rules**:
- *_Ind = 1: customer took this version; -1: did not
- Is_Assessment_*_Pass = 1: passed; 0: failed; -1: not taken
- A customer can have multiple versions if they retook the assessment after a version change

### 2.2 Overall Pass Determination

**What**: Consolidated pass/fail across all versions.
**Columns Involved**: Q23_Is_Assessment_Pass
**Rules**:
- 1 = passed ANY version (142-146 OR 101-104 OR 84-87)
- 0 = attempted at least one version but failed all
- -1 = no assessment attempted (all *_Ind = -1)

### 2.3 Scoring System (142-146 Version)

**What**: Point-based scoring for the newest assessment version.
**Columns Involved**: P_AnswerId_142 through P_AnswerId_146, Total_Points_Assessment_142_146
**Rules**:
- AnswerID 142: +2 if selected (correct), -2 if not
- AnswerID 143: -2 if selected (incorrect), +2 if not selected
- AnswerID 144: +2 if selected (correct), -2 if not
- AnswerID 145: -2 if selected (incorrect), +2 if not selected
- AnswerID 146: -2 if selected (incorrect), +2 if not selected
- Total range: -10 to +10. Pass if total > -3

### 2.4 Sentinel Values

**What**: Sentinel values indicate missing/inapplicable data.
**Columns Involved**: All version-specific columns
**Rules**:
- -1: indicator/pass flag for version not taken
- -100: point values for version not taken
- 1900-01-01: OccurredAt for version not taken
- 'N/A': text fields for version not taken

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CLUSTERED INDEX on GCID ASC. Optimized for single-customer lookups and JOIN on GCID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Overall assessment pass rate | `SELECT Q23_Is_Assessment_Pass, COUNT(*) GROUP BY Q23_Is_Assessment_Pass` |
| Customers who failed all versions | `WHERE Q23_Is_Assessment_Pass = 0` |
| 142-146 version score distribution | `WHERE Assessment_142_146_Ind = 1 GROUP BY Total_Points_Assessment_142_146` |
| Customers who never took assessment | `WHERE Q23_Is_Assessment_Pass = -1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_KYC_Panel | GCID | Full KYC profile with all question categories |
| DWH_dbo.Dim_Customer | GCID = RealCID | Customer demographics |

### 3.4 Gotchas

- **Sentinel values everywhere**: -1, -100, 'N/A', 1900-01-01 are NOT real data — they indicate the assessment version was not taken. Always filter by *_Ind = 1 before analyzing version-specific columns
- **P_AnswerId scoring is inverted for some questions**: 143, 145, 146 award +2 for NOT selecting the answer (correct behavior is to not select wrong answers)
- **Q23_AnswerText and Q23_AnswerID are mostly empty**: These legacy columns contain 'N/A' and -1 for the vast majority of rows
- **GCID not CID**: This table uses GCID (global customer ID) not CID/RealCID. JOIN to Dim_Customer on GCID = RealCID
- **Multiple versions per customer possible**: A customer may have results for both 142-146 and 101-104 if they retook the assessment

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
| 1 | GCID | int | YES | Global customer ID. One row per GCID. JOIN to Dim_Customer on GCID = RealCID. Distribution and clustering key. (Tier 2 -- SP_KYC_Panel) |
| 2 | Q23_Assessment | varchar(200) | YES | Question text for Question 23. Typically 'Trading Knowledge Assessment'. From BI_DB_KYC_Questions_Answers_Row_Data.QuestionText. (Tier 2 -- SP_KYC_Panel) |
| 3 | Q23_Is_Assessment_Pass | int | NO | Overall knowledge assessment pass flag. 1=passed at least one version, 0=attempted but failed all, -1=never attempted. 76% pass rate. (Tier 2 -- SP_KYC_Panel) |
| 4 | Assessment_142_146_Ind | int | YES | Indicator for 142-146 assessment version. 1=customer took this version (7.1M), -1=did not. (Tier 2 -- SP_KYC_Panel) |
| 5 | Is_Assessment_142_146_Pass | int | YES | Pass flag for 142-146 version. 1=passed (total points > -3), 0=failed, -1=version not taken. (Tier 2 -- SP_KYC_Panel) |
| 6 | Total_Points_Assessment_142_146 | int | YES | Total score for 142-146 version. Range: -10 to +10. Each of 5 questions contributes +2 or -2. -100 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 7 | P_AnswerId_142 | int | YES | Point score for answer 142. +2 if selected (correct), -2 if not. -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel) |
| 8 | P_AnswerId_143 | int | YES | Point score for answer 143. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel) |
| 9 | P_AnswerId_144 | int | YES | Point score for answer 144. +2 if selected (correct), -2 if not. -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel) |
| 10 | P_AnswerId_145 | int | YES | Point score for answer 145. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel) |
| 11 | P_AnswerId_146 | int | YES | Point score for answer 146. -2 if selected (wrong), +2 if not selected (correct). -100 sentinel if 142-146 version not taken. (Tier 2 -- SP_KYC_Panel) |
| 12 | OccurredAt_Assessment_142_146 | datetime | YES | Timestamp of most recent 142-146 assessment attempt. MAX(OccurredAt) from raw Q&A data. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 13 | Assessment_101_104_Ind | int | YES | Indicator for 101-104 assessment version. 1=customer took this version (8.4M), -1=did not. (Tier 2 -- SP_KYC_Panel) |
| 14 | Is_Assessment_101_104_Pass | int | YES | Pass flag for 101-104 version. 1=selected AnswerID 102 (correct), 0=selected wrong answer, -1=version not taken. (Tier 2 -- SP_KYC_Panel) |
| 15 | Q23_AnswerID_101_104 | int | YES | Selected answer ID for the 101-104 version. 101-104 or 127. -1 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 16 | Q23_AnswerText_101_104 | varchar(200) | YES | Selected answer text for 101-104 version. e.g. 'Opening a trade With $100 and 20x leverage will equate To a $2000 investment' (correct). 'N/A' sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 17 | OccurredAt_Assessment_101_104 | datetime | YES | Timestamp of most recent 101-104 assessment attempt. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 18 | Assessment_84_87_Ind | int | YES | Indicator for 84-87 assessment version. 1=customer took this version (32K), -1=did not. Legacy version, rare. (Tier 2 -- SP_KYC_Panel) |
| 19 | Is_Assessment_84_87_Pass | int | YES | Pass flag for 84-87 version. 1=AnswerID 84 AND 87 selected AND 85 AND 86 not selected, 0=failed, -1=version not taken. (Tier 2 -- SP_KYC_Panel) |
| 20 | OccurredAt_Assessment_84_87 | datetime | YES | Timestamp of most recent 84-87 assessment attempt. 1900-01-01 sentinel if version not taken. (Tier 2 -- SP_KYC_Panel) |
| 21 | Q23_AnswerText | varchar(3) | NO | Legacy consolidated answer text. 'N/A' for virtually all rows. (Tier 2 -- SP_KYC_Panel) |
| 22 | Q23_AnswerID | int | NO | Legacy consolidated answer ID. -1 for virtually all rows. (Tier 2 -- SP_KYC_Panel) |
| 23 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted/updated by SP_KYC_Panel. Set to GETDATE(). (Tier 5 -- SP_KYC_Panel) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| GCID | BI_DB_KYC_Questions_Answers_Row_Data | GCID | Passthrough |
| Q23_Assessment | BI_DB_KYC_Questions_Answers_Row_Data | QuestionText | MAX(CASE QuestionId=23) |
| Q23_Is_Assessment_Pass | Computed | Multiple version pass flags | 1 if ANY pass, 0 if all fail, -1 if none taken |
| Assessment_*_Ind | Computed | Presence check | 1 if answers exist for version |
| Is_Assessment_*_Pass | Computed | Version-specific logic | Scoring rules per version |
| Total_Points_Assessment_142_146 | Computed | P_AnswerId_142..146 | SUM of 5 point scores |
| P_AnswerId_142..146 | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | CASE: +2/-2 per answer correctness |
| OccurredAt_Assessment_* | BI_DB_KYC_Questions_Answers_Row_Data | OccurredAt | MAX per version |
| Q23_AnswerID_101_104 | BI_DB_KYC_Questions_Answers_Row_Data | AnswerId | MAX for 101-104 version |
| Q23_AnswerText_101_104 | BI_DB_KYC_Questions_Answers_Row_Data | AnswerText | MAX for 101-104 version |
| UpdateDate | GETDATE() | -- | ETL timestamp |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data
  (raw Q&A: GCID × QuestionId × AnswerId × OccurredAt)
  |-- SP_KYC_Panel @Date (daily, incremental) -----------------------|
  |   Step 1: Filter QuestionId=23, AnswerId IN (142-146)            |
  |           → #KYC_Knowledge_Assessment_142_146_Stage_1 (scoring)  |
  |           → #KYC_Knowledge_Assessment_142_146_Stage_2 (pass/fail)|
  |   Step 2: Filter QuestionId=23, AnswerId IN (101-104,127)        |
  |           → #KYC_Knowledge_Assessment_101_104                    |
  |   Step 3: Filter QuestionId=23, AnswerId IN (84-87)              |
  |           → #KYC_Knowledge_Assessment_84_87                      |
  |   Step 4: UNION ALL 3 versions → aggregate per GCID              |
  |           → overall pass = ANY version passed                    |
  |   Step 5: DELETE + INSERT by GCID                                |
  v
BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment (15.56M rows)
  |-- Consumed by SP_KYC_Panel (joined back into BI_DB_KYC_Panel)
  |-- Consumed by SP_W_Mon_Compliance_CDIM_Report
  |-- Consumed by SP_BI_DB_Suitability_KYC
  (Not in Generic Pipeline -- _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| GCID | DWH_dbo.Dim_Customer (RealCID) | Customer demographics |
| All data | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | Raw Q&A source |

### 6.2 Referenced By (other objects point to this)

| Consumer | Join Condition | Purpose |
|----------|---------------|---------|
| BI_DB_dbo.BI_DB_KYC_Panel | GCID | Consolidated KYC profile |
| SP_W_Mon_Compliance_CDIM_Report | GCID | Compliance monitoring |
| SP_BI_DB_Suitability_KYC | GCID | KYC suitability assessment |

---

## 7. Sample Queries

### 7.1 Assessment Pass Rate by Version

```sql
SELECT
  SUM(CASE WHEN Assessment_142_146_Ind = 1 AND Is_Assessment_142_146_Pass = 1 THEN 1 ELSE 0 END) AS pass_142_146,
  SUM(CASE WHEN Assessment_142_146_Ind = 1 AND Is_Assessment_142_146_Pass = 0 THEN 1 ELSE 0 END) AS fail_142_146,
  SUM(CASE WHEN Assessment_101_104_Ind = 1 AND Is_Assessment_101_104_Pass = 1 THEN 1 ELSE 0 END) AS pass_101_104,
  SUM(CASE WHEN Assessment_101_104_Ind = 1 AND Is_Assessment_101_104_Pass = 0 THEN 1 ELSE 0 END) AS fail_101_104
FROM [BI_DB_dbo].[BI_DB_KYC_Knowledge_Assessment]
```

### 7.2 Score Distribution for 142-146 Version

```sql
SELECT Total_Points_Assessment_142_146,
       COUNT(*) AS customer_count,
       SUM(CASE WHEN Is_Assessment_142_146_Pass = 1 THEN 1 ELSE 0 END) AS passed
FROM [BI_DB_dbo].[BI_DB_KYC_Knowledge_Assessment]
WHERE Assessment_142_146_Ind = 1
GROUP BY Total_Points_Assessment_142_146
ORDER BY Total_Points_Assessment_142_146
```

### 7.3 Customers Who Failed All Versions

```sql
SELECT ka.GCID, dc.RegulationID, dc.CountryID
FROM [BI_DB_dbo].[BI_DB_KYC_Knowledge_Assessment] ka
JOIN [DWH_dbo].[Dim_Customer] dc ON ka.GCID = dc.RealCID
WHERE ka.Q23_Is_Assessment_Pass = 0
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 0 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 23/23, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment | Type: Table | Production Source: BI_DB_KYC_Questions_Answers_Row_Data via SP_KYC_Panel*
