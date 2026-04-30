# dbo.V_RiskClassification_4_SynapseExport2

> Second version of the Synapse export view that wraps V_RiskClassification with sanitized column names and adds the RiskScoreName column via an additional JOIN to Dictionary.RiskClassificationRegulation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base view: dbo.V_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the second version of the Synapse export view. It differs from V_RiskClassification_4_SynapseExport in one key way: it adds an explicit `RiskScoreName` column by performing its own INNER JOIN to `Dictionary.RiskClassificationRegulation` (even though V_RiskClassification already includes this). This suggests the downstream Synapse pipeline needed the risk level name as a separate, explicitly named column.

Like v1, it sanitizes column names, aliases RiskScore to Finalscore_RiskScore, and adds PreviousRiskScore/PreviousRiskUpdateDate. Same exclusions apply (PEP Check, Place of Birth, Instruments Planned Investment commented out).

---

## 2. Business Logic

No additional business logic beyond V_RiskClassification. The only structural difference from v1 is the addition of `CR.Name AS RiskScoreName` via a redundant JOIN to Dictionary.RiskClassificationRegulation.

---

## 3. Data Overview

Same data as V_RiskClassification_4_SynapseExport with the addition of the RiskScoreName column.

---

## 4. Elements

Same as V_RiskClassification_4_SynapseExport with the addition of:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-91 | (same as SynapseExport v1) | - | - | - | CODE-BACKED | See [dbo.V_RiskClassification_4_SynapseExport](dbo.V_RiskClassification_4_SynapseExport.md) for all shared columns. |
| 92 | RiskScoreName | VARCHAR(20) | YES | - | CODE-BACKED | Named risk level from Dictionary.RiskClassificationRegulation via explicit INNER JOIN on `R.RiskScore = CR.RiskScore AND R.RegulationID = CR.RegulationID`. E.g., "Low", "Medium", "High". Added in v2 for explicit downstream consumption. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM R | dbo.V_RiskClassification | Base view | Wraps all columns |
| INNER JOIN | Dictionary.RiskClassificationRegulation | Lookup | Explicit risk level name resolution (redundant with V_RiskClassification but needed for explicit column) |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassification_4_SynapseExport2 (view)
+-- dbo.V_RiskClassification (view)
|   +-- dbo.T_RiskClassification (table)
|   +-- History.T_RiskClassification (table)
|   +-- dbo.V_Scores (view)
|   +-- Dictionary.Regulation (table)
|   +-- Dictionary.RiskClassificationRegulation (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification | View | FROM R |
| Dictionary.RiskClassificationRegulation | Table | INNER JOIN for RiskScoreName |

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

### 8.1 Query with risk level name
```sql
SELECT GCID, Regulation, RiskScoreName, Finalscore_RiskScore,
       RiskScore_Explanation, PreviousRiskScore
FROM dbo.V_RiskClassification_4_SynapseExport2 WITH (NOLOCK)
WHERE GCID = 91
```

### 8.2 Risk level distribution
```sql
SELECT Regulation, RiskScoreName, Finalscore_RiskScore, COUNT(*) AS Cnt
FROM dbo.V_RiskClassification_4_SynapseExport2 WITH (NOLOCK)
GROUP BY Regulation, RiskScoreName, Finalscore_RiskScore
ORDER BY Regulation, Finalscore_RiskScore
```

### 8.3 Compare v1 and v2 for same customer
```sql
SELECT 'v1' AS Version, GCID, Finalscore_RiskScore, Regulation
FROM dbo.V_RiskClassification_4_SynapseExport WITH (NOLOCK) WHERE GCID = 91
UNION ALL
SELECT 'v2', GCID, Finalscore_RiskScore, Regulation
FROM dbo.V_RiskClassification_4_SynapseExport2 WITH (NOLOCK) WHERE GCID = 91
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 92 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassification_4_SynapseExport2 | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassification_4_SynapseExport2.sql*
