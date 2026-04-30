# Dictionary.RiskClassificationRegulation

> Lookup table mapping numeric risk score thresholds to named risk classification levels (Low, Medium, High, etc.) per regulatory jurisdiction, providing the final score-to-label translation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RegulationID + RiskScore (composite CLUSTERED PK) |
| **Partition** | No (FILLFACTOR 90, PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table is the score-to-label translator for the risk classification system. Given a regulation ID and a numeric risk score, it returns the human-readable risk level name (e.g., "Low", "Medium", "High", "Block"). Different regulations have different tier structures - CySEC and FCA use 6 tiers while US regulations use 4 tiers.

The table is consumed by every view that displays risk level names: `dbo.V_Scores`, `dbo.V_RiskClassification`, `dbo.V_RiskClassificationParameter`, `dbo.V_RiskClassification_4_SynapseExport2`, and the CySEC-specific view. It is one of the most heavily JOINed tables in the database.

---

## 2. Business Logic

### 2.1 Regulation-Specific Tier Structures

**What**: Different regulations define different risk level breakpoints and names.

**Columns/Parameters Involved**: `RegulationID`, `RiskScore`, `Name`

**Rules**:
- **CySEC (1) and FCA (2)**: 6 tiers - 0=Low, 25=Medium Low, 50=Medium, 75=Medium High, 100=High, 200=Unacceptable
- **ASIC (4), FinCEN+FINRA (8), ASIC&GAML (10), FINRAONLY (12), NYDFSFINRA (14)**: 4 tiers - 0=Low, 50=Medium, 100=High, 200=Block
- **FinCEN (7)**: 4 tiers - 0=Low, 50=Medium, 100=High, 200=Block
- **FSA Seychelles (9), FSRA (11)**: 3 tiers - 0=Low, 50=Medium, 100=High (no Block level)
- Score 200 means "Block" (account blocked) in most jurisdictions, "Unacceptable" in CySEC/FCA

---

## 3. Data Overview

| RegulationID | RiskScore | Name | Meaning |
|-------------|-----------|------|---------|
| 1 (CySEC) | 0 | Low | Minimal compliance risk. Standard monitoring. |
| 1 (CySEC) | 75 | Medium High | Elevated risk. Enhanced due diligence required. Only CySEC/FCA have this tier. |
| 1 (CySEC) | 200 | Unacceptable | Risk exceeds thresholds. Relationship termination may be required. |
| 7 (FinCEN) | 200 | Block | Account blocked from operations. US equivalent of "Unacceptable". |
| 9 (FSA Seychelles) | 100 | High | Maximum tier for FSA Seychelles. No "Block" level exists. |

See [Risk Classification Regulation](../_glossary.md#risk-classification-regulation) for complete value map.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | INT | NO | - | VERIFIED | Regulation this tier structure belongs to. Part of composite PK. FK to Dictionary.Regulation (implicit). See [Regulation](../_glossary.md#regulation). |
| 2 | RiskScore | INT | NO | - | VERIFIED | Numeric score threshold. Part of composite PK. Standard values: 0, 25, 50, 75, 100, 200 (not all used by every regulation). This value is matched against T_RiskClassification.RiskScore and T_Scores.RiskScore to resolve the name. |
| 3 | Name | VARCHAR(20) | YES | - | VERIFIED | Human-readable risk level name. Values: "Low", "Medium Low", "Medium", "Medium High", "High", "Unacceptable", "Block". Displayed in V_Scores (as RiskScoreName), V_RiskClassification (as RiskScoreName), and all export views. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RegulationID | Dictionary.Regulation | Implicit FK | Which regulation this tier structure belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_Scores | INNER JOIN ON RegulationID + RiskScore | Lookup | Risk level name for individual parameter scores |
| dbo.V_RiskClassification | INNER JOIN ON RegulationID + RiskScore | Lookup | Risk level name for aggregate score |
| dbo.V_RiskClassificationParameter | LEFT JOIN ON RegulationID + RiskScore | Lookup | Risk level name for config rules |
| dbo.V_RiskClassification_4_SynapseExport2 | INNER JOIN ON RegulationID + RiskScore | Lookup | Risk level name for Synapse export |
| RiskClassification.CySecRiskClassificationParameterView | LEFT JOIN ON RegulationID + RiskScore | Lookup | Risk level name for CySEC config |
| History.V_Scores | INNER JOIN ON RegulationID + RiskScore | Lookup | Risk level name for historical scores |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_Scores | View | INNER JOIN |
| dbo.V_RiskClassification | View | INNER JOIN |
| dbo.V_RiskClassificationParameter | View | LEFT JOIN |
| dbo.V_RiskClassificationDataLake | View | INNER JOIN |
| dbo.V_RiskClassification_4_SynapseExport2 | View | INNER JOIN |
| RiskClassification.CySecRiskClassificationParameterView | View | LEFT JOIN |
| History.V_Scores | View | INNER JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RiskClassificationRegulation | CLUSTERED PK | RegulationID ASC, RiskScore ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RiskClassificationRegulation | PRIMARY KEY | Composite: RegulationID + RiskScore |

---

## 8. Sample Queries

### 8.1 Show all risk levels for a regulation
```sql
SELECT RegulationID, RiskScore, Name
FROM Dictionary.RiskClassificationRegulation WITH (NOLOCK)
WHERE RegulationID = 1
ORDER BY RiskScore
```

### 8.2 Compare tier structures across regulations
```sql
SELECT r.Name AS Regulation, rcr.RiskScore, rcr.Name AS RiskLevel
FROM Dictionary.RiskClassificationRegulation rcr WITH (NOLOCK)
INNER JOIN Dictionary.Regulation r WITH (NOLOCK) ON rcr.RegulationID = r.ID
ORDER BY r.Name, rcr.RiskScore
```

### 8.3 Find regulations with a "Block" level
```sql
SELECT DISTINCT r.ID, r.Name
FROM Dictionary.RiskClassificationRegulation rcr WITH (NOLOCK)
INNER JOIN Dictionary.Regulation r WITH (NOLOCK) ON rcr.RegulationID = r.ID
WHERE rcr.Name = 'Block'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskClassificationRegulation | Type: Table | Source: RiskClassification/Dictionary/Tables/Dictionary.RiskClassificationRegulation.sql*
