# Trade.IsCopying

> Returns a single row (SELECT 1 AS IsCopying) if an active mirror relationship exists where @CID is copying @ParentCID in Trade.Mirror; returns no rows if not copying.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ParentCID - the copier and leader to check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsCopying checks whether a specific customer (@CID) is currently copying a specific leader (@ParentCID) in eToro's CopyTrader feature. A "mirror" in Trade.Mirror represents a copy relationship: the copier (CID) allocates funds to follow all trades made by the leader (ParentCID). This procedure answers a directional question: is this specific copier-to-leader relationship active?

The procedure returns a result set with one row (value 1) if the relationship exists, or an empty result set if it does not. Callers check @@ROWCOUNT or the presence of a result to determine the answer. This is used to validate copy relationships, prevent duplicate registrations, or check state before performing copy-related operations.

Note: The query uses NOLOCK hint and does NOT filter on Trade.Mirror.IsActive - it will return results for both active and closed mirror relationships as long as the row exists in the table. This means it detects "ever copied" rather than "currently actively copying" if closed mirrors are retained.

Data flow: Mirror rows are created by Trade.RegisterMirror and closed/deleted by Trade.ChangeMirrorState / Trade.UnRegisterMirrorForMoe. This procedure is a read-only predicate against that table.

---

## 2. Business Logic

### 2.1 Mirror Relationship Check

**What**: SELECT 1 from Trade.Mirror WHERE CID = @CID AND ParentCID = @ParentCID.

**Columns/Parameters Involved**: `@CID`, `@ParentCID`, `Trade.Mirror.CID`, `Trade.Mirror.ParentCID`

**Rules**:
- Returns one row with value 1 if ANY mirror row exists for the (CID, ParentCID) pair.
- Returns no rows (empty result set) if no such relationship exists.
- Uses NOLOCK (WITH (NOLOCK)) hint - may read uncommitted data.
- Does NOT filter on IsActive - includes closed mirrors if they remain in the table.
- The result set column is named `IsCopying`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | The copier's customer ID. In Trade.Mirror, CID is the follower who allocates funds to copy a leader. |
| 2 | @ParentCID | int | NO | - | CODE-BACKED | The leader's customer ID. In Trade.Mirror, ParentCID is the popular investor being copied. |
| RS.1 | IsCopying | int | NO | - | CODE-BACKED | Output. Literal value 1 if @CID is copying @ParentCID. Empty result set (no rows) if not copying. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.Mirror | Reader | Checks for a mirror relationship between @CID (copier) and @ParentCID (leader) |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by copy trading services to validate or check copier-leader relationships.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsCopying (procedure)
└── Trade.Mirror (table) - mirror relationship lookup
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Checks for row with matching (CID, ParentCID) pair |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Copy trading service | External (Application) | Checks whether a copy relationship exists before registering or managing a mirror |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK hint | Concurrency | Reads uncommitted data; low latency but may return stale mirror state during writes |
| No IsActive filter | Design | Returns matches regardless of mirror IsActive state; detects relationship existence, not necessarily active copying |
| Empty result = false | API convention | Callers check @@ROWCOUNT > 0 or consume the result set to determine the boolean answer |

---

## 8. Sample Queries

### 8.1 Check if CID 1001 is copying CID 2002

```sql
EXEC Trade.IsCopying @CID = 1001, @ParentCID = 2002;
-- Returns row with IsCopying=1 if copying; empty result if not
```

### 8.2 View the mirror record directly

```sql
SELECT MirrorID, CID, ParentCID, IsActive, Amount, Occurred
FROM Trade.Mirror WITH (NOLOCK)
WHERE CID = 1001 AND ParentCID = 2002;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsCopying | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsCopying.sql*
