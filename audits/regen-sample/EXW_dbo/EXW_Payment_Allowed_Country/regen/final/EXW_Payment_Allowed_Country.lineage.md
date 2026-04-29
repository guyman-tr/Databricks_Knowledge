# Lineage: EXW_dbo.EXW_Payment_Allowed_Country

## Source Objects

| Source Object | Source Type | Relationship | Schema |
|---------------|------------|--------------|--------|
| DWH_dbo.Dim_Country | Table | JOIN (CountryID) | DWH_dbo |
| DWH_dbo.Dim_State_and_Province | Table | LEFT JOIN (CountryID, US-only) | DWH_dbo |
| EXW_Wallet.CryptoTypes | Table | CROSS APPLY (active cryptos) | EXW_Wallet |
| EXW_Settings.Resources | Table | JOIN (ResourceId) | EXW_Settings |
| EXW_Settings.SystemRestrictions | Table | JOIN (ResourceId → RestrictionId) | EXW_Settings |
| EXW_Settings.Tags | Table | JOIN (TagId) | EXW_Settings |
| CopyFromLake.SettingsDB_Dictionary_CountryGroup | Table | JOIN (CountryGroupID) | CopyFromLake |
| CopyFromLake.SettingsDB_Dictionary_CountryToCountryGroup | Table | JOIN (CountryID) | CopyFromLake |
| DWH_dbo.Dim_Regulation | Table | CROSS APPLY (non-zero regulations) | DWH_dbo |
| EXW_dbo.SP_EXW_WalletElligibleCountries | Stored Procedure | Writer SP (TRUNCATE+INSERT) | EXW_dbo |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|---------------|--------------|---------------|-----------|------|
| CountryID | DWH_dbo.Dim_Country | CountryID | Passthrough via dim-lookup | Tier 1 — Dictionary.Country |
| Country | DWH_dbo.Dim_Country | Name | Rename (Name → Country) via dim-lookup | Tier 1 — Dictionary.Country |
| StateProvince | DWH_dbo.Dim_State_and_Province | Name | CASE WHEN CountryID=219 THEN p.Name ELSE NULL END | Tier 2 — SP_EXW_WalletElligibleCountries |
| RegionByIP_ID | DWH_dbo.Dim_State_and_Province | RegionByIP_ID | CASE WHEN CountryID=219 THEN p.RegionByIP_ID ELSE NULL END; ISNULL(...,0) | Tier 2 — SP_EXW_WalletElligibleCountries |
| CryptoID | EXW_Wallet.CryptoTypes | CryptoID | Passthrough (active cryptos only, via CROSS APPLY) | Tier 2 — SP_EXW_WalletElligibleCountries |
| Crypto | EXW_Wallet.CryptoTypes | Name | Rename (Name → Crypto), active cryptos only | Tier 2 — SP_EXW_WalletElligibleCountries |
| AllowedUserResource | EXW_Settings.Resources | ResourceName | Resolved via max RestrictionWeight tag-matching logic; COALESCE(cryptoID-level, category-level) | Tier 2 — SP_EXW_WalletElligibleCountries |
| AllowedUserTagType | EXW_Settings.Tags | TagType | Resolved via max RestrictionWeight tag-matching logic; COALESCE(cryptoID-level, category-level) | Tier 2 — SP_EXW_WalletElligibleCountries |
| AllowedUserTagValue | EXW_Settings.Tags | TagValue | Resolved via max RestrictionWeight tag-matching logic; COALESCE(cryptoID-level, category-level) | Tier 2 — SP_EXW_WalletElligibleCountries |
| AllowedUserSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Resolved via max RestrictionWeight tag-matching logic; COALESCE(cryptoID-level, category-level) | Tier 2 — SP_EXW_WalletElligibleCountries |
| CryptosResourceName | EXW_Settings.Resources | ResourceName | Resolved via max RestrictionWeight for cryptos/N/allowedPayment resource | Tier 2 — SP_EXW_WalletElligibleCountries |
| CryptosTagType | EXW_Settings.Tags | TagType | Resolved via max RestrictionWeight for cryptos/N/allowedPayment resource | Tier 2 — SP_EXW_WalletElligibleCountries |
| CryptosTagValue | EXW_Settings.Tags | TagValue | Resolved via max RestrictionWeight for cryptos/N/allowedPayment resource | Tier 2 — SP_EXW_WalletElligibleCountries |
| CryptosSelectedValue | EXW_Settings.SystemRestrictions | SelectedValue | Resolved via max RestrictionWeight for cryptos/N/allowedPayment resource | Tier 2 — SP_EXW_WalletElligibleCountries |
| PaymentAllowed | EXW_Settings.SystemRestrictions | SelectedValue (both domains) | CASE WHEN AllowedUser='true' AND Cryptos='true' THEN 1 ELSE 0 END | Tier 2 — SP_EXW_WalletElligibleCountries |
| UpdateDate | — | — | GETDATE() at ETL execution time | Tier 2 — SP_EXW_WalletElligibleCountries |
