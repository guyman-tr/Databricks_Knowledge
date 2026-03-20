# Column Lineage — DWH_dbo.VU_FactBilling_ForBigQuery

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| ~20 numeric/date columns | Fact_BillingDeposit | Direct passthrough |
| ~70 string columns | Fact_BillingDeposit | `DWH_dbo.RemoveSpecialChars(CONVERT(NVARCHAR(MAX), ...))` |
| ~5 exchange/fee columns | Fact_BillingDeposit | Direct passthrough |

## All columns from single source table Fact_BillingDeposit. No joins, no filters.
