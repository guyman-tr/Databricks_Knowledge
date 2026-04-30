# Trade.GetAllPositionsWithNoLock

> Returns all open position IDs from Trade.PositionTbl using NOLOCK, designed for cross-environment orphaned position detection from Demo.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns PositionID list of all open positions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all open position IDs from the real trading environment. It was specifically created to be invoked from the Demo environment via a linked server to detect orphaned positions - positions that exist in Demo but no longer exist in the real environment. Since linked servers do not support locking hints in the remote query, this procedure wraps the NOLOCK hint locally to avoid blocking production trading operations.

The procedure exists as a non-blocking access point for cross-environment position reconciliation. Without it, the Demo environment would need to query the real PositionTbl via linked server without NOLOCK, which could cause shared locks that block trading.

Data flows as a simple read from `Trade.PositionTbl` WHERE `StatusID = 1` (open positions). Only the PositionID column is returned for minimal data transfer across the linked server connection.

---

## 2. Business Logic

### 2.1 Open Position Filter

**What**: Returns only currently open positions.

**Columns/Parameters Involved**: `StatusID`, `PositionID`

**Rules**:
- `WHERE StatusID = 1` - StatusID 1 = Open position
- Uses `WITH (NOLOCK)` explicitly to prevent blocking production trading
- Returns only PositionID for minimal data transfer across linked server

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | BIGINT | NO | - | CODE-BACKED | Unique position identifier from Trade.PositionTbl. Only open positions (StatusID=1) are returned. Used by Demo environment to reconcile against its own position list. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.PositionTbl | SELECT FROM | Source table - reads open position IDs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Demo environment | Linked server | Cross-environment call | Called from Demo environment to detect orphaned positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllPositionsWithNoLock (procedure)
+-- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT FROM - reads open position IDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Demo environment procedures | Linked server | Calls this via linked server for orphan detection |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllPositionsWithNoLock;
```

### 8.2 Count open positions
```sql
SELECT  COUNT(*) AS OpenPositionCount
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   StatusID = 1;
```

### 8.3 Find orphaned positions in Demo (example from Demo environment)
```sql
-- Run from Demo environment via linked server
SELECT  d.PositionID
FROM    Demo.Trade.PositionTbl d WITH (NOLOCK)
WHERE   d.StatusID = 1
        AND d.PositionID NOT IN (
            SELECT PositionID FROM OPENQUERY([RealServer], 'EXEC Trade.GetAllPositionsWithNoLock')
        );
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllPositionsWithNoLock | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllPositionsWithNoLock.sql*
