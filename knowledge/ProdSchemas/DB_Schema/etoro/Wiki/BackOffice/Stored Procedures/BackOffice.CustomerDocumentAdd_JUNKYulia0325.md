# BackOffice.CustomerDocumentAdd_JUNKYulia0325

> Adds a new document record for a customer (KYC upload) and sets DocumentStatusID=1 on the customer unless the document is a CashoutInfo.txt file. Marked JUNK by Yulia (March 2025) - superseded by newer document upload pipeline.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @FileName (document being added) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure adds a new customer KYC document record to `BackOffice.CustomerDocument` and conditionally updates the customer's `DocumentStatusID` to 1 (documents received/pending review) in `BackOffice.Customer`. It is part of the original document upload pipeline used when BackOffice agents manually upload identity documents for a customer.

The JUNK suffix (`_JUNKYulia0325`) indicates this procedure was marked for deprecation by Yulia in March 2025 as part of a cleanup initiative. It represents the legacy document add path; the modern pipeline uses `BackOffice.InsertCustomerDocument` or `BackOffice.InsertDocument`.

The `CashoutInfo.txt` exclusion is a specific business rule: when a system uploads a cashout-related info file (not a KYC document), the customer's DocumentStatusID should NOT be changed - only actual KYC documents trigger the status change.

---

## 2. Business Logic

### 2.1 DocumentStatusID Update Exclusion for CashoutInfo.txt

**What**: System-uploaded `CashoutInfo.txt` files should not change the customer's document verification status.

**Columns/Parameters Involved**: `@DisplayName`, `BackOffice.Customer.DocumentStatusID`

**Rules**:
- If `@DisplayName NOT LIKE '%CashoutInfo.txt'`: UPDATE BackOffice.Customer SET DocumentStatusID = 1 WHERE CID = @CID
- If `@DisplayName LIKE '%CashoutInfo.txt'`: only INSERT the document, no status update
- DocumentStatusID=1 = documents have been added/received (pending review state)
- RETURN @@ERROR: returns 0 on success, SQL error number on failure (legacy pattern)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Used to identify which customer's document record to add and whose DocumentStatusID to update. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | BackOffice agent ID performing the upload. Maps to BackOffice.Manager.ManagerID. 0 = automated system upload. |
| 3 | @DisplayName | NVARCHAR(250) | NO | - | CODE-BACKED | Filename shown to BackOffice agents and the customer (original uploaded filename). Increased from VARCHAR(20) to NVARCHAR(250) in FB:19060. The '%CashoutInfo.txt' check is applied to this field. |
| 4 | @ComputerName | VARCHAR(50) | NO | - | CODE-BACKED | Name of the computer from which the document was uploaded. Audit/provenance field. |
| 5 | @FileName | NVARCHAR(255) | NO | - | CODE-BACKED | Internal stored filename in the document storage system (may differ from DisplayName after transformation). |
| 6 | @DateAdded | DATETIME | NO | - | CODE-BACKED | Timestamp the document was added. Stored as DateAdded in BackOffice.CustomerDocument. |
| 7 | @SizeType | INTEGER | NO | - | CODE-BACKED | Document size action type ID (DocumentSizeActionTypeID in BackOffice.CustomerDocument). Indicates the size category or action associated with the file. |
| 8 | @Accounting | BIT | YES | 0 | CODE-BACKED | Whether the document is flagged for accounting purposes. Default 0 = not an accounting document. |
| 9 | @Comment | VARCHAR(255) | YES | NULL | CODE-BACKED | Optional free-text comment about the document. NULL = no comment. |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 10 | RETURN | INT | 0 = success (@@ERROR = 0). Non-zero SQL error code on failure. Legacy error-return pattern (no RAISERROR). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets DocumentStatusID=1 when DisplayName is not a CashoutInfo.txt file |
| @CID | BackOffice.CustomerDocument | INSERT | Adds the new document record for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy BackOffice document upload UI | External | Direct call | Original manual document upload path; superseded by newer procedures |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerDocumentAdd_JUNKYulia0325 (procedure)
|- BackOffice.Customer (table) [UPDATE DocumentStatusID]
|- BackOffice.CustomerDocument (table) [INSERT new document record]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: sets DocumentStatusID=1 for the customer (unless CashoutInfo.txt) |
| BackOffice.CustomerDocument | Table | INSERT: adds the new document metadata record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy BackOffice upload pipeline | External | Direct call - now superseded |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CashoutInfo.txt exclusion | Application | DisplayName NOT LIKE '%CashoutInfo.txt' is the guard for DocumentStatusID update |
| RETURN @@ERROR | Design | Legacy error handling pattern - returns SQL error code directly, no TRY/CATCH |
| JUNK designation | Lifecycle | Marked for deprecation by Yulia March 2025; do not use for new development |

---

## 8. Sample Queries

### 8.1 Add a KYC document for a customer (legacy path)

```sql
EXEC BackOffice.CustomerDocumentAdd_JUNKYulia0325
    @CID = 12345,
    @ManagerID = 0,
    @DisplayName = N'passport_front.jpg',
    @ComputerName = 'UPLOAD-SERVER-01',
    @FileName = N'12345_passport_20260317.jpg',
    @DateAdded = '2026-03-17',
    @SizeType = 1,
    @Accounting = 0,
    @Comment = NULL
```

### 8.2 Verify document was added

```sql
SELECT TOP 5 DocumentID, CID, DisplayName, DateAdded, ManagerID
FROM BackOffice.CustomerDocument WITH (NOLOCK)
WHERE CID = 12345
ORDER BY DocumentID DESC
```

### 8.3 Check customer DocumentStatusID after upload

```sql
SELECT CID, DocumentStatusID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345
-- DocumentStatusID=1 if a non-CashoutInfo document was added
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched | Corrections: 0 applied*
*Object: BackOffice.CustomerDocumentAdd_JUNKYulia0325 | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerDocumentAdd_JUNKYulia0325.sql*
