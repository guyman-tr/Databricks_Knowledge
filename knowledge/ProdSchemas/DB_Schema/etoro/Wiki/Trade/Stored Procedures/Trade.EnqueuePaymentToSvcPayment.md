# Trade.EnqueuePaymentToSvcPayment

> Enqueues a dividend payment message to the svcPayment Service Broker service for asynchronous processing of corporate action cash payments.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sends Service Broker message to svcPayment |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the entry point for processing dividend and corporate action payments through the Service Broker asynchronous messaging pipeline. When a corporate action (such as a cash dividend) occurs, this procedure packages the payment details into a semicolon-delimited message and sends it to the `svcPayment` Service Broker service for processing.

The procedure exists to decouple payment execution from the corporate action detection logic. Rather than processing payments synchronously (which could block the caller and create contention), the payment is enqueued as a message that the payment service processes independently. This is critical for dividend processing, which may involve thousands of affected positions across many customers.

The message format is a fixed-position, semicolon-delimited string containing the CID, credit type (hardcoded as 14 = dividend credit), payment amount, timestamp, mirror trading context, fee type (hardcoded as 3 = DividendFee), instrument ID, and corporate action type. The svcPayment service unpacks this message and applies the payment to the customer's account.

---

## 2. Business Logic

### 2.1 Service Broker Message Format

**What**: Fixed-position message encoding for dividend payment processing.

**Columns/Parameters Involved**: `@CID`, `@InstrumentID`, `@PaymentAmount`, `@CorporateActionTypeID`, `@MirrorID`, `@IsMirrorActive`, `@Occurred`

**Rules**:
- Message positions: [0]=CID, [1]=CreditTypeID (always 14), [2]=DiffAmountInDollars, [3]=Occurred datetime, [4]=MirrorID, [5]=IsMirrorActive, [6]=FeeType (always 3=DividendFee), [7]=InstrumentId, [8]=CorporateActionTypeID
- CreditTypeID is hardcoded to 14, identifying this as a dividend-related credit type
- FeeType is hardcoded to 3 (DividendFee), distinguishing from WeekEndFee (1) and OverNightFee (2)
- Occurred datetime is formatted as VARCHAR(40) using style 120 (YYYY-MM-DD HH:MM:SS)
- Message sent via Service Broker: FROM svcInitiator TO svcPayment ON CONTRACT ctrAnyData, MESSAGE TYPE mtAnyData

**Diagram**:
```
Caller (dividend processor)
  |
  v
Trade.EnqueuePaymentToSvcPayment
  |  Builds: "CID;14;Amount;DateTime;MirrorID;IsMirrorActive;3;InstrumentID;CorpActionTypeID"
  |
  v
Service Broker Queue (svcInitiator -> svcPayment)
  |
  v
Payment Service (processes asynchronously)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID receiving the payment. Message position [0]. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Financial instrument associated with the corporate action. Message position [7]. |
| 3 | @PaymentAmount | money | NO | - | CODE-BACKED | Dollar amount of the dividend/corporate action payment. Message position [2] as DiffAmountInDollars. Can be negative for tax withholding. |
| 4 | @CorporateActionTypeID | int | NO | - | CODE-BACKED | Type of corporate action triggering the payment (e.g., cash dividend, stock split adjustment). Message position [8]. |
| 5 | @MirrorID | int | NO | - | CODE-BACKED | Copy-trading mirror identifier. Message position [4]. 0 for non-mirrored (manual trade) positions. |
| 6 | @IsMirrorActive | bit | NO | - | CODE-BACKED | Whether the copy-trading relationship is still active. Message position [5]. Affects how the payment service handles the credit. |
| 7 | @Occurred | datetime | NO | - | CODE-BACKED | Timestamp of the corporate action event. Message position [3], formatted as 'YYYY-MM-DD HH:MM:SS'. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SEND ON CONVERSATION | svcPayment (Service Broker service) | Message Producer | Sends payment message for asynchronous processing |
| FROM SERVICE | svcInitiator (Service Broker service) | Message Origin | Initiating service for the dialog conversation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExecuteCashPayment | EXEC | Caller | Calls this procedure to enqueue dividend payments (Batch 26, #8) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.EnqueuePaymentToSvcPayment (procedure)
+-- svcInitiator (Service Broker service)
+-- svcPayment (Service Broker service)
+-- ctrAnyData (Service Broker contract)
+-- mtAnyData (Service Broker message type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| svcInitiator | Service Broker Service | FROM SERVICE in dialog conversation |
| svcPayment | Service Broker Service | TO SERVICE target for payment messages |
| ctrAnyData | Service Broker Contract | Contract governing the dialog |
| mtAnyData | Service Broker Message Type | Message type for the payment data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExecuteCashPayment | Stored Procedure | Calls this to enqueue individual dividend payments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Service Broker**: Uses `BEGIN DIALOG CONVERSATION` / `SEND ON CONVERSATION` pattern. Each call creates a new conversation. The 'CURRENT DATABASE' target qualifier means the payment queue is in the same database.

---

## 8. Sample Queries

### 8.1 Enqueue a Dividend Payment

```sql
EXEC Trade.EnqueuePaymentToSvcPayment
    @CID = 12345,
    @InstrumentID = 1001,
    @PaymentAmount = 5.25,
    @CorporateActionTypeID = 1,
    @MirrorID = 0,
    @IsMirrorActive = 0,
    @Occurred = '2026-03-15 22:00:00'
```

### 8.2 Check Service Broker Queue Status

```sql
SELECT service_name,
       msg_count = (SELECT COUNT(*) FROM sys.transmission_queue WITH (NOLOCK) WHERE to_service_name = sq.name)
  FROM sys.services sq
 WHERE sq.name IN ('svcPayment', 'svcInitiator')
```

### 8.3 View Recent Conversation Endpoints

```sql
SELECT TOP 20
       conversation_handle,
       state_desc,
       far_service,
       lifetime
  FROM sys.conversation_endpoints WITH (NOLOCK)
 WHERE far_service = 'svcPayment'
 ORDER BY lifetime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.EnqueuePaymentToSvcPayment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.EnqueuePaymentToSvcPayment.sql*
