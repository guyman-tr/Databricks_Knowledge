# Wallet.BulkStoreChecksums

> Batch-inserts checksum records for data integrity verification, skipping entries that already exist for the same record/type/version combination.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New rows in Wallet.Checksums |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure stores cryptographic checksums (hashes/signatures) for wallet data records in bulk. Checksums provide tamper detection - if a wallet address, transaction, or balance record is modified outside of normal application flow, the checksum will no longer match, alerting the system to potential data integrity issues or unauthorized changes.

Without this procedure, bulk checksum generation workflows (e.g., backfilling checksums for existing records or batch-processing new records) would need to insert one at a time, severely impacting performance.

The procedure uses the ChecksumDataType TVP for efficient batch input and performs idempotent inserts - skipping any checksum that already exists for the same ChecksumTypeId + RecordId + SecretVersion combination.

---

## 2. Business Logic

### 2.1 Idempotent Batch Insert

**What**: Prevents duplicate checksums for the same record/type/version.

**Columns/Parameters Involved**: `ChecksumTypeId`, `RecordId`, `SecretVersion`

**Rules**:
- WHERE NOT EXISTS check on (ChecksumTypeId, RecordId, SecretVersion) triple
- Allows different secret versions for the same record (key rotation support)
- Silent skip on duplicates (no error)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Checksums | Wallet.ChecksumDataType (READONLY) | NO | - | CODE-BACKED | Table-valued parameter containing checksum records. Columns: ChecksumTypeId (type of data being checksummed), RecordId (ID of the record being protected), SecretVersion (key version used), Salt (random salt), Checksum (the hash value), Signature (cryptographic signature). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Wallet.Checksums | Writer | Inserts checksum records |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application checksum services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.BulkStoreChecksums (procedure)
  ├── Wallet.Checksums (table)
  └── Wallet.ChecksumDataType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Checksums | Table | INSERT target + duplicate check |
| Wallet.ChecksumDataType | User Defined Type | Table-valued parameter |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- READONLY modifier on TVP

---

## 8. Sample Queries

### 8.1 View checksums for a specific record
```sql
SELECT Id, ChecksumTypeId, RecordId, SecretVersion, Salt, Checksum, Signature
FROM Wallet.Checksums WITH (NOLOCK)
WHERE RecordId = 12345
ORDER BY ChecksumTypeId, SecretVersion
```

### 8.2 Checksum counts by type
```sql
SELECT ChecksumTypeId, COUNT(*) AS Cnt
FROM Wallet.Checksums WITH (NOLOCK)
GROUP BY ChecksumTypeId
```

### 8.3 Find records missing checksums (example for a type)
```sql
SELECT wa.Id
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.RecordId = wa.Id AND c.ChecksumTypeId = 1
WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.BulkStoreChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.BulkStoreChecksums.sql*
