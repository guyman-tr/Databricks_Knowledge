# Column Lineage: main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_tables_h_pricelocks_hourly_report_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_tables_h_pricelocks_hourly_report_v.json` (rows: 8, mismatches: 3) |
| **Primary upstream** | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_tables_h_pricelocks_hourly.md` |

## Lineage Chain

```
main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly   ←── primary upstream
        │
        ▼
main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly_report_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `DateID` | `rename` | — | DateID AS Date |
| 2 | `Asset` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `—` | `case` | — | CASE InstrumentTypeID WHEN 1 THEN 'Currencies' WHEN 2 THEN 'Commodities' WHEN 4 THEN 'Indices' WHEN 5 THEN 'Stocks' WHEN 6 THEN 'ETF' WHEN 1 |
| 3 | `Exchange` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `Exchange` | `passthrough` | — | Exchange |
| 4 | `InstrumentID` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 5 | `InstrumentDisplayName` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `InstrumentDisplayName` | `passthrough` | — | InstrumentDisplayName |
| 6 | `EventName` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `EventName` | `passthrough` | — | EventName |
| 7 | `TotalLocks` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `—` | `aggregate` | — | SUM(TotalLocks) AS TotalLocks |
| 8 | `TotalDuration` | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly` | `—` | `aggregate` | — | SUM(TotalDuration) AS TotalDuration |

## Cross-check vs system.access.column_lineage

- Total target columns: **8**
- OK: **5**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Asset` | — | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.instrumenttypeid` | ERROR |
| `TotalLocks` | — | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.totallocks` | ERROR |
| `TotalDuration` | — | `main.bi_dealing.bi_output_dealing_tables_h_pricelocks_hourly.totalduration` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**
