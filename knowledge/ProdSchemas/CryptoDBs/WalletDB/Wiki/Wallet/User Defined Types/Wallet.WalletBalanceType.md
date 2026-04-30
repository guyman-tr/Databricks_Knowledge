# Wallet.WalletBalanceType

> Table-valued parameter type for passing provider-sourced balance updates including timestamp and crypto context to sync procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`WalletBalanceType` is a table-valued parameter (TVP) type used to convey balance data sourced from an external cryptocurrency provider (e.g., a custodian or exchange API) into the Wallet database. It differs from the `CurrentBalanceType` family in that it identifies wallets by their provider-assigned wallet ID (`ProviderWalletId`) rather than the internal `BalanceAccountID`, and includes a precise `BalanceDateTime` timestamp indicating exactly when the balance was observed by the provider.

This type is consumed by provider synchronization procedures that reconcile the internal view of wallet balances against what the provider reports. The timestamp allows the procedure to reject or flag stale updates and to build an accurate audit trail of how balances evolved over time. The `decimal(36,18)` precision on `Balance` accommodates the full range of cryptocurrency amounts without rounding.

---

## 2. Business Logic

N/A for table-valued parameter type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| ProviderWalletId | varchar(256) | NOT NULL | The wallet identifier as assigned and used by the external provider. May differ from internal wallet keys. |
| CryptoId | int | NOT NULL | Internal cryptocurrency identifier for the asset whose balance is being reported. |
| Balance | decimal(36,18) | NOT NULL | The balance amount reported by the provider. Full 18-decimal precision for crypto amounts. |
| BalanceDateTime | datetime2(7) | NOT NULL | UTC timestamp at which the provider observed this balance. Used to detect and reject stale updates. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Provider synchronization stored procedures in the `Wallet` schema that reconcile external balance feeds with the internal wallet balance records.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.WalletBalanceType`, typically provider-sync or balance-reconciliation procedures.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

All four columns carry NOT NULL constraints, ensuring that every balance update row is fully qualified with a provider wallet reference, crypto context, balance value, and observation timestamp.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @providerBalances Wallet.WalletBalanceType;
INSERT INTO @providerBalances (ProviderWalletId, CryptoId, Balance, BalanceDateTime)
VALUES
    ('PROV-WALLET-001', 1, 0.512340000000000000, '2026-04-15T10:30:00.0000000'),
    ('PROV-WALLET-002', 2, 3.141592653589793000, '2026-04-15T10:30:00.0000000');

-- Pass to provider sync procedure
EXEC Wallet.SyncProviderBalances @Balances = @providerBalances;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.WalletBalanceType | Type: UDT*
