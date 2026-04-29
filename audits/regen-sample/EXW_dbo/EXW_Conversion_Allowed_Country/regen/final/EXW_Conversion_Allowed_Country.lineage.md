# EXW_dbo.EXW_Conversion_Allowed_Country — Column Lineage

## Source Objects

| # | Source Object | Schema | Type | Relationship | Wiki |
|---|--------------|--------|------|-------------|------|
| 1 | Dim_Country | DWH_dbo | Table | Country, CountryID dimension lookup | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md |
| 2 | Dim_State_and_Province | DWH_dbo | Table | StateProvince, RegionByIP_ID (US only) | knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_State_and_Province.md |
| 3 | CryptoTypes | EXW_Wallet | Table | CryptoID, Crypto (active crypto assets) | — |
| 4 | Resources | EXW_Settings | Table | ResourceName for AllowedUser/From/To | — |
| 5 | Tags | EXW_Settings | Table | TagType, TagValue for restriction matching | — |
| 6 | SystemRestrictions | EXW_Settings | Table | SelectedValue, RestrictionWeight for priority resolution | — |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|--------------|-----------|------|
| 1 | Country | DWH_dbo.Dim_Country | Name | Rename (c.Name AS Country); passthrough value. WHERE CountryID <> 0. | Tier 1 — Dictionary.Country |
| 2 | CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough. WHERE CountryID <> 0 (excludes placeholder). | Tier 1 — Dictionary.Country |
| 3 | StateProvince | DWH_dbo.Dim_State_and_Province | Name | CASE WHEN CountryID = 219 THEN p.Name ELSE NULL END. Only populated for United States rows. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 4 | RegionByIP_ID | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | CASE WHEN CountryID = 219 THEN p.RegionByIP_ID ELSE NULL END, then ISNULL(..., 0). 0 for all non-US rows. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 5 | CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough via #wave temp table. Filtered to IsActive=1. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 6 | Crypto | EXW_Wallet.CryptoTypes | Name | Rename (t.Name AS Crypto). Filtered to IsActive=1. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 7 | AllowedUserResource | EXW_Settings.Resources | ResourceName | Via #conversionalloweduser: COALESCE of coin-level and category-level settings, resolved by MAX(RestrictionWeight). Resource = 'conversion/allowedUser'. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 8 | AllowedUserTagType | EXW_Settings.Tags | TagType | Via #conversionalloweduser: priority-resolved tag type (Country, CountryAndRegion, or Default). | Tier 2 — SP_EXW_WalletElligibleCountries |
| 9 | AllowedUserTagValue | EXW_Settings.Tags | TagValue | Via #conversionalloweduser: priority-resolved tag value (country name, country_region combo, or 'Default'). | Tier 2 — SP_EXW_WalletElligibleCountries |
| 10 | AllowedUserSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Via #conversionalloweduser: priority-resolved selected value ('true'/'false'). Determines if user is allowed to convert. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 11 | FromResourceName | EXW_Settings.Resources | ResourceName | Via #fromcrypto: same weight-resolution logic as AllowedUser, but for 'cryptos/{id}/allowedConvertFrom' resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 12 | FromTagType | EXW_Settings.Tags | TagType | Via #fromcrypto: priority-resolved tag type for the allowedConvertFrom resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 13 | FromTagValue | EXW_Settings.Tags | TagValue | Via #fromcrypto: priority-resolved tag value for the allowedConvertFrom resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 14 | FromSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Via #fromcrypto: priority-resolved selected value for whether conversion FROM this crypto is allowed. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 15 | ToResourceName | EXW_Settings.Resources | ResourceName | Via #tocrypto: same weight-resolution logic, for 'cryptos/{id}/allowedConvertTo' resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 16 | ToTagType | EXW_Settings.Tags | TagType | Via #tocrypto: priority-resolved tag type for the allowedConvertTo resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 17 | ToTagValue | EXW_Settings.Tags | TagValue | Via #tocrypto: priority-resolved tag value for the allowedConvertTo resource. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 18 | ToSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Via #tocrypto: priority-resolved selected value for whether conversion TO this crypto is allowed. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 19 | FromConversionAllowed | — | — | ETL-computed: CASE WHEN LOWER(AllowedUserSelectedValue) = 'true' AND LOWER(FromSelectedValue) = 'true' THEN 1 ELSE 0 END. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 20 | ToConversionAllowed | — | — | ETL-computed: CASE WHEN LOWER(AllowedUserSelectedValue) = 'true' AND LOWER(ToSelectedValue) = 'true' THEN 1 ELSE 0 END. | Tier 2 — SP_EXW_WalletElligibleCountries |
| 21 | UpdateDate | — | — | ETL-computed: GETDATE() at load time. | Tier 2 — SP_EXW_WalletElligibleCountries |
