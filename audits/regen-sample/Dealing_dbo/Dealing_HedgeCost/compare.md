# Compare — `Dealing_dbo.Dealing_HedgeCost`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +3.1; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.2 | 7.3 | 3.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 15 | 15 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 2 | +2 |
| T2 count | 14 | 12 | -2 |
| T3 count | 0 | 1 | +1 |
| T4 count | 0 | 0 | +0 |
| T5 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 9 |
| completeness | 4 | 8 |
| data_evidence | 5 | 7 |
| shape_fidelity | 5 | 8 |
| tier_accuracy | 3 | 5 |
| upstream_fidelity | 3 | 8 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `4` | 0.079 | 5 | 2 | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) | Settlement type classification: 'Real' = settled stock ownership position (IsSettled=1 or HedgeServerID IN (9,102,112,125,126) for LP side), 'CFD' = contract-for-difference. Client-side uses Dim_Posit |
| `2` | 0.146 | 2 | 1 | Identifier for the tradeable instrument (Stocks and ETFs, USD-denominated only). FK to DWH_dbo.Dim_Instrument. Only instruments with InstrumentTypeID IN (5,6) and SellCurrencyID=1 appear in this table | The instrument being hedged (e.g., EUR/USD, Apple stock). Implicitly references Trade.Instrument. Filtered to SellCurrencyID=1 (USD) and InstrumentTypeID IN (5,6) (stocks/ETFs). (Tier 1 -- upstream wi |
| `11` | 0.155 | 2 | 2 | **Hedge Cost** — the net P&L impact of hedging for eToro. Formula: `AskSpreaded × (Clients_Units - LP_Executed_Units) - (Clients_Units × ClientAvgRate - FullCommission) + LP_Executed_Units × LP_Avg_Ra | Hedge cost: the net cost of hedging client positions against LP executions, marked to end-of-day market price. Formula: (AskSpreaded*NetUnits - (NetUnits*AvgRate - FullCommission)) - (AskSpreaded*LP_E |
| `3` | 0.2 | 2 | 1 | Instrument name from `DWH_dbo.Dim_Instrument.Name` (internal name, e.g., 'COP.US/USD'). Note: in Phase 1 DDL this is varchar(50) which may truncate long names; prefer InstrumentDisplayName from Dim_In | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name |
| `15` | 0.235 | 2 | 2 | Variable spread commission from `BI_DB_dbo.BI_DB_VarCommission` for this instrument×HedgeServer×IsSettled on `Date`. Represents the variable component of spread revenue. Note: `BI_DB_VarCommission` mu | Total spread-based (variable) commission for the instrument on the report date. Passthrough from BI_DB_VarCommission.VarCommission, matched by DateID, InstrumentID, IsSettled, and HedgeServerID. NULL  |
| `14` | 0.241 | 2 | 2 | Realized commission amount from `Dealing_DailyZeroPnL_Stocks.RealizedCommission` — zero-PnL based commission accruals for this date. Note: differs from `AvgRateClientsNoSpread` computation which uses  | Aggregate realized commission from positions closed on the report date. Despite the column name, this is sourced from SUM(RealizedCommission) in Dealing_DailyZeroPnL_Stocks, NOT from Dim_Position.Full |
| `8` | 0.242 | 2 | 2 | Net units actually executed by eToro's Liquidity Provider on this date for this instrument×HS×IsSettled. Sourced from `etoro.Hedge.ExecutionLog.Units × (IsBuy×2-1)`, only successful executions (`Succe | Net signed liquidity provider execution units: ISNULL(SUM(Units*(IsBuy*2-1)), 0) from successful hedge fills (Success=1) in CopyFromLake.etoro_Hedge_ExecutionLog. Zero when no external hedging occurre |
| `9` | 0.274 | 2 | 2 | Volume-weighted average execution rate for LP hedge trades. `SUM(Units × ExecutionRate) / SUM(Units × (IsBuy×2-1))` from `etoro.Hedge.ExecutionLog`. Represents the average market price at which eToro  | Volume-weighted average execution rate from the liquidity provider: ISNULL(SUM(Units*(IsBuy*2-1)*ExecutionRate) / NULLIF(SUM(Units*(IsBuy*2-1)), 0), 0). Zero when no LP executions exist. (Tier 2 -- SP |
| `6` | 0.304 | 2 | 2 | Client net volume per unit minus commission per unit, representing the effective market rate seen by clients excluding the spread. Formula: `(NetUnits × AvgRate - FullCommission) / NetUnits`. This bac | Commission-adjusted average client rate: (NetUnits*AvgRate - FullCommission) / NULLIF(NetUnits, 0). Represents the effective cost basis for client positions after removing commission impact. Returns 0 |
| `5` | 0.348 | 2 | 2 | Net client position units for this instrument×HS×IsSettled on `Date`. Computed as `SUM((IsBuy×2-1) × AmountInUnitsDecimal)` across all opens and closes for valid customers. Positive = net long client  | Net signed client position units for the instrument group: SUM((IsBuy*2-1)*AmountInUnitsDecimal). Positive = net long exposure, negative = net short. Combines positions opened on @Date (using InitFore |

## Top issues — regen wiki (per judge)

- [high] `VariableSpread (#15)` — Tagged Tier 2 (SP_HedgeCost, BI_DB_VarCommission.VarCommission) but SP code is a direct passthrough: v.VarCommission AS VariableSpread. BI_DB_VarCommission wiki is in the bundle. Should be Tier 1 with verbatim upstream description.
- [high] `InstrumentID (#2)` — Tagged Tier 1 (Hedge.ExecutionLog via Dim_Instrument) but it is a GROUP BY key across multiple SP temp tables. Lineage file correctly says Tier 2. Source attribution wrong: primary source is Dim_Position, not ExecutionLog.
- [medium] `Property Table` — Missing UC Target, UC Format, UC Partitioned By, and UC Table Type rows. Other wikis in this repo include these.
- [medium] `Section 3.4 Gotchas` — Missing gotcha about Fact_CurrencyPriceWithSplit JOIN lacking isvalid=1 filter. The FCPWS wiki notes ~46% of rows are isvalid=0. HC calculation may use arbitrary price row. Documented in review-needed sidecar but not in the wiki itself.
- [low] `FullCommission (#14)` — Description says 'Aggregate realized commission from positions closed on the report date' but does not clarify the aggregation crosses all Leverage, Regulation, MifID, and IsManual values from DailyZeroPnL_Stocks. Analysts expecting instrument-level match may be surprised.
