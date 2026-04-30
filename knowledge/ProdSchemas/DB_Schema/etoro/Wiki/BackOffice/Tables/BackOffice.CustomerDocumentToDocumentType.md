# BackOffice.CustomerDocumentToDocumentType

> KYC document classification records linking uploaded customer documents to their assigned document types, with expiry dates, rejection reasons, and agent classification details.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | DocumentToDocumentTypeID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (stored ON [MAIN] filegroup) |
| **Indexes** | 3 active (1 clustered PK + 1 UNIQUE on 6 columns + 1 NC filtered on FundingID) |

---

## 1. Business Meaning

BackOffice.CustomerDocumentToDocumentType is the formal classification record for a KYC document. While BackOffice.CustomerDocument records the raw upload (the file exists, here is its metadata), this table records what type the document was classified as, by whom, when it was issued or expires, and whether it was accepted or rejected. It is the operational table that drives the customer's KYC verification status.

Each row represents one classification assignment: "DocumentID X is a Proof of Identity, issued 2023-01-01, expires 2030-01-01, classified by ManagerID 742." A single document can have multiple rows if it was classified multiple times (e.g., rejected and resubmitted, or reclassified by a different agent). The UNIQUE constraint on (DocumentID, DocumentTypeID, IssueDate, ExpiryDate, FundingID, SideID) prevents true exact duplicates but allows multiple classification attempts with different metadata.

1,327,011 rows as of 2026-03-17. Proof of Identity is the dominant document type (59.8%), followed by W9 tax forms (18.1%), W-8BEN foreign tax forms (7.7%), and Proof of Address (7.5%). The Not Accepted type (DocumentTypeID=6, 3.3%) records explicit rejections. The table is written primarily via AddDocumentClassification (bulk insert using the BackOffice.DocumentClassification table-valued parameter), and managed by UpdateDocumentClassification, RemoveDocumentClassification, and UpdateDocumentClassificationsExpiryDate.

---

## 2. Business Logic

### 2.1 Document Classification Assignment

**What**: BackOffice agents (or automated systems like Au10tix) classify each uploaded document by type, side, and date metadata.

**Columns Involved**: `DocumentID`, `DocumentTypeID`, `DocumentClassificationID`, `IssueDate`, `ExpiryDate`, `ManagerID`, `SideID`, `VisaTypeID`

**Rules**:
- AddDocumentClassification inserts one or more classification rows per document using the BackOffice.DocumentClassification TVP (COMOP-2095/2097, 2021-01-07).
- ManagerID=0 = Au10tix automated classification (comment "Authenticate by au10tix" in data).
- ManagerID>0 = manual BackOffice agent classification.
- DocumentClassificationID refines the DocumentTypeID: e.g., DocumentTypeID=2 (POI) + DocumentClassificationID=1 (Passport) or 3 (Driving License).
- VisaTypeID added 2022-05-10 (COMOP-4557): for US visa documents (DocumentClassificationID=65 "US Visa"), specifies the visa type (H1B, F1, G4, etc.). NULL for 99.9% of rows.
- SideID specifies which side(s) of the document: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for 40.3% of older rows that predate this field.

### 2.2 Document Rejection Workflow

**What**: When a document is rejected, RejectReasonID records why, and RejectEmailSent tracks whether the customer was notified.

**Columns Involved**: `DocumentTypeID`, `RejectReasonID`, `RejectEmailSent`

**Rules**:
- DocumentTypeID=6 ("Not Accepted") is the rejection indicator - 43,757 rows (3.3%).
- For rejections, RejectReasonID specifies the detailed reason from Dictionary.DocumentRejectReason (54 possible values covering POI, POA, Selfie, SSN, and general rejection reasons).
- Top rejection reasons: 15=POA - proof of address cannot be accepted (34,289), 4=POI - Expired Document (4,205), 38=SSN Card - Cannot be accepted (1,618), 14=POA - Missing address details (1,090).
- RejectEmailSent: 1=rejection notification email sent to customer, 0/NULL=not sent. NULL for 96.9% of rows.
- DocumentRejectReasonToNotificationType table maps RejectReasonIDs to notification templates sent to the customer.

### 2.3 Document Expiry Management

