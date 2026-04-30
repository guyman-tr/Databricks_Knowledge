# Billing.TraceAdd

> Inserts a 3D Secure Cardinal Commerce audit event (request or response JSON payload) into Billing.Trace for fraud investigation, chargeback disputes, and debugging failed 3DS flows.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Inserts into Billing.Trace; no output parameter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.TraceAdd` is the write procedure for the 3D Secure audit log (`Billing.Trace`). It captures each step of the Cardinal Commerce 3DS authentication flow - lookup requests, lookup responses, JWT payloads, authentication requests, and authentication responses - as raw JSON messages. Every time the payment processing pipeline sends or receives a message from Cardinal Commerce during 3DS verification, it calls this procedure to persist the payload.

This procedure was created as part of the ThreeDs database implementation (PAYIL-4273, May 2022). Before this, 3DS exchange messages were not persisted to the database, making fraud investigations and chargeback disputes reliant on external logs. `Billing.TraceAdd` ensures every 3DS interaction is durably stored with the customer ID, event type, transaction ID, and full message payload.

Called by the 3DS processing service (ThreeDsUser role) during deposit, refund, and payout flows whenever 3DS authentication is required. A single 3DS interaction generates 3-5 calls to this procedure (one per event in the Cardinal flow), all sharing the same `@TransactionId` as the correlation key.

---

## 2. Business Logic

### 2.1 3DS Event Sequence Capture

**What**: Each call to TraceAdd records one event in the 5-step Cardinal Commerce 3DS flow. Multiple calls with the same @TransactionId represent a single 3DS interaction.

**Columns/Parameters Involved**: `@EventType`, `@TransactionId`, `@TransactionType`, `@Message`

**Rules**:
- `@EventType=0` (CardinalRequest): Lookup request sent to Cardinal with card BIN and device fingerprint
- `@EventType=1` (CardinalResponse): Cardinal lookup response with enrollment status and step-up URL
- `@EventType=2` (ThreeDsPayload): JWT token payload from Cardinal's 3DS server (only if challenge required)
- `@EventType=3` (CardinalAuthenticateRequest): Authentication request to Cardinal
- `@EventType=4` (CardinalAuthenticateResponse): Final authentication result with CAVV, PAResStatus, ECI flag
- `@TransactionType=0` (Deposit), `=1` (Refund), `=2` (Payout): determines which payment flow triggered 3DS
- All five rows for a single 3DS interaction share the same `@TransactionId` (Cardinal Commerce transaction ID)

**Diagram**:
```
Deposit 3DS flow:
  TraceAdd(@CID=123, @EventType=0, @TransactionId=9048, @TransactionType=0, @Message='{lookup request JSON}')
  TraceAdd(@CID=123, @EventType=1, @TransactionId=9048, @TransactionType=0, @Message='{lookup response JSON}')
  TraceAdd(@CID=123, @EventType=2, @TransactionId=9048, @TransactionType=0, @Message='{JWT payload}')
  TraceAdd(@CID=123, @EventType=3, @TransactionId=9048, @TransactionType=0, @Message='{auth request JSON}')
  TraceAdd(@CID=123, @EventType=4, @TransactionId=9048, @TransactionType=0, @Message='{auth response JSON}')

Result in Billing.Trace: 5 rows with Id=auto, Created=UTC now, all with TransactionId=9048
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account undergoing 3DS verification. Maps to `Billing.Trace.Cid`. Used to correlate 3DS events to a specific customer for investigations. |
| 2 | @EventType | INT | NO | - | CODE-BACKED | The step in the Cardinal Commerce 3DS flow being logged: 0=CardinalRequest (lookup request), 1=CardinalResponse (lookup response), 2=ThreeDsPayload (JWT payload), 3=CardinalAuthenticateRequest, 4=CardinalAuthenticateResponse. Maps to `Billing.Trace.EventType`. |
| 3 | @Message | VARCHAR(4000) | NO | - | CODE-BACKED | Raw JSON payload of the Cardinal Commerce message at this step. Contains the full 3DS exchange data including card enrollment status, CAVV, ECI flags, and PARes status depending on EventType. Maps to `Billing.Trace.Message`. |
| 4 | @TransactionId | INT | NO | - | CODE-BACKED | Cardinal Commerce transaction identifier that groups all events from a single 3DS interaction. NOT a FK to Billing.Deposit - this is Cardinal's own transaction ID. Maps to `Billing.Trace.TransactionId`. Indexed on the target table for fast event grouping. |
| 5 | @TransactionType | INT | NO | - | CODE-BACKED | The payment flow that triggered 3DS: 0=Deposit, 1=Refund, 2=Payout. Maps to `Billing.Trace.TransactionType`. Enables filtering the audit log by payment direction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Billing.Trace | Direct INSERT | Appends one 3DS event row with UTC timestamp set by procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| 3DS processing service | - | EXEC (ThreeDsUser role) | Called during Cardinal Commerce 3DS flows for deposits, refunds, and payouts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.TraceAdd (procedure)
└── Billing.Trace (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Trace | Table | INSERT - appends one row per 3DS event, Created set to GETUTCDATE() by the procedure |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by ThreeDs payment service (ThreeDsUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: `Created` timestamp is set to `GETUTCDATE()` inside the procedure - callers do not supply the timestamp.

---

## 8. Sample Queries

### 8.1 Retrieve complete 3DS flow for a transaction
```sql
SELECT Id, Created, Cid, EventType, TransactionId, TransactionType,
       LEFT(Message, 200) AS MessagePreview
FROM Billing.Trace WITH (NOLOCK)
WHERE TransactionId = 9048
ORDER BY EventType;
```

### 8.2 Find all 3DS events for a customer
```sql
SELECT Id, Created, EventType, TransactionId, TransactionType,
       LEFT(Message, 100) AS MessagePreview
FROM Billing.Trace WITH (NOLOCK)
WHERE Cid = 12345
ORDER BY Created DESC;
```

### 8.3 Count 3DS events by type and transaction type
```sql
SELECT TransactionType,
       EventType,
       COUNT(*) AS EventCount
FROM Billing.Trace WITH (NOLOCK)
GROUP BY TransactionType, EventType
ORDER BY TransactionType, EventType;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PAYIL-4273: Add TraceAdd SP](https://etoro-jira.atlassian.net/browse/PAYIL-4273) | Jira | Confirms SP was created 2022-05-31 as part of the ThreeDs database implementation (parent: PAYIL-4365 ThreeDs DBA). Assigned to Shay Oren, reported by Itzik Galanti. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (PAYIL-4273) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.TraceAdd | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.TraceAdd.sql*
