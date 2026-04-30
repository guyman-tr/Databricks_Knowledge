# dbo.V_RiskClassification_4_SynapseExport3

> Synapse/data lake export view that reads directly from the temporal history table History.T_RiskClassification, providing historical risk classification records with sanitized column names suitable for external analytics platforms.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: History.T_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a data lake/Synapse-compatible export of historical risk classification records. Unlike V_RiskClassification_4_SynapseExport (which reads current data via V_RiskClassification), this view reads directly from `History.T_RiskClassification` - the temporal history table - providing all previous versions of customer risk scores that have been superseded by updates.

The view exists to feed historical risk data into Azure Synapse Analytics or similar data lake platforms for trend analysis, regulatory lookback, and compliance reporting. It normalizes column names by removing spaces and special characters (e.g., "Country of Residence, Onboarding_RiskScore" becomes "CountryofResidence_Onboarding_RiskScore").

Several columns are stubbed as NULL placeholders (`Regulation`, `RiskScore_Explanation`, `RiskScoreName`) because these are not available in the history table without the Dictionary JOINs that the current-data views perform. The final score is aliased as `Finalscore_RiskScore`/`Finalscore_Value`.

---

## 2. Business Logic

### 2.1 History-Only Data Source

**What**: Reads from temporal history only - excludes current (active) records.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all score columns

**Rules**:
- Source is `History.T_RiskClassification`, which contains superseded rows (EndTime < '9999-12-31')
- Combined with V_RiskClassification_4_SynapseExport (current data), this provides a complete timeline
- Regulation, RiskScore_Explanation, and RiskScoreName are cast as NULL since history table lacks Dictionary JOINs

---

## 3. Data Overview

N/A - history export view. Contains all superseded risk classification records with sanitized column aliases.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this historical risk classification version became effective. |
| 2 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this version was superseded by a newer classification. |
| 3 | GCID | INT | NO | - | VERIFIED | Global Customer ID. From History.T_RiskClassification. |
| 4 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 5 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction ID. See [Regulation](_glossary.md#regulation). |
| 6 | Regulation | VARCHAR(50) | YES | - | CODE-BACKED | Stubbed as `CAST(NULL AS VARCHAR(50))`. Not resolved from Dictionary in this history view. |
| 7-96 | *_RiskScore / *_Value columns | INT/VARCHAR(50) | YES | - | CODE-BACKED | All individual parameter score and value columns from History.T_RiskClassification, aliased with sanitized names (spaces removed). Same columns as T_RiskClassification. See dbo.T_RiskClassification documentation for full element descriptions. |
| 97 | Finalscore_RiskScore | INT | YES | - | CODE-BACKED | Final aggregate risk score (aliased from `RiskScore`). |
| 98 | Finalscore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Final score formula value (aliased from `RiskScore_Value`). |
| 99 | RiskScore_Explanation | VARCHAR(MAX) | YES | - | CODE-BACKED | Stubbed as `CAST(NULL AS VARCHAR(MAX))`. Not available in history view. |
| 100 | RiskScoreName | VARCHAR(50) | YES | - | CODE-BACKED | Stubbed as `CAST(NULL AS VARCHAR(50))`. Not resolved from Dictionary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.T_RiskClassification | Base table | Temporal history of dbo.T_RiskClassification |

### 5.2 Referenced By (other objects point to this)

No dependents found. Consumed by external Synapse/data lake pipelines.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassification_4_SynapseExport3 (view)
+-- History.T_RiskClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.T_RiskClassification | Table | FROM - direct read of temporal history |

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

### 8.1 Get all historical risk versions for a customer
```sql
SELECT GCID, BeginTime, EndTime, Finalscore_RiskScore, RegulationID
FROM dbo.V_RiskClassification_4_SynapseExport3 WITH (NOLOCK)
WHERE GCID = 91
ORDER BY BeginTime DESC
```

### 8.2 Find customers whose risk score changed in a date range
```sql
SELECT GCID, BeginTime, EndTime, Finalscore_RiskScore
FROM dbo.V_RiskClassification_4_SynapseExport3 WITH (NOLOCK)
WHERE BeginTime >= '2024-01-01' AND BeginTime < '2024-02-01'
```

### 8.3 Count historical records per customer
```sql
SELECT TOP 20 GCID, COUNT(*) AS HistoricalVersions
FROM dbo.V_RiskClassification_4_SynapseExport3 WITH (NOLOCK)
GROUP BY GCID
ORDER BY HistoricalVersions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 97 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassification_4_SynapseExport3 | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassification_4_SynapseExport3.sql*
