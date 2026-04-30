# Wallet.GetWalletPoolWithNoChecksums

> Identifies assigned or funded pool wallets that have no checksum records in the Infra.Checksum table, used by the executer service to find pool wallets that need initial checksum computation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns WalletPool rows with no Infra.Checksum record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds pool wallets that have been assigned or funded (status 2 or 6) but have no checksum record at all in the `Infra.Checksum` table (note: uses the Infra schema checksum table, not the Wallet.Checksums table used by other checksum SPs). These wallets need initial checksum computation for integrity verification.

The executer service uses this to identify pool wallets requiring first-time checksum generation. Results are limited to @MaxRecords and ordered by Id for batch processing.

---

## 2. Business Logic

### 2.1 Missing Checksum Detection

**What**: Finds pool wallets with status 2/6 that have no Infra.Checksum record.

**Columns/Parameters Involved**: `WalletPoolStatuses.WalletPoolStatusId`, `Infra.Checksum`

**Rules**:
- LEFT JOIN to Infra.Checksum WHERE ChecksumType = 'WalletPool' AND ChecksumId = wp.Id
- WHERE c.Id IS NULL means no checksum exists for this pool wallet
- Additional filter: latest WalletPoolStatuses.WalletPoolStatusId IN (2, 6) - only assigned/funded
- TOP @MaxRecords ORDER BY wp.Id for batch-sized results

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxRecords | int | NO | - | VERIFIED | Maximum pool wallets to return. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | WalletPool record ID. |
| 3 | WalletId (output) | uniqueidentifier | NO | - | CODE-BACKED | Pool wallet GUID. |
| 4 | BlockchainCryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 5 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 6 | PublicAddress (output) | nvarchar(512) | YES | - | CODE-BACKED | Blockchain address. |
| 7 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WalletPool | Source | Pool wallet records |
| - | Wallet.WalletPoolStatuses | Subquery | Latest status filter (IN 2, 6) |
| - | Infra.Checksum | LEFT JOIN (IS NULL) | Detects missing checksums |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Finds pool wallets needing initial checksum |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletPoolWithNoChecksums (procedure)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletPoolStatuses (table)
+-- Infra.Checksum (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletPool | Table | Pool wallet records |
| Wallet.WalletPoolStatuses | Table | Latest status filter |
| Infra.Checksum | Table | LEFT JOIN for missing checksum detection |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecuterUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find pool wallets without checksums
```sql
EXEC Wallet.GetWalletPoolWithNoChecksums @MaxRecords = 500;
```

### 8.2 Direct equivalent
```sql
SELECT TOP 500 wp.Id, wp.WalletId, wp.BlockchainCryptoId, wp.ProviderWalletId, wp.PublicAddress, wp.WalletProviderId
FROM Wallet.WalletPool wp WITH (NOLOCK)
    LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = wp.Id AND c.ChecksumType = 'WalletPool'
WHERE (SELECT TOP 1 wps.WalletPoolStatusId FROM Wallet.WalletPoolStatuses wps WITH (NOLOCK) WHERE wps.WalletPoolId = wp.Id ORDER BY wps.Id DESC) IN (2, 6)
    AND c.Id IS NULL
ORDER BY wp.Id;
```

### 8.3 Count pool wallets missing checksums
```sql
SELECT COUNT(*) FROM Wallet.WalletPool wp WITH (NOLOCK)
    LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = wp.Id AND c.ChecksumType = 'WalletPool'
WHERE c.Id IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletPoolWithNoChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletPoolWithNoChecksums.sql*
