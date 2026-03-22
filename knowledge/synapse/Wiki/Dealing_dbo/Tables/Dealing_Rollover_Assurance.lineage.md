# Lineage — Dealing_dbo.Dealing_Rollover_Assurance

## Writer
**SP_Rev_Assurance** (`Dealing_dbo.SP_Rev_Assurance`) — runs daily via SB_Daily (Priority 0)

## Upstream Sources

| Source Table | Schema | Usage |
|---|---|---|
| Dim_Position | DWH_dbo | Primary fact — position fields (PositionID, CID, InstrumentID, OpenOccurred, CloseOccurred, Amount, Leverage, IsBuy, MirrorID, HedgeServerID). Filtered to positions open at cutoff time. Excludes unleveraged long stocks/ETFs (InstrumentTypeID IN (5,10) AND Leverage=1 AND IsBuy=1) and HedgeServerID=121 |
| Dim_Instrument | DWH_dbo | InstrumentName (Name), InstrumentType, InstrumentTypeID |
| Dim_Customer | DWH_dbo | Filter: PlayerLevelID <> 4 excludes Premium/PI accounts |
| etoro_History_Credit | Dealing_staging | Actual rollover fees charged (CreditTypeID=14, excluding dividend payments) |
| etoro_Trade_InstrumentToFeeConfig | Dealing_staging | Overnight fee rates per instrument per direction/leverage combination |
| etoro_Customer_CustomerStatic | Dealing_staging | WeekendFeePrecentage per customer (0 = Islamic/swap-free account) |

## Column Lineage

| Column | Source | Tier | Notes |
|---|---|---|---|
| Date | SP parameter @date | Tier 2 | Execution date |
| PositionID | Dim_Position.PositionID | Tier 1 | Direct pass-through |
| CID | Dim_Position.CID | Tier 1 | Direct pass-through |
| InstrumentID | Dim_Position.InstrumentID | Tier 1 | Direct pass-through |
| InstrumentName | Dim_Instrument.Name | Tier 1 | Join on InstrumentID |
| InstrumentType | Dim_Instrument.InstrumentType | Tier 1 | Join on InstrumentID |
| OpenOccurred | Dim_Position.OpenOccurred | Tier 1 | Direct pass-through |
| CloseOccurred | Dim_Position.CloseOccurred | Tier 1 | Open positions substituted with GETDATE() |
| Units | Dim_Position.AmountInUnitsDecimal | Tier 1 | Renamed column |
| Leverage | Dim_Position.Leverage | Tier 1 | Direct pass-through |
| IsBuy | Dim_Position.IsBuy | Tier 1 | Direct pass-through |
| MirrorID | Dim_Position.MirrorID | Tier 1 | Direct pass-through (>0 = copy position) |
| HedgeServerID | Dim_Position.HedgeServerID | Tier 1 | Direct pass-through |
| WeekendFeePrecentage | etoro_Customer_CustomerStatic.WeekendFeePrecentage | Tier 4 | 0 = Islamic swap-free account |
| [Calculated RO] | Computed: InstrumentToFeeConfig rates | Tier 2 | day_multiplier × AmountInUnitsDecimal × overnight_fee_rate; day_multiplier: Sat/Sun=0, Fri×3 (Stocks/ETF/Crypto), Wed×3 (FX/Commodities/Indices), else 1 |
| [Actual RO] | etoro_History_Credit.TotalCashChange negated | Tier 4 | CreditTypeID=14, excluding dividend payments |
| [Total Diff] | Computed | Tier 2 | [Calculated RO] - [Actual RO]; positive = underpaid vs model |
| [Islamic] | Computed | Tier 2 | [Total Diff] where WeekendFeePrecentage=0 (Islamic accounts, swap-free) |
| [Closed after cutoff] | Computed | Tier 2 | [Total Diff] where non-Islamic AND position closed within 90min after cutoff time |
| [Fee updated] | Computed | Tier 2 | [Total Diff] where non-Islamic, not late-close, AND (InstrumentID=22 XNG/USD OR InstrumentTypeID IN (5,6) Crypto/ETF) |
| [Other] | Computed | Tier 2 | [Total Diff] where non-Islamic, not late-close, not Fee Updated category |
| UpdateDate | GETDATE() | Tier 2 | ETL metadata |

## Filter on Insert
Only rows where `ABS([Calculated RO] - CAST([Actual RO] AS NUMERIC(38,8))) > 1` are stored (discrepancy exceeds $1).

## Key Business Logic
- **Cutoff time**: 21:00 UTC (from 2018-03-11 onward; previously 22:00 UTC)
- **Triple-fee days**: Fridays for Stocks/ETF/Crypto; Wednesdays for FX/Commodities/Indices
- **Islamic exclusion**: WeekendFeePrecentage=0 → swap-free (no overnight fees expected)
- **Breakdown categories are mutually exclusive**: [Islamic] + [Closed after cutoff] + [Fee updated] + [Other] = [Total Diff] for each row
