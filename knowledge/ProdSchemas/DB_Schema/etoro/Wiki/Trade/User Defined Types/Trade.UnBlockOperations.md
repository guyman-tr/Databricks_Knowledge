# Trade.UnBlockOperations

> TVP for unblocking previously blocked customer operations - passes OperationTypeID, BlockReasonID, and UnBlockReasonID per unblock request.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OperationTypeID (int), BlockReasonID (int), UnBlockReasonID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

UnBlockOperations carries unblock requests for customer restrictions. Each row specifies: OperationTypeID (what operation was blocked), BlockReasonID (why it was blocked), UnBlockReasonID (reason for unblocking). This supports removing specific block entries when conditions change (e.g., compliance approval, manual override).

The type exists because customer restriction unblock operations need to target specific block combinations. Trade.CustomerRestrictionsRemove receives the TVP, JOINs it against blocked operations, and removes the matching entries.

The type flows from compliance or admin UIs into Trade.CustomerRestrictionsRemove. The procedure uses the TVP to identify which blocks to remove, tied to an UnBlockRequestGUID for auditability.

---

## 2. Business Logic

OperationTypeID + BlockReasonID + UnBlockReasonID triplet. Each row identifies one block to remove; the triple uniquely identifies the restriction entry.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationTypeID | int | NO | - | CODE-BACKED | Trading operation type that was blocked |
| 2 | BlockReasonID | int | NO | - | CODE-BACKED | Reason the operation was blocked |
| 3 | UnBlockReasonID | int | NO | - | CODE-BACKED | Reason for unblocking (e.g., approval code) |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Semantic references to operation type and block reason lookup tables.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CustomerRestrictionsRemove | @UnBlockOperations | Parameter (TVP) | Removes customer restrictions for specified operation-block-unblock triples |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CustomerRestrictionsRemove | Stored Procedure | READONLY parameter for unblock operations |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Unblock single operation
```sql
DECLARE @UnBlockOperations Trade.UnBlockOperations;
INSERT INTO @UnBlockOperations (OperationTypeID, BlockReasonID, UnBlockReasonID)
VALUES (1, 5, 10);
DECLARE @Occurred DATETIME;
EXEC Trade.CustomerRestrictionsRemove @CID = 1000, @UnBlockOperations = @UnBlockOperations,
    @UnBlockRequestGUID = NEWID(), @Occurred = @Occurred OUTPUT;
```

### 8.2 Unblock multiple operations
```sql
DECLARE @UnBlockOperations Trade.UnBlockOperations;
INSERT INTO @UnBlockOperations (OperationTypeID, BlockReasonID, UnBlockReasonID)
VALUES (1, 5, 10), (2, 5, 10), (3, 6, 11);
DECLARE @Occurred DATETIME;
EXEC Trade.CustomerRestrictionsRemove @CID = 1000, @UnBlockOperations = @UnBlockOperations,
    @UnBlockRequestGUID = NEWID(), @Occurred = @Occurred OUTPUT;
```

### 8.3 Build from staging table
```sql
DECLARE @UnBlockOperations Trade.UnBlockOperations;
INSERT INTO @UnBlockOperations (OperationTypeID, BlockReasonID, UnBlockReasonID)
SELECT OperationTypeID, BlockReasonID, UnBlockReasonID FROM Staging.UnblockRequests WHERE CID = 1000;
EXEC Trade.CustomerRestrictionsRemove @CID = 1000, @UnBlockOperations = @UnBlockOperations,
    @UnBlockRequestGUID = NEWID(), @Occurred = @Occurred OUTPUT;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 6.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 1/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UnBlockOperations | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.UnBlockOperations.sql*
