# Wallet.CustomerWalletsView

> The primary abstraction layer for accessing active customer wallets, joining wallet ownership, pool addresses, and visible crypto assets into a single denormalized row per customer-crypto combination.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | View (WITH SCHEMABINDING) |
| **Key Identifier** | Id (uniqueidentifier - the WalletId from Wallet.Wallets) |
| **Partition** | N/A |
| **Indexes** | N/A (SCHEMABINDING enables indexed view potential but no materialized indexes exist) |

---

## 1. Business Meaning

This view is the single most referenced object in the WalletDB Wallet schema, with 106+ SQL file references across stored procedures, functions, and other views. It answers the fundamental question: "Given a customer (Gcid) and a crypto asset (CryptoId), what is their wallet, its blockchain address, and its provider details?" Every transaction lookup, balance query, AML check, and wallet operation in the system resolves customer wallets through this view.

Without this view, every consumer would need to manually JOIN Wallet.Wallets + Wallet.WalletPool + Wallet.WalletAssets and apply the active/shown filters. Given that 70+ stored procedures and 8 other views depend on it, the view eliminates massive code duplication and ensures consistent filtering logic: only active wallets (IsActive=1) with visible assets (IsShown=1) are returned.

The view is built with SCHEMABINDING, meaning any DDL change to the three base tables must account for this view. Data flows into the base tables via wallet assignment (Wallet.AssociateWalletToCustomer, Wallet.AssignWallet) and asset creation, then this view exposes the denormalized result. Consumers include wallet lookups (GetWalletsByGcid, GetWalletById), transaction processing (StoreSentTransaction, StoreReceivedTransaction), balance reports (vu_GetWalletBalanceReport family), AML validation (AMLTransactionsView, Monitor_Validiations), and monitoring (OperationFailuresReport). Per Confluence (BG space), the "Crypto IN" initiative identifies this view as HIGH priority for future modification to support address-type wallets alongside traditional customer wallets.

---

## 2. Business Logic

### 2.1 Active Wallet Filter

**What**: The view enforces a two-part filter that ensures only operational, user-visible wallets are returned.

**Columns/Parameters Involved**: `IsActive` (from Wallets), `IsShown` (from WalletAssets)

**Rules**:
- `w.IsActive = 1`: Excludes deactivated wallets (deactivated by Wallet.DeactivateWallet). Deactivated wallets retain funds but cannot transact
- `wa.IsShown = 1`: Excludes hidden assets. Assets hidden via UI or system action are filtered out, ensuring only the user's visible portfolio appears
- The combination means: "active wallet AND visible asset" - both conditions must be true

**Diagram**:
```
Wallet.Wallets (1.49M rows)
    |-- IsActive = 1 --> PASS
    |-- IsActive = 0 --> EXCLUDED (deactivated)
    |
    JOIN Wallet.WalletPool ON WalletId
    JOIN Wallet.WalletAssets ON WalletId
    |-- IsShown = 1 --> PASS
    |-- IsShown = 0 --> EXCLUDED (hidden asset)
    |
    Result: 1.76M rows (active wallets with visible assets)
```

### 2.2 Activation Status Mapping

**What**: The view computes a Status column that maps the binary IsActivated flag to a status code compatible with downstream consumers.

**Columns/Parameters Involved**: `IsActivated` (from Wallets), `Status` (computed)

**Rules**:
- `IsActivated = 1` -> `Status = 0` (Created/Active - wallet fully operational)
- `IsActivated = 0` -> `Status = 5` (Pending activation - awaiting blockchain confirmation)
- 99.6% of rows have Status=0 (1,757,654 wallets), only 0.4% are Status=5 (6,865 wallets)
- This mapping provides backward compatibility with consumers that expect numeric status codes

### 2.3 One Wallet Per User Per Crypto Paradigm

**What**: The system architecture assumes one wallet per customer per crypto type, and this view enforces that model.

**Columns/Parameters Involved**: `Gcid`, `CryptoId`, `WalletTypeId`

**Rules**:
- The base table Wallet.Wallets has a unique constraint on (Gcid, BlockchainCryptoId, WalletTypeId) excluding types 1 and 6
- Consumers query this view with `WHERE Gcid = @gcid AND CryptoId = @cryptoId` expecting one result
- Per Confluence (Crypto IN - Address vs Wallet Flow Mapping, updated 2026-03-31): this paradigm is being extended to support multiple entries per user (wallet + addresses) for the Crypto IN feature

---

## 3. Data Overview

