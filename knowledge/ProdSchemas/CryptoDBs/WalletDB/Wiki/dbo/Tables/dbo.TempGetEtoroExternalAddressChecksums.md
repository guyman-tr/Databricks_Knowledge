# dbo.TempGetEtoroExternalAddressChecksums

> Temporary staging table for external blockchain address integrity checksums, used by verification jobs to validate data integrity of customer external addresses.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on Id) |

---

## 1. Business Meaning

This table stages integrity checksum records for customer external blockchain addresses. External addresses are destination addresses provided by customers for withdrawals (sends) to wallets outside the eToro platform. Each row contains a cryptographic checksum and signature for a specific external address record, enabling verification that the data has not been tampered with.

The checksum verification pattern uses a SecretVersion/Salt/Checksum/Signature combination that is consistent across multiple checksum tables (TempGetStakingChecksums, TempGetWalletChecksums, TempGetWalletPoolChecksums). With only 28 rows, this table covers a small set of external addresses -- likely a test run, sample, or addresses flagged for re-verification. PAGE compression is enabled to reduce storage overhead.

No stored procedures directly reference this table. The data was likely populated by a Logic App or scheduled job that computed checksums for integrity auditing purposes.

---

## 2. Business Logic

### 2.1 Checksum Integrity Pattern

**What**: Each row contains a cryptographic checksum and signature computed over the external address record's data fields, using a versioned secret and random salt.

**Columns/Parameters Involved**: `SecretVersion`, `Salt`, `Checksum`, `Signature`

**Rules**:
- SecretVersion identifies which cryptographic key version was used to generate the checksum
- Salt provides randomness to prevent rainbow table attacks on the checksum
- Checksum is the computed hash of the record's data fields
- Signature provides tamper-evidence -- can be verified against the secret to confirm data integrity

---

## 3. Data Overview

| Id | Address | CryptoId | ExternalAddressTypeId | Occurred | Meaning |
|----|---------|----------|-----------------------|----------|---------|
| (sample) | 0x3f5CE5... | 6 | 1 | 2024-01-15 | Ethereum external address with integrity checksum recorded on the occurred date |
| (sample) | bc1q7cy... | 1 | 1 | 2024-01-15 | Bitcoin external address checksum for withdrawal destination verification |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for this checksum record, likely corresponding to the source external address record's ID. |
| 2 | Address | nvarchar(512) | YES | - | CODE-BACKED | The customer's external blockchain address (withdrawal destination). Format varies by crypto (e.g., 0x-prefixed for Ethereum, bc1/1/3-prefixed for Bitcoin). |
| 3 | Comment | nvarchar(256) | YES | - | CODE-BACKED | Optional user-provided label or note for the external address (e.g., "My Ledger wallet"). |
| 4 | CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency type identifier. References the platform's crypto asset lookup (e.g., 1=BTC, 6=ETH). Determines the blockchain network for this address. |
| 5 | ExternalAddressTypeId | tinyint | YES | - | CODE-BACKED | Type classification of the external address. Distinguishes between standard withdrawal addresses and other address types (e.g., whitelisted, verified). |
| 6 | SecretVersion | varchar(255) | YES | - | CODE-BACKED | Version identifier of the cryptographic key/secret used to compute the checksum. Enables key rotation without invalidating existing checksums. |
| 7 | Salt | nvarchar(255) | YES | - | CODE-BACKED | Random salt value used in checksum computation. Ensures identical data produces different checksums across records, preventing pattern analysis. |
| 8 | Checksum | varbinary(max) | YES | - | CODE-BACKED | Computed cryptographic hash of the record's data fields. Used to detect unauthorized modifications to the external address data. |
| 9 | Signature | varbinary(max) | YES | - | CODE-BACKED | Cryptographic signature over the checksum, providing tamper-evidence. Can be verified using the corresponding SecretVersion key. |
| 10 | Occurred | date | YES | - | CODE-BACKED | Date when the checksum was computed or when the source record was created/modified. Provides temporal context for the integrity verification. |

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

### 8.1 List all external address checksums
```sql
SELECT Id, Address, CryptoId, ExternalAddressTypeId, Occurred
FROM dbo.TempGetEtoroExternalAddressChecksums WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Check checksums by crypto type
```sql
SELECT CryptoId, COUNT(*) AS AddressCount
FROM dbo.TempGetEtoroExternalAddressChecksums WITH (NOLOCK)
GROUP BY CryptoId
ORDER BY AddressCount DESC
```

### 8.3 Find records with missing checksum data
```sql
SELECT Id, Address, CryptoId
FROM dbo.TempGetEtoroExternalAddressChecksums WITH (NOLOCK)
WHERE Checksum IS NULL OR Signature IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TempGetEtoroExternalAddressChecksums | Type: Table | Source: WalletDB/dbo/Tables/dbo.TempGetEtoroExternalAddressChecksums.sql*
