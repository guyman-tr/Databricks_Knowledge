# Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours

> Calculates the total crypto amount spent from a specific wallet within a rolling time window, excluding failed/error transactions, used for spending limit enforcement and AML monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar sum of spent amounts in a rolling period |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates the total amount of cryptocurrency sent from a specific wallet within a configurable rolling time window. It sums the output amounts from `SentTransactionOutputs` for all qualifying transactions, excluding those in terminal failure states (Error=4, PermanentError=5, WavedError=6). This spending total is the foundation for the platform's spending limit enforcement system.

Four services consume this procedure: the balance service (real-time limit checks before allowing sends), the AML service (monitoring spending velocity for suspicious activity), the billing notification service (fee calculations based on volume), and the back-office API (operational spending inquiries). The procedure is also called indirectly by `Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours`, which first resolves a customer+crypto pair to a WalletId, then delegates here.

The rolling window is specified in hours with decimal precision (e.g., 24.0 for daily, 168.0 for weekly), converted internally to minutes via multiplication by 60. Only transactions with a non-failure latest status are included, ensuring that failed sends don't inflate the spending total.

---

## 2. Business Logic

### 2.1 Rolling Window Spending Calculation

**What**: Sums all non-failed transaction output amounts within a configurable time window from the current moment.

**Columns/Parameters Involved**: `@WalletId`, `@PeriodInHours`, `@CryptoId`, `@TransactionTypeId`

**Rules**:
- Time filter: `Occurred > DATEADD(MINUTE, -@PeriodInHours*60, GETDATE())`
- Converts hours to minutes for DATEADD precision (supports fractional hours like 0.5 = 30 min)
- Sums SentTransactionOutputs.Amount (not the transaction-level amount, but per-output amounts)
- Returns 0 when no qualifying transactions exist (ISNULL wrapper)

### 2.2 Failed Transaction Exclusion

**What**: Excludes transactions in terminal failure states from the spending total.

**Columns/Parameters Involved**: `SentTransactionStatuses.StatusId`

**Rules**:
- Gets latest status via correlated subquery: `SELECT TOP 1 StatusId ORDER BY Occurred DESC`
- Excludes StatusId IN (4, 5, 6): Timeout, PermanentError, WavedError
- Includes StatusId IN (0, 1, 2, 3): Pending, Confirmed, Verified, Error (active error may still resolve)
- ISNULL fallback to 0 (Pending) when no status exists yet
- Rationale: failed transactions didn't actually move funds on-chain, so they shouldn't count against spending limits

### 2.3 Transaction Type Filtering

**What**: Optionally restricts the calculation to a specific transaction type.

**Columns/Parameters Involved**: `@TransactionTypeId`, `SentTransactions.TransactionTypeId`

**Rules**:
- Default value is 1 (CustomerMoneyOut) - customer withdrawals
- When NULL, includes all transaction types (ISNULL pattern)
- Allows callers to calculate spending for specific operation types (e.g., only customer sends, or only conversions)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | varchar(80) | NO | - | VERIFIED | The wallet to calculate spending for. Matched against SentTransactions.WalletId. Accepts varchar despite WalletId being uniqueidentifier - implicit conversion handles this. |
| 2 | @PeriodInHours | decimal(10,4) | NO | - | VERIFIED | Rolling time window in hours from the current moment. Supports fractional hours (e.g., 0.5 = 30 minutes, 24.0 = 1 day, 168.0 = 1 week). Converted to minutes internally. |
| 3 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency filter. When non-NULL, limits to transactions of this specific crypto. When NULL (via ISNULL pattern), includes all cryptos. FK to Wallet.CryptoTypes. |
| 4 | @TransactionTypeId | tinyint | YES | 1 | VERIFIED | Transaction type filter. Default 1=CustomerMoneyOut. When NULL, includes all types. See [Transaction Type](../../_glossary.md#transaction-type). |
| 5 | (scalar result) | decimal(36,18) | NO | 0 | CODE-BACKED | Total amount spent in the rolling period. Sum of SentTransactionOutputs.Amount for qualifying transactions. Returns 0 when no qualifying transactions exist. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId | Wallet.SentTransactions.WalletId | Lookup | Identifies the wallet's transactions |
| Amount | Wallet.SentTransactionOutputs | JOIN | Source of per-output amounts to sum |
| StatusId filter | Wallet.SentTransactionStatuses | Subquery | Latest status for failed-transaction exclusion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours | - | Caller (EXEC) | Resolves Gcid+CryptoId to WalletId then delegates here |
| BalanceUser | - | EXECUTE | Real-time spending limit checks |
| AmlUser | - | EXECUTE | Spending velocity monitoring for AML |
| BillingNotificationUser | - | EXECUTE | Volume-based fee calculations |
| BackApiUser | - | EXECUTE | Operational spending inquiries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionOutputs (table)
|     +-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
      +-- Wallet.SentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | JOINed as primary transaction source, filtered by WalletId/CryptoId/TransactionType/date |
| Wallet.SentTransactionOutputs | Table | JOINed for per-output amounts to sum |
| Wallet.SentTransactionStatuses | Table | Correlated subquery to exclude failed transactions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours | Stored Procedure | Calls via EXEC after resolving WalletId |
| BalanceUser | Service Account | EXECUTE grant |
| AmlUser | Service Account | EXECUTE grant |
| BillingNotificationUser | Service Account | EXECUTE grant |
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Relies on SentTransactions indexes on WalletId and CryptoId.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check spending in the last 24 hours for a wallet
```sql
EXEC Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours
    @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678',
    @PeriodInHours = 24.0,
    @CryptoId = 1;  -- BTC
```

### 8.2 Check weekly spending across all transaction types
```sql
EXEC Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours
    @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678',
    @PeriodInHours = 168.0,
    @CryptoId = 1,
    @TransactionTypeId = NULL;  -- All types
```

### 8.3 Direct equivalent query
```sql
SELECT ISNULL(
    (SELECT SUM(sto.Amount)
     FROM Wallet.SentTransactions st WITH (NOLOCK)
         JOIN Wallet.SentTransactionOutputs sto WITH (NOLOCK) ON sto.SentTransactionId = st.Id
     WHERE st.WalletId = 'C0D5EF83-...'
         AND st.CryptoId = 1
         AND st.Occurred > DATEADD(MINUTE, -24.0*60, GETDATE())
         AND st.TransactionTypeId = 1
         AND ISNULL(
             (SELECT TOP 1 sts.StatusId FROM Wallet.SentTransactionStatuses sts
              WHERE sts.SentTransactionId = st.Id ORDER BY sts.Occurred DESC), 0)
             NOT IN (4, 5, 6)
    ), 0);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours.sql*
