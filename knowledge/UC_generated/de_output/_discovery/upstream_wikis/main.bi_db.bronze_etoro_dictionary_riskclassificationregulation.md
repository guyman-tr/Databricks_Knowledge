# Dictionary.RiskClassificationRegulation

> Configuration table mapping regulation entities to risk score thresholds with classification labels — currently empty in production, with structure for per-regulation risk bucketing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite PK (RegulationID, RiskScore) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RiskClassificationRegulation is designed to define risk score thresholds and their labels per regulatory authority. Each regulation (e.g., CySEC, FCA, ASIC) may classify the same numeric risk score differently — what CySEC considers "Medium" risk, ASIC might classify as "High." This table enables regulation-specific risk classification labels.

Currently **empty in production** — the risk classification system may use hardcoded thresholds or a different configuration mechanism. The table structure is preserved for future use or migration.

Referenced by dbo.V_RiskClassificationParameter view which joins this table for regulation-specific risk labels.

---

## 2. Business Logic

### 2.1 Per-Regulation Risk Bucketing

**What**: Each row maps a (RegulationID, RiskScore) combination to a named classification.

**Columns/Parameters Involved**: `RegulationID`, `RiskScore`, `Name`

**Rules**:
- Composite PK ensures each regulation can have unique threshold labels.
- RiskScore values come from the risk classification engine (Dictionary.RiskClassificationParameter scoring).
- Name provides the human-readable label (e.g., "Low", "Medium", "High", "Very High").
- Currently empty — classification logic may be handled elsewhere.

---

## 3. Data Overview

Table is empty in production. No rows returned from live data query.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RegulationID | int | NO | - | VERIFIED | Part of composite PK. References Dictionary.Regulation (implicit). Identifies the regulatory authority. |
| 2 | RiskScore | int | NO | - | VERIFIED | Part of composite PK. The numeric risk score threshold. Combined with RegulationID to form unique classification boundaries. |
| 3 | Name | varchar(20) | YES | - | VERIFIED | Risk classification label for this regulation+score combination (e.g., "Low", "Medium", "High"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.Regulation | RegulationID | Implicit | Regulatory authority |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_RiskClassificationParameter | RegulationID, RiskScore | View | Joins for regulation-specific risk labels |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.Regulation implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Regulation | Table | Implicit — regulatory authority |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassificationParameter | View | Joins for regulation-specific labels |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RiskClassificationRegulation | CLUSTERED PK | RegulationID ASC, RiskScore ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RiskClassificationRegulation | PRIMARY KEY | Unique regulation+score combination |

---

## 8. Sample Queries

### 8.1 List all regulation risk classifications
```sql
SELECT  RegulationID,
        RiskScore,
        Name
FROM    [Dictionary].[RiskClassificationRegulation] WITH (NOLOCK)
ORDER BY RegulationID, RiskScore;
```

### 8.2 Find risk label for a specific regulation and score
```sql
SELECT  Name
FROM    [Dictionary].[RiskClassificationRegulation] WITH (NOLOCK)
WHERE   RegulationID = 1
        AND RiskScore = 3;
```

### 8.3 Count classifications per regulation
```sql
SELECT  r.Name AS Regulation,
        COUNT(*) AS ThresholdCount
FROM    [Dictionary].[RiskClassificationRegulation] rcr WITH (NOLOCK)
JOIN    [Dictionary].[Regulation] r WITH (NOLOCK) ON rcr.RegulationID = r.RegulationID
GROUP BY r.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RiskClassificationRegulation | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RiskClassificationRegulation.sql*
