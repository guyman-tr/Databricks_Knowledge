# Saga.SagaEvents

> Audit log table recording significant operational events during saga execution, enabling post-mortem debugging and operational monitoring of distributed transactions.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table stores operational events that occur during saga execution. While `Saga.SagaRunStatuses` tracks formal state transitions and `Saga.SagaSteps` tracks step-level execution, this table captures freeform events that provide additional diagnostic context - warnings, errors, decision points, and other notable occurrences that don't fit neatly into the structured status/step model.

Events provide the detailed "story" of what happened during a saga's execution, complementing the structured status history. When a saga fails or behaves unexpectedly, operations teams use `Saga.GetSagaEvents` to retrieve all events for a given SagaKey to understand the sequence of decisions and issues that led to the outcome.

Events are written by `Saga.AddSagaEvent`, which accepts a SagaKey, event type, description, and optional JSON details. They are read by `Saga.GetSagaEvents` which retrieves all events for a specific saga run. The table is currently empty (0 rows), suggesting event logging may be optional or not actively utilized in the current deployment configuration.

---

## 2. Business Logic

### 2.1 Event Logging Model

**What**: Freeform event capture linked to a saga execution via SagaKey.

**Columns/Parameters Involved**: `SagaKey`, `SagaName`, `CorrelationId`, `EventType`, `EventDescription`, `JsonDetails`

**Rules**:
- Events are linked to saga runs via SagaKey (matches `Saga.SagaRuns.SagaKey`)
- SagaName and CorrelationId are denormalized from SagaRuns for independent queryability
- EventType categorizes the event (nvarchar(32) - short classification code)
- EventDescription provides a human-readable summary (nvarchar(128))
- JsonDetails contains structured context data (nvarchar(1024) - limited to prevent oversized entries)
- Events are append-only - once written, they are never updated or deleted

---

## 3. Data Overview

Table is currently empty (0 rows). Event logging appears to be an optional capability that is not actively generating records in the current deployment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY | CODE-BACKED | Auto-incrementing primary key. Provides chronological ordering of events across all saga runs. |
| 2 | SagaKey | uniqueidentifier | NO | - | VERIFIED | Links this event to a specific saga run via `Saga.SagaRuns.SagaKey`. Used by `Saga.GetSagaEvents` to retrieve all events for a saga. |
| 3 | SagaName | varchar(256) | NO | - | CODE-BACKED | Saga type name, denormalized from `Saga.SagaRuns.SagaName`. Allows event queries without joining to SagaRuns. Expected values: `ExternalReceiveTransactionSaga`, `TravelRuleMessageReceiveSentSaga`, etc. |
| 4 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Business correlation GUID, denormalized from `Saga.SagaRuns.CorrelationId`. Allows correlating events to the originating business request without joining to SagaRuns. |
| 5 | EventType | nvarchar(32) | NO | - | CODE-BACKED | Short classification code for the event category (e.g., warning, error, decision, retry). Limited to 32 characters for consistent categorization and efficient filtering. |
| 6 | EventDescription | nvarchar(128) | YES | - | CODE-BACKED | Human-readable summary of what occurred. Intended for operational dashboards and quick scanning. Limited to 128 characters; detailed context goes in JsonDetails. |
| 7 | JsonDetails | nvarchar(1024) | YES | - | CODE-BACKED | Structured JSON payload with event context data. Capped at 1024 characters to prevent oversized entries. Contains diagnostic details relevant to the specific event type. Note: the SP parameter is nvarchar(128) which is more restrictive than the column's 1024 - effective limit is 128 chars when using `Saga.AddSagaEvent`. |
| 8 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when the event was recorded. Passed as a parameter by the calling application (not set server-side). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaKey | Saga.SagaRuns | Implicit FK (via SagaKey) | Links event to the saga run it belongs to |

### 5.2 Referenced By (other objects point to this)

No inbound references from other tables.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.SagaEvents (table)
└── Saga.SagaRuns (table) [implicit FK - SagaKey]
    └── Saga.SagaStatusTypes (table) [implicit FK - SagaStatusTypeId]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | Implicit FK - SagaKey references the parent saga run |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Saga.AddSagaEvent | Stored Procedure | WRITER - inserts event records |
| Saga.GetSagaEvents | Stored Procedure | READER - retrieves all events for a given SagaKey |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaEvents | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key. Notable: no index on SagaKey despite being the primary query filter in `Saga.GetSagaEvents`. If the table accumulates significant data, a NC index on SagaKey would improve query performance.

---

## 8. Sample Queries

### 8.1 Get all events for a saga run
```sql
SELECT Id, SagaKey, SagaName, CorrelationId, EventType, EventDescription, JsonDetails, Created
FROM Saga.SagaEvents WITH (NOLOCK)
WHERE SagaKey = @SagaKey
ORDER BY Id ASC
```

### 8.2 Recent events across all sagas
```sql
SELECT TOP 20 Id, SagaKey, SagaName, EventType, EventDescription, Created
FROM Saga.SagaEvents WITH (NOLOCK)
ORDER BY Id DESC
```

### 8.3 Events with saga run context
```sql
SELECT se.Id, se.EventType, se.EventDescription, se.Created AS EventTime,
       sr.SagaName, sst.Name AS SagaStatus, sr.Created AS SagaStarted
FROM Saga.SagaEvents se WITH (NOLOCK)
JOIN Saga.SagaRuns sr WITH (NOLOCK) ON se.SagaKey = sr.SagaKey
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
WHERE se.SagaKey = @SagaKey
ORDER BY se.Id ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.SagaEvents | Type: Table | Source: WalletDB/Saga/Tables/Saga.SagaEvents.sql*
