# Wallet.GetCryptoData

> Stored procedure that returns comprehensive cryptocurrency configuration data for all active cryptos, including blockchain metadata, display settings, fee structures, and address validation patterns.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns enriched Wallet.CryptoTypes rows for active cryptos |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetCryptoData is the primary cryptocurrency configuration loader for the wallet application services. It returns a comprehensive dataset for every active cryptocurrency, combining data from `Wallet.CryptoTypes` with the address validation regex pattern from `Wallet.BlockchainCryptos`. This single call provides everything the application needs to configure crypto operations: display names, avatars, precision settings, blockchain explorer formats, fee parameters, staking display info, and asset categorization.

This procedure is typically called at application startup or during configuration refresh to populate in-memory crypto configuration caches. It only returns active cryptos (`IsActive=1`), filtering out decommissioned currencies.

---

## 2. Business Logic

### 2.1 Blockchain Address Pattern Join

**What**: Enriches crypto data with the address validation regex from the parent blockchain network.

**Columns/Parameters Involved**: CryptoTypes.BlockchainCryptoId, BlockchainCryptos.AddressPattern

**Rules**:
- INNER JOINs CryptoTypes to BlockchainCryptos on BlockchainCryptoId = Id
- The AddressPattern (aliased as AddressValidationRegex) is used client-side to validate blockchain addresses before submission
- Only active cryptos returned (WHERE IsActive = 1)
- MaxVerificationTimeMinutes is explicitly CAST to INT (from the native column type)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency identifier. Primary key from CryptoTypes. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Short ticker name (e.g., 'BTC', 'ETH'). |
| 3 | MinReqAccounts | int | NO | - | CODE-BACKED | Minimum wallet pool size requirement. |
| 4 | MinUnit | decimal | YES | - | CODE-BACKED | Minimum transferable unit (dust threshold equivalent). |
| 5 | Status | tinyint | YES | - | CODE-BACKED | Crypto operational status code. |
| 6 | MinReqVerifications | int | YES | - | CODE-BACKED | Minimum blockchain confirmations required before crediting. |
| 7 | MaxVerificationTimeMinutes | int | YES | - | CODE-BACKED | Maximum time (minutes) to wait for confirmations before timeout. Cast from native type. |
| 8 | IsActive | bit | NO | - | CODE-BACKED | Always 1 in results (filtered in WHERE). |
| 9 | CryptoActivityStatus | tinyint | YES | - | CODE-BACKED | Activity status for UI display (can differ from operational Status). |
| 10 | BalanceAssetName | varchar | YES | - | CODE-BACKED | Asset name used for balance display purposes. |
| 11 | SymbolFull | varchar | YES | - | CODE-BACKED | Full symbol for display (e.g., currency symbol). |
| 12 | DisplayName | varchar | YES | - | CODE-BACKED | Human-readable display name (e.g., 'Bitcoin', 'Ethereum'). |
| 13 | AvatarUrl | varchar | YES | - | CODE-BACKED | URL to the crypto asset's icon/avatar for UI rendering. |
| 14 | StakingSymbolFull | varchar | YES | - | CODE-BACKED | Display symbol for staking variant of this crypto. |
| 15 | StakingDisplayName | varchar | YES | - | CODE-BACKED | Display name for staking variant. |
| 16 | StakingAvatarUrl | varchar | YES | - | CODE-BACKED | Avatar URL for staking variant. |
| 17 | AddressValidationRegex | varchar | YES | - | CODE-BACKED | Regex pattern for validating blockchain addresses. From BlockchainCryptos.AddressPattern. |
| 18 | Precision | int | YES | - | CODE-BACKED | Number of decimal places for this crypto. |
| 19 | WebHookVerifications | int | YES | - | CODE-BACKED | Number of webhook verification confirmations. |
| 20 | StartMonitoringDelaySeconds | int | YES | - | CODE-BACKED | Delay before starting blockchain monitoring after transaction submission. |
| 21 | InitialFeeUnits | decimal | YES | - | CODE-BACKED | Initial fee units for fee estimation. |
| 22 | BlockchainExplorerFormat | varchar | YES | - | CODE-BACKED | URL template for blockchain explorer links (e.g., 'https://etherscan.io/tx/{0}'). |
| 23 | BlockchainCryptoId | int | YES | - | CODE-BACKED | Parent blockchain network ID (FK to BlockchainCryptos). |
| 24 | AssetTypeId | tinyint | YES | - | CODE-BACKED | Asset type classification (native coin vs token). |
| 25 | TagName | varchar | YES | - | CODE-BACKED | Tag/memo field label for blockchains that require it (e.g., 'Destination Tag' for XRP). |
| 26 | InstrumentId | int | YES | - | CODE-BACKED | Associated trading instrument for market rate lookups. |
| 27 | AssetBlockchainAddress | varchar | YES | - | CODE-BACKED | Smart contract address for token assets (NULL for native coins). |
| 28 | OrderIndex | int | YES | - | CODE-BACKED | Display sort order in the crypto list UI. |
| 29 | CryptoCategoryName | varchar | YES | - | CODE-BACKED | Category classification (e.g., 'Cryptocurrency', 'Stablecoin'). |
| 30 | IsEtoroHandlingFee | bit | YES | - | CODE-BACKED | Whether eToro charges a handling fee for this crypto. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.CryptoTypes | FROM | Primary crypto configuration data |
| BlockchainCryptoId | Wallet.BlockchainCryptos | INNER JOIN | Address validation regex pattern |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Primary crypto configuration loader at startup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCryptoData (procedure)
+-- Wallet.CryptoTypes (table)
+-- Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FROM - crypto configuration data |
| Wallet.BlockchainCryptos | Table | INNER JOIN - address validation patterns |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all active crypto configuration
```sql
EXEC Wallet.GetCryptoData
```

### 8.2 Specific crypto by ID after loading
```sql
SELECT CryptoId, Name, DisplayName, AddressValidationRegex, Precision
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON ct.BlockchainCryptoId = bc.Id
WHERE ct.IsActive = 1 AND ct.CryptoId = 1  -- BTC
```

### 8.3 Find token assets (non-native coins)
```sql
SELECT CryptoId, Name, AssetBlockchainAddress, BlockchainCryptoId
FROM Wallet.CryptoTypes ct WITH (NOLOCK)
JOIN Wallet.BlockchainCryptos bc WITH (NOLOCK) ON ct.BlockchainCryptoId = bc.Id
WHERE ct.IsActive = 1 AND ct.AssetBlockchainAddress IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCryptoData | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCryptoData.sql*
