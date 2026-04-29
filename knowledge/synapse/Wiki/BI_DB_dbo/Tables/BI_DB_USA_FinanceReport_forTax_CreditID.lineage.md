# BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID — Column Lineage

## Source Objects

| Source Object | Schema | Role | Confidence |
|--------------|--------|------|------------|
| External_etoro_History_Credit_Yesterday | BI_DB_dbo (external) | Primary source — History.Credit ledger via dynamic external table (CreditTypeID=6 only) | Tier 2 — SP code |
| External_etoro_Dictionary_MoveMoneyReason | BI_DB_dbo (external) | Lookup — MoveMoneyReason name for money movement classification | Tier 1 — Dictionary.MoveMoneyReason wiki |
| Dim_CreditType | DWH_dbo | Lookup — CreditTypeName for credit type classification | Tier 1 — Dictionary.CreditType wiki |
| Dim_CompensationReason | DWH_dbo | Lookup — CompensationReason Name for category classification | Tier 1 — BackOffice.CompensationReason wiki |
| External_UserApiDB_Customer_ExtendedUserField | BI_DB_dbo (external) | Lookup — SSN/TIN (FieldId=6, CountryId=219) | Tier 2 — SP code |
| Dim_Customer | DWH_dbo | Filter — US population (RegulationID IN (6,7), IsValidCustomer=1) | Tier 1 — Customer.CustomerStatic wiki |

## Column Lineage

| Target Column | Source Table | Source Column | Transform | Tier |
|--------------|-------------|---------------|-----------|------|
| CID | External_etoro_History_Credit_Yesterday | CID | Passthrough (filtered to US-regulated CIDs via #US_comp_CID) | Tier 2 |
| CreditID | External_etoro_History_Credit_Yesterday | CreditID | Passthrough | Tier 2 |
| Credit | DWH_dbo.Dim_CreditType | CreditTypeName | Dim-lookup passthrough via CreditTypeID JOIN. Always "Compensation" (CreditTypeID=6 filter) | Tier 1 |
| Amount | External_etoro_History_Credit_Yesterday | Payment | Rename (Payment → Amount) | Tier 2 |
| Category | DWH_dbo.Dim_CompensationReason | Name | Dim-lookup passthrough via CompensationReasonID JOIN. 39 distinct values. | Tier 1 |
| Reason | External_etoro_Dictionary_MoveMoneyReason | MoveMoneyReason | Passthrough via MoveMoneyReasonID JOIN. 5 distinct values (86% empty). | Tier 1 |
| Time | External_etoro_History_Credit_Yesterday | Occurred | Passthrough (renamed Occurred → Time) | Tier 2 |
| Note | External_etoro_History_Credit_Yesterday | Description | Rename (Description → Note) | Tier 2 |
| SSN | External_UserApiDB_Customer_ExtendedUserField | Value | Passthrough (FieldId=6, CountryId=219). PII — Social Security Number. | Tier 2 |
| DateID | — | — | ETL-computed: CAST(CONVERT(VARCHAR(8),[Time],112) AS INT). YYYYMMDD integer from Time. | Tier 2 |
| UpdateDate | — | — | ETL metadata: GETDATE() at SP execution time | Tier 5 |

## ETL Pipeline

```
etoro.History.Credit (production, CreditTypeID=6)
  |-- SP_Create_External_etoro_History_Credit @Date, 'Yesterday' ---|
  v
BI_DB_dbo.External_etoro_History_Credit_Yesterday (dynamic external table)
  |
  + etoro.Dictionary.MoveMoneyReason (external) → Reason lookup
  + DWH_dbo.Dim_CreditType → Credit name lookup
  + DWH_dbo.Dim_CompensationReason → Category lookup
  + UserApiDB.Customer.ExtendedUserField (external, FieldId=6) → SSN
  + DWH_dbo.Dim_Customer → US population filter (RegulationID IN (6,7))
  |
  |-- SP_USA_FinanceReport_forTax @Date (DELETE WHERE DateID=@DateID + INSERT) ---|
  v
BI_DB_dbo.BI_DB_USA_FinanceReport_forTax_CreditID (~450K rows)
```
