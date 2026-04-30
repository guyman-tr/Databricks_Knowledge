# Dictionary.ChecksumTypes

> Lookup table defining the categories of objects that have checksums computed for data integrity verification across the wallet system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 unique constraint (Name) |

---

## 1. Business Meaning

This table defines the types of wallet system objects that undergo checksum verification. Checksums are hash values computed from an object's key attributes to detect unauthorized modifications - a critical security measure for a cryptocurrency platform where data integrity directly protects financial assets.

Each checksum type represents a category of objects being monitored. The system periodically recomputes checksums and compares them against stored values to detect any unexpected changes to wallet pools, individual wallets, staking addresses, or external addresses.

The table is FK-referenced by `Wallet.Checksums` (which stores the actual checksum values) and consumed by numerous stored procedures that handle checksum computation and verification (`GetWalletChecksums`, `GetWalletPoolChecksums`, `GetEtoroExternalAddressChecksums`, etc.).

---

## 2. Business Logic

### 2.1 Integrity Monitoring Scope

**What**: Each type represents a different scope of data integrity monitoring.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `WalletPool` (1): Checksums for wallet pool entries - pre-generated wallets awaiting customer assignment. Tampering with pool wallets could redirect funds.
- `Wallet` (2): Checksums for individual customer wallets. Protects against unauthorized modifications to wallet addresses, balances, or ownership.
- `StakingAddress` (3): Checksums for staking addresses used in proof-of-stake networks. Protects staking delegation configurations.
- `EtoroExternalAddress` (4): Checksums for eToro's own external addresses (omnibus, funding, etc.). Critical infrastructure addresses that must not be altered.

**Diagram**:
```
Checksum Monitoring
    |
    +---> WalletPool (1)           [Pre-generated wallets]
    +---> Wallet (2)               [Customer wallets]
    +---> StakingAddress (3)       [Staking delegations]
    +---> EtoroExternalAddress (4) [Platform infrastructure addresses]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | WalletPool | Integrity monitoring for the wallet pool - pre-generated blockchain addresses waiting to be assigned to customers. Any unauthorized change to a pool wallet address could redirect customer funds to an attacker. |
| 2 | Wallet | Integrity monitoring for individual customer wallets. Detects unauthorized changes to wallet addresses, ownership assignments, or configuration that could compromise customer assets. |
| 3 | StakingAddress | Integrity monitoring for staking addresses used in proof-of-stake networks. Protects against unauthorized changes to staking delegation targets or reward recipients. |
| 4 | EtoroExternalAddress | Integrity monitoring for eToro's own operational addresses (omnibus wallets, funding addresses, manual-out addresses). These are the platform's critical infrastructure - any unauthorized modification is a severe security incident. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the checksum type. Values: 1=WalletPool, 2=Wallet, 3=StakingAddress, 4=EtoroExternalAddress. FK target for Wallet.Checksums.ChecksumTypeId. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Unique human-readable label identifying the scope of checksum monitoring. Used in integrity verification procedures and security monitoring alerts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.Checksums | ChecksumTypeId | FK | Each checksum record references the type of object being checksummed |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Checksums | Table | FK on ChecksumTypeId |
| Wallet.GetWalletChecksums | Stored Procedure | Filters by checksum type |
| Wallet.GetWalletPoolChecksums | Stored Procedure | Filters by checksum type |
| Wallet.GetEtoroExternalAddressChecksums | Stored Procedure | Filters by checksum type |
| Wallet.GetWalletsWithoutChecksum | Stored Procedure | Finds objects missing checksums by type |
| Wallet.GetWalletPoolWithoutChecksum | Stored Procedure | Finds pool wallets without checksums |
| Wallet.GetEtoroExternalAddressWithoutChecksum | Stored Procedure | Finds external addresses without checksums |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ChecksumTypes | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UQ_ChecksumName | UNIQUE | Name - Ensures no duplicate checksum type names |

---

## 8. Sample Queries

### 8.1 List all checksum types
```sql
SELECT Id, Name
FROM Dictionary.ChecksumTypes WITH (NOLOCK)
ORDER BY Id
```

### 8.2 Count checksums by type
```sql
SELECT ct.Name AS ChecksumType, COUNT(c.Id) AS ChecksumCount
FROM Dictionary.ChecksumTypes ct WITH (NOLOCK)
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id
GROUP BY ct.Name
ORDER BY ChecksumCount DESC
```

### 8.3 Find objects missing checksums by type
```sql
SELECT ct.Id, ct.Name, c.ObjectId, c.ChecksumValue, c.Created
FROM Wallet.Checksums c WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id
WHERE ct.Id = 4 -- EtoroExternalAddress
ORDER BY c.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ChecksumTypes | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.ChecksumTypes.sql*
