# Trade.CustomerRestrictionsRemove

> Batch-removes multiple customer operation restrictions (blocks) for a single CID using a TVP, with all-or-nothing semantics - either all specified restrictions are removed or the operation fails entirely, archiving removed blocks to history.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Occurred OUTPUT, RETURN 0 on success |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CustomerRestrictionsRemove is the batch version of Trade.CustomerRestrictionRemove, designed to remove multiple operation restrictions from a customer in a single atomic transaction. It enforces strict all-or-nothing semantics: if ALL specified restrictions exist, they are all removed and archived to history. If even one restriction from the requested set does not exist, the entire operation fails with error 60091 and no restrictions are removed.

This strict validation prevents partial unblocking scenarios that could create inconsistent states. For example, if a compliance workflow requires three specific blocks to be lifted simultaneously (trading + withdrawal + deposit), this procedure ensures either all three are lifted or none are, maintaining workflow integrity.

The procedure differs from the singular Trade.CustomerRestrictionRemove in three ways: (1) accepts multiple operations via TVP, (2) requires @UnBlockRequestGUID to be non-NULL (mandatory audit trail), and (3) validates that ALL requested restrictions exist before removing any.

---

## 2. Business Logic

### 2.1 All-or-Nothing Restriction Removal

**What**: All specified restrictions must exist for any to be removed. Partial matches cause the entire operation to fail.

**Columns/Parameters Involved**: `@CID`, `@UnBlockOperations`, `@UnBlockRequestGUID`

**Rules**:
- @UnBlockRequestGUID is mandatory - RAISERROR if NULL
- Counts TVP rows and compares against matched rows in BlockedCustomerOperations
- If matched rows < TVP rows: RAISERROR(60091) - some restrictions don't exist
- If matched: DELETE all matching blocks with OUTPUT capture, INSERT all to History.BlockedCustomerOperations
- BlockReasonID = 0 in TVP means "match any block reason" for that operation type
- Sets @Occurred = GETUTCDATE() at start and returns via OUTPUT

**Diagram**:
```
@UnBlockOperations (TVP)
    |
    +-- Count TVP rows (@count)
    +-- JOIN Customer.BlockedCustomerOperations
    |     +-- If matched < @count -> RAISERROR(60091) FAIL
    |
    +-- If all match:
          +-- DELETE from BlockedCustomerOperations (OUTPUT)
          +-- INSERT into History.BlockedCustomerOperations
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose restrictions are being removed. |
| 2 | @UnBlockOperations | Trade.UnBlockOperations (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing rows of OperationTypeID + BlockReasonID + UnBlockReasonID to remove. BlockReasonID=0 means remove any block for that operation type. |
| 3 | @UnBlockRequestGUID | NVARCHAR(50) | NO | - | CODE-BACKED | Mandatory unique identifier for the unblock request. RAISERROR if NULL. Used for audit trail correlation. |
| 4 | @Occurred | DATETIME | NO | OUTPUT | CODE-BACKED | OUTPUT parameter set to GETUTCDATE() at procedure start. Returns the exact timestamp of the unblock operation to the caller. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Validation + DELETE | Customer.BlockedCustomerOperations | Writer (DELETE) | Validates existence and removes matching block records |
| Archive | History.BlockedCustomerOperations | Writer (INSERT) | Archives removed blocks with full lifecycle metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application layer | API call | Consumer | Called for batch restriction removal requiring all-or-nothing semantics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CustomerRestrictionsRemove (procedure)
+-- Customer.BlockedCustomerOperations (table)
+-- History.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | Validation JOIN, DELETE with OUTPUT |
| History.BlockedCustomerOperations | Table | INSERT target for archived block records |
| Trade.UnBlockOperations | User Defined Type | TVP type for the unblock operations parameter |

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

### 8.2 View unblock history with request GUIDs
```sql
SELECT CID, OperationTypeID, BlockStart, BlockEnd, UnBlockReasonID, UnBlockRequestGUID
FROM   History.BlockedCustomerOperations WITH (NOLOCK)
WHERE  CID = 12345
ORDER BY BlockEnd DESC
```

### 8.3 Find customers with multiple concurrent blocks
```sql
SELECT CID, COUNT(*) AS ActiveBlocks
FROM   Customer.BlockedCustomerOperations WITH (NOLOCK)
GROUP BY CID
HAVING COUNT(*) >= 3
ORDER BY ActiveBlocks DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [CFD Block Search](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/2364080271) | Confluence | Context on customer operation blocking/unblocking patterns |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CustomerRestrictionsRemove | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CustomerRestrictionsRemove.sql*
