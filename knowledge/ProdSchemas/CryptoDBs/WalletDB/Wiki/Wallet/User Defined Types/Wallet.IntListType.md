# Wallet.IntListType

> Generic table-valued parameter type for passing a list of integer values to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`IntListType` is a general-purpose table-valued parameter (TVP) type that carries a set of standard 32-bit integer values into stored procedures. It mirrors the role of `BigintListType` but for entities whose primary keys or identifiers fit within the `int` range (up to approximately 2.1 billion). In the Wallet domain this covers entities such as crypto types, status codes, instrument IDs, and other reference data whose IDs are managed as `int`.

Having a dedicated generic list type avoids the need to create entity-specific types for every procedure that needs to accept a filtered set of integer IDs. Procedures can use this type for any int-keyed entity, making the schema more maintainable.

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
| Item | int | NOT NULL | A single integer value, typically a surrogate key or reference code. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures throughout the `Wallet` schema that accept lists of integer IDs as input parameters for filtering or bulk operations.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.IntListType`.

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
DECLARE @ids Wallet.IntListType;
INSERT INTO @ids (Item) VALUES (1), (2), (5), (10);

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByCryptoIds @CryptoIds = @ids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.IntListType | Type: UDT*
