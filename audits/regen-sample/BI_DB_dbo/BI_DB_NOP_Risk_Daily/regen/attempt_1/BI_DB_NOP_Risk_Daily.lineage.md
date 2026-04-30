# Lineage: BI_DB_dbo.BI_DB_NOP_Risk_Daily

## Source Objects

| Source Object | Schema | Type | Relationship |
|--------------|--------|------|-------------|
| BI_DB_PositionPnL | BI_DB_dbo | Table | Primary data source — daily position-level NOP aggregated by instrument/settlement/direction |
| Dim_Instrument | DWH_dbo | Table | JOIN for InstrumentTypeID and InstrumentDisplayName |
| SP_NOP_TradingActivity_Risk_Daily | BI_DB_dbo | Stored Procedure | Writer SP — Step 04 (#dailynop) populates this table |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough (GROUP BY key) | Tier 2 |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Passthrough (GROUP BY key) | Tier 1 |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough (GROUP BY key) | Tier 5 |
| InstrumentType | BI_DB_dbo.BI_DB_PositionPnL + DWH_dbo.Dim_Instrument | IsSettled, InstrumentTypeID | CASE: InstrumentTypeID+IsSettled mapped to RealStocksETF/CFDStocksETF/RealCrypto/CFDCrypto/Currencies/Commodities/Indecies/Check | Tier 2 |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough via JOIN on DWHInstrumentID=InstrumentID | Tier 1 |
| SellBuy | BI_DB_dbo.BI_DB_PositionPnL | IsBuy | CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell' | Tier 2 |
| NOP | BI_DB_dbo.BI_DB_PositionPnL | NOP | CAST(SUM(NOP) AS BIGINT) — aggregated per instrument/settlement/direction | Tier 2 |
| UpdateDate | SP_NOP_TradingActivity_Risk_Daily | N/A | GETDATE() at insert | Tier 2 |
