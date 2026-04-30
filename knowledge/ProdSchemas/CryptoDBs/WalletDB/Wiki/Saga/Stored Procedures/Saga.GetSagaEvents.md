# Saga.GetSagaEvents

> Retrieves all operational event records for a specific saga run by SagaKey, for post-mortem debugging and operational analysis.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set of saga events |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the read interface for the saga event log. Given a SagaKey, it returns all operational events recorded by `Saga.AddSagaEvent` during that saga's execution. Operations teams use this to investigate what happened during a saga's lifecycle beyond the structured status and step records.

The procedure returns all 8 columns from `Saga.SagaEvents` without any filtering or ordering beyond the SagaKey match. Since the table uses an IDENTITY PK, results are naturally ordered by insertion time.

---

## 2. Business Logic

No complex business logic. Simple SELECT with single-column WHERE filter.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Identifies the saga run whose events should be retrieved. Matches `Saga.SagaEvents.SagaKey`. |
| 2-9 | (output columns) | - | - | - | CODE-BACKED | Id, SagaKey, SagaName, CorrelationId, EventType, EventDescription, JsonDetails, Created from Saga.SagaEvents. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaEvents | SELECT FROM | Reads all events for the specified saga |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaEvents (procedure)
└── Saga.SagaEvents (table) [SELECT FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaEvents | Table | SELECT FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No NOLOCK hint used (unlike most other Saga SPs).

---

## 8. Sample Queries

### 8.1 Get events for a specific saga
```sql
EXEC Saga.GetSagaEvents @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28'
```

### 8.2 N/A
N/A.

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaEvents | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaEvents.sql*
