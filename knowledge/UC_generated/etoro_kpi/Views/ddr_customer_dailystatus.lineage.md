# Column Lineage: main.etoro_kpi.ddr_customer_dailystatus

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_customer_dailystatus` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_customer_dailystatus.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_customer_dailystatus.json` (rows: 9, mismatches: 0) |
| **Primary upstream** | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | Primary (FROM) | ✗ `knowledge/UC_generated/etoro_kpi_prep/<Tables|Views>/gold_de_user_dim_ddr_customer_dailystatus_scd.md` |

## Lineage Chain

```
main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd   ←── primary upstream
        │
        ▼
main.etoro_kpi.ddr_customer_dailystatus   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `RealCID` | `cast` | — | cast to STRING — CAST(s.RealCID AS STRING) AS RealCID |
| 2 | `FromDateID` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `FromDateID` | `passthrough` | — | s.FromDateID |
| 3 | `ToDateID` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `ToDateID` | `passthrough` | — | s.ToDateID |
| 4 | `IsFunded` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsFunded` | `passthrough` | — | s.IsFunded |
| 5 | `IsActiveTrade` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `ActiveTraded` | `rename` | — | s.ActiveTraded AS IsActiveTrade |
| 6 | `BalanceOnly` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `BalanceOnlyAccount` | `rename` | — | s.BalanceOnlyAccount AS BalanceOnly |
| 7 | `PortfolioOnly` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `Portfolio_Only` | `cast` | — | cast to INT — CAST(s.Portfolio_Only AS INT) AS PortfolioOnly |
| 8 | `IsChurn` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsChurned` | `rename` | — | s.IsChurned AS IsChurn |
| 9 | `IsWinback` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsWinBack` | `rename` | — | s.IsWinBack AS IsWinback |

## Cross-check vs system.access.column_lineage

- Total target columns: **9**
- OK: **9**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
