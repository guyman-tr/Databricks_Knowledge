# Column Lineage: main.bi_output.funded

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.funded` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\funded.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\funded.json` (rows: 2, mismatches: 0) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_CID_MonthlyPanel_FullData.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata   ←── primary upstream
        │
        ▼
main.bi_output.funded   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Year` | `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | `—` | `unknown` | — | YEAR(ActiveDate) AS Year |
| 2 | `CID` | `main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata` | `CID` | `passthrough` | (Tier 1 — DWH_dbo.Dim_Customer wiki) | CID |

## Cross-check vs system.access.column_lineage

- Total target columns: **2**
- OK: **1**, WARN: **0**, ERROR: **0**, INFO: **1**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
