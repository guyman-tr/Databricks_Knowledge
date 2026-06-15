# Column Lineage: main.etoro_kpi.ftd_click_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.ftd_click_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\ftd_click_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\ftd_click_v.json` (rows: 9, mismatches: 7) |
| **Primary upstream** | `main.etoro_kpi.de_output_ftd_click` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.etoro_kpi.de_output_ftd_click` | Primary (FROM) | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/de_output_ftd_click.md` |
| `main.etoro_kpi.de_output_ftd_click` | Primary (FROM) | ✗ `knowledge/UC_generated/etoro_kpi/<Tables|Views>/de_output_ftd_click.md` |

## Lineage Chain

```
main.etoro_kpi.de_output_ftd_click   ←── primary upstream
        │
        ▼
main.etoro_kpi.ftd_click_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `gcid` | `main.etoro_kpi.de_output_ftd_click` | `gcid` | `passthrough` | — | gcid |
| 2 | `realcid` | `main.etoro_kpi.de_output_ftd_click` | `realcid` | `passthrough` | — | realcid |
| 3 | `initial_deposit_click` | `main.etoro_kpi.de_output_ftd_click` | `initial_deposit_click` | `passthrough` | — | initial_deposit_click |
| 4 | `ftd_wizard_intro` | `main.etoro_kpi.de_output_ftd_click` | `ftd_wizard_intro` | `passthrough` | — | ftd_wizard_intro |
| 5 | `ftd_wizard_amount` | `main.etoro_kpi.de_output_ftd_click` | `ftd_wizard_amount` | `passthrough` | — | ftd_wizard_amount |
| 6 | `ftd_wizard_mean_of_payment` | `main.etoro_kpi.de_output_ftd_click` | `ftd_wizard_mean_of_payment` | `passthrough` | — | ftd_wizard_mean_of_payment |
| 7 | `final_deposit_click` | `main.etoro_kpi.de_output_ftd_click` | `final_deposit_click` | `passthrough` | — | final_deposit_click |
| 8 | `initial_deposit_clicks_combined` | `main.etoro_kpi.de_output_ftd_click` | `max_time` | `rename` | — | max_time AS initial_deposit_clicks_combined |
| 9 | `initial_deposit_click_type` | `main.etoro_kpi.de_output_ftd_click` | `—` | `case` | — | CASE WHEN max_time IS NULL THEN NULL WHEN max_time = initial_deposit_click THEN 'initial_deposit_click' WHEN max_time = ftd_wizard_intro THE |

## Cross-check vs system.access.column_lineage

- Total target columns: **9**
- OK: **2**, WARN: **6**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `initial_deposit_click` | `main.etoro_kpi.de_output_ftd_click.initial_deposit_click` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `ftd_wizard_intro` | `main.etoro_kpi.de_output_ftd_click.ftd_wizard_intro` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `ftd_wizard_amount` | `main.etoro_kpi.de_output_ftd_click.ftd_wizard_amount` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `ftd_wizard_mean_of_payment` | `main.etoro_kpi.de_output_ftd_click.ftd_wizard_mean_of_payment` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `final_deposit_click` | `main.etoro_kpi.de_output_ftd_click.final_deposit_click` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `initial_deposit_clicks_combined` | `main.etoro_kpi.de_output_ftd_click.max_time` | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | WARN |
| `initial_deposit_click_type` | — | `main.etoro_kpi.de_output_ftd_click.last_event_time`, `main.etoro_kpi.de_output_ftd_click.step_key` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN (SELECT DISTINCT gcid, realcid FROM main.etoro_kpi.de_output_ftd_click WHERE NOT realcid IS NULL) AS b ON a.gcid = b.gcid
