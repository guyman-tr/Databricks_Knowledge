# Wallet.BlockchainCryptos

> Master reference table of all supported blockchain networks, defining each chain's identifier, address validation pattern, and blockchain provider mapping.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table represents the set of all blockchain networks supported by the eToro crypto wallet platform. Each row defines one blockchain (e.g., Bitcoin, Ethereum, Solana) with its unique identifier, ticker symbol, address validation regex, and associated coin provider implementation. This is the foundational reference table for the entire wallet system - virtually every wallet-related table references it directly or indirectly through `Wallet.CryptoTypes`.

Without this table, the system would have no registry of which blockchains are supported, how to validate addresses on each chain, or which provider API to use for a given blockchain. Every wallet creation, transaction send, transaction receive, and address validation depends on this data.

Rows are inserted when eToro adds support for a new blockchain. The table is rarely modified after initial insertion. The `CryptoCoinProviderId` column links each blockchain to its technical provider implementation (e.g., BitGo UTXO provider, BitGo Ethereum provider), while `AddressPattern` stores a regex used to validate user-submitted addresses before any blockchain operation. Four core Wallet tables reference this as a parent: `Wallet.CryptoTypes`, `Wallet.Wallets`, `Wallet.WalletPool`, and `Wallet.BlockchainCryptoProviders`.

---

## 2. Business Logic

### 2.1 Address Validation via Regex Patterns

**What**: Each blockchain has a unique address format validated by a regex pattern stored in `AddressPattern`.

**Columns/Parameters Involved**: `AddressPattern`, `Name`

**Rules**:
- Before any send or receive operation, the target address is validated against the `AddressPattern` for the relevant blockchain
- Each blockchain has a distinct regex: Bitcoin accepts base58 (1/3 prefix) and bech32 (bc1 prefix), Ethereum accepts 0x-prefixed hex, Ripple accepts r-prefixed base58check with optional destination tags
- The default pattern `(.*?)` (used for EOS) means all addresses are accepted - validation is deferred to the provider
- Patterns are updated when blockchains add new address formats (e.g., Bitcoin adding SegWit bech32)

### 2.2 Provider Routing

**What**: Each blockchain is assigned a specific coin provider that handles all API interactions with that chain.

**Columns/Parameters Involved**: `CryptoCoinProviderId`

**Rules**:
- Each blockchain maps to exactly one `CryptoCoinProviderId` in `Dictionary.CryptoCoinProviders`
- Most blockchains use BitGo-based providers (Id=1: BitGoBlockchainProviderV2 for UTXO chains, Id=2: BitGoEthereumProviderV2 for ETH)
- XRP uses BitgoRippleProviderV2 (Id=3), XLM uses BitGoStellarProviderV2 (Id=4), EOS uses BitGoEOSProviderV2 (Id=5)
- The provider determines the API used for wallet creation, transaction signing, balance queries, and webhook notifications

---

## 3. Data Overview