| Id | Gcid | CryptoId | Address (truncated) | WalletTypeId | Status | Meaning |
|---|---|---|---|---|---|---|
| 805B8ACE-... | 9661239 | 3 (LTC) | 3FvRmXJe1Udr... | 5 (Customer) | 0 | A customer's Litecoin wallet, fully activated and operational. The vast majority of rows look like this - type 5, status 0. |
| 55AC9E57-... | 9248755 | 2 (ETH) | 0x3226c9c6a7... | 5 (Customer) | 0 | A customer's Ethereum wallet. The 0x prefix identifies this as an EVM-compatible address. |
| 7A45100F-... | 9314277 | 1 (BTC) | 3Lyvmt5G3MBS... | 5 (Customer) | 0 | A customer's Bitcoin wallet. The "3" prefix indicates a P2SH (Pay-to-Script-Hash) address, typical for BitGo multi-sig. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | uniqueidentifier | NO | - | VERIFIED | The wallet's universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system - referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups. From Wallet.Wallets.WalletId. |
| 2 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets. From Wallet.Wallets.Gcid. |
| 3 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: `WHERE Gcid = @gcid AND CryptoId = @cryptoId`. From Wallet.WalletAssets.CryptoId. |
| 4 | Address | nvarchar(512) | YES | - | CODE-BACKED | Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes. |
| 5 | BlockchainProviderWalletId | nvarchar(100) | NO | - | CODE-BACKED | External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId. Format is provider-specific (typically a hex hash for BitGo). |
| 6 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering. |
| 7 | WalletTypeId | tinyint | NO | - | VERIFIED | Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. See [Wallet Type](../../_glossary.md#wallet-type). FK to Dictionary.WalletTypes. From Wallet.Wallets.WalletTypeId. |
| 8 | IsActive | bit | NO | - | CODE-BACKED | Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by view). From Wallet.Wallets.IsActive. |
| 9 | Status | int | NO | - | CODE-BACKED | Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in view: `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END`. 99.6% of rows are Status=0. |
| 10 | WalletRecordId | bigint | NO | - | CODE-BACKED | Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence. |
| 11 | BlockchainCryptoId | int | NO | - | VERIFIED | The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain). From Wallet.Wallets.BlockchainCryptoId. |
| 12 | WalletProviderId | int | NO | - | VERIFIED | Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). See [Wallet Provider](../../_glossary.md#wallet-provider). FK to Dictionary.WalletProvider. From Wallet.WalletPool.WalletProviderId. |
| 13 | IsActivated | bit | NO | - | CODE-BACKED | Whether the wallet has completed initial blockchain activation. 1=activated (fully operational), 0=pending activation. The Status column is derived from this value. From Wallet.Wallets.IsActivated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Id (WalletId) | Wallet.Wallets | JOIN (source) | Primary wallet registry - provides Gcid, WalletTypeId, IsActive, IsActivated, BlockchainCryptoId |
| Id (WalletId) | Wallet.WalletPool | JOIN (source) | Pool wallet details - provides PublicAddress, ProviderWalletId, WalletProviderId |
| Id (WalletId) | Wallet.WalletAssets | JOIN (source) | Asset visibility - provides CryptoId, Occurred, IsShown filter |
| CryptoId | Wallet.CryptoTypes | Implicit | Resolves crypto asset metadata (name, symbol, blockchain) |
| BlockchainCryptoId | Wallet.BlockchainCryptos | Implicit | Resolves blockchain network metadata |
| WalletTypeId | Dictionary.WalletTypes | Implicit | Resolves wallet type labels |
| WalletProviderId | Dictionary.WalletProvider | Implicit | Resolves provider names (BitGo, CUG) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.AMLTransactionsView | cwv.Id, cwv.CryptoId, cwv.Gcid | JOIN | Resolves wallet owner for AML-flagged transactions |
| Wallet.Monitor_Validiations | cwv.Id, cwv.Gcid | JOIN | Resolves wallet owner for recent AML validations |
| Wallet.vu_GetWalletBalanceReport | T1 (all columns) | JOIN | Customer identification in balance reconciliation |
| Wallet.vu_GetWalletBalanceReportV2 | T1 (all columns) | JOIN | Same as V1 with CryptoId 228 exclusion |
| Wallet.vu_GetWalletBalanceReportV3 | T1 (all columns) | JOIN | Same as V2 |
| Wallet.vw_WalletBalanaces | cwv.Id, cwv.CryptoId, cwv.Address | JOIN | Maps balances to addresses via this view |
| Wallet.V_WalletBalances | cw.Id, cw.CryptoId, cw.Gcid | JOIN | Provides Gcid/CryptoId for balance reporting |
| dbo.Monitor_Omnibus_Alert | (via JOIN) | JOIN | Omnibus wallet monitoring |
| Staking.StakingData | (via JOIN) | JOIN | Staking data enrichment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CustomerWalletsView (view, SCHEMABINDING)
+-- Wallet.Wallets (table)
+-- Wallet.WalletPool (table)
+-- Wallet.WalletAssets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Wallets | Table | JOIN on WalletId - provides wallet ownership (Gcid), type, activation status |
| Wallet.WalletPool | Table | JOIN on WalletId - provides blockchain address and provider details |
| Wallet.WalletAssets | Table | JOIN on WalletId - provides crypto asset info and visibility filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AMLTransactionsView | View | JOINs to resolve wallet owner for AML alerts |
| Wallet.Monitor_Validiations | View | JOINs to resolve wallet owner for recent validations |
| Wallet.vu_GetWalletBalanceReport | View | CTE uses as Customers source |
| Wallet.vu_GetWalletBalanceReportV2 | View | CTE uses as Customers source (excludes CryptoId 228) |
| Wallet.vu_GetWalletBalanceReportV3 | View | CTE uses as Customers source |
| Wallet.vu_GetWalletBalanceReport_temp | View | CTE uses as Customers source |
| Wallet.vw_WalletBalanaces | View | JOINs to map balances to addresses |
| Wallet.V_WalletBalances | View | JOINs to enrich balances with Gcid/CryptoId |
| Wallet.GetWalletsByGcid | Procedure | READER - primary wallet lookup by customer |
| Wallet.GetWalletsBalance | Procedure | READER - balance query by customer wallet |
| Wallet.GetWalletById | Procedure | READER - single wallet lookup |
| Wallet.StoreSentTransaction | Procedure | READER - validates wallet before storing send |
| Wallet.StoreAmlValidation | Procedure | READER - resolves wallet for AML check |
| Wallet.AssociateWalletToCustomer | Procedure | READER - checks existing wallet during assignment |
| Wallet.GetAllWallets | Procedure | READER - lists all wallets |
| 70+ additional procedures | Procedure | Various READER operations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. However, SCHEMABINDING enables the creation of indexed (materialized) views. No clustered index exists on this view currently, so it is not materialized.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | View Binding | Locks the view to its base table schemas. Any ALTER TABLE on Wallets, WalletPool, or WalletAssets that affects referenced columns requires dropping this view first. Prevents accidental schema drift. |

---

## 8. Sample Queries

### 8.1 Get all wallets for a specific customer
```sql
SELECT Id, CryptoId, Address, WalletTypeId, Status
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Gcid = 9661239
ORDER BY CryptoId
```

### 8.2 Find a wallet by its blockchain address
```sql
SELECT Id, Gcid, CryptoId, WalletProviderId, IsActivated
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Address = '0x3226c9c6a7c7b6099f091c4c97043e84bcf38cd0'
```

### 8.3 Count wallets by provider and activation status
```sql
SELECT
    wp.Name AS ProviderName,
    cwv.Status,
    COUNT(*) AS WalletCount
FROM Wallet.CustomerWalletsView cwv WITH (NOLOCK)
LEFT JOIN Dictionary.WalletProvider wp WITH (NOLOCK) ON wp.Id = cwv.WalletProviderId
GROUP BY wp.Name, cwv.Status
ORDER BY wp.Name, cwv.Status
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Crypto IN - Address vs Wallet Flow Mapping](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14165967515) | Confluence | CustomerWalletsView identified as HIGH priority for modification in Crypto IN initiative. System built on "one wallet per user per crypto" paradigm which this view enforces. Future address-type support will break this assumption. |
| [DB / sql / query cheatsheet](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/11816239603) | Confluence | Standard query pattern: `SELECT * FROM Wallet.CustomerWalletsView WHERE Gcid=@gcid AND CryptoId=@cryptoId AND WalletTypeId=@type` |
| [Crypto IN - SSO Request Service & Database Design](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14176452645) | Confluence | Describes wallet association flow that populates the base tables this view reads from |
| [Crypto IN - HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/14212399143) | Confluence | High-level design referencing CustomerWalletsView in the receive flow architecture |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 4 Confluence + 0 Jira | Procedures: 70+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CustomerWalletsView | Type: View | Source: WalletDB/Wallet/Views/Wallet.CustomerWalletsView.sql*
