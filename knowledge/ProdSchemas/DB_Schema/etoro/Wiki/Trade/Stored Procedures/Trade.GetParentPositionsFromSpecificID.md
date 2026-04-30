# Trade.GetParentPositionsFromSpecificID

> Returns all PositionIDs from Trade.PositionTbl with a value >= the specified starting ID - used for batch enumeration from a checkpoint.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartingPositionID - the lower-bound PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetParentPositionsFromSpecificID` returns all PositionIDs from Trade.PositionTbl that are >= @StartingPositionID. It is a minimal range-scan utility that produces a list of position IDs from a known checkpoint onwards.

**WHY:** Batch processing workflows (e.g., partition rebuild, data migration, orphan detection sweeps) need to enumerate positions starting from a known high-watermark without loading full position rows. This SP provides a lightweight ID-only scan for that purpose.

**HOW:** Single-table SELECT of PositionID from Trade.PositionTbl WHERE PositionID >= @StartingPositionID. No NOLOCK hint - implies the caller accepts lock waits for consistency. No ROWCOUNT limit - returns ALL matching positions.

**Note:** The name "GetParentPositions..." suggests the intended use is enumerating leader/parent positions (those with ParentPositionID = 0 or used as parents by child copy positions), but the WHERE clause does NOT filter on ParentPositionID - it returns ALL positions including both leader and copy-child positions. The name reflects the calling context (enumerating from a parent-position starting point) rather than a filtered result set.

---

## 2. Business Logic

### 2.1 Range Scan from Checkpoint

**What:** Returns all positions with PositionID at or above the provided threshold.

**Columns/Parameters Involved:** `@StartingPositionID`, `PositionID`

**Rules:**
- `SELECT PositionID FROM Trade.PositionTbl WHERE PositionID >= @StartingPositionID`
- No filter on StatusID, ParentPositionID, or any other column
- Returns ALL positions regardless of open/closed/cancelled status
- No NOLOCK - consistent read (caller waits for any blocking transactions)
- No OPTION (RECOMPILE) - plan is cached

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartingPositionID | BIGINT | NO | - | CODE-BACKED | Lower-bound PositionID (inclusive). All positions with PositionID >= this value are returned. Changed from INT to BIGINT on 2021-11-17. |
| 2 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID from Trade.PositionTbl. All IDs at or above @StartingPositionID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | Lookup | Range scan: PositionID >= @StartingPositionID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetParentPositionsFromSpecificID (procedure)
|- Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Range scan returning all PositionIDs >= @StartingPositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by batch/partition processing tools |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOLOCK | Consistency | Consistent read - waits for blocking transactions |
| No row limit | Scope | Returns all matching positions - caller must handle large result sets |

---

## 8. Sample Queries

### 8.1 Get all positions from ID 50000000 onwards

```sql
EXEC Trade.GetParentPositionsFromSpecificID @StartingPositionID = 50000000
```

### 8.2 Enumerate all positions (full scan)

```sql
EXEC Trade.GetParentPositionsFromSpecificID @StartingPositionID = 1
```

### 8.3 Use result for batch iteration

```sql
DECLARE @ids TABLE (PositionID BIGINT)
INSERT @ids
EXEC Trade.GetParentPositionsFromSpecificID @StartingPositionID = 100000000

SELECT COUNT(*) AS PositionsFromCheckpoint FROM @ids
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.0/10 (Elements: 8.0/10, Logic: 6.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetParentPositionsFromSpecificID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetParentPositionsFromSpecificID.sql*
