# MoneyBus.TransactionLogGet

> Retrieves a single transaction log entry by its ID from History.TransactionsLog, returning the full request/response details for debugging and audit.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from History.TransactionsLog by PK |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.TransactionLogGet retrieves a single transaction log entry from History.TransactionsLog. Each log entry records an API call made during transaction processing - the request sent, the response received, the URL called, timing, and a correlation ID for distributed tracing. This is used for debugging transaction failures and auditing the communication between the MoneyBus service and external payment providers.

The procedure reads from the History schema (cross-schema dependency) which stores operational logs separate from the core MoneyBus transactional tables.

---

## 2. Business Logic

No complex business logic. Simple PK lookup on History.TransactionsLog.TransactionLogID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | The TransactionLogID to look up in History.TransactionsLog. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT target) | History.TransactionsLog | Reader | Reads a single log entry with request/response details |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.TransactionLogGet (procedure)
└── History.TransactionsLog (table) [SELECT FROM - cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.TransactionsLog | Table (cross-schema) | SELECT FROM - reads log entry by PK |

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

### 8.1 Get a transaction log entry
```sql
EXEC MoneyBus.TransactionLogGet @ID = 1000;
```

### 8.2 Find logs for a specific transaction
```sql
SELECT * FROM History.TransactionsLog WITH (NOLOCK) WHERE TransactionID = 7747200 ORDER BY RequestDate;
```

### 8.3 Direct equivalent with response timing
```sql
SELECT TransactionLogID, TransactionActionID, TransactionID,
       RequestDate, ResponseDate,
       DATEDIFF(MILLISECOND, RequestDate, ResponseDate) AS ResponseTimeMs,
       Url, CorrelationID
FROM History.TransactionsLog WITH (NOLOCK)
WHERE TransactionLogID = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.TransactionLogGet | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.TransactionLogGet.sql*
