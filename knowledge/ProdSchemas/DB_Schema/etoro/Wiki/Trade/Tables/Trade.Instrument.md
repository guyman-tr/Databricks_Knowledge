# Trade.Instrument

> Core instrument definition table that pairs a buy currency/asset with a sell currency to define every tradeable instrument on the eToro platform.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 7 active |

---

## 1. Business Meaning

Trade.Instrument is the foundational instrument definition table in the Trade schema. While Dictionary.Currency holds the master registry of all tradeable assets (stocks, forex, crypto, etc.), Trade.Instrument defines the **pairing relationship** between two Dictionary.Currency entries - the buy side and the sell side - that together form a tradeable instrument. For forex, this is literal (e.g., EUR/USD = BuyCurrencyID=EUR, SellCurrencyID=USD). For stocks and other non-forex assets, BuyCurrencyID equals the InstrumentID in Dictionary.Currency for that asset, and SellCurrencyID is the denomination currency.

This table exists because eToro's trading engine requires every instrument to have both a buy-side and sell-side definition for rate calculation, price conversion, and P&L computation. Without it, the system cannot determine how to quote prices or convert values to USD (or any other base currency). Every position, order, hedge, and exposure calculation ultimately depends on the instrument pairs defined here.

Data is created via `Trade.InstrumentAdd`, which calls `Internal.GetInstrumentID` to allocate the next available InstrumentID. The table is read by virtually every trading view and procedure - over 20 views and 20+ stored procedures reference it directly. Audit triggers (ASM-generated) track INSERT, UPDATE, and DELETE operations to `History.AuditHistory`, and system versioning tracks all row changes to `History.Instrument`.

---

## 2. Business Logic

### 2.1 Buy/Sell Currency Pairing

**What**: Every instrument is defined as a pair of currencies/assets from Dictionary.Currency.

**Columns/Parameters Involved**: `BuyCurrencyID`, `SellCurrencyID`

**Rules**:
- For **forex pairs**: BuyCurrencyID and SellCurrencyID are both actual currencies (e.g., InstrumentID=1: EUR/USD where BuyCurrencyID=2 (EUR), SellCurrencyID=1 (USD))
- For **stocks/ETFs/crypto**: BuyCurrencyID equals the InstrumentID in Dictionary.Currency for that asset (e.g., InstrumentID=1203: Bayer AG where BuyCurrencyID=1203), and SellCurrencyID is the denomination currency (e.g., EUR for European stocks, USD for US stocks)
- The combination (BuyCurrencyID, SellCurrencyID) is enforced UNIQUE by the `TISR_PAIR` index - no duplicate pairs
- Default value 0 for both columns maps to InstrumentID=0 (a system/placeholder record)

**Diagram**:
```
Forex:   InstrumentID=1  -> Buy=EUR(2)  / Sell=USD(1)   = EUR/USD pair
Stock:   InstrumentID=1203 -> Buy=1203(Bayer) / Sell=EUR(2) = Bayer AG in EUR
Crypto:  InstrumentID=2031 -> Buy=2031(easyJet) / Sell=GBX(666) = easyJet in GBP pence
```

### 2.2 DollarRatio - Price Scaling Factor

**What**: A multiplier used to normalize instrument prices to USD-comparable values.

**Columns/Parameters Involved**: `DollarRatio`

**Rules**:
- Most instruments have DollarRatio=1 (price is already in standard units)
- Japanese Yen pairs use DollarRatio=100 because JPY is quoted in 100ths (e.g., USD/JPY at 150 means 150 yen per dollar)
- Used in P&L calculations and conversion rate computations across the platform

### 2.3 Order Matching Engine (OME) Distribution

**What**: Instruments are distributed across multiple OME instances for load balancing.

**Columns/Parameters Involved**: `OMEID`, `ShardID`

**Rules**:
- OMEID values 2-5 distribute instruments roughly equally (~2,620 each) across 4 OME instances
- OMEID=1 is reserved (only 1 instrument, likely the system placeholder)
- ShardID distributes data across database shards: 1 (4,564), 2 (4,712), 8 (1,208), 0 (placeholder)
- These values determine which OME server handles order matching and which database shard stores position data

