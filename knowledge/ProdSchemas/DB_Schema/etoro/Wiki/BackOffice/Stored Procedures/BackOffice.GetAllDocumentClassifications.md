# BackOffice.GetAllDocumentClassifications

> Returns all KYC document classifications for a customer (identified by GCID), optionally filtered by document type, used by the BackOffice DocAPI layer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid - global customer identifier (GCID); returns one row per classification record |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAllDocumentClassifications` retrieves the complete KYC document classification history for a customer, joining the raw document upload records (`BackOffice.CustomerDocument`) with their formal classification assignments (`BackOffice.CustomerDocumentToDocumentType`). Each result row represents one classification: a specific document was classified as a particular document type (e.g., Proof of Identity, W9, Proof of Address) by a BackOffice agent or automated system, with associated metadata like issue date, expiry date, rejection reason, and visa type.

The procedure was created as part of the migration to DocAPI (COMOP-533, Oct 2020) - BackOffice switched from direct SQL queries to calling this procedure via a service layer, enabling consistent data access with retry logic. The @gcid parameter (Global Customer ID) rather than CID is used because DocAPI operates at the global identity level, resolving the CID internally via Customer.CustomerStatic.

The optional @docType filter allows callers to retrieve classifications only for a specific document type (e.g., all Proof of Identity records, or all W9 records), reducing data volume for targeted UI panels. Without the filter, all classifications across all document types are returned.

---

## 2. Business Logic

### 2.1 GCID-to-CID Resolution

**What**: The procedure accepts GCID (global identity, cross-jurisdiction) but queries data by CID (single account ID), performing an internal lookup.

**Columns/Parameters Involved**: `@gcid`, `@CID (internal variable)`, `Customer.CustomerStatic`

**Rules**:
- First statement: `SELECT @CID = CID FROM Customer.CustomerStatic WHERE GCID = @gcid`
- If no matching CID is found, @CID remains NULL and the main query returns 0 rows (no error).
- Only the first matching CID is used (implicit TOP 1 via assignment to scalar variable).
- GCID is the preferred input for DocAPI integrations to avoid callers needing to know the account-level CID.

**Diagram**:
```
@gcid (Global Customer ID)
        |
Customer.CustomerStatic WHERE GCID = @gcid
        |
        +--- Found -> @CID = matching CID
        +--- Not Found -> @CID = NULL -> 0 rows returned
        |
