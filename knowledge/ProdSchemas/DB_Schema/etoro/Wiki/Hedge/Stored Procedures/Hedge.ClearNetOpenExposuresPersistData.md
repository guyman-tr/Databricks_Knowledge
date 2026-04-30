# Hedge.ClearNetOpenExposuresPersistData

> Clears the net open dollar exposure persist cache by truncating Hedge.PositionsNetOpenDollarTbl, resetting it for a fresh global exposure snapshot cycle.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | TRUNCATE TABLE Hedge.PositionsNetOpenDollarTbl |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.ClearNetOpenExposuresPersistData` is the reset half of the net open dollar exposure snapshot pipeline. It truncates `Hedge.PositionsNetOpenDollarTbl`, the persist cache for the global net open position exposure aggregated by instrument.

`Hedge.PositionsNetOpenDollarTbl` stores the aggregate net exposure in USD across all customer positions, grouped by instrument. This is the table the hedge engine reads when making real-time hedging decisions about whether to buy or sell at the LP to balance the book. To refresh this cache, the pipeline follows the same clear-then-populate pattern as the hedge exposure cache:
1. **This procedure**: TRUNCATE to empty the table
2. A separate populate step: rebuild from current customer position data

This is the companion to `Hedge.ClearHedgeExposuresPersistData` which resets `Hedge.PositionsHedgeTbl`. The two procedures together clear both sides of the exposure picture:
- `PositionsHedgeTbl`: the LP/hedge side of exposures
- `PositionsNetOpenDollarTbl`: the customer/net open dollar side

---

## 2. Business Logic

### 2.1 Atomic Full-Table Reset

**What**: Empties Hedge.PositionsNetOpenDollarTbl in a single DDL operation.

**Rules**:
- TRUNCATE TABLE removes all rows from the table
- No WHERE clause - always removes all rows
- No parameters - always operates on Hedge.PositionsNetOpenDollarTbl
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
| (truncates) | Hedge.PositionsNetOpenDollarTbl | TRUNCATE | Empties the global net open dollar exposure persist cache |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called by the hedge engine exposure snapshot refresh cycle.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ClearNetOpenExposuresPersistData (procedure)
+-- Hedge.PositionsNetOpenDollarTbl (table) - TRUNCATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.PositionsNetOpenDollarTbl | Table | TRUNCATE target - the net open dollar exposure persist cache |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge engine snapshot pipeline) | External | Calls this before repopulating the net open dollar exposure cache |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- TRUNCATE requires ALTER TABLE permission (not just DELETE permission)
- TRUNCATE cannot be rolled back outside an explicit transaction
- No TRY/CATCH, no parameters, no SET NOCOUNT ON
- If Hedge.PositionsNetOpenDollarTbl has foreign key references, TRUNCATE will fail

---

## 8. Sample Queries

### 8.1 Execute: Clear the net open exposure cache

```sql
EXEC Hedge.ClearNetOpenExposuresPersistData
```

### 8.2 Paired execution: Clear both exposure caches together

```sql
-- Clear both sides of the exposure persist caches in one batch
EXEC Hedge.ClearHedgeExposuresPersistData
EXEC Hedge.ClearNetOpenExposuresPersistData
```

### 8.3 Verify: Check row count before and after

```sql
SELECT COUNT(*) AS RowsBefore FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
EXEC Hedge.ClearNetOpenExposuresPersistData
SELECT COUNT(*) AS RowsAfter FROM Hedge.PositionsNetOpenDollarTbl WITH (NOLOCK)
-- Expect: RowsAfter = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ClearNetOpenExposuresPersistData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ClearNetOpenExposuresPersistData.sql*
