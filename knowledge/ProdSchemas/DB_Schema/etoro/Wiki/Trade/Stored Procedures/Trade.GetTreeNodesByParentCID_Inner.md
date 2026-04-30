# Trade.GetTreeNodesByParentCID_Inner

> Core inner procedure that recursively traverses the copy-trading mirror hierarchy to return all customers copying a given parent trader, including their regulation, account type, equity, and hedging eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID - root of the copy hierarchy being traversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentCID_Inner` is the engine behind eToro's copy-trading hierarchy traversal. Given a parent trader's CID, it returns every customer in their copy network - who copies them, who copies those copiers, and so on - along with the data each downstream consumer needs: customer identity, regulation, account type, mirror investment amount, realized equity, and whether the node should be included in the internal eToro hedging calculation.

This procedure exists because eToro's CopyTrader feature creates multi-level relationships: a customer can copy a Popular Investor who themselves copies another Popular Investor. When a trade fires at the root, the engine needs the full tree to determine which child accounts must replicate the position and at what proportions. Without this traversal, cascading copy trades cannot be coordinated.

Data flows as follows: a trading event triggers the outer wrapper (`Trade.GetTreeNodesByParentCID`) which immediately calls this inner proc `WITH RECOMPILE`. The inner proc uses a recursive Common Table Expression (CTE) named `MirrorHiararchy` to walk the `Trade.Mirror` table, starting with all active, non-paused mirrors where `ParentCID = @ParentCID`. The anchor member captures level-1 copiers; the recursive member adds deeper levels when `@GetFirstHierarchyOnly = 0` and `@IsRealDB = 1` (multi-level copy is only active in production). Finally, the procedure UNIONs in a row for the root trader themselves (sourced from `Trade.SynRealCustomers`) so the caller receives the complete tree including the head. If no rows are returned but active mirrors exist, an error is logged to `History.LogErrorGeneral`.

---

## 2. Business Logic

### 2.1 Recursive Mirror Hierarchy Traversal

**What**: A recursive CTE that walks the `Trade.Mirror` table to build the multi-level copy hierarchy.

**Columns/Parameters Involved**: `@ParentCID`, `@GetFirstHierarchyOnly`, `@OperationDateTime`, `@IsRealDB`

**Rules**:
- **Anchor**: SELECT all mirrors where `ParentCID = @ParentCID`, `IsActive = 1`, `Occurred <= @OperationDateTime`, `PauseCopy = 0` - these are level-1 direct copiers
- **Recursive member**: JOIN back on `MH.CID = TM.ParentCID` to find copiers of copiers - only runs when `@GetFirstHierarchyOnly = 0` AND `@IsRealDB = 1`
- **IsRealDB gate**: Multi-level traversal is disabled in demo/test environments (FeatureID=22 = 0) - demo only shows direct copiers
- **PauseCopy filter**: Paused copy relationships are excluded at all levels - paused copiers are invisible to position cascading

**Diagram**:
```
@ParentCID (root trader)
  |--- Mirror(CID=A, Level=1, PauseCopy=0, IsActive=1)
  |      |--- Mirror(CID=B, Level=2, PauseCopy=0) [only when IsRealDB=1 AND GetFirstHierarchyOnly=0]
  |            |--- Mirror(CID=C, Level=3) ...
  |--- Mirror(CID=D, Level=1)
  |--- [root row: @ParentCID itself, Level=0, from SynRealCustomers]
