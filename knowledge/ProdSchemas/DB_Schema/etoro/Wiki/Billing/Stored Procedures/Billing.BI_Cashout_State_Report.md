# Billing.BI_Cashout_State_Report

> BI reporting procedure that returns a unified cashout event feed for a date window, combining both standard withdrawal records (CreditTypeID=2) and cashout rollback records (CreditTypeID=33) in a single resultset, enriched with PIPsInUSD, MID details, and dynamically-resolved transaction type classification.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CID, CreditID, TransactionType, WithdrawID, WPID, CashoutStatusID, Amount, AmountInUSD, PIPsInUSD, MID, MIDName, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_Cashout_State_Report` is the primary cashout reporting feed for BI/analytics systems. It covers two types of cashout-related credit events within a date range:

1. **Withdrawals** (CreditTypeID=2 in History.ActiveCredit): standard successful cashout events where money was sent to a payment provider.
2. **Cashout Rollbacks** (CreditTypeID=33 in History.ActiveCredit): events where a previously-sent cashout was reversed or cancelled.

The two types are combined via UNION. For rollbacks, the TransactionType label is dynamically determined by looking up the payment processing action that occurred near the credit time (within a 20-second deviation window) and matching the CashoutStatusID to classify it as "CashoutRollback", "CancelledCashoutRollback", or (for reversed/partially-reversed) still "CashoutRollback".

The resultset is used by BI dashboards and reports to track cashout volumes, provider fees (PIPsInUSD), MID performance, and rollback rates.

---

## 2. Business Logic

### 2.1 Part 1: Withdrawal Records (CreditTypeID=2)

**What**: Returns one row per cashout credit event in the date window.

**Parameters/Columns Involved**: `@StartDate`, `@EndDate`, `History.ActiveCredit`, `Billing.WithdrawToFunding`

**Rules**:
- Filter: `HC.CreditTypeID = 2 AND HC.Occurred >= @StartDate AND HC.Occurred <= @EndDate`.
- JOINs: History.ActiveCredit -> Billing.WithdrawToFunding (via HC.WithdrawProcessingID = BWTF.ID) -> Billing.Funding -> Dictionary.CashoutStatus -> Billing.CurrencySettings.
- `TransactionType = 'Withdraw'` (hardcoded).
- `Amount = BWTF.RefundAmountInDepositCurrency` (amount in the customer's deposit currency).
- `AmountInUSD = BWTF.Amount` (USD-denominated amount from WithdrawToFunding).
- BaseExchangeRate: if ProcessCurrencyID != 1 (non-USD), applies IsReciprocal flag to determine direction of rate; if USD, returns 1.0.
- `PIPsInUSD = COALESCE(BWTF.ExchangeFeeInUSD, ABS(Billing.CalculateWithdrawPIPsUSD(BWTF.ID)))` - uses pre-calculated fee if available, falls back to the scalar function.
- MID/MIDName: calls `Billing.GetMIDDescription(BWTF.ID, @CashoutActionID=2)`.
- Outer GROUP BY with MAX(ModificationDate): handles multiple credit events for the same withdrawal by returning only the most recent modification timestamp.

### 2.2 Part 2: Cashout Rollback Records (CreditTypeID=33)

**What**: Returns one row per cashout rollback credit event in the date window.

**Parameters/Columns Involved**: `@StartDate`, `@EndDate`, `History.ActiveCredit`, `Billing.CashoutRollbackTracking`

**Rules**:
- Filter: `HC.CreditTypeID = 33 AND HC.Occurred >= @StartDate AND HC.Occurred <= @EndDate`.
- JOINs: History.ActiveCredit -> Billing.CashoutRollbackTracking (via CRT.CreditID = HC.CreditID) -> Billing.WithdrawToFunding -> etc.
- `TransactionType` is dynamically resolved by looking at `History.WithdrawToFundingAction` for the WithdrawToFunding record within @SeekDeviation=20 seconds of the credit event:
  - CashoutStatusID=16 (Reversed) -> 'CashoutRollback'
  - CashoutStatusID=17 (Partially Reversed) -> 'CashoutRollback'
  - CashoutStatusID=3 (CancelledCashoutRollback) -> 'CancelledCashoutRollback'
  - else -> 'CashoutRollback'
- CashoutStatus: also dynamically resolved by looking up the nearest WithdrawToFundingAction within the deviation window.
- `PIPsInUSD = ISNULL(Billing.CalculateCashoutRollbackPIPsUSD(CRT.WitdrawToFundingID, CRT.RollbackID), 0)`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | VERIFIED | Start of the reporting window (inclusive). Filters History.ActiveCredit.Occurred. |
| 2 | @EndDate | DATETIME | NO | - | VERIFIED | End of the reporting window (inclusive). Filters History.ActiveCredit.Occurred. |

**Result set columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | History.ActiveCredit | Customer ID. |
| 2 | CreditID | History.ActiveCredit | Credit event primary key. |
| 3 | TransactionType | Computed | 'Withdraw' for standard cashouts; 'CashoutRollback' or 'CancelledCashoutRollback' for rollbacks (dynamically determined from WithdrawToFundingAction). |
| 4 | PreviousStatus | Literal NULL | Not populated in this report (reserved for future use). |
| 5 | WithdrawID | WithdrawToFunding / CashoutRollbackTracking | Withdrawal record ID. |
| 6 | WPID | WithdrawToFunding.ID | Withdrawal processing leg ID. |
| 7 | DepositID | History.ActiveCredit | Associated deposit ID (for funding instrument lookup). |
| 8 | FundingID | Billing.WithdrawToFunding | Payment instrument ID. |
| 9 | DepotID | Billing.WithdrawToFunding | Payment depot/provider ID. |
| 10 | CashoutStatusID | Billing.WithdrawToFunding | Current cashout processing status. |
| 11 | CashoutStatus | Dictionary.CashoutStatus | Human-readable cashout status name. |
| 12 | Amount | BWTF.RefundAmountInDepositCurrency / CRT.RollbackAmountInCurrency | Amount in the customer's deposit currency. |
| 13 | CurrencyID | ProcessCurrencyID / CRT.CurrencyID | Currency of the amount. |
| 14 | AmountInUSD | BWTF.Amount / CRT.RollbackAmountInUSD | USD-denominated amount. |
| 15 | BaseExchangeRate | Computed (with IsReciprocal handling) | FX rate used, adjusted for reciprocal rate direction. |
| 16 | ExchangeFee | WithdrawToFunding / CashoutRollbackTracking | Provider exchange fee. |
| 17 | ExchangeRate | WithdrawToFunding / CashoutRollbackTracking | Exchange rate applied. |
| 18 | ExTransactionID | BWTF.VerificationCode / CRT.ReferenceNumber | External transaction ID from the payment provider. |
| 19 | ModificationDate | MAX(HC.Occurred) | Most recent credit event date for the group. |
| 20 | RequestDate | BWTF.CreationDate / CRT.CreateDate | Date the cashout request was created. |
| 21 | ProtocolMIDSettingsID | BWTF.ProtocolMIDSettingsID | Protocol MID settings identifier. |
| 22 | MerchantAccountID | BWTF.MerchantAccountID | Merchant account identifier. |
| 23 | PIPsInUSD | Computed | Provider interchange fee in USD. For cashouts: COALESCE(ExchangeFeeInUSD, CalculateWithdrawPIPsUSD). For rollbacks: CalculateCashoutRollbackPIPsUSD. |
| 24 | ExchaFeeInPercentage | COALESCE(ExchangeFeeInPercentage, 0) | Exchange fee as a percentage. |
| 25 | MID | Billing.GetMIDDescription | Merchant ID code from provider settings. |
| 26 | MIDName | Billing.GetMIDDescription | Human-readable merchant account name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID=2 | History.ActiveCredit | READER | Source of withdrawal credit events. |
| CreditTypeID=33 | History.ActiveCredit | READER | Source of cashout rollback credit events. |
| HC.WithdrawProcessingID | Billing.WithdrawToFunding | READER | Cashout payment leg details and amounts. |
| CRT.CreditID | Billing.CashoutRollbackTracking | READER | Cashout rollback amount and reference data. |
| BWTF.FundingID | Billing.Funding | READER | Payment instrument to verify existence. |
| DCS.CashoutStatusID | Dictionary.CashoutStatus | READER | Cashout status name resolution. |
| BCS.CurrencyID | Billing.CurrencySettings | READER | IsReciprocal flag for exchange rate direction. |
| HWTFA.BW2F_ID | History.WithdrawToFundingAction | READER | Dynamic TransactionType classification for rollbacks. |
| (func) | Billing.CalculateWithdrawPIPsUSD | EXEC (UDF) | Calculates provider fee for withdrawal legs. |
| (func) | Billing.CalculateCashoutRollbackPIPsUSD | EXEC (UDF) | Calculates provider fee for rollback legs. |
| (func) | Billing.GetMIDDescription | EXEC (UDF/TVF) | Returns MID and description for payment leg. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_Cashout_State_Report (procedure)
|- History.ActiveCredit (table)             [SELECT - cashout/rollback credit events]
|- Billing.WithdrawToFunding (table)        [JOIN - payment leg details]
|- Billing.CashoutRollbackTracking (table)  [JOIN - rollback amounts and references]
|- Billing.Funding (table)                  [JOIN - payment instrument verification]
|- Dictionary.CashoutStatus (table)         [JOIN - status name resolution]
|- Billing.CurrencySettings (table)         [LEFT JOIN - FX rate direction flag]
|- History.WithdrawToFundingAction (table)  [subquery - dynamic TransactionType for rollbacks]
|- Billing.CalculateWithdrawPIPsUSD (func)  [EXEC UDF - withdrawal PIPs calculation]
|- Billing.CalculateCashoutRollbackPIPsUSD (func) [EXEC UDF - rollback PIPs calculation]
+- Billing.GetMIDDescription (func/TVF)     [EXEC - MID and description lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | Main source for cashout (CreditTypeID=2) and rollback (CreditTypeID=33) events |
| Billing.WithdrawToFunding | Table | Payment leg amounts, exchange rates, status, depot |
| Billing.CashoutRollbackTracking | Table | Rollback amounts, currencies, reference numbers |
| Billing.Funding | Table | JOIN for payment instrument existence |
| Dictionary.CashoutStatus | Table | CashoutStatusID to name resolution |
| Billing.CurrencySettings | Table | IsReciprocal flag for exchange rate adjustment |
| History.WithdrawToFundingAction | Table | Subquery for TransactionType and CashoutStatus in rollback leg |
| Billing.CalculateWithdrawPIPsUSD | Function | Provider fee for withdrawal legs (fallback when ExchangeFeeInUSD is NULL) |
| Billing.CalculateCashoutRollbackPIPsUSD | Function | Provider fee for cashout rollback legs |
| Billing.GetMIDDescription | Function/TVF | MID code and merchant name per payment leg |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BI reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **@SeekDeviation = 20 seconds**: The procedure looks for matching WithdrawToFundingAction records within a 20-second window of the credit event to classify rollback transaction types. This tolerance accommodates slight timing differences between the credit and the payment action.
- **GROUP BY with MAX(ModificationDate)**: The first part (withdrawals) uses an outer GROUP BY to collapse multiple History.ActiveCredit rows for the same withdrawal into a single report row with the most recent date.
- **Outer parentheses pattern**: Both UNION parts are wrapped in outer parentheses `(SELECT ...) UNION (SELECT ...)` - valid T-SQL but unusual style.

---

## 8. Sample Queries

### 8.1 Run report for a specific date range
```sql
EXEC Billing.BI_Cashout_State_Report
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-17';
```

### 8.2 Run report for today
```sql
EXEC Billing.BI_Cashout_State_Report
    @StartDate = CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME),
    @EndDate   = GETUTCDATE();
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_Cashout_State_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_Cashout_State_Report.sql*
