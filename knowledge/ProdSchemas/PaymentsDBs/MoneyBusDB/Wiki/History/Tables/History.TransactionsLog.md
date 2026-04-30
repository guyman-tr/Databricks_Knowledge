# History.TransactionsLog

> Audit log of external payment provider API calls made during the money transfer pipeline, capturing encrypted request/response payloads for each hold, debit, credit, and validation step.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | TransactionLogID (int, IDENTITY) |
| **Partition** | No |
| **Indexes** | 1 active (PK_TransactionsLog_New - CLUSTERED on TransactionLogID) |

---

## 1. Business Meaning

History.TransactionsLog records every external payment provider API call made by the MoneyBus transaction execution service. Each row captures a single request-response exchange with the external banking API (e.g., Gatsby Financial), including the encrypted request/response payloads, the URL endpoint, and the correlation context. This is not a temporal history table - it is a traditional append-only audit log with its own identity column.

This table exists for compliance, debugging, and dispute resolution. When a transaction fails at the hold, debit, or credit step, the log provides the exact encrypted request that was sent and the provider's encrypted response. This is essential for investigating payment provider disputes, verifying that the correct parameters were sent, and auditing the timing of each API call. Without this log, the system would only know THAT a step failed (from the transaction status) but not WHAT was communicated with the provider.

Data is written to this table by `MoneyBus.TransactionLogInsert`, called by the transaction execution service after each external API interaction. The procedure receives the action type, transaction ID, encrypted request/response messages, and the provider URL. Data is read by `MoneyBus.TransactionLogGet` for individual log entry retrieval. The request and response messages are encrypted before storage, so raw payloads containing sensitive financial data are not stored in plaintext.

---

## 2. Business Logic

### 2.1 Transaction Action Types (Provider API Operations)

**What**: The TransactionActionID classifies which payment provider API operation was performed. The values map to specific external API endpoints.

**Columns/Parameters Involved**: `TransactionActionID`, `Url`, `TransactionID`

**Rules**:
- TransactionActionID=3 corresponds to debitValidate (URL: .../action/debitValidate) - pre-debit validation
- TransactionActionID=4 corresponds to creditValidate (URL: .../action/creditValidate) - pre-credit validation
- TransactionActionID=5 corresponds to holdMoney (URL: .../action/holdMoney) - place a hold on funds
- TransactionActionID=6 corresponds to moneyTransferDebit (URL: .../action/moneyTransferDebit) - execute the debit
- No database dictionary table exists for TransactionActionID - values are application-defined

### 2.2 Sentinel Transaction ID for Validation Calls

**What**: Validation API calls (debitValidate, creditValidate) use a sentinel TransactionID of 9999999999 because they occur before a real transaction is created or when validating without a specific transaction context.

**Columns/Parameters Involved**: `TransactionID`, `TransactionActionID`

**Rules**:
- TransactionID=9999999999 indicates a validation-only call (no real transaction yet)
- TransactionID with a real value (e.g., 399080) indicates an execution call (holdMoney, moneyTransferDebit) for a specific transaction
- Multiple log entries share the same CorrelationID when they belong to the same transaction flow (validate -> hold -> debit sequence)

### 2.3 Encrypted Payloads

**What**: Request and response messages are encrypted before storage to protect sensitive financial data.

**Columns/Parameters Involved**: `RequestMessage`, `ResponseMessage`

**Rules**:
- RequestMessage contains the encrypted request body sent to the payment provider (base64-encoded)
- ResponseMessage contains the encrypted provider response (base64-encoded)
- Encryption happens at the application layer before calling TransactionLogInsert
- Decryption requires application-level keys - the database stores only ciphertext

---

## 3. Data Overview

