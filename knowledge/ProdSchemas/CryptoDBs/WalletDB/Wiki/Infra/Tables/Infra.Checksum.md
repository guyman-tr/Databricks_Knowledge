# Infra.Checksum

> Stores cryptographic JWT signatures for wallet-related entities, providing data integrity verification across wallets, wallet pools, and external addresses.

| Property | Value |
|----------|-------|
| **Schema** | Infra |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 unique filtered nonclustered |

---

## 1. Business Meaning

Infra.Checksum is the central data integrity store for WalletDB. It records cryptographic signatures (JWT tokens signed with RS256) that capture a snapshot of critical fields for three types of wallet entities: individual customer wallets, wallet pools, and eToro external cryptocurrency addresses. Each row represents a signed attestation that a specific entity's data matched a known state at a given point in time.

This table exists to enable tamper detection and data integrity auditing across the wallet infrastructure. Without it, there would be no mechanism to verify that wallet balances, pool configurations, or external address records have not been modified unexpectedly. The checksum system serves as a compliance and security safeguard for cryptocurrency custody operations.

Data flows into this table through two paths: Infra.InsertChecksum (single record) and Infra.InsertChecksumList (batch via the Infra.ChecksumType TVP). Both use idempotent insert logic - if a checksum already exists for a given ChecksumId + ChecksumType combination, the insert is silently skipped. Three Wallet-schema procedures (Wallet.GetWalletsWithNoChecksums, Wallet.GetWalletPoolWithNoChecksums, Wallet.GetEtoroExternalAddressesWithNoChecksums) identify entities that lack checksums, feeding a backfill pipeline that generates and stores missing signatures. Read operations use Infra.ReadChecksum (single) and Infra.ReadChecksums (batch via Infra.ChecksumKey TVP).

---

## 2. Business Logic

### 2.1 Entity-to-Checksum Mapping

**What**: Each ChecksumType maps to a specific source entity table, with ChecksumId holding the entity's primary key as a string.

**Columns/Parameters Involved**: `ChecksumId`, `ChecksumType`

**Rules**:
- ChecksumType "Wallet" -> ChecksumId = Wallet.CustomerWalletsView.WalletRecordId (cast to nvarchar)
- ChecksumType "WalletPool" -> ChecksumId = Wallet.WalletPool.Id (cast to nvarchar)
- ChecksumType "EtoroExternalAddress" -> ChecksumId = Wallet.EtoroExternalAddresses.Id (cast to nvarchar)
- The combination of ChecksumId + ChecksumType is unique (enforced by filtered unique index UQ_ChecksumId_ChecksumType)
- Multiple checksums for different ChecksumTypes can share the same ChecksumId (e.g., entity 123 could be both a wallet and an external address)

**Diagram**:
```
Wallet.CustomerWalletsView.WalletRecordId  --("Wallet")-->  Infra.Checksum
Wallet.WalletPool.Id                       --("WalletPool")--> Infra.Checksum
Wallet.EtoroExternalAddresses.Id           --("EtoroExternalAddress")--> Infra.Checksum
```

### 2.2 Idempotent Insert Pattern

**What**: Checksums are inserted with duplicate detection to prevent overwriting existing integrity records.

**Columns/Parameters Involved**: `ChecksumId`, `ChecksumType`, `Signature`

**Rules**:
- InsertChecksum uses WHERE NOT EXISTS on ChecksumId + ChecksumType before inserting
- InsertChecksumList uses LEFT JOIN + WHERE c.Id IS NULL to skip existing records
- Once a checksum is written, it is never updated or deleted through standard procedures
- This immutability ensures audit integrity - a checksum record is a permanent attestation

### 2.3 Backfill Discovery Pattern

**What**: Three Wallet-schema procedures find entities missing checksums, driving a background remediation pipeline.

**Columns/Parameters Involved**: `ChecksumId`, `ChecksumType`

**Rules**:
- Wallet.GetWalletsWithNoChecksums: finds wallets where CryptoId = BlockchainCryptoId (native chain wallets only) with no "Wallet" checksum
- Wallet.GetWalletPoolWithNoChecksums: finds pools in status 2 or 6 (active/eligible) with no "WalletPool" checksum
- Wallet.GetEtoroExternalAddressesWithNoChecksums: finds all external addresses with no "EtoroExternalAddress" checksum
- All use LEFT JOIN Infra.Checksum + WHERE c.Id IS NULL pattern with @MaxRecords to process in batches

