# Wallet.GetWalletsWithNoChecksums

> Identifies base-chain customer wallets that have no checksum record in Infra.Checksum, used by the executer service to find wallets needing initial checksum generation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallets with no Infra.Checksum record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds customer wallets that have never been checksummed. It LEFT JOINs CustomerWalletsView to Infra.Checksum (ChecksumType='Wallet', ChecksumId=WalletRecordId) and returns rows where no checksum exists. Only base-chain wallets (CryptoId = BlockchainCryptoId) are checked. The executer service uses this to identify wallets needing first-time checksum computation.

---

## 2. Business Logic

### 2.1 Missing Checksum Detection

**What**: Finds base-chain wallets with no Infra.Checksum record.

**Columns/Parameters Involved**: `CustomerWalletsView.WalletRecordId`, `Infra.Checksum`

**Rules**:
- LEFT JOIN Infra.Checksum ON ChecksumId = WalletRecordId AND ChecksumType = 'Wallet'
- WHERE c.Id IS NULL (no checksum exists)
- Only base-chain wallets (CryptoId = BlockchainCryptoId)
- TOP @MaxRecords ORDER BY WalletRecordId

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxRecords | int | NO | - | VERIFIED | Maximum wallets to return. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 3 | CryptoId (output) | int | NO | - | CODE-BACKED | Base-chain crypto. |
| 4 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 5 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. |
| 6 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 7 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary address. |
| 8 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal record ID. |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto (= CryptoId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | Source | Base-chain wallets |
| - | Infra.Checksum | LEFT JOIN (IS NULL) | Missing checksum detection |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Initial checksum generation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsWithNoChecksums (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Infra.Checksum (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Base-chain wallet lookup |
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

### 8.1 Find wallets without checksums
```sql
EXEC Wallet.GetWalletsWithNoChecksums @MaxRecords = 500;
```

### 8.2 Direct equivalent
```sql
SELECT TOP 500 cwv.Id, cwv.CryptoId, cwv.BlockchainProviderWalletId AS ProviderWalletId,
    cwv.WalletProviderId, cwv.Gcid, cwv.Address, cwv.WalletRecordId AS RecordId, cwv.BlockchainCryptoId
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
    LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = cwv.WalletRecordId AND c.ChecksumType = 'Wallet'
WHERE cwv.CryptoId = cwv.BlockchainCryptoId AND c.Id IS NULL ORDER BY cwv.WalletRecordId;
```

### 8.3 Count wallets missing checksums
```sql
SELECT COUNT(*) FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
    LEFT JOIN Infra.Checksum c WITH (NOLOCK) ON c.ChecksumId = cwv.WalletRecordId AND c.ChecksumType = 'Wallet'
WHERE cwv.CryptoId = cwv.BlockchainCryptoId AND c.Id IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsWithNoChecksums | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsWithNoChecksums.sql*
