# Compare — `Dealing_dbo.Dealing_Execution_Slippage`

**Bucket**: `slop`

**Verdict**: **WORSE**  (score delta -1.1; slop 1 -> 1 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.9 | 6.8 | -1.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 1 | +0 |
| Element rows | 21 | 21 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 1 | 1 | +0 |
| T2 count | 20 | 20 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 6 | 10 |
| data_evidence | 7 | 7 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 8 | 5 |
| upstream_fidelity | 10 | 3 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `5` | 0.187 | 2 | 2 | Direction of the hedge: 1=Buy (eToro is buying from LP), 0=Sell (eToro is selling to LP). For open positions IsBuy follows position direction; for closes it is inverted (`CASE WHEN HP.IsBuy = 1 THEN 0 | 1 = buy (long) position, 0 = sell (short). Determines slippage sign direction and which price column (Ask vs Bid) is used for eToro_Price and Kusto_Price. ~92% sells in recent data. (Tier 2 — SP_Execu |
| `21` | 0.256 | 2 | 2 | Count of individual hedge transactions aggregated into this row: `COUNT(*)` per InstrumentID/Occurred/ExecutionTime/ExecutionRate/HedgingMode group. Added Nov 2023 (SR-220487). (Tier 2 — SP_Execution_ | Count of raw Etoro_Hedge_ExecutionLog records summed into this execution group. Typically 2 per row (min=2, max=4 in recent data). Use SUM(NumberofTransaction) for total trade count, not COUNT(*). (Ti |
| `4` | 0.264 | 2 | 2 | The datetime at which the LP confirmed execution of the hedge order, per `Dealing_staging.Etoro_Hedge_ExecutionLog`. This is the actual fill timestamp. (Tier 2 — SP_Execution_Slippage) | Actual LP fill timestamp from Dealing_staging.Etoro_Hedge_ExecutionLog. Millisecond precision. Use `DATEDIFF(ms, Occurred, ExecutionTime)` for execution latency analysis. (Tier 2 — SP_Execution_Slippa |
| `16` | 0.273 | 2 | 2 | Hedging regime: `CBH` (Clearing Broker Hedging — STP to external clearing broker, e.g., Apex, BNY VIRTU) or `HBC` (Hedge By Company — eToro trades directly as market maker). Derived from `Dealing_stag | Routing mode for the execution. CBH = Clearing Broker Hedging (Apex/BNY Mellon); HBC = Hedge By Company (eToro internal). Determined by LEFT JOIN to Dealing_staging.Etoro_Hedge_HBCOrderLog: if OrderID |
| `8` | 0.29 | 2 | 2 | eToro's own price (Ask for buy, Bid for sell) at SendTime, from `CopyFromLake.PriceLog_History_CurrencyPrice` matched by `RateIDAtSent`. This is the reference price against which slippage is measured. | eToro's quoted price at SendTime. Ask for buys (IsBuy=1), Bid for sells (IsBuy=0). Source: CopyFromLake.PriceLog_History_CurrencyPrice matched via RateIDAtSent. Compare to ExecutionRate for slippage.  |
| `18` | 0.306 | 2 | 2 | LP's market price at KustoTime: `CASE WHEN IsBuy=1 THEN AskKusto ELSE BidKusto END` from PricesFromProvider_MarketCurrencyPrice. Allows comparison of LP's published market rate vs their actual executi | Kusto LP market price at KustoTime. Ask for buys (IsBuy=1), Bid for sells (IsBuy=0). Source: PricesFromProvider_MarketCurrencyPrice. Compare to eToro_Price for cross-source price validation. (Tier 2 — |
| `1` | 0.331 | 2 | 2 | Partition date: the calendar date on which the hedge executions occurred. Used as the daily load key (DELETE WHERE Date = @Date before insert). (Tier 2 — SP_Execution_Slippage) | Business date (UTC) for which slippage is computed. Equals the @Date parameter passed to SP_Execution_Slippage. Clustered index key — always include in WHERE for efficient range scans. (Tier 2 — SP_Ex |
| `11` | 0.374 | 2 | 2 | Currency conversion factor to USD for the instrument's settlement currency. Computed via instrument's SellCurrencyID chain: SellCurrencyID=1(USD)→1.0; BuyCurrencyID=1→1/ForexRate; GBX(666)→rate÷100; o | USD conversion factor. 1.0 for USD-denominated instruments. Computed from DWH_dbo.Fact_CurrencyPriceWithSplit via cross-currency logic: SellCurrencyID=1 → 1.0; BuyCurrencyID=1 → 1/Bid or 1/Ask; GBX →  |
| `2` | 0.385 | 1 | 1 | Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtu | Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument. 75 distinct instruments in recent data (Sep–Oct 2024). (Tier 1 — Trade.Instrument) |
| `19` | 0.414 | 2 | 2 | eToro's spreaded Bid price at SendTime from CopyFromLake.PriceLog_History_CurrencyPrice. The eToro price after spread markup has been applied. Added Jun 2022. (Tier 2 — SP_Execution_Slippage) | Spread-adjusted bid price from CopyFromLake.PriceLog_History_CurrencyPrice at SendTime. The bid price with broker spread applied. Passed through from the same price record as eToro_Price. (Tier 2 — SP |

## Top issues — regen wiki (per judge)

- [high] `InstrumentID` — Tagged Tier 1 — Trade.Instrument but the SP sources InstrumentID from Dealing_staging.Etoro_Hedge_ExecutionLog (SELECT InstrumentID FROM Dealing_staging.Etoro_Hedge_ExecutionLog). Dim_Instrument is joined only for InstrumentType/BuyCurrencyID/SellCurrencyID — not to source InstrumentID. Should be Tier 2.
- [high] `InstrumentID` — Description is fully paraphrased. Upstream says 'Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated.' Wiki says 'Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Identifies the hedged instrument.' — no overlap.
- [medium] `Footer / Tier counts` — Footer claims '1 T1, 20 T2' but after correcting InstrumentID to Tier 2, counts should be 0 T1, 21 T2.
- [low] `Section 8 / Phase Gate` — No explicit Phase Gate Checklist section. Footer says 'Phases: 12/14' but does not identify which 2 phases were skipped.
- [low] `Section 8` — Section 8 is a placeholder ('Phase 10 skipped'). Acceptable given environment constraints but noted.
