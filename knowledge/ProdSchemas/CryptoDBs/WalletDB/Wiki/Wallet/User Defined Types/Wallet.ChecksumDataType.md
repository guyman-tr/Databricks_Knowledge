# Wallet.ChecksumDataType

> Table-valued parameter type used by BulkStoreChecksums to insert multiple checksum records in a single operation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | N/A (table-valued parameter) |

---

## 1. Business Meaning

`ChecksumDataType` is a table-valued parameter (TVP) type that carries all fields required to store cryptographic checksum records in bulk. In the Wallet domain, checksums are used to verify the integrity and authenticity of sensitive records — for example, wallet balances or transaction outputs — by storing a cryptographic hash and optional signature alongside each record.

This type allows the `BulkStoreChecksums` procedure to accept a complete set of checksum rows from the application layer in one round-trip, avoiding repeated single-row inserts. Each row contains the type of checksum, the record it applies to, secret versioning metadata, salting data, the checksum hash itself, and an optional asymmetric signature.

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
| ChecksumTypeId | tinyint | NULL | Identifies the category or algorithm of the checksum (e.g., SHA-256, HMAC). Foreign key concept to a checksum type lookup. |
| RecordId | varchar(128) | NULL | The identifier of the record this checksum belongs to. Supports string-form keys such as GUIDs or composite IDs. |
| SecretVersion | varchar(255) | NULL | Version label of the secret or signing key used to produce the checksum, enabling key rotation without invalidating old records. |
| Salt | nvarchar(255) | NULL | Random or deterministic salt value incorporated into the checksum computation to prevent rainbow-table attacks. |
| Checksum | varbinary(max) | NULL | The raw binary checksum or hash value computed over the target record. |
| Signature | varbinary(max) | NULL | Optional asymmetric cryptographic signature over the checksum, providing non-repudiation. |

---

## 5. Relationships

### 5.1 References To

N/A for UDT.

### 5.2 Referenced By

- `Wallet.BulkStoreChecksums` — primary consumer; passes the TVP rows into the checksum storage table in a single bulk insert.

---

## 6. Dependencies

### 6.0 Dependency Chain

No dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

- `Wallet.BulkStoreChecksums`

---

## 7. Technical Details

### 7.1 Indexes

None. Standard (non-memory-optimized) table type.

### 7.2 Constraints

None. All columns are nullable, giving callers flexibility to omit fields that are not applicable for a given checksum type.

---

## 8. Sample Queries

### 8.1 Declare and populate

```sql
DECLARE @checksums Wallet.ChecksumDataType;
INSERT INTO @checksums
    (ChecksumTypeId, RecordId, SecretVersion, Salt, Checksum, Signature)
VALUES
    (1, 'REC-0001', 'v2', N'randomsalt1', 0xDEADBEEF, NULL),
    (1, 'REC-0002', 'v2', N'randomsalt2', 0xCAFEBABE, 0xABCDEF00);

EXEC Wallet.BulkStoreChecksums @Checksums = @checksums;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 7.5/10*
*Object: Wallet.ChecksumDataType | Type: UDT*
