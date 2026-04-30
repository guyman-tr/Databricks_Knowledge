# Wallet.BalanceAccountIds

> Table-valued parameter type for passing a list of balance account IDs to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`BalanceAccountIds` is a table-valued parameter (TVP) type used to pass one or more balance account identifiers into stored procedures as a set. This pattern avoids the overhead of temporary tables or comma-delimited string parsing, and aligns with the SQL Server best practice of using structured TVPs for bulk input.

In the Wallet domain, a balance account ID is the unique string key that identifies an account holding a cryptocurrency balance for a customer. By accepting this type as a parameter, procedures can operate on an arbitrary list of accounts in a single, set-based call rather than row-by-row iteration.

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
| BalanceAccountId | varchar(50) | NOT NULL | Unique string identifier for a balance account. Matches the key used in the `BalanceAccount` table. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures that accept a list of balance account IDs as input, such as those retrieving or updating balances for a specific set of accounts.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.BalanceAccountIds`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `BalanceAccountId`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @ids Wallet.BalanceAccountIds;
INSERT INTO @ids (BalanceAccountId) VALUES ('ACC-001'), ('ACC-002'), ('ACC-003');

-- Pass to a stored procedure
EXEC Wallet.GetBalancesByAccountIds @AccountIds = @ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.BalanceAccountIds | Type: UDT*
