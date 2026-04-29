# Lineage: BI_DB_dbo.BI_DB_TIN_Gap

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object** | BI_DB_TIN_Gap |
| **Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_TIN_Gap (author: Adi Meidan) |
| **Primary Source** | External_Bi_Output_Uploads_TIN_Gaps_Freeze6 (frozen base population) |
| **Secondary Source** | External_UserApiDB_Customer_ExtendedUserField (FieldId=6, TIN data) |
| **Tertiary Sources** | DWH_dbo.Dim_Customer, Dim_Country, V_Liabilities, BI_DB_PositionPnL, Fact_CustomerAction |
| **UC Target** | _Not_Migrated |

## ETL Chain

```
External_Bi_Output_Uploads_TIN_Gaps_Freeze6 (frozen base population)
  - EXCEPT Google Sheet exclusion list CIDs
  + External_UserApiDB_Customer_ExtendedUserField (FieldId=6 — TIN values)
  |-- classify gap type: No TIN / TIN Not Valid / TIN_Null_With_Reason / Done
  |-- pivot up to 3 tax countries per CID into flat columns
  + DWH_dbo.Dim_Customer (email, GCID, language, player status, level, regulation, AM, pending closure)
  + DWH_dbo.Dim_Country (KYC country name, tax country names)
  + DWH_dbo.V_Liabilities (RealizedEquity)
  + BI_DB_dbo.BI_DB_PositionPnL (open positions count)
  + DWH_dbo.Fact_CustomerAction (trading activity last 12 months)
  + last login date
  |-- SP_TIN_Gap (TRUNCATE + INSERT, no @Date — uses GETDATE()-1) ---|
  v
BI_DB_dbo.BI_DB_TIN_Gap (335K rows — TIN Gap remediation population)
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | CID | External_Bi_Output_Uploads_TIN_Gaps_Freeze6 | CID | Base population key; passthrough | Tier 1 |
| 2 | GCID | DWH_dbo.Dim_Customer | GCID | JOIN on CID; passthrough | Tier 1 |
| 3 | Email | DWH_dbo.Dim_Customer | Email | JOIN on CID; passthrough | Tier 1 |
| 4 | Client Language | DWH_dbo.Dim_Customer | Language | JOIN on CID; passthrough | Tier 1 |
| 5 | KYC_Country | DWH_dbo.Dim_Country | Name | JOIN Dim_Customer.CountryID to Dim_Country; resolved name | Tier 1 |
| 6 | TaxCountry_1 | DWH_dbo.Dim_Country | Name | Pivoted first tax country name from ExtendedUserField | Tier 1 |
| 7 | TaxCountry_2 | DWH_dbo.Dim_Country | Name | Pivoted second tax country name | Tier 1 |
| 8 | TaxCountry_3 | DWH_dbo.Dim_Country | Name | Pivoted third tax country name | Tier 1 |
| 9 | TaxCode_1 | External_UserApiDB_Customer_ExtendedUserField | FieldValue (FieldId=6) | Pivoted first TIN code from ExtendedUserField | Tier 2 |
| 10 | TaxCode_2 | External_UserApiDB_Customer_ExtendedUserField | FieldValue (FieldId=6) | Pivoted second TIN code | Tier 2 |
| 11 | TaxCode_3 | External_UserApiDB_Customer_ExtendedUserField | FieldValue (FieldId=6) | Pivoted third TIN code | Tier 2 |
| 12 | NoTIN_Reason1 | External_UserApiDB_Customer_ExtendedUserField | CRS reason field | Pivoted first CRS no-TIN reason | Tier 2 |
| 13 | NoTIN_Reason2 | External_UserApiDB_Customer_ExtendedUserField | CRS reason field | Pivoted second CRS no-TIN reason | Tier 2 |
| 14 | NoTIN_Reason3 | External_UserApiDB_Customer_ExtendedUserField | CRS reason field | Pivoted third CRS no-TIN reason | Tier 2 |
| 15 | Player_Status | DWH_dbo.Dim_PlayerStatus | Name | JOIN Dim_Customer.PlayerStatusID to Dim_PlayerStatus; resolved name | Tier 1 |
| 16 | Account Manager | DWH_dbo.Dim_Customer | AccountManager | JOIN on CID; passthrough | Tier 2 |
| 17 | Group | SP_TIN_Gap | computed | CASE logic: A/B1/B2/B3/C based on positions, equity, activity, club | Tier 2 |
| 18 | Club | DWH_dbo.Dim_PlayerLevel | Name | JOIN Dim_Customer.PlayerLevelID to Dim_PlayerLevel; resolved name | Tier 1 |
| 19 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN Dim_Customer.RegulationID; resolved short code | Tier 1 |
| 20 | Open Positions | BI_DB_dbo.BI_DB_PositionPnL | PositionID | COUNT of open positions per CID | Tier 2 |
| 21 | RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | Passthrough per CID | Tier 2 |
| 22 | Ind_1 | SP_TIN_Gap | computed | Gap indicator for first tax country: '1' = resolved, gap type otherwise | Tier 2 |
| 23 | Ind_2 | SP_TIN_Gap | computed | Gap indicator for second tax country | Tier 2 |
| 24 | Ind_3 | SP_TIN_Gap | computed | Gap indicator for third tax country | Tier 2 |
| 25 | Ind_Done | SP_TIN_Gap | computed | 1 if all three Ind columns = '1'; 0 otherwise | Tier 2 |
| 26 | UpdateDate | SP_TIN_Gap | GETDATE() | ETL timestamp at insert time | Tier 5 |
| 27 | PendingClosureStatusName | DWH_dbo.Dim_Customer | PendingClosureStatusName | JOIN on CID; passthrough | Tier 2 |
| 28 | LastLoggedIn | DWH_dbo.Dim_Customer / login source | LastLoggedIn | Last login timestamp | Tier 2 |
| 29 | Annual Income_KYC | DWH_dbo.Dim_Customer | AnnualIncome (KYC field) | KYC-declared annual income; passthrough | Tier 2 |
| 30 | Lifetime Deposits | DWH_dbo.Fact_CustomerAction or V_Liabilities | Lifetime deposit sum | Total lifetime deposits for the customer | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 10 | CID, GCID, Email, Client Language, KYC_Country, TaxCountry_1/2/3, Player_Status, Club, Regulation |
| Tier 2 | 19 | TaxCode_1/2/3, NoTIN_Reason1/2/3, Account Manager, Group, Open Positions, RealizedEquity, Ind_1/2/3, Ind_Done, PendingClosureStatusName, LastLoggedIn, Annual Income_KYC, Lifetime Deposits |
| Tier 5 | 1 | UpdateDate |

## Source Tables Referenced

| Source Object | Type | Role |
|---------------|------|------|
| External_Bi_Output_Uploads_TIN_Gaps_Freeze6 | External Table | Frozen base population for TIN gap remediation |
| External_UserApiDB_Customer_ExtendedUserField | External Table | TIN values and CRS reason codes (FieldId=6) |
| DWH_dbo.Dim_Customer | Table | Customer attributes: email, GCID, language, player status, regulation, account manager, pending closure |
| DWH_dbo.Dim_Country | Table | Country name resolution for KYC and tax countries |
| DWH_dbo.Dim_PlayerStatus | Table | Player status name lookup |
| DWH_dbo.Dim_PlayerLevel | Table | Club tier name lookup |
| DWH_dbo.Dim_Regulation | Table | Regulation short code lookup |
| DWH_dbo.V_Liabilities | View | RealizedEquity per customer |
| BI_DB_dbo.BI_DB_PositionPnL | Table | Open positions count per CID |
| DWH_dbo.Fact_CustomerAction | Table | Trading activity last 12 months (for Group classification) |
| Google Sheet exclusion list | External | CIDs excluded from base population |
