# Trade.ReportWrongDataInCustomerMoneyOLD

> Legacy version of the CustomerMoney financial integrity monitor that checks only RealizedEquity consistency (not TotalCash); superseded by Trade.ReportWrongDataInCustomerMoneyNew which adds TotalCash detection.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - runs as a scheduled monitoring job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the original version of the CustomerMoney financial integrity checker. It cross-validates `Customer.CustomerMoney.RealizedEquity` against the computed sum of a customer's credit, open mirrors, open positions, and pending cashout requests. Any customer whose stored RealizedEquity deviates from the computed value by 0.01 or more is reported via HTML email alert.

This procedure was superseded by `Trade.ReportWrongDataInCustomerMoneyNew`, which adds a TotalCash consistency check and outputs a richer CONCAT of which columns are wrong. The OLD version outputs only 'RealizedEquity' as the column name for all discrepancies. The financial logic (CTEs, formula, CreditTypeID mapping) is otherwise identical between the two versions.

The procedure is designed to run as a scheduled SQL Agent job. It sends alerts to tradingbackend, dba, tier2, and MIMO production email groups.

---

## 2. Business Logic

### 2.1 RealizedEquity Consistency Formula

**What**: Validates that CustomerMoney.RealizedEquity equals the sum of credit plus all open exposure minus pending cashouts.

**Columns/Parameters Involved**: `Customer.CustomerMoney.Credit`, `Customer.CustomerMoney.RealizedEquity`, `Trade.Mirror.Amount`, `Trade.Position.Amount`, `History.Credit.Payment`

**Rules**:
- Formula: `RealizedEquity ~= Credit + ActualMirrorAmount + SumOfPositions - PendingCashoutsWithoutApproval`
- Tolerance: ABS difference must be >= 0.01 to trigger alert (avoids floating-point noise)
- TotalCash check is defined in CASE expression but fully commented out in WHERE clause - never triggers
- "Pending cashouts" = CreditTypeID=9 or 15 with no matching CreditTypeID=2 or 8 approval
- Uses DISTINCT in final SELECT to avoid duplicate CID reporting

### 2.2 Difference from the "New" Version

**What**: The key distinction between OLD and New versions of this monitoring procedure.

**Rules**:
- OLD: ColumnsNames always = 'RealizedEquity' for all discrepancies
- NEW: ColumnsNames = CONCAT of 'TotalCash ' and/or 'RealizedEquity ' depending on which formula fails
- OLD: WHERE clause only checks RealizedEquity divergence
- NEW: WHERE clause checks RealizedEquity (TotalCash is defined but commented out)
- Both: identical CTE structure, same email recipients, same tolerance threshold

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | No input parameters. Designed as a scheduled monitoring job. |

**Internal temp variable: @Tbl (result output)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | BIGINT | NO | - | CODE-BACKED | Customer identifier of the account with the RealizedEquity discrepancy. |
| 3 | ColumnsNames | VARCHAR(40) | NO | - | CODE-BACKED | Always contains 'RealizedEquity ' for any flagged row in this OLD version. Unlike the New version, TotalCash is never reported here. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ActualMirrorData CTE | Trade.Mirror | Lookup | Sums mirror amounts per CID |
| PositionData CTE | Trade.Position | Lookup | Sums open position amounts per CID |
| ActualData CTE | Customer.CustomerMoney | Lookup | Reads cached financial summary for validation |
| Requests/Approved CTEs | History.Credit | Lookup | Identifies unapproved cashout requests via CreditTypeID 9, 15, 2, 8 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReportWrongDataInCustomerMoneyOLD (procedure)
|- Trade.Mirror (table)
|- Trade.Position (view - open positions)
|- Customer.CustomerMoney (table)
|- History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Summed by CID for total copy-trade mirror amount |
| Trade.Position | View | Summed by CID for total open position exposure |
| Customer.CustomerMoney | Table | Source of Credit, RealizedEquity to validate |
| History.Credit | Table | Identifies pending cashout requests via CreditTypeID |

### 6.2 Objects That Depend On This

No dependents found - standalone monitoring procedure, superseded by New version.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Tolerance | Logic | ABS(difference) >= 0.01 - 1 cent minimum to flag a discrepancy |

---

## 8. Sample Queries

### 8.1 Execute the legacy financial integrity check

```sql
EXEC Trade.ReportWrongDataInCustomerMoneyOLD
```

### 8.2 Compare OLD vs NEW detection for a specific CID

```sql
-- Check what OLD would detect (RealizedEquity only)
;WITH M AS (SELECT CID, SUM(Amount) MA FROM Trade.Mirror WITH (NOLOCK) GROUP BY CID),
P AS (SELECT CID, SUM(Amount) PA FROM Trade.Position WITH (NOLOCK) GROUP BY CID)
SELECT CM.CID,
    ABS((CM.Credit + ISNULL(M.MA,0) + ISNULL(P.PA,0)) - CM.RealizedEquity) AS RE_Discrepancy,
    ABS(ISNULL(CM.TotalCash,0) - CM.Credit - ISNULL(M.MA,0)) AS TC_Discrepancy
FROM Customer.CustomerMoney CM WITH (NOLOCK)
LEFT JOIN M ON M.CID = CM.CID
LEFT JOIN P ON P.CID = CM.CID
WHERE CM.CID = 123456
```

### 8.3 Find pending cashout requests not yet approved (Disc CTE)

```sql
SELECT R.CID, R.WithdrawID, SUM(R.Payment) AS PendingAmount
FROM History.Credit R WITH (NOLOCK)
LEFT JOIN History.Credit A WITH (NOLOCK)
    ON R.WithdrawID = A.WithdrawID
    AND A.CreditTypeID IN (2, 8)
WHERE R.CreditTypeID IN (9, 15)
    AND A.WithdrawID IS NULL
GROUP BY R.CID, R.WithdrawID
ORDER BY R.CID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReportWrongDataInCustomerMoneyOLD | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReportWrongDataInCustomerMoneyOLD.sql*
