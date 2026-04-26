# BI_DB_Daily_TradeData — Column Lineage

**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_Daily_TradeData  
**Generated**: 2026-04-22

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | Date | SP_Daily_TradeData | @dd parameter | passthrough | Tier 2 |
| 2 | DateID | SP_Daily_TradeData | @dd | CONVERT(CHAR(8), @dd, 112) → int | Tier 2 |
| 3 | Region | DWH_dbo.Dim_Country | Region | passthrough (via Dim_Customer.CountryID JOIN) | Tier 2 |
| 4 | Country | DWH_dbo.Dim_Country | Name | passthrough (via Dim_Customer.CountryID JOIN) | Tier 1 |
| 5 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | passthrough | Tier 2 |
| 6 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | passthrough | Tier 2 |
| 7 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough (from Fact_CurrencyPriceWithSplit.InstrumentID) | Tier 1 |
| 8 | EOD_Price | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | MAX(Bid) WHERE OccurredDateID=@ddINT | Tier 2 |
| 9 | OpenedPositions | DWH_dbo.Dim_Position | PositionID | COUNT(*) WHERE OpenDateID=@ddINT AND MirrorID=0 AND IsDepositor=1 | Tier 2 |
| 10 | UsersOpen | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) for positions opened on @dd | Tier 2 |
| 11 | OpenPositions | BI_DB_dbo.BI_DB_PositionPnL | PositionID | COUNT(*) WHERE DateID=@ddINT (EOD branch) | Tier 2 |
| 12 | UsersHold | BI_DB_dbo.BI_DB_PositionPnL | CID | COUNT(DISTINCT CID) for positions held at EOD on @dd | Tier 2 |
| 13 | UpdateDate | SP_Daily_TradeData | — | GETDATE() at INSERT time | Tier 2 |

---

## ETL Pipeline

```
etoro.Trade (Dim_Position, Dim_Customer, Dim_Instrument, Dim_Country)
  |-- DWH_dbo dimensions (already in Synapse) --|
  v
DWH_dbo.Dim_Position / Dim_Customer / Dim_Instrument / Dim_Country / Fact_CurrencyPriceWithSplit
  + BI_DB_dbo.BI_DB_PositionPnL
  |-- SP_Daily_TradeData @dd (DELETE+INSERT daily) --|
  v
BI_DB_dbo.BI_DB_Daily_TradeData (409.6M rows, 2019–2026)
  |-- UC: Not Migrated --|
```

---

## Source Objects

| Source Schema | Source Object | Role |
|---|---|---|
| DWH_dbo | Dim_Customer | Customer filtering (IsValidCustomer=1, IsDepositor=1, CountryID→Region/Country) |
| DWH_dbo | Dim_Position | Positions opened on @dd (Open branch) |
| DWH_dbo | Dim_Instrument | InstrumentType, InstrumentDisplayName, InstrumentID |
| DWH_dbo | Dim_Country | Region, Country name (via Dim_Customer.CountryID) |
| DWH_dbo | Fact_CurrencyPriceWithSplit | EOD_Price (MAX Bid per instrument on @dd); drives the final INSERT grain |
| BI_DB_dbo | BI_DB_PositionPnL | Positions held at EOD on @dd (EOD branch — provides OpenPositions/UsersHold) |

---

## UC External Lineage

UC Target: **Not Migrated** — no UC entry exists for this table.
