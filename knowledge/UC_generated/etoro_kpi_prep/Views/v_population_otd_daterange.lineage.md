# Column Lineage: main.etoro_kpi_prep.v_population_otd_daterange

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_otd_daterange` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_otd_daterange.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_otd_daterange.json` (rows: 3, mismatches: 3) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Fact_Transaction_Status.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_otd_daterange   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `—` | `RealCID` | `passthrough` | — | RealCID |
| 2 | `FromDateID` | `—` | `—` | `aggregate` | — | MIN(DateID) AS FromDateID |
| 3 | `ToDateID` | `—` | `—` | `case` | — | CASE WHEN MIN(TotalRows) = 1 THEN CAST(DATE_FORMAT(CURRENT_DATE, 'yyyyMMdd') AS INT) WHEN MIN(CountDeposits) > 1 THEN MIN(DateID) ELSE COALE |

## Cross-check vs system.access.column_lineage

- Total target columns: **3**
- OK: **0**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.cid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.realcid` | ERROR |
| `FromDateID` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.dateid` | ERROR |
| `ToDateID` | — | `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.cid`, `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status.txstatusmodificationdateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.dateid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.realcid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