**Diagram**:
```
[Backfill Discovery]          [Insert Path]           [Read Path]
GetWalletsWithNoChecksums     InsertChecksum          ReadChecksum
GetWalletPoolWithNoChecksums  InsertChecksumList      ReadChecksums
GetExternalAddressesWithNo..                          
        |                          |                       |
        v                          v                       v
  "Entities missing           Infra.Checksum         "Return stored
   checksums"                (3.95M rows)             signatures"
```

---

## 3. Data Overview

| Id | ChecksumId | ChecksumType | SignaturePrefix | Created | Meaning |
|---|---|---|---|---|---|
| 3953262 | 1572641 | Wallet | eyJhbGciOiJSUzI1NiIs... | 2026-04-15 10:38:28 | JWT integrity signature for customer wallet record 1572641. Most recent checksum in the system - wallets are the second most common type. |
| 3953258 | 1572637 | Wallet | eyJhbGciOiJSUzI1NiIs... | 2026-04-15 10:31:20 | Another wallet checksum showing continuous near-real-time signing activity (7 min gap from newest). |
| 3819908 | 170 | EtoroExternalAddress | eyJhbGciOiJSUzI1NiIs... | 2026-02-16 15:00:41 | Checksum for external crypto address #170. Only 170 such records exist - these are eToro-owned deposit/withdrawal addresses, not customer addresses. |
| - | (pool ex.) | WalletPool | eyJhbGciOiJSUzI1NiIs... | - | WalletPool is the dominant type (2.46M of 3.95M rows) - each pool links a wallet to a blockchain crypto asset. |
| 1 | (earliest) | - | eyJhbGciOiJSUzI1NiIs... | 2023-07-25 13:14:35 | First checksum ever recorded. System has been running since July 2023, accumulating ~3.95M records over ~2.7 years. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Used as the existence check in LEFT JOIN patterns (WHERE c.Id IS NULL) to detect entities without checksums. Clustered PK. |
| 2 | ChecksumId | nvarchar(64) | NO | - | VERIFIED | The primary key of the source entity, stored as a string. Maps to different entity tables depending on ChecksumType: WalletRecordId for "Wallet", WalletPool.Id for "WalletPool", EtoroExternalAddresses.Id for "EtoroExternalAddress". Combined with ChecksumType to form the unique composite business key (UQ_ChecksumId_ChecksumType). Evidence: JOIN patterns in GetWalletsWithNoChecksums, GetWalletPoolWithNoChecksums, GetEtoroExternalAddressesWithNoChecksums. |
| 3 | ChecksumType | varchar(64) | NO | - | VERIFIED | The category of entity being checksummed. Known production values: "Wallet" (1.49M rows - individual customer wallet records), "WalletPool" (2.46M rows - wallet-to-blockchain-crypto associations), "EtoroExternalAddress" (170 rows - eToro-owned crypto deposit/withdrawal addresses). Determines which source table ChecksumId refers to. Evidence: live data distribution + 3 Wallet-schema discovery SPs + 4 Infra SPs. |
| 4 | Signature | varchar(2048) | NO | - | CODE-BACKED | RS256-signed JWT (JSON Web Token) containing a serialized snapshot of the entity's critical fields at signing time. Starts with "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9" (base64 for {"alg":"RS256","typ":"JWT"}). The JWT payload encodes entity-specific fields (e.g., Id, Address for external addresses). Used for tamper detection - if entity data changes after signing, signature verification will fail. |
| 5 | Created | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the checksum was persisted. Defaults to GETUTCDATE() on the table, but can be overridden by the caller (InsertChecksum and InsertChecksumList both pass explicit @Created values). Represents the audit timestamp of the integrity snapshot. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no explicit FKs).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Infra.InsertChecksum](../Stored Procedures/Infra.InsertChecksum.md) | direct INSERT | Writer | Inserts single checksum records with idempotent duplicate detection |
| [Infra.InsertChecksumList](../Stored Procedures/Infra.InsertChecksumList.md) | direct INSERT via LEFT JOIN | Writer | Batch inserts checksums from ChecksumType TVP, skipping existing records |
| [Infra.ReadChecksum](../Stored Procedures/Infra.ReadChecksum.md) | direct SELECT | Reader | Reads single checksum by ChecksumId + ChecksumType, returns most recent (ORDER BY Id DESC) |
| [Infra.ReadChecksums](../Stored Procedures/Infra.ReadChecksums.md) | LEFT JOIN | Reader | Batch reads checksums by ChecksumKey TVP, returns matching signatures |
| Wallet.GetWalletsWithNoChecksums | LEFT JOIN | Reader | Finds wallets without "Wallet" type checksums for backfill pipeline |
| Wallet.GetWalletPoolWithNoChecksums | LEFT JOIN | Reader | Finds wallet pools (status 2/6) without "WalletPool" type checksums for backfill |
| Wallet.GetEtoroExternalAddressesWithNoChecksums | LEFT JOIN | Reader | Finds external addresses without "EtoroExternalAddress" type checksums for backfill |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Infra.InsertChecksum | Stored Procedure | Writer - single record insert |
| Infra.InsertChecksumList | Stored Procedure | Writer - batch insert via TVP |
| Infra.ReadChecksum | Stored Procedure | Reader - single lookup |
| Infra.ReadChecksums | Stored Procedure | Reader - batch lookup via TVP |
| Wallet.GetWalletsWithNoChecksums | Stored Procedure | Reader - backfill discovery for wallets |
| Wallet.GetWalletPoolWithNoChecksums | Stored Procedure | Reader - backfill discovery for wallet pools |
| Wallet.GetEtoroExternalAddressesWithNoChecksums | Stored Procedure | Reader - backfill discovery for external addresses |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Infra_Checksum | CLUSTERED PK | Id ASC | - | - | Active (DATA_COMPRESSION = PAGE) |
| UQ_ChecksumId_ChecksumType | NC UNIQUE | ChecksumId ASC, ChecksumType ASC | - | WHERE ChecksumId IS NOT NULL AND ChecksumType IS NOT NULL | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Infra_Checksum | PRIMARY KEY | Clustered on Id - ensures unique surrogate identity |
| UQ_ChecksumId_ChecksumType | UNIQUE (filtered) | Ensures no duplicate checksums for the same entity + type combination. Filtered to exclude NULLs (though both columns are NOT NULL, the filter is defensive). |
| DF_Infra_Checksum_Created | DEFAULT | GETUTCDATE() for Created - server-side UTC timestamp when no explicit value is provided |

