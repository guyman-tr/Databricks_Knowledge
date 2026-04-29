# Lineage: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

## Source Objects

| # | Source Object | Type | Schema | Database | Relationship |
|---|---------------|------|--------|----------|--------------|
| 1 | Unknown (static / manual load) | Unknown | — | — | No writer SP found; table loaded as a one-time bulk insert on 2022-11-21 |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|---------------|---------------|-----------|------|
| 1 | Currency | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 2 | CurrencyISO | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 3 | InstrumentID | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 4 | InstrumentName | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 5 | DWHInstrumentID | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 6 | BuyCurrencyID | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 7 | SellCurrencyID | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 8 | BuyCurrency | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 9 | SellCurrency | Unknown (static load) | — | None — manually loaded static data | Tier 3 |
| 10 | UpdateDate | Unknown (static load) | — | None — manually loaded static data | Tier 3 |

## Reader SPs (consume this table)

| # | SP Name | Schema | Join Pattern | Columns Used |
|---|---------|--------|-------------- |--------------|
| 1 | SP_eMoney_Dim_Account | eMoney_dbo | `CurrencyBalanceISON = CurrencyISO AND SellCurrencyID = 1` | Currency (as CurrencyBalanceISODesc) |
| 2 | SP_eMoney_Snapshot_Settled_Balance | eMoney_dbo | `CurrencyBalanceISOCode = CurrencyISO AND SellCurrencyID = 1` | InstrumentID (for Fact_CurrencyPriceWithSplit rate lookup) |
| 3 | SP_eMoney_Calculated_Balance | eMoney_dbo | `CurrencyISOCode = CurrencyISO AND SellCurrencyID = 1` | InstrumentID (for Fact_CurrencyPriceWithSplit rate lookup) |
| 4 | SP_DDR_Fact_MIMO_eMoney_Platform | BI_DB_dbo | `HolderCurrencyISO = CurrencyISO` (subquery: `BuyCurrencyID = 1`) | Currency, CurrencyISO, SellCurrencyID |
