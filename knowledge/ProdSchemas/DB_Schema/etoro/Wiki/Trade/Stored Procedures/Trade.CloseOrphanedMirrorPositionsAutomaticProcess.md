# Trade.CloseOrphanedMirrorPositionsAutomaticProcess

> Processes the orphaned position close queue by executing pre-built close commands one at a time, marking each as succeeded (1), failed (-1), or permanently failed (-2).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (from Trade.TradeOrphanedPositionsCloseByJob queue) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseOrphanedMirrorPositionsAutomaticProcess is the execution engine for orphaned CopyTrader position closures. It processes pending commands queued by Trade.CloseOrpahnedPositions, executing each one dynamically via EXEC(@cmd). This allows the system to close orphaned mirror/copy positions that lost their parent relationship.

Created by Elad on 2019-03-18, later moved from etoro_general to etoro DB by Ran Ovadia on 2025-02-09.

The procedure uses a WHILE loop to process one position at a time with individual TRY/CATCH blocks, ensuring that a failure on one position does not prevent others from being processed. After all attempts, positions that failed (ExecuteStatus=-1) are permanently marked as -2 (abandoned).

---

## 2. Business Logic

### 2.1 Queue Processing Loop

**What**: Processes all pending orphaned position close commands.

**Columns/Parameters Involved**: `PositionID`, `Cmd`, `ExecuteStatus`, `ExecuteDate`

**Rules**:
- Processes positions with ExecuteStatus = 0 (pending)
- Takes the minimum PositionID first (FIFO by PositionID)
- Executes the Cmd column as dynamic SQL via EXEC(@cmd)
- On success: ExecuteStatus = 1, ExecuteDate = GETUTCDATE()
- On failure: ExecuteStatus = -1, ExecuteDate = GETUTCDATE()
- After loop completes: all ExecuteStatus = -1 rows are set to -2 (permanently failed)

**Diagram**:
```
Trade.TradeOrphanedPositionsCloseByJob (ExecuteStatus = 0)
          |
     WHILE loop (min PositionID first)
          |
     TRY: EXEC(@cmd)
     |         |
  Success    Failure
     |         |
  Status=1   Status=-1
     |         |
     +---------+
          |
  After loop: -1 -> -2 (permanent fail)
```

### 2.2 Dynamic SQL Execution

**What**: Executes pre-built close commands stored in the Cmd column.

**Rules**:
- The Cmd column contains arbitrary SQL (built by the orphan detection service)
- Uses EXEC(@cmd) without parameterization (security consideration - Cmd is system-generated)
- Each command is expected to close a specific orphaned position

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It reads its work from the Trade.TradeOrphanedPositionsCloseByJob queue table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID, Cmd | Trade.TradeOrphanedPositionsCloseByJob | READ + UPDATE | Reads pending commands (ExecuteStatus=0), updates status after execution |
| Cmd | (dynamic targets) | EXEC (dynamic) | Executes stored SQL commands that close specific positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job / Scheduler | Scheduled | EXEC | Runs periodically to process the orphaned position queue |
| Trade.CloseOrpahnedPositions | (upstream) | Queue | Populates the queue that this procedure processes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseOrphanedMirrorPositionsAutomaticProcess (procedure)
+-- Trade.TradeOrphanedPositionsCloseByJob (table)
+-- (dynamic SQL targets - determined at runtime)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.TradeOrphanedPositionsCloseByJob | Table | READ (pending commands) + UPDATE (execution status) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled job | External | Periodic execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL via EXEC() | Security | Executes arbitrary SQL from the Cmd column - relies on system-generated commands being safe |
| Per-position TRY/CATCH | Resilience | Failure on one position does not prevent others from processing |
| Permanent failure marking | Cleanup | Failed rows (-1) are finalized to -2 after the loop completes |

---

## 8. Sample Queries

### 8.1 Check queue status summary

```sql
SELECT ExecuteStatus,
       CASE ExecuteStatus WHEN 0 THEN 'Pending' WHEN 1 THEN 'Success' WHEN -1 THEN 'Failed' WHEN -2 THEN 'Permanent Fail' END AS StatusName,
       COUNT(*) AS Cnt
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
GROUP BY ExecuteStatus;
```

### 8.2 View pending commands

```sql
SELECT TOP 10 PositionID, ParentPositionID, Cmd, EntryDate
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
WHERE  ExecuteStatus = 0
ORDER BY PositionID;
```

### 8.3 Review permanently failed close attempts

```sql
SELECT PositionID, ParentPositionID, Cmd, EntryDate, ExecuteDate
FROM   Trade.TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
WHERE  ExecuteStatus = -2
ORDER BY ExecuteDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseOrphanedMirrorPositionsAutomaticProcess | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseOrphanedMirrorPositionsAutomaticProcess.sql*
