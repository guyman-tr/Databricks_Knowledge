# Trade.SpreadGroupAdd

> Creates a new spread group with a system-generated SpreadGroupID (via Internal.GetSpreadGroupID) and a display name, returning the new ID as an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SpreadGroupID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Spread groups are named collections of spreads that can be assigned to customers or instruments. This procedure creates a new spread group definition in `Trade.SpreadGroup`, obtaining a system-allocated ID from `Internal.GetSpreadGroupID`. The caller receives the new SpreadGroupID back through the OUTPUT parameter and can then link spreads to it via `Trade.SpreadToGroupLink`.

The centralized ID allocation via `Internal.GetSpreadGroupID` ensures SpreadGroupIDs are unique and avoids identity column conflicts. The transaction wraps both the ID allocation and the INSERT atomically.

---

## 2. Business Logic

### 2.1 Centralized ID Allocation

**What**: SpreadGroupID is not an IDENTITY column; it is allocated by calling `Internal.GetSpreadGroupID`.

**Columns/Parameters Involved**: `@SpreadGroupID OUTPUT`, `Internal.GetSpreadGroupID`

**Rules**:
- EXECUTE @Answer = Internal.GetSpreadGroupID @SpreadGroupID OUTPUT
- If @Answer != 0 -> ROLLBACK and RETURN @Answer (allocation failed)
- The allocated SpreadGroupID is inserted and also returned via OUTPUT

### 2.2 Error Handling

**What**: Both the ID allocation and INSERT are checked for errors.

**Rules**:
- ID allocation failure (@Answer != 0): ROLLBACK, RETURN @Answer
- INSERT failure (@@ERROR != 0): ROLLBACK, RAISERROR(60000, 16, 1, 'Trade.SpreadGroupAdd', @LocalError), RETURN 60000
- On success: COMMIT, RETURN 0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SpreadGroupID | INTEGER OUTPUT | NO | - | CODE-BACKED | OUTPUT: the newly allocated SpreadGroupID from Internal.GetSpreadGroupID. Caller uses this to subsequently link spreads via Trade.SpreadToGroupLink. |
| 2 | @Name | VARCHAR(50) | NO | - | CODE-BACKED | Display name for the spread group. Stored in Trade.SpreadGroup.Name. Should be descriptive (e.g., 'Standard', 'VIP', 'Default'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SpreadGroupID | Internal.GetSpreadGroupID | Executor | Allocates next SpreadGroupID via OUTPUT parameter |
| SpreadGroupID, Name | Trade.SpreadGroup | Writer | Inserts new spread group record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SpreadGroupAdd (procedure)
+-- Internal.GetSpreadGroupID (procedure) [allocate SpreadGroupID]
+-- Trade.SpreadGroup (table) [insert new group record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetSpreadGroupID | Stored Procedure | Allocates next SpreadGroupID, returns via OUTPUT parameter |
| Trade.SpreadGroup | Table | Target for INSERT of new spread group |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Called by admin/configuration tooling; followed by Trade.SpreadToGroupLink |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error code 60000 | Convention | Standard error code for procedure-level failures in the Trade schema |

---

## 8. Sample Queries

### 8.1 Add a new spread group

```sql
DECLARE @NewGroupID INT;
EXEC Trade.SpreadGroupAdd
    @SpreadGroupID = @NewGroupID OUTPUT,
    @Name = 'VIP Spreads';
SELECT @NewGroupID AS NewSpreadGroupID;
```

### 8.2 View all spread groups

```sql
SELECT SpreadGroupID, Name
FROM Trade.SpreadGroup WITH (NOLOCK)
ORDER BY SpreadGroupID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SpreadGroupAdd | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SpreadGroupAdd.sql*
