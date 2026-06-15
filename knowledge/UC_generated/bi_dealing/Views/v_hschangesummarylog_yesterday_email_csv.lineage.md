# Column Lineage: main.bi_dealing.v_hschangesummarylog_yesterday_email_csv

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.v_hschangesummarylog_yesterday_email_csv` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\v_hschangesummarylog_yesterday_email_csv.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\v_hschangesummarylog_yesterday_email_csv.json` (rows: 6, mismatches: 0) |
| **Primary upstream** | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | Primary (FROM) | ✓ `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Trade/Tables/Trade.PositionsHedgeServerChangeSummaryLog.md` |

## Lineage Chain

```
main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog   ←── primary upstream
        │
        ▼
main.bi_dealing.v_hschangesummarylog_yesterday_email_csv   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `ID` | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | `ID` | `passthrough` | — | ID |
| 2 | `StartTime` | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | `StartTime` | `passthrough` | — | StartTime |
| 3 | `EndTime` | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | `EndTime` | `passthrough` | — | EndTime |
| 4 | `Comments` | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | `Comments` | `passthrough` | — | Comments |
| 5 | `etr_ymd` | `main.dealing.bronze_etoro_trade_positionshedgeserverchangesummarylog` | `etr_ymd` | `passthrough` | — | etr_ymd |
| 6 | `UpdateDate` | `—` | `—` | `literal` | — | literal `CURRENT_TIMESTAMP()` — CURRENT_TIMESTAMP() AS UpdateDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **6**
- OK: **6**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **1**

## Joins (detected)

- `INNER CROSS` — CROSS JOIN run_date AS r
