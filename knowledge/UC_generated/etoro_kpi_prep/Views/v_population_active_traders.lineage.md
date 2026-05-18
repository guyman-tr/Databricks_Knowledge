# Column Lineage: main.etoro_kpi_prep.v_population_active_traders

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_active_traders` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_active_traders.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_active_traders.json` (rows: 15, mismatches: 14) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.etoro_kpi_prep.v_revenue_optionsplatform` | JOIN / referenced | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/v_revenue_optionsplatform.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.etoro_kpi_prep.v_revenue_optionsplatform   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_active_traders   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `GCID` | `—` | `GCID` | `passthrough` | — | f.GCID |
| 2 | `RealCID` | `—` | `RealCID` | `passthrough` | — | f.RealCID |
| 3 | `DateID` | `—` | `DateID` | `passthrough` | — | f.DateID |
| 4 | `ActiveTraded` | `—` | `—` | `literal` | — | literal `1` — 1 AS ActiveTraded |
| 5 | `ActiveTradedManual` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 THEN 1 ELSE 0 END) AS ActiveTradedManual |
| 6 | `ActiveTradedCFD` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (1, 2, 4) THEN 1 ELSE 0 END) AS ActiveTradedCFD |
| 7 | `ActiveTradedCryptoCFD` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (10) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedCryptoCFD |
| 8 | `ActiveTradedCryptoReal` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (10) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedCryptoReal |
| 9 | `ActiveTradedStocksCFD` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (5) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedStocksCFD |
| 10 | `ActiveTradedStocksReal` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (5) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedStocksReal |
| 11 | `ActiveTradedETFCFD` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (6) AND f.IsSettled = 0 THEN 1 ELSE 0 END) AS ActiveTradedETFCFD |
| 12 | `ActiveTradedETFReal` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID = 0 AND f.InstrumentTypeID IN (6) AND f.IsSettled = 1 THEN 1 ELSE 0 END) AS ActiveTradedETFReal |
| 13 | `ActiveTradedCopy` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID > 0 AND f.ActionTypeID IN (15, 17) THEN 1 ELSE 0 END) AS ActiveTradedCopy |
| 14 | `ActiveTradedCopyFund` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.MirrorID > 0 AND f.ActionTypeID IN (15, 17) AND f.IsCopyFund = 1 THEN 1 ELSE 0 END) AS ActiveTradedCopyFund |
| 15 | `ActiveTradedOptions` | `—` | `—` | `aggregate` | — | MAX(CASE WHEN f.InstrumentTypeID = 9 THEN 1 ELSE 0 END) AS ActiveTradedOptions |

## Cross-check vs system.access.column_lineage

- Total target columns: **15**
- OK: **1**, WARN: **0**, ERROR: **14**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `GCID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.gcid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.gcid` | ERROR |
| `RealCID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.realcid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.realcid` | ERROR |
| `DateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.dateid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.dateid` | ERROR |
| `ActiveTradedManual` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid` | ERROR |
| `ActiveTradedCFD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid` | ERROR |
| `ActiveTradedCryptoCFD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedCryptoReal` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedStocksCFD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedStocksReal` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedETFCFD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedETFReal` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.issettled`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.issettled` | ERROR |
| `ActiveTradedCopy` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.actiontypeid` | ERROR |
| `ActiveTradedCopyFund` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrorid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.actiontypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.actiontypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.iscopyfund` | ERROR |
| `ActiveTradedOptions` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.etoro_kpi_prep.v_revenue_optionsplatform.instrumenttypeid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **12**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON fca.RealCID = fsc.RealCID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON fca.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN (SELECT MirrorID FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror WHERE MirrorTypeID = 4) AS dm ON fca.MirrorID = dm.MirrorID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON frop.RealCID = dc.RealCID
