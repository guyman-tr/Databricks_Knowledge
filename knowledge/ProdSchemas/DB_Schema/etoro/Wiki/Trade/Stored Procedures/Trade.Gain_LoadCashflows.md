# Trade.Gain_LoadCashflows

> Loads cashflow history (credits, debits, withdrawals) for a set of customers within their individual date ranges, excluding internal/system credit types, for gain/loss calculation processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxDate + @customers (TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the primary data loader for the Gain (P&L calculation) system's cashflow analysis. It extracts a customer's complete cashflow history - deposits, withdrawals, fees, dividends, and other credit/debit transactions - for the period between each customer's individual start date and the global @MaxDate. This data is the foundation for calculating net gain/loss by determining how much money flowed in and out of each customer's account during the period.

The procedure excludes a long list of internal/system credit types (CreditTypeIDs 3, 4, 8, 9, 13, 14, 18-25, 27-31) that represent internal transfers, reversals, or system-generated entries that should not affect gain calculations. The remaining credit types represent actual customer-facing cashflows.

For withdrawals linked to Billing.WithdrawToFunding records, the procedure uses the funding amount (negated) instead of TotalCashChange, because the funding amount represents the actual money that left the customer's account (net of fees).

---

## 2. Business Logic

### 2.1 Credit Type Exclusion Filter

**What**: Excludes internal/system credit types that don't represent real cashflows.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- Excluded CreditTypeIDs: 3, 4, 8, 9, 13, 14, 18, 19, 20, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31
- These represent internal transfers, bonus reversals, system adjustments, and other non-cashflow entries
- Remaining credit types (deposits, withdrawals, fees, dividends, compensations) are included

### 2.2 Withdrawal Amount Override

**What**: Uses funding amount instead of credit amount for withdrawals with funding records.

**Columns/Parameters Involved**: `TotalCashChange`, `Billing.WithdrawToFunding.Amount`

**Rules**:
- LEFT JOIN to Billing.WithdrawToFunding on WithdrawProcessingID = ID
- If a funding record exists: Amount = -c.Amount (negated funding amount, since the funding table stores positive values)
- If no funding record: Amount = a.TotalCashChange (standard credit amount)
- The IsFee column flags CreditTypeID=15 (cashout fee) as fee transactions

### 2.3 Per-Customer Date Ranges

**What**: Each customer has its own start date, with a global end date.

**Columns/Parameters Involved**: `@MaxDate`, `@customers.MinDate`

**Rules**:
- TVP provides each customer's CID and MinDate (their individual start of gain period)
- Credits are filtered: Occurred BETWEEN customer.MinDate AND @MaxDate
- This allows the Gain system to process customers with different gain period start dates in a single batch

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxDate | datetime | NO | - | CODE-BACKED | Global end date for the cashflow extraction period. Credits with Occurred > @MaxDate are excluded. |
| 2 | @customers | Trade.Gain_CashFlowProviderCustomers (TVP) | NO | - | CODE-BACKED | Table-Valued Parameter containing customer CIDs and their individual MinDate (gain period start). READONLY. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 2 | CreditID | bigint | NO | - | CODE-BACKED | Unique credit transaction identifier from History.Credit. |
| 3 | Occurred | datetime | NO | - | CODE-BACKED | Timestamp of the credit/debit event. |
| 4 | Amount | money | NO | - | CODE-BACKED | Cashflow amount. Positive = money in, Negative = money out. For withdrawal-funded records, uses -FundingAmount instead of TotalCashChange. |
| 5 | RealizedEquity | money | NO | - | CODE-BACKED | Customer's realized equity at the time of this credit event. ISNULL'd to 0. |
| 6 | WithdrawID | int | NO | - | CODE-BACKED | Withdrawal identifier if this credit is part of a withdrawal. ISNULL'd to 0 for non-withdrawal credits. |
| 7 | IsFee | int | NO | - | CODE-BACKED | 1 if CreditTypeID=15 (cashout fee), 0 otherwise. Flags fee transactions for separate handling in gain calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | History.Credit | READER | Reads credit/debit history for the specified customers and date range |
| LEFT JOIN | Billing.WithdrawToFunding | READER | Looks up actual funding amount for withdrawal-linked credits |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Primary cashflow data loader for gain/loss calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_LoadCashflows (procedure)
+-- History.Credit (table)
+-- Billing.WithdrawToFunding (table)
+-- Trade.Gain_CashFlowProviderCustomers (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | JOIN - main cashflow data source |
| Billing.WithdrawToFunding | Table | LEFT JOIN - actual funding amounts for withdrawals |
| Trade.Gain_CashFlowProviderCustomers | User Defined Type | TVP type for @customers parameter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Temp table: UNIQUE INDEX on #Customers(CID).

### 7.2 Constraints

None.

**Result Ordering**: Results ordered by CID, Occurred - enabling sequential processing per customer.

---

## 8. Sample Queries

### 8.1 Load Cashflows for Customers

```sql
DECLARE @custs Trade.Gain_CashFlowProviderCustomers
INSERT INTO @custs VALUES (12345, '2026-01-01')
EXEC Trade.Gain_LoadCashflows @MaxDate = '2026-03-31', @customers = @custs
```

### 8.2 View Credit Type Distribution

```sql
SELECT CreditTypeID, COUNT(*) AS Cnt, SUM(TotalCashChange) AS TotalAmount
  FROM History.Credit WITH (NOLOCK)
 WHERE CID = 12345
 GROUP BY CreditTypeID
 ORDER BY CreditTypeID
```

### 8.3 Check Withdrawal Funding Records

```sql
SELECT c.CreditID, c.WithdrawProcessingID, c.TotalCashChange,
       wf.Amount AS FundingAmount
  FROM History.Credit c WITH (NOLOCK)
  LEFT JOIN Billing.WithdrawToFunding wf WITH (NOLOCK) ON c.WithdrawProcessingID = wf.ID
 WHERE c.CID = 12345 AND c.WithdrawProcessingID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_LoadCashflows | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_LoadCashflows.sql*
