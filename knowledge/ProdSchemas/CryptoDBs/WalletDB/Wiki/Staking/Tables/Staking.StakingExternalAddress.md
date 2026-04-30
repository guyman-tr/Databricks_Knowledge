# Staking.StakingExternalAddress

> Configuration table holding the external blockchain addresses of eToro's staking pools, one active address per supported cryptocurrency.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (PK + 1 unique NC) |

---

## 1. Business Meaning

Staking.StakingExternalAddress stores the external blockchain addresses of eToro's staking pools - the on-chain destinations where user crypto is delegated for Proof-of-Stake reward generation. Each row represents a staking pool address for a specific cryptocurrency. The unique index on (CryptoId, IsActive) enforces that only one address is active per crypto at any time, supporting address rotation while preserving history.

Without this table, the system would not know where to send user assets for staking delegation. It is the canonical source for the staking pool address used by the InsertStakingTransaction procedure and the external blockchain transfer process.

Currently contains a single row: the Ethereum (CryptoId=2) staking pool address `0xCB2A66...`, active since 2021-06-15. The address is read by `Staking.GetStakingExternalAddress` (returns the active address for a given CryptoId), and is validated for integrity by `Staking.GetStakingAddressWithoutChecksum` and `Staking.GetStakingChecksums` which cross-reference against `Wallet.Checksums` for tamper detection.

---

## 2. Business Logic

### 2.1 Single Active Address Per Crypto

**What**: Only one staking pool address can be active per cryptocurrency at any time, enabling safe address rotation.

**Columns/Parameters Involved**: `CryptoId`, `IsActive`, `EffectiveFrom`

**Rules**:
- Unique filtered index `idx_UniqSync` on (CryptoId, IsActive) prevents duplicate active addresses
- To rotate an address: deactivate the old (IsActive=0), insert new (IsActive=1, EffectiveFrom=now)
- Historical addresses remain in the table for audit purposes
- `Staking.GetStakingExternalAddress` filters by `CryptoId = @CryptoId AND IsActive = 1`

### 2.2 Address Integrity Verification

**What**: Staking addresses are validated via checksums to detect tampering or corruption.

**Columns/Parameters Involved**: `Id`, `ExternalAddress`, `CryptoId`

**Rules**:
- `Staking.GetStakingAddressWithoutChecksum` finds addresses missing a checksum record in Wallet.Checksums (ChecksumType = 'StakingAddress')
- `Staking.GetStakingChecksums` returns addresses with their checksum, salt, and signature for verification
- Both procedures use Dictionary.ChecksumTypes to locate the 'StakingAddress' type

---

## 3. Data Overview

| Id | ExternalAddress | CryptoId | IsActive | EffectiveFrom | Meaning |
|----|-----------------|----------|----------|---------------|---------|
| 1 | 0xCB2A66540680c344bab5f818d68c3e4B9D57363B | 2 (ETH) | true | 2021-06-15 | eToro's Ethereum staking pool address. All ETH staking transfers are sent to this on-chain address. Active since the staking feature launch. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing surrogate key. Used as RecordId in Wallet.Checksums for address integrity verification. |
| 2 | ExternalAddress | varchar(100) | NO | - | VERIFIED | The blockchain address of eToro's staking pool. For ETH, this is an Ethereum address (0x-prefixed, 42 chars). This is the destination address for staking transfers. Read by Staking.GetStakingExternalAddress and validated by the checksum procedures. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this staking address serves. FK to Wallet.CryptoTypes.CryptoID. Currently only 2 (ETH). Part of the unique constraint ensuring one active address per crypto. |
| 4 | IsActive | bit | NO | 1 | VERIFIED | Whether this address is the currently active staking pool for its crypto. 1=active (used for new staking transfers), 0=retired (kept for audit). Default 1 for new addresses. Filtered by GetStakingExternalAddress and part of unique index. |
| 5 | EffectiveFrom | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this address became the active staking pool. Defaults to UTC now on insert. Used for audit trail when addresses are rotated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Identifies which cryptocurrency this staking pool address serves |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Checksums | RecordId | Implicit | Checksum integrity records for staking addresses (via ChecksumType='StakingAddress') |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.StakingExternalAddress (table)
  (no code-level dependencies - leaf node)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Staking.GetStakingExternalAddress | Stored Procedure | READER - retrieves active staking address by CryptoId |
| Staking.GetStakingAddressWithoutChecksum | Stored Procedure | READER - finds addresses missing checksum records |
| Staking.GetStakingChecksums | Stored Procedure | READER - returns addresses with their integrity checksums |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StakingExternalAddress | CLUSTERED PK | Id ASC | - | - | Active |
| idx_UniqSync | UNIQUE NC | CryptoId ASC, IsActive ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StakingExternalAddress | PRIMARY KEY | Clustered on Id, PAGE compression |
| DF (IsActive) | DEFAULT | 1 for IsActive - new addresses are active by default |
| DF_Staking_StakingExternalAddress__EffectiveFrom | DEFAULT | getutcdate() for EffectiveFrom |
| FK_Staking_StakingExternalAddress_CryptoId__Wallet_CryptoTypes_CryptoId | FOREIGN KEY | CryptoId -> Wallet.CryptoTypes.CryptoID |

---

## 8. Sample Queries

### 8.1 Get the active staking address for a crypto
```sql
SELECT ExternalAddress
FROM Staking.StakingExternalAddress WITH (NOLOCK)
WHERE CryptoId = @CryptoId AND IsActive = 1
```

### 8.2 List all staking addresses with status
```sql
SELECT sea.Id, sea.ExternalAddress, ct.Name AS CryptoName, sea.IsActive, sea.EffectiveFrom
FROM Staking.StakingExternalAddress sea WITH (NOLOCK)
INNER JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON ct.CryptoID = sea.CryptoId
ORDER BY sea.CryptoId, sea.EffectiveFrom DESC
```

### 8.3 Find addresses missing integrity checksums
```sql
SELECT sea.Id, sea.ExternalAddress, sea.CryptoId
FROM Staking.StakingExternalAddress sea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'StakingAddress'
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = sea.Id
WHERE c.Id IS NULL
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking pools are managed by eToro; users delegate voting rights to staking pools; the more delegated, the higher chance of producing blocks and earning rewards |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.StakingExternalAddress | Type: Table | Source: WalletDB/Staking/Tables/Staking.StakingExternalAddress.sql*
