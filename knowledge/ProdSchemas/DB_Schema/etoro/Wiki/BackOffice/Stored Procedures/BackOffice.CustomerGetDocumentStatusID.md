# BackOffice.CustomerGetDocumentStatusID

> Returns a customer's current DocumentStatusID from BackOffice.Customer via an OUTPUT parameter. Used to check the KYC document review state for a customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the `DocumentStatusID` for a customer from `BackOffice.Customer` and returns it via an OUTPUT parameter. It is used by callers that need to check the current KYC document review state of a customer (e.g., before deciding whether to prompt for document upload, or to branch on document status in a workflow).

`DocumentStatusID` encodes the state of the customer's KYC document process: whether no documents have been submitted, documents are pending review, documents have been approved, or documents have been rejected. Key value: DocumentStatusID=1 = documents received/pending review (set by `BackOffice.CustomerDocumentAdd_JUNKYulia0325`).

Note: The procedure header comment incorrectly states "Checks if the customer has performed phone verification" - this is a copy-paste error from a similar procedure. The actual behavior is retrieval of DocumentStatusID.

Created by Amir Moualem, October 2012. Not marked JUNK - still active.

---

## 2. Business Logic

### 2.1 Simple Scalar Lookup via OUTPUT Parameter

**What**: Retrieves DocumentStatusID for a CID. If CID not found, @DocumentStatusID remains NULL (no error raised).

**Rules**:
- SELECT @DocumentStatusID = DocumentStatusID FROM BackOffice.Customer WHERE CID=@CID
- SET NOCOUNT ON: no row count messages
- No error handling: if CID not found, @DocumentStatusID = NULL (SQL Server leaves OUTPUT parameter at its default when SELECT returns 0 rows)
- No TRY/CATCH: SQL errors propagate unhandled

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Must exist in BackOffice.Customer. If not found, @DocumentStatusID OUTPUT remains NULL. |

**Output Parameters:**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 2 | @DocumentStatusID | INT OUT | YES | CODE-BACKED | Current DocumentStatusID for the customer. NULL if CID not found or DocumentStatusID IS NULL in BackOffice.Customer. Key value: 1 = documents received/pending review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | SELECT | Reads DocumentStatusID for the given CID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice KYC workflow services | External | Direct call | Check document review state before branching workflow logic |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerGetDocumentStatusID (procedure)
|- BackOffice.Customer (table) [SELECT: DocumentStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | SELECT: reads DocumentStatusID for given CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC workflow services | External | Retrieve document status for branching logic |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |
| No error handling | Design | If CID not found, OUTPUT = NULL (no exception) |
| Misleading comment | Code quality | Procedure header says "phone verification" - incorrect copy-paste. Actual behavior: DocumentStatusID lookup. |

---

## 8. Sample Queries

### 8.1 Get document status for a customer

```sql
DECLARE @DocStatusID INT;
EXEC BackOffice.CustomerGetDocumentStatusID
    @CID = 12345,
    @DocumentStatusID = @DocStatusID OUTPUT;
SELECT @DocStatusID AS DocumentStatusID;
-- NULL = CID not found OR status not set
-- 1 = documents received, pending review
```

### 8.2 Direct query equivalent

```sql
SELECT CID, DocumentStatusID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerGetDocumentStatusID | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerGetDocumentStatusID.sql*