**What**: IssueDate and ExpiryDate track the document's validity window. ExpiryDate drives compliance alerts for expired documents.

**Columns Involved**: `IssueDate`, `ExpiryDate`, `DocumentTypeID`

**Rules**:
- ExpiryDate is critical for POI (passports expire) and time-limited forms (W-8BEN MaxAgeInMonths=36, W9 MaxAgeInMonths=36, Authorization Form MaxAgeInMonths=60).
- POA (DocumentTypeID=1) has MaxAgeInMonths=36 in Dictionary.DocumentType - records older than 36 months are considered expired.
- UpdateDocumentClassificationsExpiryDate: dedicated procedure to update ExpiryDate on existing classifications.
- GetExpiredIdentityDocuments: queries this table for documents past their ExpiryDate, used in compliance workflows.
- SignedDate: records when an authorization form was signed (relevant for DocumentTypeID=4 "Authorization Form").
- Note: some Occurred timestamps reach 2034 - these appear to be far-future default values used as "never expires" sentinels.

---

## 3. Data Overview

| DocumentToDocumentTypeID | DocumentTypeID | DocumentClassificationID | ManagerID | RejectReasonID | Meaning |
|--------------------------|----------------|--------------------------|-----------|----------------|---------|
| 1 | 1 (POA) | NULL | 728 | NULL | Earliest classification - a Proof of Address manually classified by BackOffice agent 728 in 2016. IssueDate=2016-10-13, no expiry set. Pre-dates DocumentClassificationID (NULL). |
| 37 | 2 (POI) | NULL | 0 | NULL | Au10tix automated classification (ManagerID=0, Comment="Authenticate by au10tix"). ExpiryDate=2020-02-15. Automated pipeline pre-dates DocumentClassificationID field. |
| (rejection) | 6 (Not Accepted) | NULL | >0 | 15 | POA rejected: "Proof of address cannot be accepted". Most common rejection reason (34,289 rows). BackOffice agent sets DocumentTypeID=6 and provides RejectReasonID. |
| (W9 record) | 14 (W9) | 42 (Oct 2018) | >0 | NULL | US tax form W9 classification. Second most common type (240,463 rows). US customers must provide W9 for FATCA compliance. DocumentClassificationID=42 refers to "Oct 2018" W9 form version. |
| (W-8BEN) | 12 (W-8BEN) | 39 or 62 | >0 | NULL | Foreign tax form W-8BEN for non-US customers. Third most common (101,696 rows). MaxAgeInMonths=36 - expires every 3 years and must be re-submitted. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DocumentToDocumentTypeID | int IDENTITY(1,1) | NO | - | VERIFIED | Auto-generated unique classification record ID. NOT FOR REPLICATION. Clustered PK. Referenced by BackOffice.CustomerTranslationDetails (via DocumentToDocumentTypeID). |
| 2 | DocumentID | int | NO | - | VERIFIED | The document being classified. FK (WITH CHECK) to BackOffice.CustomerDocument(DocumentID). Multiple rows per DocumentID are allowed (re-classification history). Part of the UNIQUE constraint. |
| 3 | DocumentTypeID | int | NO | - | VERIFIED | The formal document type assigned by the BackOffice agent or automation. FK (WITH CHECK) to Dictionary.DocumentType. Key values: 1=Proof of Address (7.5%), 2=Proof of Identity (59.8%), 3=Credit Card (1.0%), 6=Not Accepted - rejected (3.3%), 12=W-8BEN Form (7.7%), 14=W9 (18.1%), 15=Selfie, 17=VideoIdent, 18=SelfieLiveliness, 22=SSN Card. MaxAgeInMonths in Dictionary.DocumentType defines validity period. |
| 4 | IssueDate | datetime | YES | NULL | CODE-BACKED | The date the document was issued (e.g., passport issue date). NULL for document types where issue date is not relevant (most POI records use ExpiryDate instead). For POA, IssueDate is when the utility bill/bank statement was issued. Part of the UNIQUE constraint to allow re-classification with different dates. |
| 5 | ExpiryDate | datetime | YES | NULL | VERIFIED | The date after which this document classification is considered expired and must be re-submitted. Critical for passport expiry (POI), POA staleness (36 months), W-8BEN/W9 renewals. GetExpiredIdentityDocuments queries this field. Some rows have ExpiryDate=2034 as a sentinel "no expiry" value. Part of UNIQUE constraint. |
| 6 | FundingID | int | YES | NULL | CODE-BACKED | Links this classification to a specific payment/funding record when the document is associated with a credit card or payment method verification (e.g., credit card copy). FK (WITH CHECK) to Billing.Funding(FundingID). NULL for 99% of rows - only populated for DocumentTypeID=3 (Credit Card) cases. Part of UNIQUE constraint. Filtered NC index for fast FundingID lookups. |
| 7 | ManagerID | int | YES | - | VERIFIED | BackOffice agent who performed this classification. 0=Au10tix automated classification system. Non-zero=manual BackOffice agent (FK semantics to BackOffice.Manager, no constraint). NULL for 1 row only (data anomaly). |
| 8 | Comment | varchar(1024) | YES | - | VERIFIED | Agent's note or automation message for this classification. Common values: "" (empty, BackOffice agent with no note), "Authenticate by au10tix" (automated), specific rejection explanation text. Max 1024 chars. |
| 9 | RejectReasonID | int | YES | - | VERIFIED | Rejection reason when DocumentTypeID=6 (Not Accepted). Implicit FK to Dictionary.DocumentRejectReason. NULL for 96.7% of rows (approved/pending classifications). Top values: 15=POA cannot be accepted (34,289), 4=POI Expired (4,205), 38=SSN not acceptable (1,618), 14=POA missing address (1,090). See Section 2.2 for full reason list. |
| 10 | RejectEmailSent | bit | YES | - | VERIFIED | Whether the rejection notification email was sent to the customer. 1=sent, 0=not sent, NULL=not applicable (non-rejection classification). NULL for 96.9% of rows. Used with DocumentRejectReasonToNotificationType to determine email template. |
| 11 | Translated | smallint | YES | - | CODE-BACKED | Flag indicating whether a translation was provided for this document (for non-English documents requiring translation). 1=translated. NULL for 99.9% of rows - rarely used. Updated via CustomerDocumentTypeUpdateTranslatedStatus procedure. |
| 12 | DocumentClassificationID | int | YES | - | VERIFIED | Sub-classification refining the DocumentTypeID. FK (WITH CHECK) to Dictionary.DocumentClassification. Examples under DocumentTypeID=2 (POI): 1=Passport, 2=ID, 3=Driving License, 4=Electoral Card, 46=Residence Permit. Under DocumentTypeID=1 (POA): 6=Utility Bill, 7=Bank Statement, 40=Driving License POA. NULL for older rows that predate this field. 73 classification values in total. |
| 13 | SignedDate | datetime | YES | - | CODE-BACKED | Date the document was signed. Relevant for DocumentTypeID=4 (Authorization Form) and DocumentTypeID=9 (Client Forms). NULL for most rows. |
| 14 | Occurred | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when this classification record was created. Default GETUTCDATE(). NULL for rows created before this column was added (pre-2020). Latest value extends to 2034 in some rows - these appear to be sentinel values (not actual classification dates). |
| 15 | SideID | int | YES | NULL | VERIFIED | Which side(s) of the physical document were submitted. FK (WITH CHECK) to Dictionary.DocumentSide. Values: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for 40.3% of rows (pre-dates this field or not applicable for single-sided documents). Part of UNIQUE constraint. |
| 16 | VisaTypeID | int | YES | - | CODE-BACKED | US work/student visa type for visa documents (DocumentClassificationID=65 "US Visa"). FK (WITH CHECK) to Dictionary.VisaType. Values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. NULL for 99.9% of rows. Added 2022-05-10 per COMOP-4557 to support US eToro customers with non-citizen work visas as POI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DocumentID | BackOffice.CustomerDocument | FK (WITH CHECK) | Parent document record |
| DocumentTypeID | Dictionary.DocumentType | FK (WITH CHECK) | Formal document type classification |
| FundingID | Billing.Funding | FK (WITH CHECK) | Associated payment record for CC documents |
| DocumentClassificationID | Dictionary.DocumentClassification | FK (WITH CHECK) | Sub-classification within DocumentType |
| SideID | Dictionary.DocumentSide | FK (WITH CHECK) | Physical side(s) of the document |
| VisaTypeID | Dictionary.VisaType | FK (WITH CHECK) | US visa type for visa documents |
| RejectReasonID | Dictionary.DocumentRejectReason | Implicit | Rejection reason category |
| ManagerID | BackOffice.Manager | Implicit | BackOffice agent who classified (0=Au10tix) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerTranslationDetails | DocumentToDocumentTypeID | FK | Links translated documents to classification records |
| BackOffice.AddDocumentClassification | DocumentToDocumentTypeID | WRITER | Primary insert via TVP |
| BackOffice.UpdateDocumentClassification | DocumentToDocumentTypeID | MODIFIER | Updates classification details |
| BackOffice.RemoveDocumentClassification | DocumentToDocumentTypeID | DELETER | Removes a classification |
| BackOffice.UpdateDocumentClassificationsExpiryDate | DocumentToDocumentTypeID | MODIFIER | Updates ExpiryDate |
| BackOffice.GetExpiredIdentityDocuments | ExpiryDate | READER | Compliance: finds expired documents |
| BackOffice.GetCustomerDocumentDetails | DocumentID | READER | Returns classifications per document |
| BackOffice.GetDocumentClassifications | DocumentID | READER | BackOffice UI classification display |
| BackOffice.GetAllDocumentClassifications | DocumentID | READER | Full classification report |
| BackOffice.GetLastRiskPoiPoa | DocumentID | READER | Latest POI/POA for risk assessment |
| BackOffice.GetRedeemDisplayData | DocumentID | READER | Document status in redemption workflow |
| BackOffice.GetUnapprovedWithdrawRequests | DocumentID | READER | Document verification for withdrawal approval |
| BackOffice.GetCustomerVerifiedCCFundings | FundingID | READER | CC document verification status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentToDocumentType (table)
- FK targets:
  ├── BackOffice.CustomerDocument (table)
  ├── Dictionary.DocumentType (table)
  ├── Billing.Funding (table)
  ├── Dictionary.DocumentClassification (table)
  ├── Dictionary.DocumentSide (table)
  └── Dictionary.VisaType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | FK on DocumentID - parent document |
