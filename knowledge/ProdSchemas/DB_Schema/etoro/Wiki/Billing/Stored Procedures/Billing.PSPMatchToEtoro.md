# Billing.PSPMatchToEtoro

> Finance reconciliation report that returns all processed payment transactions (deposits, withdrawals, chargebacks, refunds, and compensations) for a given date range, formatted for PSP-to-eToro matching.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set (no OUTPUT params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PSPMatchToEtoro` is a finance reconciliation procedure used by the Finance team to match eToro's internal transaction records against Payment Service Provider (PSP) statements. It returns all transaction activity within a date range in a unified format, combining four distinct transaction types into a single result set.

This procedure exists to enable the Finance team to perform end-of-day or period reconciliation between what eToro's database recorded and what the external PSPs (e.g., card processors, e-wallets) report. Without it, the reconciliation would require separate queries across multiple tables with complex joins.

Data flows from the procedure directly to a Finance reporting tool or export. The date filter applies differently by transaction type: deposits use first-approval date (from History.DepositAction), withdrawals use modification date, chargebacks/refunds use rollback modification date, and compensations use the occurrence date. The procedure uses `OPTION (RECOMPILE)` to avoid parameter sniffing on the date predicates.

**Note**: This is the v1 version using `History.ActiveCredit` for withdrawals. See `Billing.PSPMatchToEtoro2` for the v2 version that uses the in-memory `History.ActiveCreditBucket_VW` and includes CID-level reporting.

---

## 2. Business Logic

### 2.1 Four-Block Transaction Unification

**What**: The procedure unifies four different transaction types into a single 19-column result set for cross-comparison with PSP statements.

**Columns/Parameters Involved**: `[Transaction Type]`, `[Transaction Status]`, `Amount`, `Currency`, `[Transaction Time]`

**Rules**:
- Block 1 (Deposits): Returns approved and processed deposits. Uses `CROSS APPLY` to find the first approval date (PaymentStatusID=2) within the date window. Filters `PaymentDate > DATEADD(day, -7, @FromDate)` as a lookback buffer.
- Block 2 (Withdrawals): Returns processed cashout withdrawals (CashoutStatusID=3, CreditTypeID=2, FundingTypeID <> 27 to exclude eToroCryptoWallet). Amount returned as negative to reflect outflow.
- Block 3 (Chargebacks/Refunds/Reversals): Returns deposits that became chargebacks (11), refunds (12), refunds-as-chargebacks (26), chargeback reversals (37), or refund reversals (38). Uses `BackOffice.DepositRollbackTracking` for amounts.
- Block 4 (Compensations): Returns credit compensations with CreditTypeID=6 and CompensationReasonID IN (33, 7). Amount in USD only (no exchange rate conversion).

**Diagram**:
```
UNION ALL
  Block 1: Billing.Deposit (approved, first approval in date range)
         --> 'Deposit' as Transaction Type
  Block 2: Billing.WithdrawToFunding (CashoutStatusID=3, CreditTypeID=2)
         --> 'Withdrawal' as Transaction Type, Amount negated
  Block 3: Billing.Deposit WHERE PaymentStatusID IN (11,12,26,37,38)
         --> 'Chargeback'/'Refund'/'RefundAsChargeback'/'ChargebackReversal'/'RefundReversal'
  Block 4: History.ActiveCredit (CreditTypeID=6, CompensationReasonID IN (33,7))
         --> 'Compensations'
ORDER BY [Transaction Type]
```

### 2.2 Currency Normalization

**What**: Converts internal currency abbreviations to PSP-compatible format for matching.

**Columns/Parameters Involved**: `Currency` (derived column from `Dictionary.Currency.Abbreviation`)

**Rules**:
- USD-prefixed currencies (e.g., `USDT`) have the `USD` prefix stripped: `RIGHT(Abbreviation, LEN-3)`.
- CNH is normalized to CNY (offshore vs onshore yuan mapping).
- Standard currencies pass through unchanged.

### 2.3 PSP Status Normalization

**What**: Groups multiple eToro payment statuses into the PSP-visible status "Processed."

**Columns/Parameters Involved**: `[Transaction Status]`, `[Transaction Type]`

**Rules**:
- PaymentStatusID values 2 (approved), 12 (refund), 26 (refund-as-chargeback), 11 (chargeback), 38 (refund reversal), 37 (chargeback reversal) are all shown as "Processed."
- Other statuses use their Dictionary.PaymentStatus.Name value directly.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | YES | NULL (= yesterday UTC) | CODE-BACKED | Start of the date window. NULL defaults to GETUTCDATE()-1. Applied against first-approval date for deposits, modification date for withdrawals/refunds, and occurrence date for compensations. |
| 2 | @ToDate | DATE | YES | NULL (= today UTC) | CODE-BACKED | End of the date window (exclusive). NULL defaults to GETUTCDATE(). Applied as < @ToDate in all blocks. |

**Output Columns** (19 columns, all blocks):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Transaction Type | VARCHAR | NO | - | CODE-BACKED | Type of financial event: 'Deposit', 'Withdrawal', 'Chargeback', 'Refund', 'RefundAsChargeback', 'ChargebackReversal', 'RefundReversal', 'Compensations'. Used by Finance to categorize the PSP-matching row. |
| 4 | Transaction Status | VARCHAR | NO | - | CODE-BACKED | Normalized status. Approved/processed-class statuses (PaymentStatusID 2,11,12,26,37,38) map to 'Processed'. Other statuses use their dictionary name. |
| 5 | Amount | MONEY | YES | - | CODE-BACKED | Transaction amount in the transaction currency. Withdrawals are returned as negative in v1 (outflow). Compensations are in USD. Chargebacks/refunds use RollbackAmountInCurrency from BackOffice.DepositRollbackTracking. |
| 6 | Currency | VARCHAR | NO | - | CODE-BACKED | Normalized ISO currency code. USD-prefixed stablecoins have USD stripped (e.g., USDT -> T). CNH normalized to CNY. From Dictionary.Currency.Abbreviation. |
| 7 | Transaction Time | CHAR(10) | NO | - | CODE-BACKED | Date of the transaction in DD/MM/YYYY format. For deposits: first approval date. For withdrawals: WithdrawToFunding.ModificationDate. For refunds: DepositRollbackTracking.ModificationDate. For compensations: History.ActiveCredit.Occurred. |
| 8 | Funding Method | VARCHAR | YES | - | CODE-BACKED | Payment method name from Dictionary.FundingType (e.g., 'Credit Card', 'PayPal', 'Wire Transfer'). NULL for compensations (no funding method). |
| 9 | MID | VARCHAR | YES | - | CODE-BACKED | Merchant ID value from Billing.ProtocolMIDSettings. Identifies the specific payment gateway terminal/account used for the transaction. NULL when no ProtocolMIDSettings row exists. |
| 10 | Depot | VARCHAR | YES | - | CODE-BACKED | Processing entity/account name from Billing.Depot. Identifies which eToro legal entity processed the transaction. |
| 11 | Transaction ID | VARCHAR | NO | - | CODE-BACKED | Primary identifier for PSP matching. For deposits: DepositID cast to string. For withdrawals: WithdrawProcessingID. For chargebacks: DepositRollbackTracking.ReferenceNumber. For compensations: History.ActiveCredit.Description (free text). |
| 12 | Credit ID | VARCHAR | YES | - | CODE-BACKED | Credit record identifier. NULL for all blocks except compensations (History.ActiveCredit.CreditID). |
| 13 | External Transaction ID | VARCHAR | YES | - | CODE-BACKED | PSP-assigned transaction identifier from Billing.Deposit.ExTransactionID. NULL for withdrawals, chargebacks, and compensations. Used to cross-reference eToro records against PSP statements. |
| 14 | Verification Code | VARCHAR | YES | - | CODE-BACKED | Withdrawal verification code from Billing.WithdrawToFunding.VerificationCode. NULL for all other transaction types. |
| 15 | Payee Name | VARCHAR | YES | - | CODE-BACKED | Customer name extracted from XML FundingData: FundingData.value('/Funding[1]/CustomerNameAsString[1]'). NULL for chargebacks and compensations. |
| 16 | Regulation | VARCHAR | NO | - | CODE-BACKED | Regulatory jurisdiction of the customer from Dictionary.Regulation (e.g., 'ASIC', 'FCA', 'CySEC'). Used for regulatory segmentation in reconciliation. |
| 17 | Rollback Cancled | VARCHAR | YES | - | NAME-INFERRED | Rollback/cancellation flag. NULL in all blocks in the current implementation (placeholder column maintained for PSP file format compatibility). Note: column name has a typo ('Cancled' instead of 'Cancelled'). |
| 18 | Exchange Rate | MONEY | YES | - | CODE-BACKED | Exchange rate applied for currency conversion at time of transaction. For deposits: Billing.Deposit.ExchangeRate. For withdrawals: WithdrawToFunding.ExchangeRate. For chargebacks: DepositRollbackTracking.ExchangeRate. |
| 19 | Fee in peeps | MONEY | YES | - | CODE-BACKED | Exchange fee charged (eToro's internal fee unit). For deposits: Billing.Deposit.ExchangeFee. NULL for withdrawals (not yet sourced) and compensations. |
| 20 | CID | INT | NO | - | CODE-BACKED | Customer ID (eToro internal). From Billing.Deposit.CID or Billing.Withdraw.CID or History.ActiveCredit.CID. Used for customer-level reconciliation. |
| 21 | BaseExchangeRate | MONEY | YES | - | CODE-BACKED | Base exchange rate before fee. From Billing.Deposit.BaseExchangeRate or Billing.WithdrawToFunding.BaseExchangeRate. 1 for compensations (USD fixed). |
| 22 | Amount in USD | MONEY | YES | - | CODE-BACKED | Amount converted to USD equivalent: ExchangeRate * Amount for deposits; Amount for compensations (already USD). NULL/0 for some blocks. Used for reporting in base currency. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Deposit data | Billing.Deposit | READ | Source of deposit transactions and chargeback/refund records |
| Funding data | Billing.Funding | READ | Joined for FundingType and FundingData XML |
| Withdrawal data | Billing.Withdraw + Billing.WithdrawToFunding | READ | Source of processed withdrawal transactions |
| MID data | Billing.ProtocolMIDSettings | READ | Merchant ID for each deposit/withdrawal transaction |
| Depot data | Billing.Depot | READ | Processing entity name |
| Customer data | BackOffice.Customer | READ | Regulation lookup per customer |
| Credit history | History.ActiveCredit | READ | Links withdrawals to processing records (v1); compensations source |
| Deposit history | History.DepositAction | READ | First approval timestamp for deposit date filtering |
| Rollback data | BackOffice.DepositRollbackTracking | READ | Amounts and dates for chargebacks/refunds |
| Lookups | Dictionary.PaymentStatus, Dictionary.Currency, Dictionary.FundingType, Dictionary.Regulation | READ | Decode IDs to names |

### 5.2 Referenced By (other objects point to this)

No SQL procedure callers found. Called directly by Finance team tooling or reporting layer for PSP reconciliation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PSPMatchToEtoro (procedure)
├── Billing.Deposit (table)
├── Billing.Funding (table)
├── Billing.Withdraw (table)
├── Billing.WithdrawToFunding (table)
├── Billing.ProtocolMIDSettings (table)
├── Billing.Depot (table)
├── BackOffice.Customer (table)
├── BackOffice.DepositRollbackTracking (table)
├── History.DepositAction (table)
├── History.ActiveCredit (table)
├── History.Credit (table)
├── Dictionary.PaymentStatus (table)
├── Dictionary.Currency (table)
├── Dictionary.FundingType (table)
└── Dictionary.Regulation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source of deposit and chargeback/refund rows (Block 1 and Block 3) |
| Billing.Funding | Table | Joined for FundingTypeID and XML FundingData (payee name extraction) |
| Billing.Withdraw | Table | Source of withdrawal rows (Block 2) |
| Billing.WithdrawToFunding | Table | Processed withdrawal details: amount, exchange rate, verification code |
| Billing.ProtocolMIDSettings | Table | MID value for deposits and withdrawals |
| Billing.Depot | Table | Processing entity/depot name |
| BackOffice.Customer | Table | Customer regulation assignment |
| BackOffice.DepositRollbackTracking | Table | Rollback amounts, dates, and reference numbers for Block 3 |
| History.DepositAction | Table | First approval date for deposit date filtering (CROSS APPLY) |
| History.ActiveCredit | Table | Links withdrawals to WithdrawProcessingID; compensation data (Block 4) |
| History.Credit | Table | Links chargeback/refund credits to rollback records (Block 3) |
| Dictionary.PaymentStatus | Table | Payment status names and IDs |
| Dictionary.Currency | Table | Currency abbreviations |
| Dictionary.FundingType | Table | Funding method names |
| Dictionary.Regulation | Table | Customer regulatory jurisdiction names |

### 6.2 Objects That Depend On This

No SQL dependents found. Called externally by Finance reconciliation tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (RECOMPILE) | Query hint | Forces recompilation on each execution to generate optimal plan for the specific date parameters, avoiding parameter sniffing issues on date-range queries. |
| FundingTypeID <> 27 filter | Business filter | Excludes eToroCryptoWallet withdrawals from reconciliation (these are internal crypto transfers, not PSP transactions). |

---

## 8. Sample Queries

### 8.1 Reconcile transactions for yesterday

```sql
EXEC Billing.PSPMatchToEtoro
    @FromDate = NULL,  -- defaults to yesterday UTC
    @ToDate = NULL     -- defaults to today UTC
```

### 8.2 Reconcile a specific date range

```sql
EXEC Billing.PSPMatchToEtoro
    @FromDate = '2026-03-01',
    @ToDate = '2026-03-02'
```

### 8.3 View transaction type breakdown for a date

```sql
SELECT [Transaction Type], COUNT(*) AS TxCount, SUM([Amount in USD]) AS TotalUSD
FROM (
    EXEC Billing.PSPMatchToEtoro @FromDate = '2026-03-01', @ToDate = '2026-03-02'
) AS Results
GROUP BY [Transaction Type]
ORDER BY TxCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.PSPMatchToEtoro | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PSPMatchToEtoro.sql*
