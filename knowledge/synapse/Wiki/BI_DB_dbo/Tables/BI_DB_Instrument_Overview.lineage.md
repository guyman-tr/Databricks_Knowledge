# BI_DB_dbo.BI_DB_Instrument_Overview — Column Lineage

## Source Systems

| Source | Type | Description |
|--------|------|-------------|
| DWH_dbo.Dim_Instrument | DWH Dimension | Instrument master — attributes, IDs, exchange info |
| DWH_dbo.Dim_Position | DWH Dimension | Position-level trading data |
| BI_DB_dbo.BI_DB_First5Actions | BI_DB Table | First 5 actions per CID |
| BI_DB_dbo.BI_DB_DailyCommisionReport | BI_DB Table | Daily commission + rollover fee |
| DWH_watchlists.Fact_WatchlistsItems | DWH Fact | Watchlist add/delete events |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| DWHInstrumentID | Dim_Instrument | DWHInstrumentID | Passthrough (filtered >0) |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | Passthrough |
| InstrumentType | Dim_Instrument | InstrumentType | Passthrough |
| InstrumentName | Dim_Instrument | Name | Renamed from Name to InstrumentName |
| BuyCurrencyID | Dim_Instrument | BuyCurrencyID | Passthrough |
| SellCurrencyID | Dim_Instrument | SellCurrencyID | Passthrough |
| BuyCurrency | Dim_Instrument | BuyCurrency | Passthrough |
| SellCurrency | Dim_Instrument | SellCurrency | Passthrough |
| IsMajorID | Dim_Instrument | IsMajorID | Passthrough |
| InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Passthrough |
| Exchange | Dim_Instrument | Exchange | Passthrough |
| ISINCode | Dim_Instrument | ISINCode | Passthrough |
| Tradable | Dim_Instrument | Tradable | Passthrough (varchar in DDL) |
| Symbol | Dim_Instrument | Symbol | Passthrough |
| AddedToServerDate | Dim_Instrument | ReceivedOnPriceServer | CAST to DATE |
| CUSIP | Dim_Instrument | CUSIP | Passthrough |
| UniqueTraders | Dim_Position | CID | COUNT(DISTINCT CID) for positions opened on date/month |
| Positions | Dim_Position | PositionID | COUNT for positions opened on date/month |
| OpenedVolume | Dim_Position | Volume | SUM(CAST Volume AS bigint) |
| InvestedAmount | Dim_Position | InitialAmountCents | SUM(InitialAmountCents/100) |
| Average_Traded_Leverage | Dim_Position | Leverage | AVG(Leverage) |
| Long_Transactions | Dim_Position | IsBuy | SUM(CAST IsBuy AS int) — count of long positions |
| FirstActions | BI_DB_First5Actions | CID | COUNT where FirstInstrument matches |
| Revenue | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM(FullCommissions + RollOverFee) |
| NewAddedToWhatchlist | Fact_WatchlistsItems | IsDeleted | SUM(CASE IsDeleted=0 THEN 1) |
| DeletedFromWatchList | Fact_WatchlistsItems | IsDeleted | SUM(IsDeleted) |
| Date | — | — | @Date parameter |
| Periodind | — | — | 'Daily Data' or 'Monthly Data' literal |
| UpdateDate | — | — | GETDATE() |
| Leveraged_Volume | Dim_Position | Volume, Leverage | SUM(Volume WHERE Leverage>1) |
| Leveraged_Positions | Dim_Position | Leverage | COUNT WHERE Leverage>1 |
| Real_Volume | Dim_Position | Volume, IsSettled | SUM(Volume WHERE IsSettled>0) |
| Real_Positions | Dim_Position | IsSettled | COUNT WHERE IsSettled>0 |
| NewManualAddedToWhatchlist | Fact_WatchlistsItems | IsDeleted, ItemAddedReason | SUM(CASE IsDeleted=0 AND ItemAddedReason='Manual') |
| DeletedManualFromWatchList | Fact_WatchlistsItems | IsDeleted, ItemAddedReason | SUM(CASE ItemAddedReason='Manual' THEN IsDeleted) |

## Pipeline

```
DWH_dbo.Dim_Instrument (instrument attributes, >15K instruments)
  + DWH_dbo.Dim_Position (positions opened on date, filtered IsPartialCloseChild=0)
  + BI_DB_dbo.BI_DB_First5Actions (first actions per CID)
  + BI_DB_dbo.BI_DB_DailyCommisionReport (commission + rollover)
  + DWH_watchlists.Fact_WatchlistsItems (watchlist ItemType='Instrument')
    |-- SP_Instrument_Overview @Date (daily delete-insert + monthly on EOM) --|
    |   Aggregate: per-instrument trading/revenue/watchlist metrics            |
    |   Dual rows: 'Daily Data' + 'Monthly Data' (EOM only)                  |
    |   Auto-purge: DELETE WHERE Date < 7 months ago                          |
    v
BI_DB_dbo.BI_DB_Instrument_Overview (3.19M rows, 7-month rolling window)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```
