# Column Lineage: main.etoro_kpi_prep.v_population_portfolio_only

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_portfolio_only` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_portfolio_only.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_portfolio_only.json` (rows: 21, mismatches: 20) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary` | JOIN / referenced | ✓ `knowledge\ProdSchemas\DB_Schema\Sodreconciliation\Wiki\apex\Tables\apex.EXT981_BuyPowerSummary.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.dim_position` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_Client_Balance_CID_Level_New.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.general.bronze_usabroker_apex_options` | JOIN / referenced | ✓ `knowledge\ProdSchemas\ComplianceDBs\USABroker\Wiki\apex\Tables\apex.Options.md` |
| `main.etoro_kpi_prep.v_population_active_traders` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_population_active_traders.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new   ←── primary upstream
  + main.dwh.dim_position   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.general.bronze_sodreconciliation_apex_ext981_buypowersummary   (JOIN)
  + main.general.bronze_usabroker_apex_options   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
  + main.etoro_kpi_prep.v_population_active_traders   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_portfolio_only   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `DateID` | `join_enriched` | — | f.DateID |
| 2 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | f.RealCID |
| 3 | `Portfolio_Only` | `—` | `—` | `literal` | — | literal `1` — 1 AS Portfolio_Only |
| 4 | `Portfolio_Only_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Manual |
| 5 | `Portfolio_Only_CFD_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END) AS Portfolio_Only_CFD_Manual |
| 6 | `Portfolio_Only_CryptoCFD_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS |
| 7 | `Portfolio_Only_CryptoReal_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS |
| 8 | `Portfolio_Only_StocksCFD_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS  |
| 9 | `Portfolio_Only_StocksReal_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS  |
| 10 | `Portfolio_Only_ETFCFD_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS  |
| 11 | `Portfolio_Only_ETFReal_Manual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) = 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS  |
| 12 | `Portfolio_Only_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Copy |
| 13 | `Portfolio_Only_CFD_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (1, 2, 4) THEN 1 ELSE 0 END) AS Portfolio_Only_CFD_Copy |
| 14 | `Portfolio_Only_CryptoCFD_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS |
| 15 | `Portfolio_Only_CryptoReal_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (10) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS |
| 16 | `Portfolio_Only_StocksCFD_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS  |
| 17 | `Portfolio_Only_StocksReal_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (5) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS  |
| 18 | `Portfolio_Only_ETFCFD_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 0 THEN 1 ELSE 0 END) AS  |
| 19 | `Portfolio_Only_ETFReal_Copy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.InstrumentTypeID, 0) IN (6) AND COALESCE(f.IsSettled, 0) = 1 THEN 1 ELSE 0 END) AS  |
| 20 | `Portfolio_Only_CopyFund` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.MirrorID, 0) > 0 AND COALESCE(f.IsCopyFund, 0) = 1 THEN 1 ELSE 0 END) AS Portfolio_Only_CopyFund |
| 21 | `Portfolio_Only_Options` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN COALESCE(f.PositionMarketValue, 0) > 0 THEN 1 ELSE 0 END) AS Portfolio_Only_Options |

## Cross-check vs system.access.column_lineage

- Total target columns: **21**
- OK: **1**, WARN: **0**, ERROR: **20**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new.dateid`, `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.processdate` | ERROR |
| `RealCID` | — | `main.dwh.dim_position.cid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.realcid` | ERROR |
| `Portfolio_Only_Manual` | — | `main.dwh.dim_position.mirrorid` | ERROR |
| `Portfolio_Only_CFD_Manual` | — | `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_CryptoCFD_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_CryptoReal_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_StocksCFD_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_StocksReal_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_ETFCFD_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_ETFReal_Manual` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_Copy` | — | `main.dwh.dim_position.mirrorid` | ERROR |
| `Portfolio_Only_CFD_Copy` | — | `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_CryptoCFD_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_CryptoReal_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_StocksCFD_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_StocksReal_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_ETFCFD_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_ETFReal_Copy` | — | `main.dwh.dim_position.issettled`, `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid` | ERROR |
| `Portfolio_Only_CopyFund` | — | `main.dwh.dim_position.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrorid` | ERROR |
| `Portfolio_Only_Options` | — | `main.general.bronze_sodreconciliation_apex_ext981_buypowersummary.positionmarketvalue` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **21**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.dim_position AS dp ON COALESCE(dp.IsAirDrop, 0) = 0 AND dp.OpenDateID <= bs.DateID AND (dp.CloseDateID >= bs.DateID OR dp.CloseDateID = 0)
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN (SELECT MirrorID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror WHERE MirrorTypeID = 4) AS dm ON dp.MirrorID = dm.MirrorID
- `INNER INNER` — INNER JOIN main.general.bronze_usabroker_apex_options AS op ON bps.AccountNumber = op.OptionsApexID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON op.GCID = dc.GCID
- `FULL OUTER` — FULL OUTER JOIN options_aum AS oa ON h.DateID = oa.DateID AND h.RealCID = oa.RealCID
