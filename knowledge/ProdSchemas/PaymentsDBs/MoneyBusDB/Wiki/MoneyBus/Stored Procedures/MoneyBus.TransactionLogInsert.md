# MoneyBus.TransactionLogInsert

> Inserts a new transaction log entry into History.TransactionsLog, recording an API request/response pair made during transaction processing, returning the auto-generated log ID.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT @TransactionLogID - returns new TransactionsLog.TransactionLogID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionLogInsert records each API call made by the transaction execution pipeline. Every time the service calls an external payment provider (hold, debit, credit operations), it logs the request message, response message, URL, timing, and correlation ID. This creates a comprehensive audit trail of all external communications during transaction processing.

The procedure writes to History.TransactionsLog (cross-schema). The @ResponseDate defaults to GETUTCDATE() if not provided, accommodating the common pattern where the response timestamp is captured at insert time. The @TransactionLogID OUTPUT parameter returns the new log entry ID for reference.

---

## 2. Business Logic

No complex business logic. This is a direct INSERT with optional default for ResponseDate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionLogID | int OUTPUT | NO | - | CODE-BACKED | Returns the auto-generated IDENTITY value of the new log entry. |
| 2 | @TransactionActionID | int | NO | - | CODE-BACKED | Identifies the type of action being logged (e.g., hold, debit, credit). Maps to an action type enum in the application. |
| 3 | @TransactionID | bigint | YES | NULL | CODE-BACKED | The transaction this log entry relates to. Nullable for log entries that occur before a transaction is created. |
| 4 | @RequestDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the API request was sent. Required. |
| 5 | @ResponseDate | datetime | YES | GETUTCDATE() | CODE-BACKED | UTC timestamp when the API response was received. Defaults to GETUTCDATE() if not provided. |
| 6 | @RequestMessage | nvarchar(2000) | YES | NULL | CODE-BACKED | The API request payload sent to the external provider. Truncated to 2000 chars. |
| 7 | @ResponseMessage | nvarchar(2000) | YES | NULL | CODE-BACKED | The API response payload received from the external provider. Truncated to 2000 chars. |
| 8 | @CorrelationID | nvarchar(200) | YES | NULL | CODE-BACKED | Distributed tracing correlation ID for end-to-end request tracking across services. |
| 9 | @Url | nvarchar(500) | YES | NULL | CODE-BACKED | The URL of the external API endpoint that was called. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (INSERT target) | History.TransactionsLog | Writer | Creates new API log entry |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionLogInsert (procedure)
└── History.TransactionsLog (table) [INSERT INTO - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.TransactionsLog | Table (cross-schema) | INSERT INTO - creates log entries |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Log a provider API call
```sql
DECLARE @LogID INT;
EXEC MoneyBus.TransactionLogInsert
    @TransactionLogID = @LogID OUTPUT,
    @TransactionActionID = 1,
    @TransactionID = 7747200,
    @RequestDate = '2026-04-15 13:00:00',
    @RequestMessage = '{"action":"hold","amount":500}',
    @ResponseMessage = '{"status":"approved","ref":"HOLD-123"}',
    @CorrelationID = 'trace-xyz-001',
    @Url = 'https://provider.example.com/api/hold';
SELECT @LogID AS NewLogID;
```

### 8.2 Log with auto response date
```sql
DECLARE @LogID INT;
EXEC MoneyBus.TransactionLogInsert
    @TransactionLogID = @LogID OUTPUT,
    @TransactionActionID = 2,
    @TransactionID = 7747200,
    @RequestDate = '2026-04-15 13:00:01';
```

### 8.3 Find recent logs for a transaction
```sql
SELECT * FROM History.TransactionsLog WITH (NOLOCK)
WHERE TransactionID = 7747200 ORDER BY RequestDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionLogInsert | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionLogInsert.sql*
