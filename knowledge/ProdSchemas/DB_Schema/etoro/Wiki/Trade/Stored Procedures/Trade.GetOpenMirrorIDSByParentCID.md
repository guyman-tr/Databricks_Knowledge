# Trade.GetOpenMirrorIDSByParentCID

> Returns all active (MirrorStatusID=0) copy-trade mirror IDs and copier CIDs for a given leader (ParentCID), used to identify which copiers are currently following the leader.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT - the leader whose active copiers are fetched |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOpenMirrorIDSByParentCID` retrieves all copy-trade relationships where the given customer is the leader (`ParentCID`) and the mirror is currently active (`MirrorStatusID = 0`). It returns the `MirrorID` and the copier's `CID` for each active relationship. "Open" in the procedure name refers to active/open mirrors, not open positions.

**WHY:** When an action needs to be propagated to all of a leader's copiers - such as closing a copy relationship, executing a position action across the tree, or collecting copier data - this SP provides the list of which mirrors and copiers are currently active. Without it, callers would have to query `Trade.Mirror` directly with knowledge of the MirrorStatusID filter.

**HOW:** Called from application code (no SQL-level callers found). The filter `MirrorStatusID = 0` ensures only **active** mirrors are returned - paused (1), pending-close (2), and in-alignment (3) mirrors are excluded. `NOLOCK` hint reflects the read-mostly, high-throughput nature of copy-trade queries.

---

## 2. Business Logic

### 2.1 Active Mirror Filter

**What:** Only mirrors with `MirrorStatusID = 0` (Active) are returned. This is the key business filter distinguishing which copiers are live.

**Columns/Parameters Involved:** `MirrorStatusID`, `ParentCID`

**Rules:**
- MirrorStatusID values: 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment (Dictionary.MirrorStatus)
- Only MirrorStatusID=0 (Active) rows are returned - paused, pending-close, and in-alignment mirrors are excluded
- The result represents all copiers who are currently executing trades on behalf of the leader

**Diagram:**
```
Trade.Mirror rows for ParentCID = @ParentCID:
  MirrorStatusID=0 (Active)   -> INCLUDED in result
  MirrorStatusID=1 (Pause)    -> EXCLUDED
  MirrorStatusID=2 (PendingClose) -> EXCLUDED
  MirrorStatusID=3 (InAlignment)  -> EXCLUDED
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | int | NO | - | CODE-BACKED | Input: the leader's Customer ID. All active mirrors where this CID is the leader (ParentCID) are returned. |

**Return Columns (from Trade.Mirror):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| R1 | MirrorID | int | NO | - | CODE-BACKED | The copy-trade relationship ID. Uniquely identifies the follower-leader relationship. Use to reference Trade.Mirror or to link to Trade.Position.MirrorID. |
| R2 | CID | int | NO | - | CODE-BACKED | The copier's Customer ID. The customer who is currently copying the leader identified by @ParentCID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ParentCID | Trade.Mirror | Direct query | SELECT WHERE ParentCID = @ParentCID AND MirrorStatusID = 0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application code | N/A | CALLER | Called to enumerate active copiers for a given leader |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOpenMirrorIDSByParentCID (procedure)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT MirrorID, CID WHERE ParentCID = @ParentCID AND MirrorStatusID = 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application execution/copy-trade services | External | Calls to enumerate active mirrors for leader actions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `WITH (NOLOCK)` on Trade.Mirror - read-uncommitted scan for high-throughput copy-trade queries.

---

## 8. Sample Queries

### 8.1 Get all active copiers for a leader
```sql
EXEC Trade.GetOpenMirrorIDSByParentCID @ParentCID = 12345678
```

### 8.2 Verify active mirror count for a leader
```sql
SELECT COUNT(*) AS ActiveCopierCount
FROM   Trade.Mirror WITH (NOLOCK)
WHERE  ParentCID = 12345678
       AND MirrorStatusID = 0
```

### 8.3 Join copier mirrors to their positions
```sql
SELECT m.MirrorID,
       m.CID AS CopierCID,
       m.Amount AS AllocatedAmount,
       COUNT(p.PositionID) AS OpenPositions
FROM   Trade.Mirror m WITH (NOLOCK)
       LEFT JOIN Trade.Position p WITH (NOLOCK)
           ON p.MirrorID = m.MirrorID
           AND p.StatusID = 1 -- open
WHERE  m.ParentCID = 12345678
       AND m.MirrorStatusID = 0
GROUP  BY m.MirrorID, m.CID, m.Amount
ORDER  BY OpenPositions DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOpenMirrorIDSByParentCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOpenMirrorIDSByParentCID.sql*
