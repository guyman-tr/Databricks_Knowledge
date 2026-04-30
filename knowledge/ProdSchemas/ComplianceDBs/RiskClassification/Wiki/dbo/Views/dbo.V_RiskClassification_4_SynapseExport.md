# dbo.V_RiskClassification_4_SynapseExport

> Synapse/data lake export view that wraps V_RiskClassification with sanitized column names (spaces removed), providing current-state risk classification data for Azure Synapse Analytics pipelines.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base view: dbo.V_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a thin wrapper view over `V_RiskClassification` that renames columns for data lake compatibility - removing spaces and special characters. It serves as the current-state data feed for Azure Synapse Analytics pipelines, complementing `V_RiskClassification_4_SynapseExport3` which provides historical data.

The view adds `Insert_Datetime` (always NULL) and renames `RiskScore`/`RiskScore_Value` to `Finalscore_RiskScore`/`Finalscore_Value`, and `PreviousRisk` to `PreviousRiskScore`. PEP Check and Place of Birth columns are excluded (commented out as having no values). Instruments Planned Investment is also excluded.

---

## 2. Business Logic

No additional business logic beyond V_RiskClassification. This is purely a column-aliasing wrapper.

---

## 3. Data Overview

Same data as V_RiskClassification with sanitized column names and Finalscore aliases.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. From V_RiskClassification. |
| 2 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 3 | RegulationID | INT | YES | - | CODE-BACKED | Regulation ID. |
| 4 | Regulation | VARCHAR(50) | YES | - | CODE-BACKED | Regulation name. |
| 5-84 | *_RiskScore / *_Value (sanitized) | INT/VARCHAR(50) | YES | - | CODE-BACKED | All parameter columns with sanitized names. Same as V_RiskClassification. |
| 85 | Finalscore_RiskScore | INT | YES | - | CODE-BACKED | Final aggregate risk score (aliased from RiskScore). |
| 86 | Finalscore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Final score formula (aliased from RiskScore_Value). |
| 87 | Insert_Datetime | - | YES | - | CODE-BACKED | Always NULL. Placeholder column for Synapse pipeline compatibility. |
| 88 | Update_Datetime | DATETIME2(7) | NO | - | CODE-BACKED | BeginTime from V_RiskClassification, aliased as Update_Datetime. |
| 89 | PreviousRiskScore | INT | YES | - | CODE-BACKED | Previous risk score (aliased from PreviousRisk). |
| 90 | PreviousRiskUpdateDate | DATETIME2 | YES | - | CODE-BACKED | When previous risk was set. |
| 91 | RiskScore_Explanation | VARCHAR(MAX) | YES | - | CODE-BACKED | Comma-separated contributing parameter names. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | dbo.V_RiskClassification | Base view | Wraps all columns with sanitized aliases |

### 5.2 Referenced By (other objects point to this)

No dependents found. Consumed by Synapse pipelines.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassification_4_SynapseExport (view)
+-- dbo.V_RiskClassification (view)
    +-- dbo.T_RiskClassification (table)
    +-- History.T_RiskClassification (table)
    +-- dbo.V_Scores (view)
    +-- Dictionary.Regulation (table)
    +-- Dictionary.RiskClassificationRegulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_RiskClassification | View | FROM - sole data source |

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

### 8.1 Basic Synapse-compatible export query
```sql
SELECT GCID, CID, RegulationID, Regulation, Finalscore_RiskScore, Finalscore_Value,
       Update_Datetime, PreviousRiskScore, RiskScore_Explanation
FROM dbo.V_RiskClassification_4_SynapseExport WITH (NOLOCK)
WHERE GCID = 91
```

### 8.2 Current + historical combined for full timeline
```sql
SELECT GCID, Finalscore_RiskScore, Update_Datetime, 'Current' AS Source
FROM dbo.V_RiskClassification_4_SynapseExport WITH (NOLOCK)
WHERE GCID = 91
UNION ALL
SELECT GCID, Finalscore_RiskScore, BeginTime, 'History'
FROM dbo.V_RiskClassification_4_SynapseExport3 WITH (NOLOCK)
WHERE GCID = 91
ORDER BY Update_Datetime DESC
```

### 8.3 Risk distribution for Synapse analytics
```sql
SELECT Regulation, Finalscore_RiskScore, COUNT(*) AS Cnt
FROM dbo.V_RiskClassification_4_SynapseExport WITH (NOLOCK)
GROUP BY Regulation, Finalscore_RiskScore
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 90 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassification_4_SynapseExport | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassification_4_SynapseExport.sql*
