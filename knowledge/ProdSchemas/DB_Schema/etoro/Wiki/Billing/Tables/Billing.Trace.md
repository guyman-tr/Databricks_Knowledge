# Billing.Trace

> Audit log of 3D Secure Cardinal Commerce request/response payloads for deposits, refunds, and payouts - captures raw JSON messages from the Cardinal lookup and authentication flow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | Id (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 3 (PK + 2 NCI on Cid + 2 NCI on TransactionId) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.Trace is the 3D Secure (3DS) audit log for Cardinal Commerce interactions. When a credit card payment (deposit, refund, or payout) triggers the 3DS authentication flow, each request sent to and response received from the Cardinal Commerce service is persisted here as a JSON message. This provides a complete audit trail of the 3DS exchange, including lookup requests, lookup responses, authentication requests, and authentication responses.

The table stores the raw JSON payloads - including the complete 3DS challenge parameters, device browser fingerprint data, card enrollment status, authentication results (PARes status, ECI flags, CAVV values), and transaction IDs. This level of detail is essential for fraud investigations, chargeback disputes, and debugging failed 3DS flows.

**22,788 rows** (small, audit-log table). Most common patterns:
- EventType 0+1 (Lookup request+response): ~5,300-5,400 rows each for Deposits (TransactionType=0)
- EventType 0-4 sequence for Payouts (TransactionType=2): ~1,300-2,300 rows each step

---

## 2. Business Logic

### 2.1 Cardinal Commerce 3DS Flow Capture

**What**: Every step of the Cardinal Commerce 3DS flow produces one row - from the initial lookup to the final authentication response.

**Cardinal 3DS event sequence**:
```
Step 1: EventType=0 CardinalRequest
  -> Lookup request sent to Cardinal with card BIN, device fingerprint, order details
  -> Message contains: CardNumber (masked), BrowserInfo, OrgUnit, MerchantData, etc.

Step 2: EventType=1 CardinalResponse
  -> Cardinal lookup response received
  -> Contains: Enrolled (Y/N), StepUpUrl, PAResStatus, EnumerationScore, ECI flag

Step 3: EventType=2 ThreeDsPayload (if 3DS challenge required)
  -> JWT token payload from Cardinal's 3DS server
  -> Contains: Consumer session, reference IDs, validation status

Step 4: EventType=3 CardinalAuthenticateRequest
  -> Authentication request sent to Cardinal
  -> Contains: signature, timestamp, orgUnit, identifier

Step 5: EventType=4 CardinalAuthenticateResponse
  -> Final authentication result from Cardinal
  -> Contains: CAVV, PAResStatus (Y/N/A), EciFlag, 3DS server transaction IDs
```

**TransactionType mapping**:
- 0=Deposit: Standard CC deposit 3DS flow
- 1=Refund: Refund transaction 3DS verification
- 2=Payout: Payout/withdrawal 3DS authentication

### 2.2 TransactionId as Correlation Key

**What**: TransactionId links all 5 events of one 3DS exchange together. It is NOT a Billing.Deposit FK - it's the Cardinal Commerce transaction identifier.

**Rules**:
- Each 3DS interaction produces 3-5 rows with the same TransactionId
- TransactionId appears in the Cardinal JSON Messages as `TransactionId` field
- IX_Trace_Trax and ix_Billing_Trace_TransactionID both index this for fast event grouping
- Example: TransactionId=9048 has rows for EventTypes 0,1,2,3,4 (complete 3DS flow)

---

## 3. Data Overview

| EventType | Name | TransactionType=0 (Deposit) | TransactionType=1 (Refund) | TransactionType=2 (Payout) | Total |
|-----------|------|----|----|----|----|
| 0 | CardinalRequest | 5,367 | 438 | 2,326 | 8,131 |
| 1 | CardinalResponse | 5,347 | 394 | 2,301 | 8,042 |
| 2 | ThreeDsPayload | 2,341 | 207 | 1,362 | 3,910 |
| 3 | CardinalAuthenticateRequest | - | - | 1,353 | 1,353 |
| 4 | CardinalAuthenticateResponse | - | - | 1,352 | 1,352 |

Note: EventTypes 3 and 4 (authentication steps) appear only for Payouts. Deposit flows appear to stop at EventType=2. This may reflect different 3DS enforcement policies per transaction type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | INT | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate PK. NOT FOR REPLICATION indicates table is replicated. Auto-incremented ID for each trace row. |
| 2 | Created | SMALLDATETIME | NO | - | CODE-BACKED | Timestamp when this trace event was written. SMALLDATETIME (1-minute precision). No DEFAULT in DDL - set by application on insert. Rounded to the minute, so multiple events in the same 3DS flow may share the same Created value. |
| 3 | Cid | INT | NO | - | CODE-BACKED | Customer ID. Implicit FK to Customer.Customer. Indexed via IX_BillingTrace_Cid for customer-based trace lookup. Used to query all 3DS trace events for a specific customer. |
| 4 | EventType | INT | NO | - | CODE-BACKED | Type of Cardinal Commerce message captured. FK to Dictionary.TraceEventType(ID). 0=CardinalRequest, 1=CardinalResponse, 2=ThreeDsPayload, 3=CardinalAuthenticateRequest, 4=CardinalAuthenticateResponse. |
| 5 | Message | VARCHAR(4000) | YES | - | CODE-BACKED | Full JSON payload of the Cardinal message. Up to 4000 characters. Contains complete request/response data including device fingerprint (browser info, screen size, language), card BIN (masked), 3DS transaction IDs (ThreeDSServerTransactionId, ACSTransactionId, DSTransactionId), authentication result (CAVV, PAResStatus, EciFlag), and risk scores. |
| 6 | TransactionId | INT | NO | - | CODE-BACKED | Cardinal Commerce transaction identifier linking all events of one 3DS exchange. Indexed via two NCIs. NOT a FK to Billing.Deposit or Billing.Payment. Used to group related trace events: all EventTypes for one payment attempt share the same TransactionId. |
| 7 | TransactionType | INT | NO | - | CODE-BACKED | Type of financial transaction triggering this 3DS event. FK to Dictionary.TransactionType(ID). 0=Deposit, 1=Refund, 2=Payout. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventType | Dictionary.TraceEventType | FK (FK_BillingTrace_DictionaryTraceEventType) | 0=CardinalRequest, 1=CardinalResponse, 2=ThreeDsPayload, 3=CardinalAuthenticateRequest, 4=CardinalAuthenticateResponse |
| TransactionType | Dictionary.TransactionType | FK (FK_BillingTrace_DictionaryTransactionType) | 0=Deposit, 1=Refund, 2=Payout |
| Cid | Customer.Customer | Implicit FK (no DDL constraint) | Customer whose payment triggered this 3DS flow |
| TransactionId | (Cardinal Commerce external) | External reference | Cardinal Commerce transaction ID - not an internal FK |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.GetDepositsCustomerCardPCIVersion | TransactionId, Cid | READER | Retrieves 3DS trace data for deposit lookup - used for PCI audit context |
| Billing.Daily3dReport | TransactionId | READER | Daily 3DS reporting dashboard |
| Billing.Daily3dReportHTML | TransactionId | READER | HTML-formatted version of Daily3dReport |

---

## 6. Dependencies

```
Billing.Trace (table)
|- Dictionary.TraceEventType (table) [FK: EventType]
└-- Dictionary.TransactionType (table) [FK: TransactionType]
```

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingTrace | CLUSTERED PK | Id ASC | - | - | Active |
| IX_BillingTrace_Cid | NONCLUSTERED | Cid ASC | - | - | Active |
| IX_Trace_Trax | NONCLUSTERED | TransactionId ASC | Created, EventType, Message | - | Active |
| ix_Billing_Trace_TransactionID | NONCLUSTERED | TransactionId ASC | Cid, EventType, TransactionType, Message | - | Active (PAGE COMPRESSION) |

Two indexes on TransactionId - the older IX_Trace_Trax and the newer ix_Billing_Trace_TransactionID (with more included columns and page compression). This is an index duplication that could be consolidated.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingTrace | PRIMARY KEY CLUSTERED | Id must be unique |
| FK_BillingTrace_DictionaryTraceEventType | FOREIGN KEY | EventType must exist in Dictionary.TraceEventType(ID) |
| FK_BillingTrace_DictionaryTransactionType | FOREIGN KEY | TransactionType must exist in Dictionary.TransactionType(ID) |

---

## 8. Sample Queries

### 8.1 Get full 3DS trace for a specific Cardinal transaction

```sql
DECLARE @TransactionId INT = 9048

SELECT
    t.Id,
    t.Created,
    t.Cid,
    t.EventType,
    tet.TraceEventType AS EventTypeName,
    t.TransactionId,
    t.TransactionType,
    tt.TransactionType AS TransactionTypeName,
    t.Message
FROM [Billing].[Trace] t WITH (NOLOCK)
INNER JOIN [Dictionary].[TraceEventType] tet WITH (NOLOCK) ON tet.ID = t.EventType
INNER JOIN [Dictionary].[TransactionType] tt WITH (NOLOCK) ON tt.ID = t.TransactionType
WHERE t.TransactionId = @TransactionId
ORDER BY t.Id
```

### 8.2 Get all 3DS traces for a customer

```sql
DECLARE @CID INT = 25416707

SELECT
    t.Id,
    t.Created,
    t.EventType,
    tet.TraceEventType AS EventTypeName,
    t.TransactionId,
    t.TransactionType,
    LEFT(t.Message, 200) AS MessagePreview
FROM [Billing].[Trace] t WITH (NOLOCK)
INNER JOIN [Dictionary].[TraceEventType] tet WITH (NOLOCK) ON tet.ID = t.EventType
WHERE t.Cid = @CID
ORDER BY t.Created DESC, t.Id DESC
```

### 8.3 3DS event distribution summary

```sql
SELECT
    t.TransactionType,
    tt.TransactionType AS TransactionTypeName,
    t.EventType,
    tet.TraceEventType AS EventTypeName,
    COUNT(*) AS EventCount
FROM [Billing].[Trace] t WITH (NOLOCK)
INNER JOIN [Dictionary].[TraceEventType] tet WITH (NOLOCK) ON tet.ID = t.EventType
INNER JOIN [Dictionary].[TransactionType] tt WITH (NOLOCK) ON tt.ID = t.TransactionType
GROUP BY t.TransactionType, tt.TransactionType, t.EventType, tet.TraceEventType
ORDER BY t.TransactionType, t.EventType
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 7.5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Trace | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Trace.sql*
