# Dictionary.CySecRiskClassificationParameter

> CySEC-specific version of the risk classification parameter dictionary, mirroring Dictionary.RiskClassificationParameter with identical parameter definitions and weight percentages for CySEC regulatory context.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ParameterID (INT, CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table is a CySEC-regulation-specific copy of the risk classification parameter dictionary. It contains the same 46 parameters as `Dictionary.RiskClassificationParameter` (IDs 2-21, 1001-1025, 9999) with identical names, descriptions, sources, and weight percentages. It exists as a separate entity to allow CySEC-specific parameter configurations to evolve independently from the main dictionary.

The table was created conditionally (`IF NOT EXISTS`), suggesting it was added as a later enhancement to support regulation-specific parameter management. It serves as the FK target for `RiskClassification.CySecRiskClassificationParameter` (the CySEC scoring rules configuration table).

---

## 2. Business Logic

### 2.1 Regulation-Specific Parameter Independence

**What**: Allows CySEC parameters to be configured independently from the main dictionary.

**Columns/Parameters Involved**: All columns mirror Dictionary.RiskClassificationParameter

**Rules**:
- Same parameter IDs and names as the main dictionary
- WeeklyWeightPercent and OnboardingWeightPercent can differ from the main dictionary
- Currently contains identical data, but the separate table enables future divergence
- Referenced via FK by RiskClassification.CySecRiskClassificationParameter

---

## 3. Data Overview

| ParameterID | Name | Description | Source | WeeklyWeight | OnboardingWeight | Meaning |
|------------|------|------------|--------|-------------|-----------------|---------|
| 2 | Country of Residence, Onboarding | Country by Reg. Form - Onboarding | Customer.CustomerStatic | 2.5% | 4% | Same as main dictionary. Country risk at onboarding. |
| 7 | Screening Status | Screening Service | NULL | 5.2% | 6.5% | Highest-weighted parameter. Sanctions/watchlist check. |
| 1001 | SectorHighRisk | NULL | NULL | 0% | 0% | CySEC EDD parameter. Zero weight - independent scoring. |
| 9999 | Final score | Final Score | NULL | 0% | 0% | Aggregate result marker. |

See [CySEC Risk Classification Parameter](../_glossary.md#cysec-risk-classification-parameter) for details. Contains same 46 parameters as the main dictionary.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParameterID | INT | NO | - | VERIFIED | Parameter identifier. PK. Same ID space as Dictionary.RiskClassificationParameter (2-21, 1001-1025, 9999). FK target for RiskClassification.CySecRiskClassificationParameter. |
| 2 | Name | VARCHAR(50) | YES | - | VERIFIED | Parameter name. Identical to Dictionary.RiskClassificationParameter.Name for the same ID. |
| 3 | Description | VARCHAR(MAX) | YES | - | VERIFIED | Parameter description. Same content as the main dictionary. |
| 4 | Source | VARCHAR(200) | YES | - | VERIFIED | External data source. Same as main dictionary. |

Note: The live database has additional `WeeklyWeightPercent` and `OnboardingWeightPercent` columns not in the SSDT DDL.

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RiskClassification.CySecRiskClassificationParameter | ParameterID | Explicit FK | FK_CySecRiskClassificationParameter_ParameterID - validates parameter IDs in CySEC scoring rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RiskClassification.CySecRiskClassificationParameter | Table | FK constraint on ParameterID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CySecRiskClassificationParameter | CLUSTERED PK | ParameterID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CySecRiskClassificationParameter | PRIMARY KEY | ParameterID |

Note: Table created conditionally with `IF NOT EXISTS`, suggesting post-deployment addition.

---

## 8. Sample Queries

### 8.1 List all CySEC parameters
```sql
SELECT ParameterID, Name, Description, Source
FROM Dictionary.CySecRiskClassificationParameter WITH (NOLOCK)
ORDER BY ParameterID
```

### 8.2 Compare CySEC vs main dictionary parameters
```sql
SELECT c.ParameterID,
       c.Name AS CySecName, m.Name AS MainName,
       CASE WHEN c.Name = m.Name THEN 'Match' ELSE 'DIFFER' END AS NameMatch
FROM Dictionary.CySecRiskClassificationParameter c WITH (NOLOCK)
FULL OUTER JOIN Dictionary.RiskClassificationParameter m WITH (NOLOCK)
    ON c.ParameterID = m.RiskClassificationParameterID
ORDER BY COALESCE(c.ParameterID, m.RiskClassificationParameterID)
```

### 8.3 Find CySEC EDD parameters
```sql
SELECT ParameterID, Name
FROM Dictionary.CySecRiskClassificationParameter WITH (NOLOCK)
WHERE ParameterID BETWEEN 1001 AND 1025
ORDER BY ParameterID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CySecRiskClassificationParameter | Type: Table | Source: RiskClassification/Dictionary/Tables/Dictionary.CySecRiskClassificationParameter.sql*
