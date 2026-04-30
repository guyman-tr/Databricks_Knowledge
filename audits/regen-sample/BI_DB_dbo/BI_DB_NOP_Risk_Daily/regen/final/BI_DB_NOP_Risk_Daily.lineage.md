# Lineage: BI_DB_dbo.BI_DB_NOP_Risk_Daily

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|--------------|------|--------|------|------|
| 1 | BI_DB_PositionPnL | Table | BI_DB_dbo | Primary source — daily open-position P&L snapshot; provides DateID, InstrumentID, IsSettled, IsBuy, NOP | [BI_DB_PositionPnL.md](../../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_PositionPnL.md) |
| 2 | Dim_Instrument | Table | DWH_dbo | Lookup — instrument metadata; provides InstrumentTypeID, InstrumentDisplayName | [Dim_Instrument.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| 3 | SP_NOP_TradingActivity_Risk_Daily | Stored Procedure | BI_DB_dbo | Writer SP — aggregates NOP by instrument/settlement/direction | — |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| DateID | BI_DB_PositionPnL | DateID | Passthrough | Tier 1 |
| InstrumentID | BI_DB_PositionPnL | InstrumentID | Passthrough | Tier 1 |
| IsSettled | BI_DB_PositionPnL | IsSettled | Passthrough | Tier 1 |
| InstrumentType | BI_DB_PositionPnL + Dim_Instrument | IsSettled, InstrumentTypeID | CASE on InstrumentTypeID + IsSettled → 7 categories | Tier 2 |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Passthrough (dim-lookup via InstrumentID) | Tier 1 |
| SellBuy | BI_DB_PositionPnL | IsBuy | CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell' | Tier 2 |
| NOP | BI_DB_PositionPnL | NOP | SUM(NOP) per group, CAST to BIGINT | Tier 2 |
| UpdateDate | SP_NOP_TradingActivity_Risk_Daily | — | GETDATE() at insert | Tier 2 |
