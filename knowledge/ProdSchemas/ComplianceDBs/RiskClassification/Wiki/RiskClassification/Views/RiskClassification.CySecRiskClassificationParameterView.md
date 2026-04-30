# RiskClassification.CySecRiskClassificationParameterView

> CySEC-specific scoring rules view that enriches CySecRiskClassificationParameter with parameter names, regulation names, and risk level labels from Dictionary tables, excluding the final score parameter (9999).

| Property | Value |
|----------|-------|
| **Schema** | RiskClassification |
| **Object Type** | View |
| **Key Identifier** | Base table: RiskClassification.CySecRiskClassificationParameter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view is the CySEC-specific equivalent of `dbo.V_RiskClassificationParameter`. It enriches the `RiskClassification.CySecRiskClassificationParameter` scoring rules table with human-readable names by joining to Dictionary tables. It resolves parameter IDs to names, regulation IDs to names, and risk score values to named levels (Low/Medium/High).

The view explicitly excludes parameter 9999 (Final score) via `WHERE ParameterID <> 9999`, showing only individual parameter scoring rules. It includes special handling for parameter 9999 in its column expressions (IIF for Value and Value1) even though the WHERE clause filters it out - this is likely inherited from the dbo.V_RiskClassificationParameter view it was modeled after.

Used by compliance and configuration management teams to audit and understand the CySEC-specific scoring rules.

---

## 2. Business Logic

### 2.1 Final Score Exclusion

**What**: Parameter 9999 is excluded from this view.

**Columns/Parameters Involved**: `WHERE ParameterID <> 9999`

**Rules**:
- The Final score parameter (9999) has a different Value format ("prefix,value") not relevant for individual parameter review
- The view focuses on individual scoring rules, not the aggregate

### 2.2 Value/Value1 Parsing (inherited, effectively unused)

**What**: Special parsing for parameter 9999 is coded but never executes due to WHERE filter.

**Columns/Parameters Involved**: `Value`, `Value1`

**Rules**:
- `Value`: For 9999, strips prefix via Stuff(). For others, passes through raw Value.
- `Value1`: For 9999, extracts numeric prefix. For others, NULL.
- Since 9999 is filtered out, Value always passes through and Value1 is always NULL.

---

## 3. Data Overview

Same data as querying CySecRiskClassificationParameter directly, enriched with names. See [RiskClassification.CySecRiskClassificationParameter](../Tables/RiskClassification.CySecRiskClassificationParameter.md) for sample data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Parameter ID (aliased from `RCP.ParameterID`). See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 2 | RiskClassificationParameter | VARCHAR(50) | YES | - | VERIFIED | Parameter name from Dictionary.RiskClassificationParameter (`DCP.Name`). E.g., "Country of Residence, Onboarding". |
| 3 | RegulationID | INT | NO | - | VERIFIED | Regulation ID. See [Regulation](../_glossary.md#regulation). |
| 4 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name from Dictionary.Regulation (`R.Name`). E.g., "CySEC". |
| 5 | RiskClassificationParameterOption | INT | NO | - | CODE-BACKED | Option/row ID within parameter+regulation (`RCP.ID`). 0 = default rule. |
| 6 | Value | VARCHAR(500) | YES | - | VERIFIED | Input value matching criteria. Passes through from base table (9999 parsing never executes). |
| 7 | Value1 | INT | YES | - | CODE-BACKED | Always NULL (9999 parsing never executes due to WHERE filter). |
| 8 | RiskClassificationID | INT | YES | - | CODE-BACKED | Raw risk score from base table (`RCP.RiskClassificationID`). |
| 9 | RiskClassification | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation (`RCR.Name`). "Low", "Medium", "High". |
| 10 | RiskScore | INT | YES | - | CODE-BACKED | Same as RiskClassificationID (aliased). |
| 11 | ValidationText | VARCHAR(100) | YES | - | CODE-BACKED | Rule description. "Default" for fallback rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | RiskClassification.CySecRiskClassificationParameter | Base table | CySEC scoring rules |
| INNER JOIN | Dictionary.RiskClassificationParameter | Lookup | Parameter name |
| INNER JOIN | Dictionary.Regulation | Lookup | Regulation name |
| LEFT JOIN | Dictionary.RiskClassificationRegulation | Lookup | Risk level name |

### 5.2 Referenced By (other objects point to this)

No dependents found. Used by compliance teams for CySEC rule auditing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RiskClassification.CySecRiskClassificationParameterView (view)
+-- RiskClassification.CySecRiskClassificationParameter (table)
|   +-- Dictionary.CySecRiskClassificationParameter (table) [FK]
+-- Dictionary.RiskClassificationParameter (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.CySecRiskClassificationParameter | Table | FROM - base data |
| Dictionary.RiskClassificationParameter | Table | INNER JOIN - parameter name |
| Dictionary.Regulation | Table | INNER JOIN - regulation name |
| Dictionary.RiskClassificationRegulation | Table | LEFT JOIN - risk level name |

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

### 8.1 View all CySEC scoring rules with names
```sql
SELECT RiskClassificationParameterID, RiskClassificationParameter,
       Regulation, RiskClassificationParameterOption,
       Value, RiskScore, RiskClassification, ValidationText
FROM RiskClassification.CySecRiskClassificationParameterView WITH (NOLOCK)
ORDER BY RiskClassificationParameterID, RegulationID, RiskClassificationParameterOption
```

### 8.2 Find all high-risk CySEC rules
```sql
SELECT RiskClassificationParameter, Regulation, Value, RiskScore, RiskClassification
FROM RiskClassification.CySecRiskClassificationParameterView WITH (NOLOCK)
WHERE RiskScore >= 100
```

### 8.3 Compare CySEC rules vs main BackOffice rules
```sql
SELECT 'CySEC' AS Source, RiskClassificationParameterID, Value, RiskScore
FROM RiskClassification.CySecRiskClassificationParameterView WITH (NOLOCK)
WHERE RiskClassificationParameterID = 2
UNION ALL
SELECT 'BackOffice', RiskClassificationParameterID, Value, RiskScore
FROM dbo.V_RiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationParameterID = 2
ORDER BY Source, RiskClassificationParameterID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RiskClassification.CySecRiskClassificationParameterView | Type: View | Source: RiskClassification/RiskClassification/Views/RiskClassification.CySecRiskClassificationParameterView.sql*
