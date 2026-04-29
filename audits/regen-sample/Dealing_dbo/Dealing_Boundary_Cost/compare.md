# Compare — `Dealing_dbo.Dealing_Boundary_Cost`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +2.7; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.25 | 6.95 | 2.7 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 31 | 31 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 3 | 1 | -2 |
| T2 count | 27 | 29 | +2 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |
| T5 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 10 |
| completeness | 4 | 10 |
| data_evidence | 4 | 7 |
| shape_fidelity | 5 | 9 |
| tier_accuracy | 3 | 5 |
| upstream_fidelity | 3 | 3 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.108 | 2 | 2 | Standard deviation of the bid-ask spread as a percentage of mid-price, averaged over the trailing quarterly period (2 months from start of current month). Computed from historical position open/close  | Quarterly average of monthly standard deviations of relative spread `(Ask-Bid)/Mid`, computed from position open/close bid-ask prices over a 3-month lookback window. Measures spread volatility as a pe |
| `28` | 0.112 | 2 | 2 | Identifier for the hedge server holding these positions. Positions can be distributed across multiple hedge servers; this dimension tracks per-HS NOP separately. HS assignment at `@Date` is resolved v | Hedge server managing positions for this instrument. Resolved as `ISNULL(Dim_PositionHedgeServerChangeLog_Snapshot.HedgeServerID, Dim_Position.HedgeServerID)` — prefers the point-in-time SCD2 snapshot |
| `12` | 0.196 | 2 | 2 | Bid price with eToro's spread markup applied (spreaded = bid adjusted for client-facing spread). Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.BidSpreaded`. This is the price a selling clien | Last spread-adjusted bid price within this minute from the PriceLog Data Lake feed (BidSpreaded column). The bid price with broker spread applied. NULL when no price record exists. (Tier 2 — SP_Bounda |
| `26` | 0.201 | 2 | 2 | FX conversion rate to USD for this instrument's sell currency. Sourced from `Fact_CurrencyPriceWithSplit` for the reporting date. For USD-denominated instruments (SellCurrencyID=1), FX_Bid=1.0. For EU | USD conversion rate for the instrument, computed via FX triangulation from Fact_CurrencyPriceWithSplit on @DateID: if SellCurrencyID=1 (USD-quoted) → 1.0; if BuyCurrencyID=1 (USD-based) → 1/Bid; else  |
| `5` | 0.245 | 1 | 1 | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Referenced by virtually every trading fact table. FK to DWH_dbo.Dim_Instrument. (Tie | Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to tradable, externally visible instruments in specific type categories (Commodities, Indices, Stocks, ETF, and USD-quoted Crypt |
| `30` | 0.253 | 2 | 2 | Stock split-adjusted price ratio sourced from `DWH_dbo.Dim_HistorySplitRatio`. Applied only to the first minute of the day (ROW_NUMBER()=1 per instrument×HS×IsSettled) when a split occurred on `@Date` | Stock split price adjustment factor from Dim_HistorySplitRatio. `ISNULL(sr.PriceRatio, 1)` where `MaxDate = @DateID`. Applied only to the first minute row per (InstrumentID, HedgeServerID, IsSettled)  |
| `15` | 0.272 | 2 | 2 | Net units of new short (sell) positions opened (or long positions closed, which creates reverse exposure) in this minute window. Derived from `Dim_Position.AmountInUnitsDecimal` for positions where `I | Total units sold (short positions opened + long positions closed) in this minute bucket for the instrument/HS/IsSettled combination. Aggregated from Dim_Position.AmountInUnitsDecimal. 0 when no sell-s |
| `31` | 0.275 | 2 | 2 | Net units transferred between HedgeServers during `@Date` for this instrument×HS×IsSettled. Tracked via `Dim_PositionChangeLog` ChangeTypeID=12 (HedgeServer change events). Positive values indicate un | Net units moved into or out of this hedge server during this minute due to hedge server reassignment events. Computed from `DWH_dbo.etoro_Trade_PositionsHedgeServerChangeLog` (intraday HS movements) c |
| `13` | 0.285 | 2 | 2 | Ask price with eToro's spread markup applied. Sourced from `PriceLog_History_CurrencyPrice_Active_tmp.AskSpreaded`. This is the price a buying client pays. NULL if no price tick. (Tier 2 — SP_Boundary | Last spread-adjusted ask price within this minute from the PriceLog Data Lake feed (AskSpreaded column). The ask price with broker spread applied. NULL when no price record exists. (Tier 2 — SP_Bounda |
| `20` | 0.289 | 2 | 2 | Total USD volume from buy position opens in this minute. Computed as `SUM(AmountInUnitsDecimal × InitForexRate)` for `IsBuy=1` × FX conversion. Represents the USD value of buy flow. (Tier 2 — SP_Bound | Total USD-equivalent buy-side volume in this minute. For opens: `SUM(Dim_Position.Volume WHERE IsBuy=1)`. For closes: `SUM(Dim_Position.VolumeOnClose WHERE IsBuy=0)` (direction flipped). 0 when no act |

## Top issues — regen wiki (per judge)

- [high] `InstrumentType (#7), InstrumentTypeID (#27)` — Both are direct passthroughs from DWH_dbo.Dim_Instrument (which has a wiki in the bundle) but are tagged Tier 2 — SP_Dim_Instrument. Should be Tier 1 with descriptions quoted verbatim from the Dim_Instrument wiki.
- [high] `IsSettled (#29)` — Direct passthrough from Dim_Position.IsSettled. Dim_Position wiki is in the bundle and documents IsSettled as '1 = real asset, 0 = CFD asset.' Tagged Tier 5 — Expert Review instead of Tier 1 — Dim_Position.
- [high] `InstrumentID (#5)` — Tagged Tier 1 correctly but description is completely paraphrased. Upstream says 'Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd...' but wiki rewrites to 'Financial instrument identifier. FK to DWH_dbo.Dim_Instrument...' — losing allocation origin, ID range, and cross-table references.
- [high] `InstrumentName (#6)` — Renamed from Dim_Instrument.InstrumentDisplayName (SP: InstrumentDisplayName AS InstrumentName). Dim_Instrument wiki documents InstrumentDisplayName. Tagged Tier 2 instead of Tier 1.
- [medium] `Footer` — Footer claims '1 T1, 28 T2, 0 T3, 0 T4, 2 T5' but at least 5 columns should be Tier 1 (InstrumentID, InstrumentName, InstrumentType, InstrumentTypeID, IsSettled). Tier breakdown is incorrect.
