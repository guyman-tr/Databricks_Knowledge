# Wallet.GetWalletPoolWithoutChecksum

> Retrieves pool wallets that are missing a checksum for a specific secret version in the Wallet.Checksums table, using cursor-based pagination for batch checksum generation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletPool rows missing checksums for a given SecretVersion |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds pool wallets that are missing a checksum for a specific secret version. Unlike `GetWalletPoolWithNoChecksums` (which checks the Infra.Checksum table for any checksum), this procedure checks the Wallet.Checksums table for a specific version. When secrets are rotated and a new version is deployed, all pool wallets need checksums recomputed for the new version - this procedure identifies which ones haven't been done yet.

The executer service uses this for incremental checksum computation after secret rotation. Uses a temp table for the JOIN and cursor-based pagination (Id > @IdGreaterThan).

---

## 2. Business Logic

### 2.1 Version-Specific Missing Checksum Detection

**What**: Finds pool wallets without a checksum for the specified SecretVersion.

**Columns/Parameters Involved**: `@SecretVersion`, `Dictionary.ChecksumTypes`, `Wallet.Checksums`

**Rules**:
- JOINs WalletPool to Dictionary.ChecksumTypes (Name='WalletPool')
- LEFT JOINs to Wallet.Checksums WHERE ChecksumTypeId + RecordId + SecretVersion match
- WHERE c.Id IS NULL means no checksum exists for this version
- Also includes a backward-compatibility CryptoId alias (BlockchainCryptoId aliased as CryptoId)
- Cursor pagination: Id > @IdGreaterThan, TOP @MaxRecords

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SecretVersion | varchar(255) | NO | - | VERIFIED | Checksum secret version to check against. |
| 2 | @IdGreaterThan | bigint | NO | - | VERIFIED | Cursor position for pagination. Pass 0 for first page. |
| 3 | @MaxRecords | int | NO | - | VERIFIED | Maximum records per page. |
| 4 | Id (output) | bigint | NO | - | CODE-BACKED | WalletPool record ID. Cursor key. |
| 5 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Pool wallet GUID. |
| 6 | BlockchainCryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 7 | CryptoId (output) | int | NO | - | CODE-BACKED | Alias of BlockchainCryptoId for backward compatibility. |
| 8 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 9 | PublicAddress (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | Source | Pool wallet records |
| - | Dictionary.ChecksumTypes | JOIN | 'WalletPool' type filter |
| - | Wallet.Checksums | LEFT JOIN (IS NULL) | Detects missing version-specific checksum |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Post-rotation checksum generation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolWithoutChecksum (procedure)
+-- Wallet.WalletPool (table)
+-- Dictionary.ChecksumTypes (table)
+-- Wallet.Checksums (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Pool wallet records |
| Dictionary.ChecksumTypes | Table | Checksum type filter |
| Wallet.Checksums | Table | LEFT JOIN for missing checksum detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table for intermediate results.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find pool wallets missing checksums for version v2.0
```sql
EXEC Wallet.GetWalletPoolWithoutChecksum @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 1000;
```

### 8.2 Get next page
```sql
EXEC Wallet.GetWalletPoolWithoutChecksum @SecretVersion = 'v2.0', @IdGreaterThan = 5000, @MaxRecords = 1000;
```

### 8.3 Compare the two missing-checksum SPs
```sql
-- Missing ANY checksum (Infra.Checksum): EXEC Wallet.GetWalletPoolWithNoChecksums @MaxRecords = 500;
-- Missing SPECIFIC version (Wallet.Checksums): EXEC Wallet.GetWalletPoolWithoutChecksum @SecretVersion = 'v2.0', @IdGreaterThan = 0, @MaxRecords = 500;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolWithoutChecksum | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolWithoutChecksum.sql*
