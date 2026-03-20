# Column Lineage: DWH_dbo.Dim_Country

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Country` |
| **UC Target** | _Pending - resolved during write-objects_ |
| **Primary Source** | `etoro.Dictionary.Country` (etoro) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse` |
| **Secondary Sources** | `etoro.Dictionary.MarketingRegion`, `DWH_dbo.Ext_Dim_Country`, `DWH_dbo.Ext_Dim_Country_Region_Desk`, `ComplianceStateDB.Compliance.RegulationCountry` |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Country (primary)
  -> DWH_staging.etoro_Dictionary_Country
  -> (JOIN) DWH_staging.etoro_Dictionary_MarketingRegion
  -> DWH_dbo.SP_Dictionaries_Country_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_Country (initial load)
  -> UPDATE: DWH_dbo.Ext_Dim_Country (EU, IsEuropeanCountry, MarketingRegionManualName)
  -> UPDATE: DWH_dbo.Ext_Dim_Country_Region_Desk (CFKey, Desk via MarketingRegionID)
  -> UPDATE: ComplianceStateDB via Ext_Dim_Country_Regulation (RegulationID)
  -> DWH_dbo.Dim_Country (251 rows, fully patched)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **type-cast** | Same value, different data type. |
| **computed** | Derived via expression in ETL SP. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **UPDATE-patch** | Not in initial INSERT; added via a subsequent UPDATE pass. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CountryID | etoro.Dictionary.Country | CountryID | passthrough | Integer PK. 0=Not available placeholder. |
| Abbreviation | etoro.Dictionary.Country | Abbreviation | passthrough | ISO 3166-1 alpha-2. nvarchar(max) in staging, char(2) in DWH. |
| LongAbbreviation | etoro.Dictionary.Country | LongAbbreviation | passthrough | ISO 3166-1 alpha-3. nvarchar(max) in staging, char(3) in DWH. |
| Name | etoro.Dictionary.Country | Name | passthrough | Country name in English. |
| IsHighRiskCountry | etoro.Dictionary.Country | RiskGroupID | computed | `CASE WHEN RiskGroupID IN (0,4) THEN 0 ELSE 1 END`. Not the source IsHighRiskCountry column. |
| Region | etoro.Dictionary.MarketingRegion | Name | rename | `y.Name AS Region` - joined on MarketingRegionID. Marketing region text, not geographic region. |
| StatusID | - | - | ETL-computed | Hardcoded constant 1 for all rows. |
| DWHCountryID | etoro.Dictionary.Country | CountryID | copy | `x.CountryID AS DWHCountryID` - always equals CountryID. Redundant. |
| UpdateDate | - | - | ETL-computed | GETDATE() on each reload. |
| InsertDate | - | - | ETL-computed | GETDATE() on each reload (same value as UpdateDate due to TRUNCATE+INSERT). |
| EU | DWH_dbo.Ext_Dim_Country | EU | UPDATE-patch | LEFT JOIN on CountryID. Manual extension table. |
| Desk | DWH_dbo.Ext_Dim_Country_Region_Desk | Desk | UPDATE-patch | LEFT JOIN on a.MarketingRegionID = b.RegionID. Per marketing region, not per country. |
| RegulationID | ComplianceStateDB.Compliance.RegulationCountry | RegulationID | UPDATE-patch | Via Ext_Dim_Country_Regulation staging table. LEFT JOIN on CountryID. |
| CFKey | DWH_dbo.Ext_Dim_Country_Region_Desk | CFKey | UPDATE-patch | LEFT JOIN on a.MarketingRegionID = b.RegionID. Per marketing region. |
| MarketingRegionID | etoro.Dictionary.Country | MarketingRegionID | passthrough | FK to Dictionary.MarketingRegion. |
| RiskGroupID | etoro.Dictionary.Country | RiskGroupID | passthrough | Source of truth for IsHighRiskCountry computation. |
| IsEligibleForRAFBonusCountry | etoro.Dictionary.Country | IsEligibleForRAFBonusCountry | type-cast | `CAST(bit AS int)`. 0/1 values preserved. |
| IsEuropeanCountry | DWH_dbo.Ext_Dim_Country | IsEuropeanCountry | UPDATE-patch | LEFT JOIN on CountryID. Manual extension table. |
| MarketingRegionManualName | DWH_dbo.Ext_Dim_Country | MarketingRegionManualName | UPDATE-patch | LEFT JOIN on CountryID. Manual override for Region label. |

## Dropped Source Columns (in Dictionary.Country but NOT in DWH)

| Source Column | Type | Reason Dropped |
|--------------|------|----------------|
| RegionID | int | DWH uses marketing Region text label instead of geographic RegionID |
| DefaultCurrencyID | int | Not loaded to DWH |
| LanguageID | int | Not loaded to DWH |
| PhonePrefix | varchar(3) | Not loaded to DWH |
| IsActive | bit | Not loaded; StatusID hardcoded to 1 instead |
| IsSettlementRestricted | bit | Not loaded (CRITICAL - compliance flag for CFD-only restrictions) |
| IsoCode | char(3) | Not loaded to DWH |
| EconomicTypeID | int | Not loaded to DWH |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 5 |
| **Rename** | 1 |
| **Type-cast** | 1 |
| **Computed** | 1 |
| **ETL-computed** | 3 |
| **UPDATE-patch** | 8 |
| **Total** | 19 |
| **Dropped source columns** | 8 |
