# dbo.DeferredMessages_Update

> Updates the status and/or raw message body of an existing deferred message using optimistic concurrency, re-parsing CID, AffiliateID, and Occurred from the new payload if provided, and returning the updated RowVersion and timestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DeferredMessageID + RowVersion (optimistic lock) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the update endpoint for the DeferredMessages queue system. It is typically called by a worker process to advance a message's status (e.g., from pending to processing or to failed/retry), and optionally to update the message body. Like DeferredMessages_Delete, it enforces optimistic concurrency via the RowVersion column to prevent lost updates in a multi-server worker environment. The returned @NewRowVersion allows the caller to continue holding a valid lock token for subsequent operations without re-reading the row.

---

## 2. Business Logic

- Enforces optimistic concurrency: the WHERE clause matches both DeferredMessageID AND RowVersion; if the row was changed by another process the update silently affects 0 rows.
- If @RawMessage is supplied (not NULL), parses CID, AffiliateID/SerialID (PiggyBank branch), and Occurred from the XML payload using CHARINDEX/SUBSTRING inside a TRY/CATCH; parse failures are silently ignored.
- UPDATE uses ISNULL(@param, current_column) for RawMessage, Status, CID, and AffiliateID to allow partial updates (supply NULL to keep existing values).
- Occurred is always set to the parsed value (or NULL if parsing failed/RawMessage is NULL).
- UpdatedOn is always stamped with the current time.
- Uses OUTPUT clause to capture @NewRowVersion for the caller.
- Returns @UpdatedOn = the timestamp used for UpdatedOn.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @DeferredMessageID | INT | IN | (required) | High | Primary key of the message to update |
| 2 | @RowVersion | TIMESTAMP | IN | (required) | High | Current concurrency token; must match the stored value |
| 3 | @RawMessage | NVARCHAR(MAX) | IN | NULL | High | New message body; NULL keeps the existing value |
| 4 | @Status | INT | IN | NULL | High | New status code; NULL keeps the existing value |
| 5 | @NewRowVersion | TIMESTAMP | OUT | NULL | High | Updated concurrency token after the update |
| 6 | @UpdatedOn | DATETIME | OUT | NULL | High | Timestamp applied to the UpdatedOn column |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | dbo.DeferredMessages | Write | Updates status, raw message, parsed fields, and UpdatedOn |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DeferredMessages_Update
  └── dbo.DeferredMessages    (WRITE - UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.DeferredMessages | Table | Target of the conditional UPDATE |

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
-- Advance a message from pending (0) to processing (1)
DECLARE @NewRV TIMESTAMP, @UpdatedOn DATETIME;
EXEC dbo.DeferredMessages_Update
    @DeferredMessageID = 55001,
    @RowVersion        = 0x00000000000107A3,
    @Status            = 1,
    @NewRowVersion     = @NewRV     OUTPUT,
    @UpdatedOn         = @UpdatedOn OUTPUT;
SELECT @NewRV AS NewRowVersion, @UpdatedOn AS UpdatedOn;

-- Update both the message body and status
DECLARE @NewRV2 TIMESTAMP, @UpdOn2 DATETIME;
EXEC dbo.DeferredMessages_Update
    @DeferredMessageID = 55001,
    @RowVersion        = 0x00000000000107A3,
    @RawMessage        = N'<CID>1001</CID><SerialID>5500</SerialID><Occurred>2026-04-12T12:00:00</Occurred>',
    @Status            = 2,
    @NewRowVersion     = @NewRV2 OUTPUT,
    @UpdatedOn         = @UpdOn2 OUTPUT;

-- Verify the updated row
SELECT DeferredMessageID, Status, UpdatedOn, CID, AffiliateID
FROM dbo.DeferredMessages WHERE DeferredMessageID = 55001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.DeferredMessages_Update | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DeferredMessages_Update.sql*
