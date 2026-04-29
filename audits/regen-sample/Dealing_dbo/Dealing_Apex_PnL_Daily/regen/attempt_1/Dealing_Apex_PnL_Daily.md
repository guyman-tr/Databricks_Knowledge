# Dealing_dbo.Dealing_Apex_PnL_Daily

> Daily per-symbol PnL reconciliation for eToro's Apex Clearing LP accounts (~1.66M rows, 2022-07-06 to 2024-06-07) — compares Apex statement marks to eToro internal DB prices at instrument level; **stale since 2024-06-08** (last ETL run). Written by `SP_Apex_PnL` alongside its WTD sibling `Dealing_Apex_PnL`.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Apex Clearing LP external files → `Dealing_staging.LP_APEX_EXT872_3EU_217314` (trades) + `LP_APEX_EXT982_3EU` (NOP/holdings) + `LP_APEX_EXT869_3EU` (dividends/fees) + `PriceLog_History_CurrencyPrice` (DB prices) + `Dealing_DailyZeroPnL_Stocks` (zero adjustment) |
| **Refresh** | Stale (last update 2024-06-08 09:19; historically daily) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on `[Date]` |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |
| **UC Format** | _Pending — resolved during write-objects_ |
| **UC Partitioned By** | _Pending — resolved during write-objects_ |
| **UC Table Type** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

`Dealing_dbo.Dealing_Apex_PnL_Daily` is the **daily** per-symbol PnL reconciliation table for eToro's Apex Clearing LP (liquidity provider) accounts. It holds ~1.66M rows from 2022-07-06 through 2024-06-07 across 4 Apex account numbers and ~3,993 distinct symbols. Each row represents one combination of `(Date, AccountNumber, Symbol)` and captures the **day-over-day** PnL bridge: NOP at prior business day close vs NOP at current day close, minus trades, plus dividends and fees.

This table is the **daily-grain counterpart** to `Dealing_Apex_PnL` (week-to-date). Both are written by the same stored procedure `SP_Apex_PnL` (author: Sarah Benchitrit, 2021-07-25; Synapse migration by Gal, 2024-01). The daily variant differs only in its NOP start reference: it uses the **prior business day** (skipping weekends: Monday uses Friday), whereas the WTD variant anchors to the **prior Friday EOD**.

**Stale dataset:** The last loaded date is 2024-06-07 with UpdateDate 2024-06-08 09:19. No data has been loaded for approximately two years. Treat all figures as historical unless the Apex LP pipeline is reactivated.

**Price reconciliation intent:** Non-`_DBPrice` columns use **Apex closing prices** from LP statement files. `*_DBPrice` columns use **eToro's internal database bid prices** from `PriceLog_History_CurrencyPrice`. Comparing `PnL` vs `PnL_DBPrice` isolates valuation differences between Apex marks and eToro's internal pricing.

**Instrument resolution:** `InstrumentID` and `InstrumentDisplayName` are resolved by matching Apex `Symbol`/`CUSIP`/`ISIN` to `DWH_dbo.Dim_Instrument` (filtered to Stocks/ETFs on major US exchanges, Tradable=1). NULL `InstrumentID` (~497 rows on last date) indicates the Apex symbol could not be matched.

**Domain:** Dealing — Middle Office daily reconciliation, Apex LP.

---

## 2. Business Logic

### 2.1 Daily PnL Bridge Formula

**What**: The core PnL computation for each symbol on a given day, using two pricing sources.

**Columns Involved**: `PnL`, `PnL_DBPrice`, `NOP_Start`, `NOP_End`, `NOP_Start_DBPrice`, `NOP_End_DBPrice`, `Trades`, `Dividends`, `AdditionalFees`

