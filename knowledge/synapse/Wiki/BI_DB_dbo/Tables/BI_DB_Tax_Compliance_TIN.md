# BI_DB_dbo.BI_DB_Tax_Compliance_TIN

> 8.08M-row tax compliance table tracking Tax Identification Number (TIN) data for every eToro customer who has submitted a tax ID (FieldId=6), with per-country deduplication, sourced from UserApiDB.Customer.ExtendedUserField via SP_Tax_Compliance_W8_AND_TIN. Covers TIN submissions from 2017-12-22 to present. Daily UPDATE refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.Customer.ExtendedUserField (primary, FieldId=6) via SP_Tax_Compliance_W8_AND_TIN |
| **Refresh** | Daily (UPDATE on matched CID+TIN_CountryID via OpsDB Service Broker, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Override, 1440 min) |

---

## 1. Business Meaning

`BI_DB_Tax_Compliance_TIN` stores the Tax Identification Number (TIN) submission record for every eToro customer who has provided tax ID information through the KYC extended user field system. Each row represents one customer's TIN for one country, capturing the tax number value, the country-specific tax ID type (24 distinct types including taxID, SocialSecurityNumber, taxUTR, taxTFN, etc.), whether the TIN is mandatory or optional for that country's regulation, and the reason if no TIN was provided.

The table contains 8.08M rows spanning TIN submissions from December 2017 to April 2026. Top countries by volume: United States (1.35M), United Kingdom (1.32M), Germany (698K), France (523K), Italy (467K). All rows have FieldID=6 (TaxId field). The ROW_NUMBER column `RN_TIN_CID_Country` enables per-GCID-per-country deduplication — only the most recent TIN submission per customer per country is ranked #1.

The ETL is a daily UPDATE-only pattern executed by `SP_Tax_Compliance_W8_AND_TIN` (which also writes BI_DB_Tax_Compliance_W8 and BI_DB_Tax_Compliance_Trade_CFD_US_Stocks). The SP reads from 5 External tables sourced from UserApiDB plus 2 DWH dimension tables (Dim_Customer for GCID→CID resolution, Dim_Country for country name). Existing rows are matched on CID+TIN_CountryID and updated; the original MERGE (with INSERT/DELETE) is commented out and replaced with UPDATE JOIN only.

Consumer: `SP_US_Citizens_Under_Non_US_Regulation` reads this table to identify US TIN holders under non-US regulations.

---

## 2. Business Logic

### 2.1 TIN Value Nullification

**What**: Empty or single-character TIN values are replaced with the string 'Null'.
**Columns Involved**: `TIN_Value`
**Rules**:
- If `LEN(ISNULL(Value, 0)) IN (0, 1)` → TIN_Value = 'Null'
- Otherwise → TIN_Value = raw Value from ExtendedUserField
- Note: this is the string 'Null', not SQL NULL — the column is nullable but uses a string sentinel

### 2.2 NoTIN Reason JSON Extraction

**What**: The NoTIN_ReasonID is extracted from a JSON field in AdditionalDetails.
**Columns Involved**: `NoTIN_ReasonID`, `NoTIN_Reason`
**Rules**:
- SP parses `AdditionalDetails` by stripping `{"noTaxIdReason":` prefix and taking the first character
- If the first character is numeric → cast to INT as NoTIN_ReasonID
- If not numeric → default to 0
- NoTIN_Reason is looked up from KYC.ReasonsForNoTaxID; NULL → 'TIN Information Displayed'

### 2.3 Per-Customer-Per-Country Deduplication

**What**: ROW_NUMBER enables selecting only the most recent TIN submission per customer per country.
**Columns Involved**: `RN_TIN_CID_Country`
**Rules**:
- `ROW_NUMBER() OVER(PARTITION BY GCID, CountryID ORDER BY LastModified DESC)`
- RN=1 is the most recent submission; consumers should filter `WHERE RN_TIN_CID_Country = 1` for current data
- The table stores ALL historical submissions (not just the latest)

### 2.4 Mandatory Type Resolution Chain

