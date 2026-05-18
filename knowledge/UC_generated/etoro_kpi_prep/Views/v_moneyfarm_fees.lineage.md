# Column Lineage: main.etoro_kpi_prep.v_moneyfarm_fees

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_moneyfarm_fees` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_moneyfarm_fees.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_moneyfarm_fees.json` (rows: 5, mismatches: 0) |
| **Primary upstream** | `main.etoro_kpi_prep.v_moneyfarm_fees` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|

## Lineage Chain

```
main.etoro_kpi_prep.v_moneyfarm_fees   ←── primary upstream
        │
        ▼
main.etoro_kpi_prep.v_moneyfarm_fees   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `—` | `unknown` | — | CAST(NULL AS DATE) AS date /* this is currently a placeholder, no fee logic exists yet */ |
| 2 | `dateid` | `—` | `—` | `unknown` | — | CAST(NULL AS INT) AS dateid |
| 3 | `gcid` | `—` | `—` | `unknown` | — | CAST(NULL AS BIGINT) AS gcid |
| 4 | `total_fees_gbp` | `—` | `—` | `unknown` | — | CAST(NULL AS DOUBLE) AS total_fees_gbp |
| 5 | `total_fees_usd` | `—` | `—` | `unknown` | — | CAST(NULL AS DOUBLE) AS total_fees_usd |

## Cross-check vs system.access.column_lineage

- Total target columns: **5**
- OK: **5**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **5**