BackOffice.CustomerDocument WHERE CID = @CID
```

### 2.2 Optional Document Type Filter

**What**: @docType restricts the result to a single document type classification, used by UI panels showing a specific KYC category.

**Columns/Parameters Involved**: `@docType`, `dt.DocumentTypeID`

**Rules**:
- When @docType IS NULL: all document classifications for the customer are returned (all document types).
- When @docType is provided: only rows where CustomerDocumentToDocumentType.DocumentTypeID = @docType are returned.
- Results are ordered by DocumentID ASC then DocumentToDocumentTypeID ASC, grouping all classifications for the same physical document together.

### 2.3 VisaTypeID for US Visa Holders

**What**: VisaTypeID was added in May 2022 (COMOP-4557) to support US non-citizen customers using work or student visas as Proof of Identity.

**Columns/Parameters Involved**: `VisaTypeID`, `DocumentClassificationID`

**Rules**:
- Only relevant when DocumentClassificationID=65 ("US Visa").
- Valid values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2 (Dictionary.VisaType).
- NULL for 99.9% of rows - not applicable for standard passport/ID/POA classifications.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Global Customer ID (GCID). Used by DocAPI layer to identify the customer across jurisdictions. Resolved to CID internally via Customer.CustomerStatic. |
| 2 | @docType | INT | YES | NULL | CODE-BACKED | Optional filter: restrict results to a single DocumentTypeID (e.g., 1=POA, 2=POI, 14=W9). When NULL, all classification types are returned. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer account ID (single jurisdiction). Resolved from @gcid internally. From BackOffice.CustomerDocument.CID. |
| 4 | DocumentToDocumentTypeID | INT | NO | - | VERIFIED | Primary key of the BackOffice.CustomerDocumentToDocumentType record. Uniquely identifies this classification assignment. |
| 5 | DocumentID | INT | NO | - | VERIFIED | Primary key of the BackOffice.CustomerDocument record - identifies the physical document file upload. One document can have multiple classification rows (multiple DocumentToDocumentTypeID values per DocumentID). |
| 6 | DocumentTypeID | INT | NO | - | VERIFIED | Type of document this classification assigns. FK to Dictionary.DocumentType. Key values: 1=POA (Proof of Address), 2=POI (Proof of Identity), 6=Not Accepted (rejection), 12=W-8BEN, 14=W9. |
| 7 | ClassifiedBy | INT | YES | - | CODE-BACKED | ManagerID of the BackOffice agent who performed this classification. Aliased from CustomerDocumentToDocumentType.ManagerID. 0=automated system (Au10tix, Onfido); >0=BackOffice agent ID (FK to BackOffice.Manager). |
| 8 | Comment | VARCHAR(1024) | YES | - | VERIFIED | Free-text note from the classifying agent or automation system. Common values: empty string (manual with no note), "Authenticate by au10tix" (automated). Used for rejection explanations. |
| 9 | IssueDate | DATETIME | YES | NULL | CODE-BACKED | Date the document was issued (e.g., passport issue date). NULL for many document types where this is not applicable or not recorded. |
| 10 | ExpiryDate | DATETIME | YES | NULL | CODE-BACKED | Date the document expires (e.g., passport expiry, W-8BEN 3-year expiry). NULL when not applicable. Expired documents trigger re-submission requests. |
| 11 | FundingID | INT | YES | - | CODE-BACKED | Associated payment instrument for credit card documents requiring KYC. FK to Billing.Funding. NULL for most document types (only relevant for card verification workflows). |
| 12 | RejectReasonID | INT | YES | - | VERIFIED | Rejection reason when DocumentTypeID=6 (Not Accepted). Implicit FK to Dictionary.DocumentRejectReason. NULL for approved classifications. Top values: 15=POA cannot be accepted, 4=POI Expired Document, 38=SSN not acceptable. |
| 13 | RejectEmailSent | BIT | YES | - | VERIFIED | Whether the rejection notification email was sent to the customer. 1=sent, 0/NULL=not sent. NULL for 96.9% of rows (non-rejection classifications). |
| 14 | DocumentClassificationID | INT | YES | - | VERIFIED | Sub-classification refining DocumentTypeID. FK (WITH CHECK) to Dictionary.DocumentClassification. Under DocumentTypeID=2 (POI): 1=Passport, 2=ID, 3=Driving License, 65=US Visa. Under DocumentTypeID=1 (POA): 6=Utility Bill, 7=Bank Statement. NULL for pre-2020 rows. |
| 15 | SignedDate | DATETIME | YES | - | CODE-BACKED | Date the document was signed. Relevant for DocumentTypeID=4 (Authorization Form) and 9 (Client Forms). NULL for most rows. |
| 16 | SideID | INT | YES | NULL | VERIFIED | Which physical side(s) of the document were submitted. FK (WITH CHECK) to Dictionary.DocumentSide. 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. NULL for 40.3% of rows (pre-dates this field). |
| 17 | Occurred | DATETIME | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when this classification record was created in BackOffice.CustomerDocumentToDocumentType. |
| 18 | VisaTypeID | INT | YES | - | CODE-BACKED | US work/student visa type when DocumentClassificationID=65 (US Visa). FK (WITH CHECK) to Dictionary.VisaType. Values: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. NULL for 99.9% of rows. Added 2022-05-10 per COMOP-4557 to support US non-citizen visa holders as POI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerStatic | Lookup | Resolves GCID to CID for the main query. |
| CID / DocumentID | BackOffice.CustomerDocument | Primary source | All document upload metadata for this customer. |
| DocumentToDocumentTypeID | BackOffice.CustomerDocumentToDocumentType | Primary source (JOIN) | All classification records for each document. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BOManagementService DocAPI layer (external, no SQL procedure callers in repository).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAllDocumentClassifications (procedure)
├── Customer.CustomerStatic (table)
├── BackOffice.CustomerDocument (table)
└── BackOffice.CustomerDocumentToDocumentType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | GCID-to-CID resolution: SELECT @CID WHERE GCID = @gcid. Cross-schema. |
| BackOffice.CustomerDocument | Table | Main document upload registry filtered by CID. |
| BackOffice.CustomerDocumentToDocumentType | Table | INNER JOIN on DocumentID to get all classification records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by the BackOffice DocAPI service. No SQL procedure callers in repository. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Uses NOLOCK hints on all tables. Results ordered by DocumentID ASC, DocumentToDocumentTypeID ASC.

---

## 8. Sample Queries

### 8.1 Get all document classifications for a customer by GCID
```sql
EXEC BackOffice.GetAllDocumentClassifications @gcid = 987654321;
```

### 8.2 Get only Proof of Identity (POI) classifications
```sql
-- DocumentTypeID=2 is Proof of Identity
EXEC BackOffice.GetAllDocumentClassifications
    @gcid = 987654321,
    @docType = 2;
```

### 8.3 Inline query to understand document classification status
```sql
SELECT
    cd.DocumentID,
    cd.CID,
    cdt.DocumentToDocumentTypeID,
    cdt.DocumentTypeID,
    cdt.DocumentClassificationID,
    cdt.IssueDate,
    cdt.ExpiryDate,
    cdt.RejectReasonID,
    cdt.VisaTypeID,
    cdt.Occurred
FROM BackOffice.CustomerDocument cd WITH (NOLOCK)
JOIN BackOffice.CustomerDocumentToDocumentType cdt WITH (NOLOCK)
    ON cdt.DocumentID = cd.DocumentID
JOIN Customer.CustomerStatic cs WITH (NOLOCK)
    ON cs.CID = cd.CID
WHERE cs.GCID = 987654321
ORDER BY cd.DocumentID, cdt.DocumentToDocumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [COMOP-533](https://etoro-jira.atlassian.net/browse/COMOP-533) | Jira | "Switch Backoffice to use DocApi instead direct call to SQL" - procedure created Oct 2020 as part of DocAPI migration; David Zalmanson. Added "more fields" to the returned dataset. |
| [COMOP-4557](https://etoro-jira.atlassian.net/browse/COMOP-4557) | Jira | "Support US Visa type - part 2" - VisaTypeID column added May 2022 to support US non-citizen visa holders as POI; part of US Visa holders onboarding initiative (COAKVU-172). |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 2 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAllDocumentClassifications | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetAllDocumentClassifications.sql*
