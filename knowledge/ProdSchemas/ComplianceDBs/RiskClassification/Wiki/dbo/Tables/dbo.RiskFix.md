# dbo.RiskFix

> Worklist table holding Global Customer IDs (GCIDs) that require a risk classification re-calculation or correction.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table acts as a worklist or queue of customer accounts (identified by GCID) that need their risk classification scores recalculated or corrected. The name "RiskFix" suggests it targets customers whose current risk classification is known or suspected to be incorrect, outdated, or requiring a forced recalculation.

Without this table, the compliance team would have no mechanism to flag specific customers for targeted risk score recalculation. Bulk re-scoring of all customers would be expensive, so this table enables targeted corrections for specific accounts.

Rows are likely inserted by compliance operations or automated processes that detect scoring anomalies. An external job or the main risk classification procedure (P_RiskClassification) may consume this list to process the flagged customers. After processing, rows may remain as an audit trail or be cleaned up.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table is a simple single-column worklist. The business logic is in the consuming process that reads GCIDs from this table and triggers risk re-classification.

---

## 3. Data Overview

| GCID | Meaning |
|------|---------|
| 458179 | A customer account flagged for risk classification fix. Low GCID suggests an early/long-standing customer. |
| 628171 | Another flagged account. |
| 663940 | Another flagged account. |
| 694525 | Another flagged account. |
| 851462 | A flagged account with higher GCID, suggesting a more recent customer. |

Total: 7,782 customer accounts currently flagged for risk fix.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID - the unique identifier for a customer account across the eToro platform. PK of this worklist. Each GCID in this table represents a customer whose risk classification score needs to be recalculated or corrected. Foreign key to the customer master in the etoro database (not declared as explicit FK due to cross-database boundary). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | dbo.T_RiskClassification | Implicit | The GCID identifies the customer whose risk record in T_RiskClassification needs correction |
| GCID | dbo.T_Scores | Implicit | The GCID identifies the customer whose individual parameter scores in T_Scores may need recalculation |

### 5.2 Referenced By (other objects point to this)

No other objects in the SSDT repo directly reference this table. Consumed by external processes or ad-hoc operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT repo. Likely consumed by external ETL or compliance operations processes.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RiskFix | CLUSTERED PK | GCID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 Check how many customers are pending risk fix
```sql
SELECT COUNT(*) AS PendingRiskFixes
FROM dbo.RiskFix WITH (NOLOCK)
```

### 8.2 Find if a specific customer is flagged for risk fix
```sql
SELECT rf.GCID, rc.RiskScore, rc.RiskScore_Value
FROM dbo.RiskFix rf WITH (NOLOCK)
LEFT JOIN dbo.T_RiskClassification rc WITH (NOLOCK) ON rf.GCID = rc.GCID
WHERE rf.GCID = @GCID
```

### 8.3 List flagged customers with their current risk scores
```sql
SELECT TOP 100 rf.GCID, rc.RiskScore, rc.RiskScore_Value, rc.RegulationID,
       r.Name AS Regulation
FROM dbo.RiskFix rf WITH (NOLOCK)
LEFT JOIN dbo.T_RiskClassification rc WITH (NOLOCK) ON rf.GCID = rc.GCID
LEFT JOIN Dictionary.Regulation r WITH (NOLOCK) ON rc.RegulationID = r.ID
ORDER BY rf.GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.RiskFix | Type: Table | Source: RiskClassification/dbo/Tables/dbo.RiskFix.sql*
