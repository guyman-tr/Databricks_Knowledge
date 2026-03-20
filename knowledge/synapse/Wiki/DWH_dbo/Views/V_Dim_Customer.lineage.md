# Column Lineage — DWH_dbo.V_Dim_Customer

## Source Mapping

| Target Column | Source | Transformation |
|--------------|--------|----------------|
| Country | Dim_Country.Name | INNER JOIN on Dim_Customer.CountryID = Dim_Country.CountryID |
| Affiliate | Dim_Affiliate.AffiliatesGroupsName | INNER JOIN on AffiliateID |
| Language | Dim_Language.Name | INNER JOIN on LanguageID |
| VerificationLevel | Dim_VerificationLevel.Name | INNER JOIN on VerificationLevelID = ID |
| PlayerStatus | Dim_PlayerStatus.Name | INNER JOIN on PlayerStatusID |
| PlayerLevel | Dim_PlayerLevel.Name | INNER JOIN on PlayerLevelID |
| Regulation | Dim_Regulation.Name | INNER JOIN on RegulationID = ID |
| BirthDate, RegisteredReal, etc. | Dim_Customer (datetime) | `CONVERT(VARCHAR(50), ..., 121)` — ODBC canonical |
| DocsOK, Bankruptcy, etc. | Dim_Customer (bit/int) | `CAST(... AS VARCHAR(10))` |
| FirstDepositAmount | Dim_Customer | `CAST(... AS DECIMAL(19,4))` |
| Remaining ~74 columns | Dim_Customer | Direct passthrough |
