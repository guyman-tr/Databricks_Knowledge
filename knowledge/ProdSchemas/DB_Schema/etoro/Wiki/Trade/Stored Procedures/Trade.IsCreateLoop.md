# Trade.IsCreateLoop

> Detects whether establishing a copy relationship from @CID to @ParentCID would create a cycle in the CopyTrader social graph, using recursive CTEs to traverse ancestor and descendant chains in Trade.Mirror.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @ParentCID - proposed copier and leader |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.IsCreateLoop prevents circular copy trading relationships. In eToro's CopyTrader, if user A copies user B, and user B copies user C, and user C then tries to copy user A - this would create an infinite loop in trade propagation: a trade by A would propagate to B, which would re-propagate to C, which would re-propagate to A again endlessly.

Before registering a new mirror (copy relationship), the system calls this procedure to verify the proposed (CID -> ParentCID) link would not create a cycle. If RETURN = 1, the registration is blocked. The procedure handles three distinct loop scenarios:
1. Self-copying (CID = ParentCID)
2. Direct reverse (ParentCID already copies CID)
3. Indirect cycle: any ancestor of ParentCID is already a descendant of CID in the social graph

The recursive CTE approach walks the full copy-trading social graph in both directions to detect indirect cycles. This is a depth-first graph traversal implemented in T-SQL.

