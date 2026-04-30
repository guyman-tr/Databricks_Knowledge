# Staking.GetStakingAddressWithoutChecksum

> Finds staking external addresses that do not yet have an integrity checksum record, for batch checksum generation.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: staking addresses missing checksum records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies staking pool addresses in StakingExternalAddress that have not yet been checksummed for a given secret version. It enables a batch integrity verification process: addresses are discovered here, checksums are computed externally, and then stored via Infra.InsertChecksum. This protects against address tampering or data corruption.

The procedure uses `EXECUTE AS owner` for elevated permissions to access checksum tables. It creates a temp table, LEFT JOINs to Wallet.Checksums (via Dictionary.ChecksumTypes where Name='StakingAddress'), and returns addresses where no matching checksum record exists for the specified SecretVersion.

Called by infrastructure/security batch processes that rotate or verify checksums periodically.

---

## 2. Business Logic

### 2.1 Checksum Gap Detection

**What**: Finds addresses missing integrity verification records for a specific secret version.

**Columns/Parameters Involved**: `@SecretVersion`, `@IdGreaterThan`, `@MaxRecords`

**Rules**:
- Joins StakingExternalAddress to Dictionary.ChecksumTypes (Name='StakingAddress') to get the ChecksumTypeId
- LEFT JOINs to Wallet.Checksums matching on ChecksumTypeId, RecordId (=StakingExternalAddress.Id), and SecretVersion
- Returns rows where Wallet.Checksums.Id IS NULL (no checksum exists)
- Paginates via @IdGreaterThan (cursor-based) and @MaxRecords (batch size)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) (IN) | NO | - | CODE-BACKED | The secret/key version to check against. Checksums are versioned so that key rotation produces new checksums. Only addresses missing a checksum for THIS version are returned. |
| 2 | @IdGreaterThan | bigint (IN) | NO | - | CODE-BACKED | Cursor for pagination. Only addresses with Id > this value are returned. Start with 0 for the first batch. |
| 3 | @MaxRecords | int (IN) | NO | - | CODE-BACKED | Maximum number of addresses to return per call. Controls batch size for checksum generation. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | Id | int | StakingExternalAddress.Id - used as RecordId when creating the checksum |
| 2 | ExternalAddress | varchar(100) | The blockchain address to be checksummed |
| 3 | CryptoId | int | The cryptocurrency for this address |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.StakingExternalAddress | SELECT FROM | Reads addresses to check for missing checksums |
| - | Dictionary.ChecksumTypes | JOIN | Resolves 'StakingAddress' to its ChecksumTypeId |
| - | Wallet.Checksums | LEFT JOIN | Checks for existing checksum records |

### 5.2 Referenced By (other objects point to this)

Called by infrastructure batch processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingAddressWithoutChecksum (procedure)
+-- Staking.StakingExternalAddress (table)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingExternalAddress | Table | FROM - source of addresses to check |
| Dictionary.ChecksumTypes | Table | JOIN - resolves 'StakingAddress' type |
| Wallet.Checksums | Table | LEFT JOIN - checks for existing checksums |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS owner | Security | Runs with elevated permissions to access checksum tables |

---

## 8. Sample Queries

### 8.1 Find first batch of addresses without checksums
```sql
EXEC Staking.GetStakingAddressWithoutChecksum
    @SecretVersion = 'v2.0',
    @IdGreaterThan = 0,
    @MaxRecords = 100
```

### 8.2 Equivalent direct query
```sql
SELECT sea.Id, sea.ExternalAddress, sea.CryptoId
FROM Staking.StakingExternalAddress sea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'StakingAddress'
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = sea.Id AND c.SecretVersion = 'v2.0'
WHERE sea.Id > 0 AND c.Id IS NULL
ORDER BY sea.Id
```

### 8.3 Check checksum coverage for staking addresses
```sql
SELECT COUNT(*) AS TotalAddresses,
       SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS WithChecksum
FROM Staking.StakingExternalAddress sea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'StakingAddress'
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = sea.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingAddressWithoutChecksum | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingAddressWithoutChecksum.sql*
