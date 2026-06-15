# Column Lineage: main.etoro_kpi.vg_dealing_clicks_openclose_breakdown

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_dealing_clicks_openclose_breakdown` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_dealing_clicks_openclose_breakdown.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_dealing_clicks_openclose_breakdown.json` (rows: 47, mismatches: 1) |
| **Primary upstream** | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Clicks_OpenClose_Breakdown.md` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

## Lineage Chain

```
main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   (JOIN)
        │
        ▼
main.etoro_kpi.vg_dealing_clicks_openclose_breakdown   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Date` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Date |
| 2 | `DateID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `DateID` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.DateID |
| 3 | `SellCurrency` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `SellCurrency` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cbd.SellCurrency |
| 4 | `Club` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Club` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Club |
| 5 | `CID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `CID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | cbd.CID |
| 6 | `IsBuy` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsBuy` | `passthrough` | (Tier 1 — Trade.PositionTbl) | cbd.IsBuy |
| 7 | `HeldOnReportDate` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `HeldOnReportDate` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.HeldOnReportDate |
| 8 | `HedgeServerID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `HedgeServerID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | cbd.HedgeServerID |
| 9 | `InstrumentID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InstrumentID` | `passthrough` | (Tier 1 — Trade.PositionTbl) | cbd.InstrumentID |
| 10 | `InstrumentDisplayName` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InstrumentDisplayName` | `passthrough` | (Tier 2 — SP_Dim_Instrument, etoro_Trade_InstrumentMetaData) | cbd.InstrumentDisplayName |
| 11 | `InstrumentName` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InstrumentName` | `passthrough` | (Tier 3 — live data, etoro.Trade.GetInstrument) | cbd.InstrumentName |
| 12 | `InstrumentTypeID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InstrumentTypeID` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cbd.InstrumentTypeID |
| 13 | `InstrumentType` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InstrumentType` | `passthrough` | (Tier 2 — SP_Dim_Instrument) | cbd.InstrumentType |
| 14 | `IsCopy` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsCopy` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsCopy |
| 15 | `IsCFD` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsCFD` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsCFD |
| 16 | `Symbol` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Symbol` | `passthrough` | (Tier 3 — live data, etoro.Trade.GetInstrument) | cbd.Symbol |
| 17 | `Leverage` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Leverage` | `passthrough` | (Tier 1 — Trade.PositionTbl) | cbd.Leverage |
| 18 | `Exchange` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Exchange` | `passthrough` | (Tier 3 — live data, etoro_Trade_InstrumentMetaData) | cbd.Exchange |
| 19 | `CountryID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `CountryID` | `passthrough` | (Tier 1 — Dictionary.Country upstream wiki) | cbd.CountryID |
| 20 | `Country` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Country` | `passthrough` | (Tier 1 — Dictionary.Country upstream wiki) | cbd.Country |
| 21 | `Region` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Region` | `passthrough` | (Tier 3 — Ext_Dim_Country live data) | cbd.Region |
| 22 | `RegulationID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `RegulationID` | `passthrough` | (Tier 2 — SP_Fact_SnapshotCustomer) | cbd.RegulationID |
| 23 | `Regulation` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Regulation` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Regulation |
| 24 | `IsIslamic` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsIslamic` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsIslamic |
| 25 | `Size_of_Tickets` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Size_of_Tickets` | `passthrough` | — | cbd.Size_of_Tickets |
| 26 | `OpenOrClose` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `OpenOrClose` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.OpenOrClose |
| 27 | `OpenOrCloseID` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `OpenOrCloseID` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.OpenOrCloseID |
| 28 | `Click` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Click` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Click |
| 29 | `Volume` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Volume` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Volume |
| 30 | `Units` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `Units` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.Units |
| 31 | `FullCommission` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `FullCommission` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.FullCommission |
| 32 | `InitialAmountUSDOnOpen` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `InitialAmountUSDOnOpen` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.InitialAmountUSDOnOpen |
| 33 | `UpdateDate` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `UpdateDate` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.UpdateDate |
| 34 | `IsPI` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsPI` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsPI |
| 35 | `IsTicketFee` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsTicketFee` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsTicketFee |
| 36 | `TicketFee` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `—` | `arithmetic` | — | -1 * cbd.TicketFee AS TicketFee |
| 37 | `IsAirDrop` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsAirDrop` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsAirDrop |
| 38 | `IsFuture` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsFuture` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsFuture |
| 39 | `etr_y` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `etr_y` | `passthrough` | — | cbd.etr_y |
| 40 | `etr_ym` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `etr_ym` | `passthrough` | — | cbd.etr_ym |
| 41 | `etr_ymd` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `etr_ymd` | `passthrough` | — | cbd.etr_ymd |
| 42 | `HaseMoneyAccount` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `HaseMoneyAccount` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.HaseMoneyAccount |
| 43 | `IsIBANClick` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsIBANClick` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsIBANClick |
| 44 | `IsFTDClick` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsFTDClick` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsFTDClick |
| 45 | `IsLowTouch` | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | `IsLowTouch` | `passthrough` | (Tier 2 — SP_Clicks_OpenClose_Breakdown) | cbd.IsLowTouch |
| 46 | `Multiplier` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Multiplier` | `join_enriched` | (Tier 1 — Trade.FuturesMetaData) | di.Multiplier |
| 47 | `Manager` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | `Manager` | `join_enriched` | — | cfd.Manager |

## Cross-check vs system.access.column_lineage

- Total target columns: **47**
- OK: **46**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `TicketFee` | — | `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown.ticketfee` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON cbd.InstrumentID = di.InstrumentID
- `INNER JOIN` — JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked AS cfd ON cbd.CID = cfd.CID
