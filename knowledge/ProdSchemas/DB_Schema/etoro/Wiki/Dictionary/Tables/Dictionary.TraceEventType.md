# Dictionary.TraceEventType

> Classifies Cardinal Commerce 3DS trace event types for payment authentication debugging.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Row Count** | 5 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95) |

---

## 1. Business Meaning

### What It Is
Dictionary.TraceEventType categorizes the trace/debug events generated during Cardinal Commerce 3D Secure payment authentication flows. Cardinal Commerce is the payment industry's 3DS authentication provider.

### Why It Exists
When debugging 3DS authentication issues, the billing team needs to trace the full request-response lifecycle between eToro's payment system and Cardinal Commerce's 3DS service. This table defines the five event types that can occur during a single authentication transaction.

### How It Works
The `ID` is stored in `Billing.Trace` alongside the actual request/response payloads. Each 3DS authentication produces multiple trace events — the request sent to Cardinal, the response received, the 3DS payload, and the final authenticate request/response pair. This enables full forensic reconstruction of any 3DS flow.

---

## 2. Business Logic

### Value Map (Complete — 5 rows)

| ID | TraceEventType | Business Meaning |
|----|----------------|------------------|
| 0 | CardinalRequest | Initial 3DS enrollment/lookup request sent to Cardinal Commerce |
| 1 | CardinalResponse | Cardinal Commerce's response to the enrollment/lookup request |
| 2 | ThreeDsPayload | The 3DS authentication challenge payload (sent to cardholder's bank) |
| 3 | CardinalAuthenticateRequest | Authentication verification request sent to Cardinal after cardholder completes challenge |
| 4 | CardinalAuthenticateResponse | Final authentication verification response from Cardinal |

### 3DS Authentication Lifecycle
```
0: CardinalRequest → 1: CardinalResponse → 2: ThreeDsPayload → 3: CardinalAuthenticateRequest → 4: CardinalAuthenticateResponse
```

---

## 3. Data Overview

| ID | TraceEventType | Scenario |
|----|----------------|----------|
| 0 | CardinalRequest | System sends card BIN to Cardinal to check 3DS enrollment |
| 1 | CardinalResponse | Cardinal responds with enrolled/not enrolled status |
| 2 | ThreeDsPayload | The OTP challenge HTML form sent to customer's browser |
| 3 | CardinalAuthenticateRequest | After customer enters OTP, verification sent to Cardinal |
| 4 | CardinalAuthenticateResponse | Cardinal confirms authentication success/failure |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | — | HIGH | Primary key identifying the trace event type. Sequential 0-4 covering the full Cardinal 3DS lifecycle. Referenced by Billing.Trace. |
| 2 | TraceEventType | varchar(100) | NO | — | HIGH | Event type label. PascalCase naming matching Cardinal Commerce API terminology. |

---

## 5. Relationships

### Referenced By (Implicit)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| Billing.Trace | TraceEventTypeID | Implicit FK → ID | 3DS trace event records |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `Billing.Trace` — stores trace events with type classification

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DictionaryTraceEventType | CLUSTERED PK | ID ASC | FILLFACTOR 95 |

---

## 8. Sample Queries

```sql
-- Get all trace event types
SELECT  ID, TraceEventType
FROM    Dictionary.TraceEventType WITH (NOLOCK)
ORDER BY ID;

-- Find trace events for a specific payment
SELECT  t.TraceID,
        tet.TraceEventType,
        t.CreatedDate
FROM    Billing.Trace t WITH (NOLOCK)
JOIN    Dictionary.TraceEventType tet WITH (NOLOCK)
        ON t.TraceEventTypeID = tet.ID
WHERE   t.PaymentID = @PaymentID
ORDER BY t.CreatedDate;

-- Count trace events by type
SELECT  tet.TraceEventType,
        COUNT(*) AS EventCount
FROM    Billing.Trace t WITH (NOLOCK)
JOIN    Dictionary.TraceEventType tet WITH (NOLOCK)
        ON t.TraceEventTypeID = tet.ID
GROUP BY tet.TraceEventType;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `TraceEventType`.

---

*Generated: 2026-03-14 | Quality: 9.0/10*
*Object: Dictionary.TraceEventType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.TraceEventType.sql*
