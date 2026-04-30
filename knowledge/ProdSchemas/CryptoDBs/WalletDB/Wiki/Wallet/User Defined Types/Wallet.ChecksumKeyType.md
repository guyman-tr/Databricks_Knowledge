# Wallet.ChecksumKeyType

> Table-valued parameter type for looking up checksum records by composite key (ChecksumTypeId + RecordId).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`ChecksumKeyType` is a table-valued parameter (TVP) type that carries the minimum information needed to identify and retrieve a specific checksum record: the type of checksum and the ID of the record it covers. The combination of `ChecksumTypeId` and `RecordId` forms a composite lookup key that uniquely identifies a checksum entry in the checksum storage table.

This type is used by procedures that need to verify or retrieve existing checksums for a batch of records. Instead of querying one record at a time, callers populate the TVP with all the keys they need and pass the set to the procedure in a single call. This is particularly important in integrity-check workflows where many records must be validated simultaneously.

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
| ChecksumTypeId | tinyint | NOT NULL | Identifies the category or algorithm of the checksum. Part of the composite lookup key. |
| RecordId | varchar(128) | NOT NULL | The identifier of the record whose checksum is being looked up. Supports string-form keys. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- Stored procedures that retrieve or validate checksum records by composite key, such as integrity verification procedures in the `Wallet` schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- Any stored procedure in the `Wallet` schema that accepts a parameter of type `Wallet.ChecksumKeyType` for checksum lookup operations.

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

Both columns carry NOT NULL constraints, enforcing that a complete composite key is always provided.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @keys Wallet.ChecksumKeyType;
INSERT INTO @keys (ChecksumTypeId, RecordId)
VALUES (1, 'REC-0001'),
       (1, 'REC-0002'),
       (2, 'REC-0005');

-- Pass to a procedure that retrieves or validates checksums
EXEC Wallet.GetChecksumsByKeys @Keys = @keys;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.ChecksumKeyType | Type: UDT*
