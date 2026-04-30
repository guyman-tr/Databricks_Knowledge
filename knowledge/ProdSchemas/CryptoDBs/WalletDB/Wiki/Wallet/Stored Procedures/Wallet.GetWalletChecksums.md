# Wallet.GetWalletChecksums

> Retrieves wallet integrity checksums for a specific secret version, using a daily-refreshed temp table cache (TempGetWalletChecksums) to avoid expensive JOINs across CustomerWalletsView and Checksums on every call.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated wallet checksum data from cached temp table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure supports the wallet integrity verification system. Each wallet has a cryptographic checksum (hash + salt + signature) computed against its key properties. This procedure retrieves these checksums for bulk verification - comparing stored checksums against recomputed values to detect tampering or data corruption.

The procedure uses a persistent temp table (`TempGetWalletChecksums`) as a daily cache. On the first call of each day, it truncates and repopulates the cache from CustomerWalletsView LEFT JOINed to Checksums (filtered by the 'Wallet' checksum type and the specified secret version). Subsequent calls that day read from the cache, avoiding the expensive JOIN. Consumers include the executer, logic app jobs, redeem scheduler, and wallet user services.

---

## 2. Business Logic

### 2.1 Daily Cache Refresh Pattern

**What**: Refreshes the temp table once per day, then serves reads from cache.

**Columns/Parameters Involved**: `TempGetWalletChecksums.Occurred`, `GETDATE()`

**Rules**:
- If TempGetWalletChecksums.Occurred (latest) is before today's date, truncate and repopulate
- Repopulation JOINs CustomerWalletsView (base-chain only: CryptoId = BlockchainCryptoId) with Dictionary.ChecksumTypes (Name='Wallet') and LEFT JOINs Wallet.Checksums
- LEFT JOIN means wallets without checksums still appear (with NULL checksum fields)
- Cache is valid for the rest of the day

### 2.2 Paginated Retrieval

**What**: Cursor-based pagination using Id > @IdGreaterThan with TOP @MaxRecords.

**Columns/Parameters Involved**: `@IdGreaterThan`, `@MaxRecords`

**Rules**:
- Results ordered by Id (WalletRecordId) ascending
- Caller passes last seen Id to get next page
- OPTION (RECOMPILE) for optimal plan selection with variable page sizes

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | VERIFIED | Checksum secret version to retrieve. Each rotation generates a new version. |
| 2 | @IdGreaterThan | bigint | NO | - | VERIFIED | Cursor position: return records with Id > this value. Pass 0 for first page. |
| 3 | @MaxRecords | int | NO | - | VERIFIED | Maximum records to return per page. |
| 4 | Id (output) | bigint | NO | - | CODE-BACKED | Wallet record ID (from CustomerWalletsView.WalletRecordId). Cursor key. |
| 5 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID. |
| 6 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 7 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider's wallet reference. |
| 8 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary wallet address. |
| 9 | SecretVersion (output) | varchar(255) | YES | - | CODE-BACKED | Checksum secret version. NULL if no checksum exists for this wallet. |
| 10 | Salt (output) | varbinary | YES | - | CODE-BACKED | Cryptographic salt used in checksum computation. |
| 11 | Checksum (output) | varbinary | YES | - | CODE-BACKED | The computed checksum hash. NULL if wallet has not been checksummed. |
| 12 | Signature (output) | varbinary | YES | - | CODE-BACKED | Digital signature of the checksum. NULL if not yet signed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | Cache source | Base wallet data for cache |
| - | Dictionary.ChecksumTypes | JOIN | Filters for 'Wallet' checksum type |
| - | Wallet.Checksums | LEFT JOIN | Checksum data by RecordId + SecretVersion |
| - | TempGetWalletChecksums | Cache read | Daily-refreshed persistent temp table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Wallet integrity verification |
| LogicAppJobsUser | - | EXECUTE | Scheduled checksum validation |
| RedeemSchedulerUser | - | EXECUTE | Pre-redemption integrity check |
| WalletUser | - | EXECUTE | Wallet service integrity |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletChecksums (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
+-- TempGetWalletChecksums (persistent temp table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Source for cache repopulation |
| Dictionary.ChecksumTypes | Table | Checksum type filter ('Wallet') |
| Wallet.Checksums | Table | Checksum data lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser, LogicAppJobsUser, RedeemSchedulerUser, WalletUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses OPTION (RECOMPILE) on final SELECT.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get first page of checksums
```sql
EXEC Wallet.GetWalletChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
```

### 8.2 Get next page
```sql
EXEC Wallet.GetWalletChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 1000, @MaxRecords = 1000;
```

### 8.3 Find wallets missing checksums
```sql
-- From the result, look for rows where Checksum IS NULL
EXEC Wallet.GetWalletChecksums @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 100000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletChecksums.sql*