**What**: IsTIN_Mandatory is resolved through a two-hop JOIN chain.
**Columns Involved**: `IsTIN_Mandatory`
**Rules**:
- ExtendedUserField.CountryId → KYC.CountryTaxType.TaxIdRequirmentTypeId → Dictionary.MandatoryType.Name
- Values: 'Mandatory' (1.42M rows), 'Optional' (6.46M rows), NULL/empty (195K rows)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on CID. Queries filtering by CID are efficient. For JOINs to Dim_Customer (HASH on RealCID), there will be data movement — consider filtering first then joining.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Current TIN for a customer | `WHERE CID = @CID AND RN_TIN_CID_Country = 1` |
| Customers without TIN | `WHERE NoTIN_ReasonID > 0 AND RN_TIN_CID_Country = 1` |
| TIN coverage by country | `GROUP BY TIN_CountryName WHERE RN_TIN_CID_Country = 1` |
| US SSN holders | `WHERE TypeIDName = 'SocialSecurityNumber' AND RN_TIN_CID_Country = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | CID = RealCID | Customer demographics, regulation, status |
| DWH_dbo.Dim_Country | TIN_CountryID = CountryID | Additional country attributes (region, risk) |
| BI_DB_dbo.BI_DB_Tax_Compliance_W8 | CID = CID | W8 form submission dates |

### 3.4 Gotchas

- **RN_TIN_CID_Country**: Always filter `= 1` for current data; omitting returns duplicates per customer per country
- **TIN_Value = 'Null'**: This is the string literal 'Null', NOT SQL NULL — use `WHERE TIN_Value <> 'Null'` to find real TINs
- **NoTIN_ReasonID = 0**: Means either TIN was provided OR the JSON parse failed — check TIN_Value alongside
- **FieldID**: Always 6 (TaxId) in this table — no variance, filtering on it is unnecessary
- **UPDATE-only ETL**: New customers may not appear immediately if the initial INSERT was from a prior MERGE run; the current SP only updates existing rows

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer (RealCID renamed to CID). (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | NO | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | TIN_CountryID | int | YES | Country context for this TIN field value. Allows per-country field values. Renamed from ExtendedUserField.CountryId. FK to Dim_Country. (Tier 1 — UserApiDB.Customer.ExtendedUserField) |
| 4 | TIN_CountryName | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 5 | TIN_Value | nvarchar(128) | YES | The user-provided value for this field (e.g., the actual tax number, national PIN). DWH note: SP converts empty/single-char values to the string 'Null'. (Tier 1 — UserApiDB.Customer.ExtendedUserField) |
| 6 | NoTIN_ReasonID | int | YES | ETL-computed from ExtendedUserField.AdditionalDetails JSON. Parses `{"noTaxIdReason":N}` to extract the first digit as the reason code. 0=TIN provided or parse failure. 1=Unable to obtain, 2=Not required by authorities, 3=Country doesn't issue, 4=Not legally required, 5=Diplomat/UN. (Tier 2 — SP_Tax_Compliance_W8_AND_TIN) |
| 7 | NoTIN_Reason | varchar(200) | YES | User-facing description of the reason, displayed in the KYC form. DWH note: NULL values from KYC.ReasonsForNoTaxID are replaced with 'TIN Information Displayed'. 0=TIN Information Displayed, 1=I'm unable to obtain a TIN or equivalent number, 2=The authorities in my tax residency don't require disclosure of TIN, 3=The country doesn't issue TIN, 4=I'm not legally required to have TIN or functional equivalent, 5=I am Diplomat/UN employee or spouse/dependent. (Tier 1 — UserApiDB.KYC.ReasonsForNoTaxID) |
| 8 | IsTIN_Mandatory | varchar(20) | YES | Requirement level label used in admin configuration tools. Resolved via KYC.CountryTaxType.TaxIdRequirmentTypeId → Dictionary.MandatoryType.Name. Values: 'Mandatory', 'Optional', or NULL/empty. (Tier 1 — UserApiDB.Dictionary.MandatoryType) |
| 9 | TIN_UpdateDateTime | datetime | YES | When this field value was last updated. Passthrough from ExtendedUserField.LastModified. (Tier 1 — UserApiDB.Customer.ExtendedUserField) |
| 10 | TIN_UpdateDate | date | YES | ETL-computed date truncation of TIN_UpdateDateTime. CAST(LastModified AS DATE). (Tier 2 — SP_Tax_Compliance_W8_AND_TIN) |
| 11 | TIN_UpdateDateID | int | YES | ETL-computed YYYYMMDD integer from TIN_UpdateDateTime. CAST(CONVERT(CHAR(8), LastModified, 112) AS INT). (Tier 2 — SP_Tax_Compliance_W8_AND_TIN) |
| 12 | RN_TIN_CID_Country | int | YES | ROW_NUMBER() OVER(PARTITION BY GCID, CountryID ORDER BY LastModified DESC). Deduplication rank — 1=most recent TIN per customer per country. Filter on RN=1 for current data. (Tier 2 — SP_Tax_Compliance_W8_AND_TIN) |
| 13 | FieldID | int | YES | FK to Dictionary.ExtendedUserField. Identifies which field: 0=province, 6=TaxId, 7=NationalPin, etc. Always 6 (TaxId) in this table. (Tier 1 — UserApiDB.Customer.ExtendedUserField) |
| 14 | TypeID | int | YES | Value subtype. Maps to Dictionary.ExtendedUserValueType for further classification (e.g., which specific type of tax ID). 24 distinct values observed. (Tier 1 — UserApiDB.Customer.ExtendedUserField) |
| 15 | TypeIDName | varchar(50) | YES | Value subtype name. camelCase for tax IDs (taxCPR), PascalCase for national PINs (NationalNumber). Dim-lookup passthrough from Dictionary.ExtendedUserValueType.Name. Top values: taxID (3.95M), SocialSecurityNumber (1.36M), taxUTR (1.35M), taxTFN (275K). (Tier 1 — UserApiDB.Dictionary.ExtendedUserValueType) |
| 16 | UpdateDate | date | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| GCID | UserApiDB.Customer.ExtendedUserField | GCID | Passthrough |
| TIN_CountryID | UserApiDB.Customer.ExtendedUserField | CountryId | Rename |
| TIN_CountryName | DWH_dbo.Dim_Country (← Dictionary.Country) | Name | Dim-lookup passthrough |
| TIN_Value | UserApiDB.Customer.ExtendedUserField | Value | CASE: empty/1-char → 'Null' |
| NoTIN_ReasonID | UserApiDB.Customer.ExtendedUserField | AdditionalDetails | JSON parse + CAST |
| NoTIN_Reason | UserApiDB.KYC.ReasonsForNoTaxID | Description | CASE: NULL → 'TIN Information Displayed' |
| IsTIN_Mandatory | UserApiDB.Dictionary.MandatoryType | Name | Two-hop dim-lookup via CountryTaxType |
| TIN_UpdateDateTime | UserApiDB.Customer.ExtendedUserField | LastModified | Rename |
| TIN_UpdateDate | UserApiDB.Customer.ExtendedUserField | LastModified | CAST AS DATE |
| TIN_UpdateDateID | UserApiDB.Customer.ExtendedUserField | LastModified | YYYYMMDD int |
| RN_TIN_CID_Country | (computed) | — | ROW_NUMBER() |
| FieldID | UserApiDB.Customer.ExtendedUserField | FieldId | Rename |
| TypeID | UserApiDB.Customer.ExtendedUserField | TypeId | Rename |
| TypeIDName | UserApiDB.Dictionary.ExtendedUserValueType | Name | Dim-lookup passthrough |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |

### 5.2 ETL Pipeline

```
UserApiDB.Customer.ExtendedUserField (FieldId=6, production OLTP)
  + UserApiDB.KYC.CountryTaxType
  + UserApiDB.Dictionary.ExtendedUserValueType
  + UserApiDB.Dictionary.MandatoryType
  + UserApiDB.KYC.ReasonsForNoTaxID
  |-- Generic Pipeline (Bronze export) --|
  v
BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField (External table)
BI_DB_dbo.External_UserApiDB_KYC_CountryTaxType (External table)
BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType (External table)
BI_DB_dbo.External_UserApiDB_Dictionary_MandatoryType (External table)
BI_DB_dbo.External_UserApiDB_KYC_ReasonsForNoTaxID (External table)
  + DWH_dbo.Dim_Customer (GCID→RealCID)
  + DWH_dbo.Dim_Country (CountryID→Name)
  |-- SP_Tax_Compliance_W8_AND_TIN @Date (TIN section, UPDATE JOIN) --|
  v
BI_DB_dbo.BI_DB_Tax_Compliance_TIN (8.08M rows)
  |-- Generic Pipeline (Override, delta, 1440 min) --|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master dimension |
| TIN_CountryID | DWH_dbo.Dim_Country (CountryID) | Country dimension |
| FieldID | UserApiDB.Dictionary.ExtendedUserField | Extended field definition |
| TypeID | UserApiDB.Dictionary.ExtendedUserValueType | Value subtype classification |
| NoTIN_ReasonID | UserApiDB.KYC.ReasonsForNoTaxID | No-TIN reason lookup |

### 6.2 Referenced By (other objects point to this)

| Source Object | Relationship | Description |
|--------------|-------------|-------------|
| SP_US_Citizens_Under_Non_US_Regulation | Reads CID, joins to Dim_Customer | Identifies US TIN holders under non-US regulations |

---

## 7. Sample Queries

### 7.1 Current TIN data for a customer

```sql
SELECT CID, GCID, TIN_CountryName, TIN_Value, TypeIDName, IsTIN_Mandatory
FROM BI_DB_dbo.BI_DB_Tax_Compliance_TIN
WHERE CID = @CID
  AND RN_TIN_CID_Country = 1
```

### 7.2 Customers with no TIN by reason

```sql
SELECT NoTIN_ReasonID, NoTIN_Reason, COUNT(DISTINCT CID) AS customers
FROM BI_DB_dbo.BI_DB_Tax_Compliance_TIN
WHERE RN_TIN_CID_Country = 1
  AND NoTIN_ReasonID > 0
GROUP BY NoTIN_ReasonID, NoTIN_Reason
ORDER BY customers DESC
```

### 7.3 TIN coverage by country and tax type

```sql
SELECT TIN_CountryName, TypeIDName, IsTIN_Mandatory, COUNT(*) AS submissions
FROM BI_DB_dbo.BI_DB_Tax_Compliance_TIN
WHERE RN_TIN_CID_Country = 1
  AND TIN_Value <> 'Null'
GROUP BY TIN_CountryName, TypeIDName, IsTIN_Mandatory
ORDER BY submissions DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 11 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_Tax_Compliance_TIN | Type: Table | Production Source: UserApiDB.Customer.ExtendedUserField via SP_Tax_Compliance_W8_AND_TIN*
