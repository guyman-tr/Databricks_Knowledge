# BI_DB_dbo.BI_DB_QTFN_Report

> 225,393-row Australian ASIC Tax File Number (TFN) compliance report table containing one row per GCID for ASIC-regulated customers (RegulationID IN 4,10) at VerificationLevel 3 with TaxCountry=Australia. Contains PII (name, address, DOB, TFN). Populated by SP_QTFN_Report via TRUNCATE+INSERT (full refresh, single snapshot). Formatted for ATO (Australian Taxation Office) electronic lodgement with fixed-length record fields, entity type classification, and state abbreviation mapping.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField + dimension lookups via SP_QTFN_Report |
| **Refresh** | Full refresh (TRUNCATE + INSERT). Single snapshot, last refresh 2026-04-13. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **Row Count** | 225,393 rows (1 row per GCID) |

---

## 1. Business Meaning

`BI_DB_QTFN_Report` is an Australian Tax Office (ATO) Quarterly Tax File Number (QTFN) compliance report table. It contains one row per ASIC-regulated customer who has reached Verification Level 3 and whose tax country is Australia (CountryID=12). The table is structured to conform to the ATO electronic lodgement format with fixed record lengths (594 bytes), fixed record type identifiers ('DINVESTOR'), and padded CID fields.

The population filter is: RegulationID IN (4=ASIC, 10=ASIC & GAML), VerificationLevelID=3, and TaxCountry=Australia. This yields 225,393 distinct GCIDs as of the last refresh.

The table classifies each customer into an investor entity type: Individual (AccountTypeID IN 1,6), SMSF/Self-Managed Super Fund (AccountTypeID=14), Corporate (AccountTypeID IN 2,15), or Other. PII fields (name, address, DOB) are populated for individuals but replaced with spaces for non-individual entities (S/C). TFN is sourced from the UserApiDB extended user fields for individuals; non-individuals receive a placeholder value ('987654321').

This table contains **PII data**: FirstName, LastName, MiddleName, Address, City, Zip, BirthDate, and Tax File Number. Access should be restricted to authorized compliance and finance personnel.

---

## 2. Business Logic

### 2.1 Investor Entity Type Classification

**What**: Classifies each customer into an ATO investor entity type based on their AccountTypeID.
**Columns Involved**: Investor_entity_type, and conditionally: Investor_Tax_file_number_fin, Investor_Australian_business_number, Investor_surname, First_given_name_fin, Second_given_name_fin, Date_of_birth, Non_individual_investor_name
**Rules**:
- AccountTypeID IN (1, 6) = 'I' (Individual)
- AccountTypeID = 14 = 'S' (SMSF — Self-Managed Superannuation Fund)
- AccountTypeID IN (2, 15) = 'C' (Corporate)
- All other AccountTypeIDs = 'Other'

### 2.2 TFN and ABN Conditional Logic

**What**: Populates Tax File Number and Australian Business Number fields differently based on entity type.
**Columns Involved**: Investor_Tax_file_number_fin, Investor_Australian_business_number
**Rules**:
- **Individuals (I)**: TFN sourced from External_UserApiDB_Customer_ExtendedUserField (FieldId=6, CountryId=12). ABN = '00000000000' (placeholder zeros).
- **SMSF/Corporate (S/C)**: TFN = '987654321' (fixed placeholder). ABN = 'ABN' (literal text placeholder).
- **Other**: ABN = 'Other'. TFN handling follows default.

### 2.3 PII Masking for Non-Individual Entities

**What**: Non-individual entities (S, C) have personal name and DOB fields replaced with spaces to avoid exposing irrelevant PII.
**Columns Involved**: Investor_surname, First_given_name_fin, Second_given_name_fin, Date_of_birth
**Rules**:
- Individual (I): full PII from Dim_Customer (LastName, FirstName, MiddleName, FORMAT(BirthDate, 'ddMMyyyy'))
- S/C entities: all set to ' ' (space)
- Non_individual_investor_name: Account_name_fin for S/C; space for I; 'Other' for Other

