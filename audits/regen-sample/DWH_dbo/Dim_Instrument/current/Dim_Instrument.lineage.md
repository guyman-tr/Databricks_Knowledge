# Column Lineage: DWH_dbo.Dim_Instrument

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Instrument` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **Primary Source** | `etoro.Trade.GetInstrument` (view, etoroDB-REAL / AZR-W-TRADEDB) |
| **ETL SP** | `DWH_dbo.SP_Dim_Instrument` |
| **Secondary Sources** | Trade.InstrumentMetaData, Trade.ProviderToInstrument, Trade.InstrumentCusip, Trade.FuturesMetaData, Trade.FuturesInstrumentsInitialMarginByProviderMapping, Trade.Instrument, Dictionary.Currency, Rankings.StockInfo, PriceLog (static external) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Trade.GetInstrument  (etoroDB-REAL / AZR-W-TRADEDB)
  |-- Generic Pipeline (Override, 1440min) ---|
  v
Bronze/etoro/Trade/GetInstrument/
  (trading.bronze_etoro_trade_getinstrument)
  |-- staging import ---|
  v
DWH_staging.etoro_Trade_GetInstrument   (primary)
DWH_staging.etoro_Dictionary_Currency  (+secondary JOIN)
DWH_staging.etoro_Trade_InstrumentMetaData (+secondary JOIN)
DWH_staging.etoro_Trade_ProviderToInstrument (+secondary JOIN)
DWH_staging.etoro_Trade_InstrumentCusip (+secondary JOIN)
DWH_staging.etoro_Trade_FuturesMetaData (+secondary JOIN)
DWH_staging.etoro_Trade_FuturesInstrumentsInitialMarginByProviderMapping (+secondary JOIN)
DWH_staging.etoro_Trade_Instrument (+secondary JOIN, for OperationMode/AllowBuy/Sell/Tradable)
  |-- SP_Dim_Instrument (TRUNCATE + JOIN INSERT + 5 post-load UPDATEs, daily) ---|
  v
DWH_dbo.Dim_Instrument  (15,707 rows)
  |-- SP calls: EXEC SP_Dim_Instrument_Snapshot @dt (triggers snapshot table) ---|
  |-- Generic Pipeline (Override, 1440min) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast** | Type conversion only (e.g., bit to int). |
| **CASE** | Value-mapped via CASE expression in SP. |
| **join-enriched** | Value pulled from a secondary staging JOIN. |
| **post-load UPDATE** | Set via a separate UPDATE statement after the main INSERT. |
| **ETL-computed** | Derived/calculated by ETL SP. Not from any single source column. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| InstrumentID | etoro.Trade.GetInstrument | InstrumentID | passthrough | PK; allocated by Trade.InstrumentAdd |
| InstrumentTypeID | etoro.Trade.GetInstrument | InstrumentTypeID | passthrough | 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto |
| InstrumentType | etoro.Trade.GetInstrument | InstrumentTypeID | CASE | Text label derived in SP; 'Other' for unmapped type IDs |
| Name | etoro.Trade.GetInstrument | Name | passthrough | Internal instrument name |
| DWHInstrumentID | etoro.Trade.GetInstrument | InstrumentID | rename | Always = InstrumentID; DWH redundancy pattern |
| StatusID | -- | -- | ETL-computed | Hardcoded 1 for all real rows; NULL only for ID=0 |
| BuyCurrencyID | etoro.Trade.GetInstrument | BuyCurrencyID | passthrough | Buy-side asset FK; for stocks = InstrumentID |
| SellCurrencyID | etoro.Trade.GetInstrument | SellCurrencyID | passthrough | Sell-side denomination currency FK |
| BuyCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched | Joined via BuyCurrencyID = Dictionary.Currency.CurrencyID |
| SellCurrency | etoro.Dictionary.Currency | Abbreviation | join-enriched | Joined via SellCurrencyID = Dictionary.Currency.CurrencyID |
| TradeRange | etoro.Trade.GetInstrument | TradeRange | passthrough | Allowed pip range for pending orders |
| DollarRatio | etoro.Trade.GetInstrument | DollarRatio | passthrough | Price scaling factor; JPY=100, others=1 |
| PipDifferenceThreshold | etoro.Trade.GetInstrument | PipDifferenceThreshold | passthrough | Price validation threshold; NULL for some instruments |
| IsMajorID | etoro.Trade.GetInstrument | IsMajor | cast | Production bit renamed to int; 1=major, 0=non-major |
| IsMajor | etoro.Trade.GetInstrument | IsMajor | CASE | 1->'Yes', 0->'No'; text for display |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time; not production modification date |
| InsertDate | -- | -- | ETL-computed | GETDATE() at load time; identical to UpdateDate (TRUNCATE+INSERT pattern) |
| InstrumentDisplayName | etoro.Trade.InstrumentMetaData | InstrumentDisplayName | join-enriched | User-facing name; NULL if no metadata row |
| Industry | etoro.Trade.InstrumentMetaData | Industry | join-enriched | Text industry classification from metadata |
| CompanyInfo | etoro.Trade.InstrumentMetaData | CompanyInfo | join-enriched | Free-text company description |
| Exchange | etoro.Trade.InstrumentMetaData | Exchange | join-enriched | Stock exchange name |
| ISINCode | etoro.Trade.InstrumentMetaData | ISINCode | join-enriched | 12-char ISO 6166 code |
| ISINCountryCode | etoro.Trade.InstrumentMetaData | ISINCountryCode | join-enriched | First 2 chars of ISIN |
| Tradable | etoro.Trade.Instrument | Tradable | cast | bit to int; 1=tradable |
| Symbol | etoro.Trade.GetInstrument | Symbol | passthrough | Ticker symbol |
| ReceivedOnPriceServer | PriceLog (Ext_Dim_Instrument_ReceivedOnPriceServerStatic) | ReceivedOnPriceServer | post-load UPDATE | First datetime seen on price server; static external file |
| BonusCreditUsePercent | etoro.Trade.ProviderToInstrument | BonusCreditUsePercent | join-enriched | % of bonus credit allowed for this instrument |
| SymbolFull | etoro.Trade.InstrumentMetaData | SymbolFull | join-enriched | Full ticker symbol for data provider integrations |
| CUSIP | etoro.Trade.InstrumentCusip | CUSIP | join-enriched | 9-char US/Canadian securities identifier |
| Precision | etoro.Trade.ProviderToInstrument | Precision | join-enriched | Decimal places for price display |
| AllowBuy | etoro.Trade.Instrument | AllowBuy | cast | bit to int; 1=long positions allowed |
| AllowSell | etoro.Trade.Instrument | AllowSell | cast | bit to int; 1=short positions allowed |
| AssetClass | Ext_Dim_Instrument_Classification_Static | AssetClass | post-load UPDATE | Bloomberg-style asset class; static external table |
| IndustryGroup | Ext_Dim_Instrument_Classification_Static | IndustryGroup | post-load UPDATE | Bloomberg-style industry group; static external table |
| ADV_Last3Months | Rankings.StockInfo (MetadataID=8557) | NumVal | post-load UPDATE | Average Daily Volume trailing 3 months |
| MKTcap | Rankings.StockInfo (MetadataID=8735/9315) | NumVal | post-load UPDATE | Market cap USD; MetadataID 8735 for stocks, 9315 (CryptoMarketCap) fallback |
| SharesOutStanding | Rankings.StockInfo (MetadataID=8444) | NumVal | post-load UPDATE | Total shares outstanding |
| VisibleInternallyOnly | etoro.Trade.GetInstrument | VisibleInternallyOnly | cast | bit to int; 1=internal only |
| PlatformSector | Rankings.StockInfo (MetadataID=8436) | StrVal | post-load UPDATE | eToro platform sector taxonomy |
| PlatformIndustry | Rankings.StockInfo (MetadataID=8280) | StrVal | post-load UPDATE | eToro platform industry taxonomy |
| IsFuture | etoro.Trade.InstrumentGroups (GroupID=25) | InstrumentID membership | ETL-computed | CASE: 1 if in GroupID=25, else 0 |
| Multiplier | etoro.Trade.FuturesMetaData | Multiplier | join-enriched | Contract size multiplier; NULL for non-futures |
| ProviderID | etoro.Trade.ProviderToInstrument | ProviderID | join-enriched | Liquidity provider identifier |
| ProviderMarginPerLot | etoro.Trade.FuturesInstrumentsInitialMarginByProviderMapping | InitialMargin | join-enriched | Provider's margin per lot; primarily for futures |
| eToroMarginPerLot | etoro.Trade.ProviderToInstrument | InitialMarginInAssetCurrency | join-enriched | eToro margin per lot in asset currency |
| SettlementTime | etoro.Trade.ProviderToInstrument | SettlementTime | cast | TIME formatting via SP DATEPART conversion |
| OperationMode | etoro.Trade.Instrument | OperationMode | join-enriched | 0=Standard, 1=Alternate (~83 instruments) |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 13 |
| **Rename** | 1 |
| **Cast** | 5 |
| **CASE** | 2 |
| **Join-enriched** | 18 |
| **Post-load UPDATE** | 6 |
| **ETL-computed** | 2 |
| **Total** | 47 |