| Dictionary.DocumentType | Table | FK on DocumentTypeID |
| Billing.Funding | Table | FK on FundingID |
| Dictionary.DocumentClassification | Table | FK on DocumentClassificationID |
| Dictionary.DocumentSide | Table | FK on SideID |
| Dictionary.VisaType | Table | FK on VisaTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerTranslationDetails | Table | FK via DocumentToDocumentTypeID |
| BackOffice.AddDocumentClassification | Procedure | WRITER (TVP bulk insert) |
| BackOffice.UpdateDocumentClassification | Procedure | MODIFIER |
| BackOffice.RemoveDocumentClassification | Procedure | DELETER |
| BackOffice.UpdateDocumentClassificationsExpiryDate | Procedure | MODIFIER (expiry updates) |
| BackOffice.GetExpiredIdentityDocuments | Procedure | READER (compliance) |
| BackOffice.GetCustomerDocumentDetails | Procedure | READER (UI) |
| BackOffice.GetDocumentClassifications | Procedure | READER (UI) |
| BackOffice.GetAllDocumentClassifications | Procedure | READER (report) |
| BackOffice.GetLastRiskPoiPoa | Procedure | READER (risk) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BICDTDT_DocumentToDocumentTypeID | CLUSTERED PK | DocumentToDocumentTypeID ASC | - | - | Active (FILLFACTOR=90) |
| UN_BCCDTDT | UNIQUE NC | DocumentID, DocumentTypeID, IssueDate, ExpiryDate, FundingID, SideID | - | - | Active (FILLFACTOR=70) |
| IX_CustomerDocumentToDocumentType_FundingID | NC (Filtered) | FundingID ASC | - | WHERE FundingID IS NOT NULL | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BICDTDT_DocumentToDocumentTypeID | PK | DocumentToDocumentTypeID uniqueness |
| UN_BCCDTDT | UNIQUE | Prevents exact duplicate classification entries on the 6 key columns |
| BOCDTDTDI | FK (WITH CHECK) | DocumentID -> BackOffice.CustomerDocument(DocumentID) |
| BOCDTDTDTID | FK (WITH CHECK) | DocumentTypeID -> Dictionary.DocumentType(DocumentTypeID) |
| BOCDTDTFID | FK (WITH CHECK) | FundingID -> Billing.Funding(FundingID) |
| FK_BackOffice_CustomerDocumentToDocumentType_DocumentClassificationID | FK (WITH CHECK) | DocumentClassificationID -> Dictionary.DocumentClassification(DocumentClassificationID) |
| FK_BackOffice_CustomerDocumentToDocumentType_SideID | FK (WITH CHECK) | SideID -> Dictionary.DocumentSide(SideID) |
| (unnamed) | FK (WITH CHECK) | VisaTypeID -> Dictionary.VisaType(VisaTypeID) |
| DF_BCCDTDT_ID | DEFAULT | IssueDate = NULL |
| DF_BCCDTDT_ED | DEFAULT | ExpiryDate = NULL |
| DF_BCCDTDT_FID | DEFAULT | FundingID = NULL |
| Df_BackOffice_CustomerDocumentToDocumentType_Occurred | DEFAULT | Occurred = GETUTCDATE() |
| DF_BCCDTDT_Side | DEFAULT | SideID = NULL |

