# Column Lineage: Dealing_dbo.Dealing_overnight_fees

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_overnight_fees` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | External (Fivetran sync) |
| **ETL SP** | None — loaded via Fivetran connector |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
External Source (Bloomberg/Sheets) ──► Fivetran ──► Dealing_overnight_fees
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| _row | Fivetran metadata | — | infrastructure | Fivetran row identifier |
| _fivetran_synced | Fivetran metadata | — | infrastructure | Fivetran sync timestamp |
| future_short_cut | External source | — | passthrough | Futures contract shortcut (e.g., CL, NG, LN) |
| ticker | External source | — | passthrough | Bloomberg ticker (e.g., CL1 COMB Comdty) |
| days | External source | — | passthrough | Days to expiry/rollover |
| close | External source | — | passthrough | Closing price |
| instrument_id | External source | — | passthrough | FK to instrument |
| date | External source | — | passthrough | Data date |
| update_date | External source | — | passthrough | Source update timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Infrastructure** | 2 |
| **Passthrough** | 7 |
| **Total** | 9 |
