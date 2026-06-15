# Column Lineage: main.etoro_kpi.positions_for_compliance_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.positions_for_compliance_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\positions_for_compliance_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\positions_for_compliance_v.json` (rows: 53, mismatches: 1) |
| **Primary upstream** | `main.dwh.dim_position` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CIDFirstDates.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_ClosePositionReason.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.dwh.dim_position   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked   (JOIN)
        │
        ▼
main.etoro_kpi.positions_for_compliance_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `positionid` | `main.dwh.dim_position` | `positionid` | `passthrough` | — | dp.positionid |
| 2 | `cid` | `main.dwh.dim_position` | `cid` | `passthrough` | — | dp.cid |
| 3 | `instrumentid` | `main.dwh.dim_position` | `instrumentid` | `passthrough` | — | dp.instrumentid |
| 4 | `amount` | `main.dwh.dim_position` | `amount` | `passthrough` | — | dp.amount |
| 5 | `InitialAmount` | `main.dwh.dim_position` | `—` | `arithmetic` | — | dp.initialamountcents / 100 AS InitialAmount |
| 6 | `hedgeserverid` | `main.dwh.dim_position` | `hedgeserverid` | `passthrough` | — | dp.hedgeserverid |
| 7 | `leverage` | `main.dwh.dim_position` | `leverage` | `passthrough` | — | dp.leverage |
| 8 | `isbuy` | `main.dwh.dim_position` | `isbuy` | `passthrough` | — | dp.isbuy |
| 9 | `openoccurred` | `main.dwh.dim_position` | `openoccurred` | `passthrough` | — | dp.openoccurred |
| 10 | `closeoccurred` | `main.dwh.dim_position` | `closeoccurred` | `passthrough` | — | dp.closeoccurred |
| 11 | `parentpositionid` | `main.dwh.dim_position` | `parentpositionid` | `passthrough` | — | dp.parentpositionid |
| 12 | `origparentpositionid` | `main.dwh.dim_position` | `origparentpositionid` | `passthrough` | — | dp.origparentpositionid |
| 13 | `mirrorid` | `main.dwh.dim_position` | `mirrorid` | `passthrough` | — | dp.mirrorid |
| 14 | `isopenopen` | `main.dwh.dim_position` | `isopenopen` | `passthrough` | — | dp.isopenopen |
| 15 | `opendateid` | `main.dwh.dim_position` | `opendateid` | `passthrough` | — | dp.opendateid |
| 16 | `closedateid` | `main.dwh.dim_position` | `closedateid` | `passthrough` | — | dp.closedateid |
| 17 | `volume` | `main.dwh.dim_position` | `volume` | `passthrough` | — | dp.volume |
| 18 | `regulationidonopen` | `main.dwh.dim_position` | `regulationidonopen` | `passthrough` | — | dp.regulationidonopen |
| 19 | `treeid` | `main.dwh.dim_position` | `treeid` | `passthrough` | — | dp.treeid |
| 20 | `initialunits` | `main.dwh.dim_position` | `initialunits` | `passthrough` | — | dp.initialunits |
| 21 | `Units` | `main.dwh.dim_position` | `amountinunitsdecimal` | `rename` | — | dp.amountinunitsdecimal AS Units |
| 22 | `isdiscounted` | `main.dwh.dim_position` | `isdiscounted` | `passthrough` | — | dp.isdiscounted |
| 23 | `issettled` | `main.dwh.dim_position` | `issettled` | `passthrough` | — | dp.issettled |
| 24 | `issettledonopen` | `main.dwh.dim_position` | `issettledonopen` | `passthrough` | — | dp.issettledonopen |
| 25 | `volumeonclose` | `main.dwh.dim_position` | `volumeonclose` | `passthrough` | — | dp.volumeonclose |
| 26 | `isairdrop` | `main.dwh.dim_position` | `isairdrop` | `passthrough` | — | dp.isairdrop |
| 27 | `inithedgetype` | `main.dwh.dim_position` | `inithedgetype` | `passthrough` | — | dp.inithedgetype |
| 28 | `endhedgetype` | `main.dwh.dim_position` | `endhedgetype` | `passthrough` | — | dp.endhedgetype |
| 29 | `orderid` | `main.dwh.dim_position` | `orderid` | `passthrough` | — | dp.orderid |
| 30 | `closepositionreasonid` | `main.dwh.dim_position` | `closepositionreasonid` | `passthrough` | — | dp.closepositionreasonid |
| 31 | `instrumenttypeid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `instrumenttypeid` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.instrumenttypeid |
| 32 | `instrumenttype` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `instrumenttype` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.instrumenttype |
| 33 | `Instrument` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `NAME` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.NAME AS Instrument |
| 34 | `buycurrencyid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `buycurrencyid` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.buycurrencyid |
| 35 | `sellcurrencyid` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `sellcurrencyid` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.sellcurrencyid |
| 36 | `buycurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `buycurrency` | `join_enriched` | (Tier 1 — Dictionary.Currency) | di.buycurrency |
| 37 | `sellcurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `sellcurrency` | `join_enriched` | (Tier 1 — Dictionary.Currency) | di.sellcurrency |
| 38 | `ismajor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `ismajor` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.ismajor |
| 39 | `instrumentdisplayname` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `instrumentdisplayname` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.instrumentdisplayname |
| 40 | `industry` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `industry` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.industry |
| 41 | `exchange` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `exchange` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.exchange |
| 42 | `isincode` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `isincode` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.isincode |
| 43 | `isincountrycode` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `isincountrycode` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.isincountrycode |
| 44 | `tradable` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `tradable` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.tradable |
| 45 | `symbol` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `symbol` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.symbol |
| 46 | `symbolfull` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `symbolfull` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | di.symbolfull |
| 47 | `cusip` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `cusip` | `join_enriched` | (Tier 1 — Trade.InstrumentCusip) | di.cusip |
| 48 | `isfuture` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `isfuture` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | di.isfuture |
| 49 | `ClosePositionReason` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason` | `NAME` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.ClosePositionActionType) | dcpr.NAME AS ClosePositionReason |
| 50 | `ispartialclosechild` | `main.dwh.dim_position` | `ispartialclosechild` | `passthrough` | — | dp.ispartialclosechild |
| 51 | `ispartialcloseparent` | `main.dwh.dim_position` | `ispartialcloseparent` | `passthrough` | — | dp.ispartialcloseparent |
| 52 | `netprofit` | `main.dwh.dim_position` | `netprofit` | `passthrough` | — | dp.netprofit |
| 53 | `pnlindollars` | `main.dwh.dim_position` | `pnlindollars` | `passthrough` | — | dp.pnlindollars |

## Cross-check vs system.access.column_lineage

- Total target columns: **53**
- OK: **52**, WARN: **0**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `InitialAmount` | — | `main.dwh.dim_position.initialamountcents` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **20**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.instrumentid = di.instrumentid
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason AS dcpr ON dp.closepositionreasonid = dcpr.closepositionreasonid
- `LEFT JOIN` — LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked AS cfm ON dp.cid = cfm.cid
