# Column Lineage: Dealing_dbo.Dealing_Islamic_Instruments_Groups

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Islamic_Instruments_Groups` |
| **Primary Source** | Manual configuration (reference data) |
| **ETL SP** | None — manually maintained |
| **Downstream Consumer** | `SP_Islamic_Administrative_Fee` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Transform | Notes |
|-----------|-----------|-------|
| instrument_id | reference | FK to Dim_Instrument |
| name | reference | Instrument name (e.g., EUR/USD) |
| instrument_group | reference | Fee tier group assignment |
| instrument_type_id | reference | Asset class ID |
