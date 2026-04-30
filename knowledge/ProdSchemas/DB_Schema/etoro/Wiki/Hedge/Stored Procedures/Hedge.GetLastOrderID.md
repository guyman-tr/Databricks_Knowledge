# Hedge.GetLastOrderID

> Returns the single highest OrderID from Hedge.ExecutionLog. No parameters; TOP 1 ORDER BY OrderID DESC. Used by the hedge engine as a sequence checkpoint to resume order ID generation or detect gaps in order processing after restart.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters; returns 1 row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetLastOrderID returns the maximum OrderID currently present in Hedge.ExecutionLog. The hedge engine calls this at startup (or after restart) to determine where the order sequence left off. This "last order ID" is used as a starting point for: detecting any orders that were submitted but not logged, verifying the continuity of order processing, or initializing internal counters.

OrderID in ExecutionLog is an externally assigned identifier (not a database IDENTITY column) - it is assigned by the hedge engine or by the linked HBC system before the row is inserted. The DESC ordering ensures the most recent (highest) order ID is retrieved with a minimal scan when combined with the existing indexes on ExecutionLog.

TRY/CATCH with `THROW` re-propagates errors to the caller - if ExecutionLog is unavailable or locked, the exception bubbles up rather than returning NULL silently.

---

## 2. Business Logic

### 2.1 TOP 1 ORDER BY DESC Pattern

**What**: Retrieves the maximum OrderID without using MAX() - uses TOP 1 + ORDER BY DESC for index efficiency.

**Columns/Parameters Involved**: `OrderID`, `Hedge.ExecutionLog`

**Rules**:
- `SELECT TOP 1 OrderID FROM Hedge.ExecutionLog ORDER BY OrderID DESC`
- With an index on OrderID (ExecutionLog has multiple indexes), this resolves in O(1) via index seek to last entry.
- Returns 1 row (or 0 rows if ExecutionLog is empty, which would return an empty result set - not NULL).
- OrderID in ExecutionLog is externally assigned - not auto-incremented by the DB. The hedge engine increments it.

### 2.2 TRY/CATCH with THROW

**What**: Errors are re-raised to the caller rather than swallowed.

**Rules**:
- `BEGIN TRY / END TRY BEGIN CATCH / THROW / END CATCH`
- Any failure (table lock, permission, etc.) propagates to the caller.
- The hedge engine handles the exception in its startup sequence (likely retries or fails startup).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (0 or 1 row):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | The highest OrderID currently in Hedge.ExecutionLog. Returns 0 rows if ExecutionLog is empty. The hedge engine uses this as a restart checkpoint for order sequence continuity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TOP 1 read | Hedge.ExecutionLog | Lookup / Read | OrderID column only. TOP 1 ORDER BY OrderID DESC. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | OrderID | Caller | Startup checkpoint: reads last order ID to resume order processing sequence. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetLastOrderID (procedure)
└── Hedge.ExecutionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLog | Table | TOP 1 read on OrderID column. ORDER BY DESC. No filter. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup order sequence checkpoint. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

No NOLOCK (reads latest committed state for accuracy). TRY/CATCH with THROW. No temp tables. Minimal: single index seek on ExecutionLog.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetLastOrderID;
-- Returns 1 row: the highest OrderID in ExecutionLog
-- Returns 0 rows if ExecutionLog is empty
```

### 8.2 Equivalent direct query

```sql
SELECT TOP 1 OrderID FROM Hedge.ExecutionLog ORDER BY OrderID DESC;
```

### 8.3 Check for gaps in order sequence (manual analysis)

```sql
-- After getting last order ID, examine continuity:
SELECT TOP 100 OrderID, OrderStatus, Occurred
FROM   Hedge.ExecutionLog
ORDER BY OrderID DESC;
-- Look for gaps or unexpected order statuses near the last ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Order ID sequence management and restart checkpoint in hedge execution. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetLastOrderID | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetLastOrderID.sql*
