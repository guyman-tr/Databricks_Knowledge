# Wallet.GetWalletByWalletProviderId

> Retrieves wallet details by the WalletProviderId (infrastructure provider reference), returning base-chain wallets with their addresses as JSON, used by the redeem persistor for provider-specific wallet resolution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet rows by BlockchainProviderWalletId (base-chain only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up wallets by their blockchain provider wallet ID, filtering to base-chain entries only (CryptoId = BlockchainCryptoId). Unlike `GetWalletByProviderId` which accepts an optional CryptoId parameter, this procedure always returns base-chain wallets and returns all matching entries (not just one). Each result includes addresses as a JSON array from WalletAddresses.

The redeem persistor service uses this to resolve wallet details when the provider reports events by their internal wallet reference.

---

## 2. Business Logic

### 2.1 Base-Chain Wallet Filtering

**What**: Only returns wallets where CryptoId equals BlockchainCryptoId.

**Columns/Parameters Involved**: `CryptoId`, `BlockchainCryptoId`

**Rules**:
- Filters CustomerWalletsView WHERE CryptoId = BlockchainCryptoId
- This excludes token sub-wallets (e.g., ERC-20 tokens on Ethereum where CryptoId != BlockchainCryptoId)
- Returns only the base-chain wallet entries for the given provider ID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletProviderId | nvarchar(100) | NO | - | VERIFIED | Provider's wallet reference ID to look up. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID (aliased from WalletId). |
| 3 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Echo of BlockchainProviderWalletId. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer who owns the wallet. |
| 5 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary wallet address. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Base-chain cryptocurrency (always = BlockchainCryptoId). |
| 7 | Addresses (output) | nvarchar(max) | YES | - | CODE-BACKED | JSON array of all addresses from WalletAddresses via FOR JSON AUTO. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletProviderId | Wallet.CustomerWalletsView.BlockchainProviderWalletId | Lookup | Provider wallet resolution |
| WalletId | Wallet.WalletAddresses | Subquery (JSON) | Address aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemPersistorUser | - | EXECUTE | Provider-specific wallet resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletByWalletProviderId (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.WalletAddresses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Lookup by BlockchainProviderWalletId |
| Wallet.WalletAddresses | Table | JSON address aggregation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemPersistorUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up wallet by provider wallet ID
```sql
EXEC Wallet.GetWalletByWalletProviderId @WalletProviderId = 'bitgo-wallet-abc123';
```

### 8.2 Direct equivalent
```sql
SELECT cw.Id AS WalletId, cw.BlockchainProviderWalletId AS ProviderWalletId, cw.Gcid, cw.Address, cw.CryptoId,
    (SELECT wa.Address FROM Wallet.WalletAddresses wa WITH (NOLOCK) WHERE wa.WalletId = cw.Id FOR JSON AUTO) AS Addresses
FROM Wallet.CustomerWalletsView cw WITH (NOLOCK)
WHERE cw.BlockchainProviderWalletId = 'bitgo-wallet-abc123' AND cw.CryptoId = cw.BlockchainCryptoId;
```

### 8.3 Compare with sibling SP
```sql
-- By provider ID with crypto filter:
EXEC Wallet.GetWalletByProviderId @ProviderWalletId = 'bitgo-wallet-abc123', @CryptoId = 1;
-- By provider ID, base-chain only (this SP):
EXEC Wallet.GetWalletByWalletProviderId @WalletProviderId = 'bitgo-wallet-abc123';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletByWalletProviderId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletByWalletProviderId.sql*
