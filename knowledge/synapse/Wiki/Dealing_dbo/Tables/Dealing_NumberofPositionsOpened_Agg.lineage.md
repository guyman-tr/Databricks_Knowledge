# Lineage: Dealing_dbo.Dealing_NumberofPositionsOpened_Agg

## Source Objects

| # | Source Object | Source Type | Relationship | Wiki Path |
|---|--------------|-------------|--------------|-----------|
| 1 | Dealing_dbo.Dealing_DealingDashboard_Clients | Table | Direct aggregation source | knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_DealingDashboard_Clients.md |
| 2 | DWH_dbo.Dim_Instrument | Table | Indirect — InstrumentType originates from Dim_Instrument via DealingDashboard_Clients | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md |
| 3 | DWH_dbo.Dim_Country | Table | Indirect — Region originates from Dim_Country via DealingDashboard_Clients | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| DateID | Dealing_dbo.Dealing_DealingDashboard_Clients | DateID | Passthrough (GROUP BY key) | Tier 2 |
| Date | Dealing_dbo.Dealing_DealingDashboard_Clients | Date | Passthrough (GROUP BY key) | Tier 2 |
| InstrumentType | Dealing_dbo.Dealing_DealingDashboard_Clients | InstrumentType | Passthrough (GROUP BY key); originates from Dim_Instrument.InstrumentType (CASE on InstrumentTypeID) | Tier 2 |
| Region | Dealing_dbo.Dealing_DealingDashboard_Clients | Region | Passthrough (GROUP BY key); originates from Dim_Country.Region (marketing region label from Dictionary.MarketingRegion.Name) | Tier 2 |
| NumberOfPositionsOpened | Dealing_dbo.Dealing_DealingDashboard_Clients | NumberOfPositionsOpened | SUM aggregation across all dimension slices for the date | Tier 2 |
| UpdateDate | SP_DealingDashboard_Clients | — | GETDATE() at insert time | Tier 2 |

## Writer SP

| SP | Pattern | Schedule |
|----|---------|----------|
| Dealing_dbo.SP_DealingDashboard_Clients | DELETE + INSERT for @DateID at end of SP | Daily |
