# Saga.GetSagaRun

> Retrieves a single saga run by SagaKey with all its step details, providing the complete saga state for resumption or investigation.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: result set (saga run + steps) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the complete state of a single saga run identified by its SagaKey GUID. It returns the saga's metadata (name, status, correlation ID) joined with all step records (step index, request/response, step status). This is the primary "get saga" operation used by the saga coordinator to load saga state when resuming processing after an interruption.

The LEFT JOIN to SagaSteps ensures the saga record is returned even if no steps have been created yet (e.g., immediately after saga creation). Results are ordered by StepIndex so steps appear in pipeline execution order.

---

## 2. Business Logic

No complex business logic. Single-saga lookup by SagaKey with step JOIN.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Technical saga instance GUID. Matches `Saga.SagaRuns.SagaKey` (UNIQUE indexed). |
| 2-12 | (output columns) | - | - | - | CODE-BACKED | Id, SagaName, SagaKey, Created, Status (SagaStatusTypeId), CorrelationId, StepIndex, Request, Response, StepCreated, StepStatus (StepStatusTypeId). Note: does NOT include AdditionalData (unlike some other Get* SPs). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT FROM WHERE | Reads the specific saga run |
| - | Saga.SagaSteps | LEFT JOIN | Reads all steps for the saga |

### 5.2 Referenced By (other objects point to this)

No callers found within the schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRun (procedure)
├── Saga.SagaRuns (table) [SELECT FROM]
└── Saga.SagaSteps (table) [LEFT JOIN]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT FROM |
| Saga.SagaSteps | Table | LEFT JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

Uses NOLOCK on both tables. SET NOCOUNT ON.

---

## 8. Sample Queries

### 8.1 Get a saga by key
```sql
EXEC Saga.GetSagaRun @SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28'
```

### 8.2 Equivalent query with status name resolution
```sql
SELECT sr.Id, sr.SagaName, sr.SagaKey, sr.Created, sst.Name AS Status,
       ss.StepIndex, ssst.Name AS StepStatus, ss.Created AS StepCreated
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
JOIN Saga.SagaStatusTypes sst WITH (NOLOCK) ON sr.SagaStatusTypeId = sst.Id
LEFT JOIN Saga.StepStatusTypes ssst WITH (NOLOCK) ON ss.StepStatusTypeId = ssst.Id
WHERE sr.SagaKey = 'EBEAAEE2-EF39-480A-91BF-489ED0CF6D28'
ORDER BY ss.StepIndex
```

### 8.3 N/A
N/A.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRun | Type: Stored Procedure | Source: WalletDB/Saga/Stored Procedures/Saga.GetSagaRun.sql*
