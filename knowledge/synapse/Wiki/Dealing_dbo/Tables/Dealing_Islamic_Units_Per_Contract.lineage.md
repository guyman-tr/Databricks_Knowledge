# Column Lineage: Dealing_dbo.Dealing_Islamic_Units_Per_Contract

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Islamic_Units_Per_Contract` |
| **Primary Source** | Manual configuration (reference data) |
| **ETL SP** | None — manually maintained |
| **Downstream Consumer** | `SP_Islamic_Administrative_Fee` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Transform | Notes |
|-----------|-----------|-------|
| instrument_id | reference | FK to Dim_Instrument |
| name | reference | Instrument name (e.g., XTI/USD) |
| units_per_contract | reference | Contract size for commodity fee calculation |
| instrument_type_id | reference | Asset class (2=Commodities) |
