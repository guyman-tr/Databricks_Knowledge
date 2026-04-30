# Trade.CustomerRestrictionsSet

> Batch-sets multiple customer operation restrictions (blocks) for a single CID using a TVP, with three-state logic: creates all if none exist, does nothing if all exist, fails if only some exist to prevent inconsistent blocking states.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Occurred OUTPUT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionsSet is the batch version of Trade.CustomerRestrictionSet, designed to apply multiple operation restrictions to a customer in a single call. It enforces a three-state decision model to prevent partially overlapping restriction sets that could cause confusion in the compliance workflow.

This procedure supports scenarios where a compliance action requires multiple operations to be blocked simultaneously (e.g., "block trading AND withdrawals AND transfers" as a single regulatory action). The three-state model ensures that either the full set of blocks is applied atomically, or the caller knows the exact state.

The procedure differs from the singular Trade.CustomerRestrictionSet in three ways: (1) accepts multiple operations via TVP, (2) requires @RequestGUID to be non-NULL (mandatory audit trail), and (3) validates existing restriction overlap before inserting.

---

## 2. Business Logic

### 2.1 Three-State Blocking Decision

**What**: The procedure evaluates existing restrictions against the requested set and takes one of three paths.

**Columns/Parameters Involved**: `@CID`, `@BlockOperations`, `@RequestGUID`

**Rules**:
- @RequestGUID is mandatory - RAISERROR if NULL
- Counts TVP rows (@count) and existing matching restrictions (@existingRestrictionsCount)
- **State 1**: @existingRestrictionsCount = 0 -> INSERT all blocks (none existed, create all)
- **State 2**: @existingRestrictionsCount = @count -> Do nothing (all already exist, idempotent)
- **State 3**: @existingRestrictionsCount > 0 AND < @count -> RAISERROR(60089) - partial overlap detected, fail to prevent inconsistent state
- Sets @Occurred = GETUTCDATE() at start and returns via OUTPUT

**Diagram**:
```
@BlockOperations (TVP: N rows)
    |
    +-- Count existing matches in BlockedCustomerOperations
    |
    +-- 0 matches: INSERT all N blocks
    |
    +-- N matches: Do nothing (idempotent)
    |
    +-- 1 to N-1 matches: RAISERROR(60089) FAIL
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to apply restrictions to. |
| 2 | @BlockOperations | Trade.BlockOperations (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing rows of OperationTypeID + BlockReasonID to apply. Each row becomes one block record. |
| 3 | @RequestGUID | NVARCHAR(50) | NO | - | CODE-BACKED | Mandatory unique identifier for the block request. RAISERROR if NULL. Stored in each block record for audit trail. |
| 4 | @Occurred | DATETIME | NO | OUTPUT | CODE-BACKED | OUTPUT parameter set to GETUTCDATE() at procedure start. Returns the exact timestamp of the block operation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Validation + INSERT | Customer.BlockedCustomerOperations | Writer | Validates existing blocks and inserts new block records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | API call | Consumer | Called for batch restriction creation requiring consistent state |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionsSet (procedure)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | Validation JOIN and INSERT target for block records |
| Trade.BlockOperations | User Defined Type | TVP type for the block operations parameter |

### 6.2 Objects That Depend On This

No dependents found in the Trade schema.

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

### 8.2 Find customers blocked by a specific request
```sql
SELECT CID, OperationTypeID, BlockReasonID, Occurred
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
WHERE  RequestGUID = 'some-guid-value'
```

### 8.3 Count blocks per operation type
```sql
SELECT OperationTypeID, COUNT(DISTINCT CID) AS CustomersBlocked
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
GROUP BY OperationTypeID
ORDER BY CustomersBlocked DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CFD Block Search](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2364080271) | Confluence | Context on customer operation blocking patterns for CFD trading |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionsSet | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionsSet.sql*
