# Lineage: BI_DB_dbo.BI_DB_EY_Audit_ChangeLog

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|--------------|------|--------|------|------|
| 1 | Dim_PositionChangeLog | Table | DWH_dbo | Primary source — position change events filtered to ChangeTypeID IN (12, 13) | [Dim_PositionChangeLog.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PositionChangeLog.md) |
| 2 | Dim_Position | Table | DWH_dbo | JOIN — supplies IsBuy, InstrumentID, InitialUnits (fallback for UnitsOpenStartOfDay) | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| 3 | BI_DB_PositionPnL | Table | BI_DB_dbo | LEFT JOIN — prior-day AmountInUnitsDecimal used as primary source for UnitsOpenStartOfDay | [BI_DB_PositionPnL.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL.md) |
| 4 | Fact_CurrencyPriceWithSplit | Table | DWH_dbo | EOD bid/ask prices for EODPrice computation | [Fact_CurrencyPriceWithSplit.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CurrencyPriceWithSplit.md) |
| 5 | Dim_Instrument | Table | DWH_dbo | BuyCurrencyID/SellCurrencyID for USD cross-rate conversion in EODPrice | [Dim_Instrument.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|---------------|---------------|-----------|------|
| 1 | PositionID | Dim_PositionChangeLog | PositionID | Passthrough | Tier 1 |
| 2 | CID | Dim_PositionChangeLog | CID | Passthrough | Tier 1 |
| 3 | Occurred | Dim_PositionChangeLog | Occurred | Passthrough | Tier 1 |
| 4 | OccurredDateID | Dim_PositionChangeLog | OccurredDateID | Passthrough | Tier 1 |
| 5 | ChangeTypeID | Dim_PositionChangeLog | ChangeTypeID | Passthrough; filtered to IN (12, 13) | Tier 4 |
| 6 | PreviousAmount | Dim_PositionChangeLog | PreviousAmount | Passthrough | Tier 1 |
| 7 | AmountChanged | Dim_PositionChangeLog | AmountChanged | Passthrough | Tier 1 |
| 8 | NewAmount | Dim_PositionChangeLog | NewAmount | Passthrough | Tier 1 |
| 9 | PreviousIsSettled | Dim_PositionChangeLog | PreviousIsSettled | Passthrough | Tier 5 |
| 10 | IsSettled | Dim_PositionChangeLog | IsSettled | Passthrough | Tier 5 |
| 11 | PreviousStopRate | Dim_PositionChangeLog | PreviousStopRate | Passthrough | Tier 1 |
| 12 | StopRate | Dim_PositionChangeLog | StopRate | Passthrough | Tier 1 |
| 13 | PreviousAmountInUnits | Dim_PositionChangeLog | PreviousAmountInUnits | Passthrough; backfilled from UnitsOpenStartOfDay when NULL and ChangeTypeID=13 | Tier 1 |
| 14 | AmountInUnits | Dim_PositionChangeLog | AmountInUnits | Passthrough; backfilled from UnitsOpenStartOfDay when NULL and ChangeTypeID=13 | Tier 1 |
| 15 | UnitsOpenStartOfDay | Dim_Position / BI_DB_PositionPnL | InitialUnits / AmountInUnitsDecimal | CASE: pnl.AmountInUnitsDecimal when available, else dp.InitialUnits; fallback to PreviousAmountInUnits when NULL and ChangeTypeID=12 | Tier 2 |
| 16 | EODPrice | Fact_CurrencyPriceWithSplit / Dim_Instrument | BidSpreaded, AskSpreaded, BuyCurrencyID, SellCurrencyID | IsBuy-directional bid/ask * USD cross-rate conversion factor via currency pair chain | Tier 2 |
| 17 | IsBuy | Dim_Position | IsBuy | Passthrough (CAST bit to int) | Tier 1 |
| 18 | InstrumentID | Dim_Position | InstrumentID | Passthrough | Tier 1 |
| 19 | UpdateDate | SP_EY_Audit_ChangeLog | N/A | GETDATE() at insert time | Tier 2 |