### 2.4 State Abbreviation Mapping

**What**: Maps full state/province names from Dim_State_and_Province to Australian state abbreviations via a massive CASE statement (130+ entries).
**Columns Involved**: State_or_territory, State
**Rules**:
- State_or_territory receives the abbreviated form (e.g., 'NSW', 'VIC', 'QLD')
- State retains the full unabbreviated name
- Source: Dim_State_and_Province joined via Dim_Customer.RegionByIP_ID

### 2.5 Postcode Stripping

**What**: Removes all non-numeric characters from the raw Zip to produce a numeric-only postcode for ATO format compliance.
**Columns Involved**: Postcode, Len_Postcode, Zip
**Rules**:
- Postcode = Zip with all letters, dashes, and spaces removed
- Len_Postcode = LEN(stripped Postcode) — helper for format validation
- Zip retains the original unstripped value

### 2.6 ATO Record Format Fields

**What**: Fixed-value fields required by the ATO electronic lodgement specification.
**Columns Involved**: Recordlen, RecordID, Customer_reference_number, BSB_Number, Branch_location, Filler, Investor_address_line_2_fin
**Rules**:
- Recordlen = 594 (fixed ATO record length)
- RecordID = 'DINVESTOR' (fixed record type)
- Customer_reference_number, BSB_Number, Branch_location, Filler, Investor_address_line_2_fin = ' ' (space placeholders)
- Padded_CID = '[' + CID right-padded to 25 characters + ']'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. At 225K rows this table is moderately sized. HEAP is typical for TRUNCATE+INSERT tables (no clustered index maintenance overhead). ROUND_ROBIN distributes evenly across nodes.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| "All individual investors?" | `WHERE Investor_entity_type = 'I'` |
| "SMSF accounts for ATO reporting?" | `WHERE Investor_entity_type = 'S'` |
| "Customers missing TFN?" | `WHERE Investor_Tax_file_number_fin IS NULL OR Investor_Tax_file_number_fin = ''` |
| "Customers in a specific state?" | `WHERE State_or_territory = 'NSW'` |
| "Specific customer by GCID?" | `WHERE GCID = <value>` |
| "Last refresh date?" | `SELECT MAX(UpdateDate)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON GCID | Enrich with additional customer attributes not in this table |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID (Investment_reference_number) | Additional milestone dates |

### 3.4 Gotchas

- **PII table** — contains Tax File Numbers, names, addresses, and dates of birth. Ensure appropriate access controls and do not expose in unsecured reports.
- **TFN placeholder '987654321'** — non-individual entities (S/C) have this dummy TFN. Do not treat as a real TFN. Filter `WHERE Investor_entity_type = 'I'` for real TFN data.
- **ABN field is not a real ABN** — the ABN column contains placeholder values ('00000000000' for individuals, 'ABN' text for S/C). It does not contain actual Australian Business Numbers.
- **Postcode vs Zip** — Postcode is the stripped numeric-only version; Zip is the raw original. Use Postcode for ATO submission, Zip for display.
- **Date_of_birth is int, not date** — stored as ddMMyyyy integer format (e.g., 15031990 = 15 March 1990). Space for non-individuals.
- **TRUNCATE+INSERT** — entire table is replaced on each run. There is no history; only the latest snapshot exists.
- **State_or_territory mapping** — derived from a 130+ entry CASE statement. Edge cases or new states/provinces may map incorrectly.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| **Tier 1** | Description copied verbatim from upstream wiki |
| **Tier 2** | Derived from SP code analysis or DWH ETL logic |
| **Tier 3** | Inferred from data patterns; no SP confirmation |
| **Tier 4** | Best available knowledge; limited evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Recordlen | int | YES | Fixed ATO record length. Always 594. Required by ATO electronic lodgement format specification. (Tier 2 — SP_QTFN_Report) |
| 2 | RecordID | varchar(250) | YES | Fixed ATO record type identifier. Always 'DINVESTOR'. Identifies this as an investor record in the ATO QTFN submission file. (Tier 2 — SP_QTFN_Report) |
| 3 | Investment_reference_number | int | YES | Customer's internal investment reference number. Sourced from Dim_Customer.RealCID. One unique value per row. (Tier 2 — SP_QTFN_Report) |
| 4 | Len_CID | int | YES | Length of the CID string. Computed as LEN(RealCID). Helper field used for CID padding logic. (Tier 2 — SP_QTFN_Report) |
| 5 | Padded_CID | varchar(250) | YES | Formatted CID for ATO submission. Computed as '[' + CID right-padded to 25 characters + ']'. (Tier 2 — SP_QTFN_Report) |
| 6 | Customer_reference_number | varchar(250) | YES | ATO placeholder field. Always a single space character. Reserved for customer reference in the ATO format. (Tier 2 — SP_QTFN_Report) |
| 7 | BSB_Number | varchar(250) | YES | Bank-State-Branch number placeholder. Always a single space character. Not populated as platform does not hold BSB data. (Tier 2 — SP_QTFN_Report) |
| 8 | Branch_location | varchar(250) | YES | Branch location placeholder. Always a single space character. Not populated. (Tier 2 — SP_QTFN_Report) |
| 9 | Investor_entity_type | varchar(250) | YES | ATO investor entity classification. 'I' = Individual (AccountTypeID IN 1,6), 'S' = SMSF (AccountTypeID=14), 'C' = Corporate (AccountTypeID IN 2,15), 'Other' = unclassified. Drives conditional logic for TFN, ABN, and PII fields. (Tier 2 — SP_QTFN_Report) |
| 10 | Investor_Tax_file_number_fin | varchar(250) | YES | Australian Tax File Number. For individuals: sourced from UserApiDB ExtendedUserField (FieldId=6, CountryId=12). For SMSF/Corporate entities: fixed placeholder '987654321'. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 11 | Investor_Australian_business_number | varchar(250) | YES | Australian Business Number field. '00000000000' for individuals (placeholder zeros), 'ABN' literal for SMSF/Corporate entities, 'Other' for unclassified. Does not contain actual ABNs. (Tier 2 — SP_QTFN_Report) |
| 12 | Account_name_fin | varchar(250) | YES | Full account holder name. CONCAT(FirstName, ' ', MiddleName, ' ', LastName) from Dim_Customer. Used for all entity types. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 13 | Investor_surname | varchar(250) | YES | Customer last name from Dim_Customer.LastName. Populated for individuals; single space for SMSF/Corporate entities. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 14 | First_given_name_fin | varchar(250) | YES | Customer first name from Dim_Customer.FirstName. Populated for individuals; single space for SMSF/Corporate entities. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 15 | Second_given_name_fin | varchar(250) | YES | Customer middle name from Dim_Customer.MiddleName. Populated for individuals; single space for SMSF/Corporate entities. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 16 | Date_of_birth | int | YES | Customer date of birth in ddMMyyyy integer format (e.g., 15031990). Sourced from FORMAT(Dim_Customer.BirthDate, 'ddMMyyyy'). Single space for SMSF/Corporate. Zero-padded to 8 digits if result is 7 characters. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 17 | Filler | varchar(250) | YES | ATO format alignment placeholder. Always a single space character. Reserved field in the ATO record structure. (Tier 2 — SP_QTFN_Report) |
| 18 | Non_individual_investor_name | varchar(250) | YES | Entity name for non-individual investors. Account_name_fin for SMSF/Corporate entities; single space for individuals; 'Other' for unclassified. (Tier 2 — SP_QTFN_Report) |
| 19 | Investor_address_line_1_fin | varchar(250) | YES | Customer street address. CONCAT(Dim_Customer.BuildingNumber, ' ', Dim_Customer.Address). Contains PII. (Tier 2 — SP_QTFN_Report) |
| 20 | Investor_address_line_2_fin | varchar(250) | YES | Second address line. Always a single space character. Not populated. (Tier 2 — SP_QTFN_Report) |
| 21 | Suburb_town_or_city | varchar(250) | YES | Customer city from Dim_Customer.City. Contains PII. (Tier 2 — SP_QTFN_Report) |
| 22 | State_or_territory | varchar(250) | YES | Australian state/territory abbreviation (e.g., NSW, VIC, QLD). Derived from Dim_State_and_Province.Name via a 130+ entry CASE mapping using Dim_Customer.RegionByIP_ID. (Tier 2 — SP_QTFN_Report) |
| 23 | Postcode | varchar(250) | YES | Numeric-only postcode. Dim_Customer.Zip with all letters, dashes, and spaces stripped. Used for ATO submission format compliance. (Tier 2 — SP_QTFN_Report) |
| 24 | Len_Postcode | int | YES | Length of the stripped Postcode string. Helper field for ATO format validation (e.g., Australian postcodes should be 4 digits). (Tier 2 — SP_QTFN_Report) |
| 25 | Country_fin | varchar(250) | YES | Customer's registered country name from Dim_Country. Joined via Dim_Customer.CountryID. Not always Australia (that is TaxCountry). (Tier 2 — SP_QTFN_Report) |
| 26 | State | varchar(250) | YES | Full unabbreviated state/province name from Dim_State_and_Province. Joined via Dim_Customer.RegionByIP_ID. Retained alongside the abbreviated State_or_territory for reference. (Tier 2 — SP_QTFN_Report) |
| 27 | Zip | varchar(250) | YES | Raw postal/zip code from Dim_Customer.Zip before any stripping. May contain letters, dashes, or spaces. (Tier 2 — SP_QTFN_Report) |
| 28 | UserName | varchar(250) | YES | eToro platform username from BI_DB_CIDFirstDates. Joined via CID. (Tier 2 — SP_QTFN_Report) |
| 29 | GCID | int | YES | Global Customer ID from Dim_Customer. Primary business key for this table (1 row per GCID). (Tier 2 — SP_QTFN_Report) |
| 30 | Regulation | varchar(250) | YES | Regulation name from Dim_Regulation. Values: 'ASIC' (RegulationID=4) or 'ASIC & GAML' (RegulationID=10). (Tier 2 — SP_QTFN_Report) |
| 31 | PlayerStatus | varchar(250) | YES | Customer status name from Dim_PlayerStatus. Joined via Dim_Customer.PlayerStatusID. (Tier 2 — SP_QTFN_Report) |
| 32 | Club | varchar(250) | YES | Club tier name from Dim_PlayerLevel. Values include Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Joined via Dim_Customer.PlayerLevelID. (Tier 2 — SP_QTFN_Report) |
| 33 | AccountType | varchar(250) | YES | Account type name from Dim_AccountType. Joined via Dim_Customer.AccountTypeID. Provides the human-readable label corresponding to Investor_entity_type classification. (Tier 2 — SP_QTFN_Report) |
| 34 | RegisteredReal | datetime | YES | Date the customer registered a real (non-demo) account. Sourced from Dim_Customer.RegisteredReal. (Tier 2 — SP_QTFN_Report) |
| 35 | FirstDepositDate | datetime | YES | Date of the customer's first deposit. Sourced from Dim_Customer.FirstDepositDate. (Tier 2 — SP_QTFN_Report) |
| 36 | IsDepositor | int | YES | Flag indicating whether the customer has made at least one deposit. 1 = depositor, 0 = non-depositor. Sourced from Dim_Customer.IsDepositor. (Tier 2 — SP_QTFN_Report) |
| 37 | VerificationLevel3Date | datetime | YES | Date the customer achieved Verification Level 3. Sourced from BI_DB_CIDFirstDates.VerificationLevel3Date. (Tier 2 — SP_QTFN_Report) |
| 38 | TaxCountry | varchar(250) | YES | Tax country name. Always 'Australia' in this table. Derived from Dim_Country.Name where CountryID=12. (Tier 2 — SP_QTFN_Report) |
| 39 | UpdateDate | datetime | NO | ETL metadata timestamp. GETDATE() at SP execution time. All rows share the same value from a single TRUNCATE+INSERT run. NOT NULL. (Tier 2 — SP_QTFN_Report) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Recordlen | Constant | — | Always 594 |
| RecordID | Constant | — | Always 'DINVESTOR' |
| Investment_reference_number | DWH_dbo.Dim_Customer | RealCID | Direct |
| Len_CID | DWH_dbo.Dim_Customer | RealCID | LEN(RealCID) |
| Padded_CID | DWH_dbo.Dim_Customer | RealCID | '[' + RPAD(CID, 25) + ']' |
| Customer_reference_number | Constant | — | Always ' ' |
| BSB_Number | Constant | — | Always ' ' |
| Branch_location | Constant | — | Always ' ' |
| Investor_entity_type | DWH_dbo.Dim_AccountType | AccountTypeID | CASE: I/S/C/Other |
| Investor_Tax_file_number_fin | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Value | FieldId=6, CountryId=12; placeholder for S/C |
| Investor_Australian_business_number | Computed | AccountTypeID | CASE: '00000000000'/ABN/Other |
| Account_name_fin | DWH_dbo.Dim_Customer | FirstName, MiddleName, LastName | CONCAT |
| Investor_surname | DWH_dbo.Dim_Customer | LastName | Direct (space for S/C) |
| First_given_name_fin | DWH_dbo.Dim_Customer | FirstName | Direct (space for S/C) |
| Second_given_name_fin | DWH_dbo.Dim_Customer | MiddleName | Direct (space for S/C) |
| Date_of_birth | DWH_dbo.Dim_Customer | BirthDate | FORMAT(ddMMyyyy), zero-pad |
| Filler | Constant | — | Always ' ' |
| Non_individual_investor_name | Computed | AccountTypeID + Account_name_fin | CASE by entity type |
| Investor_address_line_1_fin | DWH_dbo.Dim_Customer | BuildingNumber, Address | CONCAT |
| Investor_address_line_2_fin | Constant | — | Always ' ' |
| Suburb_town_or_city | DWH_dbo.Dim_Customer | City | Direct |
| State_or_territory | DWH_dbo.Dim_State_and_Province | Name | 130+ CASE abbreviation map |
| Postcode | DWH_dbo.Dim_Customer | Zip | Strip non-numeric chars |
| Len_Postcode | DWH_dbo.Dim_Customer | Zip | LEN(stripped Postcode) |
| Country_fin | DWH_dbo.Dim_Country | Name | CountryID join |
| State | DWH_dbo.Dim_State_and_Province | Name | Direct (full name) |
| Zip | DWH_dbo.Dim_Customer | Zip | Direct (raw) |
| UserName | BI_DB_dbo.BI_DB_CIDFirstDates | UserName | CID join |
| GCID | DWH_dbo.Dim_Customer | GCID | Direct |
| Regulation | DWH_dbo.Dim_Regulation | Name | RegulationID join |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | PlayerStatusID join |
| Club | DWH_dbo.Dim_PlayerLevel | Name | PlayerLevelID join |
| AccountType | DWH_dbo.Dim_AccountType | Name | AccountTypeID join |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | Direct |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | Direct |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | Direct |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CID join |
| TaxCountry | DWH_dbo.Dim_Country | Name | CountryID=12, always 'Australia' |
| UpdateDate | ETL system | GETDATE() | Insert timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (GCID, RealCID, FirstName, LastName, MiddleName, Address, City, Zip,
                       BirthDate, BuildingNumber, RegisteredReal, FirstDepositDate, IsDepositor,
                       RegulationID, PlayerStatusID, CountryID, PlayerLevelID, AccountTypeID, RegionID)
BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (FieldId=6, CountryId=12 → TFN value)
BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType (Tax type name)
DWH_dbo.Dim_Regulation (Name)
DWH_dbo.Dim_PlayerStatus (Name)
DWH_dbo.Dim_Country (Name)
DWH_dbo.Dim_PlayerLevel (Name)
DWH_dbo.Dim_AccountType (Name, AccountTypeID)
DWH_dbo.Dim_State_and_Province (Name, state abbreviation mapping)
BI_DB_dbo.BI_DB_CIDFirstDates (VerificationLevel3Date, UserName)
  |
  |-- SP_QTFN_Report ---|
  |   TRUNCATE BI_DB_QTFN_Report
  |   Population: ASIC regulated (RegulationID IN 4,10)
  |               + VerificationLevelID = 3
  |               + TaxCountry = Australia (CountryID = 12)
  |   Entity type: CASE on AccountTypeID → I/S/C/Other
  |   TFN: UserApiDB ExtendedUserField for I; '987654321' for S/C
  |   ABN: '00000000000' for I; 'ABN' for S/C
  |   PII: full for I; spaces for S/C
  |   State: 130+ CASE mapping → abbreviation
  |   Postcode: strip non-numeric
  |   INSERT all qualifying customers
  v
BI_DB_dbo.BI_DB_QTFN_Report (225,393 rows, 1 row per GCID, single snapshot)
  |
  |-- UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| (source) | DWH_dbo.Dim_Customer | Primary customer dimension — PII fields, registration, and classification attributes |
| (source) | BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField | Tax File Number from UserApiDB extended user fields |
| (source) | BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType | Tax type name dictionary |
| (source) | DWH_dbo.Dim_Regulation | Regulation name lookup (ASIC, ASIC & GAML) |
| (source) | DWH_dbo.Dim_PlayerStatus | Player status name lookup |
| (source) | DWH_dbo.Dim_Country | Country name lookup (for Country_fin and TaxCountry) |
| (source) | DWH_dbo.Dim_PlayerLevel | Club tier name lookup |
| (source) | DWH_dbo.Dim_AccountType | Account type name and ID for entity classification |
| (source) | DWH_dbo.Dim_State_and_Province | State name and abbreviation mapping |
| (source) | BI_DB_dbo.BI_DB_CIDFirstDates | VL3 date and username |

### 6.2 Referenced By

No SPs or views in the SSDT repo reference this table (leaf reporting table — exported for ATO QTFN compliance submission).

---

## 7. Sample Queries

### All individual investors with TFN

```sql
SELECT GCID, UserName, Investor_Tax_file_number_fin, Account_name_fin,
       State_or_territory, Postcode, Date_of_birth
