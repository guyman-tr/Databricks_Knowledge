---
object: EXW_dbo.EXW_Conversion_Allowed_Country
type: Table
batch: 9
---

# EXW_Conversion_Allowed_Country — Column Lineage

> All three Allowed_Country tables (Staking, Payment, Conversion) are written by the same SP: `EXW_dbo.SP_EXW_WalletElligibleCountries`.

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| Country | Name | `DWH_dbo.Dim_Country` | Dim_Country.Name text label | Tier 2 |
| CountryID | CountryID | `DWH_dbo.Dim_Country` | Enumerated from Dim_Country — all countries with EXW_Settings conversion rules | Tier 2 |
| StateProvince | Name | `DWH_dbo.Dim_State_and_Province` | For US states: state name; NULL for other countries | Tier 3 |
| RegionByIP_ID | RegionByIP_ID | `DWH_dbo.Dim_State_and_Province` | For US states: RegionByIP_ID; NULL for other countries | Tier 3 |
| CryptoID | — | Derived from EXW_Settings ResourceName path | Numeric crypto identifier extracted from ResourceName pattern | Tier 3 |
| Crypto | — | Crypto dimension (no upstream wiki) | Crypto name text joined from crypto lookup | Tier 3 |
| AllowedUserResource | ResourceName | `EXW_Settings` (user-level conversion setting) | ResourceName for user-level conversion eligibility | Tier 2 |
| AllowedUserTagType | TagType | `EXW_Settings` (user-level) | Tag type for user-level conversion setting resolution | Tier 2 |
| AllowedUserTagValue | TagValue | `EXW_Settings` (user-level) | Tag value matched for user-level conversion setting | Tier 2 |
| AllowedUserSelectedValue | SelectedValue | `EXW_Settings` (user-level) | Raw resolved value for user-level conversion eligibility | Tier 2 |
| FromResourceName | ResourceName | `EXW_Settings` (From-crypto conversion setting) | ResourceName for From-direction conversion eligibility | Tier 2 |
| FromTagType | TagType | `EXW_Settings` (From-direction) | Tag type for From-direction conversion setting | Tier 2 |
| FromTagValue | TagValue | `EXW_Settings` (From-direction) | Tag value matched for From-direction conversion setting | Tier 2 |
| FromSelectedValue | SelectedValue | `EXW_Settings` (From-direction) | Raw resolved value for From-direction conversion eligibility | Tier 2 |
| ToResourceName | ResourceName | `EXW_Settings` (To-crypto conversion setting) | ResourceName for To-direction conversion eligibility | Tier 2 |
| ToTagType | TagType | `EXW_Settings` (To-direction) | Tag type for To-direction conversion setting | Tier 2 |
| ToTagValue | TagValue | `EXW_Settings` (To-direction) | Tag value matched for To-direction conversion setting | Tier 2 |
| ToSelectedValue | SelectedValue | `EXW_Settings` (To-direction) | Raw resolved value for To-direction conversion eligibility | Tier 2 |
| FromConversionAllowed | — | Computed | `CASE WHEN AllowedUserSelectedValue='true' AND FromSelectedValue='true' THEN 1 ELSE 0` — currently always 0 (conversion discontinued) | Tier 2 |
| ToConversionAllowed | — | Computed | `CASE WHEN AllowedUserSelectedValue='true' AND ToSelectedValue='true' THEN 1 ELSE 0` — currently always 0 (conversion discontinued) | Tier 2 |
| UpdateDate | — | SP_EXW_WalletElligibleCountries | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
DWH_dbo.Dim_Country + Dim_State_and_Province → CountryID, Country, StateProvince, RegionByIP_ID

EXW_Settings (user-level conversion, domain='wallet') → AllowedUser* columns

EXW_Settings (From-direction crypto conversion, domain='wallet') → From* columns

EXW_Settings (To-direction crypto conversion, domain='wallet') → To* columns

Crypto dimension → CryptoID, Crypto

FromConversionAllowed = AllowedUserSelectedValue='true' AND FromSelectedValue='true'
ToConversionAllowed = AllowedUserSelectedValue='true' AND ToSelectedValue='true'

TRUNCATE TABLE EXW_dbo.EXW_Conversion_Allowed_Country
INSERT INTO EXW_dbo.EXW_Conversion_Allowed_Country
```

## Note on Current Data State

All FromConversionAllowed and ToConversionAllowed values are currently 0. Crypto-to-crypto conversions were discontinued; no country/crypto combination currently satisfies conversion eligibility conditions in EXW_Settings.
