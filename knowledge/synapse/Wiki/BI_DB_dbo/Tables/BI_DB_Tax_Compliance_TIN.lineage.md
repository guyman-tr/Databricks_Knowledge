# BI_DB_dbo.BI_DB_Tax_Compliance_TIN — Column Lineage

## Source Objects

| Source | Schema | Role | Join Condition |
|--------|--------|------|----------------|
| External_UserApiDB_Customer_ExtendedUserField | BI_DB_dbo (External) | Primary TIN data source (FieldId=6) | Main driver |
| DWH_dbo.Dim_Customer | DWH_dbo | CID resolution (RealCID from GCID) | euf.GCID = cc.GCID |
| External_UserApiDB_KYC_CountryTaxType | BI_DB_dbo (External) | Country tax type config | euf.CountryId = ct.CountryID |
| External_UserApiDB_Dictionary_ExtendedUserValueType | BI_DB_dbo (External) | TIN value type name lookup | euf.TypeId = evt.ValueTypeID |
| External_UserApiDB_Dictionary_MandatoryType | BI_DB_dbo (External) | Mandatory type name lookup | ct.TaxIdRequirmentTypeId = mt.MandatoryTypeID |
| DWH_dbo.Dim_Country | DWH_dbo | Country name lookup | u.TIN_CountryID = dc.CountryID |
| External_UserApiDB_KYC_ReasonsForNoTaxID | BI_DB_dbo (External) | No-TIN reason description | u.NoTIN_ReasonID = rti.ReasonID |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename (cc.RealCID AS 'CID') |
| GCID | Customer.ExtendedUserField | GCID | Passthrough |
| TIN_CountryID | Customer.ExtendedUserField | CountryId | Rename (euf.CountryId AS 'TIN_CountryID') |
| TIN_CountryName | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough (dc.Name AS 'TIN_CountryName') |
| TIN_Value | Customer.ExtendedUserField | Value | CASE: empty/single-char → 'Null', else passthrough |
| NoTIN_ReasonID | Customer.ExtendedUserField | AdditionalDetails | Computed: JSON parse of {"noTaxIdReason":N} → first digit cast to INT; 0 if non-numeric |
| NoTIN_Reason | KYC.ReasonsForNoTaxID | Description | CASE: NULL → 'TIN Information Displayed', else passthrough |
| IsTIN_Mandatory | Dictionary.MandatoryType | Name | Dim-lookup passthrough via KYC.CountryTaxType.TaxIdRequirmentTypeId |
| TIN_UpdateDateTime | Customer.ExtendedUserField | LastModified | Rename (euf.LastModified AS 'TIN_UpdateDateTime') |
| TIN_UpdateDate | Customer.ExtendedUserField | LastModified | CAST(LastModified AS DATE) — date truncation |
| TIN_UpdateDateID | Customer.ExtendedUserField | LastModified | CAST(CONVERT(CHAR(8), LastModified, 112) AS INT) — YYYYMMDD int |
| RN_TIN_CID_Country | (computed) | — | ROW_NUMBER() OVER(PARTITION BY GCID, CountryID ORDER BY LastModified DESC) |
| FieldID | Customer.ExtendedUserField | FieldId | Rename passthrough (always 6 for this table) |
| TypeID | Customer.ExtendedUserField | TypeId | Rename passthrough |
| TypeIDName | Dictionary.ExtendedUserValueType | Name | Dim-lookup passthrough (evt.Name AS 'TypeIDName') |
| UpdateDate | (ETL) | GETDATE() | ETL metadata timestamp |

## Production Source Chain

```
UserApiDB.Customer.ExtendedUserField (FieldId=6, TIN records)
  + UserApiDB.KYC.CountryTaxType (country→tax type config)
  + UserApiDB.Dictionary.ExtendedUserValueType (tax ID subtype names)
  + UserApiDB.Dictionary.MandatoryType (requirement level names)
  + UserApiDB.KYC.ReasonsForNoTaxID (no-TIN reason descriptions)
  + DWH_dbo.Dim_Customer (GCID→RealCID resolution)
  + DWH_dbo.Dim_Country (CountryID→Name resolution)
    |-- External Tables (Generic Pipeline Bronze export) --|
    v
  DWH_staging / External tables in BI_DB_dbo
    |-- SP_Tax_Compliance_W8_AND_TIN @Date (TIN section) --|
    v
  BI_DB_dbo.BI_DB_Tax_Compliance_TIN (8.08M rows)
    |-- Generic Pipeline (Override, delta, 1440 min) --|
    v
  bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_tax_compliance_tin
```
