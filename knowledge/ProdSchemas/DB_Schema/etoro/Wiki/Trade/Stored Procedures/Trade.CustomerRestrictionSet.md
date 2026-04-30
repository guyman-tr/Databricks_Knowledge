# Trade.CustomerRestrictionSet

> Sets a single customer operation restriction (block) for a specific CID, operation type, and block reason, preventing the customer from performing the specified operation until the block is removed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Silent return (no output) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionSet blocks a customer from performing a specific operation type by inserting a record into Customer.BlockedCustomerOperations. Operations that can be blocked include trading (open/close), withdrawals, deposits, and other account actions. This is a compliance and risk management tool used when a customer needs to be restricted - for example, due to regulatory requirements, fraud suspicion, AML review, or risk limit breach.

This is the single-restriction version of the blocking API. It handles one CID + one OperationTypeID + one BlockReasonID per call, as opposed to Trade.CustomerRestrictionsSet (plural) which handles batch blocking via a TVP. The procedure is idempotent - if the exact same block (CID + OperationTypeID + BlockReasonID) already exists, it returns silently without creating a duplicate.

The procedure is used by the Trading Server (TS) and compliance tools to impose restrictions on customer accounts.

---

## 2. Business Logic

### 2.1 Idempotent Block Creation

**What**: Creates a block record only if the exact combination doesn't already exist.

**Columns/Parameters Involved**: `@CID`, `@OperationTypeID`, `@BlockReasonID`, `@RequestGUID`

**Rules**:
- First checks if the exact block (CID + OperationTypeID + BlockReasonID) already exists
- If exists: returns silently (idempotent - no error, no duplicate)
- If not exists: INSERTs new block with Occurred = GETUTCDATE()
- @RequestGUID provides correlation with the requesting system for audit

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to block. |
| 2 | @OperationTypeID | INT | NO | - | CODE-BACKED | Type of operation to block (e.g., trade open, trade close, withdrawal). FK to Dictionary.OperationType. |
| 3 | @BlockReasonID | INT | NO | - | CODE-BACKED | Reason for the block (e.g., compliance review, fraud suspicion, regulatory hold). Multiple blocks with different reasons can coexist for the same CID+OperationTypeID. |
| 4 | @RequestGUID | NVARCHAR(50) | YES | NULL | CODE-BACKED | Unique identifier for the block request, used for correlation with the requesting system and audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Customer.BlockedCustomerOperations | Writer | Inserts a new block record for the specified customer and operation type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application (Trading Server) | API call | Consumer | Called by the TS when a single restriction needs to be applied |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionSet (procedure)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | EXISTS check and INSERT target for block records |

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

### 8.1 Check if a customer has any active blocks
```sql
SELECT CID, OperationTypeID, BlockReasonID, Occurred
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE  CID = 12345
```

### 8.2 Check all blocks for a specific operation type
```sql
SELECT CID, BlockReasonID, Occurred, RequestGUID
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE  OperationTypeID = 1
ORDER BY Occurred DESC
```

### 8.3 Count blocks by reason
```sql
SELECT BlockReasonID, COUNT(*) AS BlockCount
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
GROUP BY BlockReasonID
ORDER BY BlockCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CFD Block Search](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2364080271) | Confluence | Context on customer operation blocking patterns for CFD trading restrictions |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionSet | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionSet.sql*
