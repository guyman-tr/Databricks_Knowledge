# dbo.V_RiskClassificationDataLake

> BI/data lake oriented view that enriches T_RiskClassification with regulation names, risk explanations, and previous risk scores, with column names sanitized (spaces removed) for data lake compatibility.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: dbo.T_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the data lake / BI export variant of V_RiskClassification. It is structurally almost identical to V_RiskClassification but explicitly lists and renames every column with sanitized aliases (removing spaces and commas from column names). Created by Yulia Kramer on 2021-05-25 (COAIL-2799, COAIL-2800) for BI schema changes.

The view serves as a stable, BI-friendly interface to the risk classification data. By explicitly selecting and aliasing each column rather than using `R.*`, it provides a contract that external BI tools can rely on even if the base table schema changes.

Uses the same CTE pattern for previous risk score and the same OUTER APPLY to V_Scores for explanation string as V_RiskClassification. Does not include Screening Status or Place of Birth columns (commented out as "did not find such parameter" / "no values").

---

## 2. Business Logic

### 2.1 Same as V_RiskClassification

See [dbo.V_RiskClassification](dbo.V_RiskClassification.md) Section 2 for full business logic (RiskScore_Explanation, Previous Risk Tracking, Data Correction Window Exclusion). This view inherits identical logic.

---

## 3. Data Overview

Output is identical to V_RiskClassification but with sanitized column names (e.g., `CountryofResidenceOnboarding_RiskScore` instead of `Country of Residence, Onboarding_RiskScore`).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskScore_Explanation | VARCHAR(MAX) | YES | - | VERIFIED | Same as V_RiskClassification. Comma-separated non-zero parameter names. |
| 2 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name from Dictionary.Regulation. |
| 3 | RiskScoreName | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation. |
| 4 | GCID | INT | NO | - | VERIFIED | Global Customer ID. |
| 5 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 6 | RegulationID | INT | YES | - | CODE-BACKED | Regulation ID. See [Regulation](_glossary.md#regulation). |
| 7 | RiskScore | INT | YES | - | VERIFIED | Final aggregate risk score. |
| 8 | RiskScore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Score formula in N*Score format. |
| 9 | BeginTime | DATETIME2(7) | NO | - | CODE-BACKED | Temporal row start. |
| 10 | EndTime | DATETIME2(7) | NO | - | CODE-BACKED | Temporal row end. |
| 11-90 | *_RiskScore / *_Value (sanitized names) | INT/VARCHAR(50) | YES | - | CODE-BACKED | All parameter score and value columns with sanitized aliases. E.g., `CountryofResidenceOnboarding_RiskScore`, `AgeofCustomer_Value`. Same data as T_RiskClassification. PEP Check and Place of Birth columns excluded (commented out). |
| 91 | PreviousRisk | INT | YES | - | VERIFIED | Previous risk score from history CTE. |
| 92 | PreviousRiskUpdateDate | DATETIME2 | YES | - | VERIFIED | When previous risk score was set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.T_RiskClassification | Base table | Current risk scores |
| LEFT JOIN CTE | History.T_RiskClassification | History | Previous risk lookup |
| OUTER APPLY | dbo.V_Scores | Subquery | Score explanation |
| INNER JOIN | Dictionary.Regulation | Lookup | Regulation name |
| INNER JOIN | Dictionary.RiskClassificationRegulation | Lookup | Risk level name |

### 5.2 Referenced By (other objects point to this)

No dependents found. Consumed by external BI/data lake pipelines.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassificationDataLake (view)
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
| dbo.T_RiskClassification | Table | FROM |
| History.T_RiskClassification | Table | CTE for previous risk |
| dbo.V_Scores | View | OUTER APPLY for explanation |
| Dictionary.Regulation | Table | INNER JOIN |
| Dictionary.RiskClassificationRegulation | Table | INNER JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Query with sanitized column names for BI
```sql
SELECT GCID, Regulation, RiskScoreName, RiskScore,
       CountryofResidenceOnboarding_RiskScore,
       CountryofResidenceOnboarding_Value,
       PreviousRisk, PreviousRiskUpdateDate
FROM dbo.V_RiskClassificationDataLake WITH (NOLOCK)
WHERE GCID = 91
```

### 8.2 Export for data lake pipeline
```sql
SELECT * FROM dbo.V_RiskClassificationDataLake WITH (NOLOCK)
WHERE BeginTime >= '2024-01-01'
```

### 8.3 Risk change analysis
```sql
SELECT Regulation, RiskScoreName, COUNT(*) AS Customers
FROM dbo.V_RiskClassificationDataLake WITH (NOLOCK)
GROUP BY Regulation, RiskScoreName
ORDER BY Regulation, RiskScoreName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 86 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassificationDataLake | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassificationDataLake.sql*
