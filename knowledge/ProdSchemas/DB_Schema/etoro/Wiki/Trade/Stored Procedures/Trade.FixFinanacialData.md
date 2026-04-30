# Trade.FixFinanacialData

> Detects and corrects discrepancies in a customer's financial data (TotalCash, RealizedEquity) by recalculating from positions, mirrors, and credit history, then applying fixes via Customer.SetBalanceDataFix.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to fix |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a financial data integrity repair tool for a specific customer's account. It recalculates what the customer's `TotalCash` and `RealizedEquity` should be based on the actual source data (positions, mirrors, credits), compares those calculated values against what's stored in `Customer.CustomerMoney`, and if discrepancies of $0.01 or more exist, calls `Customer.SetBalanceDataFix` to correct them.

The procedure exists because `Customer.CustomerMoney` is a denormalized financial summary that can drift from reality due to rounding, timing issues, or edge cases in the credit/debit pipeline. The three key financial identities it enforces are:
- **TotalCash** should equal Credit + ActualMirrorAmount
- **RealizedEquity** should equal SumOfPositions + Credit + ActualMirrorAmount - PendingWithdrawals

The procedure handles a subtle edge case: cashout requests (CreditTypeID 9, 15) that have NOT been approved (CreditTypeID 2, 8) modify Credit but not RealizedEquity, creating a temporary discrepancy. The procedure accounts for these unapproved withdrawals by subtracting them from the expected RealizedEquity.

---

## 2. Business Logic

### 2.1 Actual Financial State Recalculation

**What**: Computes ground-truth financial values from source tables.

**Columns/Parameters Involved**: `Credit`, `SumOfPositions`, `ActualMirrorAmount`, `RwithoutA`

**Rules**:
- SumOfPositions = SUM(Amount) from Trade.Position (all open position investments)
- ActualMirrorAmount = SUM(Amount) from Trade.Mirror (all active mirror allocations)
- ActualTotalCash = Credit + ISNULL(ActualMirrorAmount, 0)
- ActualRealizedEquity = SumOfPositions + Credit + ActualMirrorAmount - RwithoutA
- RwithoutA = Sum of cashout request payments (CreditTypeID 9, 15) that have no matching approval (CreditTypeID 2, 8) by WithdrawID

### 2.2 Discrepancy Detection and Fix

**What**: Only applies fixes when actual vs stored values differ by >= $0.01.

**Columns/Parameters Involved**: `@TotalCash`, `@ActualTotalCash`, `@RealizedEquity`, `@ActualRealizedEquity`

**Rules**:
- TotalCash discrepancy: ABS(TotalCash - Credit - ISNULL(ActualMirrorAmount, 0)) >= 0.01
- RealizedEquity discrepancy: ABS(ActualRealizedEquity - RealizedEquity) >= 0.01
- Description field built dynamically listing which columns need fixing
- Fix applied by calling Customer.SetBalanceDataFix with corrected values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID whose financial data should be verified and corrected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.Position (view) | READER | SUM(Amount) for all open positions |
| SELECT | Trade.Mirror | READER | SUM(Amount) for all mirror allocations |
| SELECT | Customer.CustomerMoney | READER | Gets current stored Credit, RealizedEquity, TotalCash |
| SELECT | History.ActiveCredit | READER | Gets cashout requests (9,15) and approvals (2,8) to compute unapproved withdrawals |
| EXEC | Customer.SetBalanceDataFix | Caller | Applies the corrected financial values |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | Called by support/operations for individual customer balance fixes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FixFinanacialData (procedure)
+-- Trade.Position (view)
+-- Trade.Mirror (table)
+-- Customer.CustomerMoney (table)
+-- History.ActiveCredit (table)
+-- Customer.SetBalanceDataFix (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT - sums position amounts |
| Trade.Mirror | Table | SELECT - sums mirror allocation amounts |
| Customer.CustomerMoney | Table | SELECT - reads current financial state |
| History.ActiveCredit | Table | SELECT - reads cashout requests and approvals |
| Customer.SetBalanceDataFix | Stored Procedure | EXEC - applies corrected financial values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Procedure name contains a typo ("Finanacial" instead of "Financial"). This is the deployed name.

**Credit Types Referenced**:
- CreditTypeID 9: Cashout request
- CreditTypeID 15: Cashout fee
- CreditTypeID 2: Cashout (approved)
- CreditTypeID 8: Reverse cashout

---

## 8. Sample Queries

### 8.1 Fix a Specific Customer's Financial Data

```sql
EXEC Trade.FixFinanacialData @CID = 12345
```

### 8.2 Preview Financial Discrepancies Without Fixing

```sql
SELECT CM.CID,
       CM.Credit,
       CM.TotalCash,
       CM.Credit + ISNULL((SELECT SUM(Amount) FROM Trade.Mirror WITH (NOLOCK) WHERE CID = CM.CID), 0) AS ExpectedTotalCash,
       CM.RealizedEquity,
       ISNULL((SELECT SUM(Amount) FROM Trade.Position WITH (NOLOCK) WHERE CID = CM.CID), 0) AS SumPositions
  FROM Customer.CustomerMoney CM WITH (NOLOCK)
 WHERE CM.CID = 12345
```

### 8.3 Find Customers with Potential Balance Issues

```sql
SELECT CM.CID,
       CM.TotalCash,
       CM.Credit,
       ABS(CM.TotalCash - CM.Credit) AS TotalCashDelta
  FROM Customer.CustomerMoney CM WITH (NOLOCK)
 WHERE ABS(CM.TotalCash - CM.Credit) >= 0.01
 ORDER BY ABS(CM.TotalCash - CM.Credit) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FixFinanacialData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.FixFinanacialData.sql*
