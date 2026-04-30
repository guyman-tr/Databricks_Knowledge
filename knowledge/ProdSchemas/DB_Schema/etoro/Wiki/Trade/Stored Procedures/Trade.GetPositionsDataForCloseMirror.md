# Trade.GetPositionsDataForCloseMirror

> Returns two result sets for a specific mirror and customer: open positions eligible for closing, and positions already in a non-terminal close execution plan - used to drive CopyTrader mirror closure without duplicate close orders.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @mirrorId INT, @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the data needed to safely close all open positions in a CopyTrader mirror for a given customer. It returns two result sets that are consumed together: the first lists every currently open position for the specified mirror and customer (what needs to be closed), and the second lists positions that already have an active (non-terminal) close order in the execution pipeline (what is already being closed). The caller uses these two sets to compute which positions still need new close orders submitted, avoiding duplicate close requests.

The procedure exists as the data-gathering step of the mirror close workflow. When a customer stops copying a leader (or when a mirror enters a closure state), the system must close all the copier's positions that were opened via that mirror. Without knowing which close orders are already in-flight, the system could re-submit close requests for positions already being processed, causing double-close errors.

Data flows: Called by a mirror management service during the CopyTrader stop-copy or mirror-close flow. Result set 1 reads from `Trade.PositionTbl` (StatusID=1 = open, filtered by MirrorID and CID). Result set 2 reads from `Trade.CloseExecutionPlan` joined to `Trade.OrderForClose` and `Dictionary.OrderForExecutionStatus`, returning PositionIDs whose close orders have not yet reached a terminal state.

---

## 2. Business Logic

### 2.1 Two Result Sets: What to Close vs. What is Already Closing

**What**: The caller must subtract "already closing" from "open" to determine which positions need fresh close orders.

**Columns/Parameters Involved**: `@mirrorId`, `@cid`, `Trade.PositionTbl.StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Result set 1: All positions WHERE MirrorID = @mirrorId AND CID = @cid AND StatusID = 1. These are the open positions the caller needs to close.
- Result set 2: Positions WHERE CID = @cid AND the close order's status is non-terminal (IsTerminal=0). Non-terminal statuses: 1=RECEIVED, 2=PLACED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 11=WAITING_FOR_MARKET. These positions are already in the close pipeline.
- Caller logic: target_positions = ResultSet1 MINUS ResultSet2. Submit close orders only for the difference.
- Note: Result set 2 is filtered by CID only (not MirrorID), capturing all in-flight close orders for the customer regardless of which mirror they belong to.

**Diagram**:
```
[Open positions for mirror/CID]     = ResultSet1
        MINUS
[Positions with active close order] = ResultSet2
        =
[Positions needing new close order]
```

### 2.2 Non-Terminal Close Order States

**What**: Dictionary.OrderForExecutionStatus.IsTerminal=0 marks states where the close order is still in progress.

**Columns/Parameters Involved**: `Trade.CloseExecutionPlan`, `Trade.OrderForClose.StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Non-terminal (IsTerminal=0): 1=RECEIVED, 2=PLACED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 11=WAITING_FOR_MARKET. Orders in these states are still active.
- Terminal (IsTerminal=1): 3=FILLED, 4=REJECTED, 7=CANCELED, 8=EXPIRED, 9=CANCELED_PARTIALLY_FILLED, 10=REJECTED_PARTIALLY_FILLED. Terminal orders are done and should not block new close submissions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @mirrorId | INT | NO | - | CODE-BACKED | The CopyTrader Mirror ID. Identifies the copier-leader relationship whose positions should be closed. FK to Trade.Mirror.MirrorID. |
| 2 | @cid | INT | NO | - | CODE-BACKED | The customer ID (copier). Scopes both queries to a single customer to avoid cross-customer data leakage. |

**Result Set 1: Open Positions for This Mirror**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | PositionID | BIGINT | NO | - | CODE-BACKED | ID of an open position (StatusID=1) belonging to the specified @mirrorId and @cid. Each of these positions is a candidate for close order submission. |
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | The traded instrument of the open position. Returned so the caller can route close orders to the correct instrument handler or market. |

**Result Set 2: Positions Already in Close Pipeline**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | ID of a position that already has a non-terminal close order in Trade.CloseExecutionPlan. The caller should exclude these from new close order submissions to prevent duplicates. Filtered to @cid (not @mirrorId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @mirrorId | Trade.Mirror | Lookup | The mirror whose positions are being closed |
| @cid | Trade.PositionTbl | Filter | CID filter; scopes to this customer's positions |
| StatusID=1 | Trade.PositionTbl | JOIN source | Only open positions are candidates for closure |
| OrderID | Trade.CloseExecutionPlan | JOIN source | Pending close execution plans for the customer |
| StatusID | Trade.OrderForClose | JOIN | Order lifecycle status |
| IsTerminal=0 | Dictionary.OrderForExecutionStatus | Lookup | Non-terminal status filter: 1=RECEIVED, 2=PLACED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 11=WAITING_FOR_MARKET |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsDataForCloseMirror (procedure)
├── Trade.PositionTbl (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
└── Dictionary.OrderForExecutionStatus (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT open positions filtered by MirrorID, CID, StatusID=1 |
| Trade.CloseExecutionPlan | Table | JOIN to find in-flight close operations for the customer |
| Trade.OrderForClose | Table | JOIN on OrderID to get the current close order status |
| Dictionary.OrderForExecutionStatus | Table | Filter on IsTerminal=0 to identify non-terminal (still-active) close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Mirror close workflow (application service) | External application | Calls this procedure to determine which positions need close orders when stopping a CopyTrader copy relationship |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error handling | TRY/CATCH | Any SQL error is re-thrown (THROW) to the caller without suppression |

---

## 8. Sample Queries

### 8.1 Execute for a specific mirror and customer

```sql
EXEC Trade.GetPositionsDataForCloseMirror
    @mirrorId = 12345,
    @cid = 1234567;
```

### 8.2 Manually check open positions for a mirror

```sql
SELECT PositionID, InstrumentID
FROM Trade.PositionTbl WITH (NOLOCK)
WHERE MirrorID = 12345
  AND CID = 1234567
  AND StatusID = 1;
```

### 8.3 Check in-flight close orders for a customer

```sql
SELECT cep.PositionID, ofc.StatusID, os.Status, os.IsTerminal
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
INNER JOIN Trade.OrderForClose ofc WITH (NOLOCK) ON cep.OrderID = ofc.OrderID
INNER JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK) ON ofc.StatusID = os.ID
WHERE cep.CID = 1234567
  AND os.IsTerminal = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsDataForCloseMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsDataForCloseMirror.sql*
