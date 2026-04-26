# BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard — Column Lineage

## Writer SP

`BI_DB_dbo.SP_Monthly_InterestPayment_Dashboard` (@Date DATE)
Author: Adi Meidan, 2024-04-03. Changed: Lior Ben Dor (date parameter).

## Load Pattern

Monthly DELETE+INSERT by MonthOfInterest = @StartOfMonth (first day of prior month).

## Source Objects

| # | Source Object | Alias | Role |
|---|---------------|-------|------|
| 1 | BI_DB_dbo.BI_DB_InterestMonthly | i | Primary — monthly interest records (filtered to @StartOfMonth) |
| 2 | BI_DB_dbo.BI_DB_InterestDaily | id | AccountTypeID by CID+month (MAX aggregation) |
| 3 | DWH_dbo.Dim_Regulation | dr | Lookup — regulation attributes |
| 4 | DWH_dbo.Dim_Customer | dc | Customer PII and demographics |
| 5 | DWH_dbo.Dim_Country | dc1 | Country, Region (MarketingRegionManualName), Desk |
| 6 | DWH_dbo.Dim_AccountType | dat | Account type attributes |
| 7 | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | cex | Tax info (FieldId=6) |
| 8 | BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType | dex | Tax type name |
| 9 | BI_DB_dbo.External_UserApiDB_KYC_CountryTaxType | ct | Country tax requirement type |
| 10 | BI_DB_dbo.External_UserApiDB_Dictionary_MandatoryType | mt | Mandatory type for tax |
| 11 | BI_DB_dbo.External_UserApiDB_Dictionary_NationalPinValueTypeToReportType | nptr/npt | Tax report type filter (NationalPinReportTypeID <> 3) |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|----------------|-------------|---------------|-----------|
| 1 | CID | BI_DB_InterestMonthly | CID | Passthrough |
| 2 | RegulationID | BI_DB_InterestMonthly | RegulationID | Passthrough |
| 3 | StatusID | BI_DB_InterestMonthly | StatusID | Passthrough (always 3) |
| 4 | MonthOfInterest | BI_DB_InterestMonthly | MonthOfInterest | Passthrough |
| 5 | MonthlyAccumulatedInterest | BI_DB_InterestMonthly | MonthlyAccumulatedInterest | Passthrough |
| 6 | TaxPercentage | BI_DB_InterestMonthly | TaxPercentage | Passthrough |
| 7 | FinalTaxedlnterest | BI_DB_InterestMonthly | FinalTaxedlnterest | Passthrough (typo inherited) |
| 8 | ValidFrom | BI_DB_InterestMonthly | ValidFrom | Passthrough |
| 9 | ID | Dim_Regulation | ID | Passthrough (joined on RegulationID=DWHRegulationID) |
| 10 | Name | Dim_Regulation | Name | Passthrough |
| 11 | DWHRegulationID | Dim_Regulation | DWHRegulationID | Passthrough |
| 12 | StatusID_Dim_Regulation | Dim_Regulation | StatusID | Passthrough (aliased) |
| 13 | InsertDate | Dim_Regulation | InsertDate | Passthrough |
| 14 | ClusterRegulationID | Dim_Regulation | ClusterRegulationID | Passthrough |
| 15 | RealCID | Dim_Customer | RealCID | Passthrough (joined on dc.RealCID=i.CID) |
| 16 | Country | Dim_Country | Name | Rename: Dim_Country.Name → Country |
| 17 | Region | Dim_Country | MarketingRegionManualName | Rename |
| 18 | Desk | Dim_Country | Desk | Passthrough |
| 19 | RealCID_Custom_SQL_Query1 | BI_DB_InterestMonthly | CID | Duplicate of CID (Tableau artifact) |
| 20 | FirstName | Dim_Customer | FirstName | Passthrough (MASKED) |
| 21 | LastName | Dim_Customer | LastName | Passthrough (MASKED) |
| 22 | MiddleName | Dim_Customer | MiddleName | Passthrough |
| 23 | Name_Custom_SQL_Query1 | Dim_Customer | FirstName + ' ' + LastName | Concatenation (MASKED) |
| 24 | UserName | Dim_Customer | UserName | Passthrough |
| 25 | BirthDate | Dim_Customer | BirthDate | Passthrough |
| 26 | City | Dim_Customer | City | Passthrough (MASKED) |
| 27 | Address | Dim_Customer | Address | Passthrough (MASKED) |
| 28 | Zip | Dim_Customer | Zip | Passthrough (MASKED) |
| 29 | AccountTypeID | BI_DB_InterestDaily | AccountTypeID | MAX(AccountTypeID) per CID+month |
| 30 | BuildingNumber | Dim_Customer | BuildingNumber | Passthrough (MASKED) |
| 31 | Gender | Dim_Customer | Gender | Passthrough |
| 32 | CID_Custom_SQL_Query2 | BI_DB_InterestDaily | CID | Duplicate of CID (Tableau artifact) |
| 33 | Date | BI_DB_InterestDaily | Date | DATEFROMPARTS(YEAR,MONTH,1) of DayOfInterest |
| 34 | AccountTypeID_Custom_SQL_Query2 | BI_DB_InterestDaily | AccountTypeID | Duplicate of AccountTypeID (Tableau artifact) |
| 35 | AccountTypeID_Dim_AccountType | Dim_AccountType | AccountTypeID | Passthrough |
| 36 | Name_Dim_AccountType | Dim_AccountType | Name | Passthrough |
| 37 | DWHAccountTypeID | Dim_AccountType | DWHAccountTypeID | Passthrough |
| 38 | StatusID_Dim_AccountType | Dim_AccountType | StatusID | Passthrough |
| 39 | InsertDate_Dim_AccountType | Dim_AccountType | InsertDate | Passthrough |
| 40 | CID_Custom_SQL_Query1_1 | #tax | CID | Tax CID (duplicate, Tableau artifact) |
| 41 | TaxCountry_Custom_SQL_Query1 | Dim_Country | Name | Tax country resolved from ExtendedUserField.CountryId |
| 42 | TaxID | External_UserApiDB_Customer_ExtendedUserField | Value | FieldId=6 tax identifier |
| 43 | Type | External_UserApiDB_Dictionary_ExtendedUserValueType | Name | Tax value type name |
| 44 | CID_Custom_SQL_Query1_2 | #TaxRequirement | CID | Tax requirement CID (duplicate, Tableau artifact) |
| 45 | TaxRequirement_Custom_SQL_Query1 | External_UserApiDB_Dictionary_ExtendedUserValueType | Name | Tax requirement type (via CountryTaxType + MandatoryType + NationalPinValueTypeToReportType) |
| 46 | UpdateDate | ETL | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
Interest.Trade.InterestMonthly (production)
  |-- Generic Pipeline (Bronze) ---|
  v
BI_DB_dbo.BI_DB_InterestMonthly (9 cols)
  + BI_DB_dbo.BI_DB_InterestDaily (AccountTypeID)
  + DWH_dbo.Dim_Regulation (regulation attrs)
  + DWH_dbo.Dim_Customer (PII, demographics)
  + DWH_dbo.Dim_Country (country, region, desk)
  + DWH_dbo.Dim_AccountType (account type attrs)
  + External_UserApiDB (tax fields)
  |-- SP_Monthly_InterestPayment_Dashboard @Date ---|
  v
BI_DB_dbo.BI_DB_Monthly_InterestPayment_Dashboard (10.8M rows)
  UC Target: _Not_Migrated
```
