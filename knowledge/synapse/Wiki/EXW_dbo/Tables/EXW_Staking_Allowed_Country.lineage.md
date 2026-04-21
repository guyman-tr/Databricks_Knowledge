---
object: EXW_dbo.EXW_Staking_Allowed_Country
type: Table
batch: 9
---

# EXW_Staking_Allowed_Country — Column Lineage

> All three Allowed_Country tables (Staking, Payment, Conversion) are written by the same SP: `EXW_dbo.SP_EXW_WalletElligibleCountries`.

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| CountryID | CountryID | `DWH_dbo.Dim_Country` | Enumerated from Dim_Country — all countries with EXW_Settings staking rules | Tier 2 |
| Country | Name | `DWH_dbo.Dim_Country` | Dim_Country.Name text label | Tier 2 |
| StateProvince | Name | `DWH_dbo.Dim_State_and_Province` | For US states (CountryID=219): Dim_State_and_Province.Name; NULL for other countries | Tier 3 |
| RegionByIP_ID | RegionByIP_ID | `DWH_dbo.Dim_State_and_Province` | For US states: state's RegionByIP_ID; NULL for other countries | Tier 3 |
| CryptoID | — | Derived from EXW_Settings ResourceName path (e.g., 'cryptos/2/allowstakingmode' → CryptoID=2) | Numeric crypto identifier extracted from ResourceName pattern | Tier 3 |
| Crypto | — | Crypto dimension (no upstream wiki) | Crypto name text (ETH, BTC, etc.) joined from crypto lookup | Tier 3 |
| ResourceName | ResourceName | `EXW_Settings` | EXW_Settings resource name for staking eligibility (pattern: `cryptos/{CryptoID}/allowstakingmode`) | Tier 2 |
| TagType | TagType | `EXW_Settings` | Tag type for the resolved staking setting (e.g., 'Country', 'CountryAndRegion', 'GeoRegistrationDate') | Tier 2 |
| TagValue | TagValue | `EXW_Settings` | Tag value matched to resolve staking setting | Tier 2 |
| SelectedValue | SelectedValue | `EXW_Settings` | Raw resolved setting value ('true'/'false') from EXW_Settings priority resolution | Tier 2 |
| StakingAllowed | — | Computed from SelectedValue | `CASE WHEN SelectedValue = 'true' THEN 1 ELSE 0 END` — currently always 0 (staking discontinued) | Tier 2 |
| UpdateDate | — | SP_EXW_WalletElligibleCountries | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
DWH_dbo.Dim_Country (all countries)
  └─ CountryID, Country, StateProvince, RegionByIP_ID

EXW_Settings (ResourceName = 'cryptos/{N}/allowstakingmode', domain = 'wallet')
  └─ Priority-weighted tag resolution (Country > CountryAndRegion > GeoRegistrationDate)
  └─ ResourceName, TagType, TagValue, SelectedValue

Crypto dimension (CryptoID, Crypto name)

Computed: StakingAllowed = CASE WHEN SelectedValue = 'true' THEN 1 ELSE 0

TRUNCATE TABLE EXW_dbo.EXW_Staking_Allowed_Country
INSERT INTO EXW_dbo.EXW_Staking_Allowed_Country
```

## Note on Current Data State

All StakingAllowed values are currently 0. ETH staking was discontinued; no country/crypto combination currently has SelectedValue='true' in EXW_Settings for staking. The table schema is preserved for operational readiness.
