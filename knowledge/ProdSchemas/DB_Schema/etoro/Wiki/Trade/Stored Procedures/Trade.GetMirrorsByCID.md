# Trade.GetMirrorsByCID

> Returns all CopyTrader mirror relationships for a customer, providing a portfolio-level view of every leader the customer copies along with allocation amounts, profit/loss, and mirror status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - the copier's customer ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorsByCID` retrieves all mirror (copy) relationships for a given customer from `Trade.Mirror`. Each row in the result represents one leader that the customer copies, with the full financial summary: current amount allocated, initial investment, deposits/withdrawals made to the copy, realized equity, net profit, and copy status.

This procedure exists to support customer-facing portfolio views showing "who am I copying?" and their financial summary per copy. It is referenced in the Mirror table doc as one of the key readers of `Trade.Mirror`.

Data flows: Called by the trading layer or portfolio API to present the customer's active and historical copy relationships. Returns all mirrors regardless of `IsActive` or `MirrorStatusID` - both active and closed mirrors are included.

---

## 2. Business Logic

### 2.1 All Mirrors Returned (Active + Closed)

**What**: No status filter applied - all mirrors for the CID are returned.

**Columns/Parameters Involved**: `IsActive`, `MirrorStatusID`

**Rules**:
- No WHERE condition on IsActive or MirrorStatusID.
- Returns active mirrors (IsActive=1) AND closed/inactive mirrors (IsActive=0) for the customer.
- Consumer is responsible for filtering by status if needed.
- MirrorStatusID values: 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment (see Trade.Mirror doc).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | The copier's customer ID. All mirrors where CID = this value are returned. |

**Output columns** (result set - from Trade.Mirror):

| # | Column | Description |
|---|--------|-------------|
| 1 | MirrorID | Unique mirror identifier. |
| 2 | CID | The copier's customer ID (same as @CID). |
| 3 | ParentCID | The leader's customer ID. |
| 4 | ParentUserName | The leader's username. Cached on the mirror row for display purposes. |
| 5 | Amount | Current allocation amount in dollars. The active copy amount. |
| 6 | IsActive | 1=mirror is live; 0=mirror closed/inactive. |
| 7 | InitialInvestment | The original amount invested when the mirror was opened. |
| 8 | DepositSummary | Total funds added to this copy relationship (cumulative deposits). |
| 9 | WithdrawalSummary | Total funds withdrawn from this copy relationship. |
| 10 | NetProfit | Realized net profit/loss on this copy relationship. |
| 11 | MirrorStatusID | Copy state: 0=Active, 1=Pause, 2=PendingClose, 3=InAlignment. See Trade.Mirror Section 2.1. |
| 12 | RealizedEquity | The current realized equity value of the copy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Mirror | Primary read | Returns all mirrors where CID = @CID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorsByCID (procedure)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | SELECT all mirror rows for the given CID |

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

### 8.1 Get all mirrors for a customer

```sql
EXEC Trade.GetMirrorsByCID @CID = 123456;
```

### 8.2 Get only active mirrors for a customer

```sql
SELECT MirrorID, ParentCID, ParentUserName, Amount, MirrorStatusID
FROM Trade.Mirror WITH (NOLOCK)
WHERE CID = 123456
  AND IsActive = 1;
```

### 8.3 Get mirror profit summary for a customer

```sql
SELECT
    m.MirrorID,
    m.ParentUserName,
    m.Amount,
    m.InitialInvestment,
    m.NetProfit,
    m.RealizedEquity,
    m.IsActive
FROM Trade.Mirror m WITH (NOLOCK)
WHERE m.CID = 123456
ORDER BY m.IsActive DESC, m.Amount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorsByCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorsByCID.sql*
