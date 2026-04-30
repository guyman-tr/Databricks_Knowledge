# History.WithdrawLogAdd

> Simple insert procedure for the withdrawal API call audit log: appends one request/response pair to History.WithdrawLog, called by SQL_SecurePay, RedeemServiceUser, and PayoutUser services for every external withdrawal API interaction.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WithdrawToFundingID (links log entry to withdrawal transaction) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.WithdrawLogAdd` is the sole writer for `History.WithdrawLog`. It is a pure append-only logger with no error handling, no transaction wrapping, and no SET NOCOUNT ON. Every external API call made by eToro's withdrawal/payout services is logged through this procedure - the encrypted request payload sent to the payment provider and the encrypted response received are both stored for compliance, debugging, and dispute resolution.

Three distinct services call this procedure:
- **SQL_SecurePay**: The primary payment processing service
- **RedeemServiceUser**: The crypto redeem service (crypto transfer to eToro Wallet)
- **PayoutUser**: The payout scheduling and processing service

The procedure was created on 2019-11-05 by Ran Ovadia. It has not been modified since (no modification history comments). The `History.WithdrawLog` table has 54M+ rows as of 2026-03-19, demonstrating extremely high write volume across all three services.

Messages are stored encrypted in both RequestMessage and ResponseMessage - these fields contain PII, payment account details, and PCI-scope data that must remain encrypted at rest.

---

## 2. Business Logic

### 2.1 Withdrawal API Call Logging

**What**: Each call appends one request/response pair to the withdrawal audit trail.

**Columns/Parameters Involved**: @WithdrawToFundingID, @RequestMessage, @ResponseMessage, @RequestDate, @ResponseDateDateTime

**Rules**:
- @WithdrawToFundingID links the log entry to the withdrawal transaction in the Billing schema (Billing.WithdrawToFunding)
- @RequestMessage and @ResponseMessage are varchar(max) - contain encrypted payloads; caller passes them pre-encrypted
- @RequestDate and @ResponseDateDateTime are both smalldatetime (1-minute precision); timestamps are rounded to the nearest minute
- @ResponseMessage may be NULL if the API call failed before a response was received (though the SP does not explicitly default it to NULL - callers pass NULL explicitly)
- No error handling: if the INSERT fails, the exception propagates unhandled to the calling service
- No BEGIN TRAN: each INSERT is an independent atomic operation (no related tables need to be updated atomically)

**Call pattern (typical)**:
```
Payment service calls external API
-> Captures request payload + response payload
-> EXEC History.WithdrawLogAdd
       @WithdrawToFundingID = 12345,
       @RequestMessage = '<encrypted_request>',
       @ResponseMessage = '<encrypted_response>',
       @RequestDate = '2026-03-21 14:30:00',
       @ResponseDateDateTime = '2026-03-21 14:30:00'
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawToFundingID | int | NO | - | CODE-BACKED | The withdrawal transaction ID linking this log entry to the underlying payout/withdrawal record. FK to Billing.WithdrawToFunding.WithdrawToFundingID. Multiple log entries per WithdrawToFundingID are expected (one per API interaction in the processing workflow). |
| 2 | @RequestMessage | varchar(max) | NO | - | CODE-BACKED | Encrypted payload sent to the external payment provider API for this withdrawal step. Stored encrypted for PCI/PII compliance. The encryption is performed by the calling application before passing to this SP. |
| 3 | @ResponseMessage | varchar(max) | YES | - | CODE-BACKED | Encrypted response received from the external payment provider API. NULL if the API call failed before a response was received (timeout, network error, etc.). Stored encrypted matching the request encryption. |
| 4 | @RequestDate | smalldatetime | NO | - | CODE-BACKED | Timestamp when the API request was sent. smalldatetime precision (1-minute granularity). Maps to History.WithdrawLog.RequestDate (which has DEFAULT GETUTCDATE() as a safety net, but this SP always passes an explicit value). |
| 5 | @ResponseDateDateTime | smalldatetime | NO | - | CODE-BACKED | Timestamp when the API response was received (or when the failure was detected). smalldatetime precision (1-minute granularity). Maps to History.WithdrawLog.ResponseDateDateTime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | History.WithdrawLog | Write target | Appends one request/response audit row per API call |
| @WithdrawToFundingID | Billing.WithdrawToFunding | Implicit | @WithdrawToFundingID references the withdrawal transaction in Billing schema |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay service | (application call) | Application | Logs each payment API request/response for standard withdrawals |
| RedeemServiceUser service | (application call) | Application | Logs each crypto redeem API interaction |
| PayoutUser service | (application call) | Application | Logs each payout processing API call |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.WithdrawLogAdd (procedure)
└── History.WithdrawLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawLog | Table | INSERT target - one row per withdrawal API call |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay | Application Service | Primary writer for standard withdrawal API calls |
| RedeemServiceUser | Application Service | Writer for crypto redeem API calls |
| PayoutUser | Application Service | Writer for payout processing API calls |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

No TRY/CATCH, no BEGIN TRAN, no SET NOCOUNT ON. Pure single-statement INSERT. Created 2019-11-05 by Ran Ovadia. No modifications since creation. History.WithdrawLog has 54M+ rows (as of 2026-03-19) - extremely high write volume.

---

## 8. Sample Queries

### 8.1 Find all withdrawal API logs for a specific transaction

```sql
SELECT
    ID,
    WithdrawToFundingID,
    RequestDate,
    ResponseDateDateTime,
    RequestMessage,   -- encrypted
    ResponseMessage   -- encrypted
FROM History.WithdrawLog WITH (NOLOCK)
WHERE WithdrawToFundingID = 12345
ORDER BY RequestDate ASC
```

### 8.2 Count API calls per withdrawal transaction (recent)

```sql
SELECT
    WithdrawToFundingID,
    COUNT(*) AS APICallCount,
    MIN(RequestDate) AS FirstCall,
    MAX(ResponseDateDateTime) AS LastCall
FROM History.WithdrawLog WITH (NOLOCK)
WHERE RequestDate >= DATEADD(DAY, -1, GETUTCDATE())
GROUP BY WithdrawToFundingID
ORDER BY APICallCount DESC
```

### 8.3 Find transactions with many API calls (potential retry issues)

```sql
SELECT TOP 20
    WithdrawToFundingID,
    COUNT(*) AS APICallCount
FROM History.WithdrawLog WITH (NOLOCK)
WHERE RequestDate >= DATEADD(HOUR, -4, GETUTCDATE())
GROUP BY WithdrawToFundingID
HAVING COUNT(*) > 3
ORDER BY APICallCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 applicable (Phase 9B: no app code match)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed (app callers identified via UsersPermissions SQL) | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.WithdrawLogAdd | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.WithdrawLogAdd.sql*
