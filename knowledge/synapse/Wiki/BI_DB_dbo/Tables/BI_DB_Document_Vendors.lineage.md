# BI_DB_dbo.BI_DB_Document_Vendors — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Document_Vendors`

## Source Objects
- `BI_DB_dbo.External_etoro_BackOffice_CustomerDocument` — customer document records (CID, DocumentID, DateAdded, Comment, SuggestedDocumentTypeID)
- `BI_DB_dbo.External_etoro_BackOffice_CustomerDocumentToDocumentType` — document classification events (DocumentTypeID, Occurred, ExpiryDate, ManagerID, RejectReasonID)
- `BI_DB_dbo.External_etoro_Dictionary_DocumentType` — document type names (Classification, SuggestedDocumentType)
- `BI_DB_dbo.External_etoro_BackOffice_DocumentVendors` — vendor assignment per document
- `BI_DB_dbo.External_etoro_Dictionary_DocumentRejectReason` — reject reason names
- `BI_DB_dbo.External_etoro_BackOffice_DocumentAuthenticationReasons` — authentication reason list per document
- `BI_DB_dbo.External_etoro_Dictionary_AuthenticationReason` — authentication reason names
- `DWH_dbo.Dim_Manager` — manager names (ClassifiedBy)
- `DWH_dbo.Dim_Customer` — customer enrichment (RegulationID, CountryID, IsValidCustomer)
- `DWH_dbo.Dim_Regulation` — regulation name
- `DWH_dbo.Dim_Country` — country name

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| ID | IDENTITY | auto-increment | IDENTITY(1,1) — system-generated |
| CID | External_BackOffice_CustomerDocument | CID | Direct passthrough |
| DocumentID | External_BackOffice_CustomerDocument | DocumentID | Direct passthrough |
| Classification | External_Dictionary_DocumentType | Name | Joined via CustomerDocumentToDocumentType.DocumentTypeID |
| SuggestedDocumentType | External_Dictionary_DocumentType | Name | Joined via CustomerDocument.SuggestedDocumentTypeID |
| ClassificationDate | External_BackOffice_CustomerDocumentToDocumentType | Occurred | Direct passthrough |
| ClassifiedBy | Dim_Manager / System | FirstName + LastName | 'System' when ManagerID=0 or NULL; otherwise manager full name |
| Comment | External_BackOffice_CustomerDocument | Comment | Direct passthrough |
| DateAdded | External_BackOffice_CustomerDocument | DateAdded | CAST to DATE |
| ExpiryDate | External_BackOffice_CustomerDocumentToDocumentType | ExpiryDate | Direct passthrough |
| reasonList | External_BackOffice_DocumentAuthenticationReasons + Dictionary_AuthenticationReason | Reason | STRING_AGG of all reasons per document |
| RejectReasonName | External_Dictionary_DocumentRejectReason | RejectReasonName | Joined via RejectReasonID |
| Overriden | Computed | ManagerID | CASE: ManagerID=0 or NULL → 0 (system), else → 1 (human override) |
| Regulation | Dim_Regulation | Name | Joined via Dim_Customer.RegulationID |
| Country | Dim_Country | Name | Joined via Dim_Customer.CountryID |
| DocumentTypeCategory | Computed | Classification + SuggestedDocumentType | CASE: maps to 'Proof of Identity', 'Proof of address', 'Selfie', 'SelfieLiveliness', 'Selfie Motion' |
| OriginalOutcome | Computed | Classification, ClassifiedBy, Vendor, reasonList | Complex CASE: vendor-specific logic for initial vendor verdict |
| FinalOutcome | Computed | Classification, ClassifiedBy, Vendor, Overriden, reasonList | Complex CASE: final disposition after human review |
| Vendor | External_BackOffice_DocumentVendors | Vendor | Direct passthrough (Au10tix, Onfido, Sumsub) |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
