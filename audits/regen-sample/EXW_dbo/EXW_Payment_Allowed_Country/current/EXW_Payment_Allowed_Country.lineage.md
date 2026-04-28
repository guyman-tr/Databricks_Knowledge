---
object: EXW_dbo.EXW_Payment_Allowed_Country
type: Table
batch: 9
---

# EXW_Payment_Allowed_Country — Column Lineage

> All three Allowed_Country tables (Staking, Payment, Conversion) are written by the same SP: `EXW_dbo.SP_EXW_WalletElligibleCountries`.

| DWH Column | Source Column | Source Object | Transform | Tier |
|-----------|---------------|---------------|-----------|------|
| CountryID | CountryID | `DWH_dbo.Dim_Country` | Enumerated from Dim_Country — all countries with EXW_Settings payment rules | Tier 2 |
| Country | Name | `DWH_dbo.Dim_Country` | Dim_Country.Name text label | Tier 2 |
| StateProvince | Name | `DWH_dbo.Dim_State_and_Province` | For US states (CountryID=219): state name; NULL for other countries | Tier 3 |
| RegionByIP_ID | RegionByIP_ID | `DWH_dbo.Dim_State_and_Province` | For US states: RegionByIP_ID; NULL for other countries | Tier 3 |
| CryptoID | — | Derived from EXW_Settings ResourceName path | Numeric crypto identifier extracted from ResourceName pattern | Tier 3 |
| Crypto | — | Crypto dimension (no upstream wiki) | Crypto name text joined from crypto lookup | Tier 3 |
| AllowedUserResource | ResourceName | `EXW_Settings` (user-level payment setting) | ResourceName for user-level payment eligibility | Tier 2 |
| AllowedUserTagType | TagType | `EXW_Settings` (user-level) | Tag type for user-level payment setting resolution | Tier 2 |
| AllowedUserTagValue | TagValue | `EXW_Settings` (user-level) | Tag value matched for user-level payment setting | Tier 2 |
| AllowedUserSelectedValue | SelectedValue | `EXW_Settings` (user-level) | Raw resolved value ('true'/'false') for user-level payment eligibility | Tier 2 |
| CryptosResourceName | ResourceName | `EXW_Settings` (crypto-level payment setting) | ResourceName for crypto-level payment eligibility | Tier 2 |
| CryptosTagType | TagType | `EXW_Settings` (crypto-level) | Tag type for crypto-level payment setting resolution | Tier 2 |
| CryptosTagValue | TagValue | `EXW_Settings` (crypto-level) | Tag value matched for crypto-level payment setting | Tier 2 |
| CryptosSelectedValue | SelectedValue | `EXW_Settings` (crypto-level) | Raw resolved value ('true'/'false') for crypto-level payment eligibility | Tier 2 |
| PaymentAllowed | — | Computed | `CASE WHEN AllowedUserSelectedValue = 'true' AND CryptosSelectedValue = 'true' THEN 1 ELSE 0` — currently always 0 (Simplex payments discontinued) | Tier 2 |
| UpdateDate | — | SP_EXW_WalletElligibleCountries | `GETDATE()` at insert time | Tier 2 |

## ETL Pipeline

```
DWH_dbo.Dim_Country + Dim_State_and_Province → CountryID, Country, StateProvince, RegionByIP_ID

EXW_Settings (user-level payment resource, domain='wallet')
  └─ Priority-weighted tag resolution → AllowedUser* columns

EXW_Settings (crypto-level payment resource, domain='wallet')
  └─ Priority-weighted tag resolution → Cryptos* columns

Crypto dimension → CryptoID, Crypto

PaymentAllowed = AllowedUserSelectedValue='true' AND CryptosSelectedValue='true'

TRUNCATE TABLE EXW_dbo.EXW_Payment_Allowed_Country
INSERT INTO EXW_dbo.EXW_Payment_Allowed_Country
```

## Note on Current Data State

All PaymentAllowed values are currently 0. Simplex crypto payments were discontinued; no country/crypto combination currently satisfies both user and crypto eligibility conditions in EXW_Settings.
