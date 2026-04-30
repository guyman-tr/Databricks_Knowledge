# dbo.DeferredMessages_Delete

> Deletes a single deferred message row identified by both ID and RowVersion (optimistic concurrency), returning a flag indicating whether the delete succeeded.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DeferredMessageID + RowVersion (optimistic lock) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the delete endpoint for the DeferredMessages queue system. It removes a message that has been fully processed and is no longer needed. The dual-key match on DeferredMessageID AND RowVersion implements optimistic concurrency: if another process updated the row between the caller reading it and calling this SP, the RowVersion will have changed and the delete will silently fail, returning @Deleted = 'FALSE'. The caller can then decide whether to re-read and retry or raise an error.

---

## 2. Business Logic

- Issues a DELETE on the DeferredMessages table matching both DeferredMessageID and RowVersion.
- Checks @@ROWCOUNT after the delete:
  - If 1 row was deleted, sets the OUTPUT parameter @Deleted = 'TRUE'.
  - Otherwise sets @Deleted = 'FALSE' (row not found or concurrency conflict).
- SET NOCOUNT ON prevents rowcount noise in result sets.
- No transaction wrapper; the single-row delete is inherently atomic.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @DeferredMessageID | INT | IN | (required) | High | Primary key of the message to delete |
| 2 | @RowVersion | TIMESTAMP | IN | (required) | High | Concurrency token; must match the current row value |
| 3 | @Deleted | BIT | OUT | NULL | High | 'TRUE' if the row was deleted, 'FALSE' if not found or version mismatch |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE | dbo.DeferredMessages | Write | Removes the processed message row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DeferredMessages_Delete
  └── dbo.DeferredMessages    (WRITE - DELETE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.DeferredMessages | Table | Target of the DELETE operation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Delete a specific deferred message (caller holds the RowVersion from a prior read)
DECLARE @WasDeleted BIT;
EXEC dbo.DeferredMessages_Delete
    @DeferredMessageID = 55001,
    @RowVersion        = 0x00000000000107A3,
    @Deleted           = @WasDeleted OUTPUT;
SELECT @WasDeleted AS Deleted;

-- Pattern: read then delete with optimistic concurrency check
DECLARE @ID INT, @RV TIMESTAMP, @Del BIT;
SELECT TOP 1 @ID = DeferredMessageID, @RV = RowVersion
FROM dbo.DeferredMessages WHERE Status = 2;
EXEC dbo.DeferredMessages_Delete @ID, @RV, @Del OUTPUT;
IF @Del = 'FALSE' PRINT 'Concurrency conflict - row was updated by another process';

-- Verify deletion
SELECT DeferredMessageID FROM dbo.DeferredMessages WHERE DeferredMessageID = 55001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.DeferredMessages_Delete | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DeferredMessages_Delete.sql*
