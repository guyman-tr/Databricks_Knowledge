# dbo.V_Scores

> Enriched view over T_Scores that resolves regulation IDs, parameter IDs, and risk scores to their human-readable names, providing the primary queryable interface for individual customer risk parameter scores.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.T_Scores |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the enriched, human-readable layer over the normalized `T_Scores` table. It JOINs to three Dictionary tables to resolve all foreign key IDs into names: `Dictionary.Regulation` provides the regulation name, `Dictionary.RiskClassificationParameter` provides the parameter name (aliased as `RCP`), and `Dictionary.RiskClassificationRegulation` provides the risk level name (e.g., "Low", "Medium", "High").

V_Scores is consumed by the main `V_RiskClassification` view (which uses `String_agg(S.RCP, ',')` to build the `RiskScore_Explanation` field), by `P_GetRiskClassification` (which shows the explanation alongside the detailed score), and by `P_RiskClassification` (which pivots the data into T_RiskClassification). It is the single most connected view in the dbo schema.

The view reads from T_Scores with NOLOCK hints on all tables for performance. It applies `ISNULL(S.RiskScore, 0)` to treat NULL scores as 0 when joining to the risk classification regulation lookup, ensuring every row gets a risk level name even if the score is NULL.

---

## 2. Business Logic

### 2.1 NULL Score Handling

**What**: NULL risk scores are treated as 0 (Low) for risk level name resolution.

**Columns/Parameters Involved**: `RiskScore`, `RiskScoreName`

**Rules**:
- `ISNULL(S.RiskScore, 0)` is used in the JOIN to Dictionary.RiskClassificationRegulation
- This means a NULL score maps to the "Low" risk level name, not to a NULL name
- The raw `RiskScore` column still shows the original value (including NULL if applicable) via `ISNULL(S.RiskScore, 0) AS RiskScore`

---

## 3. Data Overview

| GCID | Regulation | ParameterID | RCP (Parameter Name) | RiskScore | RiskScoreName | Value | Meaning |
|------|-----------|------------|---------------------|-----------|--------------|-------|---------|
| 91 | CySEC | 2 | Country of Residence, Onboarding | 50 | Medium | Turkey | CySEC customer from Turkey. Country risk resolved to "Medium" level. RCP column provides the human-readable parameter name used in risk explanation strings. |
| 91 | CySEC | 5 | Age of customer | 0 | Low | 44 | Age 44 scores 0, resolved to "Low" risk level. |
| 91 | CySEC | 7 | Screening Status | 100 | High | 2 | Screening flag value "2" produces maximum score 100, resolved to "High" risk level. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. From T_Scores. Inherited: unique customer identifier across eToro platform. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. From T_Scores. Secondary customer identifier. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction ID. From T_Scores. See [Regulation](_glossary.md#regulation). |
| 4 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name resolved from Dictionary.Regulation via `R.Name`. E.g., "CySEC", "FCA", "ASIC". Human-readable version of RegulationID. |
| 5 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter ID. From T_Scores. See [Risk Classification Parameter](_glossary.md#risk-classification-parameter). |
| 6 | RCP | VARCHAR(50) | YES | - | VERIFIED | Risk Classification Parameter name, aliased as RCP. Resolved from Dictionary.RiskClassificationParameter via `DP.Name`. E.g., "Country of Residence, Onboarding", "Age of customer". Used by V_RiskClassification to build the `RiskScore_Explanation` via `String_agg(S.RCP, ',')`. |
| 7 | RiskScore | INT | - | - | VERIFIED | Risk score for this parameter. Computed as `ISNULL(S.RiskScore, 0)` - NULL scores are treated as 0. Values: 0 (Low), 50 (Medium), 100 (High). |
| 8 | RiskScoreName | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation via `RCR.Name`. Resolved by matching `ISNULL(S.RiskScore, 0) = RCR.RiskScore AND S.RegulationID = RCR.RegulationID`. Values: "Low", "Medium Low", "Medium", "Medium High", "High", "Unacceptable", "Block" depending on regulation. See [Risk Classification Regulation](_glossary.md#risk-classification-regulation). |
| 9 | Value | VARCHAR(100) | YES | - | VERIFIED | Raw value/label from T_Scores. Country names for country params, age for age params, screening codes, questionnaire answers, etc. |
| 10 | BeginTime | DATETIME2(7) | NO | - | CODE-BACKED | Temporal row start from T_Scores. When this score became effective. |
| 11 | EndTime | DATETIME2(7) | NO | - | CODE-BACKED | Temporal row end from T_Scores. Far-future for current rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.T_Scores | Base table | Source of all score data |
| INNER JOIN | Dictionary.Regulation | Lookup | Resolves RegulationID to regulation Name |
| INNER JOIN | Dictionary.RiskClassificationParameter | Lookup | Resolves RiskClassificationParameterID to parameter Name (RCP) |
| INNER JOIN | Dictionary.RiskClassificationRegulation | Lookup | Resolves RiskScore + RegulationID to named risk level (RiskScoreName) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassification | OUTER APPLY | Consumer | Uses String_agg(S.RCP, ',') to build RiskScore_Explanation for non-zero, non-9999 parameters |
| dbo.V_RiskClassificationDataLake | OUTER APPLY | Consumer | Same pattern as V_RiskClassification for data lake export |
| dbo.P_GetRiskClassification | FROM V_Scores (dynamic SQL) | Reader | Reads to build risk explanation alongside detailed customer score |
| dbo.P_RiskClassification | FROM V_Scores | Reader | Reads to pivot scores into T_RiskClassification wide-column format |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_Scores (view)
+-- dbo.T_Scores (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskClassificationParameter (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_Scores | Table | FROM - base data source |
| Dictionary.Regulation | Table | INNER JOIN ON S.RegulationID = R.ID |
| Dictionary.RiskClassificationParameter | Table | INNER JOIN ON S.RiskClassificationParameterID = DP.RiskClassificationParameterID |
| Dictionary.RiskClassificationRegulation | Table | INNER JOIN ON S.RegulationID = RCR.RegulationID AND ISNULL(S.RiskScore,0) = RCR.RiskScore |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification | View | OUTER APPLY for score explanation aggregation |
| dbo.V_RiskClassificationDataLake | View | OUTER APPLY for score explanation aggregation |
| dbo.P_GetRiskClassification | Stored Procedure | Reader via dynamic SQL |
| dbo.P_RiskClassification | Stored Procedure | Reader for pivot to T_RiskClassification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Get all enriched scores for a specific customer
```sql
SELECT GCID, Regulation, RiskClassificationParameterID, RCP, RiskScore, RiskScoreName, Value
FROM dbo.V_Scores WITH (NOLOCK)
WHERE GCID = 91
ORDER BY RiskClassificationParameterID
```

### 8.2 Find all customers with High screening status via enriched view
```sql
SELECT GCID, Regulation, RiskScore, RiskScoreName, Value
FROM dbo.V_Scores WITH (NOLOCK)
WHERE RiskClassificationParameterID = 7 AND RiskScore = 100
```

### 8.3 Build risk explanation string for a customer (same logic as V_RiskClassification)
```sql
SELECT GCID, STRING_AGG(RCP, ',') AS RiskScore_Explanation
FROM dbo.V_Scores WITH (NOLOCK)
WHERE GCID = 91 AND RiskScore <> 0 AND RiskClassificationParameterID <> 9999
GROUP BY GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 8 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (P_RiskClassification, P_GetRiskClassification) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_Scores | Type: View | Source: RiskClassification/dbo/Views/dbo.V_Scores.sql*