| TransactionLogID | TransactionActionID | TransactionID | Url (endpoint) | Meaning |
|------------------|---------------------|---------------|----------------|---------|
| 157953143 | 3 | 9999999999 | .../debitValidate | Pre-debit validation call using sentinel ID - checking if the debit side can process the transfer before creating the actual transaction |
| 157953144 | 5 | 399080 | .../holdMoney | Hold operation for real transaction #399080 - requesting the external bank to freeze funds before debiting |
| 157953145 | 6 | 399080 | .../moneyTransferDebit | Debit execution for transaction #399080 - instructing the external bank to actually debit the held funds |
| 157953140 | 4 | 9999999999 | .../creditValidate | Pre-credit validation call using sentinel ID - checking if the credit side can accept the incoming funds |
| 157953149 | 4 | 9999999999 | .../creditValidate | Another credit validation call with a different CorrelationID - each transaction flow generates its own validation entries |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TransactionLogID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key for each log entry. Generated by SCOPE_IDENTITY() in TransactionLogInsert and returned as an OUTPUT parameter. |
| 2 | TransactionActionID | int | NO | - | CODE-BACKED | Payment provider API operation type: 3=debitValidate, 4=creditValidate, 5=holdMoney, 6=moneyTransferDebit (inferred from URL correlation). Application-defined enum with no database dictionary table. Additional action types may exist for other operations (credit execution, hold release, etc.). |
| 3 | TransactionID | bigint | YES | - | CODE-BACKED | References the MoneyBus.Transactions.ID for execution calls (holdMoney, moneyTransferDebit). Set to sentinel value 9999999999 for validation-only calls (debitValidate, creditValidate) that occur before a real transaction exists or outside a specific transaction context. |
| 4 | RequestDate | datetime | NO | - | CODE-BACKED | Timestamp when the request was sent to the payment provider. Provided by the application at call time. |
| 5 | ResponseDate | datetime | YES | - | CODE-BACKED | Timestamp when the response was received from the payment provider. Defaults to GETUTCDATE() in TransactionLogInsert if not explicitly provided. The difference between RequestDate and ResponseDate indicates provider response latency. |
| 6 | RequestMessage | nvarchar(2000) | NO | - | CODE-BACKED | Encrypted (base64-encoded) request payload sent to the payment provider. Contains sensitive financial data (account details, amounts, references) encrypted at the application layer before storage. |
| 7 | ResponseMessage | nvarchar(2000) | YES | - | CODE-BACKED | Encrypted (base64-encoded) response payload received from the payment provider. Contains the provider's result (approval, decline, error details) encrypted at the application layer. |
| 8 | CorrelationID | nvarchar(200) | YES | - | CODE-BACKED | Distributed tracing identifier (GUID) linking all API calls that belong to the same transaction flow. A single deposit flow (validate -> hold -> debit -> credit) shares one CorrelationID across multiple log entries. |
| 9 | Url | nvarchar(500) | YES | - | CODE-BACKED | Full URL of the external payment provider API endpoint called. Reveals the operation type (e.g., creditValidate, holdMoney, moneyTransferDebit) and the provider (e.g., Gatsby Financial banking API v3). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionID | MoneyBus.Transactions | Implicit FK | Links log entries to the transaction being processed. Sentinel value 9999999999 used for validation-only calls. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.TransactionLogInsert | N/A | WRITER | Inserts log entries after each external API call |
| MoneyBus.TransactionLogGet | N/A | READER | Retrieves individual log entries by TransactionLogID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.TransactionsLog (table)
  (no code-level dependencies - leaf node)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.TransactionLogInsert | Stored Procedure | WRITER - inserts log entries after each external payment provider API call |
| MoneyBus.TransactionLogGet | Stored Procedure | READER - retrieves individual log entries by TransactionLogID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionsLog_New | CLUSTERED PK | TransactionLogID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Retrieve all API calls for a specific transaction
```sql
SELECT TransactionLogID, TransactionActionID, TransactionID,
       RequestDate, ResponseDate, Url
FROM History.TransactionsLog WITH (NOLOCK)
WHERE TransactionID = 399080
ORDER BY RequestDate ASC
```

### 8.2 Find all API calls for a correlation flow
```sql
SELECT TransactionLogID, TransactionActionID, TransactionID,
       RequestDate, ResponseDate, Url
FROM History.TransactionsLog WITH (NOLOCK)
WHERE CorrelationID = '1f250a17-a272-434b-a6f9-c9048d9701c7'
ORDER BY RequestDate ASC
```

### 8.3 Analyze provider response latency by action type
```sql
SELECT TransactionActionID, Url,
       DATEDIFF(MILLISECOND, RequestDate, ResponseDate) AS LatencyMs
FROM History.TransactionsLog WITH (NOLOCK)
WHERE TransactionID <> 9999999999  -- exclude validation calls
  AND ResponseDate IS NOT NULL
ORDER BY RequestDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Hold and Release - LLD | Confluence | Confirms the hold/release API pattern (holdMoney endpoint) used in the transaction pipeline |
| Phase 1.5 PRD: MIMO Two Ways In / Two Ways Out | Confluence | Establishes the MIMO system context and the validate-hold-debit-credit flow that this table logs |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.6/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.TransactionsLog | Type: Table | Source: MoneyBusDB/History/Tables/History.TransactionsLog.sql*
