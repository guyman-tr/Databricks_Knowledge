# Trade.CustomerRestrictionRemove_CIDs

> Removes trading operation restrictions (blocks) for a batch of customer CIDs, archiving the block records to History.BlockedCustomerOperations with unblock metadata.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (TVP with customer IDs to unblock) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionRemove_CIDs lifts trading restrictions from a batch of customers. When customers are blocked from specific operations (e.g., opening positions, closing positions, withdrawals), the block records are stored in Customer.BlockedCustomerOperations. This procedure removes those blocks and archives the history, recording when and why the block was removed.

Restrictions are removed during compliance resolution (a previously-flagged customer is cleared), after manual review by operations, or when automated systems determine a temporary block should be lifted. Each unblock operation records the UnBlockReasonID and UnBlockRequestGUID for full audit traceability.

The procedure atomically deletes matching blocks from the active table and inserts them into History.BlockedCustomerOperations with both the original block details and the unblock metadata (BlockEnd timestamp, UnBlockReasonID, UnBlockRequestGUID).

---

## 2. Business Logic

### 2.1 Atomic Delete-to-History

**What**: Removes active blocks and archives them in a single transaction.

**Columns/Parameters Involved**: `@CID`, `@OperationTypeID`, `@BlockReasonID`

**Rules**:
- DELETE from Customer.BlockedCustomerOperations with OUTPUT INTO @Temp captures deleted rows
- Matches on CID + OperationTypeID + optionally BlockReasonID
- If @BlockReasonID = 0: removes ALL blocks for the operation type (wildcard)
- If @BlockReasonID != 0: removes only blocks with the specific reason
- Archived rows get BlockEnd = GETUTCDATE() and the unblock metadata

### 2.2 Block Reason Filtering

**What**: Supports targeted or blanket unblocking.

**Rules**:
- @BlockReasonID = 0: All blocks for the OperationTypeID are removed regardless of reason
- @BlockReasonID != 0: Only blocks matching that specific reason are removed
- This allows precision: e.g., remove only the "AML freeze" block but keep the "Compliance review" block

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | Trade.CidList (TVP, READONLY) | NO | - | CODE-BACKED | List of customer CIDs to unblock. Each CID's matching block records will be removed. |
| 2 | @OperationTypeID | INT | NO | - | CODE-BACKED | Type of operation to unblock. Identifies which trading operation restriction to remove (e.g., open, close, withdraw). FK to Dictionary table. |
| 3 | @UnBlockReasonID | INT | NO | - | CODE-BACKED | Reason for removing the block. Recorded in the history for audit. |
| 4 | @BlockReasonID | INT | NO | - | CODE-BACKED | Which block reason to target. When 0: removes ALL blocks for the operation type. When non-zero: removes only blocks with this specific reason. |
| 5 | @UnBlockRequestGUID | NVARCHAR(50) | YES | '' | CODE-BACKED | Correlation GUID for the unblock request. Links to the initiating system/ticket. Empty string default. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | Customer.BlockedCustomerOperations | DELETE | Removes active block records |
| INSERT | History.BlockedCustomerOperations | INSERT | Archives block records with unblock metadata |
| Type | Trade.CidList | Type | UDT for CID list parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CustomerRestrictionCIDs_Wrapper | (batch #20) | EXEC | Wrapper procedure calls this for bulk unblocking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionRemove_CIDs (procedure)
+-- Customer.BlockedCustomerOperations (table)
+-- History.BlockedCustomerOperations (table)
+-- Trade.CidList (user-defined table type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | DELETE - source of active blocks to remove |
| History.BlockedCustomerOperations | Table | INSERT - archive target for removed blocks |
| Trade.CidList | UDT | TVP parameter type for CID list |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CustomerRestrictionCIDs_Wrapper | Procedure | EXEC - wrapper that orchestrates block/unblock in batches |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | Atomicity | DELETE + INSERT either both succeed or both roll back |
| THROW on error | Error handling | Errors propagate to caller after rollback |
| RETURN 0/1 | Return code | 0 = success, 1 = error |

---

## 8. Sample Queries

### 8.1 View active blocks for a customer

```sql
SELECT  CID, OperationTypeID, BlockReasonID, Occurred, RequestGUID
FROM    Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE   CID = 12345;
```

### 8.2 View unblock history

```sql
SELECT  CID, OperationTypeID, BlockStart, BlockEnd, BlockReasonID,
        UnBlockReasonID, UnBlockRequestGUID
FROM    History.BlockedCustomerOperations WITH (NOLOCK)
WHERE   CID = 12345
ORDER BY BlockEnd DESC;
```

### 8.3 Execute an unblock for specific customers

```sql
DECLARE @CIDs Trade.CidList;
INSERT INTO @CIDs (CID) VALUES (12345), (67890);
EXEC Trade.CustomerRestrictionRemove_CIDs
    @CID = @CIDs,
    @OperationTypeID = 1,
    @UnBlockReasonID = 5,
    @BlockReasonID = 0,
    @UnBlockRequestGUID = 'TICKET-12345';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionRemove_CIDs | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionRemove_CIDs.sql*
