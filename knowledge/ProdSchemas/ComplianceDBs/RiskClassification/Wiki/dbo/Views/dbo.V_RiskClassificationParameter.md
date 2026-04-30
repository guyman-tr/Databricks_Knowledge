# dbo.V_RiskClassificationParameter

> Configuration view that presents the complete risk scoring ruleset - showing which input values map to which risk scores for each parameter and regulation combination.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: BackOffice.RiskClassificationParameter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view exposes the risk scoring configuration rules that drive the entire risk classification system. For each combination of regulation and risk parameter, it shows what input values produce what risk scores. This is the "scoring matrix" - the rulebook that the external risk engine uses to convert raw customer data (country codes, age brackets, income levels, etc.) into individual parameter risk scores.

The view is essential for compliance teams to audit and understand the scoring logic, for developers to debug why a customer received a particular score, and for regulatory reporting to demonstrate the scoring methodology. It joins `BackOffice.RiskClassificationParameter` (the configuration rows) with Dictionary tables to resolve IDs to names.

The view includes special handling for parameter ID 9999 (Final score): it uses `IIF(RiskClassificationParameterID=9999, Stuff(Value,1,CharIndex(',',Value),''), Value)` to strip a leading prefix from the Value column, and extracts a numeric `Value1` as `Try_Cast(Left(Value, CharIndex(',',Value)-1) As Int)` for final score rows that use a comma-delimited format.

---

## 2. Business Logic

### 2.1 Scoring Rules Matrix

**What**: Maps input value ranges to risk scores per parameter per regulation.

**Columns/Parameters Involved**: `RiskClassificationParameterID`, `RegulationID`, `Value`, `RiskScore`, `ValidationText`

**Rules**:
- Each row represents one scoring rule: "For parameter X under regulation Y, input value Z produces risk score S"
- Option ID 0 with ValidationText "Default" is the fallback rule when no other option matches
- Value column contains the matching criteria (country risk tier codes, age brackets, etc.)
- RiskScore (aliased from RiskClassificationID) is the resulting score (0, 50, 100)
- RiskClassification column gives the named level ("Low", "Medium", "High")

### 2.2 Final Score Special Handling

**What**: Parameter 9999 uses a different Value format requiring special parsing.

**Columns/Parameters Involved**: `Value`, `Value1`

**Rules**:
- For parameter 9999: Value format is "prefix,actual_value" - the prefix is stripped using `Stuff(Value,1,CharIndex(',',Value),'')`
- `Value1` extracts the numeric prefix: `Try_Cast(Left(Value, CharIndex(',',Value)-1) As Int)`
- For all other parameters: Value is passed through unchanged and Value1 is NULL

---

## 3. Data Overview

