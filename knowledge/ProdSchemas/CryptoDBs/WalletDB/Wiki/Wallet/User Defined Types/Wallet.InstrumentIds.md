# Wallet.InstrumentIds

> Table-valued parameter type for passing a list of instrument IDs to stored procedures for filtering or bulk operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`InstrumentIds` is a table-valued parameter (TVP) type used to supply a set of instrument identifiers to stored procedures in the Wallet schema. An instrument in the eToro/Wallet context represents a tradeable asset — which may map to a specific cryptocurrency or financial product. `InstrumentId` is the integer key used to identify instruments in the platform's instrument catalogue.

Procedures that need to filter wallet data, transaction records, or pricing information by instrument can accept this type to receive the desired instrument set as a structured parameter. This avoids dynamic SQL construction and supports set-based operations with appropriate index utilization.

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
| InstrumentId | int | NOT NULL | Integer identifier for a tradeable instrument. References the instrument lookup in the platform catalogue. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures in the `Wallet` schema that filter or aggregate data by instrument ID, such as price feed procedures or instrument-scoped wallet queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that declares a parameter of type `Wallet.InstrumentIds`.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None beyond the NOT NULL constraint on `InstrumentId`.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @instruments Wallet.InstrumentIds;
INSERT INTO @instruments (InstrumentId) VALUES (1001), (1002), (1007);

-- Pass to a stored procedure
EXEC Wallet.GetWalletsByInstruments @InstrumentIds = @instruments;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.InstrumentIds | Type: UDT*
