# Trade.CustomerRestrictionRemove

> Removes a single customer operation restriction (block) by CID and operation type, archiving the block record to history with unblock metadata for audit trail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN 0 on success, 1 on failure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionRemove lifts a single operation-level restriction from a customer account. When a customer is blocked from performing certain operations (e.g., trading, withdrawals, deposits), this procedure removes the block and archives the restriction record to History.BlockedCustomerOperations with full audit metadata including who unblocked, when, and why.

This is the single-restriction version of the customer restriction management API. It handles one CID + one OperationTypeID combination per call, as opposed to Trade.CustomerRestrictionsRemove (plural) which handles batch unblocking via a TVP. Both procedures share the same archive-to-history pattern.

The procedure is used by the Trading Server (TS) and compliance tools when a block is no longer needed - for example, when a compliance review is complete, when a fraud investigation is cleared, or when a regulatory hold expires.

---

## 2. Business Logic

### 2.1 Block Removal with History Archive

**What**: Deletes the active block and creates a history record preserving the full block lifecycle.

**Columns/Parameters Involved**: `@CID`, `@OperationTypeID`, `@BlockReasonID`, `@UnBlockReasonID`, `@UnBlockRequestGUID`

**Rules**:
- DELETE from Customer.BlockedCustomerOperations where CID + OperationTypeID match
- If @BlockReasonID is specified (non-zero), only the block with that specific reason is removed
- If @BlockReasonID = 0, ALL blocks for that CID + OperationTypeID are removed regardless of reason
- OUTPUT clause captures the deleted record's Occurred date, BlockReasonID, and RequestGUID
- Archived to History.BlockedCustomerOperations with BlockStart (original), BlockEnd (now), and unblock metadata
- Entire operation is transactional - rollback on failure

**Diagram**:
```
Customer.BlockedCustomerOperations
    |
    +-- DELETE (with OUTPUT capture)
    |     +-- Filters: CID + OperationTypeID + optional BlockReasonID
    |
    +-- INSERT into History.BlockedCustomerOperations
          +-- BlockStart = original Occurred
          +-- BlockEnd = GETUTCDATE()
          +-- UnBlockReasonID, UnBlockRequestGUID from parameters
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose restriction is being removed. |
| 2 | @OperationTypeID | INT | NO | - | CODE-BACKED | Type of operation being unblocked (e.g., trade open, trade close, withdrawal). FK to Dictionary.OperationType. |
| 3 | @UnBlockReasonID | INT | NO | - | CODE-BACKED | Reason for removing the block (e.g., compliance review complete, fraud investigation cleared). Stored in history for audit. |
| 4 | @BlockReasonID | INT | NO | - | CODE-BACKED | The specific block reason to remove. If 0, removes ALL blocks for this CID+OperationTypeID regardless of reason. If non-zero, only removes the block with this exact reason. |
| 5 | @UnBlockRequestGUID | NVARCHAR(50) | YES | NULL | CODE-BACKED | Unique identifier for the unblock request, used for correlation with the requesting system. Stored in history for audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE source | Customer.BlockedCustomerOperations | Writer (DELETE) | Removes the active block record for the specified customer and operation |
| Archive target | History.BlockedCustomerOperations | Writer (INSERT) | Archives the block lifecycle record with block start, block end, and unblock metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (Trading Server) | API call | Consumer | Called by the TS when a single restriction needs to be lifted |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionRemove (procedure)
+-- Customer.BlockedCustomerOperations (table)
+-- History.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | DELETE source for active block records |
| History.BlockedCustomerOperations | Table | INSERT target for archived block records |

### 6.2 Objects That Depend On This

No dependents found in the Trade schema. Called from the application layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check active blocks for a customer
```sql
SELECT CID, OperationTypeID, BlockReasonID, Occurred, RequestGUID
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE  CID = 12345
```

### 8.2 View block history for a customer
```sql
SELECT CID, OperationTypeID, BlockStart, BlockEnd, BlockReasonID, UnBlockReasonID
FROM   History.BlockedCustomerOperations WITH (NOLOCK)
WHERE  CID = 12345
ORDER BY BlockEnd DESC
```

### 8.3 Find recently unblocked customers
```sql
SELECT TOP 20 CID, OperationTypeID, BlockStart, BlockEnd,
       DATEDIFF(HOUR, BlockStart, BlockEnd) AS BlockDurationHours
FROM   History.BlockedCustomerOperations WITH (NOLOCK)
WHERE  BlockEnd >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY BlockEnd DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CFD Block Search](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2364080271) | Confluence | Context on customer operation blocking/unblocking patterns for CFD trading restrictions |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionRemove.sql*
