# History.CloseExecutionPlan

> Synonym providing local-schema access to DB_Logs.History.CloseExecutionPlan - the date-partitioned archive table for Trade.CloseExecutionPlan (the in-memory close order execution plan), populated via MERGE by cleanup and delete jobs that move orphaned or completed close execution plans from the live in-memory table to long-term storage.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.CloseExecutionPlan |
| **Partition** | OccurredAsDate (date column, partition elimination via BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.CloseExecutionPlan` is a cross-database synonym pointing to `DB_Logs.History.CloseExecutionPlan`. It is the **archive tier** for `Trade.CloseExecutionPlan` - an in-memory (MEMORY_OPTIMIZED) table that holds the execution plan for "close by units" orders. The execution plan defines which positions to close, how many units from each, at what tree level, and whether they are hedged.

The live `Trade.CloseExecutionPlan` table is high-velocity but transient - rows are inserted when a close order is created and deleted when the order is processed. This History synonym serves as the permanent archive: two cleanup/delete jobs (run as SQL Agent jobs) move completed or orphaned execution plan rows from the in-memory table to this archive via MERGE operations.

**Key distinction from `History.CloseByUnitsFail`**: `CloseByUnitsFail` records failures; `CloseExecutionPlan` records the successful (or at minimum attempted) execution plans regardless of outcome. Every close-by-units order that was created will eventually have its plan rows here.

The `OccurredAsDate` column (added automatically during archive, not in the live table) enables date-based partition elimination for efficient querying - callers always filter `OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)` to avoid full table scans.

---

## 2. Business Logic

### 2.1 Archive via Cleanup Job

**What**: `Trade.CleanupCloseExecutionPlanJob` (SQL Agent job) finds orphaned execution plans and archives them.

**Rules**:
- An orphan is a row in `Trade.CloseExecutionPlan` with no matching row in `Trade.OrderForClose`
- The job uses `EXCEPT` to find such OrderIDs, then MERGEs them into `History.CloseExecutionPlan`
- MERGE logic: INSERT if (OrderID, PositionID) not in History within the last 30 days; UPDATE if already present
- After successful MERGE, deletes the archived rows from `Trade.CloseExecutionPlan`
- Triggered by SQL Agent job "[etoro - US CleanupJob]"

### 2.2 Archive via Delete Job

**What**: `Trade.DeleteCloseExecutionPlanJob` archives execution plans for a specific list of OrderIDs.

**Rules**:
- Receives a list of OrderIDs via `Trade.IdIntList` TVP parameter
- Performs the same MERGE pattern (INSERT or UPDATE into History, then DELETE from Trade)
- Used for explicit, targeted archival when specific orders need to be cleared

### 2.3 Partition Elimination Pattern

**What**: All MERGE and SELECT operations on History.CloseExecutionPlan use partition elimination.

**Rules**:
- Target side of MERGE always includes: `AND Target.OccurredAsDate between CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)`
- This ensures SQL Server scans only the relevant date partition(s) rather than the full history table
- Readers (GetOrdersForExecutionReport, GetAleErrorReport, etc.) must include OccurredAsDate filter for performance

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.CloseExecutionPlan. Target columns inferred from MERGE statements in Trade.CleanupCloseExecutionPlanJob and Trade.DeleteCloseExecutionPlanJob: OrderID (bigint, PK part 1 - the close order ID), PositionID (bigint, PK part 2 - the position being closed), Units (decimal(16,6), units to close from this position), Level (smallint, tree level in the copy-trade hierarchy; 0=root, N=Nth copy level), CID (int, customer ID of the position owner), CloseActionType (tinyint, type of close action), IsHedged (bit, whether this position is hedged), OccurredAsDate (date, archive date added on MERGE - used for partition elimination; not in Trade.CloseExecutionPlan live table). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.CloseExecutionPlan | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CleanupCloseExecutionPlanJob | MERGE (INSERT/UPDATE) | Writer | Archives orphaned close execution plans (no matching OrderForClose) |
| Trade.DeleteCloseExecutionPlanJob | MERGE (INSERT/UPDATE) | Writer | Archives specific OrderID execution plans on demand |
| Trade.GetOrdersForExecutionReportV2 | SELECT | Reader | Reads archived execution plans for execution reporting |
| Trade.GetOrdersForExecutionReportV3Junk | SELECT | Reader | Reads archived execution plans for execution reporting (v3) |
| Trade.GetAleErrorReport | SELECT | Reader | Reads execution plans for ALE error analysis |
| Trade.GetAleErrorReportV2 | SELECT | Reader | Reads execution plans for ALE error analysis (v2) |
| Trade.GetAleErrorReportNew | SELECT | Reader | Reads execution plans for ALE error analysis (new version) |
| Trade.FunGetAleErrorReportNew | SELECT | Reader | Table-valued function reading execution plans for ALE errors |
| Trade.GetOrderForClosePositionsOvt | SELECT | Reader | Reads archived execution plans for position OVT queries |
| Trade.ViewBulkOrders | SELECT | Reader | Reads execution plans for bulk order views |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CloseExecutionPlan (synonym)
├── DB_Logs.History.CloseExecutionPlan (table - external database)
└── Source: Trade.CloseExecutionPlan (in-memory live table -> archived here)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.CloseExecutionPlan | Table (external DB) | Synonym target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CleanupCloseExecutionPlanJob | Stored Procedure | Archive writer (orphan cleanup) |
| Trade.DeleteCloseExecutionPlanJob | Stored Procedure | Archive writer (targeted delete) |
| Trade.GetOrdersForExecutionReportV2 | Stored Procedure | Execution report reader |
| Trade.GetAleErrorReport | Stored Procedure | ALE error report reader |
| Trade.GetAleErrorReportV2 | Stored Procedure | ALE error report reader |
| Trade.GetAleErrorReportNew | Stored Procedure | ALE error report reader |
| Trade.FunGetAleErrorReportNew | Function | ALE error report reader |
| Trade.GetOrderForClosePositionsOvt | Stored Procedure | OVT query reader |
| Trade.ViewBulkOrders | Stored Procedure | Bulk order view reader |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym (target table partition structure: date-partitioned on OccurredAsDate; MERGE targets use `OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)` for partition elimination).

### 7.2 Constraints

N/A for Synonym. MERGE pattern used for both INSERT and UPDATE scenarios. The live table (`Trade.CloseExecutionPlan`) is MEMORY_OPTIMIZED with nonclustered hash indexes; the archive table is disk-based with date partitioning.

---

## 8. Sample Queries

### 8.1 Find archived execution plans for a specific order (within last 30 days)

```sql
SELECT
    OrderID,
    PositionID,
    Units,
    Level,
    CID,
    CloseActionType,
    IsHedged,
    OccurredAsDate
FROM History.CloseExecutionPlan WITH (NOLOCK)
WHERE OrderID = 987654
  AND OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)
ORDER BY Level ASC
```

### 8.2 Count positions in execution plans by close action type (recent)

```sql
SELECT
    CloseActionType,
    COUNT(*) AS PlanRows,
    COUNT(DISTINCT OrderID) AS UniqueOrders
FROM History.CloseExecutionPlan WITH (NOLOCK)
WHERE OccurredAsDate BETWEEN CAST(GETUTCDATE()-7 AS DATE) AND CAST(GETUTCDATE() AS DATE)
GROUP BY CloseActionType
ORDER BY PlanRows DESC
```

### 8.3 Find all execution plans for a specific customer (last 30 days)

```sql
SELECT TOP 50
    OrderID,
    PositionID,
    Units,
    Level,
    CloseActionType,
    IsHedged,
    OccurredAsDate
FROM History.CloseExecutionPlan WITH (NOLOCK)
WHERE CID = 12345
  AND OccurredAsDate BETWEEN CAST(GETUTCDATE()-30 AS DATE) AND CAST(GETUTCDATE() AS DATE)
ORDER BY OccurredAsDate DESC, OrderID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.CloseExecutionPlan | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.CloseExecutionPlan.sql*
