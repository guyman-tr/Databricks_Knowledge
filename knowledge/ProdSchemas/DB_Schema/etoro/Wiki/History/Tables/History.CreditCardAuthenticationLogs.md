# History.CreditCardAuthenticationLogs

> Operational log table that records every credit card 3D-Secure (or similar) authentication request and response, with encrypted message payloads, enabling audit and replay of card authentication events.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on ID, UNIQUE NC on CardAuthenticationID) |

---

## 1. Business Meaning

This table stores the raw request and response messages exchanged during credit card authentication flows (e.g., 3D-Secure, card verification challenges). Each row represents one complete authentication exchange: the message sent to the card authentication service and the reply received. The `CardAuthenticationID` links back to the authentication session identifier used by the billing system.

This table exists to maintain a full audit trail of card authentication activity for compliance, fraud investigation, and debugging billing flows. Payment processors require traceability of authentication exchanges, and this log provides the raw encrypted evidence. It serves as a durable record that can be consulted when a customer disputes a charge, when a card authorization fails unexpectedly, or when a compliance review requires proof of authentication steps.

Data flows into this table via `History.InsertCreditCardAuthenticationLog`, which is called by the billing/payment system after each authentication attempt. The procedure is idempotent: if a record for the same `CardAuthenticationID` already exists, the insert is skipped - preventing duplicates from retry logic. No updates or deletes are performed on this table.

---

## 2. Business Logic

### 2.1 Idempotent Insert Pattern

**What**: Inserts are de-duplicated by CardAuthenticationID to handle retry scenarios.

**Columns/Parameters Involved**: `CardAuthenticationID`, `ID`

**Rules**:
- `History.InsertCreditCardAuthenticationLog` checks whether a row with the given `CardAuthenticationID` already exists before inserting.
- If the record already exists, the procedure silently does nothing (no error, no duplicate).
- This handles cases where the billing system retries the logging call after a transient failure.
- `CardAuthenticationID` has a UNIQUE constraint to enforce this at the database level as a safety net.

**Diagram**:
```
Billing service completes card authentication
  -> Calls History.InsertCreditCardAuthenticationLog(@CardAuthenticationID, ...)
       IF EXISTS(CardAuthenticationID) -> skip (already logged)
       ELSE -> INSERT row
  -> Row persisted with encrypted request + response messages
```

### 2.2 Encrypted Message Storage

**What**: Request and response message payloads are stored in encrypted form.

**Columns/Parameters Involved**: `RequestMessage`, `ResponseMessage`

**Rules**:
- Both columns are `nvarchar(max)` and contain base64-encoded encrypted data based on observed values.
- Encryption is applied before the data reaches the database - the stored procedure accepts and stores whatever the caller provides.
- The database does not encrypt or decrypt these values - it is a pass-through store.
- These messages contain sensitive card authentication protocol data (e.g., 3DS challenge/response tokens) and are encrypted to protect cardholder data in compliance with PCI-DSS requirements.
- Either column may be NULL (ResponseMessage may be absent if the request failed before receiving a response).

---

## 3. Data Overview

