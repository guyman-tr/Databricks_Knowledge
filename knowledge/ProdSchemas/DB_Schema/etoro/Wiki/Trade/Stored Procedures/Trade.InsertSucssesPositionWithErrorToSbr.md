# Trade.InsertSucssesPositionWithErrorToSbr

> Service Broker relay that drains the Trade.PositionEndedWithTOError queue by sending each pending timeout-error notification as a Service Broker message to the position processing service, then deleting the delivered row. (Note: "Sucssess" is a typo in the original procedure name.)

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - processes all rows in Trade.PositionEndedWithTOError |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertSucssesPositionWithErrorToSbr is the Service Broker relay procedure for position timeout errors. When a position close or position-related operation times out, the failure context (an XML notification payload) is written to Trade.PositionEndedWithTOError by the timeout handler. This procedure is the consumer of that queue: it reads each pending notification, sends it as a Service Broker message to the svcPosition service, and removes the delivered row.

Without this procedure, timeout error notifications would accumulate indefinitely in PositionEndedWithTOError and never reach the position processing service. The Service Broker channel (svcInitiator -> svcPosition) allows asynchronous, durable delivery to the position service even if it is temporarily unavailable - the broker guarantees delivery. Once the notification is sent and the row is deleted, the error is considered relayed and the position processing pipeline can act on it.

Data flow: Position timeout handler inserts into Trade.PositionEndedWithTOError -> this procedure is called (likely by a scheduled job or agent) -> for each row it sends the XML payload via SB -> deletes the row -> loop continues until the table is empty. The table is typically empty in steady state, indicating successful draining.

---

## 2. Business Logic

### 2.1 Service Broker Drain Loop

**What**: Row-by-row processing loop that sends each queued error notification via Service Broker and deletes it on success.

**Columns/Parameters Involved**: PositionEndedWithTOError.ID, PositionEndedWithTOError.Notificationtosend

**Rules**:
- Processes rows in ascending ID order (MIN(ID) first) - oldest errors are relayed first (FIFO queue semantics).
- Each iteration operates in its own transaction: BEGIN TRANSACTION / COMMIT (or ROLLBACK on error).
- The Notificationtosend column is cast to XML before sending as the Service Broker message body.
- If a Service Broker SEND fails for a row, CATCH block ROLLBACKs the transaction (row remains in table for retry) and SELECT ERROR_MESSAGE() returns the error. The WHILE loop then attempts the next row (error does not break the loop).
- After successful SEND and END CONVERSATION, the row is DELETE'd within the same transaction - atomicity ensures no message is sent without the corresponding delete.

**Diagram**:
```
WHILE Trade.PositionEndedWithTOError has rows
    |
    +-> Get MIN(ID) -> @ID
    +-> Get Notificationtosend as XML -> @XMLResult
    |
    +-> BEGIN TRAN
    |       BEGIN DIALOG CONVERSATION @Handle
    |           FROM svcInitiator
    |           TO svcPosition (CURRENT DATABASE)
    |           ON CONTRACT ctrAnyXMLData
    |
    |       SEND ON CONVERSATION @Handle
    |           MESSAGE TYPE mtAnyXMLData (@XMLResult)
    |
    |       END CONVERSATION @Handle
    |
    |       DELETE PositionEndedWithTOError WHERE ID = @ID
    |   COMMIT
    |
    +-> [CATCH: ROLLBACK, SELECT ERROR_MESSAGE(), continue loop]
    |
LOOP until table empty
```

### 2.2 Service Broker Channel

**What**: Uses a defined Service Broker channel to deliver position timeout notifications asynchronously.

**Columns/Parameters Involved**: svcInitiator, svcPosition, ctrAnyXMLData, mtAnyXMLData

**Rules**:
- FROM SERVICE: svcInitiator - the sending service (this database)
- TO SERVICE: svcPosition (CURRENT DATABASE) - the receiving service (same database, asynchronous queue)
- CONTRACT: ctrAnyXMLData - the contract governing the message exchange
- MESSAGE TYPE: mtAnyXMLData - the XML message type
- END CONVERSATION is called immediately after SEND - this is a fire-and-forget pattern: the dialog is opened, one message sent, and closed immediately.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|

No parameters. The procedure processes all rows in Trade.PositionEndedWithTOError unconditionally.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHILE + SELECT | Trade.PositionEndedWithTOError | Reader | Reads rows to process (MIN(ID), Notificationtosend) |
| DELETE | Trade.PositionEndedWithTOError | Deleter | Removes each successfully sent row |
| Service Broker | svcPosition | SB Message | Sends XML notification to the position processing service |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase - called by a scheduled job or SQL Server Agent job that polls for pending errors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertSucssesPositionWithErrorToSbr (procedure)
└── Trade.PositionEndedWithTOError (table) - source queue (read + delete)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionEndedWithTOError | Table | Source queue - reads pending notifications and deletes processed rows |
| svcInitiator | Service Broker Service | Sending service for dialog conversations |
| svcPosition | Service Broker Service | Receiving service for position notifications |
| ctrAnyXMLData | Service Broker Contract | Contract governing the message exchange |
| mtAnyXMLData | Service Broker Message Type | XML message type for notification payloads |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled job / SQL Server Agent | External | Calls this procedure to drain the error queue |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Per-row transaction | Design | Each row is processed in its own transaction - a SB failure for one row does not prevent processing of subsequent rows |
| CAST as XML | Runtime | Notificationtosend (varchar(max)) is cast to XML before sending - the payload must be valid XML or the cast will raise an error and trigger the CATCH block |

---

## 8. Sample Queries

### 8.1 Check pending notifications before running the procedure

```sql
SELECT
    pe.ID,
    pe.MessageType,
    pe.Notificationtosend,
    pe.Status,
    pe.Occurred
FROM Trade.PositionEndedWithTOError pe WITH (NOLOCK)
ORDER BY pe.ID ASC;
```

### 8.2 Run the procedure to drain the queue

```sql
EXEC Trade.InsertSucssesPositionWithErrorToSbr;
```

### 8.3 Verify queue is empty after execution

```sql
SELECT COUNT(*) AS PendingErrors
FROM Trade.PositionEndedWithTOError WITH (NOLOCK);
-- Expected: 0 when queue is fully drained
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.InsertSucssesPositionWithErrorToSbr | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertSucssesPositionWithErrorToSbr.sql*
