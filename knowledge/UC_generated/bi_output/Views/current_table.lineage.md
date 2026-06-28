# Column Lineage: main.bi_output.current_table

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.current_table` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\current_table.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\current_table.json` (rows: 1, mismatches: 0) |
| **Primary upstream** | `main.csv.abfss://analysis@stgdpdlwe.dfs.core.windows.net/bi_output/finance/uploads/guy_m/current_isfundedthisyear` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.csv.abfss://analysis@stgdpdlwe.dfs.core.windows.net/bi_output/finance/uploads/guy_m/current_isfundedthisyear` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.csv.abfss://analysis@stgdpdlwe.dfs.core.windows.net/bi_output/finance/uploads/guy_m/current_isfundedthisyear   ←── primary upstream
        │
        ▼
main.bi_output.current_table   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `_c0` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **1**
- OK: **1**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
