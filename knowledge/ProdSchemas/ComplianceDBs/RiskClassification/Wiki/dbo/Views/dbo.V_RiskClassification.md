# dbo.V_RiskClassification

> Primary enriched risk classification view that combines customer scores from T_RiskClassification with regulation names, risk level labels, score explanations listing contributing parameters, and previous risk score history.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.T_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary consumer-facing view for risk classification data. It takes the raw T_RiskClassification table and enriches it with: (1) the regulation name from Dictionary.Regulation, (2) the named risk level (e.g., "Medium", "High") from Dictionary.RiskClassificationRegulation, (3) a `RiskScore_Explanation` field that lists which parameters contributed non-zero scores, and (4) the customer's previous risk score and when it changed, derived from the temporal history.

This view is the main interface for compliance dashboards, customer risk lookups, and downstream data exports. `V_RiskClassification_4_SynapseExport` and `V_RiskClassification_4_SynapseExport2` are wrappers that alias this view's columns for data lake compatibility.

The view uses a CTE to find each customer's most recent historical risk score (excluding a data correction window 2021-03-07 to 2021-03-10). It OUTER APPLYs `V_Scores` with `String_agg(S.RCP, ',')` to build the explanation string from all parameters with non-zero scores (excluding parameter 9999, the final score itself).

---

## 2. Business Logic

### 2.1 Risk Score Explanation

**What**: Builds a comma-separated list of parameter names that contributed non-zero scores to the customer's risk classification.

**Columns/Parameters Involved**: `RiskScore_Explanation`

**Rules**:
- Uses `OUTER APPLY` on `V_Scores` for the same GCID
- Filters: `RiskScore <> 0 AND RiskClassificationParameterID <> 9999` (exclude zero-score and final-score parameters)
- Aggregates with `String_agg(S.RCP, ',')` to produce comma-separated parameter names
- ISNULL wraps the result to default to '' if no parameters have non-zero scores
- Example output: "Country of Residence, Onboarding,Screening Status,NFTF"

### 2.2 Previous Risk Score Tracking

**What**: Shows the customer's previous risk classification before the current one, enabling change detection.

**Columns/Parameters Involved**: `PreviousRisk`, `PreviousRiskUpdateDate`

**Rules**:
- CTE `historyDate` finds `MAX(BeginTime)` per GCID from `History.T_RiskClassification`
- Excludes dates between 2021-03-07 00:00 and 2021-03-10 14:00 (known data correction window - bulk re-scoring occurred and should not count as "previous")
- CTE `history` JOINs back to get the RiskScore at that historical point
- `PreviousRisk`: the risk score from the most recent historical version
- `PreviousRiskUpdateDate`: when that previous score was set (NULL if no history exists)
- CASE expression returns NULL date when no history row exists (h.GCID IS NULL)

### 2.3 Data Correction Window Exclusion

**What**: Historical lookback deliberately skips a known bad data period.

**Columns/Parameters Involved**: `PreviousRisk`, `PreviousRiskUpdateDate`

**Rules**:
- Period: 2021-03-07 00:00 to 2021-03-10 14:00
- Likely a bulk re-classification run that would make "previous score" misleading
- The exclusion ensures PreviousRisk reflects the last genuine organic score change, not a mass correction

---

## 3. Data Overview

