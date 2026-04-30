# Wallet.GetWalletPoolChecksums

> Retrieves pool wallet integrity checksums for a specific secret version, using a daily-refreshed temp table cache (TempGetWalletPoolChecksums) for efficient bulk verification.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated pool wallet checksum data from cached temp table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the pool wallet counterpart to `Wallet.GetWalletChecksums`. It retrieves cryptographic checksums for pool wallets (pre-created reserve wallets) to verify their integrity. Like the customer wallet version, it uses a daily-refreshed persistent temp table (`TempGetWalletPoolChecksums`) to cache the expensive JOIN between WalletPool, Dictionary.ChecksumTypes, and Wallet.Checksums.

The executer, logic app jobs, and redeem scheduler services use this for pool wallet integrity verification during assignment and funding operations.

---

## 2. Business Logic

### 2.1 Daily Cache Refresh Pattern

**What**: Refreshes TempGetWalletPoolChecksums once per day.

**Columns/Parameters Involved**: `TempGetWalletPoolChecksums.Occurred`, `GETDATE()`

**Rules**:
- Same pattern as GetWalletChecksums: checks if cache is stale (Occurred < today)
- Repopulation: WalletPool JOIN Dictionary.ChecksumTypes (Name='WalletPool') LEFT JOIN Checksums
- LEFT JOIN means pool wallets without checksums still appear
- Cursor-based pagination: Id > @IdGreaterThan, TOP @MaxRecords, ORDER BY Id

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | VERIFIED | Checksum secret version to retrieve. |
| 2 | @IdGreaterThan | bigint | NO | - | VERIFIED | Cursor position for pagination. Pass 0 for first page. |
| 3 | @MaxRecords | int | NO | - | VERIFIED | Maximum records per page. |
| 4 | Id (output) | bigint | NO | - | CODE-BACKED | WalletPool record ID. Cursor key. |
| 5 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Pool wallet GUID. |
| 6 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (aliased from ProviderWalletId). |
| 7 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Pool wallet blockchain address (aliased from PublicAddress). |
| 8 | SecretVersion (output) | varchar(255) | YES | - | CODE-BACKED | Checksum secret version. NULL if no checksum. |
| 9 | Salt (output) | varbinary | YES | - | CODE-BACKED | Cryptographic salt. |
| 10 | Checksum (output) | varbinary | YES | - | CODE-BACKED | Computed checksum hash. NULL if not checksummed. |
| 11 | Signature (output) | varbinary | YES | - | CODE-BACKED | Digital signature. NULL if not signed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | Cache source | Pool wallet data |
| - | Dictionary.ChecksumTypes | JOIN | 'WalletPool' checksum type |
| - | Wallet.Checksums | LEFT JOIN | Checksum data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser, LogicAppJobsUser, RedeemSchedulerUser | - | EXECUTE | Pool wallet integrity verification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolChecksums (procedure)
+-- Wallet.WalletPool (table)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Pool wallet data for cache |
| Dictionary.ChecksumTypes | Table | Checksum type filter |
| Wallet.Checksums | Table | Checksum data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser, LogicAppJobsUser, RedeemSchedulerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses OPTION (RECOMPILE).

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get first page of pool checksums
```sql
EXEC Wallet.GetWalletPoolChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
```

### 8.2 Get next page
```sql
EXEC Wallet.GetWalletPoolChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 1000, @MaxRecords = 1000;
```

### 8.3 Compare with customer wallet checksums
```sql
-- Customer wallets: EXEC Wallet.GetWalletChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
-- Pool wallets (this SP): EXEC Wallet.GetWalletPoolChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolChecksums.sql*
