# Wallet.GetWalletByProviderId

> Retrieves a customer wallet by its blockchain provider wallet ID with backward-compatible CryptoId resolution and JSON-aggregated addresses, used by six service consumers for provider-side wallet correlation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet row by BlockchainProviderWalletId + optional CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up a wallet by its blockchain provider's reference ID (e.g., the BitGo wallet ID). When blockchain providers report events (transaction confirmations, balance updates), they identify wallets by their own reference, not eToro's internal WalletId. This procedure bridges from the provider's identifier to eToro's internal wallet details.

Six services use this: AML, back-office API, balance, conversion, redeem persistor, and redeem scheduler. The procedure includes CryptoId auto-resolution (same pattern as GetWalletById) and returns all wallet addresses as a JSON array via JSON_QUERY + STRING_AGG from WalletAddresses.

---

## 2. Business Logic

### 2.1 Provider-to-Internal Wallet Resolution

**What**: Maps a blockchain provider's wallet identifier to internal wallet details.

**Columns/Parameters Involved**: `@ProviderWalletId`, `@CryptoId`

**Rules**:
- @ProviderWalletId matches CustomerWalletsView.BlockchainProviderWalletId
- If @CryptoId IS NULL, auto-resolved from base-chain entry (CryptoId = BlockchainCryptoId)
- Returns wallet addresses as JSON array: `["addr1","addr2"]` via STRING_AGG

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderWalletId | nvarchar(100) | NO | - | VERIFIED | Blockchain provider's wallet reference ID (e.g., BitGo wallet ID). |
| 2 | @CryptoId | int | YES | NULL | VERIFIED | Optional crypto filter. Auto-resolved if NULL. |
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 6 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary wallet address. |
| 7 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Echo of BlockchainProviderWalletId. |
| 8 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal wallet record ID. |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto. |
| 10 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet provider. FK to Wallet.WalletProviders. |
| 11 | Addresses (output) | nvarchar(max) | YES | - | CODE-BACKED | JSON array of all addresses for this wallet: `["addr1","addr2"]`. Aggregated from WalletAddresses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ProviderWalletId | Wallet.CustomerWalletsView.BlockchainProviderWalletId | Lookup | Provider-to-internal resolution |
| WalletId | Wallet.WalletAddresses | Subquery | Address JSON aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser, BackApiUser, BalanceUser, ConversionUser, RedeemPersistorUser, RedeemSchedulerUser | - | EXECUTE | Provider-side wallet correlation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletByProviderId (procedure)
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
| AmlUser, BackApiUser, BalanceUser, ConversionUser, RedeemPersistorUser, RedeemSchedulerUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up wallet by provider ID
```sql
EXEC Wallet.GetWalletByProviderId @ProviderWalletId = 'bitgo-wallet-abc123', @CryptoId = 1;
```

### 8.2 Auto-resolve crypto
```sql
EXEC Wallet.GetWalletByProviderId @ProviderWalletId = 'bitgo-wallet-abc123';
```

### 8.3 Direct equivalent
```sql
SELECT cwv.Id, cwv.Gcid, cwv.CryptoId, cwv.Address, cwv.BlockchainProviderWalletId AS ProviderWalletId,
    cwv.WalletRecordId AS RecordId, cwv.BlockchainCryptoId, cwv.WalletProviderId,
    JSON_QUERY((SELECT CONCAT('["',STRING_AGG(wa.Address, '","'),'"]') FROM Wallet.WalletAddresses wa WHERE wa.WalletId = cwv.Id)) AS Addresses
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
WHERE cwv.BlockchainProviderWalletId = 'bitgo-wallet-abc123' AND cwv.CryptoId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletByProviderId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletByProviderId.sql*
