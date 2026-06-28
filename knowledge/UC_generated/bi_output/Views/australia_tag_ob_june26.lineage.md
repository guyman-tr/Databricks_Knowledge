# Column Lineage: main.bi_output.australia_tag_ob_june26

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.australia_tag_ob_june26` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\australia_tag_ob_june26.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\australia_tag_ob_june26.json` (rows: 8, mismatches: 0) |
| **Primary upstream** | `main.bi_output.australia_tag_ob_june26` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|

## Lineage Chain

```
main.bi_output.australia_tag_ob_june26   ←── primary upstream
        │
        ▼
main.bi_output.australia_tag_ob_june26   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `$distinct_id` | `—` | `$distinct_id` | `passthrough` | — | `$distinct_id` |
| 2 | `$name` | `—` | `$name` | `passthrough` | — | `$name` |
| 3 | `$email` | `—` | `$email` | `passthrough` | — | `$email` |
| 4 | `$last_seen` | `—` | `$last_seen` | `passthrough` | — | `$last_seen` |
| 5 | `$country_code` | `—` | `$country_code` | `passthrough` | — | `$country_code` |
| 6 | `$region` | `—` | `$region` | `passthrough` | — | `$region` |
| 7 | `$city` | `—` | `$city` | `passthrough` | — | `$city` |
| 8 | `$GCID` | `—` | `$GCID` | `passthrough` | — | `$GCID` |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **8**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
