# Trade.CloseByRateAlert

> Identifies positions that were marked for manual crisis closure (within the last 2 hours) but are still open (StatusID=1) in Trade.PositionTbl, returning their PositionIDs for follow-up processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | PositionID (output - positions needing crisis close follow-up) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CloseByRateAlert is a crisis management procedure that detects positions which were submitted for manual closure during a market crisis event but have not yet been successfully closed. It queries the History.ManualOperationPositionClose_Crisis and History.ManualPositionClose_Crisis tables (which log crisis-triggered close requests) and cross-references with Trade.PositionTbl to find positions still in StatusID=1 (Open).

This procedure is part of eToro's crisis response system. During extreme market events (flash crashes, circuit breakers, etc.), operations may trigger mass position closures. If some closures fail or are delayed, this procedure identifies the stragglers so they can be re-processed. The 2-hour lookback window (DATEADD(HOUR, -2, GETUTCDATE())) ensures only recent crisis events are considered.

---

## 2. Business Logic

### 2.1 Crisis Close Straggler Detection

**What**: Finds positions from recent crisis close operations that remain open.

**Columns/Parameters Involved**: `OperationID`, `PositionID`, `StatusID`, `InsertDate`

**Rules**:
- Looks back 2 hours from current UTC time for crisis operations
- Joins History.ManualOperationPositionClose_Crisis -> History.ManualPositionClose_Crisis -> Trade.PositionTbl
- Only returns positions where StatusID = 1 (still open)
- Uses OPTION (RECOMPILE) on initial query for fresh statistics
- Returns a result set of PositionIDs (not a scalar output)

**Diagram**:
```
History.ManualOperationPositionClose_Crisis (last 2 hours)
          |
          JOIN (OperationID)
          |
History.ManualPositionClose_Crisis
          |
          JOIN (PositionID)
          |
Trade.PositionTbl (StatusID = 1 = still open)
          |
          = PositionIDs needing re-closure
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | This procedure has no parameters. It returns a result set of PositionIDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OperationID | History.ManualOperationPositionClose_Crisis | READ | Finds crisis close operations from the last 2 hours |
| OperationID, PositionID | History.ManualPositionClose_Crisis | READ (JOIN) | Maps operations to individual positions targeted for closure |
| PositionID | Trade.PositionTbl | READ (JOIN) | Filters to positions still in StatusID=1 (open) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external - crisis management) | - | EXEC | Called by operations/monitoring to detect failed crisis closures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CloseByRateAlert (procedure)
+-- History.ManualOperationPositionClose_Crisis (table)
+-- History.ManualPositionClose_Crisis (table)
+-- Trade.PositionTbl (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ManualOperationPositionClose_Crisis | Table | READ - crisis operation records |
| History.ManualPositionClose_Crisis | Table | READ - individual position close requests |
| Trade.PositionTbl | Table | READ - verifies positions are still open (StatusID=1) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (external) | - | Called by crisis management systems |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Performance | Forces recompilation for accurate cardinality estimates on time-filtered data |
| WITH (NOLOCK) | Isolation | Reads from History tables without locks (acceptable for monitoring) |
| Temp table with clustered index | Performance | #OperationList gets clustered index on OperationID for efficient JOIN |

---

## 8. Sample Queries

### 8.1 Run crisis close straggler detection

```sql
EXEC Trade.CloseByRateAlert;
```

### 8.2 Check recent crisis operations directly

```sql
SELECT TOP 10 OperationID, InsertDate
FROM   History.ManualOperationPositionClose_Crisis WITH (NOLOCK)
ORDER BY InsertDate DESC;
```

### 8.3 Count open positions per crisis operation

```sql
SELECT c.OperationID, COUNT(*) AS StillOpenCount
FROM   History.ManualPositionClose_Crisis c WITH (NOLOCK)
       INNER JOIN Trade.PositionTbl tp WITH (NOLOCK) ON tp.PositionID = c.PositionID AND tp.StatusID = 1
       INNER JOIN History.ManualOperationPositionClose_Crisis o WITH (NOLOCK) ON o.OperationID = c.OperationID
WHERE  o.InsertDate >= DATEADD(HOUR, -2, GETUTCDATE())
GROUP BY c.OperationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CloseByRateAlert | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CloseByRateAlert.sql*
