# History.CurrencyPriceMaxDateClosingPriceWithSplitView

> Price cache table storing three split-adjusted price snapshots per instrument (most-recent price, official closing price, and end-of-day closing rate), used as the data source for end-of-day PnL calculations on open positions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID - clustered (one row per instrument, no PK constraint) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED CIX1 on InstrumentID, NC NCix on Occurred) |

---

## 1. Business Meaning

This table is an extension of `History.CurrencyPriceMaxDateWithSplitView` that adds two additional price snapshots per instrument alongside the most-recent price. Where `CurrencyPriceMaxDateWithSplitView` holds only the latest price, this table holds **three simultaneous price snapshots** for each instrument, enabling the system to calculate both current and end-of-day PnL for open positions.

The three price groups are:
1. **MaxDate prices** (`MaxDate_*` columns) - the most recent available price for the instrument
2. **Closing prices** (`ClosingPrice_*` columns) - the official end-of-day closing price (with a PriceType to classify the close)
3. **End-of-day calculation rate** (plain columns with no prefix) - the price used as the actual calculation rate for end-of-day PnL, along with a `Close_SourceID` identifying its origin

All prices are **split-adjusted** (the "WithSplitView" part of the name), meaning stock splits are factored into the stored values so that historical prices are comparable to current prices.

The primary consumer is `Trade.OpenPositionEndOfDay` (and its variant `Trade.OpenPositionEndOfDay With2Pnl`), which reads this table to compute both a "MaxDate PnL" (what the position is worth right now) and a "Close PnL" (what the position was worth at end-of-day close). The table is on the [MAIN] filegroup, consistent with its role as a high-frequency read cache rather than a traditional archive.

---

## 2. Business Logic

### 2.1 Three-Price-Group Architecture

**What**: Each instrument row stores three distinct price snapshots serving different PnL calculation purposes.

**Columns/Parameters Involved**: `MaxDate_*`, `ClosingPrice_*`, plain-prefix columns (`AskSpreaded`, `BidSpreaded`, `Bid`, `Ask`, `Occurred`, `PriceRateID`, `PriceType`, `Close_SourceID`)

**Rules**:
- **MaxDate group** (`MaxDate_AskSpreaded`, `MaxDate_BidSpreaded`, `MaxDate_Bid`, `MaxDate_Ask`, `MaxDate_PriceRateID`, `MaxDate_Occurred`): The most recent price tick. Used in `Trade.OpenPositionEndOfDay` as the "current rate" for live PnL via `FnCalculatePnLWrapper`.
- **ClosingPrice group** (`ClosingPrice_AskSpreaded`, `ClosingPrice_BidSpreaded`, `ClosingPrice_Bid`, `ClosingPrice_Ask`, `ClosingPrice_PriceRateID`, `ClosingPrice_Occurred`, `ClosingPrice_PriceType`): The official closing price from the market or exchange. `ClosingPrice_PriceType` classifies the close (e.g., regular session close vs. auction).
- **End-of-day calculation group** (plain `AskSpreaded`, `BidSpreaded`, `Bid`, `Ask`, `Occurred`, `PriceRateID`, `PriceType`, `Close_SourceID`): In `Trade.OpenPositionEndOfDay` these are aliased as `Close_*` and used as the rate for end-of-day PnL. `Close_SourceID` identifies the data source for this price.

**Diagram**:
```
Per InstrumentID row contains:
+---------------------------+----------------------------------+----------------------------------+
| MaxDate group             | ClosingPrice group               | End-of-Day Calc group            |
| (most recent live price)  | (official market close)          | (rate for EOD PnL calc)          |
|---------------------------|----------------------------------|----------------------------------|
| MaxDate_AskSpreaded       | ClosingPrice_AskSpreaded         | AskSpreaded                      |
| MaxDate_BidSpreaded       | ClosingPrice_BidSpreaded         | BidSpreaded                      |
| MaxDate_Bid               | ClosingPrice_Bid                 | Bid                              |
| MaxDate_Ask               | ClosingPrice_Ask                 | Ask                              |
| MaxDate_PriceRateID       | ClosingPrice_PriceRateID         | PriceRateID                      |
| MaxDate_Occurred          | ClosingPrice_Occurred            | Occurred                         |
|                           | ClosingPrice_PriceType           | PriceType                        |
|                           |                                  | Close_SourceID                   |
+---------------------------+----------------------------------+----------------------------------+
```

### 2.2 Closing Rate Selection for PnL (Buy/Sell and Real/CFD)

**What**: The end-of-day calculation group selects different columns based on position direction (Buy/Sell) and settlement type (Real vs CFD).

**Columns/Parameters Involved**: `BidSpreaded`, `Bid`, `AskSpreaded`, `Ask`

