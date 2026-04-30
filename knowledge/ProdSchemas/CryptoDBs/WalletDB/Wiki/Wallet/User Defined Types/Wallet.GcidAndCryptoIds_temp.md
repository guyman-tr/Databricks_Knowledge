# Wallet.GcidAndCryptoIds_temp

> Memory-optimized table-valued parameter type for high-performance bulk wallet queries by customer-cryptocurrency pair, with an index on Gcid.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`GcidAndCryptoIds_temp` is the memory-optimized variant of `Wallet.GcidAndCryptoIds`. It serves the same business purpose — passing a batch of Global Customer ID / cryptocurrency pairs to stored procedures — but is declared `WITH (MEMORY_OPTIMIZED = ON)`, which enables it to be used as a table-valued parameter in natively compiled stored procedures and dramatically reduces memory-to-disk overhead for high-throughput scenarios.

The `CryptoId` column uses `tinyint` instead of `int`, reflecting a design decision to reduce the memory footprint of each row in the in-memory structure. This type is intended for latency-sensitive code paths where the overhead of disk-based table types would be measurable, such as real-time wallet look-ups at scale.

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
| Gcid | bigint | NOT NULL | Global Customer ID. Indexed for fast look-up within the in-memory structure. |
| CryptoId | tinyint | NOT NULL | Cryptocurrency identifier. Uses tinyint (vs int in GcidAndCryptoIds) to minimize per-row memory usage. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Natively compiled or memory-sensitive stored procedures in the `Wallet` schema that require the performance characteristics of a memory-optimized TVP for customer-crypto pair lookups.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any natively compiled stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.GcidAndCryptoIds_temp`.

---

## 7. Technical Details

### 7.1 Indexes

- **Non-clustered hash index on `Gcid`** — provided by the memory-optimized table definition. Enables O(1) average-case lookup of rows by customer ID within the TVP when joining inside a natively compiled procedure.

### 7.2 Constraints

Both columns carry NOT NULL constraints. The type is declared `WITH (MEMORY_OPTIMIZED = ON)`, meaning it can only be used in sessions or procedures that support In-Memory OLTP.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
-- Requires a database with In-Memory OLTP enabled
DECLARE @pairs Wallet.GcidAndCryptoIds_temp;
INSERT INTO @pairs (Gcid, CryptoId)
VALUES (100000001, 1),  -- Customer A, BTC
       (100000001, 2),  -- Customer A, ETH (tinyint)
       (100000002, 1);  -- Customer B, BTC

-- Pass to a natively compiled procedure
EXEC Wallet.GetWalletsByGcidAndCrypto_Fast @Pairs = @pairs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.GcidAndCryptoIds_temp | Type: UDT*