| GCID | CID | Regulation | RiskScore | RiskScoreName | RiskScore_Explanation | PreviousRisk | PreviousRiskUpdateDate | Meaning |
|------|-----|-----------|-----------|--------------|----------------------|-------------|----------------------|---------|
| 11 | 683703 | CySEC | 50 | Medium | NFTF | 0 (Low) | 2021-02-24 | CySEC customer currently at Medium risk. Only one parameter (NFTF - Non-Face-To-Face) has a non-zero score. Previously was Low (0), changed in Feb 2021. |
| 91 | 683770 | CySEC | 100 | High | Country of Residence, Onboarding,Country of Residence, Existing clients,Screening Status,NFTF | 50 (Medium) | 2023-04-23 | CySEC customer at High risk. Four parameters contributing: both country scores, screening status, and NFTF. Upgraded from Medium (50) in Apr 2023. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskScore_Explanation | VARCHAR(MAX) | YES | - | VERIFIED | Comma-separated list of risk parameter names with non-zero scores. Built via `String_agg(S.RCP, ',')` from V_Scores where `RiskScore <> 0 AND ParameterID <> 9999`. Defaults to '' via ISNULL when no parameters are non-zero. |
| 2 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name from Dictionary.Regulation via INNER JOIN on RegulationID. E.g., "CySEC", "FCA". |
| 3 | RiskScoreName | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation via INNER JOIN on RiskScore + RegulationID. E.g., "Low", "Medium", "High". See [Risk Classification Regulation](_glossary.md#risk-classification-regulation). |
| 4 | R.* | (all T_RiskClassification columns) | - | - | VERIFIED | All columns from T_RiskClassification passed through via `R.*`. See [dbo.T_RiskClassification](../Tables/dbo.T_RiskClassification.md) for full element descriptions (99 columns including GCID, CID, RegulationID, RiskScore, RiskScore_Value, BeginTime, EndTime, and all parameter score/value pairs). |
| 5 | PreviousRisk | INT | YES | - | VERIFIED | Customer's risk score from the most recent historical version (before current). Derived from CTE on History.T_RiskClassification. NULL if no history exists. Excludes 2021-03-07 to 2021-03-10 correction window. |
| 6 | PreviousRiskUpdateDate | DATETIME2 | YES | - | VERIFIED | When the previous risk score was set. NULL if no history exists (uses CASE WHEN h.GCID IS NULL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.T_RiskClassification | Base table | All current customer risk scores |
| LEFT JOIN | History.T_RiskClassification (via CTE) | History lookup | Previous risk score retrieval |
| OUTER APPLY | dbo.V_Scores | Subquery | Score explanation aggregation |
| INNER JOIN | Dictionary.Regulation | Lookup | Regulation name resolution |
| INNER JOIN | Dictionary.RiskClassificationRegulation | Lookup | Risk level name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassification_4_SynapseExport | FROM | Consumer | Synapse export view wrapping all columns with sanitized aliases |
| dbo.V_RiskClassification_4_SynapseExport2 | FROM R | Consumer | Synapse export v2 with additional RiskScoreName JOIN |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassification (view)
+-- dbo.T_RiskClassification (table)
+-- History.T_RiskClassification (table)
+-- dbo.V_Scores (view)
|   +-- dbo.T_Scores (table)
|   +-- Dictionary.Regulation (table)
|   +-- Dictionary.RiskClassificationParameter (table)
|   +-- Dictionary.RiskClassificationRegulation (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_RiskClassification | Table | FROM - base data |
| History.T_RiskClassification | Table | CTE - previous risk score lookup |
| dbo.V_Scores | View | OUTER APPLY - score explanation aggregation |
| Dictionary.Regulation | Table | INNER JOIN - regulation name |
| Dictionary.RiskClassificationRegulation | Table | INNER JOIN - risk level name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification_4_SynapseExport | View | FROM - wraps all columns |
| dbo.V_RiskClassification_4_SynapseExport2 | View | FROM R - wraps with extra JOIN |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get a customer's full risk profile with explanation
```sql
SELECT GCID, CID, Regulation, RiskScoreName, RiskScore,
       RiskScore_Explanation, PreviousRisk, PreviousRiskUpdateDate
FROM dbo.V_RiskClassification WITH (NOLOCK)
WHERE GCID = 91
```

### 8.2 Find customers whose risk increased since last assessment
```sql
SELECT GCID, Regulation, RiskScoreName, RiskScore, PreviousRisk,
       RiskScore - PreviousRisk AS ScoreIncrease
FROM dbo.V_RiskClassification WITH (NOLOCK)
WHERE RiskScore > ISNULL(PreviousRisk, 0)
  AND PreviousRisk IS NOT NULL
```

### 8.3 Distribution of risk levels by regulation
```sql
SELECT Regulation, RiskScoreName, COUNT(*) AS CustomerCount
FROM dbo.V_RiskClassification WITH (NOLOCK)
GROUP BY Regulation, RiskScoreName
ORDER BY Regulation, RiskScoreName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassification | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassification.sql*
