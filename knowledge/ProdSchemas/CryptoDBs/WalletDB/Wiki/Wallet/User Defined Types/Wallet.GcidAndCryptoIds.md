# Wallet.GcidAndCryptoIds

> Table-valued parameter type for passing customer-cryptocurrency pairs to bulk wallet query procedures.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`GcidAndCryptoIds` is a table-valued parameter (TVP) type that pairs a Global Customer ID (`Gcid`) with a `CryptoId`, enabling bulk wallet queries scoped to specific customer-cryptocurrency combinations. In the Wallet domain, a customer may hold wallets for multiple cryptocurrencies; a single `Gcid` alone is therefore not sufficient to identify a unique wallet context.

By passing a set of `(Gcid, CryptoId)` pairs in one TVP, procedures can retrieve or operate on the exact wallets needed for a heterogeneous batch of customers and currencies. This is common in scenarios such as multi-asset portfolio queries, balance aggregation jobs, and cross-customer reporting operations.

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
| Gcid | bigint | NOT NULL | Global Customer ID. The unique identifier for a customer in the eToro platform. |
| CryptoId | int | NOT NULL | Identifier of the cryptocurrency. Combined with Gcid to identify a specific customer wallet. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that look up or operate on wallets by customer-cryptocurrency combination, such as bulk wallet retrieval and portfolio aggregation procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.GcidAndCryptoIds`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

Both columns carry NOT NULL constraints, ensuring every row represents a fully qualified customer-crypto pair.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @pairs Wallet.GcidAndCryptoIds;
INSERT INTO @pairs (Gcid, CryptoId)
VALUES (100000001, 1),  -- Customer A, BTC
       (100000001, 2),  -- Customer A, ETH
       (100000002, 1);  -- Customer B, BTC

EXEC Wallet.GetWalletsByGcidAndCrypto @Pairs = @pairs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.GcidAndCryptoIds | Type: UDT*
