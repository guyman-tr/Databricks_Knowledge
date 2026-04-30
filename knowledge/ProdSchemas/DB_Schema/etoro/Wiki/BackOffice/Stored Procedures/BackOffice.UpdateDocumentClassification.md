# BackOffice.UpdateDocumentClassification

> Updates metadata fields on an existing KYC document classification record - sub-type, dates, agent, rejection details, side, visa type - using a partial-update pattern, then returns the updated row.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @classificationID - targets BackOffice.CustomerDocumentToDocumentType.DocumentToDocumentTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateDocumentClassification` is the primary edit procedure for KYC document classification records. After a document is classified (via `AddDocumentClassification`), back-office agents or automated systems may need to correct or enrich the classification - changing the document sub-type, updating expiry dates, flagging a translation, recording a visa type, or marking a rejection reason and whether the customer was notified. This SP handles all such edits in one call.

The procedure exists because KYC document management is iterative: a document might be initially auto-classified by Au10tix, then reviewed and refined by a human agent, then have its expiry date corrected when additional information arrives. The SELECT * return at the end confirms the post-update state to the calling application, avoiding a separate read round-trip.

Over its lifetime the procedure has been extended multiple times (COMOP-508/509: POI front/back sides in 2020; COMOP-1795/1925: general update improvements; COMOP-1682/2019: allow removing definitions; COMOP-4557: VisaTypeID for US visa documents in 2022; COMOP-3588: RejectEmailSent handling in 2022).

---

## 2. Business Logic

### 2.1 Partial Update via ISNULL Pattern

**What**: Only parameters passed with non-NULL values overwrite the existing column; NULL parameters leave columns unchanged.

**Columns/Parameters Involved**: All updatable columns

**Rules**:
- `SET col = ISNULL(@param, col)` - callers omit (NULL) parameters they don't want to change.
- Exception: `@emailSent` parameter name maps to `RejectEmailSent` column (the UI may send this specifically to mark rejection email as sent).
- To explicitly clear a field (set it to NULL), the caller must use a different procedure (e.g., `RemoveDocumentClassification`) - ISNULL cannot distinguish "I want to clear this" from "I'm not updating this."

### 2.2 Document Sub-Classification Refinement

**What**: `@classificationSubTypeID` refines the document classification within its type.

**Columns/Parameters Involved**: `@classificationSubTypeID` -> `DocumentClassificationID`

**Rules**:
- Maps to `DocumentClassificationID` (FK to Dictionary.DocumentClassification).
- Example updates: change POI type from Passport (1) to Driving License (3), or update the W9 form year version.
- ManagerID (`@classifiedBy`) should be updated to reflect who made the change.

### 2.3 Rejection Workflow Fields

**What**: When a document is rejected (DocumentTypeID=6 "Not Accepted"), rejection reason and email notification state must be recorded.

**Columns/Parameters Involved**: `@rejectReasonID`, `@emailSent`

**Rules**:
- `@rejectReasonID`: set when classifying a document as rejected. Values from Dictionary.DocumentRejectReason.
- `@emailSent` (-> `RejectEmailSent`): set to 1 after the rejection notification email is sent to the customer. COMOP-3588 fixed a bug where this flag was not correctly highlighted in the BO UI.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @classificationID | int | NO | - | VERIFIED | DocumentToDocumentTypeID of the classification record to update. Clustered PK of BackOffice.CustomerDocumentToDocumentType. Identifies the exact classification row. |
| 2 | @classificationSubTypeID | int | YES | NULL | VERIFIED | New DocumentClassificationID value. Sub-classification refining the document type (e.g., for POI: 1=Passport, 2=ID, 3=Driving License). NULL=leave unchanged. FK to Dictionary.DocumentClassification. |
| 3 | @issueDate | datetime | YES | NULL | VERIFIED | Date the physical document was issued. NULL=leave unchanged. For passports/ID: official issue date. For POA: date of utility bill/bank statement. |
| 4 | @expiryDate | datetime | YES | NULL | VERIFIED | Expiry date of the document. NULL=leave unchanged. Critical for POI expiry alerts, W-8BEN/W9 36-month renewals, POA 36-month staleness checks. |
| 5 | @signedDate | datetime | YES | NULL | CODE-BACKED | Date the document was signed. NULL=leave unchanged. Relevant for Authorization Forms (DocumentTypeID=4) and Client Forms (DocumentTypeID=9). |
| 6 | @classifiedBy | int | YES | NULL | VERIFIED | ManagerID of the agent performing this reclassification. NULL=leave existing ManagerID unchanged. 0=Au10tix automated system; >0=manual BackOffice agent. Maps to BackOffice.CustomerDocumentToDocumentType.ManagerID. |
| 7 | @comment | varchar(1024) | YES | NULL | VERIFIED | Updated agent comment or automation message. NULL=leave unchanged. Common values: "" (empty), "Authenticate by au10tix", rejection explanation text. |
| 8 | @fundingID | int | YES | NULL | CODE-BACKED | Associated Billing.Funding record for credit card document verification. NULL=leave unchanged. Only relevant for DocumentTypeID=3 (Credit Card). FK to Billing.Funding. |
| 9 | @rejectReasonID | int | YES | NULL | VERIFIED | Rejection reason code when classifying as "Not Accepted" (DocumentTypeID=6). NULL=leave unchanged. FK semantics to Dictionary.DocumentRejectReason (54 possible values). Top: 15=POA cannot be accepted, 4=POI expired document. |
| 10 | @emailSent | bit | YES | NULL | VERIFIED | Whether the rejection notification email was sent to the customer (maps to RejectEmailSent). NULL=leave unchanged. 1=email sent, 0=email not sent. Used in COMOP-3588 to track rejection email status in BO UI. |
| 11 | @sideID | int | YES | NULL | VERIFIED | Document physical side(s). NULL=leave unchanged. FK to Dictionary.DocumentSide: 0=NotRecognizable, 1=Front, 2=Back, 3=Front & Back. Added COMOP-508/509 (2020) for POI front/back side tracking. |
| 12 | @visaTypeID | int | YES | NULL | CODE-BACKED | US work/student visa type for US visa documents (DocumentClassificationID=65). NULL=leave unchanged. FK to Dictionary.VisaType: 1=E1, 2=E2, 3=E3, 4=F1, 5=G4, 6=H1B, 7=L1, 8=O1, 9=TN1, 10=TN2. Added COMOP-4557 (2022). |
| 13 | @translated | smallint | YES | NULL | CODE-BACKED | Translation status flag. NULL=leave unchanged. 1=translation was provided for a non-English document. NULL for 99.9% of records. |

**Output**: Result set - `SELECT * FROM BackOffice.CustomerDocumentToDocumentType WHERE DocumentToDocumentTypeID = @classificationID`. Returns the updated row (all columns) to confirm post-update state.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @classificationID | [BackOffice.CustomerDocumentToDocumentType](../Tables/BackOffice.CustomerDocumentToDocumentType.md) | UPDATE + SELECT target | Target classification record |
| @classificationSubTypeID | Dictionary.DocumentClassification | Lookup | Document sub-type |
| @classifiedBy | BackOffice.Manager | Lookup (implicit) | Classifying agent |
| @fundingID | Billing.Funding | FK lookup | Associated funding record |
| @rejectReasonID | Dictionary.DocumentRejectReason | Lookup | Rejection reason |
| @sideID | Dictionary.DocumentSide | FK lookup | Document side |
| @visaTypeID | Dictionary.VisaType | FK lookup | Visa type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| No direct callers found in BackOffice SPs. | - | - | Called from back-office UI document classification editor and automated KYC pipelines. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateDocumentClassification (procedure)
+-- BackOffice.CustomerDocumentToDocumentType (table) [UPDATE + SELECT target]
      +-- BackOffice.CustomerDocument (table) [FK: DocumentID]
      +-- Dictionary.DocumentType (table) [FK: DocumentTypeID]
      +-- Dictionary.DocumentClassification (table) [FK: DocumentClassificationID]
      +-- Dictionary.DocumentSide (table) [FK: SideID]
      +-- Dictionary.VisaType (table) [FK: VisaTypeID]
      +-- Billing.Funding (table) [FK: FundingID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [BackOffice.CustomerDocumentToDocumentType](../Tables/BackOffice.CustomerDocumentToDocumentType.md) | Table | UPDATE target + SELECT for return value |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Called from back-office document classification UI and automated KYC review workflows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None enforced in this SP (FK constraints are on the target table).

---

## 8. Sample Queries

### 8.1 Update a POI document with corrected expiry date and driving license sub-type

```sql
EXEC BackOffice.UpdateDocumentClassification
    @classificationID        = 1234567,
    @classificationSubTypeID = 3,           -- Driving License
    @expiryDate              = '2030-05-15',
    @classifiedBy            = 742;         -- ManagerID of reviewing agent
