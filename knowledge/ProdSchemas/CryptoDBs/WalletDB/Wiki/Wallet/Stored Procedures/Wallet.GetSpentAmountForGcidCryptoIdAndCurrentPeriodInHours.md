# Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours

> Convenience wrapper that resolves a customer's wallet from Gcid + CryptoId, then delegates to GetSpentAmountForWalletIdAndCurrentPeriodInHours to calculate rolling-period spending for limit enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar spent amount by Gcid + CryptoId + period |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a convenience wrapper for `Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours`. While the inner procedure requires a WalletId, many callers only have the customer's Gcid and CryptoId. This wrapper resolves the customer's wallet ID from `Wallet.CustomerWalletsView` and then delegates to the inner procedure for the actual spending calculation.

Four services consume this: the balance service (real-time limit checks using customer + crypto as the natural lookup key), the AML service (spending velocity monitoring per customer per crypto), the conversion service (checking spending before conversion operations), and the back-office API (operational spending inquiries by customer). This customer-centric interface is more natural for most callers than the wallet-centric inner procedure.

---

## 2. Business Logic

### 2.1 Wallet Resolution and Delegation

**What**: Resolves the customer's wallet ID and delegates the spending calculation to the inner procedure.

**Columns/Parameters Involved**: `@Gcid`, `@CryptoId`, `CustomerWalletsView`

**Rules**:
- Looks up WalletId from CustomerWalletsView WHERE Gcid = @Gcid AND CryptoId = @CryptoId
- If no wallet exists, @WalletId will be NULL, and the inner procedure returns 0 (no transactions for NULL wallet)
- Passes @WalletId, @PeriodInHours, @CryptoId, and @TransactionTypeId to the inner EXEC
- All spending calculation logic (rolling window, failed transaction exclusion, transaction type filtering) is in the inner procedure

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID identifying the customer. Used to resolve their wallet for the specified crypto. |
| 2 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency to check spending for. FK to Wallet.CryptoTypes. Combined with Gcid to resolve the specific wallet. |
| 3 | @PeriodInHours | decimal(10,4) | NO | - | VERIFIED | Rolling time window in hours. Supports fractional hours (e.g., 24.0 = daily, 168.0 = weekly). Passed directly to the inner procedure. |
| 4 | @TransactionTypeId | tinyint | YES | 1 | VERIFIED | Transaction type filter. Default 1=CustomerMoneyOut. When NULL, includes all types. Passed directly to the inner procedure. See [Transaction Type](../../_glossary.md#transaction-type). |
| 5 | (scalar result) | decimal(36,18) | NO | 0 | CODE-BACKED | Total amount spent in the rolling period. Delegated from GetSpentAmountForWalletIdAndCurrentPeriodInHours. Returns 0 when no qualifying transactions or wallet not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid + @CryptoId | Wallet.CustomerWalletsView | Lookup | Resolves the customer's WalletId |
| - | Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours | EXEC | Delegates spending calculation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Pre-conversion spending limit check |
| BalanceUser | - | EXECUTE | Real-time spending limit enforcement |
| AmlUser | - | EXECUTE | Spending velocity monitoring |
| BackApiUser | - | EXECUTE | Operational spending inquiries |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours (procedure)
      +-- Wallet.SentTransactions (table)
      +-- Wallet.SentTransactionOutputs (table)
      +-- Wallet.SentTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Resolves WalletId from Gcid + CryptoId |
| Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours | Stored Procedure | Delegates spending calculation via EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser | Service Account | EXECUTE grant |
| BalanceUser | Service Account | EXECUTE grant |
| AmlUser | Service Account | EXECUTE grant |
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check daily spending for a customer's BTC
```sql
EXEC Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours
    @Gcid = 30351701,
    @CryptoId = 1,
    @PeriodInHours = 24.0;
```

### 8.2 Check weekly spending across all transaction types
```sql
EXEC Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours
    @Gcid = 30351701,
    @CryptoId = 1,
    @PeriodInHours = 168.0,
    @TransactionTypeId = NULL;  -- All types
```

### 8.3 Compare with direct wallet-based call
```sql
-- This SP does this internally:
DECLARE @WalletId VARCHAR(100) = (
    SELECT Id FROM Wallet.CustomerWalletsView
    WHERE Gcid = 30351701 AND CryptoId = 1
);
EXEC Wallet.GetSpentAmountForWalletIdAndCurrentPeriodInHours
    @WalletId = @WalletId,
    @PeriodInHours = 24.0,
    @CryptoId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetSpentAmountForGcidCryptoIdAndCurrentPeriodInHours.sql*
