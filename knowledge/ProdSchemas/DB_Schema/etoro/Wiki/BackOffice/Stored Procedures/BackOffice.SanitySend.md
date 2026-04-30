# BackOffice.SanitySend

> Packages a description and XML data payload into a Service Broker XML message and sends it on the ctrDataIntegrity contract from svcInitiator to svcDataIntegrity for asynchronous data integrity processing.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | BEGIN DIALOG CONVERSATION from svcInitiator to svcDataIntegrity ON ctrDataIntegrity; SEND ON CONVERSATION MESSAGE TYPE mtDataIntegrity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.SanitySend` is the Service Broker delivery layer for the BackOffice data integrity alerting system. It is called by `BackOffice.SanityCheck` whenever that procedure detects a data consistency violation (e.g., a credit record without a matching payment, or a balance that does not match the sum of its history).

The procedure wraps the violation details in a standardized XML envelope (with Description, Occurred timestamp, and the anomaly data as a nested XML payload) and delivers it asynchronously via SQL Server Service Broker. The receiving service (`svcDataIntegrity`) processes these messages independently - likely triggering alerts, logging to an audit system, or notifying operations staff.

By using Service Broker rather than direct inserts or synchronous email, the sending transaction is decoupled from the notification delivery. `SanityCheck` can detect a problem and fire this message within a fraction of a second, even if the downstream processor is temporarily unavailable.

---

## 2. Business Logic

### 2.1 XML Message Construction

**What**: Builds a standardized SanityCheck XML envelope containing the violation description, timestamp, and data payload.

**Rules**:
- `SELECT @Description AS Description, GETDATE() AS Occurred, @XMLData FOR XML RAW(''), BINARY BASE64, ELEMENTS, TYPE, ROOT('SanityCheck')`: wraps the inputs in a `<SanityCheck>` root element with Description, Occurred, and the caller-provided XML data nested inside.
- `BINARY BASE64`: any binary content in @XMLData is encoded as Base64 in the output.
- `TYPE`: the FOR XML result is typed as XML (not varchar), preserving XML structure for the Service Broker message.
- The resulting @XMLMessage is always a well-formed XML document with a `<SanityCheck>` root.

### 2.2 Service Broker Message Delivery

**What**: Opens a new dialog and sends the XML message asynchronously to the data integrity service.

**Rules**:
- `BEGIN DIALOG CONVERSATION @Handle FROM SERVICE svcInitiator TO SERVICE 'svcDataIntegrity', 'CURRENT DATABASE' ON CONTRACT ctrDataIntegrity`: opens a one-way conversation. 'CURRENT DATABASE' routes to the service in the same database (not a remote Service Broker endpoint).
- `SEND ON CONVERSATION @Handle MESSAGE TYPE mtDataIntegrity (@XMLMessage)`: sends the XML payload. The message type `mtDataIntegrity` defines the expected XML schema/contract.
- The dialog is NOT ended after SEND - the conversation remains open (fire-and-forget style; the receiver ends the conversation after processing).
- No error handling: if Service Broker is disabled or the service is unavailable, this SEND will fail silently or raise an error that propagates to the caller (SanityCheck).
- `RETURN 0`: always returns success code 0.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Description | varchar(255) | NO | - | CODE-BACKED | Human-readable description of the data integrity violation being reported. Becomes the Description element in the XML envelope. Examples: 'CREDIT DOES NOT MATCH HISTORY', 'DEPOSIT WITHOUT PAYMENT', 'PAYMENT WITHOUT DEPOSIT'. |
| 2 | @XMLData | xml | NO | - | CODE-BACKED | XML payload containing the specific anomalous records. Constructed by SanityCheck using FOR XML RAW with a schema-specific ROOT element (e.g., AccountDifference, ActionCountDifference). Nested inside the SanityCheck envelope. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DIALOG CONVERSATION | svcInitiator (Service Broker service) | Caller | Source service for the dialog |
| SEND | svcDataIntegrity (Service Broker service) | Callee (async) | Destination service that processes data integrity violation messages |
| CONTRACT | ctrDataIntegrity | Protocol | Defines allowed message types and direction for the conversation |
| MESSAGE TYPE | mtDataIntegrity | Protocol | Defines the expected XML structure of the message payload |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.SanityCheck | EXECUTE BackOffice.SanitySend | Caller | Calls SanitySend for each active data integrity check that finds violations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SanitySend (procedure)
+-- svcInitiator (Service Broker service) [BEGIN DIALOG FROM]
+-- svcDataIntegrity (Service Broker service) [SEND TO]
+-- ctrDataIntegrity (Service Broker contract) [ON CONTRACT]
+-- mtDataIntegrity (Service Broker message type) [MESSAGE TYPE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| svcInitiator | Service Broker Service | Source of the dialog conversation |
| svcDataIntegrity | Service Broker Service | Destination for data integrity violation messages |
| ctrDataIntegrity | Service Broker Contract | Protocol contract governing the conversation |
| mtDataIntegrity | Service Broker Message Type | Defines the XML message format sent in the conversation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.SanityCheck | Stored Procedure | Calls SanitySend to deliver violation alerts for each active integrity check |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Service Broker requirement | Infrastructure | Requires Service Broker to be enabled on the database and the svcInitiator/svcDataIntegrity services to be configured. |
| 'CURRENT DATABASE' routing | Design | Dialog is routed within the same database - no remote Service Broker endpoint required. |
| Open dialog (no END CONVERSATION) | Design | The conversation handle is not closed by SanitySend - the receiver (svcDataIntegrity) is responsible for ending the conversation. |

---

## 8. Sample Queries

### 8.1 Send a data integrity violation alert (via SanityCheck)

```sql
-- SanitySend is called internally by SanityCheck; direct calls are for testing only
DECLARE @XMLData XML = (
    SELECT 12345 AS CID, 1000.00 AS Credit, 950.00 AS SumInHistory
    FOR XML RAW('Customer'), ELEMENTS, ROOT('AccountDifference')
);
EXEC BackOffice.SanitySend
    @Description = 'CREDIT DOES NOT MATCH HISTORY',
    @XMLData = @XMLData;
```

### 8.2 Check Service Broker queue for pending integrity messages

```sql
SELECT TOP 10 message_type_name, CAST(message_body AS XML) AS MessageBody, queuing_order
FROM sys.transmission_queue WITH (NOLOCK)
ORDER BY queuing_order;

-- Or check the target queue directly:
-- SELECT TOP 10 * FROM [<DataIntegrityQueueName>] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller (SanityCheck) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SanitySend | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SanitySend.sql*
