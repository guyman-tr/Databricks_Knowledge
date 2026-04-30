# Wallet.GetWalletsForChecksumsValidation

> Returns base-chain customer wallets with pagination for bulk checksum recomputation and validation by the executer service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns paginated base-chain wallets from CustomerWalletsView |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns customer wallets eligible for checksum validation - specifically base-chain wallets (CryptoId = BlockchainCryptoId). Token sub-wallets are excluded since they share the same underlying blockchain wallet. The executer service uses this to iterate through all wallets in paginated batches and validate their integrity checksums.

Results are ordered by WalletRecordId with OFFSET/FETCH pagination. Each row provides all fields needed for checksum computation: wallet ID, crypto, provider reference, address, Gcid, record ID, and blockchain crypto.

---

## 2. Business Logic

### 2.1 Base-Chain Filtering

**What**: Only returns wallets where CryptoId equals BlockchainCryptoId.

**Columns/Parameters Involved**: `CryptoId`, `BlockchainCryptoId`

**Rules**:
- Filters out token sub-wallets (e.g., ERC-20 tokens on Ethereum)
- Only the base-chain wallet entry is checksum-validated
- Ordered by WalletRecordId for deterministic pagination

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SkipRecords | int | NO | - | VERIFIED | Pagination offset. |
| 2 | @MaxRecords | int | NO | - | VERIFIED | Page size. |
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID. |
| 4 | CryptoId (output) | int | NO | - | CODE-BACKED | Base-chain cryptocurrency. |
| 5 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. |
| 6 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. |
| 7 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 8 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary address. |
| 9 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal record ID (pagination key). |
| 10 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto (equals CryptoId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CustomerWalletsView | Filter + paginate | Base-chain wallets |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecuterUser | - | EXECUTE | Checksum validation batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsForChecksumsValidation (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Filtered base-chain wallet lookup |

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

### 8.1 Get first page
```sql
EXEC Wallet.GetWalletsForChecksumsValidation @SkipRecords = 0, @MaxRecords = 1000;
```

### 8.2 Get next page
```sql
EXEC Wallet.GetWalletsForChecksumsValidation @SkipRecords = 1000, @MaxRecords = 1000;
```

### 8.3 Direct equivalent
```sql
SELECT Id, CryptoId, BlockchainProviderWalletId AS ProviderWalletId, WalletProviderId, Gcid, Address, WalletRecordId AS RecordId, BlockchainCryptoId
FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE CryptoId = BlockchainCryptoId
ORDER BY WalletRecordId OFFSET 0 ROWS FETCH NEXT 1000 ROWS ONLY;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsForChecksumsValidation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsForChecksumsValidation.sql*
