# BackOffice.GetCustomerOpenCopiedTraders

> Returns all copy (mirror) relationships for a customer from Trade.Mirror, with aggregated open-position equity metrics per copied trader.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer lookup |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a BackOffice agent reviews a customer's Copy Trading activity, this procedure populates the Open Copied Traders panel: each row represents one copy relationship (mirror), showing the copied trader's identity, the customer's cash and position equity in that mirror, unrealized P&L, and Copy Stop Loss level.

The procedure was originally extracted from inline BackOffice application code in October 2013 (case 18846 - "This is the backoffice query from the code, turned into a stored procedure").

**Important behavioral note**: The WHERE clause filters only on `TMIR.CID = @CID` with no open-state filter on Trade.Mirror. The companion procedure `GetCustomerClosedCopiedTraders` uses a separate HAVING-based pattern to detect closed mirrors. This means `GetCustomerOpenCopiedTraders` returns all mirror rows for the customer in Trade.Mirror regardless of open/closed state. In practice, Trade.Mirror is the live/active state table and closed mirrors are typically tracked via History.Mirror, so the absence of a state filter effectively means active mirrors are returned - but agents may occasionally see mirrors in transitional states.

**Equity breakdown per mirror**:
- **Mirror Cash** (`TMIR.Amount`): the uninvested cash balance sitting idle in the mirror wallet
- **Amount In Open Positions** (aggregated from PositionForExternalUseWithPnL): total `Amount` invested in open copy positions
- **Realized Equity**: Mirror Cash + Amount In Open Positions (excludes unrealized P&L)
- **Total P&L**: sum of `PnLInDollars` on all open copy positions (unrealized)
- **Equity**: Mirror Cash + Amount In Open Positions + Total P&L (total economic value)

---

## 2. Business Logic

### 2.1 Open Position Aggregation Per Mirror

**What**: A subquery aggregates position-level data from Trade.PositionForExternalUseWithPnL for copy (mirror) positions only.

**Rules**:
- `TPOS.CID = @CID` - only this customer's positions
- `TPOS.MirrorID > 0` - only positions associated with a mirror (non-zero MirrorID means copy position)
- `ParentPositionID > 0` - only copy positions that have a parent (the master trader's position); manual positions in a mirror have ParentPositionID=0
- `GROUP BY MirrorID` - aggregates PositionCount, TotalAmount (sum of Amount), TotalPNL (sum of PnLInDollars)

### 2.2 Equity Components

**Rules**:
- `[Realized Equity]` = `TMIR.Amount + ISNULL(OpenPositions.TotalAmount, 0)` - ISNULL guard handles mirrors with no open positions
- `[Equity]` = `TMIR.Amount + OpenPositions.TotalAmount + OpenPositions.TotalPNL` - NOTE: no ISNULL here; if OpenPositions is NULL (LEFT JOIN miss), this expression evaluates to NULL
- The asymmetry between [Realized Equity] (ISNULL-guarded) and [Equity] (unguarded) means [Equity] can be NULL for mirrors with no open positions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Matched against Trade.Mirror.CID. |
| **Output Columns** | | | | | | |
| 2 | [Mirror ID] | INT | NO | - | CODE-BACKED | Copy relationship identifier. From Trade.Mirror.MirrorID. |
| 3 | [Parent CID] | INT | YES | - | CODE-BACKED | CID of the trader being copied (the Popular Investor / copy source). From Trade.Mirror.ParentCID. |
| 4 | [Parent Username] | NVARCHAR | YES | - | CODE-BACKED | Username of the copied trader. From Trade.Mirror.ParentUserName. |
| 5 | [Mirror Cash] | DECIMAL(16,2) | NO | - | CODE-BACKED | Uninvested cash balance held in the mirror wallet. From Trade.Mirror.Amount. |
| 6 | [Amount In Open Positions] | DECIMAL(16,2) | YES | NULL | CODE-BACKED | Total amount currently invested in open copy positions for this mirror. NULL if no open copy positions exist. Sum of Trade.PositionForExternalUseWithPnL.Amount where MirrorID matches. |
| 7 | [Realized Equity] | DECIMAL(16,2) | NO | - | CODE-BACKED | Mirror Cash + Amount In Open Positions. ISNULL-guarded: 0 used when no open positions. Excludes unrealized P&L. |
| 8 | [Total P&L] | DECIMAL(16,2) | YES | NULL | CODE-BACKED | Sum of unrealized P&L on all open copy positions. From sum of Trade.PositionForExternalUseWithPnL.PnLInDollars. NULL if no open copy positions. |
| 9 | [Equity] | DECIMAL(16,2) | YES | NULL | CODE-BACKED | Total economic value: Mirror Cash + Amount In Open Positions + Total P&L. NULL if no open copy positions (no ISNULL guard on this expression). |
| 10 | [Open Positions] | INT | YES | NULL | CODE-BACKED | Count of open copy positions in this mirror. NULL if no open copy positions exist. |
| 11 | [Copied On] | DATETIME | NO | - | CODE-BACKED | Timestamp when the copy relationship started. From Trade.Mirror.Occurred. |
| 12 | [Copy Stop Loss] | DECIMAL(16,2) | YES | NULL | CODE-BACKED | Copy Stop Loss percentage level set for this mirror. From Trade.Mirror.MirrorSL. NULL if not configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Trade.Mirror | Primary Source | All copy relationships for the customer |
| MirrorID | Trade.PositionForExternalUseWithPnL | LEFT JOIN (subquery) | Aggregated open copy position equity per mirror |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice application (BO) | N/A | Application call | Open Copied Traders panel in customer profile |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerOpenCopiedTraders (procedure)
|- Trade.Mirror (copy relationship state + cash balance)
+-- Trade.PositionForExternalUseWithPnL (open copy position aggregates)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Primary source - copy relationships, mirror cash, copy stop loss |
| Trade.PositionForExternalUseWithPnL | View/Table | LEFT JOINed subquery - aggregates position count, invested amount, and unrealized P&L per MirrorID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice application (BO) | External application | Open Copied Traders panel - mirror equity overview per copied trader |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `SET NOCOUNT ON`; `WITH(NOLOCK)` on Trade.Mirror.
- `ORDER BY TMIR.Occurred DESC` - most recently started copy relationships first.
- No explicit open-state filter: relies on Trade.Mirror being the active-state table. Compare with `GetCustomerClosedCopiedTraders` which uses a HAVING-based approach to detect closed mirrors via History.Mirror.
- [Equity] can be NULL for mirrors with zero open positions due to missing ISNULL guard (unlike [Realized Equity]).

---

## 8. Sample Queries

### 8.1 Get open copied traders for a customer

```sql
EXEC BackOffice.GetCustomerOpenCopiedTraders @CID = 12345678;
```

### 8.2 Direct base-table query

```sql
SELECT
    TMIR.MirrorID AS [Mirror ID],
    TMIR.ParentCID AS [Parent CID],
    TMIR.ParentUserName AS [Parent Username],
    CAST(TMIR.Amount AS DECIMAL(16,2)) AS [Mirror Cash],
    CAST(TMIR.MirrorSL AS DECIMAL(16,2)) AS [Copy Stop Loss]
FROM Trade.Mirror TMIR WITH(NOLOCK)
WHERE TMIR.CID = 12345678
ORDER BY TMIR.Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found for this procedure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerOpenCopiedTraders | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerOpenCopiedTraders.sql*
