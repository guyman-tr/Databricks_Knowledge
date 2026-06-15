# Column Lineage: main.etoro_kpi.ddr_customer_current_flags

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ddr_customer_current_flags` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ddr_customer_current_flags.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ddr_customer_current_flags.json` (rows: 7, mismatches: 0) |
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
main.etoro_kpi.ddr_customer_current_flags   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `RealCID` | `cast` | — | cast to STRING — CAST(s.RealCID AS STRING) AS RealCID |
| 2 | `IsFunded` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsFunded` | `passthrough` | — | s.IsFunded |
| 3 | `IsActiveTrade` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `ActiveTraded` | `rename` | — | s.ActiveTraded AS IsActiveTrade |
| 4 | `BalanceOnly` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `BalanceOnlyAccount` | `rename` | — | s.BalanceOnlyAccount AS BalanceOnly |
| 5 | `PortfolioOnly` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `Portfolio_Only` | `cast` | — | cast to INT — CAST(s.Portfolio_Only AS INT) AS PortfolioOnly |
| 6 | `IsChurn` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsChurned` | `rename` | — | s.IsChurned AS IsChurn |
| 7 | `IsWinback` | `main.etoro_kpi_prep.gold_de_user_dim_ddr_customer_dailystatus_scd` | `IsWinBack` | `rename` | — | s.IsWinBack AS IsWinback |

## Cross-check vs system.access.column_lineage

- Total target columns: **7**
- OK: **7**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
