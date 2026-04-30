# Customer.CustomerCommentBulkAppend

> Bulk prepends internal operational comments to customer records in Customer.Customer, with partial-success handling: invalid CIDs or comments that would exceed the 8000-character limit are collected and returned as the result set without updating the valid rows.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @tbl (batch of CID + comment pairs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.CustomerCommentBulkAppend allows mass-operations tooling (MassOperationsServiceUser role) to annotate large sets of customer accounts simultaneously. Each call accepts a batch of CID + comment text pairs and prepends the new comment to the front of each customer's existing Comments field, separated by a CRLF (carriage return + line feed). This creates a chronological stack: newest comment at the top, oldest at the bottom.

The procedure exists to support compliance, risk, and BackOffice mass-operation workflows where many customers must be annotated at once - fraud sweeps, compliance campaigns, bulk account reviews, or any scenario where a single operator action affects hundreds or thousands of accounts. Without this batch procedure, each comment would require a separate UPDATE call.

Partial success: the procedure handles failures gracefully by tracking two failure cases in @FailedComments (declared as Customer.TBL_CustomerComment) and returning them as the result set. Valid rows are always updated regardless of failures in other rows. The caller must inspect the returned result set to identify which rows were skipped and why.

---

## 2. Business Logic

### 2.1 Failure Case 1 - Invalid CID

**What**: A row in the input batch references a CID that does not exist in Customer.Customer.

**Columns/Parameters Involved**: `@tbl.CID`, `Customer.Customer.CID`, `@FailedComments`

**Rules**:
- SELECT from @tbl WHERE CID NOT IN (SELECT CID FROM Customer.Customer)
- Any input row with a non-existent CID goes to @FailedComments
- These rows are excluded from the UPDATE via LEFT JOIN + WHERE f.CID IS NULL

### 2.2 Failure Case 2 - Comment Length Overflow

**What**: The combined length of the new comment + CRLF + existing comment would exceed 8000 characters.

**Columns/Parameters Involved**: `@tbl.Comments`, `Customer.Customer.Comments`, `@FailedComments`

**Rules**:
- Check: LEN(CONCAT(t.Comments, CHAR(13), CHAR(10), ISNULL(C.Comments, ''))) > 8000
- If the new comment prepended to the existing comment would exceed varchar(8000), the row fails
- ISNULL(C.Comments, '') handles NULL existing comments (customer has no prior comments)
- These rows are excluded from the UPDATE even if the CID is valid

### 2.3 Prepend Logic

**What**: The actual comment update prepends the new comment before the existing comments.

**Columns/Parameters Involved**: `@tbl.Comments`, `Customer.Customer.Comments`

**Rules**:
- UPDATE: Comments = CONCAT(t.Comments, CHAR(13), CHAR(10), ISNULL(C.Comments, ''))
- New comment goes FIRST (most recent at top), CRLF separator, then old content
- ISNULL: if customer had no comments (NULL), the new comment is inserted cleanly with no trailing CRLF
- Applies only to rows where f.CID IS NULL (LEFT JOIN to @FailedComments excludes failures)
- Duplicate CIDs in @tbl are allowed: each will be applied as a separate UPDATE

### 2.4 Partial Success Return

**What**: Returns the failed rows so the caller can identify and retry or log them.

**Rules**:
- SELECT * FROM @FailedComments returns all rows that could not be applied
- Includes both failure types in one result set (no discrimination between failure reasons)
- If all rows succeeded: returns empty result set
- If all rows failed: the UPDATE affects no rows; all input rows are returned

**Diagram**:
```
Input @tbl
    |
    +--[CID not in Customer.Customer]---> @FailedComments
    |
    +--[CONCAT length > 8000]-----------> @FailedComments
    |
    +--[valid rows only]
         |
         v
    UPDATE Customer.Customer.Comments
    = CONCAT(new + CRLF + old)
         |
         v
    RETURN: SELECT * FROM @FailedComments
            (empty = full success, non-empty = partial failure)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @tbl | Customer.TBL_CustomerComment READONLY | NO | - | CODE-BACKED | Batch input: TVP containing (CID int, Comments varchar(8000)) pairs. READONLY. No PK constraint on the type - duplicate CIDs allowed for appending multiple comments to the same customer. See Customer.TBL_CustomerComment. |

**Output result set (failed rows):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | CID | int | NO | CODE-BACKED | Customer ID of the row that failed to update. Either CID did not exist in Customer.Customer, or the combined comment would exceed 8000 characters. |
| 2 | Comments | varchar(8000) | YES | CODE-BACKED | The comment text that was NOT applied to the customer record. Returned so the caller can log or retry the failed annotation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @tbl | Customer.TBL_CustomerComment | TVP type | Input batch type and internal @FailedComments variable type |
| @tbl.CID | Customer.Customer | JOIN (read + UPDATE) | Validates CID existence and applies prepend UPDATE to Comments column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MassOperationsServiceUser role | EXECUTE permission | Caller | Called by mass operations tooling for bulk customer annotations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerCommentBulkAppend (procedure)
├── Customer.TBL_CustomerComment (type)
└── Customer.Customer (view - used for validation and UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TBL_CustomerComment | User Defined Type | Input parameter type (@tbl) and internal failure tracking variable (@FailedComments) |
| Customer.Customer | View | Read (CID validation) + UPDATE (prepend comment to Comments column) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MassOperationsServiceUser | External caller | Bulk comment append in mass operations workflows |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| LEN(CONCAT(...)) > 8000 | Application validation | Enforces the varchar(8000) limit of Customer.Customer.Comments before attempting UPDATE |
| LEFT JOIN @FailedComments f ... WHERE f.CID IS NULL | UPDATE filter | Excludes failed rows from the UPDATE - ensures partial success without ROLLBACK |
| No explicit transaction | Design decision | UPDATE is applied without a transaction wrapper - partial updates are committed immediately |

---

## 8. Sample Queries

### 8.1 Execute a batch comment append and check failures

```sql
DECLARE @batch Customer.TBL_CustomerComment
INSERT INTO @batch (CID, Comments) VALUES
    (12345678, 'AML review completed 2026-03-17 - no action required'),
    (23456789, 'Fraud flag: shared payment method with CID 12345678'),
    (99999999, 'Test comment - invalid CID should appear in failures')

EXEC Customer.CustomerCommentBulkAppend @tbl = @batch
-- Result set contains rows that failed (99999999 if CID not found)
```

### 8.2 Check current comments for a customer

```sql
SELECT CID, Comments
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345678
```

### 8.3 Check comment length before batch to avoid overflow failures

```sql
DECLARE @newComment VARCHAR(8000) = 'New operational note here...'
SELECT
    c.CID,
    LEN(CONCAT(@newComment, CHAR(13), CHAR(10), ISNULL(c.Comments, ''))) AS CombinedLength,
    CASE WHEN LEN(CONCAT(@newComment, CHAR(13), CHAR(10), ISNULL(c.Comments, ''))) > 8000
         THEN 'WILL FAIL - too long'
         ELSE 'OK' END AS Status
FROM Customer.Customer c WITH (NOLOCK)
WHERE c.CID IN (12345678, 23456789)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerCommentBulkAppend | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.CustomerCommentBulkAppend.sql*
