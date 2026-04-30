# Wallet.CryptoProviderContract

> Defines the technical contract between each cryptocurrency and its blockchain provider, including denomination units, ticker symbols, dust thresholds, and initial activation settings.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table stores the technical configuration for how each cryptocurrency interacts with its blockchain provider. Each row defines the denomination system (e.g., Bitcoin uses "satoshi" with 10^8 units per coin, Ethereum uses "wei" with 10^18 units), the provider's ticker symbol for production and test environments, the dust threshold (minimum meaningful amount), and whether wallets for this crypto are initially activated. With 174 rows matching all CryptoTypes, this is a comprehensive provider configuration table.

---

## 2. Business Logic

### 2.1 Denomination and Unit Conversion

**What**: Each crypto has a smallest unit denomination used by the provider API.

**Columns/Parameters Involved**: `Denomination`, `Units`, `CryptoId`

**Rules**:
- BTC: "satoshi", 100000000 units per coin (10^8)
- ETH: "wei", 1000000000000000000 units per coin (10^18)
- XRP: "drop", 1000000 units per coin (10^6)
- LTC/BCH: "satoshi", 100000000 units per coin (10^8)
- Provider APIs work in smallest units; the system converts for display

### 2.2 Dust Threshold

**What**: Minimum amount below which a transaction output is considered "dust" and rejected by the blockchain.

**Columns/Parameters Involved**: `DustThreshold`, `CryptoId`

**Rules**:
- BTC/BCH: 2730 satoshis - below this, outputs are rejected by the network
- LTC: 100000 satoshis - higher threshold than BTC
- ETH/XRP: 0 - no dust threshold (any amount is valid)

---

## 3. Data Overview

| Id | CryptoId | Denomination | Units | ProdEnvTicker | DustThreshold | Meaning |
|---|---|---|---|---|---|---|
| 1 | 1 (BTC) | satoshi | 100000000 | btc | 2730 | Bitcoin: 1 BTC = 10^8 satoshis. Dust threshold 2730 sat (~$0.70). |
| 2 | 2 (ETH) | wei | 10^18 | eth | 0 | Ethereum: 1 ETH = 10^18 wei. No dust threshold. |
| 5 | 4 (XRP) | drop | 1000000 | xrp | 0 | Ripple: 1 XRP = 10^6 drops. No dust threshold. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency this configuration applies to. Implicit to Wallet.CryptoTypes. Part of unique constraint with ProviderId. |
| 3 | ProviderId | int | NO | - | CODE-BACKED | Blockchain provider ID (1=BitGo, 2=CUG). Part of unique constraint with CryptoId. |
| 4 | Denomination | varchar(32) | NO | - | VERIFIED | Name of the smallest unit: "satoshi" (BTC/BCH/LTC), "wei" (ETH), "drop" (XRP), etc. |
| 5 | Units | decimal(20,0) | NO | - | VERIFIED | Number of smallest units per one whole coin. Used for API amount conversion. |
| 6 | ProdEnvTicker | varchar(32) | NO | - | CODE-BACKED | Provider's production environment ticker symbol (e.g., "btc", "eth", "xrp"). |
| 7 | TestEnvTicker | varchar(32) | YES | - | CODE-BACKED | Provider's test environment ticker (e.g., "tbtc", "teth"). NULL for cryptos without test networks. |
| 8 | DustThreshold | int | NO | - | VERIFIED | Minimum meaningful amount in smallest units. Transactions below this are rejected as "dust". |
| 9 | IsInitiallyActivated | bit | NO | 1 | CODE-BACKED | Whether wallets for this crypto are activated immediately on creation: 1=yes, 0=requires explicit activation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK references (CryptoId and ProviderId are implicit).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetCryptoProvidersContract | - | Reader | Reads provider contracts |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no explicit FK dependencies.

### 6.1 Objects This Depends On

No explicit FK dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetCryptoProvidersContract | Stored Procedure | Reads contracts |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CryptoProviderContract_Id | CLUSTERED PK | Id ASC | - | - | Active |
| Unique_CryptoProviderContract | NC UNIQUE | ProviderId, CryptoId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (IsInitiallyActivated) | DEFAULT | 1 |

---

## 8. Sample Queries

### 8.1 List all provider contracts with crypto names
```sql
SELECT ct.Name AS Crypto, cpc.Denomination, cpc.Units, cpc.ProdEnvTicker, cpc.DustThreshold
FROM Wallet.CryptoProviderContract cpc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON cpc.CryptoId = ct.CryptoID
WHERE cpc.ProviderId = 1
ORDER BY ct.Name
```

### 8.2 Find contract for a specific crypto
```sql
SELECT * FROM Wallet.CryptoProviderContract WITH (NOLOCK) WHERE CryptoId = 1
```

### 8.3 Cryptos with dust thresholds
```sql
SELECT ct.Name, cpc.DustThreshold, cpc.Denomination
FROM Wallet.CryptoProviderContract cpc WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON cpc.CryptoId = ct.CryptoID
WHERE cpc.DustThreshold > 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CryptoProviderContract | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.CryptoProviderContract.sql*
