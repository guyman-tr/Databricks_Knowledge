# Wallet.GetChecksums

> Stored procedure that retrieves the most recent checksum records for a set of checksum keys, supporting integrity verification of wallet data.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns latest Wallet.Checksums per key |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetChecksums retrieves the most recent checksum/signature records for a batch of requested keys. The wallet system uses checksums to verify the integrity of critical data (wallet addresses, balances, transaction records). Each checksum record stores a cryptographic hash, salt, signature, and secret version, allowing the application to detect if data has been tampered with.

The procedure accepts a table-valued parameter of `Wallet.ChecksumKeyType` (ChecksumTypeId, RecordId pairs) and returns the most recent checksum for each key, using ROW_NUMBER partitioned by key and ordered by Occurred DESC.

---

## 2. Business Logic

### 2.1 Most Recent Checksum Selection

**What**: For each requested (ChecksumTypeId, RecordId) pair, returns only the most recent checksum record.

**Columns/Parameters Involved**: `@ChecksumKeyTypes`, Wallet.Checksums

**Rules**:
- JOINs the input TVP to Wallet.Checksums on ChecksumTypeId and RecordId
- Uses ROW_NUMBER partitioned by (ChecksumTypeId, RecordId), ordered by Occurred DESC
- Filters to RowNum = 1 (most recent per key)
- Uses NOLOCK on Checksums table

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ChecksumKeyTypes | Wallet.ChecksumKeyType | NO | - | CODE-BACKED | Table-valued parameter containing (ChecksumTypeId, RecordId) pairs to look up. Each pair identifies a specific data record type and instance to verify. |
| 2 | ChecksumTypeId | int | NO | - | CODE-BACKED | Type of data being checksummed (e.g., wallet address, balance, transaction). From Wallet.Checksums. |
| 3 | RecordId | bigint | NO | - | CODE-BACKED | The specific record ID within that checksum type. Together with ChecksumTypeId forms the composite lookup key. |
| 4 | SecretVersion | int | YES | - | CODE-BACKED | Version of the cryptographic secret used to generate this checksum. Supports key rotation. |
| 5 | Salt | varbinary | YES | - | CODE-BACKED | Random salt used in the checksum computation for uniqueness. |
| 6 | Checksum | varbinary | YES | - | CODE-BACKED | The computed cryptographic hash of the protected data. |
| 7 | Signature | varbinary | YES | - | CODE-BACKED | Digital signature for additional integrity verification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ChecksumKeyTypes | Wallet.ChecksumKeyType | Parameter TVP | Input type defining the keys to look up |
| - | Wallet.Checksums | JOIN | Checksum data source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Integrity verification services | - | EXEC | Data integrity checks on wallet records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetChecksums (procedure)
+-- Wallet.Checksums (table)
+-- Wallet.ChecksumKeyType (user defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Checksums | Table | JOIN with NOLOCK - checksum data |
| Wallet.ChecksumKeyType | User Defined Type | Table-valued parameter type |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up checksums for specific records
```sql
DECLARE @keys Wallet.ChecksumKeyType
INSERT INTO @keys (ChecksumTypeId, RecordId) VALUES (1, 12345), (1, 12346), (2, 67890)
EXEC Wallet.GetChecksums @ChecksumKeyTypes = @keys
```

### 8.2 See all checksum types
```sql
SELECT DISTINCT ChecksumTypeId, COUNT(*) AS RecordCount
FROM Wallet.Checksums WITH (NOLOCK)
GROUP BY ChecksumTypeId
```

### 8.3 Latest checksum for a single record
```sql
SELECT TOP 1 ChecksumTypeId, RecordId, SecretVersion, Salt, Checksum, Signature
FROM Wallet.Checksums WITH (NOLOCK)
WHERE ChecksumTypeId = 1 AND RecordId = 12345
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetChecksums.sql*
