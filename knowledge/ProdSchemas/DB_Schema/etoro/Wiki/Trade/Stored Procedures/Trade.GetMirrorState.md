# Trade.GetMirrorState

> Returns the open/closed state and pending-closure flag for a specific mirror, with an Active-to-History fallback and CID ownership validation. The PendingForClosure flag is an inverted form of IsActive.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @MirrorID - identifies mirror with ownership validation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorState` determines the current state of a mirror: whether it is open (active in `Trade.Mirror`) or closed (moved to `History.Mirror`), and whether it is pending closure. The procedure enforces ownership - it only returns a result if the `@CID` matches the mirror's owner CID, preventing a customer from querying another customer's mirror state.

The procedure falls back to `History.Mirror` when the mirror is not found in `Trade.Mirror` (NULL result), searching for the last close operation (`MirrorOperationID = 2`). The `PendingForClosure` value is an inverted form of `IsActive`: when IsActive=1 (mirror live), PendingForClosure=0; when IsActive=0 (mirror closing/closed), PendingForClosure=1.

Data flows: Called by the SSE service or mirror management to check whether a mirror is currently open or has been closed, and whether a closure is in progress.

---

## 2. Business Logic

### 2.1 IsActive Inversion to PendingForClosure

**What**: The PendingForClosure output is the logical inverse of Trade.Mirror.IsActive.

**Columns/Parameters Involved**: `IsActive`, `PendingForClosure`

**Rules**:
- `CASE IsActive WHEN 1 THEN 0 ELSE 1 END AS PendingForClosure`
- IsActive=1 (mirror live, actively copying) -> PendingForClosure=0 (not pending closure)
- IsActive=0 (mirror inactive/being closed) -> PendingForClosure=1 (pending or in closure)
- This inversion means PendingForClosure signals "is this mirror in a non-active state?"

### 2.2 Active-to-History Fallback with Ownership Guard

**What**: Looks in Trade.Mirror first, falls back to History.Mirror, and only returns state if the CID matches.

**Columns/Parameters Involved**: `@CID`, `@MirrorID`, `IsOpen`, `MirrorOperationID`

**Rules**:
- If MirrorID found in Trade.Mirror: IsOpen=1, PendingForClosure from IsActive inversion.
- If not found (IsActive IS NULL): look in History.Mirror WHERE MirrorID = @MirrorID AND MirrorOperationID = 2. IsOpen=0 for historical mirrors.
- MirrorOperationID = 2 in History.Mirror: identifies the close/unregister operation record.
- Ownership validation: `WHERE @CID = @CID_V` - the SELECT only returns a row if the CID on the mirror matches the requesting @CID. If they differ, no row is returned.
- If mirror not found in either table, result is empty.

**Diagram**:
```
@MirrorID
    |
    v
Trade.Mirror found? -> YES: IsOpen=1, PendingForClosure = NOT(IsActive)
                              verify @CID = mirror.CID
    NO (NULL)
    |
    v
History.Mirror found (MirrorOperationID=2)?
    YES: IsOpen=0, PendingForClosure = NOT(IsActive)
         verify @CID = mirror.CID
    NO: empty result
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The customer ID requesting the mirror state. Used for ownership validation - result is only returned if this CID matches the mirror's owner CID. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier to look up. Checked in Trade.Mirror first, then History.Mirror as fallback. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | IsOpen | 1 = mirror is open/active (found in Trade.Mirror); 0 = mirror is closed (found in History.Mirror only). Returns nothing if mirror not found or CID mismatch. |
| 2 | PendingForClosure | Inverse of Trade.Mirror.IsActive: 0 = mirror is live (IsActive=1); 1 = mirror is inactive/pending closure (IsActive=0). Note: this is NOT a direct column from Trade.Mirror - it is a derived flag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Primary lookup | Checks for active mirror; derives state from IsActive. |
| @MirrorID | History.Mirror | Fallback lookup | Used when mirror not in Trade.Mirror; queries MirrorOperationID=2 rows. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorState (procedure)
├── Trade.Mirror (table)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Primary lookup for mirror IsActive/CID state |
| History.Mirror | Table (cross-schema) | Fallback lookup WHERE MirrorOperationID = 2 |

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

### 8.1 Get mirror state

```sql
EXEC Trade.GetMirrorState @CID = 123456, @MirrorID = 789;
```

### 8.2 Verify mirror state directly (bypasses ownership guard)

```sql
SELECT
    m.MirrorID,
    m.CID,
    m.IsActive,
    1 AS IsOpen,
    CASE m.IsActive WHEN 1 THEN 0 ELSE 1 END AS PendingForClosure
FROM Trade.Mirror m WITH (NOLOCK)
WHERE m.MirrorID = 789;
```

### 8.3 Check history for closed mirror state

```sql
SELECT
    hm.MirrorID,
    hm.CID,
    hm.IsActive,
    0 AS IsOpen,
    CASE hm.IsActive WHEN 1 THEN 0 ELSE 1 END AS PendingForClosure
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.MirrorID = 789
  AND hm.MirrorOperationID = 2;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorState | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorState.sql*
