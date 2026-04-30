# Trade.GetTreeNodesByParentCIDDebug

> Debug outer wrapper for the copy-trading hierarchy traversal, equivalent to Trade.GetTreeNodesByParentCID but delegates to GetTreeNodesByParentCID_InnerDebug (the debug inner proc) instead of the production _Inner.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID - root of copy hierarchy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentCIDDebug` is the debug counterpart to `Trade.GetTreeNodesByParentCID`. It is a thin wrapper that applies the same `@OperationDateTime` defaulting logic (NULL -> GETUTCDATE()) and then delegates to `Trade.GetTreeNodesByParentCID_InnerDebug` - a separate debug inner procedure (distinct from `_InnerDebugJunk`).

This procedure exists so developers can test changes to the hierarchy traversal algorithm using the debug inner proc without touching the production `GetTreeNodesByParentCID`. It maintains the same parameter-sniffing protection pattern as the production wrapper. Note that this calls `GetTreeNodesByParentCID_InnerDebug` (not `_InnerDebugJunk`), suggesting there are two separate debug inner procs in the system.

It does NOT have the `@EnableEtorianHedging` or `@MasterAccountCID` parameters present in the production version, making it unsuitable for hedge-aware scenarios.

---

## 2. Business Logic

### 2.1 Parameter Sniffing Wrapper Pattern

**What**: Same delegation pattern as production - wraps an inner proc to avoid parameter sniffing.

**Rules**:
- `@OperationDateTime` defaults to `GETUTCDATE()` when NULL, same as production wrapper
- Delegates to `Trade.GetTreeNodesByParentCID_InnerDebug` (not `_Inner` or `_InnerDebugJunk`)
- No hedging parameters - this version cannot compute IsComputedForHedge with full hedging logic

**Diagram**:
```
Caller (debug)
  |
  v
GetTreeNodesByParentCIDDebug (wrapper)
  - Sets @OperationDateTime = ISNULL(@OperationDateTime, GETUTCDATE())
  |
  v
GetTreeNodesByParentCID_InnerDebug (debug inner proc - separate from InnerDebugJunk)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | CID of the root trader whose copy network is traversed. Same semantics as production wrapper. |
| 2 | @OperationDateTime | DATETIME | YES | NULL -> GETUTCDATE() | CODE-BACKED | Point-in-time cutoff for mirror membership. Defaults to current UTC time when NULL. |
| 3 | @GetFirstHierarchyOnly | INT | NO | 0 | CODE-BACKED | 0 = full multi-level traversal; 1 = direct copiers only. Behavior depends on InnerDebug implementation. |

Note: `@EnableEtorianHedging` and `@MasterAccountCID` are NOT present in this debug version.

**Output columns**: Determined by `Trade.GetTreeNodesByParentCID_InnerDebug` (file not in this batch - expected to be similar to production minus hedging parameters).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (delegates to) | Trade.GetTreeNodesByParentCID_InnerDebug | EXEC | All logic in the debug inner proc |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (debug/manual use) | - | - | Not referenced by production code - manual debug/testing use only |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentCIDDebug (procedure)
└── Trade.GetTreeNodesByParentCID_InnerDebug (procedure)
      └── (same dependencies as _Inner: Trade.Mirror, Customer.Customer, BackOffice.Customer, etc.)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCID_InnerDebug | Stored Procedure | EXEC - all logic delegated here |

### 6.2 Objects That Depend On This

No dependents found. This is a debug procedure.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Debug hierarchy traversal
```sql
EXEC Trade.GetTreeNodesByParentCIDDebug
    @ParentCID = 123456,
    @OperationDateTime = NULL,
    @GetFirstHierarchyOnly = 0
```

### 8.2 Compare to production output
```sql
-- Production version
EXEC Trade.GetTreeNodesByParentCID
    @ParentCID = 123456, @GetFirstHierarchyOnly = 0

-- Debug version (no hedging params)
EXEC Trade.GetTreeNodesByParentCIDDebug
    @ParentCID = 123456, @GetFirstHierarchyOnly = 0
```

### 8.3 N/A - third query not applicable for debug wrapper
```sql
-- Check for any references to this debug SP
SELECT OBJECT_NAME(id) FROM syscomments WITH (NOLOCK)
WHERE text LIKE '%GetTreeNodesByParentCIDDebug%'
  AND OBJECT_NAME(id) NOT LIKE '%Debug%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Debug procedure not covered in official documentation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 7/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentCIDDebug | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentCIDDebug.sql*
