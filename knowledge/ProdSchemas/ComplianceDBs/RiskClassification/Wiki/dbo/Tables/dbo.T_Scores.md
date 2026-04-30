# dbo.T_Scores

> Normalized customer risk scores table storing one row per customer per risk classification parameter, serving as the canonical source for individual parameter-level risk assessments that feed into the aggregate T_RiskClassification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | GCID + RiskClassificationParameterID (INT + INT, composite CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the normalized scoring table at the heart of the risk classification system. While `T_RiskClassification` stores a denormalized wide-column view (one row per customer with ~100 score columns), `T_Scores` stores the same data in normalized form: one row per customer per risk parameter. Each row records which parameter was assessed, what score it received, and what value was used.

This table is critical for several reasons: (1) it feeds the `V_Scores` view which provides enriched, human-readable score data; (2) it is the source for the `P_RiskClassification` procedure which pivots scores into `T_RiskClassification`; (3) it enables flexible querying of individual parameter scores without parsing the wide-column format; and (4) it supports schema evolution - new parameters can be added without DDL changes.

Data arrives via the `P_RiskClassification` procedure, which MERGEs rows from `T_ScoresTemporary` (the staging table populated by the external risk calculation engine). The MERGE performs UPDATE for changed scores and INSERT for new customer-parameter combinations. The parameter ID 9999 stores the final aggregate score. The table is temporal, preserving the full history of every score change in `History.T_Scores`.

---

## 2. Business Logic

### 2.1 Normalized Score Storage Pattern

**What**: One row per customer per risk parameter, enabling flexible querying and schema-independent parameter addition.

**Columns/Parameters Involved**: `GCID`, `RiskClassificationParameterID`, `RiskScore`, `Value`

**Rules**:
- Composite PK (GCID + RiskClassificationParameterID) ensures one score per parameter per customer
- Standard parameters (IDs 2-21) carry individual risk factor scores
- CySEC EDD parameters (IDs 1001-1025) carry enhanced due diligence scores
- Parameter ID 9999 ("Final score") holds the aggregate composite risk score
- The `P_RiskClassification` procedure reads this data (via V_Scores) to pivot into T_RiskClassification's wide columns

**Diagram**:
```
External Risk Engine -> T_ScoresTemporary (staging)
                              |
                        P_RiskClassification (MERGE)
                              |
                        T_Scores (normalized)
                              |
                    +-------------------+
                    |                   |
              V_Scores (enriched)   P_RiskClassification (pivot)
                    |                   |
              P_GetRiskClassification   T_RiskClassification (wide)
                                        |
                                  V_RiskClassification (views)
```

### 2.2 Score Change Detection via MERGE

**What**: The P_RiskClassification procedure uses MERGE to efficiently update only changed scores.

**Columns/Parameters Involved**: `GCID`, `RiskClassificationParameterID`, `CID`, `RegulationID`, `RiskScore`, `Value`

**Rules**:
- MERGE matches on GCID + RiskClassificationParameterID
- UPDATE triggers only when CID, RegulationID, RiskScore, or Value differs (using ISNULL comparisons with sentinel values -999 and '')
- INSERT applies for new customer-parameter combinations not yet in T_Scores
- Temporal versioning captures every change automatically

---

## 3. Data Overview

| GCID | CID | RegulationID | ParameterID | Parameter Name | RiskScore | Value | BeginTime | Meaning |
|------|-----|-------------|------------|----------------|-----------|-------|-----------|---------|
| 91 | 683770 | 1 (CySEC) | 2 | Country of Residence, Onboarding | 50 | Turkey | 2023-04-23 | Customer from Turkey scored at 50 (Medium) for onboarding country risk. Turkey is a medium-risk country for CySEC regulation. |
| 91 | 683770 | 1 (CySEC) | 5 | Age of customer | 0 | 44 | 2023-11-26 | Customer age 44 scores 0 (no risk). Age is within the normal range (21-65). Updated later than country scores. |
| 91 | 683770 | 1 (CySEC) | 7 | Screening Status | 100 | 2 | 2021-02-18 | Screening status value "2" triggers maximum score 100 (High). This is the highest-impact parameter - the screening service flagged this customer. Score dates from 2021. |

Total: ~222M rows (~5M customers x ~44 parameters each).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Part of composite PK with RiskClassificationParameterID. Identifies the customer being scored. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID - secondary identifier. Updated via MERGE from T_ScoresTemporary. |
| 3 | RegulationID | INT | YES | - | VERIFIED | Regulatory jurisdiction for this customer's scoring. FK to Dictionary.Regulation. Determines which weight percentages and thresholds apply to this parameter score. See [Regulation](_glossary.md#regulation). |
| 4 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being scored. Part of composite PK. FK to Dictionary.RiskClassificationParameter. Values: 2-21 (standard params), 1001-1025 (CySEC EDD params), 9999 (final aggregate score). See [Risk Classification Parameter](_glossary.md#risk-classification-parameter). |
| 5 | RiskScore | INT | YES | - | VERIFIED | Numeric risk score for this parameter. Typical values: 0 (Low/no risk), 50 (Medium), 100 (High). For parameter 9999, this is the final aggregate score that maps to Dictionary.RiskClassificationRegulation levels. |
| 6 | Value | VARCHAR(100) | YES | - | VERIFIED | The raw value or label that determined the RiskScore. Contents vary by parameter: country names ("Turkey", "Spain") for country params, age numbers ("44") for age, screening codes ("2") for screening, questionnaire answer codes for financial params. Used by V_Scores for display. |
| 7 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. Set when the score is inserted or updated via P_RiskClassification MERGE. Different parameters may have different BeginTimes for the same customer (updated independently). |
| 8 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit FK | Identifies which risk factor this score represents |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulatory jurisdiction determining score thresholds and weights |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_Scores | S.* | Base table (FROM) | Primary enriched view that JOINs to Dictionary tables for human-readable parameter names and risk level labels |
| dbo.P_RiskClassification | T_Scores (MERGE target) | Writer | MERGE from T_ScoresTemporary; also reads via V_Scores for pivot to T_RiskClassification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (it is a table).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_Scores | View | Base table - enriches with parameter names and regulation info |
| dbo.P_RiskClassification | Stored Procedure | MERGE target from T_ScoresTemporary; also read via V_Scores |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_dbo_T_Scores | CLUSTERED PK | GCID ASC, RiskClassificationParameterID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_dbo_T_Scores_BeginTime | DEFAULT | GETUTCDATE() |
| Df_dbo_T_Scores_EndTime | DEFAULT | '99991231 23:59:59.9999999' |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[T_Scores], DATA_CONSISTENCY_CHECK=ON |

---

## 8. Sample Queries

### 8.1 Get all current scores for a customer with parameter names
```sql
SELECT S.GCID, S.RiskClassificationParameterID, P.Name AS Parameter,
       S.RiskScore, S.Value, S.BeginTime
FROM dbo.T_Scores S WITH (NOLOCK)
INNER JOIN Dictionary.RiskClassificationParameter P WITH (NOLOCK)
    ON S.RiskClassificationParameterID = P.RiskClassificationParameterID
WHERE S.GCID = 91
ORDER BY S.RiskClassificationParameterID
```

### 8.2 Find customers with High screening status
```sql
SELECT S.GCID, S.RiskScore, S.Value, S.BeginTime
FROM dbo.T_Scores S WITH (NOLOCK)
WHERE S.RiskClassificationParameterID = 7
  AND S.RiskScore = 100
```

### 8.3 Get the final aggregate score for a customer with risk level name
```sql
SELECT S.GCID, S.RiskScore, S.Value AS ScoreFormula,
       RCR.Name AS RiskLevel, R.Name AS Regulation
FROM dbo.T_Scores S WITH (NOLOCK)
INNER JOIN Dictionary.Regulation R WITH (NOLOCK) ON S.RegulationID = R.ID
INNER JOIN Dictionary.RiskClassificationRegulation RCR WITH (NOLOCK)
    ON S.RegulationID = RCR.RegulationID AND S.RiskScore = RCR.RiskScore
WHERE S.GCID = 91
  AND S.RiskClassificationParameterID = 9999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (P_RiskClassification) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.T_Scores | Type: Table | Source: RiskClassification/dbo/Tables/dbo.T_Scores.sql*
