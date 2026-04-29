# BI_DB_dbo.BI_DB_QTFN_Report — Column Lineage

> Generated: 2026-04-26 | Pipeline Phase: 10B | Writer SP: SP_QTFN_Report

## ETL Chain

```
DWH_dbo.Dim_Customer (GCID, RealCID, FirstName, LastName, MiddleName, Address, City, Zip,
                       BirthDate, BuildingNumber, RegisteredReal, FirstDepositDate, IsDepositor,
                       RegulationID, PlayerStatusID, CountryID, PlayerLevelID, AccountTypeID, RegionID)
BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6, CountryId=12 → TFN)
BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType (Tax type name)
DWH_dbo.Dim_Regulation (RegulationID → Name)
DWH_dbo.Dim_PlayerStatus (PlayerStatusID → Name)
DWH_dbo.Dim_Country (CountryID → Name)
DWH_dbo.Dim_PlayerLevel (PlayerLevelID → Name)
DWH_dbo.Dim_AccountType (AccountTypeID → Name)
DWH_dbo.Dim_State_and_Province (RegionByIP_ID → State name + abbreviation)
BI_DB_dbo.BI_DB_CIDFirstDates (VerificationLevel3Date, UserName)
  |
  |-- SP_QTFN_Report ---|
  |   TRUNCATE BI_DB_QTFN_Report
  |   INSERT: ASIC-regulated (RegulationID IN 4,10), VL3 (VerificationLevelID=3),
  |           TaxCountry=Australia (CountryID=12)
  |   Entity type classification: I/S/C/Other from AccountTypeID
  |   TFN/ABN conditional logic by entity type
  |   State abbreviation mapping (130+ CASE entries)
  |   Postcode stripping (letters, dashes, spaces removed)
  v
BI_DB_dbo.BI_DB_QTFN_Report (225,393 rows, 1 row per GCID, single snapshot)
  |
  |-- UC Target: _Not_Migrated (not in Generic Pipeline mapping)
```

## Source Objects

