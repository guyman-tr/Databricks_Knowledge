# BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted --- Column Lineage

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|---|---|---|---|
| 1 | Price:12 Candles DB (AO-CANDLES-LSN) | Production Database | External data source | Confluence: Candle Builder service generates T_PriceCandle60Min candle data from incoming rates |
| 2 | BI_DB_Migration.BI_DB_SpreadedPriceCandle60MinSplitted | Migration staging table | Migration relay | SSDT: NoDbObjectsScripts migration DDL with varchar dates |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|---|---|---|---|---|
| 1 | ProviderID | Price:12 Candles DB | ProviderID | Passthrough (external load) | Tier 3 |
| 2 | InstrumentID | Price:12 Candles DB | InstrumentID | Passthrough (external load) | Tier 3 |
| 3 | DateFrom | Price:12 Candles DB | DateFrom | Passthrough (external load) | Tier 3 |
| 4 | DateTo | Price:12 Candles DB | DateTo | Passthrough (external load) | Tier 3 |
| 5 | AskFirst | Price:12 Candles DB | AskFirst | Passthrough (external load) | Tier 3 |
| 6 | AskLast | Price:12 Candles DB | AskLast | Passthrough (external load) | Tier 3 |
| 7 | AskMin | Price:12 Candles DB | AskMin | Passthrough (external load) | Tier 3 |
| 8 | AskMax | Price:12 Candles DB | AskMax | Passthrough (external load) | Tier 3 |
| 9 | BidFirst | Price:12 Candles DB | BidFirst | Passthrough (external load) | Tier 3 |
| 10 | BidLast | Price:12 Candles DB | BidLast | Passthrough (external load) | Tier 3 |
| 11 | BidMin | Price:12 Candles DB | BidMin | Passthrough (external load) | Tier 3 |
| 12 | BidMax | Price:12 Candles DB | BidMax | Passthrough (external load) | Tier 3 |
| 13 | AskFirstOccurred | Price:12 Candles DB | AskFirstOccurred | Passthrough (external load) | Tier 3 |
| 14 | AskLastOccurred | Price:12 Candles DB | AskLastOccurred | Passthrough (external load) | Tier 3 |
| 15 | AskMinOccurred | Price:12 Candles DB | AskMinOccurred | Passthrough (external load) | Tier 3 |
| 16 | AskMaxOccurred | Price:12 Candles DB | AskMaxOccurred | Passthrough (external load) | Tier 3 |
| 17 | BidFirstOccurred | Price:12 Candles DB | BidFirstOccurred | Passthrough (external load) | Tier 3 |
| 18 | BidLastOccurred | Price:12 Candles DB | BidLastOccurred | Passthrough (external load) | Tier 3 |
| 19 | BidMinOccurred | Price:12 Candles DB | BidMinOccurred | Passthrough (external load) | Tier 3 |
| 20 | BidMaxOccurred | Price:12 Candles DB | BidMaxOccurred | Passthrough (external load) | Tier 3 |
| 21 | UpdateDate | Price:12 Candles DB | UpdateDate | Passthrough (external load) | Tier 3 |

## Lineage Notes

- No writer stored procedure exists in Synapse for this table.
- Data was loaded via external migration from the production Candle Builder service (Price:12 / Candles DB on AO-CANDLES-LSN).
- A migration staging table `BI_DB_Migration.BI_DB_SpreadedPriceCandle60MinSplitted` with varchar date columns exists, suggesting CSV/bulk load pipeline.
- The `_no_upstream_found.txt` marker is present; no upstream wiki could be resolved.
- All columns are Tier 3: production source identified via Confluence but no upstream wiki documentation exists and no Synapse writer SP code is available for column-level tracing.
