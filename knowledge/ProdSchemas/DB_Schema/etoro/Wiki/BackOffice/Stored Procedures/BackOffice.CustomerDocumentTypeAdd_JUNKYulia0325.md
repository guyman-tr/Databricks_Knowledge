# BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325

> UPSERT a document-type classification record for a KYC document (BackOffice.CustomerDocumentToDocumentType), enforcing 6 type-specific validation rules before writing. Marked JUNK by Yulia (March 2025) - superseded by the newer document classification pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DocumentID + @DocumentTypeID (document being classified) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure attaches a document type classification to an existing KYC document in `BackOffice.CustomerDocumentToDocumentType`. It is the write path used by BackOffice agents when they review an uploaded document and tag it with its type (Passport, Proof of Identity, Credit Card, etc.) along with type-specific metadata such as issue date, expiry date, and funding reference.

The procedure implements an UPSERT pattern: if `@DocumentToDocumentTypeID` is supplied and the row exists, it performs an UPDATE; otherwise it performs an INSERT. Both branches include duplicate-prevention guards to ensure no exact duplicate classification (same DocumentID + DocumentTypeID + IssueDate + ExpiryDate + FundingID) is created.

Before writing, 6 validation checks enforce business rules specific to each document type. All validation failures raise error 60024 and return without writing.

The JUNK suffix (`_JUNKYulia0325`) indicates this procedure was marked for deprecation by Yulia in March 2025. It represents the legacy document classification write path; the modern pipeline uses a different SP. Created by Geri Reshef (July 2017, OPS0244 - Translation and Update of Verification Info).

---

## 2. Business Logic

### 2.1 Validation Gate - 6 Rules Before Any Write

**What**: All 6 checks must pass before the UPSERT executes. All failures raise the same error number (60024) with distinct messages.

**Columns/Parameters Involved**: @DocumentID, @DocumentTypeID, @IssueDate, @ExpiryDate, @FundingID, @Comment, @RejectReasonID

**Rules**:

| # | Condition | Error Message |
|---|-----------|---------------|
| 1 | BackOffice.CustomerDocument WHERE DocumentID=@DocumentID must exist | 'Document Does Not Exist!' |
| 2 | Dictionary.DocumentType WHERE DocumentTypeID=@DocumentTypeID must exist | 'Document Type ID Does Not Exist!' |
| 3 | If Dictionary.DocumentType.MaxAgeInMonths IS NOT NULL for this type AND @IssueDate IS NULL | 'Issue Date required For this document Type' |
| 4 | If @DocumentTypeID=2 (Proof of Identity) AND @ExpiryDate IS NULL | 'Expiry Date Is required For proof of Identity' |
| 5 | If @DocumentTypeID=3 (Credit Card) AND @FundingID IS NULL | 'FundingID Is required For Credit Card Document' |
| 6 | If @DocumentTypeID=6 (Not Accepted) AND (@Comment IS NULL OR @RejectReasonID IS NULL) | 'Comment Is required For Not Accepted document' |

All use `RAISERROR(60024, 16, 1, message)` and are caught by the outer TRY/CATCH which re-throws with THROW.

### 2.2 UPSERT Branch Logic

**What**: Mode is determined by whether @DocumentToDocumentTypeID matches an existing row.

**Rules**:

**UPDATE branch** (when @DocumentToDocumentTypeID IS NOT NULL AND EXISTS in table):
- Updates all classification fields on the matching row
- WHERE guard: NOT EXISTS a different row with the same (DocumentID, DocumentTypeID, IssueDate, ExpiryDate, FundingID) - prevents duplicate creation during UPDATE
- If duplicate would result: UPDATE executes 0 rows but @Result is still set to the original row ID (silent no-op)
- @Result = @DocumentToDocumentTypeID (SELECT after UPDATE)

**INSERT branch** (when @DocumentToDocumentTypeID IS NULL or not found):
- Inserts using SELECT with 4 safety WHERE guards:
  1. NOT EXISTS duplicate row (same DocumentID + DocumentTypeID + IssueDate + ExpiryDate + FundingID)
  2. EXISTS BackOffice.CustomerDocument for @DocumentID (re-validates)
  3. EXISTS Dictionary.DocumentType for @DocumentTypeID (re-validates)
  4. EXISTS Billing.Funding for @FundingID (validates funding reference; if @FundingID IS NULL, ISNULL coalesces to always-true match)
