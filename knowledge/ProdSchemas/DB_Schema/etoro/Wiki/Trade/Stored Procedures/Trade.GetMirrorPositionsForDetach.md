# Trade.GetMirrorPositionsForDetach

> Returns open copy-trade position IDs and instrument IDs for a specific customer in a mirror, used during mirror detach processing to identify which positions must be closed or re-parented.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId + @cid - identifies one customer's open copy positions in one mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorPositionsForDetach` retrieves the minimal set of identifiers (`PositionID`, `InstrumentID`) for all open copy-trade positions owned by a customer (`@cid`) within a specific mirror (`@mirrorId`). It is called during the mirror detach flow to enumerate positions that need to be actioned - typically closed or re-routed - before the customer can fully detach from the mirror.

The procedure reads directly from `Trade.PositionTbl` (not the view) and a code comment notes that an index on MirrorID exists to support efficient filtering. The double filter `MirrorID = @mirrorId AND MirrorID > 0` is a safety guard against accidentally matching positions with MirrorID=0 (manual trades).

Data flows: Part of the SSE detach flow (alongside `GetMirrorOrderIdForSSEDetach` for orders and `GetMirrorPartialExitOrdersDataWithCIDAndMirrorIdForSSE` for exit orders). Returns the position list for position-level detach cleanup.

---

## 2. Business Logic

### 2.1 Detach-Safe Position Filter

**What**: Only genuinely active copy positions that are eligible for detach processing are returned.

**Columns/Parameters Involved**: `MirrorID`, `ParentPositionID`, `CID`, `StatusID`

**Rules**:
- `MirrorID = @mirrorId AND MirrorID > 0`: Scoped to the mirror. The `MirrorID > 0` guard prevents manual positions (MirrorID=0) from being included even if @mirrorId were passed as 0.
- `ParentPositionID > 0`: Copy-trade child positions only. Root/manual positions are excluded.
- `CID = @cid`: Scoped to one customer within the mirror.
- `StatusID = 1`: Open positions only. Closed positions do not need detach processing.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The mirror identifier. Filters PositionTbl to positions in this mirror (AND MirrorID > 0 guard). |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer ID. Scopes the result to one user's positions within the mirror. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | PositionID | Trade.PositionTbl | The unique position identifier. Used by caller to execute detach-related actions on each position. |
| 2 | InstrumentID | Trade.PositionTbl | The instrument for this position. Provided so caller can group or route actions by instrument without an additional join. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId + @cid | Trade.PositionTbl | Primary read | Reads open copy positions with the given mirror + customer combination. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorPositionsForDetach (procedure)
└── Trade.PositionTbl (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT PositionID, InstrumentID WHERE MirrorID + CID + StatusID + ParentPositionID filters |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get positions for detach

```sql
EXEC Trade.GetMirrorPositionsForDetach @mirrorId = 12345, @cid = 67890;
```

### 8.2 Verify count of detachable positions directly

```sql
SELECT COUNT(*) AS DetachablePositions
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 12345
  AND MirrorID > 0
  AND ParentPositionID > 0
  AND CID = 67890
  AND StatusID = 1;
```

### 8.3 Detach positions grouped by instrument

```sql
SELECT InstrumentID, COUNT(*) AS PositionCount
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 12345
  AND MirrorID > 0
  AND ParentPositionID > 0
  AND CID = 67890
  AND StatusID = 1
GROUP BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorPositionsForDetach | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorPositionsForDetach.sql*
