# Wallet.CryptoMarketRatesMappings

> Maps each cryptocurrency to its market rate feed symbol, enabling the system to fetch real-time USD prices for balance display, conversion calculations, and portfolio valuation.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table maps each supported cryptocurrency to its corresponding symbol in the market rate feed system. When the wallet needs to display a crypto balance in USD (or any fiat), it looks up the crypto's `MarketRatesCurrencySymbol` here and queries the rate feed for the current price. With 178 rows covering all 174 CryptoTypes (some may have aliases), this is a comprehensive rate mapping.

Without this table, the system could not resolve which rate feed to query for each crypto, breaking all USD-denominated balance displays, conversion pricing, and portfolio valuations.

The table includes mappings for native coins (BTC, ETH, etc.), ERC-20 tokens (USDT, LINK, UNI, etc.), and historical eToroX tokens (EURX, GLDX, etc.). FK to Wallet.CryptoTypes ensures referential integrity.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple 1:1 mapping between CryptoId and MarketRatesCurrencySymbol. See individual element descriptions in Section 4.

---

## 3. Data Overview

| Id | CryptoId | MarketRatesCurrencySymbol | Meaning |
|---|---|---|---|
| 69 | 1 | BTC | Bitcoin rate feed - primary crypto, most queried rate |
| 198 | 224 | USDT | Tether stablecoin - pegged to USD, rate should always be ~1.00 |
| 204 | 227 | UNI | Uniswap DeFi token rate feed |
| 246 | 64 | SOL | Solana - newest addition (Feb 2026) |
| 176 | 101 | EURX | eToroX Euro token - historical stablecoin product |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CryptoId | int | NO | - | VERIFIED | The cryptocurrency this mapping applies to. FK to Wallet.CryptoTypes.CryptoID. Unique constraint ensures one rate mapping per crypto. |
| 3 | MarketRatesCurrencySymbol | varchar(20) | NO | - | CODE-BACKED | Symbol used to query the market rate feed for this crypto's USD price. Usually matches the crypto ticker (BTC, ETH, USDT) but may differ for versioned tokens (KNC2, AXSV2, GALAV2). Unique constraint prevents duplicate symbols. |
| 4 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this mapping was created. Original mappings share 2019-11-26. Newer cryptos have later dates tracking their rate feed integration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CryptoId | Wallet.CryptoTypes | FK | Links to the crypto asset definition |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetCryptoMarketRatesMappings | - | Reader | Reads all mappings for rate resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.CryptoMarketRatesMappings (table)
└── Wallet.CryptoTypes (table)
      └── Wallet.BlockchainCryptos (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CryptoTypes | Table | FK target for CryptoId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetCryptoMarketRatesMappings | Stored Procedure | Reads all mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CryptoMarketRatesMappings | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_CryptoMarketRatesMappings__CryptoId | NC UNIQUE | CryptoId ASC | - | - | Active |
| IX_Wallet_CryptoMarketRatesMappings__MarketRatesCurrencySymbol | NC UNIQUE | MarketRatesCurrencySymbol ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_CryptoMarketRatesMappings__Occurred | DEFAULT | getutcdate() |
| FK_...CryptoId__Wallet_CryptoTypes_CryptoId | FK | CryptoId -> Wallet.CryptoTypes.CryptoID |

---

## 8. Sample Queries

### 8.1 Get rate symbol for a crypto
```sql
SELECT MarketRatesCurrencySymbol FROM Wallet.CryptoMarketRatesMappings WITH (NOLOCK) WHERE CryptoId = 1
```

### 8.2 List all rate mappings with crypto names
```sql
SELECT ct.Name AS Crypto, ct.DisplayName, cmr.MarketRatesCurrencySymbol
FROM Wallet.CryptoMarketRatesMappings cmr WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON cmr.CryptoId = ct.CryptoID
ORDER BY ct.Name
```

### 8.3 Find recently added rate mappings
```sql
SELECT ct.Name, cmr.MarketRatesCurrencySymbol, cmr.Occurred
FROM Wallet.CryptoMarketRatesMappings cmr WITH (NOLOCK)
JOIN Wallet.CryptoTypes ct WITH (NOLOCK) ON cmr.CryptoId = ct.CryptoID
ORDER BY cmr.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CryptoMarketRatesMappings | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.CryptoMarketRatesMappings.sql*
