# Dictionary.RiskClassificationParameter

> Master lookup table defining all risk classification parameters (scoring factors) with their names, descriptions, data sources, and weight percentages for weekly and onboarding assessments.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RiskClassificationParameterID (INT, CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the master dictionary of all risk assessment parameters used in the risk classification system. Each row defines one risk factor (e.g., "Country of Residence", "Age of customer", "Screening Status") with its human-readable name, description, data source, and weighting percentages. The parameter IDs are the key linkage between the normalized scoring tables (T_Scores), the configuration tables (BackOffice.RiskClassificationParameter), and the views.

Three tiers of parameters exist: standard parameters (IDs 2-21) with defined weights and external data sources, CySEC Enhanced Due Diligence parameters (IDs 1001-1025) with zero weight, and the special "Final score" parameter (ID 9999) representing the aggregate result.

---

## 2. Business Logic

### 2.1 Parameter Tiers

**What**: Parameters are organized into functional tiers based on ID ranges.

**Columns/Parameters Involved**: `RiskClassificationParameterID`, `WeeklyWeightPercent`, `OnboardingWeightPrcent`

**Rules**:
- IDs 2-21: Standard parameters. Have non-zero weights and identified data sources. Used in both weekly re-assessment and onboarding scoring.
- IDs 1001-1025: CySEC EDD parameters. All have zero weight - scored independently for enhanced due diligence. No defined data source.
- ID 9999: "Final score" - the aggregate result. Zero weight (it IS the final result, not an input).
- Weights represent the parameter's contribution to the composite score. Weekly and onboarding weights differ.

### 2.2 Data Source Tracking

**What**: Each standard parameter records where its input data comes from.

**Columns/Parameters Involved**: `Source`

**Rules**:
- Sources reference specific tables/views in external databases: Customer.CustomerStatic, V_CustomerAnswersNrml, Billing.Deposit, BackOffice.CustomerAllTimeAggregatedData, UserApiDB_rep.Customer.ExtendedUserField
- CySEC EDD parameters (1001-1025) have NULL source - data is collected through enhanced due diligence processes
- The source column helps trace data lineage from the originating system to the risk score

---

## 3. Data Overview

| ID | Name | Description | Source | WeeklyWeight | OnboardingWeight | Meaning |
|----|------|------------|--------|-------------|-----------------|---------|
| 2 | Country of Residence, Onboarding | Country by Reg. Form - Onboarding | Customer.CustomerStatic | 2.5% | 4% | Customer's registration country risk at onboarding. One of the highest-weighted parameters. |
| 7 | Screening Status | Screening Service | NULL | 5.2% | 6.5% | External screening/sanctions check. Highest weighted parameter overall - sanctions hits dominate the score. |
| 9999 | Final score | Final Score | NULL | 0% | 0% | The aggregate composite risk classification result. Not a scoring input. |

See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter) for complete value map with all 46 entries.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Parameter identifier. PK. IDs 2-21 = standard params, 1001-1025 = CySEC EDD params, 9999 = final score. Referenced by T_Scores, BackOffice.RiskClassificationParameter, and all scoring views. |
| 2 | Name | VARCHAR(50) | YES | - | VERIFIED | Human-readable parameter name. E.g., "Country of Residence, Onboarding", "Screening Status", "Final score". Used as display label in V_Scores (aliased as RCP) and V_RiskClassificationParameter. |
| 3 | Description | VARCHAR(MAX) | YES | - | VERIFIED | Detailed description of the parameter. Contains questionnaire question references (e.g., "Q15 Main income A89/90/105=Social security/Family financial support/Other"), scoring logic hints, and source field mappings. NULL for CySEC EDD parameters. |
| 4 | Source | VARCHAR(200) | YES | - | VERIFIED | External data source table/view that provides the input for this parameter. E.g., "Customer.CustomerStatic", "V_CustomerAnswersNrml", "Billing.Deposit". NULL for CySEC EDD params and Final score. Traces data lineage. |

Note: The live database has additional columns `WeeklyWeightPercent` and `OnboardingWeightPrcent` (DECIMAL) that are not in the SSDT DDL file. These store the weight percentages for weekly re-assessment and onboarding scoring respectively.

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a root lookup table.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.T_Scores | RiskClassificationParameterID | Implicit FK | Identifies which parameter each score row represents |
| dbo.V_Scores | INNER JOIN ON ParameterID | Lookup | Parameter name resolution (aliased as RCP) |
| dbo.V_RiskClassificationParameter | INNER JOIN ON ParameterID | Lookup | Parameter name for config view |
| dbo.P_RiskClassification | SELECT FROM | Reader | Discovers new parameters for dynamic schema evolution |
| BackOffice.RiskClassificationParameter | RiskClassificationParameterID | Explicit FK | Scoring rules reference this for parameter validation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_Scores | View | INNER JOIN for parameter name |
| dbo.V_RiskClassificationParameter | View | INNER JOIN for parameter name |
| dbo.P_RiskClassification | Stored Procedure | Reads for dynamic schema evolution |
| BackOffice.RiskClassificationParameter | Table | FK constraint on ParameterID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RiskClassificationParameter | CLUSTERED PK | RiskClassificationParameterID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RiskClassificationParameter | PRIMARY KEY | RiskClassificationParameterID |

---

## 8. Sample Queries

### 8.1 List all parameters with weights
```sql
SELECT RiskClassificationParameterID, Name, Description, Source
FROM Dictionary.RiskClassificationParameter WITH (NOLOCK)
ORDER BY RiskClassificationParameterID
```

### 8.2 Find standard parameters (with weights)
```sql
SELECT RiskClassificationParameterID, Name, Source
FROM Dictionary.RiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationParameterID BETWEEN 2 AND 21
ORDER BY RiskClassificationParameterID
```

### 8.3 Show parameter usage in scoring
```sql
SELECT p.RiskClassificationParameterID, p.Name, COUNT(s.GCID) AS CustomersScored
FROM Dictionary.RiskClassificationParameter p WITH (NOLOCK)
LEFT JOIN dbo.T_Scores s WITH (NOLOCK) ON p.RiskClassificationParameterID = s.RiskClassificationParameterID
GROUP BY p.RiskClassificationParameterID, p.Name
ORDER BY CustomersScored DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (P_RiskClassification) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskClassificationParameter | Type: Table | Source: RiskClassification/Dictionary/Tables/Dictionary.RiskClassificationParameter.sql*
