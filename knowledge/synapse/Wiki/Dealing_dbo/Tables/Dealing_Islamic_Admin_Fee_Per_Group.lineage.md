# Column Lineage: Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | Manual configuration (reference data) |
| **ETL SP** | None — manually maintained reference table |
| **Downstream Consumer** | `SP_Islamic_Administrative_Fee` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Transform | Notes |
|-----------|-----------|-------|
| instrument_group | reference | Group ID for fee tier classification |
| admin_fee_usd | reference | USD fee amount per unit/contract |
| grace_period | reference | Days before fee starts (always 7) |
| currency | reference | Fee currency (always USD) |
| instrument_type_id | reference | Asset class: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto |
