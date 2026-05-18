# Column Lineage: main.etoro_kpi_prep.v_dim_instrument_enriched

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_dim_instrument_enriched` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_dim_instrument_enriched.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_dim_instrument_enriched.json` (rows: 50, mismatches: 3) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata_daily` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\Trade\Views\Trade.InstrumentMetaData_Daily.md` |
| `main.trading.bronze_etoro_trade_instrumentgroups` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\Trade\Tables\Trade.InstrumentGroups.md` |
| `main.trading.bronze_etoro_trade_instrumentmetadata_daily` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\Trade\Views\Trade.InstrumentMetaData_Daily.md` |
| `main.trading.bronze_etoro_trade_providertoinstrument` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\etoro\Wiki\Trade\Tables\Trade.ProviderToInstrument.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   ←── primary upstream
  + main.trading.bronze_etoro_trade_instrumentmetadata_daily   (JOIN)
  + main.trading.bronze_etoro_trade_instrumentgroups   (JOIN)
  + main.trading.bronze_etoro_trade_instrumentmetadata_daily   (JOIN)
  + main.trading.bronze_etoro_trade_providertoinstrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_dim_instrument_enriched   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `InstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.InstrumentID |
| 2 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.InstrumentTypeID |
| 3 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentType` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.InstrumentType |
| 4 | `Name` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Name` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.Name |
| 5 | `DWHInstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `DWHInstrumentID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.DWHInstrumentID |
| 6 | `StatusID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `StatusID` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.StatusID |
| 7 | `BuyCurrencyID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `BuyCurrencyID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.BuyCurrencyID |
| 8 | `SellCurrencyID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SellCurrencyID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.SellCurrencyID |
| 9 | `BuyCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `BuyCurrency` | `passthrough` | (Tier 1 — Dictionary.Currency) | cc.BuyCurrency |
| 10 | `SellCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SellCurrency` | `passthrough` | (Tier 1 — Dictionary.Currency) | cc.SellCurrency |
| 11 | `TradeRange` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `TradeRange` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.TradeRange |
| 12 | `DollarRatio` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `DollarRatio` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.DollarRatio |
| 13 | `PipDifferenceThreshold` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `PipDifferenceThreshold` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.PipDifferenceThreshold |
| 14 | `IsMajorID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IsMajorID` | `passthrough` | (Tier 1 — Trade.GetInstrument) | cc.IsMajorID |
| 15 | `IsMajor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IsMajor` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.IsMajor |
| 16 | `UpdateDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `UpdateDate` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.UpdateDate |
| 17 | `InsertDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InsertDate` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.InsertDate |
| 18 | `InstrumentDisplayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentDisplayName` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.InstrumentDisplayName |
| 19 | `Industry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Industry` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.Industry |
| 20 | `CompanyInfo` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `CompanyInfo` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.CompanyInfo |
| 21 | `Exchange` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Exchange` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.Exchange |
| 22 | `ISINCode` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ISINCode` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.ISINCode |
| 23 | `ISINCountryCode` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ISINCountryCode` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.ISINCountryCode |
| 24 | `Tradable` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Tradable` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.Tradable |
| 25 | `Symbol` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Symbol` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.Symbol |
| 26 | `ReceivedOnPriceServer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ReceivedOnPriceServer` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.ReceivedOnPriceServer |
| 27 | `BonusCreditUsePercent` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `BonusCreditUsePercent` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.BonusCreditUsePercent |
| 28 | `SymbolFull` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SymbolFull` | `passthrough` | (Tier 1 — Trade.InstrumentMetaData) | cc.SymbolFull |
| 29 | `CUSIP` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `CUSIP` | `passthrough` | (Tier 1 — Trade.InstrumentCusip) | cc.CUSIP |
| 30 | `Precision` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Precision` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.Precision |
| 31 | `AllowBuy` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `AllowBuy` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.AllowBuy |
| 32 | `AllowSell` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `AllowSell` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.AllowSell |
| 33 | `AssetClass` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `AssetClass` | `passthrough` | (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) | cc.AssetClass |
| 34 | `IndustryGroup` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IndustryGroup` | `passthrough` | (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) | cc.IndustryGroup |
| 35 | `ADV_Last3Months` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ADV_Last3Months` | `passthrough` | (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) | cc.ADV_Last3Months |
| 36 | `MKTcap` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `MKTcap` | `passthrough` | (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) | cc.MKTcap |
| 37 | `SharesOutStanding` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SharesOutStanding` | `passthrough` | (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) | cc.SharesOutStanding |
| 38 | `VisibleInternallyOnly` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `VisibleInternallyOnly` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.VisibleInternallyOnly |
| 39 | `PlatformSector` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `PlatformSector` | `passthrough` | (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) | cc.PlatformSector |
| 40 | `PlatformIndustry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `PlatformIndustry` | `passthrough` | (Tier 2 — SP_Dim_Instrument, Rankings.StockInfo) | cc.PlatformIndustry |
| 41 | `IsFuture` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `IsFuture` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cc.IsFuture |
| 42 | `Multiplier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Multiplier` | `passthrough` | (Tier 1 — Trade.FuturesMetaData) | cc.Multiplier |
| 43 | `ProviderID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ProviderID` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.ProviderID |
| 44 | `ProviderMarginPerLot` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ProviderMarginPerLot` | `passthrough` | (Tier 1 — Trade.FuturesInstrumentsInitialMarginByProviderMapping) | cc.ProviderMarginPerLot |
| 45 | `eToroMarginPerLot` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `eToroMarginPerLot` | `passthrough` | (Tier 1 — Trade.ProviderToInstrument) | cc.eToroMarginPerLot |
| 46 | `SettlementTime` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SettlementTime` | `passthrough` | (Tier 1 — Trade.FuturesMetaData) | cc.SettlementTime |
| 47 | `OperationMode` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `OperationMode` | `passthrough` | (Tier 1 — Trade.Instrument) | cc.OperationMode |
| 48 | `Tradeable` | `main.trading.bronze_etoro_trade_instrumentmetadata_daily / main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `—` | `case` | — | CASE WHEN cc.VisibleInternallyOnly = 0 AND cc.Tradable = 1 AND dd.InstrumentVisible = 1 THEN 1 ELSE 0 END AS Tradeable |
| 49 | `IsSQF` | `main.trading.bronze_etoro_trade_instrumentgroups` | `—` | `case` | — | CASE WHEN NOT etig.InstrumentID IS NULL THEN 1 ELSE 0 END AS IsSQF |
| 50 | `Is_245_Instrument` | `—` | `—` | `case` | — | CASE WHEN NOT i245.InstrumentID IS NULL THEN 1 ELSE 0 END AS Is_245_Instrument |

## Cross-check vs system.access.column_lineage

- Total target columns: **50**
- OK: **47**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Tradeable` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.tradable`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.visibleinternallyonly`, `main.trading.bronze_etoro_trade_instrumentmetadata.instrumentvisible`, `main.trading.bronze_etoro_trade_instrumentmetadata_daily.instrumentvisible` | ERROR |
| `IsSQF` | — | `main.trading.bronze_etoro_trade_instrumentgroups.instrumentid` | ERROR |
| `Is_245_Instrument` | — | `main.trading.bronze_etoro_trade_instrumentmetadata.instrumentid`, `main.trading.bronze_etoro_trade_instrumentmetadata_daily.instrumentid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER JOIN` — JOIN main.trading.bronze_etoro_trade_instrumentmetadata_daily AS dd ON cc.InstrumentID = dd.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.trading.bronze_etoro_trade_instrumentgroups AS etig ON cc.InstrumentID = etig.InstrumentID AND etig.GroupID = 59
- `LEFT JOIN` — LEFT JOIN instruments_245 AS i245 ON cc.InstrumentID = i245.InstrumentID
- `INNER JOIN` — JOIN main.trading.bronze_etoro_trade_providertoinstrument AS pti ON imd.InstrumentID = pti.InstrumentID
- `INNER JOIN` — JOIN main.trading.bronze_etoro_trade_providertoinstrument AS pti ON imd.InstrumentID = pti.InstrumentID
- `INNER JOIN` — JOIN rth_instruments AS rth ON rth.ISINCode = imd.ISINCode
