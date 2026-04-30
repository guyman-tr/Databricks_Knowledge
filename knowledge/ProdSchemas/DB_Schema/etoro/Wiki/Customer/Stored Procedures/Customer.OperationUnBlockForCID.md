# Customer.OperationUnBlockForCID

> Removes an active operation block for a customer by archiving it to History.BlockedCustomerOperations and deleting from Customer.BlockedCustomerOperations, wrapped in a transaction with error 60086 if no active block exists.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @OperationTypeID -> History.BlockedCustomerOperations (archive) + DELETE Customer.BlockedCustomerOperations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.OperationUnBlockForCID is the complementary procedure to Customer.OperationBlockForCID. It lifts an active operation block for a customer by:
1. Archiving the block record to History.BlockedCustomerOperations (with BlockEnd=GETUTCDATE() to record when the block was lifted)
2. Deleting the active block from Customer.BlockedCustomerOperations

The transactional design (BEGIN TRAN / COMMIT) ensures both steps succeed atomically - no partial states where the history record exists but the active block remains, or vice versa. If no active block exists for the CID+OperationTypeID combination, error 60086 is raised (preventing silent no-ops).

**Historical note**: The procedure comment dated 10-08-2015 mentions a planned enhancement to add @BlockReasonID and @UnBlockReasonID as separate input parameters. This was never implemented - the UnBlockReasonID in the History insert is set equal to the BlockReasonID from the source record (not a distinct unblock reason). This means the history table shows the same reason code for both block and unblock events.

---

## 2. Business Logic

### 2.1 Transactional Block Removal (Archive + Delete)

**What**: Atomically archives and removes an active operation block.

**Columns/Parameters Involved**: `Customer.BlockedCustomerOperations.CID`, `Customer.BlockedCustomerOperations.OperationTypeID`, `Customer.BlockedCustomerOperations.BlockReasonID`, `Customer.BlockedCustomerOperations.Occurred`

**Rules**:
- BEGIN TRAN wraps both operations for atomicity
- Step 1 INSERT History.BlockedCustomerOperations:
  - CID, OperationTypeID from @CID, @OperationTypeID
  - BlockStart = Customer.BlockedCustomerOperations.Occurred (when block was originally applied)
  - BlockEnd = GETUTCDATE() (when block is being lifted - UTC)
  - BlockReasonID = Customer.BlockedCustomerOperations.BlockReasonID (from source row)
  - UnBlockReasonID = Customer.BlockedCustomerOperations.BlockReasonID (SAME value - no distinct unblock reason stored)
- Step 2 DELETE Customer.BlockedCustomerOperations WHERE CID=@CID AND OperationTypeID=@OperationTypeID
- IF @@ROWCOUNT = 0 after DELETE -> RAISERROR(60086, 16, 1): no active block found; ROLLBACK TRAN
- If @@ROWCOUNT > 0 -> COMMIT TRAN

### 2.2 Error Code 60086 - No Active Block

**What**: Guards against unblocking a customer who was never blocked (or already unblocked).

**Rules**:
- Error 60086 is a custom eToro error code (16, 1 = severity 16, state 1)
- Triggered when DELETE affects 0 rows (no matching CID+OperationTypeID in BlockedCustomerOperations)
- Causes ROLLBACK - History row is NOT inserted if delete fails
- Callers should handle this error and treat it as "already unblocked" or "invalid operation"

### 2.3 UnBlockReasonID = BlockReasonID (Known Gap)

**What**: The unblock reason in History always mirrors the block reason.

**Rules**:
- The History.BlockedCustomerOperations table has a separate UnBlockReasonID column
- The procedure sets UnBlockReasonID = BlockReasonID (the original block reason code)
- This means the audit trail does not capture WHY the block was lifted - only when
- This is a known incomplete implementation (referenced in the 10-08-2015 comment)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Internal Customer ID of the customer to unblock. Used to identify and delete the active block row, and to populate the History archive. |
| 2 | @OperationTypeID | int | NO | - | VERIFIED | Identifies the specific operation type to unblock. Must match an existing row in Customer.BlockedCustomerOperations; if not found, error 60086 is raised. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @OperationTypeID | Customer.BlockedCustomerOperations | Reader + Writer (DELETE) | Reads BlockReasonID/Occurred for archive; deletes the active block row |
| @CID + @OperationTypeID | History.BlockedCustomerOperations | Writer (INSERT) | Archives the block with BlockStart, BlockEnd, BlockReasonID, UnBlockReasonID |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by Back-Office administration tools and automated compliance/risk systems.

Related: Customer.OperationBlockForCID (creates the block), Customer.GetBlockedOperationsForCID (reads active blocks).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.OperationUnBlockForCID (procedure)
├── Customer.BlockedCustomerOperations (table) [read + delete]
└── History.BlockedCustomerOperations (table) [insert archive]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | SELECT BlockReasonID/Occurred for archive data; DELETE to remove active block |
| History.BlockedCustomerOperations | Table | INSERT - creates audit record with BlockStart, BlockEnd, BlockReasonID, UnBlockReasonID |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses explicit BEGIN TRAN / COMMIT / ROLLBACK for atomicity. Error 60086 (custom eToro error) is raised when no active block exists for the given CID+OperationTypeID.

---

## 8. Sample Queries

### 8.1 Unblock a customer's withdrawal operation
```sql
BEGIN TRY
    EXEC Customer.OperationUnBlockForCID
        @CID = 12345678,
        @OperationTypeID = 3;  -- 3 = withdrawal (example)
    PRINT 'Block removed successfully';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 60086
        PRINT 'No active block found for this CID+OperationType combination';
    ELSE
        THROW;
END CATCH;
```

### 8.2 View the archived history after unblocking
```sql
SELECT CID, OperationTypeID, BlockStart, BlockEnd, BlockReasonID, UnBlockReasonID,
       DATEDIFF(hour, BlockStart, BlockEnd) AS BlockDurationHours
FROM History.BlockedCustomerOperations WITH (NOLOCK)
WHERE CID = 12345678
ORDER BY BlockEnd DESC;
```

### 8.3 Full block-and-unblock lifecycle for debugging
```sql
-- Block first
EXEC Customer.OperationBlockForCID @CID = 12345678, @OperationTypeID = 3;
-- Verify active block
SELECT * FROM Customer.BlockedCustomerOperations WHERE CID = 12345678 AND OperationTypeID = 3;
-- Unblock
EXEC Customer.OperationUnBlockForCID @CID = 12345678, @OperationTypeID = 3;
-- Verify removed from active + added to history
SELECT * FROM Customer.BlockedCustomerOperations WHERE CID = 12345678 AND OperationTypeID = 3;  -- empty
SELECT * FROM History.BlockedCustomerOperations WHERE CID = 12345678 AND OperationTypeID = 3;  -- 1 row
```

---

## 9. Atlassian Knowledge Sources

**Historical note from SP comment (10-08-2015)**: Planned enhancement to add @BlockReasonID and @UnBlockReasonID as separate input parameters was noted but never implemented. The current code sets UnBlockReasonID = BlockReasonID from the source block record, meaning the audit trail does not distinguish why the block was applied vs. why it was lifted.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.OperationUnBlockForCID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.OperationUnBlockForCID.sql*
