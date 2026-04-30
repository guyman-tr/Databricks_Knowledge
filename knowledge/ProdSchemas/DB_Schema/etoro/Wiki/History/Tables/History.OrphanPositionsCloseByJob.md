# History.OrphanPositionsCloseByJob

> Audit log recording which copy-trading positions were automatically closed by the orphan-detection job on demo environments, capturing position ID, close time, and the procedure that performed the closure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PositionID (BIGINT, no formal PK) |
| **Partition** | No |
| **Indexes** | None |

---

## 1. Business Meaning

History.OrphanPositionsCloseByJob is a lightweight audit log for the orphan position cleanup process on demo trading environments. An "orphan position" is a copy-trading position in Trade.PositionTbl (ParentPositionID != 0, StatusID=1) whose parent position no longer exists in the real trading environment - meaning the copier is holding a position that is no longer backed by any live original. These positions need to be forcibly closed to prevent them from remaining open indefinitely.

This table exists to provide an audit trail of which positions were closed by the automated orphan-detection job, when each was closed, and which procedure executed the closure. Without this log, there would be no record of why a position was closed by the system rather than by the customer.

The table currently has 0 rows in the live environment. The procedure Trade.CloseAllOrphandPositions that writes to this table is explicitly restricted to demo environments only (it raises an error if Maintenance.Feature FeatureID=22 is set to 1, indicating a real/production environment). This is a demo-only safety mechanism.

---

## 2. Business Logic

### 2.1 Orphan Position Detection and Closure Flow

**What**: The orphan detection job identifies and closes copy positions that have lost their parent in the real environment.

**Columns/Parameters Involved**: `PositionID`, `CloseOccurred`, `ProcName`

**Rules**:
- A position is considered orphaned when: Trade.PositionTbl has ParentPositionID != 0 AND StatusID=1 (open) AND the parent position does NOT exist in the real environment (queried via `EXEC GetRealPositionsWithNoLock`).
- Only runs on demo environments - the procedure raises an error on real/production.
- CloseOccurred defaults to GETUTCDATE() - the UTC timestamp of when the orphan close was recorded.
- ProcName is auto-populated from the calling procedure's name using `(object_schema_name(@@procid)+'.'+object_name(@@procid))` - gives the calling stored procedure's schema.name.

**Diagram**:
```
Orphan Position Lifecycle (Demo Only)
--------------------------------------
1. Trade.CloseAllOrphandPositions runs (scheduled job, demo env)
2. Finds positions: ParentPositionID != 0, StatusID=1
3. Checks which parent positions exist in real env (GetRealPositionsWithNoLock)
4. Positions with no parent in real = orphans
5. For each orphan:
   a. Closes the position (closes in Trade schema)
   b. Inserts INTO History.OrphanPositionsCloseByJob
      (PositionID, CloseOccurred=GETUTCDATE(), ProcName=auto)
```

---

## 3. Data Overview

Table currently has 0 rows in the live database. Populated only on demo environments when the orphan-detection job runs.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | CODE-BACKED | The copy-trading position that was identified as an orphan and automatically closed. References Trade.PositionTbl.PositionID (implicit - no FK constraint). |
| 2 | CloseOccurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the orphan close was recorded in this log. Defaults to GETUTCDATE(). Represents when the async log INSERT executed. |
| 3 | ProcName | varchar(60) | YES | object_schema_name(@@procid)+'.'+object_name(@@procid) | CODE-BACKED | The stored procedure that performed the orphan close, auto-populated from the caller's schema and name using SQL Server built-ins. Provides traceability to the exact procedure version that closed the position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Implicit | The copy position that was orphaned and closed. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No other objects query this table by name.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CloseAllOrphandPositions | Stored Procedure | WRITER - inserts a row for each orphan position it closes (demo env only) |
| Trade.IsNewPositionOrphan | Stored Procedure | References orphan detection pattern |

---

## 7. Technical Details

### 7.1 Indexes

N/A for this table (no indexes defined).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistoryOrphanPositionsCloseByJob_CloseOccurred | DEFAULT | CloseOccurred defaults to GETUTCDATE() |
| DF_HistoryOrphanPositionsCloseByJob_ProcName | DEFAULT | ProcName defaults to calling procedure's schema.name via @@procid |

---

## 8. Sample Queries

### 8.1 Get all positions closed by the orphan job

```sql
SELECT PositionID, CloseOccurred, ProcName
FROM History.OrphanPositionsCloseByJob WITH (NOLOCK)
ORDER BY CloseOccurred DESC;
```

### 8.2 Count orphan closures by procedure name

```sql
SELECT ProcName, COUNT(*) AS ClosureCount, MIN(CloseOccurred) AS FirstRun, MAX(CloseOccurred) AS LastRun
FROM History.OrphanPositionsCloseByJob WITH (NOLOCK)
GROUP BY ProcName
ORDER BY ClosureCount DESC;
```

### 8.3 Find orphan-closed positions and their current status in position history

```sql
SELECT o.PositionID, o.CloseOccurred AS OrphanCloseTime, o.ProcName
FROM History.OrphanPositionsCloseByJob o WITH (NOLOCK)
ORDER BY o.CloseOccurred DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.OrphanPositionsCloseByJob | Type: Table | Source: etoro/etoro/History/Tables/History.OrphanPositionsCloseByJob.sql*
