# Lineage: BI_DB_dbo.BI_DB_PastYearsGain

## Source Objects

| Source Object | Schema | Role | Wiki Available |
|--------------|--------|------|----------------|
| DWH_GainDaily | BI_DB_dbo | Primary data source — Gain_y, Date, CID | Yes |
| V_Dim_Date | DWH_dbo | Filter — DayNumberOfYear=1 selects Jan 1 dates | Yes |
| SP_PI_Dashboard_COPYDATA_RuningSideBySide | BI_DB_dbo | Writer SP — section 3.4 inserts past year gains | Yes (bundle) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough (filtered to Jan 1 dates via V_Dim_Date WHERE DayNumberOfYear=1) | Tier 2 |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough | Tier 1 |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough | Tier 2 |
| Year1 | BI_DB_dbo.DWH_GainDaily | Date | ETL-computed: YEAR(Date)-1 | Tier 2 |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 |
