# BackOffice.RiskClassificationParameter

> Master scoring rules configuration table defining how input values map to risk scores for each parameter and regulation combination, with temporal versioning for audit of all rule changes.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table (Temporal - system-versioned) |
| **Key Identifier** | RegulationID + RiskClassificationParameterID + ID (composite CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This is the primary scoring rules configuration table for the risk classification system. Each row defines one scoring rule: "For regulation X and parameter Y, when the input matches value Z, assign risk score S." The table drives the entire scoring logic - the external risk engine reads these rules to determine how to score each customer parameter.

The table is temporal (system-versioned with `History.RiskClassificationParameter`), preserving every configuration change. This is essential for regulatory audits - when a scoring rule changes, the previous version is preserved with exact timestamps. The CySEC-specific equivalent is `RiskClassification.CySecRiskClassificationParameter`.

The `dbo.V_RiskClassificationParameter` view enriches this table with human-readable parameter names, regulation names, and risk level labels for compliance review.

---

## 2. Business Logic

### 2.1 Scoring Rules Engine

**What**: Maps input values to risk scores per parameter and regulation.

**Columns/Parameters Involved**: `RegulationID`, `RiskClassificationParameterID`, `ID`, `Value`, `RiskClassificationID`

**Rules**:
- Composite PK: RegulationID + ParameterID + ID ensures unique rules
- ID=0 typically represents the default/fallback rule
- Value contains matching criteria (country tier codes, questionnaire answer codes, screening status values)
- RiskClassificationID is the resulting score (0=Low, 50=Medium, 100=High)
- ValidationText provides human-readable descriptions ("Default", "No Match", "Sanction Match\Risk Match")
- The external risk engine evaluates these rules against customer data to produce individual parameter scores

### 2.2 Temporal Audit Trail

**What**: Every rule change is preserved with exact timestamps.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- BeginTime = when this rule version became effective
- EndTime = far-future for active rules
- History shows ~195 historical versions in History.RiskClassificationParameter

---

## 3. Data Overview

Queried via `dbo.V_RiskClassificationParameter` for enriched view. See [dbo.V_RiskClassificationParameter](../../dbo/Views/dbo.V_RiskClassificationParameter.md) for sample data with names resolved.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | INT | NO | - | VERIFIED | Regulation this rule applies to. Part of composite PK. See [Regulation](../_glossary.md#regulation). Different regulations have different rule sets. |
| 2 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being configured. Part of composite PK. FK to Dictionary.RiskClassificationParameter. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 3 | ID | INT | NO | - | VERIFIED | Option/row ID within the parameter+regulation combination. Part of composite PK. 0 = default/fallback rule, 1+ = specific matching rules ordered by priority. |
| 4 | Value | VARCHAR(500) | YES | - | VERIFIED | Input value matching criteria. NULL for default rules. Contains country tier codes ("0","1","2,3"), screening codes, questionnaire answer IDs, or comma-separated lists. |
| 5 | RiskClassificationID | INT | YES | - | VERIFIED | Resulting risk score when this rule matches. 0=Low, 50=Medium, 100=High, 200=Unacceptable/Block. Looked up in Dictionary.RiskClassificationRegulation for named level. |
| 6 | ValidationText | VARCHAR(100) | YES | - | CODE-BACKED | Human-readable rule description. "Default" for fallback, NULL for standard matching rules, descriptive text like "Sanction Match\Risk Match" for complex rules. |
| 7 | BeginTime | DATETIME2(7) | NO | GETUTCDATE() | VERIFIED | Temporal row start. GENERATED ALWAYS AS ROW START. |
| 8 | EndTime | DATETIME2(7) | NO | 9999-12-31... | VERIFIED | Temporal row end. GENERATED ALWAYS AS ROW END. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Explicit FK | FK_BackOffice_RiskClassificationParameter_RiskParameterID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassificationParameter | FROM RCP | Base table | View enriches rules with names |
| History.RiskClassificationParameter | (temporal) | History | Temporal history table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.RiskClassificationParameter (table)
+-- Dictionary.RiskClassificationParameter (table) [FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RiskClassificationParameter | Table | FK constraint |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassificationParameter | View | FROM - base data source |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BackOffice_RiskClassificationParameter | CLUSTERED PK | RegulationID ASC, RiskClassificationParameterID ASC, ID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BackOffice_RiskClassificationParameter | PRIMARY KEY | Composite: RegulationID + ParameterID + ID |
| FK_BackOffice_RiskClassificationParameter_RiskParameterID | FOREIGN KEY | -> Dictionary.RiskClassificationParameter(RiskClassificationParameterID) |
| SYSTEM_VERSIONING | Temporal | ON with HISTORY_TABLE=[History].[RiskClassificationParameter] |

---

## 8. Sample Queries

### 8.1 View scoring rules via enriched view
```sql
SELECT * FROM dbo.V_RiskClassificationParameter WITH (NOLOCK)
ORDER BY RiskClassificationParameterID, RegulationID, RiskClassificationParameterOption
```

### 8.2 Find rules for a specific parameter and regulation
```sql
SELECT RegulationID, RiskClassificationParameterID, ID, Value,
       RiskClassificationID, ValidationText
FROM BackOffice.RiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationParameterID = 7 AND RegulationID = 1
ORDER BY ID
```

### 8.3 Temporal query - rules at a point in time
```sql
SELECT *
FROM BackOffice.RiskClassificationParameter
FOR SYSTEM_TIME AS OF '2023-01-01'
WHERE RiskClassificationParameterID = 7
ORDER BY RegulationID, ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RiskClassificationParameter | Type: Table | Source: RiskClassification/BackOffice/Tables/BackOffice.RiskClassificationParameter.sql*
