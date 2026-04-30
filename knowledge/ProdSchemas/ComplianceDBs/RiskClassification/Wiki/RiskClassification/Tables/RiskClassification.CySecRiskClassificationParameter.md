# RiskClassification.CySecRiskClassificationParameter

> CySEC-specific risk scoring rules configuration table that maps input values to risk scores for each parameter under CySEC regulation, with temporal versioning for audit of rule changes.

| Property | Value |
|----------|-------|
| **Schema** | RiskClassification |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | RegulationID + ParameterID + ID (composite CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table stores the CySEC-specific risk scoring configuration rules - the mapping of input values to risk scores for each risk parameter. It is structurally identical to `BackOffice.RiskClassificationParameter` but serves as a separate, CySEC-focused configuration store. Each row defines one scoring rule: "For parameter X under regulation Y, when the input matches value Z, assign risk score S."

The table is temporal (system-versioned with History.cySecRiskClassificationParameter), preserving the complete audit trail of every scoring rule change. This is critical for CySEC regulatory compliance - auditors need to know what rules were in effect at any historical point.

With only 65 rows, this is a small configuration table. Some parameters have been explicitly deleted via DML in the DDL file (parameters 5 with specific values, and parameters 6, 14, 15, 16, 19 entirely), suggesting a cleanup of deprecated or invalid rules.

---

## 2. Business Logic

### 2.1 Scoring Rule Configuration

**What**: Maps input values to risk scores per parameter and regulation.

**Columns/Parameters Involved**: `RegulationID`, `ParameterID`, `ID`, `Value`, `RiskClassificationID`

**Rules**:
- Composite PK: RegulationID + ParameterID + ID ensures unique rules per parameter per regulation
- ID=0 with ValidationText="Default" is the fallback rule (score when no specific match)
- Value contains matching criteria (country tier codes like "1", "2,3", "0")
- RiskClassificationID is the resulting score (0=Low, 50=Medium, 100=High)
- Explicit FK to Dictionary.CySecRiskClassificationParameter for parameter validation
- Note inverted scoring vs BackOffice version: for Parameter 2 (Country), tier "1" scores 100 (High) here but may differ in BackOffice

---

## 3. Data Overview

| RegulationID | ParameterID | Option ID | Value | Score | ValidationText | Meaning |
|-------------|------------|-----------|-------|-------|----------------|---------|
| 1 (CySEC) | 2 (Country, Onboarding) | 0 | NULL | 0 | Default | Default rule: if no country tier matches, score 0 (Low). |
| 1 (CySEC) | 2 (Country, Onboarding) | 1 | 1 | 100 | NULL | Country tier 1 = score 100 (High). Tier 1 countries are highest risk. |
| 1 (CySEC) | 2 (Country, Onboarding) | 2 | 2,3 | 50 | NULL | Country tiers 2 or 3 = score 50 (Medium). |
| 1 (CySEC) | 2 (Country, Onboarding) | 3 | 0 | 0 | NULL | Country tier 0 = score 0 (Low). Low-risk countries. |

Total: 65 active scoring rules.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | INT | NO | - | VERIFIED | Regulation this rule applies to. Part of composite PK. Currently CySEC-focused. See [Regulation](../_glossary.md#regulation). |
| 2 | ParameterID | INT | NO | - | VERIFIED | Risk parameter being configured. Part of composite PK. FK to Dictionary.CySecRiskClassificationParameter. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 3 | ID | INT | NO | - | VERIFIED | Option/row ID within the parameter+regulation combination. Part of composite PK. 0 = default/fallback rule, 1+ = specific matching rules. |
| 4 | Value | VARCHAR(500) | YES | - | VERIFIED | Input value matching criteria. NULL for default rules. Contains country tier codes ("0","1","2,3"), screening status codes, or other matching patterns. Comma-separated values match any of the listed values. |
| 5 | RiskClassificationID | INT | YES | - | VERIFIED | Resulting risk score when this rule matches. 0=Low, 50=Medium, 100=High. Looked up in Dictionary.RiskClassificationRegulation for named level. |
| 6 | ValidationText | VARCHAR(100) | YES | - | CODE-BACKED | Human-readable description of the rule. "Default" for fallback rules, NULL for specific matching rules. May also contain descriptions like "Sanction Match\Risk Match". |
| 7 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. GENERATED ALWAYS AS ROW START. |
| 8 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParameterID | Dictionary.CySecRiskClassificationParameter | Explicit FK | FK_CySecRiskClassificationParameter_ParameterID - validates parameter ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RiskClassification.CySecRiskClassificationParameterView | FROM RCP | Base table | View that enriches these rules with parameter/regulation names |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RiskClassification.CySecRiskClassificationParameter (table)
+-- Dictionary.CySecRiskClassificationParameter (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CySecRiskClassificationParameter | Table | FK constraint on ParameterID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.CySecRiskClassificationParameterView | View | FROM - base data source |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CySecRiskClassificationParameter | CLUSTERED PK | RegulationID ASC, ParameterID ASC, ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CySecRiskClassificationParameter | PRIMARY KEY | Composite: RegulationID + ParameterID + ID |
| FK_CySecRiskClassificationParameter_ParameterID | FOREIGN KEY | ParameterID REFERENCES Dictionary.CySecRiskClassificationParameter(ParameterID) |
| Df_CySecRiskClassificationParameter_BeginTime | DEFAULT | GETUTCDATE() |
| Df_CySecRiskClassificationParameter_EndTime | DEFAULT | '99991231 23:59:59.9999999' |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[cySecRiskClassificationParameter] |

---

## 8. Sample Queries

### 8.1 View all CySEC scoring rules for a parameter
```sql
SELECT ParameterID, ID, Value, RiskClassificationID AS Score, ValidationText
FROM RiskClassification.CySecRiskClassificationParameter WITH (NOLOCK)
WHERE ParameterID = 2
ORDER BY RegulationID, ID
```

### 8.2 Find all high-risk scoring rules
```sql
SELECT ParameterID, RegulationID, Value, RiskClassificationID, ValidationText
FROM RiskClassification.CySecRiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationID >= 100
ORDER BY ParameterID
```

### 8.3 Compare current vs historical rules (temporal query)
```sql
SELECT ParameterID, ID, Value, RiskClassificationID, BeginTime
FROM RiskClassification.CySecRiskClassificationParameter
FOR SYSTEM_TIME ALL
WHERE ParameterID = 7
ORDER BY ParameterID, ID, BeginTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RiskClassification.CySecRiskClassificationParameter | Type: Table | Source: RiskClassification/RiskClassification/Tables/RiskClassification.CySecRiskClassificationParameter.sql*
