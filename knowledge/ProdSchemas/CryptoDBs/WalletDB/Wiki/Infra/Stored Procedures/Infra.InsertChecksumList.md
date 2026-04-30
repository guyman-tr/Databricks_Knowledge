# Infra.InsertChecksumList

> Batch-inserts cryptographic checksum records from a table-valued parameter into Infra.Checksum with set-based idempotent duplicate detection.

| Property | Value |
|----------|-------|
| **Schema** | Infra |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch inserts into Infra.Checksum via Infra.ChecksumType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Infra.InsertChecksumList is the batch insertion procedure for the data integrity checksum system. It accepts multiple checksum records via the Infra.ChecksumType table-valued parameter and inserts them into Infra.Checksum in a single set-based operation, skipping any records that already exist.

This procedure exists to support high-throughput checksum generation workflows. When the application processes a batch of wallet entities through the backfill pipeline (discovered by Wallet.GetWalletsWithNoChecksums, Wallet.GetWalletPoolWithNoChecksums, or Wallet.GetEtoroExternalAddressesWithNoChecksums), it generates JWT signatures for all entities in the batch and submits them through this procedure in one round-trip rather than calling InsertChecksum repeatedly.

The procedure uses a LEFT JOIN against Infra.Checksum to identify which records in the TVP are new (c.Id IS NULL) and inserts only those. This mirrors the NOT EXISTS pattern of InsertChecksum but operates on sets. SET NOCOUNT ON suppresses row-count messages for cleaner ADO.NET consumption.

---

## 2. Business Logic

### 2.1 Set-Based Idempotent Insert

**What**: Batch insertion with anti-join duplicate detection, ensuring only new checksums are persisted.

**Columns/Parameters Involved**: `@Checksums` (Infra.ChecksumType TVP)

**Rules**:
- LEFT JOINs @Checksums against Infra.Checksum on ChecksumId + ChecksumType
- Inserts only rows where c.Id IS NULL (no existing match)
- If all rows in the TVP already have checksums, the INSERT produces zero rows (no error)
- If some rows are new and some exist, only the new rows are inserted
- No error handling block - relies on SQL Server's default error propagation (unlike InsertChecksum which has TRY/CATCH)

**Diagram**:
```
@Checksums TVP (N rows)
        |
        v
  LEFT JOIN Infra.Checksum
  ON ChecksumId + ChecksumType
        |
        v
  WHERE c.Id IS NULL
  (filter to new-only)
        |
        v
  INSERT into Infra.Checksum
  (0 to N rows inserted)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Checksums | Infra.ChecksumType (READONLY) | NO | - | VERIFIED | Table-valued parameter containing the batch of checksum records to insert. Each row provides ChecksumId (entity PK as string), ChecksumType (entity category: "Wallet"/"WalletPool"/"EtoroExternalAddress"), Signature (RS256 JWT), and Created (UTC timestamp). Marked READONLY as required for TVP parameters - the procedure cannot modify the input. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Infra.Checksum | Direct write | Batch-inserts new checksum rows |
| LEFT JOIN guard | Infra.Checksum | Read (anti-join) | Reads existing records to skip duplicates |
| @Checksums type | Infra.ChecksumType | Parameter type | Uses the ChecksumType UDT to receive batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Infra.InsertChecksumList (procedure)
├── Infra.ChecksumType (type)
└── Infra.Checksum (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Infra.ChecksumType | User Defined Type | TVP parameter type for @Checksums |
| Infra.Checksum | Table | INSERT target and LEFT JOIN anti-join read |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Batch-insert checksums for multiple wallets
```sql
DECLARE @Checksums Infra.ChecksumType
INSERT INTO @Checksums (ChecksumId, ChecksumType, Signature, Created)
VALUES
    ('100', 'Wallet', 'eyJhbGciOiJSUzI1NiIs...jwt1...', GETUTCDATE()),
    ('200', 'Wallet', 'eyJhbGciOiJSUzI1NiIs...jwt2...', GETUTCDATE()),
    ('300', 'Wallet', 'eyJhbGciOiJSUzI1NiIs...jwt3...', GETUTCDATE())

EXEC Infra.InsertChecksumList @Checksums = @Checksums
```

### 8.2 Mixed-type batch insert
```sql
DECLARE @Checksums Infra.ChecksumType
INSERT INTO @Checksums (ChecksumId, ChecksumType, Signature, Created)
VALUES
    ('100', 'Wallet', 'eyJ...wallet-jwt...', GETUTCDATE()),
    ('500', 'WalletPool', 'eyJ...pool-jwt...', GETUTCDATE()),
    ('10', 'EtoroExternalAddress', 'eyJ...addr-jwt...', GETUTCDATE())

EXEC Infra.InsertChecksumList @Checksums = @Checksums
```

### 8.3 Preview which records would be inserted vs skipped
```sql
DECLARE @Checksums Infra.ChecksumType
INSERT INTO @Checksums (ChecksumId, ChecksumType, Signature, Created)
VALUES ('1572641', 'Wallet', 'test', GETUTCDATE()),
       ('9999999', 'Wallet', 'test', GETUTCDATE())

SELECT ck.ChecksumId, ck.ChecksumType,
       CASE WHEN c.Id IS NULL THEN 'WILL INSERT' ELSE 'SKIP (exists)' END AS Action
FROM @Checksums ck
    LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = ck.ChecksumId
        AND c.ChecksumType = ck.ChecksumType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Infra.InsertChecksumList | Type: Stored Procedure | Source: WalletDB/Infra/Stored Procedures/Infra.InsertChecksumList.sql*