| ParameterID | Parameter | RegulationID | Regulation | Option | Value | RiskScore | RiskClassification | ValidationText | Meaning |
|------------|-----------|-------------|-----------|--------|-------|-----------|-------------------|----------------|---------|
| 2 | Country of Residence, Onboarding | 1 | CySEC | 0 | NULL | 0 | Low | Default | Default rule for CySEC onboarding country: if no specific country tier matches, score is 0 (Low). |
| 2 | Country of Residence, Onboarding | 1 | CySEC | 1 | 1 | 50 | Medium | NULL | Country tier "1" produces Medium risk (50) for CySEC onboarding. Tier 1 = medium-risk countries. |
| 2 | Country of Residence, Onboarding | 1 | CySEC | 2 | 2,3 | 100 | High | NULL | Country tiers "2" or "3" produce High risk (100) for CySEC onboarding. These are high-risk/sanctioned country tiers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter ID from BackOffice.RiskClassificationParameter. See [Risk Classification Parameter](_glossary.md#risk-classification-parameter). |
| 2 | RiskClassificationParameter | VARCHAR(50) | YES | - | VERIFIED | Parameter name from Dictionary.RiskClassificationParameter (`DCP.Name`). E.g., "Country of Residence, Onboarding". |
| 3 | RegulationID | INT | NO | - | VERIFIED | Regulation ID from BackOffice.RiskClassificationParameter. See [Regulation](_glossary.md#regulation). |
| 4 | Regulation | VARCHAR(50) | YES | - | VERIFIED | Regulation name from Dictionary.Regulation (`R.Name`). E.g., "CySEC", "FCA". |
| 5 | RiskClassificationParameterOption | INT | NO | - | CODE-BACKED | Option/row ID within the parameter+regulation combination (`RCP.ID`). 0 = default rule, 1+ = specific value-matching rules. |
| 6 | Value | VARCHAR(500) | YES | - | VERIFIED | Input value matching criteria. For parameter 9999: transformed via `IIF(ParameterID=9999, Stuff(...), Value)` to strip prefix. For other parameters: raw value from BackOffice.RiskClassificationParameter (country tier codes, age brackets, etc.). |
| 7 | Value1 | INT | YES | - | CODE-BACKED | Numeric prefix extracted from parameter 9999 Value using `Try_Cast(Left(Value, CharIndex(',',Value)-1) As Int)`. NULL for all non-9999 parameters. |
| 8 | RiskClassificationID | INT | YES | - | CODE-BACKED | Raw risk classification ID from BackOffice.RiskClassificationParameter (`RCP.RiskClassificationID`). This is the score value used to look up the risk level name. |
| 9 | RiskClassification | VARCHAR(20) | YES | - | VERIFIED | Named risk level from Dictionary.RiskClassificationRegulation (`RCR.Name`). "Low", "Medium", "High", etc. Resolved via LEFT JOIN on RegulationID + RiskClassificationID=RiskScore. |
| 10 | RiskScore | INT | YES | - | CODE-BACKED | Same as RiskClassificationID (aliased). The numeric score value (0, 50, 100, 200). |
| 11 | ValidationText | VARCHAR(100) | YES | - | CODE-BACKED | Validation description from BackOffice.RiskClassificationParameter. "Default" for fallback rules, NULL for specific matching rules. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | BackOffice.RiskClassificationParameter | Base table | Source of scoring configuration rows |
| INNER JOIN | Dictionary.RiskClassificationParameter | Lookup | Resolves parameter ID to name |
| INNER JOIN | Dictionary.Regulation | Lookup | Resolves regulation ID to name |
| LEFT JOIN | Dictionary.RiskClassificationRegulation | Lookup | Resolves score to named risk level per regulation |

### 5.2 Referenced By (other objects point to this)

No dbo objects directly reference this view. Used by compliance/analytics consumers for scoring rule auditing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassificationParameter (view)
+-- BackOffice.RiskClassificationParameter (table)
+-- Dictionary.RiskClassificationParameter (table)
+-- Dictionary.Regulation (table)
+-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RiskClassificationParameter | Table | FROM - base configuration data |
| Dictionary.RiskClassificationParameter | Table | INNER JOIN - parameter name resolution |
| Dictionary.Regulation | Table | INNER JOIN - regulation name resolution |
| Dictionary.RiskClassificationRegulation | Table | LEFT JOIN - risk level name resolution |

### 6.2 Objects That Depend On This

No dependents found in dbo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Show all scoring rules for a specific parameter across regulations
```sql
SELECT RiskClassificationParameterID, RiskClassificationParameter,
       RegulationID, Regulation, RiskClassificationParameterOption,
       Value, RiskScore, RiskClassification, ValidationText
FROM dbo.V_RiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationParameterID = 2
ORDER BY RegulationID, RiskClassificationParameterOption
```

### 8.2 Find all High-risk scoring rules
```sql
SELECT RiskClassificationParameter, Regulation, Value, RiskScore, RiskClassification
FROM dbo.V_RiskClassificationParameter WITH (NOLOCK)
WHERE RiskScore >= 100
ORDER BY RiskClassificationParameterID, RegulationID
```

### 8.3 Count scoring rules per parameter
```sql
SELECT RiskClassificationParameterID, RiskClassificationParameter,
       COUNT(*) AS TotalRules, COUNT(DISTINCT RegulationID) AS Regulations
FROM dbo.V_RiskClassificationParameter WITH (NOLOCK)
GROUP BY RiskClassificationParameterID, RiskClassificationParameter
ORDER BY RiskClassificationParameterID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassificationParameter | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassificationParameter.sql*