| Id | Name | CryptoCoinProviderId | AddressPattern (truncated) | Meaning |
|---|---|---|---|---|
| 1 | BTC | 1 | ^[13][a-km-zA-HJ-NP-Z1-9]...\|^bc1... | Bitcoin - the original cryptocurrency. Uses UTXO model. Supports legacy (1...), P2SH (3...), and SegWit (bc1...) address formats. First blockchain supported by eToro wallet. |
| 2 | ETH | 2 | ^0x[a-fA-F0-9]{40}$ | Ethereum - account-based blockchain supporting smart contracts and ERC-20 tokens. All ERC-20 tokens share this blockchain entry. |
| 4 | XRP | 3 | ^(r[1-9A-HJ-NP-Za-km-z]...:\d...)$ | Ripple/XRP - uses account-based model with optional destination tags (memo) for exchange deposits. Requires special provider. |
| 64 | SOL | 1 | ^[1-9A-HJ-NP-Za-km-z]{32,44}$ | Solana - high-performance blockchain added most recently (Feb 2026). Uses base58-encoded ed25519 public keys. |
| 18 | ADA | 1 | ^(addr1\|addr_test1)... | Cardano - proof-of-stake blockchain with complex bech32 address format. Added Mar 2022 to support staking features. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | VERIFIED | Unique blockchain network identifier. Manually assigned (not IDENTITY) to maintain stable IDs across environments. Referenced by Wallet.CryptoTypes, Wallet.Wallets, Wallet.WalletPool, and Wallet.BlockchainCryptoProviders as BlockchainCryptoId. Gaps exist in sequence (e.g., 5, 7 missing) - likely reserved IDs for blockchains that were planned but not launched. |
| 2 | Name | varchar(255) | NO | - | VERIFIED | Standard ticker symbol for the blockchain (e.g., BTC, ETH, XRP, SOL). Unique constraint enforced by IX_Wallet_BlockchainCryptos__Name. Used for human-readable identification and API parameter matching. |
| 3 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this blockchain was added to the system. Original blockchains (BTC, ETH, BCH, XRP, LTC, XLM) all share the same date (2019-06-11), indicating the initial platform launch batch. Newer chains have later dates tracking their go-live. |
| 4 | CryptoCoinProviderId | tinyint | NO | 1 | VERIFIED | Blockchain provider implementation used for this chain: 1=BitGoBlockchainProviderV2 (UTXO chains like BTC, LTC, BCH, also SOL, ADA, DOGE, TRX, ETC), 2=BitGoEthereumProviderV2 (ETH/ERC-20), 3=BitgoRippleProviderV2 (XRP), 4=BitGoStellarProviderV2 (XLM), 5=BitGoEOSProviderV2 (EOS). See [Crypto Coin Provider](../../_glossary.md#crypto-coin-provider). FK to Dictionary.CryptoCoinProviders. |
| 5 | AddressPattern | varchar(255) | NO | (.*?) | CODE-BACKED | Regex pattern for validating blockchain addresses before any transaction. Each blockchain has a unique pattern matching its address format. The default `(.*?)` accepts all strings (used when provider handles validation). Updated when chains add new address formats (e.g., Bitcoin SegWit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoCoinProviderId | Dictionary.CryptoCoinProviders | FK | Links blockchain to its technical API provider implementation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CryptoTypes | BlockchainCryptoId | FK | Each crypto asset type (coin or token) maps to one blockchain |
| Wallet.Wallets | BlockchainCryptoId | FK | Each wallet is created on a specific blockchain |
| Wallet.WalletPool | BlockchainCryptoId | FK | Pre-generated pool wallets are specific to a blockchain |
| Wallet.BlockchainCryptoProviders | BlockchainCryptoId | FK | Maps which wallet providers serve each blockchain |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (FK targets are Dictionary tables).

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CryptoCoinProviders | Table | FK target for CryptoCoinProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK on BlockchainCryptoId |
| Wallet.Wallets | Table | FK on BlockchainCryptoId |
| Wallet.WalletPool | Table | FK on BlockchainCryptoId |
| Wallet.BlockchainCryptoProviders | Table | FK on BlockchainCryptoId |
| Wallet.GetBlockchainCryptos | Stored Procedure | Reads Id and Name for API/UI listing |
| Wallet.GetCryptoData | Stored Procedure | JOINs for crypto configuration data |
| Wallet.GetNonAssignedBalanceAddresseses | Stored Procedure | JOINs for address management |
| Wallet.GetWalletsByBalanceAccounts | Stored Procedure | JOINs for wallet lookup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlockchainCryptos | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_BlockchainCryptos__Name | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_BlockchainCryptos__Occurred | DEFAULT | getutcdate() - auto-sets creation timestamp |
| BlockchainCryptosAddressPatternDefault | DEFAULT | (.*?) - permissive default pattern accepts all addresses |
| FK_Wallet_BlockchainCryptos_CryptoCoinProviderId__Dictionary_CryptoCoinProviders_Id | FK | CryptoCoinProviderId -> Dictionary.CryptoCoinProviders.Id |

---

## 8. Sample Queries

### 8.1 List all supported blockchains with their providers
```sql
SELECT bc.Id, bc.Name, ccp.Name AS ProviderName, bc.AddressPattern
FROM Wallet.BlockchainCryptos bc WITH (NOLOCK)
JOIN Dictionary.CryptoCoinProviders ccp WITH (NOLOCK) ON bc.CryptoCoinProviderId = ccp.Id
ORDER BY bc.Id
```

### 8.2 Find the blockchain for a given ticker
```sql
SELECT Id, Name, AddressPattern
FROM Wallet.BlockchainCryptos WITH (NOLOCK)
WHERE Name = 'ETH'
```

### 8.3 Count wallets per blockchain
```sql
SELECT bc.Name AS Blockchain, COUNT(w.Id) AS WalletCount
FROM Wallet.BlockchainCryptos bc WITH (NOLOCK)
LEFT JOIN Wallet.Wallets w WITH (NOLOCK) ON bc.Id = w.BlockchainCryptoId
GROUP BY bc.Name
ORDER BY WalletCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Blockchain Glossary | Confluence | General blockchain terminology and concepts used in the eToro crypto platform |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.BlockchainCryptos | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.BlockchainCryptos.sql*