### 2.4 Operation Mode

**What**: Controls the trading operation mode for the instrument.

**Columns/Parameters Involved**: `OperationMode`

**Rules**:
- OperationMode=0 (default, 10,402 instruments): Standard trading mode
- OperationMode=1 (83 instruments): Alternate operation mode - observed primarily on European stock CFDs (e.g., Bayer AG, BMW) traded in non-USD denominations

---

## 3. Data Overview

| InstrumentID | BuyCurrencyID | BuyCurrency | SellCurrencyID | SellCurrency | IsMajor | DollarRatio | Meaning |
|---|---|---|---|---|---|---|---|
| 0 | 0 | (system) | 0 | (system) | true | 0 | System placeholder record with all zero values. Never used for real trading. |
| 1 | 2 | EUR | 1 | USD | true | 1 | EUR/USD - the most traded forex pair globally. Marked as major with standard dollar ratio. |
| 5 | 4 | JPY | 1 | USD | false | 100 | USD/JPY - Japanese Yen pair. DollarRatio=100 because JPY is quoted in hundredths compared to other currencies. |
| 1203 | 1203 | Bayer AG | 2 | EUR | false | 1 | European stock CFD. BuyCurrencyID equals InstrumentID, denominated in EUR. OperationMode=1. |
| 2031 | 2031 | easyJet | 666 | GBX | false | 1 | UK stock CFD denominated in GBP pence (GBX). OperationMode=1. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Primary key identifying the tradeable instrument pair. Allocated by `Internal.GetInstrumentID` during creation via `Trade.InstrumentAdd`. Values range from 0 (system placeholder) to 21,100,110. Referenced by virtually every trading table. |
| 2 | BuyCurrencyID | int | NO | 0 | VERIFIED | The buy-side asset of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the base currency (e.g., EUR in EUR/USD). For stocks/ETFs/crypto: the asset itself (BuyCurrencyID = the asset's CurrencyID in Dictionary.Currency). 10,252 distinct values. |
| 3 | SellCurrencyID | int | NO | 0 | VERIFIED | The sell-side (denomination) currency of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading currency (USD, EUR, GBX). 67 distinct values - far fewer than BuyCurrencyID since many assets share the same denomination. |
| 4 | TradeRange | smallint | NO | - | CODE-BACKED | The allowed trade range (pip distance) for the instrument. Determines how far from market price a pending order can be placed. Set during instrument creation via `Trade.InstrumentAdd`. |
| 5 | DollarRatio | decimal(8,2) | NO | - | VERIFIED | Price scaling factor for USD normalization. Most instruments = 1. Japanese Yen pairs = 100 (because JPY prices are 100x larger numerically). Used in P&L and conversion rate calculations across the platform. |
| 6 | Passport | timestamp | NO | - | CODE-BACKED | Row version / concurrency token. Automatically maintained by SQL Server. Returned as OUTPUT from `Trade.InstrumentAdd` for optimistic concurrency control. |
| 7 | PipDifferenceThreshold | bigint | YES | - | CODE-BACKED | Maximum allowed pip difference threshold for the instrument. Used for price validation - if a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. Values range from 1 to 10,000. Audited on INSERT/UPDATE/DELETE. |
| 8 | IsMajor | bit | NO | 0 | VERIFIED | Flag indicating whether the instrument is classified as a "major" instrument. 1 = major (5,831 instruments, includes all major forex pairs and many popular assets), 0 = minor (4,654 instruments). Affects spread calculations, margin requirements, and regulatory leverage caps (ESMA allows higher leverage for major forex pairs). |
| 9 | PriceServerID | int | YES | - | CODE-BACKED | Identifies which price server feeds rate data for this instrument. 14 distinct values (1-10, 15, 16, 25, 100). NULL for 1 record (the system placeholder). Determines the source of real-time price feeds. Audited on INSERT/UPDATE/DELETE. |
| 10 | ShardID | int | NO | - | VERIFIED | Database shard assignment for the instrument. Determines which database shard stores position and order data. Values: 0 (1 - placeholder), 1 (4,564 instruments), 2 (4,712), 8 (1,208). Audited on INSERT/UPDATE/DELETE. |
| 11 | OMEID | int | YES | - | CODE-BACKED | Order Matching Engine instance assignment. Determines which OME server handles order matching for this instrument. Values: 1 (1 - system), 2 (2,622), 3 (2,621), 4 (2,620), 5 (2,621). Round-robin distribution across 4 active OME instances. |
| 12 | DbLoginName | computed | NO | - | VERIFIED | Computed: `SUSER_NAME()`. Captures the SQL Server login name of the current session. Used for audit trail purposes alongside the ASM triggers. |
| 13 | AppLoginName | computed | NO | - | VERIFIED | Computed: `CONVERT(VARCHAR(500), CONTEXT_INFO())`. Reads the application-set context info to identify which application service made the change. Used for audit trail alongside DbLoginName. |
| 14 | SysStartTime | datetime2(7) | NO | GETUTCDATE() | VERIFIED | System versioning row start time. Automatically set when a row is inserted or updated. Part of the temporal table mechanism tracking all changes to History.Instrument. |
| 15 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | VERIFIED | System versioning row end time. Set to max datetime for current rows. When a row is updated or deleted, the previous version's SysEndTime is set to the modification time in History.Instrument. |
| 16 | OperationMode | tinyint | YES | 0 | CODE-BACKED | Trading operation mode for the instrument. 0 = Standard mode (10,402 instruments - default for all asset types), 1 = Alternate mode (83 instruments - primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BuyCurrencyID | Dictionary.Currency | FK | The buy-side asset/currency. For forex: base currency. For stocks: the asset itself. |
| SellCurrencyID | Dictionary.Currency | FK | The sell-side denomination currency. For forex: quote currency. For stocks: trading currency. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | InstrumentID | FK/JOIN | Maps instruments to their liquidity providers and trading configurations |
| Trade.InstrumentMetaData | InstrumentID | JOIN | Extended metadata for instruments (display names, categories, etc.) |
| Trade.InstrumentActivitySchedule | InstrumentID | JOIN | Trading hours and activity windows per instrument |
| Trade.InstrumentConversion | InstrumentID | JOIN | Currency conversion rates and mappings |
| Trade.InstrumentImages | InstrumentID | JOIN | Logos and visual assets for instruments |
| Trade.InstrumentSpread | InstrumentID | JOIN | Spread configurations per instrument |
| Trade.IndexDividends | InstrumentID | JOIN | Dividend payments for index instruments |
| Trade.TradonomiContracts | InstrumentID | JOIN | Liquidity provider contract assignments |
| Trade.LiquidityProviderContracts | InstrumentID | JOIN | Detailed liquidity provider contract terms |
| Trade.GetInstrument (view) | InstrumentID | JOIN | Core instrument view joining Instrument + metadata |
| Trade.GetProviderToInstrument (view) | InstrumentID | JOIN | Provider-instrument mapping view |
| Trade.GetPositionData (view) | InstrumentID | JOIN | Position data view enriched with instrument details |
| Trade.FnGetConversionInstrument (function) | InstrumentID | JOIN | Finds the conversion instrument for a given currency pair |
| Trade.InstrumentAdd (procedure) | InstrumentID | Writer | Creates new instrument records |
| Trade.InsertInstrumentRealTable (procedure) | InstrumentID | Writer | Bulk instrument data loading |
| Trade.GetAllInstrumentData (procedure) | InstrumentID | Reader | Retrieves full instrument dataset |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Instrument (table)
├── Dictionary.Currency (table) [via BuyCurrencyID FK]
└── Dictionary.Currency (table) [via SellCurrencyID FK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK target for both BuyCurrencyID and SellCurrencyID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | References InstrumentID |
| Trade.InstrumentMetaData | Table | References InstrumentID |
| Trade.InstrumentActivitySchedule | Table | References InstrumentID |
| Trade.InstrumentConversion | Table | References InstrumentID |
| Trade.InstrumentImages | Table | References InstrumentID |
| Trade.InstrumentSpread | Table | References InstrumentID |
| Trade.IndexDividends | Table | References InstrumentID |
| Trade.TradonomiContracts | Table | References InstrumentID |
| Trade.LiquidityProviderContracts | Table | References InstrumentID |
| Trade.GetInstrument | View | JOINs to Instrument for base instrument data |
| Trade.GetInstrumentConfiguration | View | JOINs to Instrument for configuration views |
| Trade.GetInstrumentDataDealing | View | JOINs for dealing desk data |
| Trade.GetProviderToInstrument | View | JOINs for provider mappings |
| Trade.GetPositionData | View | JOINs to resolve instrument info on positions |
| Trade.GetCurrentPriceAndConversionRate | View | JOINs for price conversion |
| Trade.FnGetConversionInstrument | Function | Reads Instrument to find conversion pairs |
| Trade.FunGetInstrumentConfiguration | Function | Reads instrument configuration |
| Trade.InstrumentAdd | Procedure | INSERTs new instruments |
| Trade.GetAllInstrumentData | Procedure | SELECTs instrument data |
| Trade.CheckValidInstruments | Procedure | Validates instrument configurations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TISR | NC PK (UNIQUE) | InstrumentID | - | - | Active |
| ClusteredIndex- | CLUSTERED (UNIQUE) | InstrumentID | - | - | Active |
| IXInstrumentID | NC | InstrumentID, SellCurrencyID | - | - | Active |
| IX_SellCurrencyID | NC | SellCurrencyID | InstrumentID, BuyCurrencyID | - | Active |
| TISR_BUY | NC | BuyCurrencyID | - | - | Active |
| TISR_PAIR | NC (UNIQUE) | BuyCurrencyID, SellCurrencyID | - | - | Active |
| TISR_SELL | NC | SellCurrencyID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TDCUR_TSISU | FK | BuyCurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_TDCUR_TSISV | FK | SellCurrencyID -> Dictionary.Currency(CurrencyID) |
| TISR_NULLBUY | DEFAULT | BuyCurrencyID defaults to 0 |
| TISR_NULLSELL | DEFAULT | SellCurrencyID defaults to 0 |
| DB_TradeInstrumentIsMajor | DEFAULT | IsMajor defaults to 0 (not major) |
| D_OperationMode | DEFAULT | OperationMode defaults to 0 (standard) |
| DF_Instrument_SysStart | DEFAULT | SysStartTime defaults to GETUTCDATE() |
| DF_Instrument_SysEnd | DEFAULT | SysEndTime defaults to '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Get all major forex instruments with currency names
```sql
SELECT i.InstrumentID,
       bc.Abbreviation AS BuyCurrency,
       sc.Abbreviation AS SellCurrency,
       i.DollarRatio,
       i.PriceServerID
  FROM Trade.Instrument i WITH (NOLOCK)
  JOIN Dictionary.Currency bc WITH (NOLOCK) ON i.BuyCurrencyID = bc.CurrencyID
  JOIN Dictionary.Currency sc WITH (NOLOCK) ON i.SellCurrencyID = sc.CurrencyID
 WHERE i.IsMajor = 1
   AND i.BuyCurrencyID < 100
   AND i.SellCurrencyID < 100
 ORDER BY i.InstrumentID
```

### 8.2 Find instruments assigned to a specific OME and shard
```sql
SELECT i.InstrumentID,
       i.OMEID,
       i.ShardID,
       i.OperationMode
  FROM Trade.Instrument i WITH (NOLOCK)
 WHERE i.OMEID = 3
   AND i.ShardID = 1
 ORDER BY i.InstrumentID
```

### 8.3 Instrument distribution summary by OME and shard
```sql
SELECT i.OMEID,
       i.ShardID,
       COUNT(*) AS InstrumentCount,
       SUM(CASE WHEN i.IsMajor = 1 THEN 1 ELSE 0 END) AS MajorCount
  FROM Trade.Instrument i WITH (NOLOCK)
 WHERE i.OMEID IS NOT NULL
 GROUP BY i.OMEID, i.ShardID
 ORDER BY i.OMEID, i.ShardID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Instruments MAPI 20 July 21 | Confluence | API documentation for instrument management endpoints |
| Instruments Discovery API | Confluence | API for instrument discovery and search functionality |
| No Prices - Add sources to instruments in Price desk | Confluence | Price feed configuration and source management for instruments |

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.1/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 3 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Instrument | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Instrument.sql*
