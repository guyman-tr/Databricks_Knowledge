# Wallet.CurrentBalanceType

> Table-valued parameter type used by AddWalletsBalances to update multiple account balances in a single bulk operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`CurrentBalanceType` is a table-valued parameter (TVP) type that carries current balance data for one or more wallet accounts. It is the current, active version of the balance update input type, distinguishing it from its legacy predecessor `CurrentBalanceType_old` by the inclusion of the `CryptoId` column. This allows balance updates to be cryptocurrency-aware, supporting wallets that may hold multiple crypto assets.

The type is used by `Wallet.AddWalletsBalances` to receive a batch of balance records from the application tier. By accepting the full set in one TVP, the procedure can perform a single bulk upsert rather than multiple individual calls, significantly reducing latency and lock contention during high-frequency balance refresh operations.

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
| BalanceAccountID | varchar(50) | NOT NULL | Unique string identifier for the balance account being updated. |
| CryptoId | int | NULL | Identifier of the cryptocurrency this balance refers to. NULL may indicate a legacy or default crypto context. |
| Balance | decimal(19,10) | NOT NULL | The current balance amount for the account and crypto combination. Uses high precision to accommodate fractional crypto amounts. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- `Wallet.AddWalletsBalances` — bulk balance upsert procedure that consumes this type to update the current balance for a set of accounts.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- `Wallet.AddWalletsBalances`

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

- `BalanceAccountID` and `Balance` are NOT NULL.
- `CryptoId` is nullable, preserving backward compatibility with callers that do not supply a crypto context.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @balances Wallet.CurrentBalanceType;
INSERT INTO @balances (BalanceAccountID, CryptoId, Balance)
VALUES ('ACC-001', 1,  0.0512340000),
       ('ACC-002', 2,  1.2500000000),
       ('ACC-003', 1, 10.0000000000);

EXEC Wallet.AddWalletsBalances @Balances = @balances;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.CurrentBalanceType | Type: UDT*
