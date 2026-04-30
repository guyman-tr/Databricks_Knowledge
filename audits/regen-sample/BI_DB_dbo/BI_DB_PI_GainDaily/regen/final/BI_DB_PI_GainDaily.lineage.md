# Lineage: BI_DB_dbo.BI_DB_PI_GainDaily

## Source Objects

| Source Object | Type | Schema | Role |
|--------------|------|--------|------|
| BI_DB_dbo.DWH_GainDaily | Table | BI_DB_dbo | Primary data source — all gain columns passthrough |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Population filter (GuruStatusID, AccountTypeID, IsValidCustomer) |
| DWH_dbo.Dim_GuruStatus | Table | DWH_dbo | Population filter (JOIN for PI status) |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Population filter (JOIN in #pop) |
| DWH_dbo.Dim_PlayerStatus | Table | DWH_dbo | Population filter (JOIN in #pop) |
| BI_DB_dbo.SP_PI_Dashboard_COPYDATA_RuningSideBySide | Stored Procedure | BI_DB_dbo | Writer SP (sections 3.1, 3.2) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| Date | BI_DB_dbo.DWH_GainDaily | Date | Passthrough | Tier 2 — DWH_GainDaily |
| CID | BI_DB_dbo.DWH_GainDaily | CID | Passthrough (filtered to PI/CopyFund population) | Tier 1 — Customer.CustomerStatic |
| Gain_w | BI_DB_dbo.DWH_GainDaily | Gain_w | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_m | BI_DB_dbo.DWH_GainDaily | Gain_m | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_q | BI_DB_dbo.DWH_GainDaily | Gain_q | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_h | BI_DB_dbo.DWH_GainDaily | Gain_h | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_y | BI_DB_dbo.DWH_GainDaily | Gain_y | Passthrough | Tier 2 — DWH_GainDaily |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide |
| Gain_MTD | BI_DB_dbo.DWH_GainDaily | Gain_MTD | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_YTD | BI_DB_dbo.DWH_GainDaily | Gain_YTD | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_d | BI_DB_dbo.DWH_GainDaily | Gain_d | Passthrough | Tier 2 — DWH_GainDaily |
| Gain_QTD | BI_DB_dbo.DWH_GainDaily | Gain_QTD | Passthrough | Tier 2 — DWH_GainDaily |