**Rules**:
- **Apex-priced PnL**: `PnL = ISNULL(NOP_End, 0) - ISNULL(NOP_Start, 0) - ISNULL(Trades, 0) + ISNULL(Dividends, 0) + ISNULL(AdditionalFees, 0)`
- **DB-priced PnL**: `PnL_DBPrice = ISNULL(NOP_End_DBPrice, 0) - ISNULL(NOP_Start_DBPrice, 0) - ISNULL(Trades, 0) + ISNULL(Dividends, 0) + ISNULL(AdditionalFees, 0)`
- `Trades` enters with a **minus** sign (cash outflow for buys, inflow for sells)
- `PnL` is **never NULL** (ISNULL wrapping ensures a computed value even when components are missing)
- Difference `PnL - PnL_DBPrice` isolates mark-to-market discrepancies between Apex and eToro pricing

### 2.2 Daily NOP Start Reference (Prior Business Day)

**What**: The daily variant anchors NOP_Start to the prior business day rather than the prior Friday.

**Columns Involved**: `NOP_Start`, `NOP_Start_DBPrice`, `Price_Start`, `Price_Start_DB`

**Rules**:
- `@PreviousDay` = prior calendar day, except on Mondays where it skips back to Friday (`DATEADD(day, -3, @Date)`)
- NOP_Start reads from `LP_APEX_EXT982_3EU` at `@PreviousDayID`
- `Price_Start_DB` (eToro bid) comes from `PriceLog_History_CurrencyPrice` at the same date, using end-of-session rates (21:30 Fridays, 22:00 weekdays)
- `NOP_Start_DBPrice = TradeQuantity_Start × Price_Start_DB`
- GBX adjustment: when `SellCurrencyID = 666`, bid is divided by 100 to convert from GBP pence to GBP

### 2.3 Instrument Resolution (Multi-Step Match)

**What**: Apex symbols are matched to eToro `InstrumentID` via a two-pass resolution.

**Columns Involved**: `InstrumentID`, `InstrumentDisplayName`, `Symbol`

