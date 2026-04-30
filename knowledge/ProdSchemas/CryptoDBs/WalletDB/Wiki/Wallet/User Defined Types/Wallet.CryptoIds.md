# Wallet.CryptoIds

> Table-valued parameter type for passing a list of cryptocurrency IDs to stored procedures for filtering.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`CryptoIds` is a table-valued parameter (TVP) type used to supply a set of cryptocurrency identifiers to stored procedures. In the Wallet domain, each supported cryptocurrency (Bitcoin, Ethereum, etc.) is assigned an integer `CryptoId`. Procedures that operate across multiple cryptocurrencies — such as those retrieving wallet balances or filtering transactions — use this type to accept the desired crypto IDs as a structured set.

Passing a TVP of crypto IDs is more efficient and type-safe than alternatives such as comma-delimited strings or dynamic SQL. It also integrates naturally with set-based JOIN operations inside the receiving procedure, enabling clean, index-friendly filtering.

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
| CryptoId | int | NOT NULL | Integer identifier for a supported cryptocurrency. References the crypto lookup table. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that filter results by one or more cryptocurrency IDs, such as balance retrieval and wallet query procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.CryptoIds`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `CryptoId`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @cryptos Wallet.CryptoIds;
INSERT INTO @cryptos (CryptoId) VALUES (1), (2), (5); -- e.g. BTC, ETH, LTC

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByCryptos @CryptoIds = @cryptos;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.CryptoIds | Type: UDT*
