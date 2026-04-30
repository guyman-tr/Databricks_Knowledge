# History.RiskClassificationParameter

> Temporal history table preserving all superseded versions of risk scoring configuration rules from BackOffice.RiskClassificationParameter, enabling audit of how scoring rules have changed over time.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | RegulationID + RiskClassificationParameterID + ID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `BackOffice.RiskClassificationParameter` - the scoring rules configuration table. Each row represents a previous version of a scoring rule that has since been modified. This preserves the complete audit trail of how risk scoring rules have evolved, which is critical for regulatory compliance and answering questions like "What scoring rules were in effect on date X?"

With only ~195 rows, this is a small table reflecting the relatively low frequency of scoring rule changes. Each change (e.g., modifying a validation text or risk score for a parameter option) generates a historical version here.

---

## 2. Business Logic

### 2.1 Scoring Rule Change Tracking

**What**: Captures every modification to the risk scoring configuration rules.

**Columns/Parameters Involved**: All columns mirror BackOffice.RiskClassificationParameter

**Rules**:
- A row appears here when a scoring rule in BackOffice.RiskClassificationParameter is updated
- The row shows the PREVIOUS state of the rule (before the update)
- Comparing consecutive versions reveals what changed (e.g., Screening Status validation text changed from "No Match" to "Sanction Match\Risk Match")
- Combined with the current BackOffice.RiskClassificationParameter row, provides complete timeline of each rule

---

## 3. Data Overview

| RegulationID | ParameterID | Option ID | Value | RiskClassificationID | ValidationText | BeginTime | EndTime | Meaning |
|-------------|------------|-----------|-------|---------------------|----------------|-----------|---------|---------|
| 4 (ASIC) | 7 (Screening Status) | 1 | 1 | 100 | No Match | 2023-05-09 | 2023-05-24 | ASIC Screening Status rule: value "1" mapped to score 100 with validation "No Match". This version lasted ~2 weeks before being updated. |
| 1 (CySEC) | 7 (Screening Status) | 2 | 7,4 | 100 | Sanction Match\Risk Match | 2023-04-10 | 2023-05-09 | CySEC Screening Status rule: values "7" or "4" mapped to score 100 with combined validation text. Superseded by a configuration update. |

Total: ~195 historical configuration versions.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | INT | NO | - | VERIFIED | Regulation this scoring rule applied to. Part of composite clustered index. See [Regulation](../_glossary.md#regulation). |
| 2 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter this rule scored. Part of composite index. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). |
| 3 | ID | INT | NO | - | VERIFIED | Option/row ID within the parameter+regulation combination. 0 = default rule, 1+ = specific matching rules. Part of composite index. |
| 4 | Value | VARCHAR(500) | YES | - | CODE-BACKED | Input value matching criteria that was in effect during this period. Contains country tier codes, age brackets, or other matching patterns. |
| 5 | RiskClassificationID | INT | YES | - | CODE-BACKED | Risk score (0/50/100/200) that this rule produced during this period. |
| 6 | ValidationText | VARCHAR(100) | YES | - | CODE-BACKED | Validation description for this rule version. E.g., "Default", "No Match", "Sanction Match\Risk Match". |
| 7 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | Start of this historical version's validity. |
| 8 | EndTime | DATETIME2(7) | NO | - | VERIFIED | End of this historical version's validity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | BackOffice.RiskClassificationParameter | Temporal history | System-versioned history for the scoring rules configuration |
| RegulationID | Dictionary.Regulation | Implicit FK | Regulation lookup |
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit FK | Parameter lookup |

### 5.2 Referenced By (other objects point to this)

No other objects reference this history table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_RiskClassificationParameter | CLUSTERED | RegulationID ASC, RiskClassificationParameterID ASC, ID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 View scoring rule change history for a parameter
```sql
SELECT RegulationID, RiskClassificationParameterID, ID, Value,
       RiskClassificationID, ValidationText, BeginTime, EndTime
FROM History.RiskClassificationParameter WITH (NOLOCK)
WHERE RiskClassificationParameterID = 7
ORDER BY RegulationID, ID, BeginTime DESC
```

### 8.2 Find what rules were active on a specific date
```sql
SELECT *
FROM History.RiskClassificationParameter WITH (NOLOCK)
WHERE BeginTime <= '2023-04-15' AND EndTime > '2023-04-15'
```

### 8.3 Count configuration changes per parameter
```sql
SELECT RiskClassificationParameterID, COUNT(*) AS Changes
FROM History.RiskClassificationParameter WITH (NOLOCK)
GROUP BY RiskClassificationParameterID
ORDER BY Changes DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RiskClassificationParameter | Type: Table | Source: RiskClassification/History/Tables/History.RiskClassificationParameter.sql*
