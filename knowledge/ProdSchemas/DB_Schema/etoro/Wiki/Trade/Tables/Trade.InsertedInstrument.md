# Trade.InsertedInstrument

> Staging table for bulk instrument insertion; holds validated instrument definitions before insertion into Trade.Instrument and related tables.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY) |
| **Partition** | PRIMARY |
| **Indexes** | None specified in DDL |

---

## 1. Business Meaning

Trade.InsertedInstrument is a staging table for bulk instrument insertion. It holds instrument definitions loaded from external sources (e.g. CSV or ETL) with all properties needed to create a new tradable instrument: name, exchange, tickers for multiple providers (Xignite, IB, IG, Saxo, EXANTE), currency mappings, fee configurations, trading limits (pip difference, max position, precision), and provider-specific mappings (ExchangeID_IB, ExchangeID_SAXO, RateConversionFactor).

Trade.CheckAllInstrumentUpload validates rows in this table before processing. Trade.InsertInstrumentRealTable then moves validated rows into Trade.Instrument and related tables. The CopyMainpropertiesFromInstrument column allows cloning base settings from an existing InstrumentID to reduce duplication when adding similar instruments.

The live database contains 53 rows. Sample data includes instruments such as "Nikola Corp" (NKLA, InstrumentID=6481), "USD/RON" (FX pair, InstrumentID=83), and "Crude Oil Future December 21" (commodity, InstrumentID=133).

---

## 2. Business Logic

- Validation: Trade.CheckAllInstrumentUpload checks required fields, ticker uniqueness, and referential integrity before insert.
- Insert: Trade.InsertInstrumentRealTable processes validated rows into Trade.Instrument and related tables (InstrumentToFeeConfig, etc.).
- CopyMainpropertiesFromInstrument: When set, base properties are copied from the referenced InstrumentID before applying row-specific overrides.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | 53 |
| Typical use | Staging for new instruments before production insert |
| Sample instruments | Nikola Corp (NKLA), USD/RON, Crude Oil Future Dec 21 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NOT NULL | IDENTITY(1,1) | High | Surrogate key for staging row |
| 2 | Name | varchar(500) | NULL | - | High | Instrument display name |
| 3 | Exchange | varchar(255) | NULL | - | Medium | Exchange name (legacy) |
| 4 | Industry | varchar(255) | NULL | - | Medium | Industry classification |
| 5 | ISINCode | varchar(500) | NULL | - | Medium | ISIN identifier |
| 6 | UnitMargin | int | NULL | - | Medium | Unit margin setting |
| 7 | Ticker_Xignite | varchar(255) | NULL | - | High | Ticker for Xignite provider |
| 8 | Ticker_IB | varchar(255) | NULL | - | High | Ticker for Interactive Brokers |
| 9 | Ticker_IG | varchar(255) | NULL | - | High | Ticker for IG |
| 10 | Ticker_saxo | varchar(255) | NULL | - | High | Ticker for Saxo |
| 11 | Ticker_EXANTE | varchar(255) | NULL | - | High | Ticker for EXANTE |
| 12 | InstrumentID | int | NULL | - | High | Output: assigned InstrumentID after insert, or source for CopyMainpropertiesFromInstrument |
| 13 | BuyCurrencyID | int | NULL | - | High | Currency for buy side |
| 14 | SellCurrencyID | int | NULL | - | High | Currency for sell side |
| 15 | CopyMainpropertiesFromInstrument | int | NULL | - | High | InstrumentID to clone base settings from |
| 16 | SymbolFull | varchar(255) | NULL | - | Medium | Full symbol |
| 17 | Abbreviation | varchar(255) | NULL | - | Medium | Short symbol |
| 18 | DisplayName | varchar(255) | NULL | - | Medium | Display name |
| 19 | ExchangeID | int | NULL | - | High | FK to exchange |
| 20 | StocksIndustryID | int | NULL | - | Medium | Industry FK |
| 21 | IsMajor | int | NULL | - | Medium | Major instrument flag |
| 22 | IsRealAsset | int | NULL | - | Medium | Real asset flag |
| 23 | CurrencyTypeID | int | NULL | - | Medium | Currency type classification |
| 24 | PipDifferenceThreshold | int | NULL | - | Medium | Pip threshold for validation |
| 25 | MaxPositionUnits | int | NULL | - | Medium | Max position size |
| 26 | Precision | int | NULL | - | High | Decimal precision for prices |
| 27 | InstrumentTypeSubCategoryID | int | NULL | - | High | Instrument subcategory |
| 28 | MinOrderSizeForExecutionInEToroUnits | int | NULL | - | Medium | Min order size |
| 29 | HBCDealSizeThresholdAlertInEToroUnits | int | NULL | - | Medium | HBC alert threshold |
| 30 | HBCMaxDealSizeThresholdRejectInEToroUnits | int | NULL | - | Medium | HBC reject threshold |
| 31 | ManualMaxDealSizeInEToroUnits | int | NULL | - | Medium | Manual max deal size |
| 32 | VolatiliyFeatureValue | int | NULL | - | Medium | Volatility feature value |
| 33 | InstrumentTypeID | int | NULL | - | High | Instrument type FK |
| 34+ | 8 fee columns | decimal | varies | - | High | NonLeveraged/Leveraged * Buy/Sell * OverNight/EndOfWeek |
| - | Provider columns | varies | - | - | Medium | ExchangeID_IB, ExchangeID_SAXO, RateConversionFactor* |
| - | PriceSourceID | int | NULL | - | Medium | Price source FK |
| - | ShardID | int | NULL | - | Medium | Shard assignment |

---

## 5. Relationships

### 5.1 References To
- Trade.Instrument (InstrumentID via CopyMainpropertiesFromInstrument)
- Exchange, Currency, InstrumentType, etc. (via various ID columns)

### 5.2 Referenced By
- Trade.CheckAllInstrumentUpload - validates rows
- Trade.InsertInstrumentRealTable - processes validated rows into production tables

---

## 6. Dependencies

### 6.1 Objects This Depends On
- Trade.Instrument (for CopyMainpropertiesFromInstrument)
- Dictionary/exchange/currency tables for FK resolution

### 6.2 Objects That Depend On This
- Trade.CheckAllInstrumentUpload
- Trade.InsertInstrumentRealTable

---

## 7. Technical Details

### 7.1 Indexes
None specified in provided DDL.

### 7.2 Constraints
None specified beyond IDENTITY on ID.

---

*Generated: 2026-03-14 | Quality: 8.0/10*
*Object: Trade.InsertedInstrument | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InsertedInstrument.sql*
