# Compare — `Dealing_dbo.Dealing_IGReconEODHolding`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +1.45; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.6 | 9.05 | 1.45 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 28 | 28 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 28 | 27 | -1 |
| T3 count | 0 | 1 | +1 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 6 | 10 |
| data_evidence | 5 | 9 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `10` | 0.183 | 2 | 2 | EOD position units reported by IG. `SUM((2*IsBuy-1)*IG_Units)` from `LP_IG_PS_EODPositions`. Oil (InstrumentID=17): ×100 multiplier applied. Negative = net short. (Tier 2 — SP_IGRecon) | IG's reported EOD position size in units. Computed as `SUM((2*IsBuy−1) × ABS(Position))` from `LP_IG_PS_EODPositions`. Oil instruments (US Crude) are multiplied by 100. ISNULL defaults to 0 for eToro- |
| `11` | 0.218 | 2 | 2 | eToro's internal EOD hedge units for IG-mapped positions. `SUM(eToro_Units)` from `Dealing_Duco_EODRecon` where HedgeServerID matches IG Fivetran mapping. (Tier 2 — SP_IGRecon) | eToro's hedge position units from Dealing_Duco_EODRecon.eToro_Units. SUM grouped by instrument+account. ISNULL defaults to 0 for IG-only rows. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToro_Units) |
| `24` | 0.231 | 2 | 2 | eToro's price per unit. `MAX(eToroRate)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_IGRecon) | eToro's holding rate from Dealing_Duco_EODRecon.eToroRate. GBX instruments divided by 100 for GBP normalization. MAX grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToroRa |
| `26` | 0.318 | 2 | 2 | IG's FX conversion rate (local → USD). `CASE WHEN Ccy='USD' THEN 1 ELSE CAST(LEFT([Conversion Rate], LEN-1) AS FLOAT)`. (Tier 2 — SP_IGRecon) | IG's FX rate for local-to-USD conversion. From `LP_IG_PS_EODPositions.[Conversion Rate]` (trailing character stripped, parsed as float). USD hardcoded to 1. MAX grouped. ISNULL defaults to 0. (Tier 2  |
| `8` | 0.359 | 2 | 2 | Instrument's local currency. GBX normalised to 'GBP'. ISNULL(eToro_side, IG_side). (Tier 2 — SP_IGRecon) | Instrument local currency. On the eToro side: GBX is normalized to GBP (`CASE WHEN SellCurrency='GBX' THEN 'GBP'`). On the IG side: Ccy passthrough. ISNULL(eToro, IG). Distinct values: USD (56%), EUR  |
| `18` | 0.389 | 2 | 2 | IG's position value in USD. From `LP_IG_PS_EODPositions.[Consideration (Base Ccy)]`. (Tier 2 — SP_IGRecon) | IG's EOD position value in USD. From `LP_IG_PS_EODPositions.[Consideration (Base Ccy)]` with sign adjustment via (2*IsBuy−1). SUM grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPosi |
| `4` | 0.421 | 2 | 2 | eToro instrument identifier. Resolved from IG [Market Name] via `#MarketNameToID` lookup or ISIN join to `DWH_dbo.Dim_Instrument`. FK → DWH_dbo.Dim_Instrument.InstrumentID. (Tier 2 — SP_IGRecon) | eToro instrument identifier. On the eToro side: passthrough from Dealing_Duco_EODRecon. On the IG side: resolved via Dim_Instrument.ISINCode or hardcoded #MarketNameToID mapping. NULL when IG market n |
| `12` | 0.471 | 2 | 2 | Aggregated client NOP units for IG-matched positions. `SUM(ClientUnits)` from `Dealing_Duco_EODRecon`. (Tier 2 — SP_IGRecon) | Aggregated client NOP units from Dealing_Duco_EODRecon.ClientUnits. SUM grouped by instrument+account. ISNULL defaults to 0 for IG-only rows. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.ClientUnits) |
| `23` | 0.478 | 2 | 2 | IG's price per unit (closing price). `MAX(TRY_CONVERT(DECIMAL(16,6), [Latest]))` from `LP_IG_PS_EODPositions`. (Tier 2 — SP_IGRecon) | IG's EOD position price (latest market price). `TRY_CONVERT(DECIMAL(16,6), Latest)` from `LP_IG_PS_EODPositions`. MAX grouped per instrument+account. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG |
| `28` | 0.479 | 2 | 3 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() on each INSERT. (Tier 2 — SP_IGRecon) | ETL batch timestamp set to GETDATE() at INSERT time. Does not reflect production modification time. (Tier 3 -- SP_IGRecon, GETDATE()) |

## Top issues — regen wiki (per judge)

- [low] `IG_Units` — Wiki collapses two-step computation (ABS+oil multiplier in #IG_EOD, then sign adjustment in #IG_EOD_Final) into single formula. Accurate but simplified.
- [low] `IG_LocalAmount` — Wiki says 'TRY_CONVERT' but SP actually uses TRY_CONVERT(DECIMAL) with TRY_CONVERT(FLOAT) fallback chain. Minor precision omission.
- [info] `Section 6.2` — No downstream consumers documented beyond companion table Dealing_IGReconTrades. May be a reporting endpoint with no known readers.
