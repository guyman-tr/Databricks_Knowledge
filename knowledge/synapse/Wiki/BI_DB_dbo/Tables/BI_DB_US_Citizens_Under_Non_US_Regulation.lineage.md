# BI_DB_dbo.BI_DB_US_Citizens_Under_Non_US_Regulation — Column Lineage

## Source Objects

| Source Object | Type | Role |
|---|---|---|
| DWH_dbo.Dim_Customer | Table | Primary — customer attributes, POB, regulation, verification |
| DWH_dbo.Dim_Country | Table | KYC country name + country-level regulation |
| DWH_dbo.Dim_PlayerStatus | Table | Player status name |
| DWH_dbo.Dim_Regulation | Table | Regulation name (current, designated, country-level) |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | LastLoggedIn, VerificationLevel3Date |
| BI_DB_dbo.BI_DB_Tax_Compliance_TIN | Table | TIN country detection (TIN_CountryID=219) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---|---|---|---|
| CID | Dim_Customer | RealCID | COALESCE(POB.RealCID, TIN.RealCID) |
| LastLoggedIn | BI_DB_CIDFirstDates | LastLoggedIn | COALESCE(POB side, TIN side) |
| VerificationLevel3Date | BI_DB_CIDFirstDates | VerificationLevel3Date | COALESCE(POB side, TIN side) |
| PlayerStatus | Dim_PlayerStatus | Name | JOIN on PlayerStatusID, COALESCE |
| CurrentRegulation | Dim_Regulation | Name | JOIN on RegulationID, COALESCE |
| DesignatedRegulation | Dim_Regulation | Name | JOIN on DesignatedRegulationID, COALESCE |
| POB | Derived | — | 'Yes' if POBCountryID=219, 'No' otherwise |
| TaxCountry | Derived | — | 'Yes' if TIN_CountryID=219, 'No' otherwise |
| DateRelevance | Derived | @Date | Date when customer was first detected |
| UpdateDate | ETL | GETDATE() | Insert timestamp |
| Designated_Regulation_DB | Dim_Regulation | Name | JOIN on Dim_Country.RegulationID (country-level regulation) |
| KYC_Country | Dim_Country | Name | JOIN on CountryID |

## Lineage Notes

- **Two detection paths**: POB (Place of Birth = USA, CountryID=219) and TIN (US TIN from Tax_Compliance_TIN). FULL OUTER JOIN combines both.
- **Accumulation pattern**: Only NEW customers (not already in the table) are inserted. Existing CIDs are excluded via LEFT JOIN anti-pattern (WHERE u.CID IS NULL).
- **Exclusion filter**: RegulationID NOT IN (6,7,8,12) — excludes customers already under US regulations (FinCEN, FINRA, NYDFS, etc.). The goal is to find US citizens under non-US regulation.