---

## 8. Sample Queries

### 8.1 Get all current classifications for a customer's documents
```sql
SELECT
    cd.DocumentID,
    cd.DisplayName,
    dt.Name AS DocumentTypeName,
    dc.Name AS ClassificationName,
    c2dt.IssueDate,
    c2dt.ExpiryDate,
    c2dt.ManagerID,
    c2dt.Comment,
    ds.Name AS DocumentSide,
    c2dt.Occurred
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN BackOffice.CustomerDocumentToDocumentType c2dt WITH (NOLOCK) ON c2dt.DocumentID = cd.DocumentID
JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = c2dt.DocumentTypeID
LEFT JOIN Dictionary.DocumentClassification dc WITH (NOLOCK) ON dc.DocumentClassificationID = c2dt.DocumentClassificationID
LEFT JOIN Dictionary.DocumentSide ds WITH (NOLOCK) ON ds.SideID = c2dt.SideID
WHERE cd.CID = @CID
ORDER BY c2dt.Occurred DESC
```

### 8.2 Find documents that have expired and need re-submission
```sql
SELECT
    cd.CID,
    cd.DocumentID,
    cd.DisplayName,
    dt.Name AS DocumentTypeName,
    c2dt.ExpiryDate,
    c2dt.DocumentToDocumentTypeID
FROM BackOffice.CustomerDocumentToDocumentType c2dt WITH (NOLOCK)
JOIN BackOffice.CustomerDocument cd WITH (NOLOCK) ON cd.DocumentID = c2dt.DocumentID
JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = c2dt.DocumentTypeID
WHERE c2dt.ExpiryDate < GETUTCDATE()
  AND c2dt.DocumentTypeID IN (2, 12, 14)  -- POI, W-8BEN, W9
ORDER BY c2dt.ExpiryDate ASC
```

### 8.3 Rejection analysis by reason with document type context
```sql
SELECT
    dt.Name AS DocumentTypeName,
    drr.RejectReasonName,
    COUNT(*) AS RejectionCount
FROM BackOffice.CustomerDocumentToDocumentType c2dt WITH (NOLOCK)
JOIN Dictionary.DocumentType dt WITH (NOLOCK) ON dt.DocumentTypeID = c2dt.DocumentTypeID
JOIN Dictionary.DocumentRejectReason drr WITH (NOLOCK) ON drr.RejectReasonID = c2dt.RejectReasonID
WHERE c2dt.DocumentTypeID = 6  -- Not Accepted
  AND c2dt.RejectReasonID IS NOT NULL
GROUP BY dt.Name, drr.RejectReasonName
ORDER BY RejectionCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COMOP-2095/2097 | Jira | Change Classification CRUD to eliminate Prod errors - Yulia Kramer 2021-01-07 |
| COMOP-4557 | Jira | Added VisaTypeID to POI Document Classification - Michal Bogucki 2022-05-10 |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentToDocumentType | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerDocumentToDocumentType.sql*
