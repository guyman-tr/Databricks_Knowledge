# Billing.PSPMatchToEtoro2

> Finance reconciliation report (v2) returning all processed payment transactions for a date range for PSP-to-eToro matching - uses the in-memory History.ActiveCreditBucket_VW for improved performance on withdrawals and refunds.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set (no OUTPUT params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PSPMatchToEtoro2` is the v2 evolution of `Billing.PSPMatchToEtoro` - a Finance reconciliation procedure that returns all transaction activity within a date range for PSP-to-eToro matching. It serves the same purpose: enabling the Finance team to cross-check eToro's internal records against PSP statements.

The primary upgrade from v1 is the substitution of `History.ActiveCreditBucket_VW` (an in-memory-optimized view) in place of `History.ActiveCredit` and `History.Credit` for the withdrawal and refund blocks respectively. This was introduced on 03/01/2021 (Shay Oren) to improve query performance using the in-memory architecture. A secondary difference is that withdrawal amounts are returned as positive values (v1 negated them), and the deposit date filter is slightly tighter (no 7-day lookback buffer).

The v2 output returns 16 columns (compared to v1's 19) - it omits CID, BaseExchangeRate, and Amount in USD, making it suitable for contexts where those fields are not needed by the Finance recipient.

---

## 2. Business Logic

### 2.1 Four-Block Transaction Unification

**What**: Same 4-block UNION ALL structure as v1, but with performance and data differences.

**Columns/Parameters Involved**: `[Transaction Type]`, Amount, Currency, `[Transaction Time]`

**Rules**:
- Block 1 (Deposits): Same as v1 but deposit lookback uses `BD.PaymentDate > @FromDate` (no 7-day buffer). Stricter date filtering.
- Block 2 (Withdrawals): Uses `History.ActiveCreditBucket_VW` instead of `History.ActiveCredit`. Amount returned as POSITIVE (v1 negated it for outflow representation).
- Block 3 (Chargebacks/Refunds): Uses `History.ActiveCreditBucket_VW` instead of `History.Credit`. Uses `TotalRollbackAmountInCurrency` (v1 used `RollbackAmountInCurrency` for most statuses).
- Block 4 (Compensations): Identical to v1.

**Diagram**:
```
v1 vs v2 key differences:
  Withdrawal: History.ActiveCredit  --> History.ActiveCreditBucket_VW (in-memory)
  Refund:     History.Credit        --> History.ActiveCreditBucket_VW (in-memory)
  Withdrawal Amount: -1 * Amount    --> Amount (positive, no negation)
  Deposit filter: PaymentDate > DATEADD(-7, @FromDate) --> PaymentDate > @FromDate
  Refund amount: RollbackAmountInCurrency --> TotalRollbackAmountInCurrency
  Output columns: 19               --> 16 (no CID, BaseExchangeRate, Amount in USD)
```

### 2.2 In-Memory Table Usage

**What**: Performance optimization using eToro's in-memory bucket view.

**Columns/Parameters Involved**: History.ActiveCreditBucket_VW (external dependency)

**Rules**:
- `History.ActiveCreditBucket_VW` is a memory-optimized view/table that provides faster access to recent credit history records.
- Used for the withdrawal block (CreditTypeID=2, CashoutStatusID=3) and refund/chargeback block (CreditTypeID IN 11,12,26,37,38).
- Trade-off: limited to "recent" data in the bucket; for older date ranges, v1 (History.ActiveCredit/Credit) may be required.

### 2.3 Currency Normalization

**What**: Same as v1 - converts internal currency abbreviations to PSP-compatible format.

**Rules**:
- USD-prefixed stablecoins have the `USD` prefix stripped (e.g., USDT -> T).
- CNH normalized to CNY.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | YES | NULL (= yesterday UTC) | CODE-BACKED | Start of the date window. NULL defaults to GETUTCDATE()-1. Applied against first-approval date for deposits, modification date for withdrawals/refunds, occurrence date for compensations. v2 uses stricter deposit filter (PaymentDate > @FromDate, no 7-day buffer). |
| 2 | @ToDate | DATE | YES | NULL (= today UTC) | CODE-BACKED | End of the date window (exclusive). NULL defaults to GETUTCDATE(). |

**Output Columns** (16 columns - note: no CID, BaseExchangeRate, Amount in USD vs v1):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Transaction Type | VARCHAR | NO | - | CODE-BACKED | Type of event: 'Deposit', 'Withdrawal', 'Chargeback', 'Refund', 'RefundAsChargeback', 'ChargebackReversal', 'RefundReversal', 'Compensations'. |
| 4 | Transaction Status | VARCHAR | NO | - | CODE-BACKED | Normalized status. PaymentStatusID IN (2,11,12,26,37,38) = 'Processed'. |
| 5 | Amount | MONEY | YES | - | CODE-BACKED | Transaction amount in transaction currency. NOTE: withdrawals returned as POSITIVE values in v2 (unlike v1 which negates them). Compensations in USD. |
| 6 | Currency | VARCHAR | NO | - | CODE-BACKED | ISO currency code, normalized (USD-prefix stripped, CNH->CNY). From Dictionary.Currency.Abbreviation. |
| 7 | Transaction Time | CHAR(10) | NO | - | CODE-BACKED | DD/MM/YYYY formatted date. For deposits: first approval date. For withdrawals: ModificationDate. For refunds: rollback ModificationDate. For compensations: Occurred. |
| 8 | Funding Method | VARCHAR | YES | - | CODE-BACKED | Payment method name from Dictionary.FundingType. NULL for compensations. |
| 9 | MID | VARCHAR | YES | - | CODE-BACKED | Merchant ID value from Billing.ProtocolMIDSettings. NULL when not present. |
| 10 | Depot | VARCHAR | YES | - | CODE-BACKED | Processing entity name from Billing.Depot. |
| 11 | Transaction ID | VARCHAR | NO | - | CODE-BACKED | PSP matching key. DepositID / WithdrawProcessingID / RollbackTracking.ReferenceNumber / Credit.Description. |
| 12 | Credit ID | VARCHAR | YES | - | CODE-BACKED | NULL for all blocks except compensations (History.ActiveCredit.CreditID). |
| 13 | External Transaction ID | VARCHAR | YES | - | CODE-BACKED | PSP external reference from Billing.Deposit.ExTransactionID. NULL for non-deposit blocks. |
| 14 | Verification Code | VARCHAR | YES | - | CODE-BACKED | Withdrawal verification code from Billing.WithdrawToFunding. NULL for other blocks. |
| 15 | Payee Name | VARCHAR | YES | - | CODE-BACKED | Customer name from XML FundingData (/Funding[1]/CustomerNameAsString[1]). NULL for chargebacks and compensations. |
| 16 | Regulation | VARCHAR | NO | - | CODE-BACKED | Customer regulatory jurisdiction from Dictionary.Regulation. |
| 17 | Rollback Cancled | VARCHAR | YES | - | NAME-INFERRED | Rollback/cancellation flag column. NULL in all current blocks. Column name contains a typo ('Cancled'). Maintained for output format compatibility. |
| 18 | Exchange Rate | MONEY | YES | - | CODE-BACKED | Exchange rate at transaction time. From Deposit.ExchangeRate, WithdrawToFunding.ExchangeRate, or DepositRollbackTracking.ExchangeRate. |
| 19 | Fee in peeps | MONEY | YES | - | CODE-BACKED | eToro exchange fee (Billing.Deposit.ExchangeFee). NULL for withdrawals and compensations. Note: v2 refund block also returns this field (same as v1). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | READ | Deposits and chargeback source |
| Funding data | Billing.Funding | READ | FundingType and XML payee name |
| Withdrawal data | Billing.Withdraw, Billing.WithdrawToFunding | READ | Withdrawal transactions |
| MID data | Billing.ProtocolMIDSettings | READ | Merchant ID |
| Credit history (v2) | History.ActiveCreditBucket_VW | READ | In-memory view for withdrawals and refund/chargeback records |
| Compensation data | History.ActiveCredit | READ | Compensation transactions (Block 4 only) |
| Rollback data | BackOffice.DepositRollbackTracking | READ | Chargeback/refund amounts |
| Lookups | Dictionary.PaymentStatus, Dictionary.Currency, Dictionary.FundingType, Dictionary.Regulation | READ | Decode IDs to names |

### 5.2 Referenced By (other objects point to this)

No SQL procedure callers found. Called directly by Finance team tooling.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PSPMatchToEtoro2 (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
├── Billing.ProtocolMIDSettings (table)
├── Billing.Depot (table)
├── BackOffice.Customer (table)
├── BackOffice.DepositRollbackTracking (table)
├── History.DepositAction (table)
├── History.ActiveCreditBucket_VW (view - in-memory)
├── History.ActiveCredit (table - compensations only)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Currency (table)
├── Dictionary.FundingType (table)
└── Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Deposit and chargeback/refund source |
| Billing.Funding | Table | FundingType and XML FundingData |
| Billing.Withdraw | Table | Withdrawal records |
| Billing.WithdrawToFunding | Table | Processed withdrawal details |
| Billing.ProtocolMIDSettings | Table | Merchant ID per transaction |
| Billing.Depot | Table | Processing entity name |
| BackOffice.Customer | Table | Customer regulation lookup |
| BackOffice.DepositRollbackTracking | Table | Chargeback/refund amounts and references |
| History.DepositAction | Table | First deposit approval date (CROSS APPLY) |
| History.ActiveCreditBucket_VW | View | In-memory credit history for withdrawals and refunds (v2 optimization) |
| History.ActiveCredit | Table | Compensation records (Block 4) |
| Dictionary.PaymentStatus | Table | Status names |
| Dictionary.Currency | Table | Currency abbreviations |
| Dictionary.FundingType | Table | Funding method names |
| Dictionary.Regulation | Table | Regulatory jurisdiction names |

### 6.2 Objects That Depend On This

No SQL dependents found. Called by Finance reconciliation tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces recompile per execution for optimal date-range plans. |
| FundingTypeID <> 27 | Business filter | Excludes eToroCryptoWallet from withdrawal reconciliation. |

---

## 8. Sample Queries

### 8.1 Reconcile transactions for yesterday (v2, in-memory optimized)

```sql
EXEC Billing.PSPMatchToEtoro2
    @FromDate = NULL,
    @ToDate = NULL
```

### 8.2 Specific date range reconciliation

```sql
EXEC Billing.PSPMatchToEtoro2
    @FromDate = '2026-03-01',
    @ToDate = '2026-03-02'
```

### 8.3 Compare v1 vs v2 output for a given date

```sql
-- Run both versions and compare counts/amounts
EXEC Billing.PSPMatchToEtoro  @FromDate = '2026-03-01', @ToDate = '2026-03-02'
EXEC Billing.PSPMatchToEtoro2 @FromDate = '2026-03-01', @ToDate = '2026-03-02'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 related analyzed (PSPMatchToEtoro v1) | App Code: skipped | Corrections: 0 applied*
*Object: Billing.PSPMatchToEtoro2 | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PSPMatchToEtoro2.sql*
