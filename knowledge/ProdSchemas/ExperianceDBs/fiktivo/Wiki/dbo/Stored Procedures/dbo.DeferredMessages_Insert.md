# dbo.DeferredMessages_Insert

> Inserts a new deferred message into the queue, parsing CID, AffiliateID, and Occurred timestamp from the XML-like RawMessage payload, and returns the generated ID, RowVersion, and registration timestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | DeferredMessageID (generated on insert) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the enqueue endpoint for the DeferredMessages queue system. It is called whenever an upstream service needs to submit a message for asynchronous processing by the affiliate platform workers. In addition to storing the raw message body, it parses key fields directly out of the XML payload (CID, AffiliateID or SerialID, and Occurred) to enable efficient filtering and routing by the consumer side. The extracted values are stored in indexed columns on the DeferredMessages table so consumers can filter without parsing raw XML. The procedure returns the new record's ID, RowVersion, and RegisteredOn timestamp so the caller can track the message.

---

## 2. Business Logic

- Parses @RawMessage for XML tags using CHARINDEX and SUBSTRING inside a TRY/CATCH block; parsing failures are silently swallowed (fields default to NULL / 0).
- AffiliateID extraction branches: if the message contains 'PiggyBank', extracts from the AffiliateID XML tag; otherwise extracts from the SerialID tag.
- Inserts one row into DeferredMessages with Status defaulting to 0 (pending) if @Status is NULL.
- RegisteredOn and UpdatedOn are both set to the same @time snapshot.
- Uses OUTPUT clause to capture the generated DeferredMessageID and RowVersion from the inserted row.
- Returns @DeferredMessageID, @RowVersion, and @RegsiteredOn (note: typo in original - "Regsiter") as OUTPUT parameters.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @RawMessage | NVARCHAR(MAX) | IN | NULL | High | Raw XML-like message body to store and parse |
| 2 | @Source | NVARCHAR(MAX) | IN | NULL | High | Originating system or topic name |
| 3 | @SourceKey | NVARCHAR(MAX) | IN | NULL | High | Source-specific unique key for deduplication |
| 4 | @TrackingKey | NVARCHAR(MAX) | IN | NULL | High | Correlation/tracking key for end-to-end tracing |
| 5 | @Status | INT | IN | NULL | High | Initial status; defaults to 0 (pending) if NULL |
| 6 | @DeferredMessageID | INT | OUT | NULL | High | Generated primary key of the new row |
| 7 | @RowVersion | TIMESTAMP | OUT | NULL | High | Concurrency token for subsequent update/delete calls |
| 8 | @RegsiteredOn | DATETIME | OUT | NULL | High | Timestamp recorded as RegisteredOn (matches UpdatedOn on insert) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | dbo.DeferredMessages | Write | Adds the new message row to the queue |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DeferredMessages_Insert
  └── dbo.DeferredMessages    (WRITE - INSERT)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.DeferredMessages | Table | Destination queue table |

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
-- Enqueue a new CPA event message
DECLARE @MsgID INT, @RV TIMESTAMP, @RegOn DATETIME;
EXEC dbo.DeferredMessages_Insert
    @RawMessage        = N'<CID>1001</CID><SerialID>5500</SerialID><Occurred>2026-04-12T10:00:00</Occurred>',
    @Source            = N'CPAService',
    @SourceKey         = N'DEP-98765',
    @TrackingKey       = N'TRACK-001',
    @Status            = 0,
    @DeferredMessageID = @MsgID    OUTPUT,
    @RowVersion        = @RV       OUTPUT,
    @RegsiteredOn      = @RegOn    OUTPUT;
SELECT @MsgID AS NewID, @RegOn AS RegisteredOn;

-- Enqueue a PiggyBank message (uses AffiliateID tag instead of SerialID)
DECLARE @ID INT, @RV2 TIMESTAMP, @Reg2 DATETIME;
EXEC dbo.DeferredMessages_Insert
    @RawMessage  = N'<CID>2002</CID><AffiliateID>56662</AffiliateID><PiggyBank/><Occurred>2026-04-12T11:00:00</Occurred>',
    @Source      = N'PiggyBankService',
    @SourceKey   = N'PB-001',
    @DeferredMessageID = @ID  OUTPUT,
    @RowVersion        = @RV2 OUTPUT,
    @RegsiteredOn      = @Reg2 OUTPUT;
SELECT @ID AS NewID;

-- Verify insert
SELECT DeferredMessageID, Source, Status, CID, AffiliateID, RegisteredOn
FROM dbo.DeferredMessages WHERE DeferredMessageID = @ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 8.2/10*
*Object: dbo.DeferredMessages_Insert | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.DeferredMessages_Insert.sql*
