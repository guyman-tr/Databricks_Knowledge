# Dictionary.PriceSourceName

> Master registry of 27 price data sources — stock exchanges, market data providers, and internal eToro pricing — used to identify the origin of instrument price feeds.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PriceSourceID (INT, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PriceSourceName identifies the source of price data for each instrument traded on the eToro platform. Every instrument receives its price feed from one or more sources — major exchanges (NASDAQ, LSE, HKEX), regional exchanges (Xetra, Euronext, SGX), data aggregators (Xignite), or eToro's own internal pricing engine.

This table exists because regulatory compliance requires knowing where each instrument's price originates. Best execution obligations, price transparency, and audit requirements demand that the platform tracks and reports which exchange or data provider supplied the price for each trade.

The PriceSourceID is used in Price.LiquidityProviderPriceSource to map liquidity providers to their price sources, and referenced by Trade.CheckValidInstruments for instrument validation, Trade.GetAllInstrumentData and Trade.GetAllInstrumentDisplayDatasForAPI for API instrument data, and Dictionary.GetPricesBy for price source lookups.

---

## 2. Business Logic

### 2.1 Price Source Categories

**What**: The 27 price sources group into distinct categories by function and geography.

**Columns/Parameters Involved**: `PriceSourceID`, `Name`

**Rules**:
- **Internal (0)** — eToro's own pricing engine. Used for instruments where eToro acts as the market maker (CFDs, crypto).
- **Data Aggregators (1)** — Xignite provides aggregated market data for instruments not directly fed from an exchange.
- **US Exchanges (2-3)** — CME (derivatives), NASDAQ (equities).
- **European Exchanges (4-7, 12-13, 17, 19-22)** — Chi-Ex, LSE PLC, Xetra, Euronext, BME, Nasdaq Nordic, CBOE EU, Wiener Borse, Prague SE, Warsaw SE, Budapest SE.
- **Middle East (8, 11)** — DFM (Dubai Financial Market), ADX (Abu Dhabi Securities Exchange).
- **Asia-Pacific (9, 14-16, 18, 29)** — HKEX, CBOE Japan, SGX, TWSE, CBOE AUS, KRX.
- **Americas (10)** — TMX (Canada).
- **India/Baltics (27-28)** — NSE, Nasdaq Baltic.
- **Alternative (30)** — Blue Ocean (extended-hours trading venue).

**Diagram**:
```
Price Source Geography
├── Internal: 0 = eToro
├── Aggregator: 1 = Xignite
├── Americas: 2 = CME, 3 = NASDAQ, 10 = TMX, 30 = Blue Ocean
├── Europe: 4-7, 12-13, 17, 19-22, 28
├── Middle East: 8 = DFM, 11 = ADX
├── Asia-Pacific: 9 = HKEX, 14-16, 18, 29 = KRX
└── India: 27 = NSE
```

---

## 3. Data Overview

| PriceSourceID | Name | Meaning |
|---|---|---|
| 0 | eToro | eToro's internal pricing engine — used for CFDs, crypto, and instruments where eToro provides the price quote. The default source for market-maker instruments. |
| 3 | NASDAQ | National Association of Securities Dealers Automated Quotations — primary US equities exchange. Source for Apple, Tesla, Microsoft, and thousands of US-listed stocks. |
| 5 | LSE PLC | London Stock Exchange — primary UK equities exchange. Source for FTSE 100 stocks and London-listed securities. |
| 9 | HKEX | Hong Kong Exchanges and Clearing — primary exchange for Hong Kong and China-linked equities. |
| 30 | Blue Ocean | Alternative trading system for extended-hours trading. Enables trading outside standard market hours. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceSourceID | int | NO | - | VERIFIED | Primary key identifying the price source. 0=eToro (internal), 1=Xignite, 2=CME, 3=NASDAQ, through 30=Blue Ocean. Referenced by Price.LiquidityProviderPriceSource and multiple Trade/Price procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Short code name for the price source (exchange ticker or provider name). Used in instrument configuration screens, API responses, and regulatory reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.LiquidityProviderPriceSource | PriceSourceID | Implicit | Maps liquidity providers to their price data sources |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.LiquidityProviderPriceSource | Table | Stores PriceSourceID per liquidity provider |
| Trade.CheckValidInstruments | Stored Procedure | Reader — validates instrument price source |
| Trade.GetAllInstrumentData | Stored Procedure | Reader — returns instrument data with price source |
| Trade.GetAllInstrumentDisplayDatasForAPI | Stored Procedure | Reader — API instrument display data |
| Price.GetAllLiquidityProviderPriceSource | Stored Procedure | Reader — loads all LP price source mappings |
| Price.InsertLiquidityProviderPriceSource | Stored Procedure | Writer — creates LP-to-price-source mapping |
| Price.UpdateLiquidityProviderPriceSource | Stored Procedure | Modifier — updates LP-to-price-source mapping |
| Dictionary.GetPricesBy | Stored Procedure | Reader — full read of PriceSourceName |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceSourceName | CLUSTERED PK | PriceSourceID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PriceSourceName | PRIMARY KEY | Unique price source identifier |

---

## 8. Sample Queries

### 8.1 List all price sources
```sql
SELECT  PriceSourceID,
        Name
FROM    [Dictionary].[PriceSourceName] WITH (NOLOCK)
ORDER BY PriceSourceID;
```

### 8.2 Find all European exchanges
```sql
SELECT  PriceSourceID,
        Name
FROM    [Dictionary].[PriceSourceName] WITH (NOLOCK)
WHERE   Name IN ('Chi-Ex', 'LSE PLC', 'Xetra', 'Euronext', 'BME', 'Nasdaq Nordic',
                  'CBOE EU', 'Wiener Borse', 'Prague SE', 'Warsaw SE', 'Budapest SE',
                  'Nasdaq Baltic')
ORDER BY Name;
```

### 8.3 Join price sources to liquidity providers
```sql
SELECT  lps.LiquidityProviderID,
        psn.Name AS PriceSourceName
FROM    [Price].[LiquidityProviderPriceSource] lps WITH (NOLOCK)
JOIN    [Dictionary].[PriceSourceName] psn WITH (NOLOCK)
        ON lps.PriceSourceID = psn.PriceSourceID
ORDER BY psn.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PriceSourceName | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PriceSourceName.sql*
