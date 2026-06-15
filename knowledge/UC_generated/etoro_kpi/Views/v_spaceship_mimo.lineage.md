# Column Lineage: main.etoro_kpi.v_spaceship_mimo

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.v_spaceship_mimo` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\v_spaceship_mimo.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\v_spaceship_mimo.json` (rows: 1, mismatches: 0) |
| **Primary upstream** | `main.etoro_kpi_prep.v_spaceship_mimo` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi_prep.v_spaceship_mimo` | Primary (FROM) | ✓ `knowledge/UC_generated/etoro_kpi_prep/Views/v_spaceship_mimo.md` |

## Lineage Chain

```
main.etoro_kpi_prep.v_spaceship_mimo   ←── primary upstream
        │
        ▼
main.etoro_kpi.v_spaceship_mimo   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `date` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 2 | `date_id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 3 | `product` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 4 | `is_internal_transfer` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 5 | `user_id` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 6 | `gcid` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 7 | `total_deposits_aud` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 8 | `total_withdrawals_aud` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 9 | `net_flow_aud` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 10 | `total_deposits_usd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 11 | `total_withdrawals_usd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 12 | `net_flow_usd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 13 | `count_deposits` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 14 | `count_withdrawals` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |
| 15 | `is_ftd` | `—` | `—` | `unknown` | — | (not parsed — column missing from SELECT?) |

## Cross-check vs system.access.column_lineage

- Total target columns: **1**
- OK: **1**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **1**
