# BackOffice.GetUserStatementTransactionList

> Returns the full transaction history for a customer as a unified statement - combining deposits, bonuses, adjustments, trade P/L, withdrawals, fees, and chargebacks from History.Credit into a single chronological list.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (required); returns History.Credit rows for 10 transaction types as a unified statement |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`GetUserStatementTransactionList` produces a customer account statement by pulling all credit events from `History.Credit` across 10 distinct CreditTypeIDs, unioning them into a single result set. This is used by Back Office to show a complete financial history for a customer: every deposit, bonus, trade close, withdrawal request/cancellation, fee, and chargeback in a single ordered list. The statement mirrors what a customer would see in their transaction history on the platform.

The procedure uses 10 UNION ALL branches, each filtering on a different CreditTypeID or set of CreditTypeIDs from History.Credit, with different display labels for the [Type] column. Each branch also derives appropriate [Details] and [Amount] values from linked tables.

---

## 2. Business Logic

### 2.1 Transaction Type Classification

**What**: Maps CreditTypeIDs to human-readable transaction types.

**Columns/Parameters Involved**: `[Type]`, `CreditTypeID`, `TotalCashChange`

**Rules** (10 UNION ALL branches):
- CreditTypeID=1 -> 'Deposit' (with amount+currency+funding type as Details)
- CreditTypeID IN (5,7) -> 'Bonus' (with BonusType name for specific BonusTypeIDs)
- CreditTypeID=6 -> 'Adjustment' (no details)
- CreditTypeID=4 -> 'Profit/Loss of Trade' (with instrument name as Details, Amount = History.Position.NetProfit)
- CreditTypeID=9 -> 'Withdraw Request' (Details = '-')
- CreditTypeID=8 -> 'Withdraw Request Cancelled' (Details = '-')
- CreditTypeID=15 AND TotalCashChange <= 0 -> 'Withdraw Fee'
- CreditTypeID=15 AND TotalCashChange >= 0 AND CashoutStatusID=4 -> 'Withdraw Fee Cancelled'
- CreditTypeID=14 -> 'Over Weekend Fee' (holding/rollover fee)
- CreditTypeID IN (11,12,16):
  - 11 + TotalCashChange < 0 -> 'Charge Back'
  - 12 + TotalCashChange < 0 -> 'Refund'
  - 16 + TotalCashChange < 0 -> 'Refund as Charge Back'
  - 11 + TotalCashChange > 0 -> 'Cancelled Charge Back'
  - 12 + TotalCashChange > 0 -> 'Cancelled Refund'
  - 16 + TotalCashChange > 0 -> 'Cancelled Refund as Charge Back'
  - TotalCashChange = 0 excluded (AND TotalCashChange != 0)

### 2.2 Bonus Type Details Filtering

**What**: Only shows bonus type name for specific bonus types; others show empty string.

**Columns/Parameters Involved**: `Details` (Bonus branch), `BackOffice.BonusType.BonusTypeID`, `BBNT.Name`

**Rules**:
- BonusTypeID IN (2,4,5,7,11,23,28,42,43,46,47,48,49) -> show BonusType.Name
- All other BonusTypeIDs -> '' (empty string Details)

### 2.3 Trade P/L Amount Source

**What**: For trade close transactions, Amount comes from History.Position.NetProfit rather than History.Credit.TotalCashChange.

**Columns/Parameters Involved**: `Amount` (Profit/Loss branch), `History.Position.NetProfit`