| ID | CardAuthenticationID | DepotID | RequestDate | Meaning |
|----|---------------------|---------|-------------|---------|
| 5828 | 9079 | 92 | 2026-03-19 01:10:25 | Card authentication attempt: request sent at 01:10:25, encrypted challenge payload stored. DepotID 92 identifies the payment depot/provider handling this authentication. |
| 5829 | 9080 | 92 | 2026-03-19 01:10:36 | Another authentication attempt 11 seconds later - same depot, different CardAuthenticationID (sequential session IDs from billing system). |
| 5830 | 9083 | 92 | 2026-03-19 01:11:08 | Note gap in sequence (9081, 9082 may be in other systems or authentication types not logged here). |
| 5831 | 9089 | 92 | 2026-03-19 01:14:11 | High-frequency activity - multiple authentications per minute during peak billing load. |
| 5832 | 9090 | 92 | 2026-03-19 01:14:28 | Most recent authentication log in current dataset. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate primary key, auto-incremented. Uniquely identifies each log entry within this table. Not exposed externally - internal row identifier only. |
| 2 | CardAuthenticationID | nvarchar(50) | NO | - | CODE-BACKED | External identifier for the card authentication session, assigned by the billing/payment system. Stored as nvarchar to accommodate alphanumeric formats (currently observed as numeric strings). UNIQUE constraint prevents duplicate log entries for the same authentication session. Used as the idempotency key in History.InsertCreditCardAuthenticationLog. |
| 3 | DepotID | int | YES | - | NAME-INFERRED | Identifier of the payment depot or billing provider that initiated this authentication. Currently only one distinct value observed (92), suggesting this log covers a single payment channel. NULL-able to accommodate authentications where the depot context is unavailable. |
| 4 | RequestDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the card authentication request was made. Set by the calling billing service at the moment of the authentication attempt. Used to correlate authentication events with deposit/payment transactions by time. |
| 5 | RequestMessage | nvarchar(max) | YES | - | CODE-BACKED | The encrypted request payload sent to the card authentication service (e.g., 3D-Secure challenge request). Base64-encoded encrypted content based on observed data. NULL if no request message was captured (unlikely in normal flow). PCI-DSS sensitive - encrypted before storage. |
| 6 | ResponseMessage | nvarchar(max) | YES | - | CODE-BACKED | The encrypted response payload received from the card authentication service (e.g., 3D-Secure authentication result). Base64-encoded encrypted content based on observed data. NULL if the authentication failed before a response was received, or if the response was not captured. PCI-DSS sensitive - encrypted before storage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepotID | Billing depot/provider (cross-schema) | Implicit | References the billing depot that initiated the authentication. Exact FK target not defined in DDL. |
| CardAuthenticationID | External billing system authentication ID | Implicit | References the authentication session in the billing/payment service. Used to correlate with deposit records. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.InsertCreditCardAuthenticationLog | @CardAuthenticationID | Writer | The sole writer to this table - inserts one row per authentication event. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CreditCardAuthenticationLogs (table)
- Leaf node - no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.InsertCreditCardAuthenticationLog | Stored Procedure | Writes - idempotent insert of new authentication log entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CreditCardAuthenticationLogs | CLUSTERED (PK) | ID ASC | - | - | Active |
| UQ_CreditCardAuthenticationLogs_CardAuthId | NC UNIQUE | CardAuthenticationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CreditCardAuthenticationLogs | PRIMARY KEY | Uniqueness on ID (surrogate key) |
| UQ_CreditCardAuthenticationLogs_CardAuthId | UNIQUE | One log entry per CardAuthenticationID - prevents duplicate logging of the same authentication session |

**Storage**: TEXTIMAGE_ON [PRIMARY] - nvarchar(max) columns stored on PRIMARY filegroup.

---

## 8. Sample Queries

### 8.1 Recent authentication activity
```sql
SELECT TOP 20
    ID, CardAuthenticationID, DepotID, RequestDate,
    CASE WHEN ResponseMessage IS NULL THEN 'No Response' ELSE 'Has Response' END AS ResponseStatus
FROM [History].[CreditCardAuthenticationLogs] WITH (NOLOCK)
ORDER BY RequestDate DESC
```

### 8.2 Check if a specific authentication session was logged
```sql
SELECT ID, CardAuthenticationID, DepotID, RequestDate
FROM [History].[CreditCardAuthenticationLogs] WITH (NOLOCK)
WHERE CardAuthenticationID = '9090'
```

### 8.3 Authentication volume by day
```sql
SELECT
    CAST(RequestDate AS DATE) AS AuthDate,
    COUNT(*) AS AuthCount,
    COUNT(CASE WHEN ResponseMessage IS NULL THEN 1 END) AS NoResponseCount
FROM [History].[CreditCardAuthenticationLogs] WITH (NOLOCK)
GROUP BY CAST(RequestDate AS DATE)
ORDER BY AuthDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 8.3/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CreditCardAuthenticationLogs | Type: Table | Source: etoro/etoro/History/Tables/History.CreditCardAuthenticationLogs.sql*
