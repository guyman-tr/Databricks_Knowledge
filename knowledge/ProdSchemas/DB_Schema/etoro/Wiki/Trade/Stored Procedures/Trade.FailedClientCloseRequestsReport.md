# Trade.FailedClientCloseRequestsReport

> Generates a report comparing client-requested close rates against actual close rates for positions, calculating the PnL delta between what the client expected and what they received.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Requires pre-populated #positions temp table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure produces a regulatory/compliance report for failed or disputed client close requests. When a client requests to close a position, they see a specific rate on their screen (`ClientViewRate`). If the actual close rate differs significantly, this report calculates the PnL impact of that difference - the "delta" between what the client expected to receive and what they actually received.

The procedure exists because eToro operates under multiple regulatory jurisdictions (identified by the `RegulationID` from the customer's record). When clients dispute close prices, regulators may require evidence of the rate difference and its financial impact. This report provides that evidence.

The report covers both closed positions (from `History.PositionSlim` with actual close data) and still-open positions (from `Trade.Position` with current unrealized PnL), combining them via UNION ALL. The caller must pre-populate a `#positions` temp table with CID, PositionID, ClientViewRate, and RequestOccurred before calling this procedure.

---

## 2. Business Logic

### 2.1 PnL Delta Calculation

**What**: Computes the difference between PnL at the client's requested rate and the actual PnL received.

**Columns/Parameters Involved**: `ClientViewRate`, `InitForexRate`, `AmountInUnitsDecimal`, `LastOpConversionRate`, `NetProfit`, `IsBuy`

**Rules**:
- PnlByRequestedRate (for Buy/Long): ROUND((ClientViewRate - InitForexRate) * AmountInUnitsDecimal * LastOpConversionRate, 2)
- PnlByRequestedRate (for Sell/Short): ROUND((InitForexRate - ClientViewRate) * AmountInUnitsDecimal * LastOpConversionRate, 2)
- Delta = PnlByRequestedRate - NetProfit (positive delta means client would have received MORE at their requested rate)
- For open positions (still active): Delta is NULL since there's no actual close yet

### 2.2 Dual-Source Position Lookup

**What**: Reports both closed and still-open positions from the failed close request list.

**Columns/Parameters Involved**: `History.PositionSlim`, `Trade.Position`

**Rules**:
- Closed positions: JOINed with History.PositionSlim to get actual EndForexRate, CloseOccurred, NetProfit, and ClosePositionActionName
- Open positions: JOINed with Trade.Position (still open despite close request failure) - close fields are NULL
- UNION ALL combines both result sets
- Both include regulation name from BackOffice.Customer -> Dictionary.Regulation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Prerequisite**: Caller must create and populate `#positions` before calling:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | #positions.CID | int | NO | - | CODE-BACKED | Customer who submitted the close request. |
| 2 | #positions.PositionID | int | NO | - | CODE-BACKED | Position for which close was requested. Becomes the UNIQUE CLUSTERED INDEX key. |
| 3 | #positions.ClientViewRate | decimal(18,8) | NO | - | CODE-BACKED | Rate the client saw on their screen when they submitted the close request. Used to calculate expected PnL. |
| 4 | #positions.RequestOccurred | datetime | NO | - | CODE-BACKED | Timestamp when the client submitted the close request. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | History.PositionSlim | READER | Gets actual close data (EndForexRate, NetProfit, CloseOccurred, ActionType) for closed positions |
| JOIN | Trade.Position (view) | READER | Gets current state for positions that are still open despite close request |
| JOIN | Dictionary.ClosePositionActionType | READER | Resolves ActionType to human-readable close reason name |
| JOIN | BackOffice.Customer | READER | Gets customer's RegulationID |
| JOIN | Dictionary.Regulation | READER | Resolves RegulationID to regulation name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | Called by compliance/reporting processes that populate #positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FailedClientCloseRequestsReport (procedure)
+-- History.PositionSlim (table/view)
+-- Trade.Position (view)
+-- Dictionary.ClosePositionActionType (table)
+-- BackOffice.Customer (table)
+-- Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table/View | JOIN - closed position data |
| Trade.Position | View | JOIN - open position data |
| Dictionary.ClosePositionActionType | Table | JOIN - resolves close action type to name |
| BackOffice.Customer | Table | JOIN - gets customer regulation |
| Dictionary.Regulation | Table | JOIN - resolves regulation name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp table indexes: UNIQUE CLUSTERED INDEX `Cix` on #positions(PositionID)

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Generate Report for Specific Close Requests

```sql
CREATE TABLE #positions (CID INT, PositionID INT, ClientViewRate DECIMAL(18,8), RequestOccurred DATETIME)

INSERT INTO #positions VALUES (12345, 999999, 150.50000000, '2026-03-15 14:30:00')

EXEC Trade.FailedClientCloseRequestsReport

DROP TABLE #positions
```

### 8.2 Find Positions with Large Rate Discrepancies in History

```sql
SELECT TOP 50
       PositionID,
       CID,
       InitForexRate AS OpenRate,
       EndForexRate AS ActualCloseRate,
       NetProfit,
       ActionType
  FROM History.PositionSlim WITH (NOLOCK)
 WHERE CloseOccurred > DATEADD(DAY, -7, GETUTCDATE())
   AND ActionType IN (1, 5)
 ORDER BY CloseOccurred DESC
```

### 8.3 View Regulation Distribution of Active Customers

```sql
SELECT dr.Name AS Regulation,
       COUNT(DISTINCT bc.CID) AS CustomerCount
  FROM BackOffice.Customer bc WITH (NOLOCK)
  JOIN Dictionary.Regulation dr WITH (NOLOCK) ON dr.ID = bc.RegulationID
 GROUP BY dr.Name
 ORDER BY CustomerCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FailedClientCloseRequestsReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FailedClientCloseRequestsReport.sql*