**Rules**:
- **Pass 1** (`#Apex_Ins1`): Match on `Symbol` against `Dim_Instrument.Symbol` (filtered to InstrumentTypeID IN (5,6), major US exchanges, Tradable=1)
- **Pass 2** (`#Apex_Ins2`): Match on `ISIN` against `Dim_Instrument.ISINCode` for instruments not already matched in Pass 1
- Final instrument: `ISNULL(Pass1.InstrumentID, Pass2.InstrumentID)` — Symbol match takes priority
- NULL `InstrumentID` means neither Symbol nor ISIN matched (e.g., delisted instruments, ADRs, or symbols not in eToro's universe)

### 2.4 Zero PnL Adjustment

**What**: Captures PnL from positions that opened and fully closed to zero within the day.

**Columns Involved**: `Zero`

**Rules**:
- Sourced from `Dealing_DailyZeroPnL_Stocks` for `Date = @Date`
- Joined via `InstrumentID` and `AccountNumber` (mapped to `HedgeServerID` via hardcoded lookup: 3EU05026→9, 3EU05025→112, 3EU05027→102, 3EU00101→223, 3EU05028→3)
- Without this adjustment, positions that opened and closed within the day would be invisible to the daily PnL bridge

### 2.5 Trades and Volume Computation

**What**: Net traded notional and absolute volume from Apex activity.

**Columns Involved**: `Trades`, `Volume`

**Rules**:
- **Daily scope**: Only trades with `ReportDateID = @DateID` (single day, unlike WTD which spans Saturday through @Date)
- `Trades = SUM(Quantity × Price + FeeSec + Fee5)` — net notional (signed: buys positive, sells negative)
- `Volume = SUM(ABS(Quantity × Price + FeeSec + Fee5))` — absolute value of all trade activity
- Scientific notation handling: Quantity fields containing `e+` notation are parsed into decimal

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distributed — no hash key; no co-location benefit on JOINs. **Clustered on `Date` ASC** — always filter on `Date` (or a tight date range) to avoid full-table scans across ~1.66M rows.

### 3.1b UC (Databricks) Storage & Partitioning

UC target pending. At ~1.66M rows, suggest partitioning by year or Z-ORDER on `Date` for temporal range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily PnL for a specific account and date | `WHERE Date = @Date AND AccountNumber = @Acct` |
| Price discrepancy investigation | `SELECT PnL - PnL_DBPrice AS MarkDiff WHERE Date = @Date ORDER BY ABS(PnL - PnL_DBPrice) DESC` |
| Unmatched Apex symbols | `WHERE InstrumentID IS NULL AND Date = @Date` |
| Daily vs WTD comparison | Join to `Dealing_Apex_PnL` on `Date + AccountNumber + Symbol` |
| Zero PnL impact | `SELECT Symbol, Zero WHERE Zero IS NOT NULL AND Date = @Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | `ON InstrumentID` | Resolve full instrument attributes (expect NULL InstrumentID for unmatched symbols) |
| Dealing_dbo.Dealing_Apex_PnL | `ON Date + AccountNumber + Symbol` | Compare daily vs WTD PnL for the same symbol |
| Dealing_dbo.Dealing_Apex_PnL_EE_Daily | `ON Date + AccountNumber` | Compare symbol-level sum to account equity PnL |

### 3.4 Gotchas

- **Stale data**: Last loaded date is 2024-06-07. Always check `MAX(Date)` before publishing numbers.
- **NULL InstrumentID**: ~497 rows on the last date could not be matched to `Dim_Instrument`. These are valid Apex positions that eToro's instrument dimension doesn't cover (delisted, ADRs, etc.).
- **NULL components ≠ missing row**: `NOP_Start` can be NULL (new position opened today), `Trades` can be NULL (no trades), `Dividends` can be NULL (no dividends). PnL is always computed using ISNULL(..., 0).
- **Daily vs WTD**: This table uses **prior business day** as NOP start. `Dealing_Apex_PnL` uses **prior Friday EOD**. Do not confuse the two grains.
- **AccountNumber→HedgeServerID mapping**: Hardcoded in SP (3EU05026→HS9, 3EU05025→HS112, 3EU05027→HS102, 3EU00101→HS223, 3EU05028→HS3). If a new Apex account is added, the SP must be updated.
- **GBX pence adjustment**: Instruments with `SellCurrencyID = 666` (GBP pence) have their DB bid divided by 100. This only affects `*_DBPrice` and `Price_*_DB` columns.
- **PnL is never NULL**: The ISNULL wrapping in the formula guarantees a value even when all components are NULL (result = 0).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Apex_PnL)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Report date for this daily PnL row — the business date for which the day-over-day bridge is computed. Set to `@Date` parameter passed to SP_Apex_PnL. (Tier 2 — SP_Apex_PnL) |
| 2 | AccountNumber | varchar(20) | YES | Apex LP account number (e.g. 3EU05025, 3EU05027). Resolved via COALESCE across NOP, Trades, and Dividends feeds. Maps to internal HedgeServerID via hardcoded lookup in SP. (Tier 2 — SP_Apex_PnL) |
| 3 | Symbol | varchar(50) | YES | Instrument symbol as Apex reports it (e.g. AAPL, SPY). Resolved via COALESCE across NOP, Trades, and Dividends feeds. Used with CUSIP/ISIN to resolve `DWH_dbo.Dim_Instrument`. (Tier 2 — SP_Apex_PnL) |
| 4 | NOP_Start | decimal(16,6) | YES | Net open position at prior business day EOD, valued at Apex's closing price — opening mark for the daily bridge. From `LP_APEX_EXT982_3EU.MarketValue` at `@PreviousDayID`. NULL if the symbol had no position at prior day close. (Tier 2 — SP_Apex_PnL) |
| 5 | NOP_Start_DBPrice | decimal(16,6) | YES | NOP at prior business day EOD using eToro internal DB bid price × quantity — pairs with Apex NOP_Start for mark-to-market reconciliation. Computed as `TradeQuantity_Start × Price_Start_DB`. NULL if no prior-day position or no DB price available. (Tier 2 — SP_Apex_PnL) |
| 6 | NOP_End | decimal(16,6) | YES | Net open position at report date EOD, Apex closing price — closing mark for the daily bridge. From `LP_APEX_EXT982_3EU.MarketValue` at `@DateID`. NULL if the symbol has no open position at day end. (Tier 2 — SP_Apex_PnL) |
| 7 | NOP_End_DBPrice | decimal(16,6) | YES | NOP at report date EOD using eToro DB bid × quantity — internal mark at the same point as `NOP_End`. Computed as `TradeQuantity_End × Price_End_DB`. NULL if no position or no DB price. (Tier 2 — SP_Apex_PnL) |
| 8 | Trades | decimal(16,8) | YES | Net traded notional for the day from Apex activity: `SUM(Quantity × Price + FeeSec + Fee5)`. Buys are positive, sells negative. Enters the PnL formula with a minus sign. NULL if no trades on this date. (Tier 2 — SP_Apex_PnL) |
| 9 | Dividends | decimal(16,6) | YES | Dividend income credited via Apex for this symbol on the report date. From `LP_APEX_EXT869_3EU` where `TerminalID = '$+DIV'`, negated (sign convention). NULL if no dividends. (Tier 2 — SP_Apex_PnL) |
| 10 | PnL | decimal(24,6) | YES | Daily PnL using Apex prices: `ISNULL(NOP_End, 0) - ISNULL(NOP_Start, 0) - ISNULL(Trades, 0) + ISNULL(Dividends, 0) + ISNULL(AdditionalFees, 0)`. Primary statement-side PnL. Never NULL due to ISNULL wrapping. (Tier 2 — SP_Apex_PnL) |
| 11 | PnL_DBPrice | decimal(16,6) | YES | Daily PnL using eToro DB prices on NOP start/end — compare to `PnL` to isolate price-source differences vs Apex. Same formula as PnL but substituting `NOP_End_DBPrice` and `NOP_Start_DBPrice`. (Tier 2 — SP_Apex_PnL) |
| 12 | UpdateDate | datetime | YES | Row load timestamp from the ETL (`GETDATE()` in SP_Apex_PnL) — when this row was last written. Does not reflect business event time. (Tier 2 — SP_Apex_PnL) |
| 13 | InstrumentID | int | YES | eToro instrument key from `DWH_dbo.Dim_Instrument` resolved via two-pass Symbol/ISIN matching against Apex identifiers. NULL if no match found (delisted instruments, ADRs not in eToro universe). (Tier 2 — SP_Apex_PnL) |
| 14 | InstrumentDisplayName | varchar(100) | YES | eToro display name for the instrument from `DWH_dbo.Dim_Instrument.InstrumentDisplayName`. May differ from Apex `Symbol`. NULL if InstrumentID is NULL. (Tier 2 — SP_Apex_PnL) |
| 15 | Price_Start | decimal(16,6) | YES | Apex closing price at prior business day EOD. From `LP_APEX_EXT982_3EU.ClosingPrice` at `@PreviousDayID`, CAST to decimal(16,6). NULL if no position at prior day. (Tier 2 — SP_Apex_PnL) |
| 16 | Price_Start_DB | decimal(16,6) | YES | eToro DB bid at prior business day EOD — supports price-level reconciliation alongside `Price_Start`. From `PriceLog_History_CurrencyPrice.Bid` (GBX/100 adjusted for SellCurrencyID=666). NULL if no DB price available. (Tier 2 — SP_Apex_PnL) |
| 17 | Price_End | decimal(16,6) | YES | Apex closing price at report date EOD. From `LP_APEX_EXT982_3EU.ClosingPrice` at `@DateID`, CAST to decimal(16,6). NULL if no position at report date. (Tier 2 — SP_Apex_PnL) |
| 18 | Price_End_DB | decimal(16,6) | YES | eToro DB bid at report date EOD — pairs with `Price_End`. From `PriceLog_History_CurrencyPrice.Bid` (GBX/100 adjusted). NULL if no DB price. (Tier 2 — SP_Apex_PnL) |
| 19 | AdditionalFees | decimal(16,6) | YES | Additional Apex fees/adjustments (borrow, corporate actions, etc.) for the day. From `LP_APEX_EXT869_3EU` where `TerminalID NOT IN ('$+DIV','CSCSG','FWWRD','MGLOA','MGJNL')`, negated. Included in the PnL bridge. NULL if no fees. (Tier 2 — SP_Apex_PnL) |
| 20 | Volume | decimal(16,6) | YES | Total traded volume as absolute notional: `SUM(ABS(Quantity × Price + fees))` for the day. Measures total activity regardless of direction. NULL if no trades. (Tier 2 — SP_Apex_PnL) |
| 21 | Zero | decimal(18,6) | YES | Zero PnL adjustment from `Dealing_DailyZeroPnL_Stocks` for `Date = @Date` — captures PnL from positions fully closed to zero within the day. Joined via InstrumentID and AccountNumber→HedgeServerID mapping. NULL if no zero-close activity for this instrument. (Tier 2 — SP_Apex_PnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | SP_Apex_PnL | @Date parameter | SET to report date |
| AccountNumber | LP_APEX_EXT982_3EU / EXT872 / EXT869 | AccountNumber | COALESCE across feeds |
| Symbol | LP_APEX_EXT982_3EU / EXT872 / EXT869 | Symbol | COALESCE across feeds |
| NOP_Start | LP_APEX_EXT982_3EU | MarketValue | Passthrough (sci-notation parsed); @PreviousDayID |
| NOP_Start_DBPrice | LP_APEX_EXT982_3EU + PriceLog | TradeQuantity × Bid | Computed |
| NOP_End | LP_APEX_EXT982_3EU | MarketValue | Passthrough; @DateID |
| NOP_End_DBPrice | LP_APEX_EXT982_3EU + PriceLog | TradeQuantity × Bid | Computed |
| Trades | LP_APEX_EXT872_3EU_217314 | Quantity × Price + fees | SUM; daily scope |
| Dividends | LP_APEX_EXT869_3EU | Amount | SUM WHERE TerminalID='$+DIV'; negated |
| PnL | Computed | — | NOP_End - NOP_Start - Trades + Dividends + AdditionalFees |
| PnL_DBPrice | Computed | — | Same formula, DB-priced NOP |
| UpdateDate | SP_Apex_PnL | GETDATE() | ETL timestamp |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Two-pass Symbol/ISIN match |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Two-pass match |
| Price_Start | LP_APEX_EXT982_3EU | ClosingPrice | CAST; @PreviousDayID |
| Price_Start_DB | PriceLog_History_CurrencyPrice | Bid | GBX/100 adjusted; @PreviousDayID |
| Price_End | LP_APEX_EXT982_3EU | ClosingPrice | CAST; @DateID |
| Price_End_DB | PriceLog_History_CurrencyPrice | Bid | GBX/100 adjusted; @DateID |
| AdditionalFees | LP_APEX_EXT869_3EU | Amount | SUM non-DIV/non-transfer; negated |
| Volume | LP_APEX_EXT872_3EU_217314 | ABS(Quantity × Price + fees) | SUM absolute |
| Zero | Dealing_DailyZeroPnL_Stocks | TotalZero | SUM; Date = @Date; InstrumentID + AccountNumber→HS |

### 5.2 ETL Pipeline

```
Apex Clearing LP External Files
  ├── EXT982_3EU (positions/NOP) ─────────→ Dealing_staging.LP_APEX_EXT982_3EU
  ├── EXT872_3EU_217314 (trades/activity) → Dealing_staging.LP_APEX_EXT872_3EU_217314
  ├── EXT869_3EU (dividends/fees) ────────→ Dealing_staging.LP_APEX_EXT869_3EU
  └── EXT981_3EU (equity) ────────────────→ Dealing_staging.LP_APEX_EXT981_3EU (used by EE tables)

eToro Internal Prices
  └── PriceLog_History_CurrencyPrice ─────→ Dealing_staging.PriceLog_History_CurrencyPrice
      (auto-loaded by SP if missing for @Date)

Internal DWH Sources
  ├── DWH_dbo.Dim_Instrument ─────────────→ Symbol/CUSIP/ISIN → InstrumentID resolution
  ├── DWH_dbo.Dim_Date ───────────────────→ Bank holiday / weekend logic
  └── Dealing_dbo.Dealing_DailyZeroPnL_Stocks → Zero PnL adjustment

  ┌──────────────────────────────────────────────────────┐
  │  SP_Apex_PnL (@Date)                                 │
  │  1. Resolve Apex instruments (#Apex_Ins)             │
  │  2. Get DB prices (#Rates)                           │
  │  3. NOP Start (prior biz day) + NOP End (#NOP_Daily) │
  │  4. Trades (#Trades_ApexFiles_Daily)                 │
  │  5. Dividends + Fees (#Dividends_ApexFiles_Daily)    │
  │  6. Zero adjustment (#Zero_Daily)                    │
  │  7. DELETE WHERE Date=@Date                          │
  │  8. INSERT (FULL JOIN across all feeds)              │
  └──────────────────────────────────────────────────────┘
        ↓
  Dealing_dbo.Dealing_Apex_PnL_Daily (~1.66M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument lookup for display name and attributes |
| Zero | Dealing_dbo.Dealing_DailyZeroPnL_Stocks | Source of Zero PnL adjustment (via InstrumentID + HedgeServerID) |

### 6.2 Referenced By (other objects point to this)

| Downstream | Schema | Notes |
|------------|--------|-------|
| (No known downstream consumers) | — | This is a leaf-level reporting/reconciliation table for Middle Office |

---

## 7. Sample Queries

### 7.1 Latest Available Date and Stale Check

```sql
SELECT MAX(Date) AS LastReportDate, MAX(UpdateDate) AS LastLoad,
       COUNT(*) AS TotalRows
FROM Dealing_dbo.Dealing_Apex_PnL_Daily;
```

### 7.2 Single Day, Single Account — Symbol-Level PnL vs DB-Priced PnL

```sql
SELECT Symbol, InstrumentID, InstrumentDisplayName,
       PnL, PnL_DBPrice,
       PnL - PnL_DBPrice AS MarkDifference
FROM Dealing_dbo.Dealing_Apex_PnL_Daily
WHERE Date = '2024-06-07'
  AND AccountNumber = '3EU05025'
ORDER BY ABS(PnL - PnL_DBPrice) DESC;
```

### 7.3 Compare Daily vs WTD PnL for a Symbol

```sql
SELECT d.Date, d.Symbol, d.PnL AS DailyPnL, w.PnL AS WtdPnL
FROM Dealing_dbo.Dealing_Apex_PnL_Daily d
LEFT JOIN Dealing_dbo.Dealing_Apex_PnL w
  ON w.Date = d.Date AND w.AccountNumber = d.AccountNumber AND w.Symbol = d.Symbol
WHERE d.Date = '2024-06-07'
  AND d.AccountNumber = '3EU05025'
  AND d.Symbol = 'AAPL';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-28 | Quality: 7.5/10 (★★★★☆) | Batch: regen-harness*
*Tiers: 0 T1, 21 T2, 0 T3, 0 T4 | Elements: 21/21, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_Apex_PnL_Daily | Type: Table | Production Source: LP external data via SP_Apex_PnL*
