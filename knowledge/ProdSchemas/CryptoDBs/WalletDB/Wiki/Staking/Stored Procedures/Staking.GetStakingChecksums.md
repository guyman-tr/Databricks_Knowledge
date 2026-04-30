# Staking.GetStakingChecksums

> Returns staking external addresses with their integrity checksums, using a daily-refreshed temp table cache for performance.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: staking addresses with checksum data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns staking pool addresses along with their integrity checksum data (salt, checksum, signature) for verification purposes. It uses a persistent `TempGetStakingChecksums` table as a daily cache - if the cache is stale (Occurred < today), it truncates and repopulates from the live join of StakingExternalAddress, Dictionary.ChecksumTypes, and Wallet.Checksums. Only active addresses (IsActive=1) are included.

The caching mechanism avoids repeatedly joining across checksum tables for what is essentially static data that only changes when addresses or secrets rotate. The procedure paginates via @IdGreaterThan and @MaxRecords for batch verification workflows.

Uses `EXECUTE AS owner` for elevated permissions to access checksum tables.

---

## 2. Business Logic

### 2.1 Daily Cache Refresh Pattern

**What**: Caches the address+checksum join result in a persistent temp table, refreshing once daily.

**Columns/Parameters Involved**: `TempGetStakingChecksums.Occurred`

**Rules**:
- Checks if the cache table's Occurred date is earlier than today
- If stale (or empty): TRUNCATE + INSERT from live join (StakingExternalAddress + ChecksumTypes + Checksums)
- If fresh: skip refresh, read directly from cache
- Only includes active addresses (WHERE IsActive=1)
- Cache covers all secret versions (SecretVersion from Wallet.Checksums is included)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) (IN) | NO | - | CODE-BACKED | The secret version for checksum matching. Used in the LEFT JOIN to Wallet.Checksums to find checksums generated with this key version. |
| 2 | @IdGreaterThan | bigint (IN) | NO | - | CODE-BACKED | Cursor for pagination. Returns records with Id > this value from the cache table. |
| 3 | @MaxRecords | int (IN) | NO | - | CODE-BACKED | Maximum records to return per call. Controls verification batch size. |

**Return Columns**:

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | Id | int | StakingExternalAddress.Id |
| 2 | ExternalAddress | varchar(100) | The blockchain staking pool address |
| 3 | CryptoId | int | The cryptocurrency |
| 4 | SecretVersion | varchar(255) | The secret version used for this checksum (NULL if no checksum) |
| 5 | Salt | varchar(max) | Cryptographic salt used in checksum generation (NULL if no checksum) |
| 6 | Checksum | varchar(max) | The computed integrity checksum (NULL if no checksum) |
| 7 | Signature | varchar(max) | Digital signature of the checksum (NULL if no checksum) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Staking.StakingExternalAddress | SELECT FROM | Source of staking addresses |
| - | Dictionary.ChecksumTypes | JOIN | Resolves 'StakingAddress' type |
| - | Wallet.Checksums | LEFT JOIN | Provides checksum, salt, signature data |
| - | TempGetStakingChecksums | INSERT/SELECT | Daily cache table (unqualified, likely dbo schema) |

### 5.2 Referenced By (other objects point to this)

Called by infrastructure integrity verification processes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.GetStakingChecksums (procedure)
+-- Staking.StakingExternalAddress (table)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
+-- TempGetStakingChecksums (table - cache)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.StakingExternalAddress | Table | FROM - source addresses |
| Dictionary.ChecksumTypes | Table | JOIN - type resolution |
| Wallet.Checksums | Table | LEFT JOIN - checksum data |
| TempGetStakingChecksums | Table | Cache table - daily refresh |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS owner | Security | Runs with elevated permissions for checksum table access |

---

## 8. Sample Queries

### 8.1 Get first batch of checksums
```sql
EXEC Staking.GetStakingChecksums
    @SecretVersion = 'v2.0',
    @IdGreaterThan = 0,
    @MaxRecords = 100
```

### 8.2 Check cache freshness
```sql
SELECT TOP 1 Occurred FROM TempGetStakingChecksums WITH (NOLOCK)
```

### 8.3 Verify all addresses have checksums
```sql
SELECT sea.Id, sea.ExternalAddress,
       CASE WHEN c.Id IS NOT NULL THEN 'Valid' ELSE 'Missing' END AS ChecksumStatus
FROM Staking.StakingExternalAddress sea WITH (NOLOCK)
JOIN Dictionary.ChecksumTypes ct WITH (NOLOCK) ON ct.Name = 'StakingAddress'
LEFT JOIN Wallet.Checksums c WITH (NOLOCK) ON c.ChecksumTypeId = ct.Id AND c.RecordId = sea.Id
WHERE sea.IsActive = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.GetStakingChecksums | Type: Stored Procedure | Source: WalletDB/Staking/Stored Procedures/Staking.GetStakingChecksums.sql*
