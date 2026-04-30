# Saga.GetSagaRunsByStatusAndThreshold

> Retrieves actively-leased saga runs filtered by status, saga name, and age threshold with row limit - the most specific query variant combining all four filter dimensions.

| Property | Value |
|----------|-------|
| **Schema** | Saga |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: TOP @Limit actively-leased SagaRuns + SagaSteps by status, name, and age |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSagaRunsByStatusAndThreshold is the most specific query variant, combining all four filter dimensions: status, saga name, age threshold, and active lease check. It answers: "Give me up to N sagas of type X in status Y that are actively being processed and have been running for more than Z seconds."

Used for targeted monitoring of specific saga types that are taking too long. Note: uses GETDATE() (local time) for the age threshold instead of GETUTCDATE() - this is inconsistent with other procedures that use GETUTCDATE().

---

## 2. Business Logic

### 2.1 Four-Dimension Filter

**What**: Status + Name + Age + Active Lease + Limit.

**Columns/Parameters Involved**: `@SagaStatusTypeId`, `@SagaName`, `@Threshold`, `@Limit`

**Rules**:
- SELECT TOP (@Limit) WHERE SagaStatusTypeId = @SagaStatusTypeId AND SagaName = @SagaName
- AND DATEDIFF(ss, sr.Created, GETDATE()) > @Threshold (note: uses GETDATE not GETUTCDATE)
- AND SagaKey IN SagaLeaseTime WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE())
- The GETDATE() vs GETUTCDATE() inconsistency means age calculation uses local server time while lease check uses UTC

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SagaStatusTypeId | tinyint | NO | - | VERIFIED | Status to filter by. See [Saga Status Type](../../_glossary.md#saga-status-type). |
| 2 | @SagaName | varchar(256) | NO | - | VERIFIED | Saga workflow type to filter by. Example: "CryptoToFiatSaga". |
| 3 | @Threshold | int | NO | - | VERIFIED | Minimum age in seconds (using local server time via GETDATE()). |
| 4 | @Limit | tinyint | NO | - | VERIFIED | Maximum number of saga runs to return. Max 255. |

**Return Columns:** Same as Saga.GetSagaRun.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Saga.SagaRuns | SELECT (FROM) | Filtered by status, name, age, and active lease |
| - | Saga.SagaSteps | SELECT (LEFT JOIN) | Step data joined by SagaRunId |
| - | Saga.SagaLeaseTime | SELECT (IN subquery) | Active lease check |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Saga.GetSagaRunsByStatusAndThreshold (procedure)
├── Saga.SagaRuns (table)
├── Saga.SagaSteps (table)
└── Saga.SagaLeaseTime (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - filtered by status, name, age threshold |
| Saga.SagaSteps | Table | LEFT JOIN by SagaRunId |
| Saga.SagaLeaseTime | Table | IN subquery - active lease validation |

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

### 8.1 Find long-running CryptoToFiatSaga in Start status
```sql
EXEC Saga.GetSagaRunsByStatusAndThreshold
    @SagaStatusTypeId = 1,
    @SagaName = 'CryptoToFiatSaga',
    @Threshold = 300,
    @Limit = 10
```

### 8.2 Find long-running rollback sagas
```sql
EXEC Saga.GetSagaRunsByStatusAndThreshold
    @SagaStatusTypeId = 2,
    @SagaName = 'CryptoToFiatSaga',
    @Threshold = 600,
    @Limit = 5
```

### 8.3 Equivalent direct query (corrected to GETUTCDATE)
```sql
SELECT TOP 10 sr.*, ss.StepIndex, ss.StepStatusTypeId
FROM Saga.SagaRuns sr WITH (NOLOCK)
LEFT JOIN Saga.SagaSteps ss WITH (NOLOCK) ON ss.SagaRunId = sr.Id
WHERE sr.SagaStatusTypeId = 1 AND sr.SagaName = 'CryptoToFiatSaga'
AND DATEDIFF(SECOND, sr.Created, GETUTCDATE()) > 300
AND sr.SagaKey IN (
    SELECT SagaKey FROM Saga.SagaLeaseTime WITH (NOLOCK)
    WHERE LastUpdaed > DATEADD(MINUTE, -5, GETUTCDATE())
)
ORDER BY ss.StepIndex
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Saga.GetSagaRunsByStatusAndThreshold | Type: Stored Procedure | Source: WalletConversionDB/Saga/Stored Procedures/Saga.GetSagaRunsByStatusAndThreshold.sql*
