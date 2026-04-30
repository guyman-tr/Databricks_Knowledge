# History.InsertCreditCardAuthenticationLog

> Idempotent writer for credit card authentication event logs - inserts a new authentication request/response record only if the CardAuthenticationID has not been previously recorded, preventing duplicates from billing system retries.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CardAuthenticationID - the unique authentication session identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.InsertCreditCardAuthenticationLog` is the sole writer for `History.CreditCardAuthenticationLogs`, the audit log for credit card 3D-Secure (and similar) authentication exchanges. Called by the billing/payment system after each card authentication attempt, it stores the authentication session ID, the request and response payloads, and the timestamp - providing a durable record for compliance, fraud investigation, and dispute resolution.

The idempotent pattern (IF NOT EXISTS before INSERT) is the defining characteristic of this procedure. Payment systems often retry API calls on transient failures. If the billing service retried logging the same authentication session twice, the second call silently exits without inserting a duplicate. The UNIQUE constraint on `CardAuthenticationID` in the target table provides a database-level safety net for the same condition.

Data flows: billing/payment service calls this procedure after each authentication attempt -> record stored in History.CreditCardAuthenticationLogs -> compliance/fraud teams can query the full authentication trail by CardAuthenticationID.

---

## 2. Business Logic

### 2.1 Idempotent Insert Pattern

**What**: Prevents duplicate authentication log entries from retry scenarios.

**Columns/Parameters Involved**: `@CardAuthenticationID`

**Rules**:
- IF NOT EXISTS (SELECT 1 ... WHERE CardAuthenticationID = @CardAuthenticationID) -> only INSERT if not already present
- If the record already exists: procedure exits silently (no error raised, no duplicate inserted)
- The underlying table also has a UNIQUE NC index on CardAuthenticationID as a physical safety net
- No update path exists - authentication records are write-once, immutable after insertion
- Handles all retry scenarios: network timeouts, application crashes, duplicate calls from the billing system

**Diagram**:
```
Billing/Payment System
        |
        v
History.InsertCreditCardAuthenticationLog(@CardAuthenticationID, ...)
        |
        v
IF NOT EXISTS in History.CreditCardAuthenticationLogs
        |
  YES (new) --> INSERT row
        |
  NO (exists) --> Silent exit, no duplicate
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CardAuthenticationID | NVARCHAR(50) | NO | - | VERIFIED | Unique identifier for the authentication session from the card authentication service (e.g., 3DS session token or external transaction reference). Used as the idempotency key - if a record with this ID already exists, the insert is skipped. Maps to History.CreditCardAuthenticationLogs.CardAuthenticationID (UNIQUE constraint). |
| 2 | @DepotID | INT | YES | NULL | CODE-BACKED | The depot/payment method identifier associated with this authentication. Links the authentication event to a specific payment instrument in the billing system. NULL if not applicable or not provided. |
| 3 | @RequestDate | DATETIME | NO | - | VERIFIED | Timestamp of the authentication request. Recorded to establish when the authentication event occurred for audit and timeline purposes. |
| 4 | @RequestMessage | NVARCHAR(MAX) | YES | NULL | VERIFIED | The raw request payload sent to the card authentication service. May contain encrypted 3DS authentication request data. NULL if the request content is not captured. Stored for full audit replay capability. |
| 5 | @ResponseMessage | NVARCHAR(MAX) | YES | NULL | VERIFIED | The raw response payload received from the card authentication service. May contain authentication outcome, challenge data, or error details. NULL if no response was received. Stored for dispute resolution and compliance review. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.CreditCardAuthenticationLogs | Writes (idempotent INSERT) | Sole writer for the credit card authentication audit log |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository. Called by the external billing/payment service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InsertCreditCardAuthenticationLog (procedure)
└── History.CreditCardAuthenticationLogs (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CreditCardAuthenticationLogs | Table | IF NOT EXISTS check + idempotent INSERT |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository. Called by the external billing service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. Note: `SET NOCOUNT ON` applied. No transaction wrapper - single INSERT operation.

---

## 8. Sample Queries

### 8.1 Insert a new credit card authentication log entry

```sql
EXEC History.InsertCreditCardAuthenticationLog
    @CardAuthenticationID = 'AUTH-20240101-ABC123',
    @DepotID = 456,
    @RequestDate = '2024-01-01 12:00:00',
    @RequestMessage = N'<3ds:AuthRequest>...</3ds:AuthRequest>',
    @ResponseMessage = N'<3ds:AuthResponse>...</3ds:AuthResponse>'
```

### 8.2 Check if an authentication record already exists before insert

```sql
SELECT ID, CardAuthenticationID, DepotID, RequestDate
FROM History.CreditCardAuthenticationLogs WITH (NOLOCK)
WHERE CardAuthenticationID = 'AUTH-20240101-ABC123'
```

### 8.3 Find recent authentication events for a depot

```sql
SELECT TOP 20
    ID,
    CardAuthenticationID,
    DepotID,
    RequestDate
FROM History.CreditCardAuthenticationLogs WITH (NOLOCK)
WHERE DepotID = 456
ORDER BY RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring investment Phase 1.2 - 3DS support - Operations support (BRS)](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13473284120) | Confluence | Found via search (updated 2025-10-28) - likely contains business requirements for 3DS authentication logging in recurring investments |
| [HLD Recurring Payments Zero Auth](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/13281656921) | Confluence | Found via search (updated 2025-11-17) - HLD for zero-authorization in recurring payments, related to card authentication flows |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 2 Confluence found (inaccessible) + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.InsertCreditCardAuthenticationLog | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.InsertCreditCardAuthenticationLog.sql*
