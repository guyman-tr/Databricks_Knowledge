# Dealing_dbo.Dealing_Apex_PnL

> 3.0M-row weekly and daily P&L reconciliation table for Apex Clearing Corporation stock positions across 5 eToro hedge server accounts (3EU05025/26/27/28, 3EU00101), covering 2021-02-10 to 2024-06-07. Tracks Net Open Position (NOP) start/end values, trade activity, dividends, fees, and computed P&L per instrument per account per day. Populated daily by SP_Apex_PnL via DELETE+INSERT from Apex clearing files (EXT982/EXT872/EXT869 staging tables) joined with DWH_dbo.Dim_Instrument for instrument identification and Dealing_staging.PriceLog_History_CurrencyPrice for eToro DB prices.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing files (LP_APEX_EXT982_3EU, LP_APEX_EXT872_3EU_217314, LP_APEX_EXT869_3EU) via SP_Apex_PnL |
| **Refresh** | Daily (DELETE+INSERT for @Date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A -- not in Generic Pipeline |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_Apex_PnL` is the Middle Office's weekly P&L reconciliation table for stock positions held at Apex Clearing Corporation, eToro's US equities clearing house. Each row represents one instrument held in one Apex account on one reporting date, capturing the net open position (NOP) at week-start (Friday EOD) and week-end (current day EOD), intervening trade activity, dividends received, additional fees, and the computed profit/loss.

The table serves 5 Apex clearing accounts mapped to eToro hedge servers: 3EU05025 (HedgeServerID 112, 64.8% of rows), 3EU05026 (HedgeServerID 9, 13.4%), 3EU05027 (HedgeServerID 102, 10.1%), 3EU00101 (HedgeServerID 223, 6.5%), and 3EU05028 (HedgeServerID 3, 5.2%). As of the last load, the table contains 2,999,038 rows spanning 2021-02-10 to 2024-06-07, covering 4,841 distinct symbols mapped to 4,229 distinct InstrumentIDs (135,419 rows have NULL InstrumentID where symbol matching failed).

The ETL SP (`SP_Apex_PnL`, authored by Sarah Benchitrit, 2021-07-25) runs daily with a `@Date` parameter. It DELETEs existing rows for that date and INSERTs freshly computed rows. The SP also populates three sibling tables in the same run: `Dealing_Apex_PnL_EE` (account-level equity start/end), `Dealing_Apex_PnL_Daily` (same structure, daily window instead of weekly), and `Dealing_Apex_PnL_EE_Daily`. The SP handles bank holidays (shifting to the previous business day via Dim_Date), weekend boundaries (Friday EOD as week start), and scientific notation parsing in Apex file fields.

Instrument matching is performed by joining Apex file symbols to `DWH_dbo.Dim_Instrument` on Symbol (for NASDAQ/NYSE/CBOE/OTCMKTS equities) with a fallback to ISIN matching. Prices come from two sources: Apex's own ClosingPrice (Price_Start, Price_End) and eToro's internal price server via `PriceLog_History_CurrencyPrice` BidSpreaded rates (Price_Start_DB, Price_End_DB), with a GBX-to-GBP conversion for SellCurrencyID=666.

---

## 2. Business Logic

### 2.1 P&L Computation Formula

**What**: The core P&L is computed as the change in net open position value minus trade costs plus income adjustments.

**Columns Involved**: `PnL`, `PnL_DBPrice`, `NOP_Start`, `NOP_End`, `NOP_Start_DBPrice`, `NOP_End_DBPrice`, `Trades`, `Dividends`, `AdditionalFees`

**Rules**:
- `PnL = ISNULL(NOP_End, 0) - ISNULL(NOP_Start, 0) - ISNULL(Trades, 0) + ISNULL(Dividends, 0) + ISNULL(AdditionalFees, 0)`
- `PnL_DBPrice` uses the same formula but substitutes `NOP_End_DBPrice` and `NOP_Start_DBPrice` (eToro DB prices instead of Apex closing prices)
- PnL is never NULL (0 rows with NULL PnL) because ISNULL() defaults all components to 0
- Trades are subtracted (represent cost of trades executed); Dividends and AdditionalFees are added (income/credits received)

### 2.2 NOP (Net Open Position) Valuation

**What**: NOP captures the market value of all positions in an instrument at a point in time, using two price sources.

**Columns Involved**: `NOP_Start`, `NOP_Start_DBPrice`, `NOP_End`, `NOP_End_DBPrice`, `Price_Start`, `Price_Start_DB`, `Price_End`, `Price_End_DB`

**Rules**:
- NOP_Start = MarketValue from Apex EXT982 file for the Friday before the reporting week (or previous business day if bank holiday)
- NOP_End = MarketValue from Apex EXT982 file for the current reporting date
- NOP_Start_DBPrice = TradeQuantity * eToro DB Bid price (from PriceLog at Friday-before EOD)
- NOP_End_DBPrice = TradeQuantity * eToro DB Bid price (from PriceLog at current-day EOD)
- NULL NOP_Start (143K rows, 5%) = instrument had no position at week start (new position opened during week)
- NULL NOP_End (387K rows, 13%) = instrument had no position at week end (position fully closed during week)
- Scientific notation in Apex fields (e.g., `1.23e+06`) is parsed via CHARINDEX/POWER logic

### 2.3 Trade Aggregation Window

**What**: Trades and Volume are aggregated over the weekly window from Saturday (day after previous Friday) through the current reporting date.

**Columns Involved**: `Trades`, `Volume`

**Rules**:
- Trades = SUM of (Quantity * Price + FeeSec + Fee5) from Apex EXT872 trade execution files
- Volume = SUM of ABS(Quantity * Price + FeeSec + Fee5) -- absolute value of trade amounts
- Aggregation window: `@SaturdayBeforeID` to `@DateID` (i.e., Saturday through current date)
- NULL Trades (794K rows, 26%) = no trade executions for that instrument in the reporting window
- Fee5 may be empty string in source; handled with `CASE WHEN Fee5 <> '' THEN CAST(Fee5) ELSE 0 END`

### 2.4 Dividend and Fee Separation

**What**: Dividend income and additional fees come from the same Apex file (EXT869) but are separated by TerminalID.

**Columns Involved**: `Dividends`, `AdditionalFees`

**Rules**:
- Dividends = SUM of negated Amount WHERE TerminalID = '$+DIV' (dividend distributions)
- AdditionalFees = SUM of negated Amount WHERE TerminalID NOT IN ('$+DIV', 'CSCSG', 'FWWRD', 'MGLOA', 'MGJNL')
- TerminalIDs 'CSCSG', 'FWWRD', 'MGLOA', 'MGJNL' are excluded from both -- these are account transfers used in the EE (equity) sibling table
- NULL Dividends/AdditionalFees (2.95M rows, 98%) = no dividend/fee activity for that instrument in the window

### 2.5 Zero PnL Adjustment

**What**: A separate correction factor from `Dealing_DailyZeroPnL_Stocks` captures P&L attributed to zero-value or rounding adjustments.

**Columns Involved**: `Zero`

**Rules**:
- Zero = SUM of TotalZero from `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` joined on InstrumentID and HedgeServerID (mapped to AccountNumber via hardcoded lookup)
- HedgeServerID-to-AccountNumber mapping: 9=3EU05026, 112=3EU05025, 102=3EU05027, 223=3EU00101, 3=3EU05028
- NULL Zero (1.06M rows, 35%) = no zero-PnL adjustment for that instrument
- Aggregated over Saturday-to-current-date window (same as Trades)

### 2.6 Dual Price Sources

**What**: Every NOP and price column exists in two versions: Apex closing price and eToro DB price (internal bid).

**Columns Involved**: `Price_Start`, `Price_Start_DB`, `Price_End`, `Price_End_DB`, `NOP_Start`, `NOP_Start_DBPrice`, `NOP_End`, `NOP_End_DBPrice`, `PnL`, `PnL_DBPrice`

**Rules**:
- `Price_Start` / `Price_End` = Apex ClosingPrice from EXT982 files (external clearing house price)
- `Price_Start_DB` / `Price_End_DB` = Last BidSpreaded from `PriceLog_History_CurrencyPrice` before trading session close (internal eToro price)
- Trading session close: 21:30 on Fridays, 22:00 on weekdays (ROW_NUMBER DESC by PriceRateID)
- GBX adjustment: when SellCurrencyID = 666 (GBP pence), DB price is divided by 100 to convert to GBP

### 2.7 Account-to-HedgeServer Mapping

**What**: The 5 Apex accounts are hardcoded to eToro hedge server IDs for joining to internal dealing tables.

**Columns Involved**: `AccountNumber`

**Rules**:
- Hardcoded in SP via INSERT INTO #AccountToHS: 3EU05026=9, 3EU05025=112, 3EU05027=102, 3EU00101=223, 3EU05028=3
- AccountNumber is resolved via COALESCE across NOP, Trades, and Dividends temp tables (FULL OUTER JOINs)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

This table uses **ROUND_ROBIN** distribution (3.0M rows spread evenly across all distributions) with a **CLUSTERED INDEX on Date ASC**. Date-range queries are efficient via the clustered index. Since there is no hash distribution key, all JOINs require data movement -- for large joins, filter by Date first to reduce shuffle.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Weekly P&L for a specific account | `WHERE AccountNumber = '3EU05025' AND Date = '2024-01-15'` |
| Total P&L by instrument over a period | `SELECT Symbol, SUM(PnL) FROM ... WHERE Date BETWEEN ... GROUP BY Symbol` |
| Compare Apex vs DB price P&L | `SELECT Symbol, SUM(PnL) AS ApexPnL, SUM(PnL_DBPrice) AS DBPnL FROM ... GROUP BY Symbol` |
| Find instruments with large discrepancy | `WHERE ABS(PnL - PnL_DBPrice) > threshold` |
| Dividend income by account | `SELECT AccountNumber, SUM(Dividends) WHERE Dividends IS NOT NULL GROUP BY AccountNumber` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON Dim_Instrument.InstrumentID = Dealing_Apex_PnL.InstrumentID` | Get full instrument metadata (type, exchange, ISIN, market cap) |
| Dealing_dbo.Dealing_Apex_PnL_EE | `ON EE.Date = PnL.Date AND EE.AccountNumber = PnL.AccountNumber` | Get account-level equity start/end alongside instrument-level P&L |
| Dealing_dbo.Dealing_Apex_PnL_Daily | `ON Daily.Date = PnL.Date AND Daily.AccountNumber = PnL.AccountNumber AND Daily.Symbol = PnL.Symbol` | Compare weekly vs daily P&L for same instrument |
| DWH_dbo.Dim_Date | `ON Dim_Date.FullDate = Dealing_Apex_PnL.Date` | Calendar enrichment (week number, business day flags) |

### 3.4 Gotchas

- **PnL is never NULL but NOP components can be**: PnL uses ISNULL(..., 0) on all inputs. A row with NULL NOP_Start and NULL NOP_End will have PnL = -Trades + Dividends + AdditionalFees.
- **Weekly vs Daily**: This table (`Dealing_Apex_PnL`) uses Friday-to-current-day weekly windows. For daily windows, use `Dealing_Apex_PnL_Daily`. Both are populated in the same SP run.
- **Apex price vs DB price**: `PnL` uses Apex ClosingPrice-based NOP values; `PnL_DBPrice` uses eToro internal bid prices. Discrepancies are expected and are the purpose of reconciliation.
- **Scientific notation in source**: Apex files may contain values like `1.23e+06` which the SP parses. This is handled in the ETL but may explain precision differences.
- **GBX/GBP conversion**: Instruments with SellCurrencyID=666 have DB prices divided by 100. Apex prices are already in GBP.
- **Bank holiday shifts**: If @Date falls on a bank holiday, NOP_End uses the previous business day's data. Same logic for Friday-before if that Friday is a bank holiday.
- **Only 5 accounts**: This table covers only Apex clearing accounts (3EU*). Other clearing houses have separate tables.
- **Zero column not in PnL formula**: The `Zero` column is a P&L adjustment from `Dealing_DailyZeroPnL_Stocks` and is NOT included in the main PnL/PnL_DBPrice formula. It is present as a separate reference for reconciliation comparison, not as an additive component.
- **UpdateDate is ETL timestamp**: Reflects when SP_Apex_PnL ran, not when the Apex data was generated.
- **NULL InstrumentID**: 135,419 rows (4.5%) have NULL InstrumentID where Apex symbol could not be matched to Dim_Instrument via Symbol/ISIN/CUSIP.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- upstream wiki verbatim | `(Tier 1 -- upstream wiki)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -- SP_Apex_PnL)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -- live data)` |
| ★ | Tier 4 -- inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 -- inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date for which P&L is computed. Set to the @Date parameter passed to SP_Apex_PnL. One row per instrument per account per date. The clustered index column. (Tier 2 -- SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | Apex Clearing Corporation account identifier. 5 accounts: 3EU05025 (64.8% of rows, HedgeServerID 112), 3EU05026 (13.4%, HS 9), 3EU05027 (10.1%, HS 102), 3EU00101 (6.5%, HS 223), 3EU05028 (5.2%, HS 3). Resolved via COALESCE across NOP, Trades, and Dividends sources. (Tier 2 -- SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | Stock ticker symbol from Apex clearing files (e.g., AAPL, AMC, OCGN). Used for instrument matching to DWH_dbo.Dim_Instrument. Resolved via COALESCE across NOP, Trades, and Dividends sources. (Tier 2 -- SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | Net Open Position market value at week start (Friday EOD of the previous week), from Apex EXT982 MarketValue field. Parsed from scientific notation when present. NULL when no position existed at week start (new position opened during week). (Tier 2 -- SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | Net Open Position at week start valued using eToro internal DB prices. Computed as TradeQuantity_Start * Price_Start_DB (last BidSpreaded from PriceLog before Friday EOD trading session close). NULL when NOP_Start is NULL. (Tier 2 -- SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | Net Open Position market value at current day EOD, from Apex EXT982 MarketValue field. Parsed from scientific notation when present. NULL when no position existed at day end (position fully closed). (Tier 2 -- SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | Net Open Position at current day EOD valued using eToro internal DB prices. Computed as TradeQuantity_End * Price_End_DB (last BidSpreaded from PriceLog before current-day trading session close). NULL when NOP_End is NULL. (Tier 2 -- SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | Net trade value over the weekly window (Saturday through current date). SUM of (Quantity * Price + FeeSec + Fee5) from Apex EXT872 trade execution files. Negative values indicate net selling; positive indicate net buying. NULL when no trades occurred for this instrument in the window. (Tier 2 -- SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | Total dividend income received for this instrument over the weekly window. SUM of negated Amount from Apex EXT869 files WHERE TerminalID = '$+DIV'. NULL for 98% of rows (most instruments pay no dividend in any given week). (Tier 2 -- SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | Weekly profit/loss computed as: ISNULL(NOP_End,0) - ISNULL(NOP_Start,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(AdditionalFees,0). Uses Apex closing prices for NOP valuation. Never NULL (all components default to 0 via ISNULL). (Tier 2 -- SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | Weekly profit/loss using eToro internal DB prices instead of Apex closing prices. Formula: ISNULL(NOP_End_DBPrice,0) - ISNULL(NOP_Start_DBPrice,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(AdditionalFees,0). Difference from PnL reflects Apex-vs-eToro price discrepancy. (Tier 2 -- SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() by SP_Apex_PnL. Reflects when the SP ran, not when Apex data was generated. (Tier 2 -- SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables. (Tier 1 -- Trade.Instrument) |
| 14 | InstrumentDisplayName | varchar(100) | YES | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 1 -- Trade.Instrument) |
| 15 | Price_Start | decimal(16,6) | YES | Apex closing price at week start (Friday EOD of the previous week). CAST from ClosingPrice field in Apex EXT982 position file. Represents the clearing house's official closing price. NULL when no NOP_Start position exists. (Tier 2 -- SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | eToro internal DB bid price at week start. Last BidSpreaded from PriceLog_History_CurrencyPrice before Friday trading session close (21:30 Fri, 22:00 weekdays). GBX prices divided by 100 for GBP conversion (SellCurrencyID=666). NULL when no NOP_Start position exists. (Tier 2 -- SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | Apex closing price at current day EOD. CAST from ClosingPrice field in Apex EXT982 position file. NULL when no NOP_End position exists (position closed). (Tier 2 -- SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | eToro internal DB bid price at current day EOD. Last BidSpreaded from PriceLog_History_CurrencyPrice before current-day trading session close. GBX/100 conversion applied for SellCurrencyID=666. NULL when no NOP_End position exists. (Tier 2 -- SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | Additional non-dividend fees/credits from Apex EXT869 files. SUM of negated Amount WHERE TerminalID is not '$+DIV' and not a transfer code ('CSCSG','FWWRD','MGLOA','MGJNL'). NULL for 98% of rows (most instruments incur no fees in a given week). (Tier 2 -- SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | Absolute trade volume over the weekly window. SUM of ABS(Quantity * Price + FeeSec + Fee5) from Apex EXT872 trade execution files. Always non-negative when not NULL. NULL when no trades occurred (same NULL pattern as Trades). (Tier 2 -- SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | Zero-PnL adjustment from Dealing_dbo.Dealing_DailyZeroPnL_Stocks. SUM of TotalZero joined by InstrumentID and HedgeServerID (mapped to AccountNumber via hardcoded lookup). Captures rounding or zero-value P&L corrections used for reconciliation comparison alongside the main PnL/PnL_DBPrice values. NULL for 35% of rows. (Tier 2 -- SP_Apex_PnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP parameter | @Date | Direct assignment |
| AccountNumber | Apex EXT982/EXT872/EXT869 | AccountNumber | COALESCE across sources |
| Symbol | Apex EXT982/EXT872/EXT869 | Symbol | COALESCE across sources |
| NOP_Start | LP_APEX_EXT982_3EU | MarketValue | Scientific notation parse, Friday-before EOD |
| NOP_Start_DBPrice | EXT982 + PriceLog | TradeQuantity * BidSpreaded | Computed product |
| NOP_End | LP_APEX_EXT982_3EU | MarketValue | Scientific notation parse, current-day EOD |
| NOP_End_DBPrice | EXT982 + PriceLog | TradeQuantity * BidSpreaded | Computed product |
| Trades | LP_APEX_EXT872_3EU_217314 | Quantity, Price, FeeSec, Fee5 | SUM(Qty*Price+Fees), weekly |
| Dividends | LP_APEX_EXT869_3EU | Amount | SUM WHERE TerminalID='$+DIV', negated |
| PnL | Computed | -- | NOP_End - NOP_Start - Trades + Dividends + AdditionalFees |
| PnL_DBPrice | Computed | -- | Same formula, DB price NOP values |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Dim-lookup via Symbol/ISIN/CUSIP |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough |
| Price_Start | LP_APEX_EXT982_3EU | ClosingPrice | CAST, Friday-before EOD |
| Price_Start_DB | PriceLog_History_CurrencyPrice | BidSpreaded | Last before session close, GBX/100 |
| Price_End | LP_APEX_EXT982_3EU | ClosingPrice | CAST, current-day EOD |
| Price_End_DB | PriceLog_History_CurrencyPrice | BidSpreaded | Last before session close, GBX/100 |
| AdditionalFees | LP_APEX_EXT869_3EU | Amount | SUM WHERE TerminalID not dividend/transfer, negated |
| Volume | LP_APEX_EXT872_3EU_217314 | Quantity, Price, FeeSec, Fee5 | SUM(ABS(Qty*Price+Fees)), weekly |
| Zero | Dealing_DailyZeroPnL_Stocks | TotalZero | SUM by InstrumentID+HedgeServerID, weekly |

### 5.2 ETL Pipeline

```
Apex Clearing Corporation (external clearing house files)
  |-- EXT982: Positions EOD (MarketValue, ClosingPrice, TradeQuantity)
  |-- EXT872: Trade Executions (Quantity, Price, Fees)
  |-- EXT869: Dividends & Fees (Amount, TerminalID)
  v
Dealing_staging.LP_APEX_EXT982_3EU          (NOP positions)
Dealing_staging.LP_APEX_EXT872_3EU_217314   (trade activity)
Dealing_staging.LP_APEX_EXT869_3EU          (dividends/fees)
  +-> DWH_dbo.Dim_Instrument               (instrument ID matching via Symbol/ISIN/CUSIP)
  +-> Dealing_staging.PriceLog_History_CurrencyPrice  (eToro internal prices)
  +-> DWH_dbo.Dim_Date                      (bank holiday / week boundary logic)
  +-> Dealing_dbo.Dealing_DailyZeroPnL_Stocks  (zero PnL adjustments)
  |
  |-- SP_Apex_PnL @Date (daily DELETE+INSERT)
  v
Dealing_dbo.Dealing_Apex_PnL         (3.0M rows, weekly window)
Dealing_dbo.Dealing_Apex_PnL_Daily   (daily window sibling)
Dealing_dbo.Dealing_Apex_PnL_EE      (account equity, weekly)
Dealing_dbo.Dealing_Apex_PnL_EE_Daily (account equity, daily)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK to instrument dimension. Matched via Symbol/ISIN/CUSIP from Apex files |
| Date | DWH_dbo.Dim_Date | Reporting date, used for bank holiday and week boundary logic in the SP |
| AccountNumber | Hardcoded mapping | Maps to HedgeServerID in Dealing_DailyZeroPnL_Stocks (5 accounts) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| -- | Dealing_dbo.Dealing_Apex_PnL_EE | Sibling: account-level equity, same SP, joined on Date + AccountNumber |
| -- | Dealing_dbo.Dealing_Apex_PnL_Daily | Sibling: daily-window version of same data, same SP |
| -- | Dealing_dbo.Dealing_Apex_PnL_EE_Daily | Sibling: daily equity version, same SP |

---

## 7. Sample Queries

### 7.1 Weekly P&L by Account for a Specific Date

```sql
SELECT
    AccountNumber,
    COUNT(*) AS instruments,
    SUM(PnL) AS total_pnl_apex,
    SUM(PnL_DBPrice) AS total_pnl_db,
    SUM(PnL) - SUM(PnL_DBPrice) AS price_discrepancy
FROM Dealing_dbo.Dealing_Apex_PnL
WHERE Date = '2024-01-15'
GROUP BY AccountNumber
ORDER BY AccountNumber;
```

### 7.2 Top 10 Instruments by Absolute P&L Impact

```sql
SELECT TOP 10
    p.Symbol,
    di.InstrumentDisplayName,
    SUM(p.PnL) AS total_pnl,
    SUM(p.Volume) AS total_volume,
    COUNT(*) AS data_points
FROM Dealing_dbo.Dealing_Apex_PnL p
LEFT JOIN DWH_dbo.Dim_Instrument di ON di.InstrumentID = p.InstrumentID
WHERE p.Date >= '2024-01-01'
GROUP BY p.Symbol, di.InstrumentDisplayName
ORDER BY ABS(SUM(p.PnL)) DESC;
```

### 7.3 Apex vs DB Price Discrepancy Analysis

```sql
SELECT
    Date,
    Symbol,
    PnL AS pnl_apex,
    PnL_DBPrice AS pnl_db,
    PnL - PnL_DBPrice AS discrepancy,
    Price_End,
    Price_End_DB,
    Price_End - Price_End_DB AS price_diff
FROM Dealing_dbo.Dealing_Apex_PnL
WHERE ABS(PnL - PnL_DBPrice) > 10000
    AND Date >= '2024-01-01'
ORDER BY ABS(PnL - PnL_DBPrice) DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found (search skipped in regen harness mode).

---

PHASE GATE — Dealing_dbo.Dealing_Apex_PnL:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)  [x] P8 SP-scan
  [x] P9 SP-logic     [x] P9B ETL          [-] P10 Jira (regen harness)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11

---

*Generated: 2026-04-27 | Quality: 8.5/10 | Phases: 12/14 (P7 skipped -- no views, P10 skipped -- regen harness)*
*Tiers: 2 T1, 19 T2, 0 T3, 0 T4, 0 T5 | Elements: 21/21, Logic: 7/10, Lineage: complete*
*Object: Dealing_dbo.Dealing_Apex_PnL | Type: Table | Production Source: Apex Clearing files via SP_Apex_PnL*