**Rules** (from `Trade.OpenPositionEndOfDay`):
- BUY + CFD: use `BidSpreaded` as closing rate (customer sells back at bid with spread)
- BUY + Real stock: use `Bid` (no spread for real stock settlement)
- SELL + CFD: use `AskSpreaded` as closing rate
- SELL + Real stock: use `Ask` (no spread for real stock settlement)
- The spread columns represent the market-maker markup applied on top of raw prices.

---

## 3. Data Overview

The table currently contains 0 rows in this environment. This table is populated by a periodic job that runs at market close to capture end-of-day prices for all instruments. A representative row for a stock instrument would look like:

| InstrumentID | MaxDate_Ask | MaxDate_Occurred | ClosingPrice_Ask | ClosingPrice_PriceType | Ask (EOD rate) | Close_SourceID | Meaning |
|---|---|---|---|---|---|---|---|
| 1234 | 185.50 | 2024-06-20 20:59:59 | 185.42 | 1 | 185.42 | 3 | For Apple stock: most recent price 185.50, official NYSE closing price 185.42 (PriceType=1 regular session), EOD calc rate also 185.42 from source 3. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | YES | - | CODE-BACKED | Instrument identifier - de-facto primary key (one row per instrument). Clustered index key. FK to Trade.InstrumentMetaData / Trade.Instrument (cross-schema). All three price groups in the row belong to this instrument. |
| 2 | MaxDate_AskSpreaded | decimal(33,16) | YES | - | CODE-BACKED | Most recent ask price with spread applied (what customers buy at), split-adjusted. Used in Trade.OpenPositionEndOfDay as the "max rate" for BUY CFD positions in current PnL calculation. 16 decimal places for precision across crypto, forex, and stock price scales. |
| 3 | MaxDate_BidSpreaded | decimal(33,16) | YES | - | CODE-BACKED | Most recent bid price with spread applied (what customers sell at), split-adjusted. Used as the "max rate" for SELL CFD positions in current PnL calculation. |
| 4 | MaxDate_Bid | decimal(33,16) | YES | - | CODE-BACKED | Most recent raw market bid price without spread, split-adjusted. Used as the "max rate" for BUY real-stock positions (real stock settlement has no spread deduction). |
| 5 | MaxDate_Ask | decimal(33,16) | YES | - | CODE-BACKED | Most recent raw market ask price without spread, split-adjusted. Used as the "max rate" for SELL real-stock positions. |
| 6 | MaxDate_PriceRateID | bigint | YES | - | CODE-BACKED | ID of the price tick record from which the MaxDate price group was derived. Referenced in Trade.OpenPositionEndOfDay as the CurrentCalculationRateID for current PnL. Links to the price feed system. |
| 7 | MaxDate_Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the MaxDate price tick occurred. Exposed as CurrentOccurred in Trade.OpenPositionEndOfDay. |
| 8 | ClosingPrice_AskSpreaded | decimal(33,16) | YES | - | CODE-BACKED | Official end-of-day ask price with spread applied, split-adjusted. The ClosingPrice group represents the formal market closing price for the trading session. |
| 9 | ClosingPrice_BidSpreaded | decimal(33,16) | YES | - | CODE-BACKED | Official end-of-day bid price with spread applied, split-adjusted. |
| 10 | ClosingPrice_Bid | decimal(33,16) | YES | - | CODE-BACKED | Official end-of-day raw bid price without spread, split-adjusted. |
| 11 | ClosingPrice_Ask | decimal(33,16) | YES | - | CODE-BACKED | Official end-of-day raw ask price without spread, split-adjusted. |
| 12 | ClosingPrice_PriceRateID | bigint | YES | - | CODE-BACKED | ID of the price tick record from which the ClosingPrice group was derived. |
| 13 | ClosingPrice_Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the official closing price occurred (market close time). |
| 14 | ClosingPrice_PriceType | int | YES | - | NAME-INFERRED | Classifies the type of closing price (e.g., 1=regular session close, 2=auction close). Distinguishes how the official close was determined. Cross-reference with Dictionary.PriceType if available. |
| 15 | AskSpreaded | decimal(33,16) | YES | - | CODE-BACKED | End-of-day calculation rate: ask price with spread, split-adjusted. Aliased as Close_AskSpreaded in Trade.OpenPositionEndOfDay. Used as closing rate for SELL CFD positions in end-of-day PnL calculation. |
| 16 | BidSpreaded | decimal(33,16) | YES | - | CODE-BACKED | End-of-day calculation rate: bid price with spread, split-adjusted. Aliased as Close_BidSpreaded. Used as closing rate for BUY CFD positions in end-of-day PnL calculation. |
| 17 | Bid | decimal(33,16) | YES | - | CODE-BACKED | End-of-day calculation rate: raw bid without spread, split-adjusted. Aliased as Close_Bid. Used as closing rate for BUY real-stock positions (no spread deduction for real ownership). |
| 18 | Ask | decimal(33,16) | YES | - | CODE-BACKED | End-of-day calculation rate: raw ask without spread, split-adjusted. Aliased as Close_Ask. Used as closing rate for SELL real-stock positions. |
| 19 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp for the end-of-day calculation rate price tick. Aliased as Close_Occurred in Trade.OpenPositionEndOfDay. NC index key - supports time-range filtering of instruments by their EOD calculation time. |
| 20 | PriceRateID | bigint | YES | - | CODE-BACKED | ID of the price tick for the end-of-day calculation rate. Aliased as Close_PriceRateID in Trade.OpenPositionEndOfDay. Passed to FnCalculatePnLWrapper as the calculation rate ID. |
| 21 | PriceType | int | YES | - | CODE-BACKED | Type of the end-of-day calculation rate price. Aliased as Close_PriceType in Trade.OpenPositionEndOfDay. Used to classify whether the EOD calculation used a regular, synthetic, or auction price. |
| 22 | Close_SourceID | int | YES | - | CODE-BACKED | Identifies the data source that provided the end-of-day calculation rate price. Passed through directly in Trade.OpenPositionEndOfDay. Distinguishes between price feed providers or internal calculation methods. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument / Trade.InstrumentMetaData | Implicit | The instrument these prices belong to (cross-schema) |
| MaxDate_PriceRateID | Price feed system | Implicit | The specific most-recent price tick record |
| ClosingPrice_PriceRateID | Price feed system | Implicit | The official closing price tick record |
| PriceRateID | Price feed system | Implicit | The end-of-day calculation rate price tick record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OpenPositionEndOfDay | History.CurrencyPriceMaxDateClosingPriceWithSplitView | JOIN (LEFT) | Primary consumer - reads all three price groups for end-of-day PnL calculation |
| Trade.OpenPositionEndOfDayWith2Pnl | History.CurrencyPriceMaxDateClosingPriceWithSplitView | JOIN (LEFT) | Variant consumer for dual-PnL end-of-day reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPriceMaxDateClosingPriceWithSplitView (table)
- Leaf node - no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies. This is a standalone cache table populated by an external job.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OpenPositionEndOfDay | View | Reads all three price groups to produce current and end-of-day PnL for open positions |
| Trade.OpenPositionEndOfDayWith2Pnl | View | Reads all three price groups for dual-PnL variant of the same view |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX1 | CLUSTERED | InstrumentID ASC | - | - | Active |
| NCix | NONCLUSTERED | Occurred ASC | - | - | Active |