**Rules**:
- CAST(HPOS.NetProfit AS DECIMAL(16,2)) - the net profit/loss of the closed position
- JOIN History.Position ON PositionID AND CID
- JOIN Trade.GetInstrument for instrument name in Details

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID to retrieve statement for. Required. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Time | DATETIME | NO | - | CODE-BACKED | Timestamp of the transaction (History.Credit.Occurred). Ordered by CreditID ASC. |
| 2 | Type | NVARCHAR | NO | - | VERIFIED | Transaction type label derived from CreditTypeID (and TotalCashChange for fees/chargebacks). Values: Deposit, Bonus, Adjustment, Profit/Loss of Trade, Withdraw Request, Withdraw Request Cancelled, Withdraw Fee, Withdraw Fee Cancelled, Over Weekend Fee, Charge Back, Refund, Refund as Charge Back, Cancelled Charge Back, Cancelled Refund, Cancelled Refund as Charge Back. |
| 3 | Details | NVARCHAR | YES | - | CODE-BACKED | Contextual details for the transaction. Deposit: 'Amount Currency FundingType'. Bonus: BonusType name (for selected BonusTypeIDs). Profit/Loss: instrument name. Chargebacks: OldPaymentID or DepositID. Withdraw types: '-'. Adjustment/Fees: empty string. |
| 4 | TransactionID | INT | NO | - | CODE-BACKED | Primary key from History.Credit (CreditID). Used as unique row identifier. |
| 5 | Amount | DECIMAL(16,2) | YES | - | CODE-BACKED | Transaction amount. For most types: History.Credit.TotalCashChange. For Profit/Loss of Trade: History.Position.NetProfit. Negative for charges/fees, positive for credits. |
| 6 | Credit | DECIMAL | YES | - | CODE-BACKED | Customer's account balance after this transaction (History.Credit.Credit). Running balance snapshot. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HCRD.CID = @CID | History.Credit | Read (driving, 10 branches) | All transaction credit records |
| HCRD.DepositID | Billing.Deposit | LEFT JOIN | Deposit amount and FundingID for Details |
| BDEP.FundingID | Billing.Funding | LEFT JOIN | FundingTypeID for funding method name |
| BFUN.FundingTypeID | Dictionary.FundingType | LEFT JOIN | Funding method name |
| BDEP.CurrencyID | Dictionary.Currency | LEFT JOIN | Currency abbreviation |
| HCRD.BonusTypeID | BackOffice.BonusType | LEFT JOIN | Bonus type name for statement |
| HCRD.PositionID | History.Position | JOIN | Trade NetProfit for P/L transactions |
| HPOS.InstrumentID | Trade.GetInstrument | JOIN | Instrument name for P/L details |
| HCRD.WithdrawID | Billing.Withdraw | JOIN (x3) | Withdraw request/cancel/fee transactions |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BO customer statement screen) | @CID | Application | Customer financial statement display |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetUserStatementTransactionList (procedure)
├── History.Credit (table) - driving (10 UNION branches)
├── Billing.Deposit (table) - deposit branch
├── Billing.Funding (table) - deposit branch
├── Dictionary.FundingType (table) - deposit branch
├── Dictionary.Currency (table) - deposit branch
├── BackOffice.BonusType (table) - bonus branch
├── History.Position (table) - P/L branch
├── Trade.GetInstrument (view/TVF) - P/L branch instrument name
└── Billing.Withdraw (table) - withdraw/fee branches
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | All 10 UNION branches - CreditTypeID filter per branch |
| Billing.Deposit | Table | Deposit amount and funding details |
| Billing.Funding | Table | FundingTypeID for method name |
| Dictionary.FundingType | Table | Payment method name |
| Dictionary.Currency | Table | Currency abbreviation |
| BackOffice.BonusType | Table | Bonus type name for selected BonusTypeIDs |
| History.Position | Table | NetProfit for P/L transactions |
| Trade.GetInstrument | View/TVF | Instrument name for P/L |
| Billing.Withdraw | Table | WithdrawID linkage for withdraw/fee/cancel branches |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called by BO customer statement screens. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 10 UNION ALL branches | Performance | All branches query History.Credit separately. No CreditTypeID index hint. Performance depends on History.Credit index coverage for CID + CreditTypeID. |
| ORDER BY CreditID ASC | Semantic | Ordered by CreditID (not Occurred) - CreditID is monotonically increasing so this approximates chronological order. |
| Withdraw Fee split | Logic | CreditTypeID=15 appears in two branches: negative TotalCashChange = 'Withdraw Fee'; positive + CashoutStatusID=4 = 'Withdraw Fee Cancelled'. |
| Bonus details filtering | Logic | Only 13 specific BonusTypeIDs show names - others are blanked, likely for display privacy or because those bonus types don't have meaningful display names. |

---

## 8. Sample Queries

### 8.1 Get full statement for a customer
```sql
EXEC BackOffice.GetUserStatementTransactionList @CID = 123456
```

### 8.2 Get only deposit and withdrawal events
```sql
SELECT [Time], [Type], Details, Amount, Credit
FROM (
    SELECT HCRD.Occurred AS [Time],
           'Deposit' AS [Type],
           HCRD.CreditID AS TransactionID,
           HCRD.TotalCashChange AS Amount,
           HCRD.Credit
    FROM History.Credit HCRD WITH (NOLOCK)
    WHERE HCRD.CreditTypeID = 1 AND HCRD.CID = 123456
    UNION ALL
    SELECT HCRD.Occurred, 'Withdraw Request', HCRD.CreditID, HCRD.TotalCashChange, HCRD.Credit
    FROM History.Credit HCRD WITH (NOLOCK)
    WHERE HCRD.CreditTypeID = 9 AND HCRD.CID = 123456
) T ORDER BY TransactionID ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetUserStatementTransactionList | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetUserStatementTransactionList.sql*