Data flow: Trade.RegisterMirror (or the application's copy registration endpoint) calls this procedure before inserting into Trade.Mirror. RETURN 0 = safe to proceed. RETURN 1 = would create a loop, registration should be rejected.

---

## 2. Business Logic

### 2.1 Null Guard

**What**: Rejects NULL inputs immediately with a RAISERROR.

**Rules**:
- IF @CID IS NULL OR @ParentCID IS NULL: RAISERROR('The parameters can not have NULL as a value', 16, 1).
- Execution continues (no RETURN) after RAISERROR in TRY block - control flows to subsequent checks, but the error state means caller receives error.

### 2.2 Self-Copy Detection

**What**: Direct check: CID = ParentCID would mean copying oneself.

**Rules**:
- IF @CID = @ParentCID AND @RetVal = 0: RETURN(1).
- Fast short-circuit before any table queries.

### 2.3 Direct Reverse Detection

**What**: Checks if the reverse mirror already exists (ParentCID is already a follower of CID).

**Rules**:
- IF EXISTS (SELECT * FROM Trade.Mirror WHERE ParentCID = @CID AND CID = @ParentCID): RETURN(1).
- Detects the immediate two-way loop: A copies B, B tries to copy A.

### 2.4 Indirect Cycle Detection (Recursive CTEs)

**What**: Walks the full social graph to find indirect cycles. Only runs if @CID already has followers (i.e., someone is copying CID).

**Columns/Parameters Involved**: `Trade.Mirror.CID`, `Trade.Mirror.ParentCID`, `@HasLoop`

**Rules**:
- Pre-condition: IF EXISTS (SELECT * FROM Trade.Mirror WHERE ParentCID = @CID). Only performs the expensive recursive traversal if @CID has followers (otherwise no cycle is possible from this direction).
- CTE 1 `GetPrarentsForParent`: Traverses UP the copy chain from @ParentCID.
  - Anchor: SELECT ParentCID FROM Trade.Mirror WHERE CID = @ParentCID (direct leaders of @ParentCID).
  - Recursive: JOIN Trade.Mirror ON TM.CID = GetPrarentsForParent.ParentCID WHERE TM.ParentCID IS NOT NULL (walk further up).
  - Result: all CIDs that @ParentCID (directly or transitively) copies.
- CTE 2 `GetCIDsFallowers`: Traverses DOWN the copy chain from @CID.
  - Anchor: SELECT CID FROM Trade.Mirror WHERE ParentCID = @CID (direct followers of @CID).
  - Recursive: JOIN Trade.Mirror ON TM.ParentCID = GetCIDsFallowers.CID (walk further down).
  - Result: all CIDs that (directly or transitively) copy @CID.
- Loop detection: SELECT COUNT(*) FROM GetPrarentsForParent P INNER JOIN GetCIDsFallowers F ON P.ParentCID = F.CID.
  - If any ancestor of @ParentCID is also a descendant of @CID -> @HasLoop > 0 -> cycle detected.
- IF @HasLoop > 0: SET @RetVal = 1.
- RETURN(@RetVal).

**Diagram**:
```
@CID, @ParentCID
    |
    v
NULL check -> RAISERROR if NULL
    |
    v
@CID = @ParentCID? -> RETURN(1) (self-copy)
    |
    v
EXISTS(Mirror WHERE ParentCID=@CID AND CID=@ParentCID)? -> RETURN(1) (direct reverse)
    |
    v
EXISTS(Mirror WHERE ParentCID=@CID)?  [CID has any followers?]
    |
    +--[NO]---> RETURN(0) (no followers, no cycle possible)
    |
    +--[YES]--> Recursive CTEs:
                  GetPrarentsForParent: walk UP from @ParentCID (all ancestors of proposed leader)
                  GetCIDsFallowers: walk DOWN from @CID (all descendants of proposed copier)
                  |
                  v
                COUNT intersection > 0 -> @HasLoop=1 -> @RetVal=1
                COUNT intersection = 0 -> @RetVal=0
                    |
                    v
                RETURN(@RetVal)
                0 = safe, 1 = loop
```

### 2.5 Error Handling

**What**: TRY/CATCH with custom RAISERROR on error.

**Rules**:
- BEGIN CATCH: builds custom error message with ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE(), ERROR_NUMBER().
- RAISERROR with the built message (16, 1).
- RETURN(1) in catch block - error path is treated as "loop detected" (fail safe: registration blocked on error).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | The proposed copier's customer ID. The customer who wants to start copying @ParentCID. |
| 2 | @ParentCID | int | NO | - | CODE-BACKED | The proposed leader's customer ID. The popular investor @CID wants to copy. |
| RETURN | int | NO | - | CODE-BACKED | RETURN value (not result set). 0 = no loop detected (safe to create mirror). 1 = loop detected (mirror creation would create a cycle). Also returns 1 on error (fail-safe). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXISTS check + Recursive CTEs | Trade.Mirror | Reader | Traverses the copy trading social graph to detect cycles |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by mirror registration logic (Trade.RegisterMirror or application layer) before inserting into Trade.Mirror.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.IsCreateLoop (procedure)
└── Trade.Mirror (table) - social graph traversal source
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | All three loop checks: self-copy, direct reverse, and recursive ancestor/descendant traversal |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Mirror registration service | External (Application) | Calls before creating a copy relationship to reject loop-creating registrations |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| TRY/CATCH + RAISERROR | Error handling | Custom error message with procedure/line context; RETURN(1) on error (fail-safe) |
| Recursive CTE depth | Performance | No MAXRECURSION hint - uses default (100 levels). Deep copy chains (>100 levels) would hit the recursion limit and throw an error, treated as loop (RETURN 1) |
| Pre-condition for recursion | Performance | Only runs expensive recursive CTEs if @CID already has followers; avoids full graph traversal for new leaders with no copy relationships |
| RETURN integer | API | Uses RETURN value (not OUTPUT param or result set) - callers must use EXEC @rc = Trade.IsCreateLoop pattern |
| Typo in code | Note | Variable @Msg is declared as INT (not VARCHAR) - this means the string concatenation in the CATCH block would fail with a type conversion error. The CATCH error message construction is broken; however, RAISERROR itself would still fire with a generic error. |

---

## 8. Sample Queries

### 8.1 Check if a new copy relationship would create a loop

```sql
DECLARE @RC INT;
EXEC @RC = Trade.IsCreateLoop @CID = 1001, @ParentCID = 2002;
SELECT @RC AS WouldCreateLoop;
-- 0 = safe to proceed, 1 = loop detected
```

### 8.2 View current direct followers of a CID (depth 1)

```sql
SELECT CID, ParentCID, IsActive
FROM Trade.Mirror WITH (NOLOCK)
WHERE ParentCID = 1001;
```

### 8.3 Manually trace the ancestor chain (what the recursive CTE does)

```sql
WITH AncestorChain AS (
    SELECT ParentCID FROM Trade.Mirror WITH (NOLOCK) WHERE CID = 2002
    UNION ALL
    SELECT TM.ParentCID
    FROM Trade.Mirror TM WITH (NOLOCK)
         INNER JOIN AncestorChain AC ON TM.CID = AC.ParentCID
    WHERE TM.ParentCID IS NOT NULL
)
SELECT DISTINCT ParentCID AS AncestorOfProposedLeader FROM AncestorChain;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.IsCreateLoop | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.IsCreateLoop.sql*
