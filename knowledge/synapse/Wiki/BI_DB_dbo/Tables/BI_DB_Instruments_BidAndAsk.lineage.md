# BI_DB_dbo.BI_DB_Instruments_BidAndAsk — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| DWH_dbo.Dim_Instrument | DWH Dimension | Instrument master — attributes, IDs, exchange info |
| DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted | DWH Dimension | Hourly price candles with bid/ask |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| InstrumentID | Dim_Instrument | InstrumentID | Passthrough (filtered <>0) |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Passthrough |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | Passthrough |
| InstrumentTypeName | Dim_Instrument | InstrumentType | Renamed |
| Symbol | Dim_Instrument | Symbol | Passthrough |
| SymbolFull | Dim_Instrument | SymbolFull | Passthrough |
| Exchange | Dim_Instrument | Exchange | Passthrough |
| ISINCode | Dim_Instrument | ISINCode | ISNULL(ISINCode, 0) |
| ISINCountryCode | Dim_Instrument | ISINCode | Derived: first 2-3 characters of ISIN (country prefix extraction) |
| CUSIP | Dim_Instrument | CUSIP | ISNULL(CUSIP, 0) |
| BuyCurrencyID | Dim_Instrument | BuyCurrencyID | Passthrough |
| BuyCurrencyName | Dim_Instrument | BuyCurrency | Renamed |
| SellCurrencyID | Dim_Instrument | SellCurrencyID | Passthrough |
| SellCurrencyName | Dim_Instrument | SellCurrency | Renamed |
| PipDifferenceThreshold | Dim_Instrument | PipDifferenceThreshold | Passthrough |
| Precision | Dim_Instrument | Precision | Passthrough |
| Tradable | Dim_Instrument | Tradable | Passthrough |
| AllowBuy | Dim_Instrument | AllowBuy | Passthrough |
| AllowSell | Dim_Instrument | AllowSell | Passthrough |
| Ask | Dim_GetSpreadedPriceCandle60MinSplitted | AskLast | Latest candle for yesterday (ROW_NUMBER DESC, RN=1) |
| Bid | Dim_GetSpreadedPriceCandle60MinSplitted | BidLast | Latest candle for yesterday (ROW_NUMBER DESC, RN=1) |
| UpdateDate | — | — | GETDATE() |

## Pipeline

```
DWH_dbo.Dim_Instrument (instrument attributes, filtered InstrumentID<>0)
  + DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted (hourly candles, yesterday only)
    |-- SP_Instruments_BidAndAsk (daily TRUNCATE + INSERT) --|
    |   JOIN on InstrumentID, filter AskLastOccurred=yesterday |
    |   ROW_NUMBER per instrument, take latest candle (RN=1)   |
    v
BI_DB_dbo.BI_DB_Instruments_BidAndAsk (460 rows, daily snapshot)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
