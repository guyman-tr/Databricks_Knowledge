# Trade.GetTreeNodesByParentCID

> Outer wrapper for the copy-trading hierarchy traversal that returns all copier nodes beneath a given parent customer, delegating to an inner procedure to avoid parameter sniffing on the datetime argument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID - the root customer whose copy network is traversed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetTreeNodesByParentCID` retrieves the full graph of customers who are directly or indirectly copying a given trader (identified by `@ParentCID`) at a specific point in time. The result set represents every node in the copy-trading mirror hierarchy rooted at the parent: immediate copiers (level 1), copiers-of-copiers (level 2), and so on, depending on the `@GetFirstHierarchyOnly` flag.

This procedure exists because the copy-trading engine needs to identify all affected copiers when a parent trader opens or closes a position. Without it, the system cannot determine which child accounts need to mirror the trade. It is also used for hedging calculations (the eToro internal hedge desk needs the same tree data to compute exposure).

Data flows into this procedure from the trading engine: when a position open or close event fires, the calling service passes the parent CID and the event datetime. The wrapper defaults the datetime to UTC now and forwards all parameters to `Trade.GetTreeNodesByParentCID_Inner`, which performs the actual recursive CTE traversal over `Trade.Mirror`. The wrapper pattern exists specifically to prevent SQL Server from caching a bad execution plan for the `@OperationDateTime` parameter (a common performance issue with recursive CTEs and date filters).

---

## 2. Business Logic

### 2.1 Parameter Sniffing Wrapper Pattern

**What**: This procedure is a pure delegation wrapper to work around SQL Server parameter sniffing.

**Columns/Parameters Involved**: `@OperationDateTime`

**Rules**:
- `@OperationDateTime` defaults to `NULL` at the outer level; the wrapper converts it to `GETUTCDATE()` before passing it to the inner proc
- The inner proc is declared `WITH RECOMPILE` so each execution gets a fresh plan regardless of the sniffed value
- This two-layer design ensures stable performance when the datetime value varies widely across calls (e.g., current time vs. historical backfill)

**Diagram**:
```
Caller
  |
  v
GetTreeNodesByParentCID (wrapper)
  - Sets @OperationDateTime = ISNULL(@OperationDateTime, GETUTCDATE())
  |
  v
GetTreeNodesByParentCID_Inner (WITH RECOMPILE)
  - Recursive CTE over Trade.Mirror
  - Returns hierarchy nodes
