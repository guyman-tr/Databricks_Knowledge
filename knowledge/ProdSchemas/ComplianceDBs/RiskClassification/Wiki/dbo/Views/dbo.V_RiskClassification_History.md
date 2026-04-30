# dbo.V_RiskClassification_History

> Historical risk classification view reading from the temporal history table, providing superseded customer risk records with sanitized column names. Structurally identical to V_RiskClassification_4_SynapseExport3.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base table: History.T_RiskClassification |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides access to historical (superseded) customer risk classification records from `History.T_RiskClassification`. It is structurally identical to `V_RiskClassification_4_SynapseExport3` - both read from the same history table and produce the same sanitized column aliases. The difference is likely naming convention: this view is named for general historical querying, while the "SynapseExport3" variant is specifically named for the data lake export pipeline.

The view enables compliance lookback queries, regulatory audits, and trend analysis by exposing all previous versions of customer risk classifications. Each row represents a past risk state with BeginTime/EndTime marking its validity period.

Regulation, RiskScore_Explanation, and RiskScoreName are stubbed as NULL since the view reads raw history without Dictionary JOINs.

---

## 2. Business Logic

### 2.1 History-Only Data Source

**What**: Same pattern as V_RiskClassification_4_SynapseExport3 - reads superseded temporal rows only.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, all score columns

**Rules**:
- Source is `History.T_RiskClassification`
- Contains all versions of risk classifications that have been superseded by updates
- NULL stubs for Regulation, RiskScore_Explanation, RiskScoreName

---

## 3. Data Overview

N/A - history view. Contains all superseded risk classification records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | When this historical classification became effective. |
| 2 | EndTime | DATETIME2(7) | NO | - | VERIFIED | When this version was superseded. |
| 3 | GCID | INT | NO | - | VERIFIED | Global Customer ID. |
| 4 | CID | INT | YES | - | CODE-BACKED | Customer ID. |
| 5 | RegulationID | INT | YES | - | CODE-BACKED | Regulatory jurisdiction ID. See [Regulation](_glossary.md#regulation). |
| 6 | Regulation | - | YES | - | CODE-BACKED | Stubbed as NULL. Not resolved from Dictionary. |
| 7-96 | *_RiskScore / *_Value columns | INT/VARCHAR(50) | YES | - | CODE-BACKED | All parameter score/value columns from History.T_RiskClassification with sanitized names. See dbo.T_RiskClassification for full descriptions. |
| 97 | Finalscore_RiskScore | INT | YES | - | CODE-BACKED | Final aggregate score (aliased from RiskScore). |
| 98 | Finalscore_Value | VARCHAR(50) | YES | - | CODE-BACKED | Final score formula (aliased from RiskScore_Value). |
| 99 | RiskScore_Explanation | - | YES | - | CODE-BACKED | Stubbed as NULL. |
| 100 | RiskScoreName | - | YES | - | CODE-BACKED | Stubbed as NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.T_RiskClassification | Base table | Temporal history |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_RiskClassification_History (view)
+-- History.T_RiskClassification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.T_RiskClassification | Table | FROM - direct read |

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

### 8.1 View risk classification history for a customer
```sql
SELECT GCID, BeginTime, EndTime, Finalscore_RiskScore, RegulationID
FROM dbo.V_RiskClassification_History WITH (NOLOCK)
WHERE GCID = 91
ORDER BY BeginTime DESC
```

### 8.2 Find score changes in a specific period
```sql
SELECT GCID, BeginTime, Finalscore_RiskScore
FROM dbo.V_RiskClassification_History WITH (NOLOCK)
WHERE EndTime >= '2024-01-01' AND BeginTime < '2024-01-01'
```

### 8.3 Count total historical versions
```sql
SELECT COUNT(*) AS TotalHistoricalRecords, COUNT(DISTINCT GCID) AS UniqueCustomers
FROM dbo.V_RiskClassification_History WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 97 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.V_RiskClassification_History | Type: View | Source: RiskClassification/dbo/Views/dbo.V_RiskClassification_History.sql*
