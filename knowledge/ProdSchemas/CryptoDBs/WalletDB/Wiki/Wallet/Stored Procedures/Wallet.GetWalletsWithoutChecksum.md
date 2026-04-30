# Wallet.GetWalletsWithoutChecksum

> Finds customer wallets missing a checksum for a specific secret version in Wallet.Checksums, using cursor-based pagination for incremental checksum generation after secret rotation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallets missing version-specific checksum with cursor pagination |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds customer wallets that are missing a checksum for a specific secret version. When secrets are rotated, all wallets need checksums recomputed under the new version. This procedure identifies which ones haven't been done yet. Unlike GetWalletsWithNoChecksums (which checks Infra.Checksum for any checksum), this checks Wallet.Checksums for a specific SecretVersion.

The procedure JOINs Wallet.Wallets to WalletPool (for address details), then LEFT JOINs to Checksums filtered by the target SecretVersion. Uses a temp table and cursor-based pagination (Id > @IdGreaterThan). The executer service uses this for incremental post-rotation checksum generation.

---

## 2. Business Logic

### 2.1 Version-Specific Missing Checksum Detection

**What**: Finds wallets without a checksum for the specified SecretVersion.

**Columns/Parameters Involved**: `@SecretVersion`, `Dictionary.ChecksumTypes`, `Wallet.Checksums`

**Rules**:
- JOINs Wallets to WalletPool for blockchain details
- JOINs Dictionary.ChecksumTypes WHERE Name='Wallet'
- LEFT JOINs Checksums WHERE ChecksumTypeId + RecordId + SecretVersion match
- WHERE c.Id IS NULL (no checksum for this version)
- Cursor: Id > @IdGreaterThan, TOP @MaxRecords, ORDER BY RecordId

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | VERIFIED | Checksum secret version to check. |
| 2 | @IdGreaterThan | bigint | NO | - | VERIFIED | Cursor position. Pass 0 for first page. |
| 3 | @MaxRecords | int | NO | - | VERIFIED | Page size. |
| 4 | RecordId (output) | bigint | NO | - | CODE-BACKED | Wallet record ID (cursor key, from Wallets.Id). |
| 5 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet GUID (from Wallets.WalletId). |
| 6 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 7 | BlockchainCryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 8 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (from WalletPool.ProviderWalletId). |
| 9 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Public address (from WalletPool.PublicAddress). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Wallets | Source | Customer wallet records |
| - | Wallet.WalletPool | JOIN | Address and provider details |
| - | Dictionary.ChecksumTypes | JOIN | 'Wallet' type filter |
| - | Wallet.Checksums | LEFT JOIN (IS NULL) | Missing version-specific checksum |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Post-rotation checksum generation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsWithoutChecksum (procedure)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPool (table)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | Customer wallet records |
| Wallet.WalletPool | Table | Address details |
| Dictionary.ChecksumTypes | Table | Type filter |
| Wallet.Checksums | Table | Missing checksum detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table for results.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find wallets missing checksums for version v2.0
```sql
EXEC Wallet.GetWalletsWithoutChecksum @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
```

### 8.2 Get next page
```sql
EXEC Wallet.GetWalletsWithoutChecksum @SecretVersion = 'v2.0', @IdGreaterThan = 5000, @MaxRecords = 1000;
```

### 8.3 Compare the two missing-checksum SPs
```sql
-- Missing ANY checksum (Infra.Checksum): EXEC Wallet.GetWalletsWithNoChecksums @MaxRecords = 500;
-- Missing SPECIFIC version (Wallet.Checksums, this SP): EXEC Wallet.GetWalletsWithoutChecksum @SecretVersion='v2.0', @IdGreaterThan=0, @MaxRecords=500;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsWithoutChecksum | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsWithoutChecksum.sql*