| # | Source Object | Columns Used | Join / Filter |
|---|-------------|--------------|---------------|
| 1 | DWH_dbo.Dim_Customer | GCID, RealCID, FirstName, LastName, MiddleName, Address, City, Zip, BirthDate, BuildingNumber, RegisteredReal, FirstDepositDate, IsDepositor, RegulationID, PlayerStatusID, CountryID, PlayerLevelID, AccountTypeID, RegionID | Main source; RegulationID IN (4,10), VerificationLevelID=3 |
| 2 | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | FieldId, CountryId, Value | FieldId=6, CountryId=12 (Australia TFN) |
| 3 | BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType | Name | Tax type name lookup |
| 4 | DWH_dbo.Dim_Regulation | Name | RegulationID join |
| 5 | DWH_dbo.Dim_PlayerStatus | Name | PlayerStatusID join |
| 6 | DWH_dbo.Dim_Country | Name | CountryID join (for Country_fin and TaxCountry) |
| 7 | DWH_dbo.Dim_PlayerLevel | Name | PlayerLevelID join |
| 8 | DWH_dbo.Dim_AccountType | Name, AccountTypeID | AccountTypeID join |
| 9 | DWH_dbo.Dim_State_and_Province | Name | RegionByIP_ID join → state abbreviation CASE |
| 10 | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date, UserName | CID join |

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | Recordlen | Constant | — | Always 594. Fixed ATO record length. | Tier 2 — SP_QTFN_Report |
| 2 | RecordID | Constant | — | Always 'DINVESTOR'. Fixed ATO record type identifier. | Tier 2 — SP_QTFN_Report |
| 3 | Investment_reference_number | DWH_dbo.Dim_Customer | RealCID | CID (RealCID) as investment reference. | Tier 2 — SP_QTFN_Report |
| 4 | Len_CID | DWH_dbo.Dim_Customer | RealCID | LEN(CID). Helper for CID padding. | Tier 2 — SP_QTFN_Report |
| 5 | Padded_CID | DWH_dbo.Dim_Customer | RealCID | '[' + CID padded to 25 chars + ']'. Formatted for ATO submission. | Tier 2 — SP_QTFN_Report |
| 6 | Customer_reference_number | Constant | — | Always ' ' (space). ATO placeholder. | Tier 2 — SP_QTFN_Report |
| 7 | BSB_Number | Constant | — | Always ' ' (space). Bank-State-Branch placeholder. | Tier 2 — SP_QTFN_Report |
| 8 | Branch_location | Constant | — | Always ' ' (space). Branch location placeholder. | Tier 2 — SP_QTFN_Report |
| 9 | Investor_entity_type | DWH_dbo.Dim_AccountType | AccountTypeID | CASE: 'I' if AccountTypeID IN (1,6), 'S' if 14, 'C' if IN (2,15), else 'Other'. | Tier 2 — SP_QTFN_Report |
| 10 | Investor_Tax_file_number_fin | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Value (FieldId=6, CountryId=12) | TFN for individuals; '987654321' for S/C entities. | Tier 2 — SP_QTFN_Report |
| 11 | Investor_Australian_business_number | Computed | AccountTypeID | '00000000000' for individuals; 'ABN' for S/C; 'Other' for other. | Tier 2 — SP_QTFN_Report |
| 12 | Account_name_fin | DWH_dbo.Dim_Customer | FirstName, MiddleName, LastName | CONCAT(FirstName, ' ', MiddleName, ' ', LastName). | Tier 2 — SP_QTFN_Report |
| 13 | Investor_surname | DWH_dbo.Dim_Customer | LastName | LastName for individuals; space for S/C entities. | Tier 2 — SP_QTFN_Report |
| 14 | First_given_name_fin | DWH_dbo.Dim_Customer | FirstName | FirstName for individuals; space for S/C entities. | Tier 2 — SP_QTFN_Report |
| 15 | Second_given_name_fin | DWH_dbo.Dim_Customer | MiddleName | MiddleName for individuals; space for S/C entities. | Tier 2 — SP_QTFN_Report |
| 16 | Date_of_birth | DWH_dbo.Dim_Customer | BirthDate | FORMAT(BirthDate, 'ddMMyyyy') for individuals; space for S/C. Zero-padded if 7 chars. | Tier 2 — SP_QTFN_Report |
| 17 | Filler | Constant | — | Always ' ' (space). ATO format alignment placeholder. | Tier 2 — SP_QTFN_Report |
| 18 | Non_individual_investor_name | Computed | AccountTypeID, Account_name_fin | Account_name_fin for S/C entities; space for individuals; 'Other' for other. | Tier 2 — SP_QTFN_Report |
| 19 | Investor_address_line_1_fin | DWH_dbo.Dim_Customer | BuildingNumber, Address | CONCAT(BuildingNumber, ' ', Address). | Tier 2 — SP_QTFN_Report |
| 20 | Investor_address_line_2_fin | Constant | — | Always ' ' (space). | Tier 2 — SP_QTFN_Report |
| 21 | Suburb_town_or_city | DWH_dbo.Dim_Customer | City | City from Dim_Customer. | Tier 2 — SP_QTFN_Report |
| 22 | State_or_territory | DWH_dbo.Dim_State_and_Province | Name | State abbreviation via 130+ entry CASE mapping from full state name. | Tier 2 — SP_QTFN_Report |
| 23 | Postcode | DWH_dbo.Dim_Customer | Zip | Zip with all letters, dashes, and spaces stripped (numeric only). | Tier 2 — SP_QTFN_Report |
| 24 | Len_Postcode | DWH_dbo.Dim_Customer | Zip | LEN(stripped Postcode). Helper for format validation. | Tier 2 — SP_QTFN_Report |
| 25 | Country_fin | DWH_dbo.Dim_Country | Name | Country name (customer's registered country). | Tier 2 — SP_QTFN_Report |
| 26 | State | DWH_dbo.Dim_State_and_Province | Name | Full (unabbreviated) state name from Dim_State_and_Province. | Tier 2 — SP_QTFN_Report |
| 27 | Zip | DWH_dbo.Dim_Customer | Zip | Raw Zip from Dim_Customer (before stripping). | Tier 2 — SP_QTFN_Report |
| 28 | UserName | BI_DB_dbo.BI_DB_CIDFirstDates | UserName | eToro username. | Tier 2 — SP_QTFN_Report |
| 29 | GCID | DWH_dbo.Dim_Customer | GCID | Global Customer ID. | Tier 2 — SP_QTFN_Report |
| 30 | Regulation | DWH_dbo.Dim_Regulation | Name | 'ASIC' or 'ASIC & GAML'. | Tier 2 — SP_QTFN_Report |
| 31 | PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Player status name. | Tier 2 — SP_QTFN_Report |
| 32 | Club | DWH_dbo.Dim_PlayerLevel | Name | Club tier name. | Tier 2 — SP_QTFN_Report |
| 33 | AccountType | DWH_dbo.Dim_AccountType | Name | Account type name. | Tier 2 — SP_QTFN_Report |
| 34 | RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Registration date. | Tier 2 — SP_QTFN_Report |
| 35 | FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | First deposit date. | Tier 2 — SP_QTFN_Report |
| 36 | IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Depositor flag. | Tier 2 — SP_QTFN_Report |
| 37 | VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | Date customer reached VL3 verification. | Tier 2 — SP_QTFN_Report |
| 38 | TaxCountry | DWH_dbo.Dim_Country | Name (CountryID=12) | Always 'Australia'. Joined via CountryID=12 filter. | Tier 2 — SP_QTFN_Report |
| 39 | UpdateDate | ETL system | GETDATE() | ETL timestamp at INSERT. | Tier 2 — SP_QTFN_Report |

## UC External Lineage

| UC Target | `_Not_Migrated` (not in Generic Pipeline mapping) |
|-----------|---|
