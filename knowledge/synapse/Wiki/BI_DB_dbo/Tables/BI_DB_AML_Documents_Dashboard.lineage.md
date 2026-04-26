# Column Lineage: BI_DB_dbo.BI_DB_AML_Documents_Dashboard

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_AML_Documents_Dashboard` |
| **UC Target** | Not_Migrated |
| **Primary Source** | `External_etoro_BackOffice_CustomerDocumentToDocumentType` (→ `etoro.BackOffice.CustomerDocumentToDocumentType`) |
| **ETL SP** | `SP_AML_Documents_Dashboard` |
| **Secondary Sources** | `Dim_Customer`, `Dim_Regulation`, `Dim_PlayerLevel`, `Dim_PlayerStatus`, `Dim_Country`, `Dim_Manager`, `External_etoro_BackOffice_CustomerDocument`, `External_etoro_BackOffice_Customer`, `External_etoro_Dictionary_DocumentStatus`, `External_etoro_Dictionary_DocumentType` (×2), `External_etoro_Dictionary_DocumentRejectReason` |
| **Generated** | 2026-03-28 |

## Lineage Chain

```
etoro.BackOffice.CustomerDocumentToDocumentType (production)
    │
    └─ External_etoro_BackOffice_CustomerDocumentToDocumentType (external table)
        │
        ├── JOIN Dim_Manager dm — filtered to 23 hardcoded AML team member names
        ├── LEFT JOIN External_etoro_BackOffice_CustomerDocument cd
        ├── LEFT JOIN Dim_Customer cc
        ├── LEFT JOIN External_etoro_BackOffice_Customer bc
        ├── LEFT JOIN External_etoro_Dictionary_DocumentStatus ds
        ├── LEFT JOIN External_etoro_Dictionary_DocumentType ddt (×2: actual + suggested)
        ├── LEFT JOIN External_etoro_Dictionary_DocumentRejectReason rr
        │
        └─ SP_AML_Documents_Dashboard (no parameters)
            ├─ CTAS #gen (document classification data)
            ├─ CTAS #final (JOIN #gen with Dim_Customer + Dim_Regulation + Dim_PlayerLevel + Dim_PlayerStatus + Dim_Country)
            ├─ TRUNCATE TABLE target
            └─ INSERT → BI_DB_dbo.BI_DB_AML_Documents_Dashboard
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **join-enriched** | Joined from a secondary source table during ETL. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| CID | DWH_dbo.Dim_Customer (cc) | RealCID | rename | `cc.RealCID AS CID` via CustomerDocument.CID → Dim_Customer.RealCID | Customer Real account ID |
| RegisteredReal | DWH_dbo.Dim_Customer (dc) | RegisteredReal | passthrough | Direct: `dc.RegisteredReal` | Account registration date |
| FirstDepositDate | DWH_dbo.Dim_Customer (dc) | FirstDepositDate | passthrough | Direct: `dc.FirstDepositDate` | First deposit date |
| FirstDepositAmount | DWH_dbo.Dim_Customer (dc) | FirstDepositAmount | passthrough | Direct: `dc.FirstDepositAmount` | First deposit amount in USD |
| VerificationLevelID | DWH_dbo.Dim_Customer (dc) | VerificationLevelID | passthrough | Direct: `dc.VerificationLevelID` | KYC verification level |
| IsValidCustomer | DWH_dbo.Dim_Customer (dc) | IsValidCustomer | passthrough | Direct: `dc.IsValidCustomer` | DWH-computed valid customer flag |
| IsDepositor | DWH_dbo.Dim_Customer (dc) | IsDepositor | passthrough | Direct: `dc.IsDepositor` | Ever-deposited flag |
| BirthDate | DWH_dbo.Dim_Customer (dc) | BirthDate | passthrough | Direct: `dc.BirthDate` | Customer date of birth |
| Gender | DWH_dbo.Dim_Customer (dc) | Gender | passthrough | Direct: `dc.Gender` | Customer gender |
| Regulation | DWH_dbo.Dim_Regulation (dr) | Name | join-enriched | `dr.Name` via `Dim_Customer.RegulationID = dr.DWHRegulationID` | Regulatory entity name |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (dps) | Name | join-enriched | `dps.Name` via `Dim_Customer.PlayerStatusID = dps.PlayerStatusID` | Account restriction state |
| Club | DWH_dbo.Dim_PlayerLevel (dpl) | Name | join-enriched | `dpl.Name` via `Dim_Customer.PlayerLevelID = dpl.PlayerLevelID` | eToro Club loyalty tier |
| Country | DWH_dbo.Dim_Country (dc1) | Name | join-enriched | `dc1.Name` via `Dim_Customer.CountryID = dc1.DWHCountryID` | Customer country of residence |
| DocumentAdded | External_etoro_BackOffice_CustomerDocument (cd) | DateAdded | rename | `cd.DateAdded AS DocumentAdded` | When document was uploaded |
| DocumentStatus | External_etoro_Dictionary_DocumentStatus (ds) | DocumentStatusName | join-enriched | `ds.DocumentStatusName` via `BackOffice_Customer.DocumentStatusID` | Document review status |
| ClassificationComment | External_etoro_BackOffice_CustomerDocumentToDocumentType (dt) | Comment | rename | `dt.Comment AS ClassificationComment` | AML reviewer's classification note |
| DocumentType | External_etoro_Dictionary_DocumentType (ddt) | Name | join-enriched | `ddt.Name` via `dt.DocumentTypeID = ddt.DocumentTypeID` | Assigned document type |
| RejectReason | External_etoro_Dictionary_DocumentRejectReason (rr) | RejectReasonName | join-enriched | `rr.RejectReasonName` via `dt.RejectReasonID = rr.RejectReasonID` | Reason for rejection |
| ClassifiedBy | DWH_dbo.Dim_Manager (dm) | FirstName, LastName | ETL-computed | `dm.FirstName + ' ' + dm.LastName` | AML team member who classified the doc |
| ClassificationOccured | External_etoro_BackOffice_CustomerDocumentToDocumentType (dt) | Occurred | rename | `dt.Occurred AS ClassificationOccured` | When classification was performed |
| SuggestedDocumentType | External_etoro_Dictionary_DocumentType (ddt1) | Name | join-enriched | `ddt1.Name` via `cd.SuggestedDocumentTypeID = ddt1.DocumentTypeID` | System-suggested document type |
| Comment | External_etoro_BackOffice_CustomerDocument (cd) | Comment | passthrough | Direct: `cd.Comment` | Upload comment |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL execution timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 9 |
| **Rename** | 4 |
| **Join-enriched** | 8 |
| **ETL-computed** | 2 |
| **Total** | 23 |
