# Wallet.BigintListType

> Generic table-valued parameter type for passing a list of bigint values (typically IDs) to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`BigintListType` is a general-purpose table-valued parameter (TVP) type designed to carry a set of `bigint` values into stored procedures. In the Wallet domain, `bigint` is the standard data type for surrogate primary keys on large tables such as wallets, transactions, and redemptions. This type provides a reusable, schema-standard way to pass ID lists without needing custom types per entity.

By standardizing on a single generic integer-list type, the Wallet schema reduces type proliferation and makes procedure signatures easier to understand. Callers simply populate the TVP with the relevant IDs before executing the procedure.

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
| Item | bigint | NOT NULL | A single bigint value, typically a surrogate key or large numeric ID. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures throughout the `Wallet` schema that accept lists of large integer IDs as input parameters, such as bulk retrieval or bulk update procedures keyed on bigint primary keys.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.BigintListType`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `Item`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @ids Wallet.BigintListType;
INSERT INTO @ids (Item) VALUES (100001), (100002), (100003);

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByIds @WalletIds = @ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.BigintListType | Type: UDT*
