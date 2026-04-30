# Wallet.Checksums

> Stores cryptographic checksums and digital signatures for wallet-related records, providing tamper detection and data integrity verification for compliance and security purposes.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table stores cryptographic checksums and digital signatures for critical wallet records. Each row contains a hash (checksum) and signature for a specific record, identified by its type and ID. If a record is tampered with after the checksum was computed, the checksum verification will fail, alerting the system to potential data corruption or unauthorized modification.

With ~2.94M rows, this table covers checksums for wallet pools (ChecksumTypeId=1) and individual wallets (ChecksumTypeId=2). The checksums use salted hashing with versioned secrets, enabling key rotation without invalidating existing checksums. This is a core security and compliance feature ensuring the integrity of financial records.

Rows are created by `Wallet.StoreChecksum` and `Wallet.BulkStoreChecksums` procedures. Verification is performed by `Wallet.GetChecksums`, `Wallet.GetWalletChecksums`, and `Wallet.GetWalletPoolChecksums`. The system periodically validates checksums via background jobs to detect any data integrity issues.

---

## 2. Business Logic

### 2.1 Salted Hash with Versioned Secrets

**What**: Each checksum uses a unique random salt and a versioned secret key, enabling secure key rotation.

**Columns/Parameters Involved**: `Salt`, `SecretVersion`, `Checksum`, `Signature`

**Rules**:
- Each record gets a unique random Salt (GUID) to prevent rainbow table attacks
- SecretVersion identifies which encryption key was used (enables key rotation)
- Checksum is a 64-byte hash of the record's critical fields + salt + secret
- Signature is a larger (~512 byte) digital signature providing non-repudiation
- Key rotation: when the secret is rotated, new checksums use the new version; old checksums remain valid under their original secret version

### 2.2 Record Type Classification

**What**: Checksums are scoped to different record types via ChecksumTypeId.

**Columns/Parameters Involved**: `ChecksumTypeId`, `RecordId`

**Rules**:
- ChecksumTypeId=1 (WalletPool): Checksums for pool wallet records (Wallet.WalletPool.Id)
- ChecksumTypeId=2 (Wallet): Checksums for customer wallet records
- See [Checksum Type](../../_glossary.md#checksum-type). FK to Dictionary.ChecksumTypes.
- RecordId is a string reference to the target record's primary key
- Unique constraint on (SecretVersion, RecordId, ChecksumTypeId) prevents duplicate checksums

---

## 3. Data Overview

| Id | ChecksumTypeId | RecordId | SecretVersion (truncated) | Meaning |
|---|---|---|---|---|
| 3077705 | 1 (WalletPool) | 1774509 | 47b35fe8... | Checksum for wallet pool record #1774509. Verifies the pool wallet's data hasn't been altered. |
| 3077702 | 2 (Wallet) | 1254257 | 47b35fe8... | Checksum for customer wallet record #1254257. All use the same SecretVersion, indicating no recent key rotation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | ChecksumTypeId | tinyint | NO | - | VERIFIED | Type of record this checksum protects: 1=WalletPool, 2=Wallet, 3=StakingAddress, 4=EtoroExternalAddress. See [Checksum Type](../../_glossary.md#checksum-type). FK to Dictionary.ChecksumTypes. |
| 3 | RecordId | varchar(128) | NO | - | CODE-BACKED | String representation of the target record's primary key. For WalletPool checksums, this is the WalletPool.Id. Part of unique constraint. |
| 4 | SecretVersion | varchar(255) | NO | - | CODE-BACKED | Identifier of the encryption key version used to compute this checksum. Enables key rotation - when the secret is changed, the new version is used for new checksums while old ones remain verifiable under their original version. |
| 5 | Salt | nvarchar(255) | NO | - | CODE-BACKED | Unique random salt (GUID format) added to the hash input. Prevents rainbow table attacks and ensures identical records produce different checksums. |
| 6 | Checksum | varbinary(max) | NO | - | CODE-BACKED | Cryptographic hash (64 bytes) computed from the record's critical fields combined with the salt and secret. Used for fast integrity verification. |
| 7 | Signature | varbinary(max) | NO | - | CODE-BACKED | Digital signature (~512 bytes) computed using an asymmetric key. Provides non-repudiation - proves the checksum was created by the authorized system, not forged. |
| 8 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this checksum was computed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChecksumTypeId | Dictionary.ChecksumTypes | FK | Identifies the type of record being checksummed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.StoreChecksum | - | Writer | Creates individual checksums |
| Wallet.BulkStoreChecksums | - | Writer | Bulk creates checksums |
| Wallet.GetChecksums | - | Reader | Reads checksums for verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (FK targets are Dictionary tables).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ChecksumTypes | Table | FK target for ChecksumTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.StoreChecksum | Stored Procedure | Inserts checksums |
| Wallet.BulkStoreChecksums | Stored Procedure | Bulk inserts checksums |
| Wallet.GetChecksums | Stored Procedure | Reads checksums for verification |
| Wallet.GetWalletChecksums | Stored Procedure | Reads wallet-specific checksums |
| Wallet.GetWalletPoolChecksums | Stored Procedure | Reads pool wallet checksums |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK__Checksums | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Checksums_ChecksumTypeId_RecordId | NC | ChecksumTypeId, RecordId | Checksum, Occurred, Salt, SecretVersion, Signature | - | Active |
| IX_Wallet_Checksums_RecordId_ChecksumTypeId_SecretVersion | NC UNIQUE | SecretVersion, RecordId, ChecksumTypeId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_Checksums_Occurred | DEFAULT | getutcdate() |
| FK_Wallet_Checksums_ChecksumTypesId_Dictionary_ChecksumTypes_Id | FK | ChecksumTypeId -> Dictionary.ChecksumTypes.Id |

---

## 8. Sample Queries

### 8.1 Get checksum for a specific wallet pool record
```sql
SELECT Id, ChecksumTypeId, RecordId, SecretVersion, Occurred
FROM Wallet.Checksums WITH (NOLOCK)
WHERE ChecksumTypeId = 1 AND RecordId = '1774509'
```

### 8.2 Count checksums by type
```sql
SELECT ct.Name AS ChecksumType, COUNT(*) AS ChecksumCount
FROM Wallet.Checksums c WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id
GROUP BY ct.Name
```

### 8.3 Find records missing checksums (wallet pool)
```sql
SELECT wp.Id AS WalletPoolId
FROM Wallet.WalletPool wp WITH (NOLOCK)
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.RecordId = CAST(wp.Id AS varchar(128)) AND c.ChecksumTypeId = 1
WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Checksums | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Checksums.sql*