- @Result = SCOPE_IDENTITY() - returns NULL if duplicate guard prevented insert (0 rows inserted)

**Result output**: Both branches do `SELECT @Result` as a result set in addition to the OUTPUT parameter, so callers receive the DocumentToDocumentTypeID via both channels.

### 2.3 Document Type Business Rules (Known Types)

**Rules**:
- DocumentTypeID=2 = Proof of Identity (POI): ExpiryDate required (government-issued ID expiry for AML compliance)
- DocumentTypeID=3 = Credit Card: FundingID required (links classification to specific payment method in Billing.Funding)
- DocumentTypeID=6 = Not Accepted: Comment + RejectReasonID required (rejection must be documented with reason)
- DocumentTypes with MaxAgeInMonths set (any type): IssueDate required (document age validation for compliance)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DocumentToDocumentTypeID | INT | YES | NULL | CODE-BACKED | If supplied and exists in BackOffice.CustomerDocumentToDocumentType: triggers UPDATE mode. If NULL or not found: triggers INSERT mode. |
| 2 | @DocumentID | INT | NO | - | CODE-BACKED | ID of the document being classified. Must exist in BackOffice.CustomerDocument (validation check 1). FK to BackOffice.CustomerDocument.DocumentID. |
| 3 | @DocumentTypeID | INT | NO | - | CODE-BACKED | Document type to assign. Must exist in Dictionary.DocumentType (validation check 2). Known values: 2=POI, 3=Credit Card, 6=Not Accepted. Additional types defined in Dictionary.DocumentType. |
| 4 | @IssueDate | DATETIME | YES | NULL | CODE-BACKED | Issue date of the document. Required when Dictionary.DocumentType.MaxAgeInMonths IS NOT NULL (validation check 3). Used for document age compliance checking. |
| 5 | @ExpiryDate | DATETIME | YES | NULL | CODE-BACKED | Expiry date. Required for @DocumentTypeID=2 (Proof of Identity) per AML requirements (validation check 4). |
| 6 | @FundingID | INT | YES | NULL | CODE-BACKED | Billing funding reference. Required for @DocumentTypeID=3 (Credit Card) to link classification to a specific payment method in Billing.Funding (validation check 5). NULL for non-card types. |
| 7 | @ManagerID | INT | YES | NULL | CODE-BACKED | BackOffice agent ID performing the classification. NULL = system/automated (e.g., Au10tix pipeline). 0 also used for automated classification. |
| 8 | @Comment | VARCHAR(1024) | YES | NULL | CODE-BACKED | Free-text comment about the classification. Required for @DocumentTypeID=6 (Not Accepted) - must document rejection reason in text (validation check 6). |
| 9 | @RejectReasonID | INT | YES | NULL | CODE-BACKED | Structured rejection reason ID. Required for @DocumentTypeID=6 (Not Accepted) alongside @Comment (validation check 6). |
| 10 | @RejectEmailSent | BIT | YES | NULL | CODE-BACKED | Flag indicating whether a rejection email has been sent to the customer. NULL = not applicable or not yet sent. |
| 11 | @Result | INT OUTPUT | YES | - | CODE-BACKED | OUTPUT parameter. Returns DocumentToDocumentTypeID of the inserted or updated row. NULL if duplicate prevention blocked an INSERT (0 rows inserted - SCOPE_IDENTITY() returns NULL). |

