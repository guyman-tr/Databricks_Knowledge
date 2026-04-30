# Customer.TBL_CustomerComment

> Table-Valued Parameter type for passing a batch of customer CID + comment text pairs to the bulk comment append procedure.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int, no PK constraint within type) |
| **Partition** | N/A |
| **Indexes** | None (no PK defined - allows duplicate CIDs within a batch) |

---

## 1. Business Meaning

Customer.TBL_CustomerComment is a Table-Valued Parameter (TVP) type for bulk-appending internal customer comments. It pairs a customer identifier (CID) with a comment text (up to 8000 characters), enabling the MassOperationsServiceUser role to submit a batch of annotated customer records in a single call to Customer.CustomerCommentBulkAppend.

Customer comments are internal operational notes — written by compliance, risk, or BackOffice staff — used to document account actions, fraud flags, investigation notes, or customer service interactions. The bulk insert pattern is used in mass operations scenarios where many customers need to be annotated simultaneously (e.g., compliance campaigns, fraud sweeps, bulk account reviews).

Unlike the other Customer TVP types, TBL_CustomerComment has no PRIMARY KEY constraint, which means duplicate CIDs are permitted within a single batch. This supports appending multiple comments for the same customer in one operation.

---

## 2. Business Logic

### 2.1 Bulk Comment Append Pattern

**What**: Enables mass-operations tooling to submit multiple customer annotations in a single batch call.

**Columns/Parameters Involved**: `CID`, `Comments`

**Rules**:
- No PK constraint: duplicate CIDs are allowed — a single batch can append multiple comments to the same customer
- Passed as READONLY to Customer.CustomerCommentBulkAppend
- Comments column uses Latin1_General_BIN collation for binary-level string comparison
- Customer.CustomerCommentBulkAppend also declares an internal `@FailedComments` variable of this same type to track which rows fail during processing, enabling partial-success error handling
- The MassOperationsServiceUser role is explicitly granted EXECUTE permission on this type, confirming it is used in mass-operations workflows

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer ID - identifies which customer this comment belongs to. No uniqueness constraint within the TVP, allowing multiple comments per customer in a single batch. |
| 2 | Comments | varchar(8000) | YES | - | CODE-BACKED | The comment text to append to the customer's record. Latin1_General_BIN collation. Up to 8000 characters. NULL indicates no comment text (may still result in a placeholder row). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerCommentBulkAppend | @tbl (input) + @FailedComments (internal) | TVP Parameter | Input batch of CID+comment pairs; also used internally to capture failed rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerCommentBulkAppend | Stored Procedure | READONLY TVP input parameter for batch comment insert; also used as internal @FailedComments tracking variable |

---

## 7. Technical Details

### 7.1 Indexes

N/A - no indexes defined on this type (no PK constraint).

### 7.2 Constraints

None. No PRIMARY KEY or UNIQUE constraints — duplicate CIDs allowed within a single batch to support multiple comments per customer.

---

## 8. Sample Queries

### 8.1 Declare and use the TVP to bulk append comments

```sql
DECLARE @Comments Customer.TBL_CustomerComment
INSERT INTO @Comments (CID, Comments)
VALUES
    (1001, 'Account reviewed for AML compliance - no issues found'),
    (1002, 'Customer flagged for unusual deposit pattern - escalated to Risk team'),
    (1001, 'Follow-up: document verification requested')  -- second comment for same CID

EXEC Customer.CustomerCommentBulkAppend @tbl = @Comments
```

### 8.2 Inspect the type definition

```sql
SELECT
    t.name AS TypeName,
    c.name AS ColumnName,
    tp.name AS DataType,
    c.max_length,
    c.is_nullable
FROM sys.table_types t WITH (NOLOCK)
INNER JOIN sys.columns c WITH (NOLOCK) ON c.object_id = t.type_table_object_id
INNER JOIN sys.types tp WITH (NOLOCK) ON tp.user_type_id = c.user_type_id
WHERE t.schema_id = SCHEMA_ID('Customer')
  AND t.name = 'TBL_CustomerComment'
```

### 8.3 Check existing comments for customers

```sql
SELECT CID, Comments
FROM Customer.CustomerCommentBulkAppend  -- hypothetical view or direct table
-- In practice, comments are stored in the target table (not directly accessible via the TVP)
-- Use the actual comments storage table for reads (check BackOffice.CustomerComments or similar)
SELECT TOP 20 *
FROM Customer.CustomerStatic cs WITH (NOLOCK)
WHERE cs.CID IN (1001, 1002)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.TBL_CustomerComment | Type: User Defined Type | Source: etoro/etoro/Customer/User Defined Types/Customer.TBL_CustomerComment.sql*
