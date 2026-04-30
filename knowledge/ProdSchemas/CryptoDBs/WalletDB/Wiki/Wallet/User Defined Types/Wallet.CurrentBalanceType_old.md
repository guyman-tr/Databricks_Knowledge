# Wallet.CurrentBalanceType_old

> Legacy table-valued parameter type for bulk balance updates — predecessor to CurrentBalanceType, without the CryptoId column.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`CurrentBalanceType_old` is the legacy version of the balance update TVP type. It predates the introduction of multi-currency support in the Wallet schema. In this older version, a balance record is identified only by its `BalanceAccountID`, with no cryptocurrency dimension — an implicit assumption that each account held a single asset.

This type has been superseded by `Wallet.CurrentBalanceType`, which adds the `CryptoId` column to support multi-asset wallets. `CurrentBalanceType_old` is retained for backward compatibility with older procedures or application code paths that have not yet migrated to the current type. New development should use `Wallet.CurrentBalanceType` instead.

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
| Balance | decimal(19,10) | NOT NULL | The current balance amount for the account. High precision supports fractional crypto values. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Legacy stored procedures in the `Wallet` schema that have not yet migrated to `Wallet.CurrentBalanceType`. Any procedure still referencing this type should be considered a candidate for migration.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Legacy procedures in the `Wallet` schema that accept a parameter of type `Wallet.CurrentBalanceType_old`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

Both columns carry NOT NULL constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
-- Legacy usage — prefer Wallet.CurrentBalanceType for new code
DECLARE @balances Wallet.CurrentBalanceType_old;
INSERT INTO @balances (BalanceAccountID, Balance)
VALUES ('ACC-001', 0.0512340000),
       ('ACC-002', 1.2500000000);

-- Pass to a legacy stored procedure
EXEC Wallet.AddWalletsBalances_old @Balances = @balances;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.CurrentBalanceType_old | Type: UDT*
