# Trade.CleanupOpenExecutionPlanJob

> Archives completed open execution plans from Trade.OpenExecutionPlan to History.OpenExecutionPlan using MERGE, then deletes the archived rows. Part of the US CleanupJob.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - autonomous job |
| **Partition** | History.OpenExecutionPlan partitioned by OccurredAsDate |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CleanupOpenExecutionPlanJob moves completed open execution plan records from the hot operational table to history. An open execution plan row is considered "completed" when its OrderID no longer appears in Trade.OrderForOpen. The procedure preserves the full plan detail including CID, MirrorID, units, level, settlement type, hedge status, action type, and correlation IDs.

Part of the `[etoro - US CleanupJob]` SQL Agent job. Same archive pattern as the other cleanup procedures.

---

## 2. Business Logic

### 2.1 Completed Order Detection

**What**: Finds OrderIDs in Trade.OpenExecutionPlan that are not in Trade.OrderForOpen.

### 2.2 MERGE to History

**What**: Upserts into History.OpenExecutionPlan with partition elimination on OccurredAsDate (last 30 days).

**Columns Archived**: OrderID, CID, MirrorID, Units, Level, SettlementTypeID, IsHedged, OpenActionType, OpenCorrelationID, ParentOpenCorrelationID, Amount

**Match Key**: OrderID + OpenCorrelationID (two-part match for correlation uniqueness)

### 2.3 Delete from Active

**What**: Removes archived rows from Trade.OpenExecutionPlan after successful MERGE.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.OpenExecutionPlan | SELECT + DELETE | Source: open execution plans |
| (reads) | Trade.OrderForOpen | SELECT (EXCEPT) | Reference: active open orders |
| (writes) | History.OpenExecutionPlan | MERGE (INSERT/UPDATE) | Target: archived open execution plans |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [etoro - US CleanupJob] | SQL Agent Job | EXEC | Scheduled cleanup job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CleanupOpenExecutionPlanJob (procedure)
+-- Trade.OpenExecutionPlan (table)
+-- Trade.OrderForOpen (table)
+-- History.OpenExecutionPlan (table, partitioned)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenExecutionPlan | Table | SELECT source + DELETE |
| Trade.OrderForOpen | Table | EXCEPT reference |
| History.OpenExecutionPlan | Table | MERGE target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| [etoro - US CleanupJob] | SQL Agent Job | Scheduled execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Partition elimination | Performance | History MERGE filters OccurredAsDate between GETUTCDATE()-30 and GETUTCDATE() |
| Nonclustered index on temp | Performance | #OpenExecutionPlan uses nonclustered index on OrderID |
| Two-part MERGE match | Uniqueness | OrderID + OpenCorrelationID |
| TRY/CATCH with RAISERROR | Error handling | Captures and re-raises with procedure name prefix |

---

## 8. Sample Queries

### 8.1 Run the cleanup

```sql
EXEC Trade.CleanupOpenExecutionPlanJob;
```

### 8.2 Check counts

```sql
SELECT 'Active' AS Source, COUNT(*) AS Cnt FROM Trade.OpenExecutionPlan WITH (NOLOCK)
UNION ALL
SELECT 'History (30d)', COUNT(*) FROM History.OpenExecutionPlan WITH (NOLOCK)
WHERE OccurredAsDate >= CAST(GETUTCDATE()-30 AS DATE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CleanupOpenExecutionPlanJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CleanupOpenExecutionPlanJob.sql*
