# Lineage: BI_DB_dbo.BI_DB_RejectedDocuments

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | BackOffice.CustomerDocument (production) | Production DB | KYC document submissions with rejection dates and reasons |
| L0 | BackOffice.DocumentToDocumentType (production) | Production DB | Document type lookup (join to resolve document type) |
| L0 | Dictionary.DocumentRejectReason (production) | Production DB | Rejection reason text lookup |
| L1 | BI_DB_dbo.External_BackOffice_CustomerDocument | External Table | Lake bridge for BackOffice.CustomerDocument (refreshed by SP_Create_External_etoro_backoffice_customerdocument before main SP) |
| L1 | DWH_dbo.Dim_Customer | DWH Dimension | VerificationLevelID, CountryID, PlayerStatusID, LanguageID, AccountManagerID |
| L1 | DWH_dbo.Dim_Country | DWH Dimension | CountryID → Country, Region |
| L1 | DWH_dbo.Dim_PlayerStatus | DWH Dimension | PlayerStatusID → PlayerStatus |
| L1 | DWH_dbo.Dim_Language | DWH Dimension | LanguageID → Language |
| L1 | DWH_dbo.Dim_Manager | DWH Dimension | LEFT JOIN (joined but NOT included in INSERT — ghost column Manager) |
| L1 | DWH_dbo.Fact_BillingDeposit | DWH Fact | LEFT JOIN to get FirstDepositDate (first billing event = FTD date) |
| L2 | BI_DB_dbo.BI_DB_RejectedDocuments | **THIS TABLE** | Incrementally maintained rejection log with demographics |

## ETL Pipeline

```
BackOffice.CustomerDocument + DocumentToDocumentType + Dictionary.DocumentRejectReason (production)
  |-- SP_Create_External_etoro_backoffice_customerdocument (called first — refreshes external table) ---|
  v
BI_DB_dbo.External_BackOffice_CustomerDocument (external table — lake bridge)

DWH_dbo.Dim_Customer (VerificationLevelID, CountryID, PlayerStatusID, LanguageID)
DWH_dbo.Dim_Country → Country, Region
DWH_dbo.Dim_PlayerStatus → PlayerStatus
DWH_dbo.Dim_Language → Language
DWH_dbo.Dim_Manager → (LEFT JOIN, NOT included in INSERT — Manager column always NULL)
DWH_dbo.Fact_BillingDeposit → FirstDepositDate (LEFT JOIN, MIN billing date per CID)

  └── SP_RejectedDocuments (@Date) — daily incremental:
        DELETE WHERE RejectionDate = @Date (remove prior day's data)
        INSERT WHERE RejectionDate = @Date (reload from source)
        (Historical data: 2022-07-01 → retained indefinitely)
              v
BI_DB_dbo.BI_DB_RejectedDocuments (2,122,132 rows — 2022-07-01 to 2026-04-13, ROUND_ROBIN HEAP)
  └── UC: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | CID | Dim_Customer | RealCID | Direct — customer ID. Via BackOffice.CustomerDocument → Dim_Customer join. | Tier 1 |
| 2 | DocumentID | BackOffice.CustomerDocument (ext) | DocumentID | Direct — unique document submission ID. | Tier 2 |
| 3 | UploadDate | BackOffice.CustomerDocument (ext) | UploadDate | Direct — date document was submitted by customer. | Tier 2 |
| 4 | RejectionDate | BackOffice.CustomerDocument (ext) | RejectionDate | Direct — date document was rejected by agent. Partition key for daily incremental. | Tier 2 |
| 5 | RejectionReason | Dictionary.DocumentRejectReason (ext) | Reason | Direct — standardized rejection reason text (e.g., 'POA - Proof of address cannot be accepted'). | Tier 2 |
| 6 | [Classification comment] | BackOffice.CustomerDocument (ext) | Classification comment | Direct — free-text internal agent note attached to the rejection. Column name has a SPACE — must use square brackets: [[Classification comment]]. | Tier 2 |
| 7 | Manager | Dim_Manager | Name | GHOST COLUMN — Dim_Manager is LEFT JOINed in the SP query but Manager is NOT included in the INSERT column list. Always NULL in data. Never populated. | Tier 4 |
| 8 | VerificationLevelID | Dim_Customer | VerificationLevelID | Direct — KYC verification tier at time of rejection. | Tier 1 |
| 9 | Country | Dim_Country | Country | Direct — customer country name. | Tier 1 |
| 10 | Region | Dim_Country | Region | Direct — marketing region label. | Tier 1 |
| 11 | FirstDepositDate | Fact_BillingDeposit | BillingDate | LEFT JOIN MIN(BillingDate) per CID — first deposit date (NULL for non-depositors). | Tier 2 |
| 12 | PlayerStatus | Dim_PlayerStatus | Name | Direct — customer account status at time of run. | Tier 1 |
| 13 | Language | Dim_Language | Name | Direct — customer preferred/detected language. | Tier 1 |
| 14 | CustomerName | Dim_Customer (or similar) | CustomerName | GHOST COLUMN — in DDL but NOT included in the INSERT column list. Always NULL in data. Never populated. | Tier 4 |
| 15 | UpdateDate | SP-computed | GETDATE() | ETL metadata: timestamp when this row was last updated by the ETL pipeline. | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
