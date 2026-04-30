# Wallet.GetWalletById

> Retrieves a customer wallet's core details by its unique ID with backward-compatible CryptoId resolution, serving as the primary wallet lookup endpoint for eight service consumers.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet row from CustomerWalletsView by WalletId + CryptoId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most widely used wallet lookup procedure, consumed by eight service accounts: AML, back-office API, balance, conversion, executer, redeem persistor, redeem scheduler, and scheduled jobs. It retrieves a wallet's core details (Gcid, CryptoId, address, provider wallet ID, blockchain crypto ID, record ID, provider ID) from CustomerWalletsView.

The procedure includes backward-compatible CryptoId resolution: if @CryptoId is NULL, it auto-resolves from CustomerWalletsView where CryptoId equals BlockchainCryptoId (the base-chain entry). The result includes BlockchainProviderWalletId twice - once by its full name and once aliased as ProviderWalletId for backward compatibility.

---

## 2. Business Logic

### 2.1 Backward-Compatible CryptoId Resolution

**What**: Auto-resolves CryptoId when not provided.

**Columns/Parameters Involved**: `@WalletId`, `@CryptoId`, `CustomerWalletsView`

**Rules**:
- If @CryptoId IS NULL, resolves from CustomerWalletsView WHERE Id = @WalletId AND CryptoId = BlockchainCryptoId
- The CryptoId = BlockchainCryptoId condition selects the base-chain wallet (not token sub-wallets)
- When @CryptoId IS provided, the resolution step is skipped

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | VERIFIED | The wallet to look up. |
| 2 | @CryptoId | int | YES | NULL | VERIFIED | Optional crypto filter. Auto-resolved if NULL. |
| 3 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Wallet ID (echo of @WalletId). |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer who owns this wallet. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency for this wallet entry. |
| 6 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Primary blockchain address. |
| 7 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider's reference ID for this wallet. Returned twice for backward compatibility. |
| 8 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Alias of BlockchainProviderWalletId. Backward compatibility name. |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | The base-chain crypto this wallet belongs to. |
| 10 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal wallet record ID (aliased from WalletRecordId). |
| 11 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet infrastructure provider. FK to Wallet.WalletProviders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletId + @CryptoId | Wallet.CustomerWalletsView | Lookup | Primary wallet data source |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML wallet verification |
| BackApiUser | - | EXECUTE | Back-office wallet lookup |
| BalanceUser | - | EXECUTE | Balance operations |
| ConversionUser | - | EXECUTE | Conversion wallet resolution |
| ExecuterUser | - | EXECUTE | Execution wallet context |
| RedeemPersistorUser | - | EXECUTE | Redemption wallet details |
| RedeemSchedulerUser | - | EXECUTE | Redeem scheduling |
| ScheduledJobsUser | - | EXECUTE | Scheduled job wallet context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletById (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Primary lookup by Id + CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, BalanceUser, ConversionUser, ExecuterUser, RedeemPersistorUser, RedeemSchedulerUser, ScheduledJobsUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up a wallet
```sql
EXEC Wallet.GetWalletById @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678', @CryptoId = 1;
```

### 8.2 Auto-resolve crypto
```sql
EXEC Wallet.GetWalletById @WalletId = 'C0D5EF83-1234-5678-9ABC-DEF012345678'; -- CryptoId auto-resolved
```

### 8.3 Direct equivalent
```sql
SELECT Id, Gcid, CryptoId, Address, BlockchainProviderWalletId, BlockchainProviderWalletId AS ProviderWalletId,
    BlockchainCryptoId, WalletRecordId AS RecordId, WalletProviderId
FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Id = 'C0D5EF83-...' AND CryptoId = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletById | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletById.sql*
