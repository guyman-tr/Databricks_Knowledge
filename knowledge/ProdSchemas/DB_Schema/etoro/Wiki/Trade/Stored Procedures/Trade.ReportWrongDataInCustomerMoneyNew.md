# Trade.ReportWrongDataInCustomerMoneyNew

> Monitors financial data consistency by detecting customers whose CustomerMoney balances (TotalCash and RealizedEquity) deviate from the sum of their actual positions, mirrors, and cashout requests, and sends an HTML email alert when discrepancies exceed 0.01.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - runs as a scheduled monitoring job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a financial integrity watchdog for the eToro trading platform. It cross-validates the cached financial summary in `Customer.CustomerMoney` against the true sum of a customer's live positions, active copy-trade mirrors, and pending cashout requests. If a customer's stored TotalCash or RealizedEquity diverges from the ground truth by 0.01 or more, their CID and the affected column(s) are captured and emailed to the trading backend, DBA, tier2, and MIMO production teams.

Without this procedure, financial data corruption - caused by failed transactions, race conditions, or missed updates - could go undetected, leading to customers seeing incorrect account balances or the system making incorrect margin and risk decisions based on stale financial data.

The procedure is intended to be run as a scheduled SQL Agent job. It has no input parameters and produces two outputs: a result set (CID + affected columns) and an HTML email alert. It is the "New" version of `Trade.ReportWrongDataInCustomerMoneyOLD` and adds a TotalCash check (though TotalCash validation is partially commented out in the WHERE clause, only RealizedEquity discrepancies trigger the current alert).

---

## 2. Business Logic

### 2.1 Financial Consistency Formula

**What**: Two independent financial equations that must balance for every customer account.

**Columns/Parameters Involved**: `Customer.CustomerMoney.Credit`, `Customer.CustomerMoney.TotalCash`, `Customer.CustomerMoney.RealizedEquity`, `Trade.Mirror.Amount`, `Trade.Position.Amount`, `History.Credit.Payment`

**Rules**:
- TotalCash equation: `TotalCash ~= Credit + ActualMirrorAmount` (within 0.01 tolerance)
- RealizedEquity equation: `RealizedEquity ~= Credit + ActualMirrorAmount + SumOfPositions - PendingCashoutsWithoutApproval`
- Tolerance is 0.01 (1 cent) to avoid floating-point noise
- "Pending cashouts" = CreditTypeID=9 (cashout request) or 15 (cashout fee) that have no matching CreditTypeID=2 (approved cashout) or 8 (reversed cashout) - these modify Credit but not RealizedEquity

**Diagram**:
```
CustomerMoney.RealizedEquity should equal:
  Credit
  + SUM(Trade.Mirror.Amount) per CID
  + SUM(Trade.Position.Amount) per CID
  - SUM(History.Credit.Payment WHERE pending cashout request with no approval)

CustomerMoney.TotalCash should equal:
  Credit
  + SUM(Trade.Mirror.Amount) per CID
  [TotalCash check is defined but currently not active in WHERE clause]
```

### 2.2 CreditType Mapping

**What**: History.Credit CreditTypeID values used to identify pending cashout state.

**Columns/Parameters Involved**: `History.Credit.CreditTypeID`, `History.Credit.WithdrawID`

**Rules**:
- CreditTypeID=9: Cashout request (modifies Credit but not yet RealizedEquity)
- CreditTypeID=15: Cashout fee (modifies Credit but not yet RealizedEquity)
- CreditTypeID=2: Approved cashout (matches against request via WithdrawID)
- CreditTypeID=8: Reversed cashout
- "Disc" CTE: requests with NO matching approval = pending cashouts to subtract from RealizedEquity

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure has no input parameters. It is designed as a scheduled monitoring job that runs autonomously. |

**Internal temp variable: @Tbl**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | BIGINT | NO | - | CODE-BACKED | Customer identifier of the account with detected financial inconsistency. |
| 3 | ColumnsNames | VARCHAR(40) | NO | - | CODE-BACKED | Space-delimited list of column names with wrong values in CustomerMoney. Possible values: 'TotalCash ' (defined but currently not triggered), 'RealizedEquity '. Both can appear together if multiple columns are wrong. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActualMirrorData CTE | Trade.Mirror | Lookup | Sums open mirror amounts per CID to get total copy-trade exposure |
| PositionData CTE | Trade.Position | Lookup | Sums open position amounts per CID |
| ActualData CTE | Customer.CustomerMoney | Lookup | Reads the cached financial summary to compare against computed truth |
| Requests/Approved CTEs | History.Credit | Lookup | Identifies pending (unapproved) cashout requests via CreditTypeID filtering |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInCustomerMoneyNew (procedure)
|- Trade.Mirror (table)
|- Trade.Position (view - open positions)
|- Customer.CustomerMoney (table)
|- History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Summed by CID to get total copy-trade investment amount |
| Trade.Position | View | Summed by CID to get total open position exposure |
| Customer.CustomerMoney | Table | Read for Credit, RealizedEquity, TotalCash to validate |
| History.Credit | Table | Filtered by CreditTypeID to identify pending cashout requests and approvals |

### 6.2 Objects That Depend On This

No dependents found - this is a standalone monitoring procedure called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Tolerance check | Logic | ABS(difference) >= 0.01 - only flags differences of 1 cent or more to avoid floating-point noise |
| TotalCash check | Logic | Defined in CONCAT but commented out in WHERE - currently only RealizedEquity discrepancies trigger the alert |

---

## 8. Sample Queries

### 8.1 Run the financial integrity check manually

```sql
EXEC Trade.ReportWrongDataInCustomerMoneyNew
```

### 8.2 Replicate the RealizedEquity check for a specific CID

```sql
;WITH ActualMirrorData AS (
    SELECT CID, SUM(Amount) AS ActualMirrorAmount
    FROM Trade.Mirror WITH (NOLOCK)
    GROUP BY CID
),
PositionData AS (
    SELECT CID, SUM(Amount) AS PositionAmount
    FROM Trade.Position WITH (NOLOCK)
    GROUP BY CID
)
SELECT CM.CID,
    CM.Credit,
    CM.RealizedEquity,
    ISNULL(PA.PositionAmount, 0) AS SumPositions,
    ISNULL(MA.ActualMirrorAmount, 0) AS SumMirrors,
    CM.Credit + ISNULL(MA.ActualMirrorAmount,0) + ISNULL(PA.PositionAmount,0) AS ComputedRealizedEquity,
    ABS((CM.Credit + ISNULL(MA.ActualMirrorAmount,0) + ISNULL(PA.PositionAmount,0)) - CM.RealizedEquity) AS Discrepancy
FROM Customer.CustomerMoney CM WITH (NOLOCK)
LEFT JOIN PositionData PA ON PA.CID = CM.CID
LEFT JOIN ActualMirrorData MA ON MA.CID = CM.CID
WHERE CM.CID = 123456
```

### 8.3 Check pending cashout requests (the Disc CTE logic)

```sql
SELECT R.CID, SUM(R.Payment) AS PendingCashoutAmount
FROM History.Credit R WITH (NOLOCK)
LEFT JOIN History.Credit A WITH (NOLOCK)
    ON R.WithdrawID = A.WithdrawID
    AND (A.CreditTypeID = 2 OR A.CreditTypeID = 8)
WHERE (R.CreditTypeID = 9 OR R.CreditTypeID = 15)
    AND A.WithdrawID IS NULL
GROUP BY R.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInCustomerMoneyNew | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInCustomerMoneyNew.sql*
