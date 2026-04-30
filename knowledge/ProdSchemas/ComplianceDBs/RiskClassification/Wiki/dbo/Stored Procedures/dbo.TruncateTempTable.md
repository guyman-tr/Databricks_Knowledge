# dbo.TruncateTempTable

> Utility procedure that clears the T_ScoresTemporary staging table after the risk classification processing pipeline completes, preparing it for the next batch of recalculated scores.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters, no return value |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs the final "clear" step in the Load-Process-Truncate risk scoring pipeline. After the external risk engine loads scores into `T_ScoresTemporary` and `P_RiskClassification` merges them into the permanent tables, this procedure is called to truncate the staging table, preparing it for the next batch.

Without this procedure, residual data from previous runs would remain in T_ScoresTemporary, potentially causing the next MERGE to re-process already-handled scores or creating key conflicts on INSERT. The TRUNCATE operation is used instead of DELETE for performance (minimal logging, instant space reclamation).

Created by Yulia Kramer on 2020-07-19 as part of the BI processing pipeline automation.

---

## 2. Business Logic

No complex logic. Single `TRUNCATE TABLE [dbo].[T_ScoresTemporary]` statement with `SET NOCOUNT ON`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No parameters. No return values. The procedure takes no input and produces no output - it simply truncates the staging table.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TRUNCATE | dbo.T_ScoresTemporary | Target | Clears all rows from the staging table |

### 5.2 Referenced By (other objects point to this)

Called by external BI/risk processing pipeline after P_RiskClassification completes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.TruncateTempTable (procedure)
+-- dbo.T_ScoresTemporary (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.T_ScoresTemporary | Table | TRUNCATE TABLE |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by external pipeline.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC dbo.TruncateTempTable
```

### 8.2 Verify staging table is empty after execution
```sql
EXEC dbo.TruncateTempTable
SELECT COUNT(*) AS RemainingRows FROM dbo.T_ScoresTemporary WITH (NOLOCK)
```

### 8.3 Check staging table row count before and after
```sql
SELECT 'Before' AS Phase, COUNT(*) AS Rows FROM dbo.T_ScoresTemporary WITH (NOLOCK)
EXEC dbo.TruncateTempTable
SELECT 'After' AS Phase, COUNT(*) AS Rows FROM dbo.T_ScoresTemporary WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TruncateTempTable | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.TruncateTempTable.sql*
