# EXW_dbo.EXW_WalletElligibleCountries — Column Lineage

**Generated**: 2026-04-20 | **ETL SP**: SP_EXW_WalletElligibleCountries | **Load Pattern**: TRUNCATE + INSERT (no date param)

## ETL Pipeline

```
EXW_Settings.Resources + SystemRestrictions + Tags (ResourceId=5903)
  + DWH_dbo.Dim_Country + Dim_State_and_Province + Dim_Regulation
  |-- SP_EXW_WalletElligibleCountries
  |   Max(RestrictionWeight) priority resolution per CountryID×RegulationID×RegionByIP_ID
  |   TRUNCATE + INSERT ---|
  v
EXW_dbo.EXW_WalletElligibleCountries (4,228 rows)
  |-- SP_EXW_UserSettingsWalletAllowance (consumer) ---|
  v
EXW_dbo.EXW_UserSettingsWalletAllowance (documented, Batch 2)
  |-- (no UC migration) ---|
  v
_Not_Migrated
```

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|---|---|---|---|---|
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough | Tier 1 — Dictionary.Country upstream wiki |
| ResourceName | EXW_Settings.Resources | ResourceName | Passthrough — always 'AllowedUsingWalletStatus' for this table | Tier 2 — SP_EXW_WalletElligibleCountries |
| ResourceId | EXW_Settings.Resources | ResourceId | Passthrough — always 5903 | Tier 2 — SP_EXW_WalletElligibleCountries |
| TagType | EXW_Settings.Tags | TagType | Passthrough — winning tag type per priority resolution | Tier 2 — SP_EXW_WalletElligibleCountries |
| TagValue | EXW_Settings.Tags | TagValue | Passthrough — winning tag value per priority resolution | Tier 2 — SP_EXW_WalletElligibleCountries |
| SelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Passthrough — 0=Closed, 1=ReadOnly, 2=Open, 3=OpenForExistingOnly | Tier 2 — SP_EXW_WalletElligibleCountries |
| Country | DWH_dbo.Dim_Country | Name | Passthrough | Tier 1 — Dictionary.Country upstream wiki |
| Region | DWH_dbo.Dim_Country | Region | Passthrough (marketing region, not geographic) | Tier 2 — SP_Dictionaries_Country_DL_To_Synapse |
| CountryOpenforWallet | computed | SelectedValue | CASE: 0=0, 1=1, 2=2, 3=3 (integer passthrough of SelectedValue) | Tier 2 — SP_EXW_WalletElligibleCountries |
| US State | DWH_dbo.Dim_State_and_Province | Name (StateProvince) | Passthrough — NULL for non-US (CountryID≠219) | Tier 2 — SP_EXW_WalletElligibleCountries |
| MarketingRegionID | DWH_dbo.Dim_Country | MarketingRegionID | Passthrough | Tier 1 — Dictionary.Country upstream wiki |
| UpdateDate | GETDATE() | — | ETL timestamp | Tier 2 — SP_EXW_WalletElligibleCountries |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough | Tier 1 — upstream wiki, Dictionary.Regulation |
| RegulationID | DWH_dbo.Dim_Regulation | DWHRegulationID | Passthrough — ETL alias of regulation ID | Tier 2 — SP_Dictionaries_DL_To_Synapse |
| RestrictionWeight | EXW_Settings.SystemRestrictions | RestrictionWeight | Passthrough — highest weight wins priority resolution | Tier 2 — SP_EXW_WalletElligibleCountries |
| CountryOpenforWalletDescription | computed | SelectedValue | CASE: 0=Closed, 1=ReadOnly, 2=Open, 3=OpenForExistingOnly (human-readable) | Tier 2 — SP_EXW_WalletElligibleCountries |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | ISNULL(RegionByIP_ID, 0) — 0 for non-US | Tier 2 — SP_EXW_WalletElligibleCountries |

## Source Objects

| Object | Role |
|---|---|
| EXW_Settings.Resources | Source of ResourceName, ResourceId for wallet allowance resource (ResourceId=5903) |
| EXW_Settings.SystemRestrictions | Source of SelectedValue, RestrictionWeight, TagId |
| EXW_Settings.Tags | Source of TagType, TagValue |
| DWH_dbo.Dim_Country | Source of CountryID, Country (Name), Region, MarketingRegionID |
| DWH_dbo.Dim_Regulation | Source of Regulation (Name), RegulationID (DWHRegulationID) |
| DWH_dbo.Dim_State_and_Province | Source of [US State] (Name), RegionByIP_ID — US only |
| EXW_dbo.SP_EXW_WalletElligibleCountries | Writer SP |
| EXW_dbo.SP_EXW_UserSettingsWalletAllowance | Reader SP |

## Tier Summary

| Tier | Count | Columns |
|---|---|---|
| Tier 1 | 4 | CountryID, Country, MarketingRegionID, Regulation |
| Tier 2 | 13 | ResourceName, ResourceId, TagType, TagValue, SelectedValue, Region, CountryOpenforWallet, US State, UpdateDate, RegulationID, RestrictionWeight, CountryOpenforWalletDescription, RegionByIP_ID |