```

### 2.2 IsComputedForHedge Logic

**What**: Determines whether a hierarchy node participates in eToro's internal hedge desk exposure calculations.

**Columns/Parameters Involved**: `@EnableEtorianHedging`, `@MasterAccountCID`, `CC.PlayerLevelID`, `CC.CountryID`, `CC.PlayerStatusID`, `BC.AccountTypeID`

**Rules**:
- A node is a **hedge-excluded Etorian** (IsComputedForHedge = 0) if ALL of:
  - `@EnableEtorianHedging = 1` (flag enabled by caller)
  - `CC.PlayerLevelID = 4` (Etorian internal account)
  - `CountryID IN (250, 219)` (specific jurisdictions)
  - `PlayerStatusID = 10` (specific account status)
  - `AccountTypeID IN (7, 13)` (specific account types used by hedge desk)
  - `MasterAccountCID = @MasterAccountCID` (must be under the correct master)
- If ANY condition fails, `IsComputedForHedge = 1` (included in hedge calculation)
- For non-Etorian accounts (`PlayerLevelID != 4`), `IsComputedForHedge` is always 1
- The root node row (UNION branch) uses simplified logic: `IIF(CC.PlayerLevelID = 4, 0, 1)` - Etorian roots are always excluded

### 2.3 IsFundCopy Flag

**What**: Distinguishes Fund Copy mirrors from regular CopyTrader mirrors within the hierarchy.

**Columns/Parameters Involved**: `TM.MirrorTypeID`

**Rules**:
- `IsFundCopy = 1` when `MirrorTypeID = 4` (Fund Copy)
- `IsFundCopy = 0` for all other mirror types (regular CopyTrader, etc.)
- This is used downstream to apply different position-opening logic for fund copies vs. regular copies

### 2.4 Error Logging for Empty Hierarchy

**What**: If the CTE returns 0 rows but active mirrors exist, the procedure logs an anomaly.

**Rules**:
- After SELECT, checks `@@ROWCOUNT = 0`
- If zero but `Trade.Mirror WHERE ParentCID = @ParentCID AND IsActive = 1 AND PauseCopy = 0` has rows, it means the parent has copiers but the join to `Customer.Customer`/`BackOffice.Customer` failed to match (orphaned mirrors)
- Inserts a record into `History.LogErrorGeneral` with SP name `'Trade.GetTreeLeavesByParentCID'` (note: legacy name in the log message), the CID, datetime, and GetFirstHierarchyOnly value as XML

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | CID of the root trader whose copy network is traversed. The CTE anchor filters `Trade.Mirror.ParentCID = @ParentCID`. |
| 2 | @OperationDateTime | DATETIME | NO | - | CODE-BACKED | Point-in-time cutoff. Only mirrors with `Occurred <= @OperationDateTime` are included, enabling historical reconstruction of the copy tree at the moment a position event occurred. |
| 3 | @GetFirstHierarchyOnly | INT | NO | - | CODE-BACKED | 0 = full recursive traversal (all levels); 1 = anchor-only (direct copiers of @ParentCID, no recursion). Recursion is additionally gated on `@IsRealDB = 1`. |
| 4 | @EnableEtorianHedging | BIT | NO | 0 (default in inner) | CODE-BACKED | Controls whether the full 5-condition hedging logic applies to `IsComputedForHedge`. Default is 0 in this inner proc (caller passes 1 from the outer wrapper). |
| 5 | @MasterAccountCID | INT | NO | 10717251 | CODE-BACKED | CID of the eToro master hedge account. Part of the IsComputedForHedge exclusion condition - only applies when MasterAccountCID matches. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | MirrorID | INT | YES | - | CODE-BACKED | Mirror relationship ID. NULL for the root node row (UNION branch for @ParentCID themselves). FK to Trade.Mirror. |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer ID of this node in the hierarchy. |
| 8 | CountryID | INT | NO | - | CODE-BACKED | Customer's country of residence from Customer.Customer. FK to Dictionary.Country. |
| 9 | RegulationID | INT | YES | - | CODE-BACKED | Effective regulation: `ISNULL(BC.DesignatedRegulationID, BC.RegulationID)`. DesignatedRegulationID takes precedence when set (regulatory override). NULL for root node. |
| 10 | AccountTypeID | INT | YES | - | CODE-BACKED | Account type from BackOffice.Customer. Used in IsComputedForHedge: types 7 and 13 are hedge desk account types. NULL for root node. |
| 11 | ParentCID | INT | NO | - | CODE-BACKED | Direct parent CID in copy hierarchy. 0 for the root node row. |
| 12 | Level | INT | NO | - | CODE-BACKED | Depth in hierarchy. 1 = direct copier, 2+ = deeper levels. 0 for root node. |
| 13 | MirrorAmount | DECIMAL | YES | - | CODE-BACKED | Amount invested in this mirror relationship (Trade.Mirror.Amount). NULL for root node. |
| 14 | MirrorRealizedEquity | MONEY | YES | - | CODE-BACKED | Realized equity accumulated by this copier in this mirror (Trade.Mirror.RealizedEquity). NULL for root node. |
| 15 | UserRealizedEquity | MONEY | NO | - | CODE-BACKED | Customer's total realized equity across all accounts (Customer.Customer.RealizedEquity). |
| 16 | MirrorCalculationType | INT | YES | - | CODE-BACKED | Copy calculation method for this mirror. Controls how the copier's position size is derived from the parent's trade. NULL for root node. |
| 17 | IsComputedForHedge | BIT | NO | - | CODE-BACKED | 1 = include in eToro hedge exposure calculation; 0 = exclude (eToro internal hedging account meeting all 5 exclusion criteria). |
| 18 | PlayerStatusID | INT | NO | - | CODE-BACKED | Current player account status from Customer.Customer. FK to Dictionary.PlayerStatus. PlayerStatusID=10 is one of the hedging exclusion conditions. |
| 19 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1 = Fund Copy mirror (MirrorTypeID=4); 0 = regular CopyTrader mirror. Drives different copy-open logic downstream. |
| 20 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration date from Customer.Customer. Used downstream for age-based eligibility checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE anchor/recursive | Trade.Mirror | JOIN/FROM | Source of copy relationships - all active, non-paused mirrors where ParentCID matches |
| JOIN | Customer.Customer | JOIN | Provides CountryID, PlayerLevelID, PlayerStatusID, RealizedEquity, Registered for each node |
| JOIN | BackOffice.Customer | JOIN | Provides DesignatedRegulationID, RegulationID, AccountTypeID for each node |
| UNION root row | Trade.SynRealCustomers | FROM | Synonym that provides the root trader's own row (CID = @ParentCID) |
| FeatureID=22 | Maintenance.Feature | SELECT | IsRealDB flag - controls whether multi-level recursion runs |
| Error log | History.LogErrorGeneral | INSERT | Receives anomaly records when hierarchy returns 0 rows but mirrors exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTreeNodesByParentCID | EXEC | Caller | Outer wrapper that delegates all logic here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentCID_Inner (procedure)
├── Trade.Mirror (table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── Trade.SynRealCustomers (synonym -> points to real customer view)
├── Maintenance.Feature (table)
└── History.LogErrorGeneral (table) [error logging only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | CTE anchor and recursive member - source of all copy relationships |
| Customer.Customer | Table | JOINed to get country, player level, status, equity, registered date |
| BackOffice.Customer | Table | JOINed to get regulation, designated regulation, account type |
| Trade.SynRealCustomers | Synonym | UNION branch provides the root node's own row |
| Maintenance.Feature | Table | FeatureID=22 read to get IsRealDB flag for recursion gate |
| History.LogErrorGeneral | Table | INSERT target for anomaly logging when hierarchy returns empty |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCID | Stored Procedure | EXEC caller - outer wrapper |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Execution hint | Forces fresh query plan on every execution to avoid parameter sniffing issues with @OperationDateTime and recursive CTE date filters |

---

## 8. Sample Queries

### 8.1 Called by outer wrapper - full tree traversal
```sql
EXEC Trade.GetTreeNodesByParentCID_Inner
    @ParentCID = 123456,
    @OperationDateTime = '2025-06-01 09:30:00',
    @GetFirstHierarchyOnly = 0,
    @EnableEtorianHedging = 1,
    @MasterAccountCID = 10717251
```

### 8.2 First-level copiers only (fast lookup)
```sql
EXEC Trade.GetTreeNodesByParentCID_Inner
    @ParentCID = 123456,
    @OperationDateTime = GETUTCDATE(),
    @GetFirstHierarchyOnly = 1,
    @EnableEtorianHedging = 0,
    @MasterAccountCID = 10717251
```

### 8.3 Inspect active mirror structure for a trader (reference query)
```sql
-- Understand the copy tree structure before calling the SP
SELECT  TM.MirrorID, TM.CID, TM.ParentCID, TM.MirrorTypeID, TM.IsActive, TM.PauseCopy,
        TM.Occurred, TM.Amount, TM.MirrorCalculationType
FROM    Trade.Mirror TM WITH (NOLOCK)
WHERE   TM.ParentCID = 123456
        AND TM.IsActive = 1
        AND TM.PauseCopy = 0
ORDER BY TM.Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Not listed in the configured TRAD/DB Confluence folder (which covers execution-critical objects). No TRAD space search results for this procedure name.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentCID_Inner | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentCID_Inner.sql*
