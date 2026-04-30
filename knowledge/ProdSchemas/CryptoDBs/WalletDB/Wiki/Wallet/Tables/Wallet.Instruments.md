# Wallet.Instruments

> Registry of tradeable crypto-currency pairs (instruments) used for conversions, market rate lookups, and mapping between crypto assets and fiat currencies.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | InstrumentId (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table defines all tradeable instrument pairs within the crypto wallet system. Each row represents a pair of assets (buy side and sell side) identified by their currency IDs from the eToro trading platform. InstrumentIds in the 100000+ range represent crypto and fiat currency pairs used for conversions, rate calculations, and trading position valuation.

Without this table, the system could not determine valid conversion pairs, look up exchange rates between crypto assets and fiat currencies, or link wallet operations to the trading platform's instrument framework. It is the bridge between the wallet system's internal currency identifiers and the eToro trading platform's instrument system.

Rows are inserted when new trading pairs are added. The table stores both crypto-to-fiat pairs (e.g., BTC/USD, ETH/EUR) and crypto-to-crypto pairs (e.g., ETH/BTC, ADA/DOGE). SellCurrencyId=1 indicates USD-denominated pairs (the most common). Referenced by `Wallet.CryptoTypes.InstrumentId` and `Wallet.FiatTypes.InstrumentId` for linking assets to their instruments.

---

## 2. Business Logic

### 2.1 Currency Pair Structure

**What**: Each instrument defines a directional pair with a buy (base) currency and sell (quote) currency.

**Columns/Parameters Involved**: `InstrumentId`, `BuyCurrencyId`, `SellCurrencyId`

**Rules**:
- BuyCurrencyId = the base asset being purchased (crypto IDs in 100000+ range)
- SellCurrencyId = the quote asset being sold in exchange (1=USD, 2=EUR, 3=GBP, 4=AUD, or another crypto)
- Most pairs have SellCurrencyId=1 (USD) since crypto is primarily priced in USD
- Cross-currency pairs exist for EUR, GBP, AUD and crypto-to-crypto swaps
- Unique constraint on (BuyCurrencyId, SellCurrencyId) prevents duplicate pairs

---

## 3. Data Overview

| Id | InstrumentId | BuyCurrencyId | SellCurrencyId | Meaning |
|---|---|---|---|---|
| 1 | 100000 | 100000 | 1 | BTC/USD - Bitcoin priced in US Dollars. The primary BTC instrument. |
| 2 | 100001 | 100001 | 1 | ETH/USD - Ethereum priced in US Dollars. |
| 15 | 100109 | 100000 | 2 | BTC/EUR - Bitcoin priced in Euros. Cross-currency pair for EU customers. |
| 25 | 100125 | 100001 | 100022 | ETH/DOGE - Ethereum to Dogecoin. Crypto-to-crypto conversion pair. |
| 27 | 100133 | 100001 | 100000 | ETH/BTC - Ethereum priced in Bitcoin. Major crypto-to-crypto pair. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate row identifier. Not used as FK target - InstrumentId is the business key. |
| 2 | InstrumentId | int | NO | - | VERIFIED | eToro trading platform instrument identifier. Clustered PK and business key. Values in 100000+ range for crypto instruments. Referenced implicitly by Wallet.CryptoTypes.InstrumentId and Wallet.FiatTypes.InstrumentId for linking assets to their primary trading pair. |
| 3 | BuyCurrencyId | int | NO | - | CODE-BACKED | Currency ID of the base (buy) asset in the pair. For crypto assets, values are in the 100000+ range (e.g., 100000=BTC, 100001=ETH). Maps to the eToro trading platform's internal currency ID system. |
| 4 | SellCurrencyId | int | NO | - | CODE-BACKED | Currency ID of the quote (sell) asset in the pair. Values: 1=USD, 2=EUR, 3=GBP, 4=AUD for fiat-quoted pairs. 100000+ values for crypto-to-crypto pairs (e.g., 100000=BTC, 100022=DOGE). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.CryptoTypes | InstrumentId | Implicit | Links each crypto asset to its primary USD trading instrument |
| Wallet.FiatTypes | InstrumentId | Implicit | Links each fiat currency to its exchange rate instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | Implicit reference via InstrumentId |
| Wallet.FiatTypes | Table | Implicit reference via InstrumentId |
| Wallet.GetInstrument | Stored Procedure | Reads instrument details by InstrumentId |
| Wallet.GetAllInstruments | Stored Procedure | Reads all instruments for API listing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Instruments | CLUSTERED PK | InstrumentId ASC | - | - | Active |
| IX_Wallet_Instruments__BuyCurrencyId_SellCurrencyId | NC UNIQUE | BuyCurrencyId ASC, SellCurrencyId ASC | - | - | Active |

### 7.2 Constraints

None (beyond PK and unique indexes).

---

## 8. Sample Queries

### 8.1 List all crypto-to-USD instruments
```sql
SELECT InstrumentId, BuyCurrencyId, SellCurrencyId
FROM Wallet.Instruments WITH (NOLOCK)
WHERE SellCurrencyId = 1
ORDER BY InstrumentId
```

### 8.2 Find all pairs for a specific crypto
```sql
SELECT InstrumentId, BuyCurrencyId, SellCurrencyId
FROM Wallet.Instruments WITH (NOLOCK)
WHERE BuyCurrencyId = 100000 OR SellCurrencyId = 100000  -- BTC pairs
ORDER BY InstrumentId
```

### 8.3 List crypto-to-crypto conversion pairs
```sql
SELECT i.InstrumentId, i.BuyCurrencyId, i.SellCurrencyId
FROM Wallet.Instruments i WITH (NOLOCK)
WHERE i.SellCurrencyId > 1000  -- Crypto-to-crypto (non-fiat sell side)
ORDER BY i.InstrumentId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Instruments | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Instruments.sql*
