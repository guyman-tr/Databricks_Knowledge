# BI_DB_dbo.BI_DB_Diversification — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Diversification`

## Source Objects
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — population base (funded depositors)
- `DWH_dbo.V_Liabilities` — balance and equity components (Credit, TotalCash, InProcessCashouts, TotalStockOrders)
- `BI_DB_dbo.BI_DB_PositionPnL` — open position data (CID, InstrumentID, MirrorID, PositionPnL, Amount)
- `DWH_dbo.Dim_Instrument` — instrument classification (InstrumentTypeID, InstrumentType, InstrumentDisplayName, Industry)

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | BI_DB_CID_DailyPanel_FullData | CID | Direct passthrough (filtered to IsFunded_New=1) |
| DateID | BI_DB_CID_DailyPanel_FullData | DateID | Direct passthrough |
| Date | SP parameter | @dd | Direct assignment |
| Seniority | BI_DB_CID_DailyPanel_FullData | Seniority | Direct passthrough |
| IsFunded_New | BI_DB_CID_DailyPanel_FullData | IsFunded_New | Direct passthrough (always 1 — filter condition) |
| ActiveUser | BI_DB_CID_DailyPanel_FullData | ActiveOpen | MAX(ActiveOpen) over 30-day window ending at @dd |
| Country | BI_DB_CID_DailyPanel_FullData | Country | CASE: 'United States' → 'US', else → 'Rest' |
| Copy | BI_DB_PositionPnL + Dim_Instrument | MirrorID, InstrumentType | PIVOT: count of positions where MirrorID <> 0 → 'Copy' |
| Crypto Currencies | BI_DB_PositionPnL + Dim_Instrument | InstrumentType | PIVOT: count where MirrorID=0 AND InstrumentType='Crypto Currencies' |
| Stocks/ETF | BI_DB_PositionPnL + Dim_Instrument | InstrumentTypeID | PIVOT: count where MirrorID=0 AND InstrumentTypeID IN (5,6) |
| Commodities/Indices/Currencies | BI_DB_PositionPnL + Dim_Instrument | InstrumentTypeID | PIVOT: count where MirrorID=0 AND InstrumentTypeID IN (2,4,1) |
| NumOfInstruments | Computed | Copy + Crypto + Stocks/ETF + Commodities | SUM of 4 PIVOT columns (ISNULL to 0) |
| NumOfAssets | BI_DB_PositionPnL + Dim_Instrument | InstrumentID | COUNT(DISTINCT InstrumentID) for Stocks/ETF only; NULL unless user holds exactly 1 asset class |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Only populated when user holds exactly 1 Stock/ETF AND NumOfInstruments=1 |
| CryptoName | Dim_Instrument | InstrumentDisplayName | Only populated when user holds exactly 1 crypto AND NumOfInstruments=1 |
| AUA | BI_DB_PositionPnL | PositionPnL, Amount | SUM(ISNULL(PositionPnL,0) + ISNULL(Amount,0)) — assets under administration |
| NumOfIndustries | Dim_Instrument | Industry | COUNT of distinct industries for Stocks/ETF positions; NULL unless user holds exactly 1 industry |
| NumOfCFD | BI_DB_PositionPnL + Dim_Instrument | InstrumentID | COUNT(DISTINCT InstrumentID) for Commodities/Indices/Currencies; NULL unless user holds exactly 1 |
| Balance | V_Liabilities | Credit | Direct rename: Credit → Balance |
| Equity | V_Liabilities + BI_DB_PositionPnL | AUA, TotalCash, TotalStockOrders, InProcessCashouts | ISNULL(AUA,0) + TotalCash + TotalStockOrders + InProcessCashouts |
| Revenue | BI_DB_CID_DailyPanel_FullData | Revenue_Total | SUM(Revenue_Total) over 30-day window ending at @dd |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
