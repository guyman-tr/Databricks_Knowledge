# Column Lineage: main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly_report_v

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly_report_v` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_dealing\_discovery\source_code\bi_output_dealing_tables_h_market_manipulation_hourly_report_v.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_dealing\_discovery\column_lineage\bi_output_dealing_tables_h_market_manipulation_hourly_report_v.json` (rows: 12, mismatches: 0) |
| **Primary upstream** | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | Primary (FROM) | ✗ `knowledge/UC_generated/bi_dealing/<Tables|Views>/bi_output_dealing_tables_h_market_manipulation_hourly.md` |

## Lineage Chain

```
main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly   ←── primary upstream
        │
        ▼
main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly_report_v   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `Date` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `Date` | `passthrough` | — | Date |
| 2 | `StartTime` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `StartTime` | `passthrough` | — | StartTime |
| 3 | `InstrumentID` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `InstrumentID` | `passthrough` | — | InstrumentID |
| 4 | `InstrumentName` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `InstrumentName` | `passthrough` | — | InstrumentName |
| 5 | `ADV_Last3Months` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `ADV_Last3Months` | `passthrough` | — | ADV_Last3Months |
| 6 | `SharesOutStanding` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `SharesOutStanding` | `passthrough` | — | SharesOutStanding |
| 7 | `EtoroVolumeExternalized` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `EtoroVolumeExternalized` | `passthrough` | — | EtoroVolumeExternalized |
| 8 | `CustomersTotalUnits` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `CustomersTotalUnits` | `passthrough` | — | CustomersTotalUnits |
| 9 | `CID` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `CID` | `passthrough` | — | CID |
| 10 | `VolumeInUnitsDailyRealized` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `VolumeInUnitsDailyRealized` | `passthrough` | — | VolumeInUnitsDailyRealized |
| 11 | `RealizedZero` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `RealizedZero` | `passthrough` | — | RealizedZero |
| 12 | `VolumeExternalised_CID` | `main.bi_dealing.bi_output_dealing_tables_h_market_manipulation_hourly` | `VolumeExternalised_CID` | `passthrough` | — | VolumeExternalised_CID |

## Cross-check vs system.access.column_lineage

- Total target columns: **12**
- OK: **0**, WARN: **0**, ERROR: **0**, INFO: **12**  ✓

## Lost / added columns

- Computed/added columns vs primary: **0**
