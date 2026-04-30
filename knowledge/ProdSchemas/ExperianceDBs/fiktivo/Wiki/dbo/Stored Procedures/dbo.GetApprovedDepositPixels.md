# dbo.GetApprovedDepositPixels

> Marks a durable message as delivered by updating tblaff_DurableMessages based on ReferenceID and CorrelationID, and returns the MessageData payload via an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Geri Reshef |
| **Created** | 2017-08-05 |

---

## 1. Business Meaning

The approved-deposit pixel system is responsible for firing tracking pixels when a customer deposit is approved. To guarantee at-most-once delivery, deposit pixel messages are stored in a durable message table (tblaff_DurableMessages) and must be explicitly acknowledged once delivered.

This procedure performs the acknowledgement: it locates the undelivered message identified by @ReferenceID and @CorrelationID, updates its delivery status, and returns the original MessageData payload to the caller via an OUTPUT parameter. The caller can then use the payload to fire the actual pixel call.

The UPDATE...OUTPUT pattern (OUTPUT Inserted.MessageData INTO @T) atomically captures the pre-update data in a single statement, avoiding race conditions that would arise from a separate SELECT followed by an UPDATE.

---

## 2. Business Logic

### 2.1 Atomic Acknowledge-and-Retrieve

**What**: Marks one undelivered durable message as delivered and returns its payload.

**Columns/Parameters Involved**: `@ReferenceID`, `@CorrelationID`, `@IsDelivered`, `@UpdateTime`, `IsDelivered`, `UpdateTime`, `MessageData`

**Rules**:
- The WHERE clause filters to rows where ReferenceID = @ReferenceID AND CorrelationID = @CorrelationID AND IsDelivered = 0
- Only undelivered messages (IsDelivered = 0) are updated; if the message was already delivered, no rows are affected and @MessageData remains NULL
- The UPDATE sets IsDelivered = @IsDelivered (defaults to 1) and UpdateTime = @UpdateTime (defaults to NULL, caller should supply the current timestamp)
- MessageData is captured from the updated row via the OUTPUT clause and stored in the table variable @T before being assigned to the output parameter
- If no matching row exists, @MessageData is set to NULL and the procedure returns silently

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ReferenceID | IN | bigint | (required) | The numeric reference identifier of the durable message to acknowledge. Used with @CorrelationID to uniquely locate the message row. |
| 2 | @CorrelationID | IN | varchar(255) | (required) | A string correlation identifier (e.g., a GUID or tracking token) that further qualifies the message to acknowledge. |
| 3 | @IsDelivered | IN | bit | 1 | The delivered flag value to set on the message row. Defaults to 1 (delivered). |
| 4 | @UpdateTime | IN | datetime | NULL | The timestamp to record as the delivery acknowledgement time. Caller should supply GETDATE(); defaults to NULL if omitted. |
| 5 | @MessageData | OUT | nvarchar(max) | NULL | Returns the MessageData payload of the acknowledged message. NULL if no undelivered row matched. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_DurableMessages | UPDATE | Sets IsDelivered and UpdateTime on the matched undelivered message row |

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_DurableMessages | UPDATE with OUTPUT | The OUTPUT clause reads Inserted.MessageData from the updated row |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetApprovedDepositPixels (stored procedure)
+-- dbo.tblaff_DurableMessages (table) [UPDATE with OUTPUT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_DurableMessages | Table | Target of the UPDATE; source of the MessageData output |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deposit pixel delivery service | Application | Calls this procedure to claim and retrieve undelivered pixel messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- The UPDATE...OUTPUT...INTO @T pattern performs a single atomic operation; no separate SELECT is required
- Only rows with IsDelivered = 0 are updated, providing idempotency protection
- The procedure name references "GetApproved" but the primary operation is an UPDATE (acknowledgement); the "Get" reflects the return of the MessageData payload
- Jira context: ticket 45013 ("Approved Deposit Pixel - DB Changes") introduced this procedure on 2017-08-05

---

## 8. Sample Queries

### 8.1 Acknowledge a pixel message and retrieve its payload

```sql
DECLARE @Payload NVARCHAR(MAX);
EXEC dbo.GetApprovedDepositPixels
    @ReferenceID  = 98765,
    @CorrelationID = '3fa85f64-5717-4562-b3fc-2c963f66afa6',
    @IsDelivered  = 1,
    @UpdateTime   = GETDATE(),
    @MessageData  = @Payload OUTPUT;
SELECT @Payload AS ReturnedPayload;
```

### 8.2 Check for undelivered messages for a reference

```sql
SELECT ReferenceID, CorrelationID, IsDelivered, UpdateTime
FROM dbo.tblaff_DurableMessages WITH (NOLOCK)
WHERE ReferenceID = 98765
  AND IsDelivered = 0;
```

### 8.3 Count pending undelivered messages

```sql
SELECT COUNT(*) AS PendingCount
FROM dbo.tblaff_DurableMessages WITH (NOLOCK)
WHERE IsDelivered = 0;
```

---

## 9. Atlassian Knowledge Sources

- Ticket 45013: "Approved Deposit Pixel - DB Changes" (2017-08-05, Geri Reshef) -- introduced the durable message table and this acknowledgement procedure.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10*
*Object: dbo.GetApprovedDepositPixels | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetApprovedDepositPixels.sql*