---

## 8. Sample Queries

### 8.1 Find the latest checksum for a specific wallet
```sql
SELECT TOP 1 Id, ChecksumId, ChecksumType, Signature, Created
FROM Infra.Checksum WITH (NOLOCK)
WHERE ChecksumId = '1572641' AND ChecksumType = 'Wallet'
ORDER BY Id DESC
```

### 8.2 Count checksums by type with date range
```sql
SELECT ChecksumType,
       COUNT(*) AS Total,
       MIN(Created) AS Earliest,
       MAX(Created) AS Latest
FROM Infra.Checksum WITH (NOLOCK)
GROUP BY ChecksumType
ORDER BY Total DESC
```

### 8.3 Find wallets missing checksums (replicates backfill discovery)
```sql
SELECT TOP 100 cwv.WalletRecordId, cwv.CryptoId, cwv.Address
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
    LEFT JOIN Infra.Checksum c WITH (NOLOCK)
        ON c.ChecksumId = cwv.WalletRecordId AND c.ChecksumType = 'Wallet'
WHERE cwv.CryptoId = cwv.BlockchainCryptoId
    AND c.Id IS NULL
ORDER BY cwv.WalletRecordId
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Wallet.Infrastructure.Checksum (page not accessible) | Confluence | Page exists with matching title but returned 404 - may have been archived or moved. |

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence (inaccessible) + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Infra.Checksum | Type: Table | Source: WalletDB/Infra/Tables/Infra.Checksum.sql*
