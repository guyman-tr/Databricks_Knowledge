# Trade.GetTreeNodesByParentCID_InnerDebugJunk

> Obsolete debug variant of the copy-trading hierarchy traversal inner procedure, retained as reference/junk code - differs from the production version in using Customer.Customer for the root node, omitting AccountTypeID/Registered output columns, and adding MAXDOP 1 hint.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID - root of copy hierarchy |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentCID_InnerDebugJunk` is a deprecated debug copy of `Trade.GetTreeNodesByParentCID_Inner`. The "DebugJunk" suffix in the name explicitly marks it as non-production code retained for historical reference or occasional manual debugging. It implements the same recursive CTE over `Trade.Mirror` as the production inner proc but with several differences that make it unsuitable for live use.

This procedure exists as an artifact of incremental development: the production inner proc was updated over time (adding AccountTypeID, Registered, the SynRealCustomers synonym for the root row, and the EnableEtorianHedging parameter), while this version retains the older logic. It may be used by developers for side-by-side comparison or ad-hoc debugging but is not called by any production wrapper.

The procedure uses the same recursive CTE pattern and IsRealDB gate (`Maintenance.Feature FeatureID=22`) and performs the same anomaly-logging to `History.LogErrorGeneral` on empty results.

---

## 2. Business Logic

### 2.1 Differences from Production Inner Proc

**What**: Key behavioral and structural differences from `Trade.GetTreeNodesByParentCID_Inner`.

**Rules**:
- **Root row source**: Uses `Customer.Customer` (base table) instead of `Trade.SynRealCustomers` (production synonym). This means in environments where SynRealCustomers points to a different database, this version always reads from the local Customer.Customer.
- **Missing output columns**: Does NOT return `AccountTypeID` or `Registered` (present in production version). Consumers expecting these columns will get different result-set shapes.
- **No @EnableEtorianHedging / @MasterAccountCID parameters**: IsComputedForHedge is computed with simplified logic: `IIF(CC.PlayerLevelID = 4, 0, 1)` for all rows (no 5-condition hedging check).
- **MAXDOP 1 hint**: The anchor UNION SELECT uses `option(maxdop 1)` to force single-threaded execution - intended to make query plans deterministic for debugging.
- **IsFundCopy in root row**: Returns NULL for IsFundCopy on the root node (production returns NULL too, consistent).
- Same recursive CTE, same IsRealDB gate, same error logging.

### 2.2 Recursive CTE (same as production)

**What**: Same recursive mirror traversal as GetTreeNodesByParentCID_Inner.

**Rules**: Same anchor/recursive structure; see `Trade.GetTreeNodesByParentCID_Inner` Section 2.1 for full details.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | CID of the root trader. Same semantics as production inner proc. |
| 2 | @OperationDateTime | DATETIME | NO | - | CODE-BACKED | Point-in-time cutoff for mirror inclusion. No default in this version (caller must supply). |
| 3 | @GetFirstHierarchyOnly | INT | NO | - | CODE-BACKED | 0 = full recursion; 1 = direct copiers only. Same gating on IsRealDB=1 for recursion. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | MirrorID | INT | YES | - | CODE-BACKED | Mirror relationship ID. NULL for root node. |
| 5 | CID | INT | NO | - | CODE-BACKED | Customer ID of this hierarchy node. |
| 6 | CountryID | INT | NO | - | CODE-BACKED | Customer's country from Customer.Customer. |
| 7 | RegulationID | INT | YES | - | CODE-BACKED | Effective regulation: ISNULL(DesignatedRegulationID, RegulationID). NULL for root node. |
| 8 | ParentCID | INT | NO | - | CODE-BACKED | Direct parent CID. 0 for root node. |
| 9 | Level | INT | NO | - | CODE-BACKED | Hierarchy depth. 0 for root, 1+ for copiers. |
| 10 | MirrorAmount | DECIMAL | YES | - | CODE-BACKED | Mirror investment amount. NULL for root. |
| 11 | MirrorRealizedEquity | MONEY | YES | - | CODE-BACKED | Mirror realized equity. NULL for root. |
| 12 | UserRealizedEquity | MONEY | NO | - | CODE-BACKED | Customer total realized equity. |
| 13 | MirrorCalculationType | INT | YES | - | CODE-BACKED | Copy calculation method. NULL for root. |
| 14 | IsComputedForHedge | BIT | NO | - | CODE-BACKED | Simplified: IIF(PlayerLevelID=4, 0, 1). No 5-condition hedging check as in production. |
| 15 | PlayerStatusID | INT | NO | - | CODE-BACKED | Current player status from Customer.Customer. |
| 16 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1 = Fund Copy (MirrorTypeID=4); 0 = regular copy. |

Note: **AccountTypeID** and **Registered** are NOT returned by this version (difference from production).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE | Trade.Mirror | FROM/JOIN | Source of mirror relationships |
| JOIN | Customer.Customer | JOIN | Customer profile data (root node uses Customer.Customer, not SynRealCustomers) |
| JOIN | BackOffice.Customer | JOIN | Regulation and account type data |
| FeatureID=22 | Maintenance.Feature | SELECT | IsRealDB flag |
| Error log | History.LogErrorGeneral | INSERT | Anomaly logging for empty result |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTreeNodesByParentCIDDebug | EXEC | Caller | Debug wrapper that calls this proc instead of the production _Inner |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentCID_InnerDebugJunk (procedure)
├── Trade.Mirror (table)
├── Customer.Customer (table) [root node uses this, NOT SynRealCustomers]
├── BackOffice.Customer (table)
├── Maintenance.Feature (table)
└── History.LogErrorGeneral (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Recursive CTE source |
| Customer.Customer | Table | JOINed for node data AND root row (not SynRealCustomers) |
| BackOffice.Customer | Table | JOINed for regulation/account type |
| Maintenance.Feature | Table | IsRealDB flag lookup |
| History.LogErrorGeneral | Table | Error logging INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCIDDebug | Stored Procedure | EXEC caller - debug wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Execution hint | Forces fresh plan each execution |
| OPTION(MAXDOP 1) | Query hint | Forces single-threaded execution on the anchor UNION branch for deterministic debug plans |

---

## 8. Sample Queries

### 8.1 Debug call (mirroring production wrapper behavior)
```sql
EXEC Trade.GetTreeNodesByParentCID_InnerDebugJunk
    @ParentCID = 123456,
    @OperationDateTime = GETUTCDATE(),
    @GetFirstHierarchyOnly = 0
```

### 8.2 Compare output to production version
```sql
-- Side by side: production output vs debug version
EXEC Trade.GetTreeNodesByParentCID_Inner
    @ParentCID = 123456, @OperationDateTime = GETUTCDATE(),
    @GetFirstHierarchyOnly = 0, @EnableEtorianHedging = 0, @MasterAccountCID = 10717251

-- Note: InnerDebugJunk returns fewer columns (no AccountTypeID, no Registered)
EXEC Trade.GetTreeNodesByParentCID_InnerDebugJunk
    @ParentCID = 123456, @OperationDateTime = GETUTCDATE(), @GetFirstHierarchyOnly = 0
```

### 8.3 Check if any non-production callers reference this SP
```sql
-- Find all references to InnerDebugJunk in the SP folder
SELECT OBJECT_NAME(id) FROM syscomments WITH (NOLOCK)
WHERE text LIKE '%InnerDebugJunk%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. This is a non-production debug procedure not covered in official documentation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentCID_InnerDebugJunk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentCID_InnerDebugJunk.sql*
