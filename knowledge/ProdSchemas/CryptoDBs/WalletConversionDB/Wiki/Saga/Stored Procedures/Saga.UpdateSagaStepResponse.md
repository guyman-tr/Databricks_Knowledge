# Saga.UpdateSagaStepResponse

> Updates the Response payload of an existing saga step, used when async step operations complete and the result needs to be recorded for pipeline chaining.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: UpdateStatus BIT (1=updated, 0=not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UpdateSagaStepResponse updates the Response column of a specific saga step identified by SagaKey and StepIndex. This is used when a step's operation is asynchronous - the step is initially created with a Request but no Response, and when the async result arrives, this procedure records the Response payload so subsequent steps can use it as input.

Without this procedure, the saga pipeline chaining pattern would break for async operations. Step N's Response feeds into Step N+1's Request, so recording the async result is essential for the saga to progress.

---

## 2. Business Logic

### 2.1 Step Lookup via SagaKey + StepIndex

**What**: Finds the step using a two-hop lookup: SagaKey -> SagaRuns.Id -> SagaSteps.SagaRunId + StepIndex.

**Columns/Parameters Involved**: `@SagaKey`, `@StepIndex`, `@Response`

**Rules**:
- First finds SagaRuns.Id via subquery: `SELECT Id FROM SagaRuns WHERE SagaKey = @SagaKey`
- Then UPDATEs SagaSteps SET Response = @Response WHERE SagaRunId = (subquery) AND StepIndex = @StepIndex
- Returns UpdateStatus BIT: 1 if step found and updated, 0 if SagaKey or StepIndex not found
- Does NOT update StepStatusTypeId - only the Response payload is changed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaKey | uniqueidentifier | NO | - | VERIFIED | Business-level saga identifier. Used to look up SagaRuns.Id for the step query. |
| 2 | @StepIndex | tinyint | NO | - | VERIFIED | Ordinal position of the step to update (1-11 for CryptoToFiatSaga). |
| 3 | @Response | varchar(max) | NO | - | VERIFIED | JSON response payload from the async operation. Replaces the existing Response value in SagaSteps. |

**Return:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | UpdateStatus | BIT | VERIFIED | 1 = Response updated, 0 = SagaKey or StepIndex not found |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @SagaKey | Saga.SagaRuns | SELECT (subquery) | Looks up SagaRuns.Id by SagaKey |
| - | Saga.SagaSteps | UPDATE target | Updates Response column for the matching step |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.UpdateSagaStepResponse (procedure)
├── Saga.SagaRuns (table)
└── Saga.SagaSteps (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | SELECT (subquery) - looks up Id by SagaKey |
| Saga.SagaSteps | Table | UPDATE target - sets Response column |

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

### 8.1 Update step response after async completion
```sql
EXEC Saga.UpdateSagaStepResponse
    @SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E',
    @StepIndex = 5,
    @Response = '{"result": "success", "transactionId": "TX12345"}'
```

### 8.2 Check current step response
```sql
SELECT ss.StepIndex, LEFT(ss.Response, 200) AS Response, ss.StepStatusTypeId
FROM Saga.SagaSteps ss WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId
WHERE sr.SagaKey = '9E441DD9-D33E-4482-8682-ADB4FFE7B72E'
AND ss.StepIndex = 5
```

### 8.3 Find steps with NULL responses (awaiting async result)
```sql
SELECT sr.SagaKey, ss.StepIndex, ss.Created, ss.StepStatusTypeId
FROM Saga.SagaSteps ss WITH (NOLOCK)
INNER JOIN Saga.SagaRuns sr WITH (NOLOCK) ON sr.Id = ss.SagaRunId
WHERE ss.Response IS NULL AND sr.SagaStatusTypeId = 1
ORDER BY ss.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.UpdateSagaStepResponse | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.UpdateSagaStepResponse.sql*
