# DWH_dbo.Fact_Position_Futures_Snapshot — Production Lineage Map

## Source Resolution

| Property | Value |
|----------|-------|
| **Production Source** | DWH-internal computation (no direct production import) |
| **Key Inputs** | Dim_Position, Dim_Instrument_Snapshot, Fact_Settlement_Prices, Dim_PositionChangeLog |
| **ETL SP** | SP_Fact_Position_Futures_Snapshot |
| **Created** | 2024-11-11 by Guy Manova |

## Column Lineage

| # | Column | Source | Transform |
|---|--------|--------|-----------|
| 1 | Date | SP parameter @dt | Passthrough |
| 2 | DateID | SP parameter @dt | CONVERT(INT, YYYYMMDD) |
| 3 | SettlementCategory | Computed | 'OpenAtSettlement' or 'ClosedBeforeSettlement' |
| 4 | CID | Dim_Position.CID | Passthrough |
| 5 | PositionID | Dim_Position.PositionID | Passthrough |
| 6 | OriginalPositionID | Dim_Position.OriginalPositionID | For non-partials: set to PositionID |
| 7 | InstrumentID | Dim_Position.InstrumentID | Filtered: IsFuture=1 only |
| 8 | LotCountDecimal | Dim_Position + PositionChangeLog | Adjusted to settlement-time state |
| 9 | SettlementTime | Dim_Instrument_Snapshot.SettlementTime | Passthrough |
| 10 | SettlementPrice | Fact_Settlement_Prices | Latest within 14-day lookback |
| 11 | InvestedAmount | Dim_Position.Amount + PositionChangeLog | Adjusted to settlement-time state |
| 12 | OpenOccurred | Dim_Position.OpenOccurred | Passthrough |
| 13 | CloseOccurred | Dim_Position.CloseOccurred | '1900-01-01' for open positions |
| 14 | InitForexRate | Dim_Position.InitForexRate | Passthrough |
| 15 | EndForexRate | Dim_Position.EndForexRate | NULL for open positions |
| 16-17 | IsPartialClose* | Computed from PositionChangeLog | Reconstructed at settlement time |
| 18 | IsBuy | Dim_Position.IsBuy | Passthrough |
| 19 | ProviderID | Dim_Instrument_Snapshot.ProviderID | Passthrough |
| 20 | Multiplier | Dim_Instrument_Snapshot.Multiplier | Passthrough |
| 21-22 | Margins | Computed | LotCount × MarginPerLot at settlement |
| 23 | PnL | Computed | Open: settlement MTM. Closed: NetProfit |
| 24-27 | Initial*Full | Computed from PositionChangeLog | Original position state at open |
| 28-31 | Initial*Residual | Computed | Pro-rated by residual/full lot ratio |
| 32 | UpdateDate | GETDATE() | ETL timestamp |
