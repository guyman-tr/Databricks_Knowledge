# dbo.TempGetWalletPoolChecksums

> Temporary staging table for wallet pool (omnibus) integrity checksums, covering 1.6M+ pool wallet records for data tamper detection.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on Id) |

---

## 1. Business Meaning

This table stages integrity checksum records for wallet pool (omnibus) wallets. Pool wallets are shared infrastructure wallets that hold crypto assets on behalf of multiple customers, as opposed to individually-assigned customer wallets. Each row contains a cryptographic checksum and signature for a pool wallet record, enabling verification that the data has not been tampered with.

With 1,654,449 rows, this is the largest of all checksum staging tables -- even larger than TempGetWalletChecksums (1M+ rows). The higher count reflects the volume of pool wallet addresses across all supported blockchains. The checksum verification pattern (SecretVersion/Salt/Checksum/Signature) is shared across the family of integrity tables. Unlike TempGetWalletChecksums, this table does not include a Gcid column since pool wallets are not directly owned by individual customers.

PAGE compression is enabled to manage the significant storage footprint. No stored procedures directly reference this table.

---

## 2. Business Logic

### 2.1 Checksum Integrity Pattern

**What**: Each row contains a cryptographic checksum and signature computed over the pool wallet record's identifying fields, using a versioned secret and random salt.

**Columns/Parameters Involved**: `WalletId`, `BlockchainProviderWalletId`, `Address`, `SecretVersion`, `Salt`, `Checksum`, `Signature`

**Rules**:
- The pool wallet's identity fields (WalletId, BlockchainProviderWalletId, Address) are the data being integrity-checked
- No Gcid column because pool wallets are omnibus (shared), not customer-specific
- SecretVersion identifies which cryptographic key version was used to generate the checksum
- Salt provides randomness; Checksum is the computed hash; Signature provides tamper-evidence

---

## 3. Data Overview

| Id | WalletId | Address | Occurred | Meaning |
|----|----------|---------|----------|---------|
| (sample) | a1b2c3d4-... | 0x7a250d... | 2024-03-01 | Ethereum pool wallet integrity checksum for omnibus address |
| (sample) | e5f6g7h8-... | bc1qw508... | 2024-03-01 | Bitcoin pool wallet integrity checksum record |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for this checksum record, likely corresponding to the source pool wallet record's ID. |
| 2 | WalletId | uniqueidentifier | YES | - | CODE-BACKED | The pool wallet's unique GUID identifier. Maps to the wallet pool record in the Wallet schema. |
| 3 | BlockchainProviderWalletId | nvarchar(100) | YES | - | CODE-BACKED | The wallet identifier assigned by the blockchain infrastructure provider (e.g., Fireblocks vault ID) for this pool wallet. Part of the data being integrity-checked. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | The blockchain public address of the pool (omnibus) wallet. Format varies by crypto network. Part of the data being integrity-checked. |
| 5 | SecretVersion | varchar(255) | YES | - | CODE-BACKED | Version identifier of the cryptographic key/secret used to compute the checksum. Enables key rotation without invalidating existing checksums. |
| 6 | Salt | nvarchar(255) | YES | - | CODE-BACKED | Random salt value used in checksum computation. Ensures identical data produces different checksums across records. |
| 7 | Checksum | varbinary(max) | YES | - | CODE-BACKED | Computed cryptographic hash of the pool wallet record's data fields. Used to detect unauthorized modifications to pool wallet data. |
| 8 | Signature | varbinary(max) | YES | - | CODE-BACKED | Cryptographic signature over the checksum, providing tamper-evidence. Can be verified using the corresponding SecretVersion key. |
| 9 | Occurred | date | YES | - | CODE-BACKED | Date when the checksum was computed or when the source pool wallet record was created/modified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED (PK) | Id | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (PK) | PRIMARY KEY | Clustered PK on Id -- ensures unique checksum records |

### 7.3 Compression

PAGE compression is enabled on this table.

---

## 8. Sample Queries

### 8.1 Count pool wallet checksums
```sql
SELECT COUNT(*) AS ChecksumCount
FROM dbo.TempGetWalletPoolChecksums WITH (NOLOCK)
```

### 8.2 Find checksums for a specific pool wallet
```sql
SELECT Id, WalletId, BlockchainProviderWalletId, Address, Occurred
FROM dbo.TempGetWalletPoolChecksums WITH (NOLOCK)
WHERE WalletId = 'a1b2c3d4-0000-0000-0000-000000000000'
```

### 8.3 Check for records with missing integrity data
```sql
SELECT Id, WalletId, Address
FROM dbo.TempGetWalletPoolChecksums WITH (NOLOCK)
WHERE Checksum IS NULL OR Signature IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TempGetWalletPoolChecksums | Type: Table | Source: WalletDB/dbo/Tables/dbo.TempGetWalletPoolChecksums.sql*
