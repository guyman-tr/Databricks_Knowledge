# dbo.TempGetStakingChecksums

> Temporary staging table for staking record integrity checksums, used to validate data integrity of customer staking positions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on Id) |

---

## 1. Business Meaning

This table stages integrity checksum records for customer staking positions. Staking involves customers locking crypto assets to participate in proof-of-stake blockchain validation, earning rewards. Each row contains a cryptographic checksum and signature for a staking record, enabling verification that staking data has not been tampered with.

The checksum verification pattern (SecretVersion/Salt/Checksum/Signature) is shared across a family of integrity tables: TempGetEtoroExternalAddressChecksums, TempGetWalletChecksums, and TempGetWalletPoolChecksums. With only 1 row, this table appears to be a minimal test or initial setup -- staking checksum verification may not have been fully rolled out, or only a single staking record was flagged for verification. PAGE compression is enabled.

No stored procedures directly reference this table. The data was likely populated by a Logic App or scheduled job for integrity auditing purposes.

---

## 2. Business Logic

### 2.1 Checksum Integrity Pattern

**What**: Each row contains a cryptographic checksum and signature computed over the staking record's data fields, using a versioned secret and random salt.

**Columns/Parameters Involved**: `SecretVersion`, `Salt`, `Checksum`, `Signature`

**Rules**:
- SecretVersion identifies which cryptographic key version was used to generate the checksum
- Salt provides randomness to prevent rainbow table attacks on the checksum
- Checksum is the computed hash of the staking record's data fields
- Signature provides tamper-evidence -- can be verified against the secret to confirm data integrity

---

## 3. Data Overview

| Id | ExternalAddress | CryptoId | Occurred | Meaning |
|----|-----------------|----------|----------|---------|
| (sample) | addr1q8x... | 18 | 2024-01-15 | Cardano staking position with integrity checksum for tamper detection |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Primary key. Unique identifier for this checksum record, likely corresponding to the source staking record's ID. |
| 2 | ExternalAddress | varchar(100) | YES | - | CODE-BACKED | The blockchain address where the staking position is delegated or held. Format varies by blockchain (e.g., Cardano addr1 prefix for ADA staking). |
| 3 | CryptoId | int | YES | - | CODE-BACKED | Cryptocurrency type identifier. References the platform's crypto asset lookup. Identifies which staking-eligible asset this record covers (e.g., 18=ADA, 46=ETH2). |
| 4 | SecretVersion | varchar(255) | YES | - | CODE-BACKED | Version identifier of the cryptographic key/secret used to compute the checksum. Enables key rotation without invalidating existing checksums. |
| 5 | Salt | nvarchar(255) | YES | - | CODE-BACKED | Random salt value used in checksum computation. Ensures identical data produces different checksums across records, preventing pattern analysis. |
| 6 | Checksum | varbinary(max) | YES | - | CODE-BACKED | Computed cryptographic hash of the staking record's data fields. Used to detect unauthorized modifications to staking data. |
| 7 | Signature | varbinary(max) | YES | - | CODE-BACKED | Cryptographic signature over the checksum, providing tamper-evidence. Can be verified using the corresponding SecretVersion key. |
| 8 | Occurred | date | YES | - | CODE-BACKED | Date when the checksum was computed or when the source staking record was created/modified. Provides temporal context for the integrity verification. |

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

### 8.1 View all staking checksums
```sql
SELECT Id, ExternalAddress, CryptoId, SecretVersion, Occurred
FROM dbo.TempGetStakingChecksums WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Check for records with missing integrity data
```sql
SELECT Id, ExternalAddress, CryptoId
FROM dbo.TempGetStakingChecksums WITH (NOLOCK)
WHERE Checksum IS NULL OR Signature IS NULL
```

### 8.3 Count checksums by crypto type
```sql
SELECT CryptoId, COUNT(*) AS RecordCount
FROM dbo.TempGetStakingChecksums WITH (NOLOCK)
GROUP BY CryptoId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TempGetStakingChecksums | Type: Table | Source: WalletDB/dbo/Tables/dbo.TempGetStakingChecksums.sql*
