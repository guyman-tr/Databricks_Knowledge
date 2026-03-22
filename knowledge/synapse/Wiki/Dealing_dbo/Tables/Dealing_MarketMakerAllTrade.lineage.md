# Column Lineage: Dealing_dbo.Dealing_MarketMakerAllTrade

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_MarketMakerAllTrade` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `MarketMaker.dbo.HedgeTrades` (production) |
| **ETL SP** | `SP_MarketMakerAllTrade` |
| **Secondary Sources** | `MarketMaker.dbo.Instruments`, `MarketMaker.dbo.Exchanges` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
MarketMaker.dbo.HedgeTrades ──────┐
MarketMaker.dbo.Instruments ──────┼──► CopyFromLake / Dealing_staging ──► SP_MarketMakerAllTrade ──► Dealing_MarketMakerAllTrade
MarketMaker.dbo.Exchanges ────────┘
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter |
| Id | HedgeTrades | Id | passthrough | Trade ID |
| ExecutionTime | HedgeTrades | ExecutionTime | passthrough | — |
| Instrument_Name | Instruments | Name | join-enriched | Via InstrumentId |
| Name | Exchanges | Name | join-enriched | Exchange name via ExchangeId |
| Side | HedgeTrades | Side | ETL-computed | `CASE WHEN Side=1 THEN 'Sell' WHEN Side=0 THEN 'Buy'` |
| Price | HedgeTrades | ApiPrice | rename | Reported as "Price" |
| Quantity | HedgeTrades | ApiQuantity | rename | Reported as "Quantity" |
| Funds | HedgeTrades | ApiPrice, ApiQuantity | ETL-computed | `ApiPrice * ApiQuantity` |
| ApiPrice | HedgeTrades | ExecutedPrice | ETL-computed | 0 when same as ApiPrice, else ExecutedPrice |
| APiQuantity | HedgeTrades | ExecutedQuantity | ETL-computed | 0 when same as ApiQuantity, else ExecutedQuantity |
| ApiFunds | HedgeTrades | ExecutedPrice, ExecutedQuantity | ETL-computed | 0 when same as Api funds, else Executed price*qty |
| Fee | HedgeTrades | Fee | ETL-computed | 0 when Fee=-1, else Fee |
| FeeCurrency | HedgeTrades | FeeCurrency | passthrough | — |
| PartyName | HedgeTrades | PartyName | passthrough | — |
| InsertTime | HedgeTrades | InsertTime | passthrough | — |
| OrderId | HedgeTrades | OrderId | passthrough | — |
| Unit | HedgeTrades | ApiQuantity, ExecutedQuantity | ETL-computed | Signed units: negative for Sell, positive for Buy |
| Value | — | — | ETL-computed | `Unit * -1 * Price - Fee` (when USD) or `Unit * -1 * Price` (non-USD fee) |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| DIFF | — | — | ETL-computed | 'X'=price/qty diff, 'DB'=dealer override, 'API'=API-only |
| Dealer | HedgeTrades | User | rename | Trade executor |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 3 |
| **ETL-computed** | 12 |
| **Join-enriched** | 2 |
| **Total** | 22 |