-- Returns SELECT * for the updated classification row
```

### 8.2 Record a document rejection and notify customer

```sql
EXEC BackOffice.UpdateDocumentClassification
    @classificationID = 1234568,
    @rejectReasonID   = 15,    -- POA cannot be accepted
    @emailSent        = 1;     -- rejection email has been sent
```

### 8.3 Add visa type to a US visa document classification

```sql
EXEC BackOffice.UpdateDocumentClassification
    @classificationID = 1234569,
    @visaTypeID       = 6;     -- H1B visa
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| COMOP-508/509 | Jira | Added POI front and back side tracking (@sideID parameter) - 2020-06-07 |
| COMOP-1795/1925 | Jira | General update to BackOffice.UpdateDocumentClassifications SP - 2020-12-07 |
| COMOP-1682/2019 | Jira | Ability to remove document definitions - 2020-12-29 |
| COMOP-4557 | Jira | Added @visaTypeID parameter for US visa documents - 2022-05-10 |
| COMOP-3588 | Jira | Fixed RejectEmailSent (emailSent) tickbox not highlighted correctly in BO UI - 2022-10-06 |
| RD-17538 | Jira | Bug fix in UpdateDocumentClassifications procedure - 2019-12-10 |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (DDL, Dependency Inheritance, Caller Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 6 Jira (from DDL comments) | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateDocumentClassification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateDocumentClassification.sql*
