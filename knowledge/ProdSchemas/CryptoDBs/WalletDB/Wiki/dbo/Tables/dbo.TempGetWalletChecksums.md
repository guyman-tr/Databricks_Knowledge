# dbo.TempGetWalletChecksums

> Temporary staging table for wallet record integrity checksums, the largest checksum table with 1M+ rows covering customer wallet data integrity verification.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on Id) |

---

## 1. Business Meaning

This table stages integrity checksum records for customer wallets. Each row contains a cryptographic checksum and signature computed over a wallet record's core data fields (WalletId, Gcid, BlockchainProviderWalletId, Address), enabling verification that wallet data has not been tampered with. With 1,061,374 rows, this is the largest of the checksum staging tables, reflecting the full scope of customer wallet records.

The checksum verification pattern (SecretVersion/Salt/Checksum/Signature) is shared across a family of integrity tables: TempGetEtoroExternalAddressChecksums, TempGetStakingChecksums, and TempGetWalletPoolChecksums. This table has a known (but commented-out) reference in the stored procedure `Wallet.Job_LogicApp_Fill_TempGetWalletChecksums`, which was designed to populate this table. The commented-out state suggests the integrity verification job may have been disabled or is being reworked.

PAGE compression is enabled to manage the significant storage footprint of 1M+ rows with varbinary(max) columns.

---

## 2. Business Logic

### 2.1 Checksum Integrity Pattern

**What**: Each row contains a cryptographic checksum and signature computed over the wallet record's identifying fields, using a versioned secret and random salt.

**Columns/Parameters Involved**: `WalletId`, `Gcid`, `BlockchainProviderWalletId`, `Address`, `SecretVersion`, `Salt`, `Checksum`, `Signature`

**Rules**:
- The wallet's identity fields (WalletId, Gcid, BlockchainProviderWalletId, Address) are the data being integrity-checked
- SecretVersion identifies which cryptographic key version was used to generate the checksum
- Salt provides randomness to prevent rainbow table attacks on the checksum
- Checksum is the computed hash -- any modification to the source wallet data would produce a different checksum
- Signature provides tamper-evidence and non-repudiation

---

## 3. Data Overview

| Id | WalletId | Gcid | Address | Occurred | Meaning |
|----|----------|------|---------|----------|---------|
| (sample) | a1b2c3d4-... | 20267280 | 0x3f5CE... | 2024-03-01 | Ethereum wallet integrity checksum for a specific customer |
| (sample) | e5f6g7h8-... | 7311046 | bc1q7cy... | 2024-03-01 | Bitcoin wallet integrity checksum record |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for this checksum record, likely corresponding to the source wallet record's ID. |
| 2 | WalletId | uniqueidentifier | YES | - | CODE-BACKED | The wallet's unique GUID identifier. Maps to the wallet record in the Wallet schema (e.g., Wallet.CustomerWallets.WalletId). |
| 3 | Gcid | bigint | YES | - | CODE-BACKED | Global Customer ID. The eToro customer who owns this wallet. Used to correlate checksums back to customer context. |
| 4 | BlockchainProviderWalletId | nvarchar(100) | YES | - | CODE-BACKED | The wallet identifier assigned by the blockchain infrastructure provider (e.g., Fireblocks vault ID). Part of the data being integrity-checked. |
| 5 | Address | nvarchar(512) | YES | - | CODE-BACKED | The blockchain public address associated with the wallet. Format varies by crypto network. Part of the data being integrity-checked. |
| 6 | SecretVersion | varchar(255) | YES | - | CODE-BACKED | Version identifier of the cryptographic key/secret used to compute the checksum. Enables key rotation without invalidating existing checksums. |
| 7 | Salt | nvarchar(255) | YES | - | CODE-BACKED | Random salt value used in checksum computation. Ensures identical data produces different checksums across records. |
| 8 | Checksum | varbinary(max) | YES | - | CODE-BACKED | Computed cryptographic hash of the wallet record's data fields. Used to detect unauthorized modifications to wallet data. |
| 9 | Signature | varbinary(max) | YES | - | CODE-BACKED | Cryptographic signature over the checksum, providing tamper-evidence. Can be verified using the corresponding SecretVersion key. |
| 10 | Occurred | date | YES | - | CODE-BACKED | Date when the checksum was computed or when the source wallet record was created/modified. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Object | Schema | Type | Relationship | Status |
|--------|--------|------|-------------|--------|
| Wallet.Job_LogicApp_Fill_TempGetWalletChecksums | Wallet | Stored Procedure | Populates this table | Commented out |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no active dependencies (reference is commented out).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | Dependency Type | Status |
|--------|------|----------------|--------|
| Wallet.Job_LogicApp_Fill_TempGetWalletChecksums | Stored Procedure | INSERT INTO | Commented out |

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

### 8.1 Count wallet checksums
```sql
SELECT COUNT(*) AS ChecksumCount
FROM dbo.TempGetWalletChecksums WITH (NOLOCK)
```

### 8.2 Find checksums for a specific customer
```sql
SELECT Id, WalletId, Address, Occurred
FROM dbo.TempGetWalletChecksums WITH (NOLOCK)
WHERE Gcid = 12345678
```

### 8.3 Check for records with missing integrity data
```sql
SELECT Id, WalletId, Gcid
FROM dbo.TempGetWalletChecksums WITH (NOLOCK)
WHERE Checksum IS NULL OR Signature IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TempGetWalletChecksums | Type: Table | Source: WalletDB/dbo/Tables/dbo.TempGetWalletChecksums.sql*