```

### 2.2 Etorian Hedging Inclusion Flag

**What**: The `@EnableEtorianHedging` parameter controls whether eToro's internal hedge accounts (PlayerLevelID=4) are included in the computed nodes.

**Columns/Parameters Involved**: `@EnableEtorianHedging`, `@MasterAccountCID`

**Rules**:
- When `@EnableEtorianHedging = 1` (default), the inner proc evaluates whether each node is a hedging account and sets the `IsComputedForHedge` flag accordingly
- The `@MasterAccountCID` (default 10717251) identifies the master hedge account; only nodes under this specific master are subject to the hedging calculation
- When `@EnableEtorianHedging = 0`, the `IsComputedForHedge` flag is computed purely from `PlayerLevelID` (non-level-4 customers are always computed for hedge)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The customer ID of the trader being copied. The procedure returns all customers in the mirror hierarchy rooted at this CID. |
| 2 | @OperationDateTime | DATETIME | YES | NULL -> GETUTCDATE() | CODE-BACKED | Point-in-time filter for mirror membership. Only mirrors where `Occurred <= @OperationDateTime` and `IsActive = 1` are included. Defaults to the current UTC time when NULL. Used for historical hierarchy reconstruction (e.g., what did the copy tree look like at position open time). |
| 3 | @GetFirstHierarchyOnly | INT | NO | 0 | CODE-BACKED | Controls recursion depth: 0 = full multi-level traversal (copiers of copiers), 1 = first-level copiers only (direct mirrors of @ParentCID). Also gated on `@IsRealDB = 1` in the inner proc - multi-level traversal is disabled in demo environments. |
| 4 | @EnableEtorianHedging | BIT | NO | 1 | CODE-BACKED | When 1, the `IsComputedForHedge` output flag is calculated using the full hedging logic (PlayerLevelID, CountryID, PlayerStatusID, AccountTypeID, MasterAccountCID check). When 0, all non-Etorian nodes return `IsComputedForHedge = 1`. |
| 5 | @MasterAccountCID | INT | NO | 10717251 | CODE-BACKED | CID of the eToro master hedge account. Used in the `IsComputedForHedge` computation: only nodes whose hierarchy traces to this master CID are subject to hedging inclusion checks. Hardcoded default identifies the production hedge master account. |

**Output columns** (returned by inner proc, passed through):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | MirrorID | INT | YES | - | CODE-BACKED | Mirror relationship ID linking the copier to the parent. NULL for the root node (the @ParentCID themselves, returned via UNION from Trade.SynRealCustomers). FK to Trade.Mirror. |
| 7 | CID | INT | NO | - | CODE-BACKED | Customer ID of this hierarchy node. |
| 8 | CountryID | INT | NO | - | CODE-BACKED | Customer's country of residence. FK to Dictionary.Country. Used downstream for regulation enforcement. |
| 9 | RegulationID | INT | YES | - | CODE-BACKED | Effective regulation for this node: `ISNULL(DesignatedRegulationID, RegulationID)` from BackOffice.Customer. The DesignatedRegulation overrides the base regulation when set (used for regulatory override scenarios). |
| 10 | AccountTypeID | INT | YES | - | CODE-BACKED | Account type of this node. FK to Dictionary.AccountType. Used to identify fund accounts (AccountTypeID=7 or 13 in hedging logic). NULL for the root node row. |
| 11 | ParentCID | INT | NO | - | CODE-BACKED | CID of the node's direct parent in the copy hierarchy. 0 for the root node (@ParentCID themselves). |
| 12 | Level | INT | NO | - | CODE-BACKED | Depth in the copy hierarchy. 1 = direct copier of @ParentCID, 2 = copier of a copier, etc. 0 for the root node row. |
| 13 | MirrorAmount | DECIMAL | YES | - | CODE-BACKED | Amount the copier has invested in this mirror relationship (Trade.Mirror.Amount). NULL for the root node. |
| 14 | MirrorRealizedEquity | MONEY | YES | - | CODE-BACKED | Realized equity accumulated by the copier in this mirror (Trade.Mirror.RealizedEquity). NULL for root. |
| 15 | UserRealizedEquity | MONEY | NO | - | CODE-BACKED | The copier customer's total realized equity across all their accounts (Customer.Customer.RealizedEquity). |
| 16 | MirrorCalculationType | INT | YES | - | CODE-BACKED | Calculation method for this mirror: determines how copy amounts are computed when the parent trades. FK to Dictionary.MirrorCalculationType (implied). NULL for root. |
| 17 | IsComputedForHedge | BIT | NO | - | CODE-BACKED | 1 = this node should be included in eToro's internal hedge calculations; 0 = excluded (typically eToro's own internal Etorian accounts that are level-4 with specific country/status/type conditions). |
| 18 | PlayerStatusID | INT | NO | - | CODE-BACKED | Current player/account status. FK to Dictionary.PlayerStatus. Used to filter active copiers (PlayerStatusID=10 is part of hedging eligibility). |
| 19 | IsFundCopy | BIT | NO | - | CODE-BACKED | 1 = this mirror is a Fund Copy relationship (MirrorTypeID=4 in Trade.Mirror); 0 = regular CopyTrader relationship. |
| 20 | Registered | DATETIME | NO | - | CODE-BACKED | Customer registration timestamp. Used downstream for age-of-account calculations and regulatory checks. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (delegates to) | Trade.GetTreeNodesByParentCID_Inner | EXEC | All business logic is in the inner proc; this is a pure parameter-forwarding wrapper. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetTreeNodesByParentPositionAndTreeId | (independent SP) | Sibling | Alternative tree-traversal SP that queries by PositionID+TreeID rather than by CID. |
| (application services) | @ParentCID | EXEC caller | Called by trading engine services when a position event requires propagating to copiers. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetTreeNodesByParentCID (procedure)
└── Trade.GetTreeNodesByParentCID_Inner (procedure)
      ├── Trade.Mirror (table)
      ├── Customer.Customer (table)
      ├── BackOffice.Customer (table)
      ├── Trade.SynRealCustomers (synonym/view)
      └── Maintenance.Feature (table) [FeatureID=22 IsRealDB flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCID_Inner | Stored Procedure | EXEC - all logic delegated here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetTreeNodesByParentCIDDebug | Stored Procedure | Sibling debug wrapper that delegates to GetTreeNodesByParentCID_InnerDebug instead |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all copiers of a trader right now
```sql
EXEC Trade.GetTreeNodesByParentCID
    @ParentCID = 123456,
    @OperationDateTime = NULL,  -- defaults to GETUTCDATE()
    @GetFirstHierarchyOnly = 0,
    @EnableEtorianHedging = 1,
    @MasterAccountCID = 10717251
```

### 8.2 Get direct (first-level) copiers only at a historical point in time
```sql
EXEC Trade.GetTreeNodesByParentCID
    @ParentCID = 123456,
    @OperationDateTime = '2025-01-15 10:00:00',
    @GetFirstHierarchyOnly = 1
```

### 8.3 Get full hierarchy excluding eToro hedging accounts
```sql
EXEC Trade.GetTreeNodesByParentCID
    @ParentCID = 123456,
    @GetFirstHierarchyOnly = 0,
    @EnableEtorianHedging = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Not listed in the configured TRAD/DB Confluence folder, and no TRAD space search results for this procedure name.)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: Trade.GetTreeNodesByParentCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetTreeNodesByParentCID.sql*
