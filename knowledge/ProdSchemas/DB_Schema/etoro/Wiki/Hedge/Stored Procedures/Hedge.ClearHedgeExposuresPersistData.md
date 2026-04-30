# Hedge.ClearHedgeExposuresPersistData

> Clears the hedge exposure persist cache by truncating Hedge.PositionsHedgeTbl, resetting it for a fresh exposure snapshot cycle.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | TRUNCATE TABLE Hedge.PositionsHedgeTbl |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ClearHedgeExposuresPersistData` is the reset half of the hedge exposure snapshot pipeline. It truncates `Hedge.PositionsHedgeTbl`, the in-memory persist cache for current hedge exposure positions.

`Hedge.PositionsHedgeTbl` is a high-frequency cache that the hedge engine reads when reporting or calculating exposure without hitting the main position tables. To refresh this cache, the pipeline follows a clear-then-populate cycle:
1. **This procedure**: TRUNCATE to empty the table atomically and instantly
2. A separate populate procedure (or direct INSERT): rebuild the cache with fresh position data from current Hedge tables

This procedure is the first step in that cycle. Without the clear step, stale positions from a prior snapshot would remain alongside fresh data, causing incorrect exposure calculations.

TRUNCATE is used instead of DELETE because it is:
- DDL-level operation, faster than DELETE for full-table removal
- Does not log individual row deletions (minimal logging)
- Resets identity/page allocations

This is a companion to `Hedge.ClearNetOpenExposuresPersistData` which performs the equivalent reset for `Hedge.PositionsNetOpenDollarTbl`.

---

## 2. Business Logic

### 2.1 Atomic Full-Table Reset

**What**: Empties Hedge.PositionsHedgeTbl in a single DDL operation.

**Rules**:
- TRUNCATE TABLE removes all rows from the table
- No WHERE clause - always removes all rows
- No parameters - always operates on Hedge.PositionsHedgeTbl
- Caller is responsible for repopulating the table after clearing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters - procedure takes no arguments.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (truncates) | Hedge.PositionsHedgeTbl | TRUNCATE | Empties the hedge exposure persist cache |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge engine exposure snapshot refresh cycle.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ClearHedgeExposuresPersistData (procedure)
+-- Hedge.PositionsHedgeTbl (table) - TRUNCATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsHedgeTbl | Table | TRUNCATE target - the hedge exposure persist cache |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge engine snapshot pipeline) | External | Calls this before repopulating the exposure cache |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- TRUNCATE requires ALTER TABLE permission (not just DELETE permission)
- TRUNCATE cannot be rolled back if called outside an explicit transaction
- No TRY/CATCH, no parameters, no SET NOCOUNT ON
- If Hedge.PositionsHedgeTbl has foreign key references, TRUNCATE will fail; DELETE would be required instead

---

## 8. Sample Queries

### 8.1 Execute: Clear the hedge exposure cache

```sql
EXEC Hedge.ClearHedgeExposuresPersistData
```

### 8.2 Verify: Check row count before and after

```sql
SELECT COUNT(*) AS RowsBefore FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
EXEC Hedge.ClearHedgeExposuresPersistData
SELECT COUNT(*) AS RowsAfter FROM Hedge.PositionsHedgeTbl WITH (NOLOCK)
-- Expect: RowsAfter = 0
```

### 8.3 Pattern: Clear-then-populate snapshot refresh

```sql
-- Step 1: Clear the cache
EXEC Hedge.ClearHedgeExposuresPersistData

-- Step 2: Populate with fresh data (actual populate procedure varies)
-- INSERT INTO Hedge.PositionsHedgeTbl SELECT ... FROM Hedge.Netting ...
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ClearHedgeExposuresPersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ClearHedgeExposuresPersistData.sql*
