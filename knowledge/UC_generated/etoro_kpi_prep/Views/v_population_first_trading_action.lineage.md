# Column Lineage: main.etoro_kpi_prep.v_population_first_trading_action

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_population_first_trading_action` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_population_first_trading_action.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_population_first_trading_action.json` (rows: 6, mismatches: 3) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Mirror.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CustomerAction.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_population_first_trading_action   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `PositionID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `InstrumentID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `Instrument` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `InstrumentTypeID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `InstrumentType` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `IsSettled` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `MirrorID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `Exchange` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `ISINCode` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `IsAirDrop` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `RN` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `IsCopyFund` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `FirstTradeDateID` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `Occurred` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 16 | `IsDepositor` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `IsDepositor` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.IsDepositor |
| 17 | `FirstDepositDate` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `FirstDepositDate` | `join_enriched` | (Tier 2 — SP_Dim_Customer) | dc.FirstDepositDate |
| 18 | `FirstTradeDate` | `—` | `Occurred` | `join_enriched` | — | a.Occurred AS FirstTradeDate |
| 19 | `FirstDepositDateID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(dc.FirstDepositDate AS DATE), 'yyyyMMdd') AS INT) AS FirstDepositDateID |
| 20 | `FirstActionType` | `—` | `—` | `case` | — | CASE WHEN a.InstrumentTypeID IN (1, 2, 4) THEN 'Forex' WHEN a.InstrumentTypeID = 10 THEN 'Crypto' WHEN a.MirrorID > 0 AND a.IsCopyFund = 0 T |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **3**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `FirstTradeDate` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.occurred` | ERROR |
| `FirstDepositDateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `FirstActionType` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.instrumenttypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror.mirrortypeid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction.mirrorid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **5**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON a.RealCID = dc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dp.InstrumentID = di.InstrumentID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror AS dm ON dp.MirrorID = dm.MirrorID AND dm.MirrorTypeID = 4