FROM [BI_DB_dbo].[BI_DB_QTFN_Report]
WHERE Investor_entity_type = 'I'
  AND Investor_Tax_file_number_fin IS NOT NULL
  AND Investor_Tax_file_number_fin <> '';
```

### SMSF and Corporate entities

```sql
SELECT GCID, UserName, Investor_entity_type, AccountType,
       Non_individual_investor_name, Regulation
FROM [BI_DB_dbo].[BI_DB_QTFN_Report]
WHERE Investor_entity_type IN ('S', 'C')
ORDER BY Investor_entity_type, GCID;
```

### Customers by state/territory

```sql
SELECT State_or_territory, COUNT(*) AS customer_count
FROM [BI_DB_dbo].[BI_DB_QTFN_Report]
WHERE State_or_territory IS NOT NULL AND State_or_territory <> ' '
GROUP BY State_or_territory
ORDER BY customer_count DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources searched (Phase 10 skipped). The table purpose is clearly defined by SP code: Australian ATO Quarterly Tax File Number compliance reporting for ASIC-regulated customers.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 39 T2, 0 T3, 0 T4 | Elements: 39/39 | Logic: 6 subsections*
*Object: BI_DB_dbo.BI_DB_QTFN_Report | Type: Table | Production Source: DWH_dbo.Dim_Customer + UserApiDB + dimensions via SP_QTFN_Report*
