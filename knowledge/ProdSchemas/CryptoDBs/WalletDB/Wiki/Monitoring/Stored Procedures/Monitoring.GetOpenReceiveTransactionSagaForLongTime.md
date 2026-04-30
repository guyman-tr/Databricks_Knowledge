# Monitoring.GetOpenReceiveTransactionSagaForLongTime

> Identifies receive transactions whose associated ExternalReceiveTransactionSaga has been in Start or Rollback status for longer than the specified threshold, indicating stuck processing.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns long-running receive transaction sagas |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetOpenReceiveTransactionSagaForLongTime detects receive transaction sagas that have been running for an unusually long time. Unlike GetFailedReceiveTransactions which finds explicitly failed sagas, this procedure finds sagas that are STILL in progress (SagaStatusTypeId=1 Start, or SagaStatusTypeId=2 Rollback) but have been open for longer than the threshold. These represent customer deposits that are "stuck in processing."

Without this procedure, long-running sagas would go unnoticed until they either complete, fail, or a customer complains. Early detection allows operations to investigate and potentially manually resolve stuck deposits.

---

## 2. Business Logic

### 2.1 Long-Running Saga Detection

**What**: Finds sagas older than the threshold that haven't reached a terminal status.

**Columns/Parameters Involved**: `SagaStatusTypeId`, `@Hours`, `Created`

**Rules**:
- SagaName = 'ExternalReceiveTransactionSaga' targets receive flows
- SagaStatusTypeId IN (1, 2): 1=Start (still processing), 2=Rollback (compensation in progress)
- Created < DATEADD(HOUR, -@Hours, GETUTCDATE()) - older than threshold
- Default threshold: 24 hours

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 24 | CODE-BACKED | Age threshold in hours. Sagas older than this are flagged. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransaction ID. |
| 2 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the receive transaction was recorded. |
| 3 | Amount | DECIMAL | NO | - | CODE-BACKED | Crypto amount received. |
| 4 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID linking to the stuck saga. |
| 5 | BlockchainTransactionDate | DATETIME2 | YES | - | CODE-BACKED | When the blockchain transaction was confirmed. |
| 6 | ReceivedTransactionTypeId | TINYINT | NO | - | CODE-BACKED | Type of receive transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Saga.SagaRuns | FROM (read) | Long-running saga detection |
| Query body | Wallet.ReceivedTransactions | JOIN | Transaction details for stuck sagas |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetOpenReceiveTransactionSagaForLongTime (procedure)
  ├── Saga.SagaRuns (table)
  └── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - saga status detection |
| Wallet.ReceivedTransactions | Table | JOIN - transaction details |

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

### 8.1 Check for sagas open longer than 24 hours (default)
```sql
EXEC Monitoring.GetOpenReceiveTransactionSagaForLongTime;
```

### 8.2 Check for sagas open longer than 4 hours (tighter threshold)
```sql
EXEC Monitoring.GetOpenReceiveTransactionSagaForLongTime @Hours = 4;
```

### 8.3 View all open receive sagas with their age
```sql
SELECT sr.CorrelationId, sr.SagaStatusTypeId, sr.Created,
  DATEDIFF(HOUR, sr.Created, GETUTCDATE()) AS AgeHours
FROM Saga.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaName = 'ExternalReceiveTransactionSaga'
  AND sr.SagaStatusTypeId IN (1, 2)
ORDER BY sr.Created;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetOpenReceiveTransactionSagaForLongTime | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetOpenReceiveTransactionSagaForLongTime.sql*