**Result Set:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 12 | (scalar) | INT | YES | CODE-BACKED | Same value as @Result OUTPUT - DocumentToDocumentTypeID. Returned via SELECT @Result at end of procedure. NULL if insert was blocked by duplicate guard. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DocumentID | BackOffice.CustomerDocument | SELECT (validation) + INSERT/UPDATE target | Validates document exists; DocumentID is FK in CustomerDocumentToDocumentType |
| @DocumentID + @DocumentTypeID | BackOffice.CustomerDocumentToDocumentType | INSERT / UPDATE | Inserts or updates the document-type classification row |
| @DocumentTypeID | Dictionary.DocumentType | SELECT (validation) | Validates document type exists; checks MaxAgeInMonths for IssueDate requirement |
| @FundingID | Billing.Funding | SELECT (validation, INSERT guard) | Validates funding reference in INSERT branch; ISNULL coalesces to always-true when @FundingID IS NULL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice KYC classification UI | External | Direct call | Original document-type assignment path; superseded by newer SP |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325 (procedure)
|- BackOffice.CustomerDocument (table) [SELECT: validate document exists; FK target]
|- BackOffice.CustomerDocumentToDocumentType (table) [INSERT/UPDATE: classification target]
|- Dictionary.DocumentType (table) [SELECT: validate type + MaxAgeInMonths check]
|- Billing.Funding (table) [SELECT: validate FundingID in INSERT branch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerDocument | Table | Validation check 1: document must exist. DocumentID FK. |
| BackOffice.CustomerDocumentToDocumentType | Table | UPSERT target: writes classification record |
| Dictionary.DocumentType | Table | Validation checks 2+3: type must exist; MaxAgeInMonths drives IssueDate requirement |
| Billing.Funding | Table | Validation in INSERT branch: FundingID checked when @FundingID IS NOT NULL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice document classification pipeline | External | Calls this SP to classify uploaded documents |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Error 60024 | Application | All 6 validation failures raise the same error number; callers check for 60024 |
| TRY/CATCH + THROW | Design | Detailed PRINT diagnostic on catch (server, DB, proc, line, message, error), then THROW to re-raise to caller |
| Duplicate prevention (UPDATE) | Application | UPDATE WHERE NOT EXISTS same combo (excl. current row) - silent no-op if would create duplicate |
| Duplicate prevention (INSERT) | Application | INSERT SELECT WHERE NOT EXISTS same combo - 0 rows inserted if duplicate; @Result = NULL in that case |
| INSERT safety re-validation | Design | INSERT branch re-checks CustomerDocument, DocumentType, Billing.Funding existence inside SELECT WHERE - belt-and-suspenders after initial validation gate |
| JUNK designation | Lifecycle | Marked for deprecation by Yulia March 2025; do not use for new development |

---

## 8. Sample Queries

### 8.1 Add a Proof of Identity classification to a document

```sql
DECLARE @ResultID INT;
EXEC BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325
    @DocumentToDocumentTypeID = NULL,        -- INSERT mode
    @DocumentID = 12345,
    @DocumentTypeID = 2,                     -- POI: requires ExpiryDate
    @IssueDate = '2020-01-15',
    @ExpiryDate = '2030-01-14',
    @FundingID = NULL,
    @ManagerID = 99,
    @Comment = NULL,
    @RejectReasonID = NULL,
    @RejectEmailSent = NULL,
    @Result = @ResultID OUTPUT;
SELECT @ResultID AS DocumentToDocumentTypeID;
```

### 8.2 Add a Credit Card classification (requires FundingID)

```sql
DECLARE @ResultID INT;
EXEC BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325
    @DocumentToDocumentTypeID = NULL,
    @DocumentID = 99999,
    @DocumentTypeID = 3,                     -- Credit Card: requires FundingID
    @IssueDate = NULL,
    @ExpiryDate = '2027-06-30',
    @FundingID = 777,
    @ManagerID = 0,
    @Comment = NULL,
    @RejectReasonID = NULL,
    @RejectEmailSent = NULL,
    @Result = @ResultID OUTPUT;
SELECT @ResultID AS DocumentToDocumentTypeID;
```

### 8.3 Mark a document as Not Accepted (requires Comment + RejectReasonID)

```sql
DECLARE @ResultID INT;
EXEC BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325
    @DocumentToDocumentTypeID = NULL,
    @DocumentID = 55555,
    @DocumentTypeID = 6,                     -- Not Accepted: requires Comment + RejectReasonID
    @IssueDate = NULL,
    @ExpiryDate = NULL,
    @FundingID = NULL,
    @ManagerID = 42,
    @Comment = 'Document is blurry and unreadable',
    @RejectReasonID = 3,
    @RejectEmailSent = 0,
    @Result = @ResultID OUTPUT;
SELECT @ResultID AS DocumentToDocumentTypeID;
```

### 8.4 Verify classification was written

```sql
SELECT DocumentToDocumentTypeID, DocumentID, DocumentTypeID, IssueDate, ExpiryDate,
       FundingID, ManagerID, Comment, RejectReasonID, RejectEmailSent
FROM BackOffice.CustomerDocumentToDocumentType WITH (NOLOCK)
WHERE DocumentID = 12345
ORDER BY DocumentToDocumentTypeID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Created per OPS0244 (Translation and Update of Verification Info DB Changes, July 2017).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerDocumentTypeAdd_JUNKYulia0325.sql*
