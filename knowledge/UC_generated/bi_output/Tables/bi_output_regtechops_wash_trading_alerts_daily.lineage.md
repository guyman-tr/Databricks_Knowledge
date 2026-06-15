# Column Lineage: main.bi_output.bi_output_regtechops_wash_trading_alerts_daily

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_regtechops_wash_trading_alerts_daily` |
| **Object Type** | `EXTERNAL` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_regtechops_wash_trading_alerts_daily.py` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_regtechops_wash_trading_alerts_daily.json` (rows: 19, mismatches: 11) |
| **Parse warning** | `no final write to target found in notebook` |
| **Primary upstream** | `n/a` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `snapshot_date` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 2 | `CID` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 3 | `InstrumentID` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 4 | `InstrumentDisplayName` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 5 | `Symbol` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 6 | `wash_pair_count` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 7 | `roundtrip_count` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 8 | `total_volume` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 9 | `avg_time_between_pairs` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 10 | `avg_hold_minutes` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 11 | `first_detected` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 12 | `last_detected` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 13 | `risk_score` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 14 | `risk_level` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 15 | `detection_type` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 16 | `alert_status` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 17 | `assigned_to` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 18 | `created_at` | `—` | `—` | `unknown` | — | (no final write found in notebook) |
| 19 | `updated_at` | `—` | `—` | `unknown` | — | (no final write found in notebook) |

## Cross-check vs system.access.column_lineage

- Total target columns: **19**
- OK: **8**, WARN: **0**, ERROR: **11**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `CID` | — | `main.trading.bronze_etoro_history_position_datafactory.cid` | ERROR |
| `InstrumentID` | — | `main.trading.bronze_etoro_history_position_datafactory.instrumentid` | ERROR |
| `InstrumentDisplayName` | — | `main.trading.bronze_etoro_trade_instrumentmetadata.instrumentdisplayname` | ERROR |
| `Symbol` | — | `main.trading.bronze_etoro_trade_instrumentmetadata.symbol` | ERROR |
| `total_volume` | — | `main.trading.bronze_etoro_history_position_datafactory.amount` | ERROR |
| `avg_time_between_pairs` | — | `main.trading.bronze_etoro_history_position_datafactory.initdatetime` | ERROR |
| `avg_hold_minutes` | — | `main.trading.bronze_etoro_history_position_datafactory.closeoccurred`, `main.trading.bronze_etoro_history_position_datafactory.initdatetime` | ERROR |
| `first_detected` | — | `main.trading.bronze_etoro_history_position_datafactory.initdatetime` | ERROR |
| `last_detected` | — | `main.trading.bronze_etoro_history_position_datafactory.initdatetime` | ERROR |
| `risk_score` | — | `main.trading.bronze_etoro_history_position_datafactory.amount`, `main.trading.bronze_etoro_history_position_datafactory.netprofit` | ERROR |
| `risk_level` | — | `main.trading.bronze_etoro_history_position_datafactory.amount`, `main.trading.bronze_etoro_history_position_datafactory.netprofit` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **0**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **19**