**Filegroup**: [MAIN] - same as History.CurrencyPriceMaxDateWithSplitView, indicating this is a live/operational table despite being in the History schema.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| None | - | No PK, FK, CHECK, or UNIQUE constraints defined |

---

## 8. Sample Queries

### 8.1 Current prices vs. closing prices for all instruments
```sql
SELECT
    InstrumentID,
    MaxDate_Ask AS CurrentAsk,
    MaxDate_Occurred AS CurrentPriceTime,
    Ask AS EODCalcAsk,
    Occurred AS EODCalcTime,
    ClosingPrice_Ask AS OfficialCloseAsk,
    ClosingPrice_PriceType AS CloseType
FROM [History].[CurrencyPriceMaxDateClosingPriceWithSplitView] WITH (NOLOCK)
ORDER BY InstrumentID
```

### 8.2 Get EOD closing rate for a specific instrument (BUY CFD position scenario)
```sql
-- For a BUY CFD position, the EOD closing rate is BidSpreaded
SELECT
    InstrumentID,
    BidSpreaded AS EOD_BuyRate_CFD,
    Bid AS EOD_BuyRate_RealStock,
    PriceRateID AS EOD_PriceRateID,
    Close_SourceID
FROM [History].[CurrencyPriceMaxDateClosingPriceWithSplitView] WITH (NOLOCK)
WHERE InstrumentID = 1234
```

### 8.3 Instruments where EOD price differs significantly from most-recent price
```sql
SELECT
    InstrumentID,
    MaxDate_Ask AS CurrentAsk,
    Ask AS EODCalcAsk,
    ABS(MaxDate_Ask - Ask) AS PriceDelta,
    MaxDate_Occurred,
    Occurred AS EODOccurred
FROM [History].[CurrencyPriceMaxDateClosingPriceWithSplitView] WITH (NOLOCK)
WHERE MaxDate_Ask IS NOT NULL
  AND Ask IS NOT NULL
  AND ABS(MaxDate_Ask - Ask) > 1
ORDER BY PriceDelta DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.3/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | Views: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPriceMaxDateClosingPriceWithSplitView | Type: Table | Source: etoro/etoro/History/Tables/History.CurrencyPriceMaxDateClosingPriceWithSplitView.sql*
