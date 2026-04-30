# Monitoring.GetFailedReceiveTransactions

> Retrieves received transactions whose associated ExternalReceiveTransactionSaga has failed, indicating crypto deposits that were not successfully processed.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns failed receive transactions via saga status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetFailedReceiveTransactions identifies incoming crypto deposits that failed during processing. The system uses a saga pattern (ExternalReceiveTransactionSaga) to orchestrate the multi-step receive flow. When the saga fails (SagaStatusTypeId=4), the customer's deposit was not fully processed - funds may have arrived on-chain but are not reflected in the customer's wallet balance.

Without this procedure, failed receive transactions would require manual correlation between saga runs and received transactions. Failed deposits directly impact customer experience and may require manual intervention to credit the customer's account.

The procedure joins Saga.SagaRuns (filtering for failed ExternalReceiveTransactionSaga instances) with Wallet.ReceivedTransactions via CorrelationId.

---

## 2. Business Logic

### 2.1 Failed Saga Detection

**What**: Links failed saga runs to their corresponding received transactions.

**Columns/Parameters Involved**: `SagaName`, `SagaStatusTypeId`, `CorrelationId`

**Rules**:
- SagaName = 'ExternalReceiveTransactionSaga' targets the receive flow specifically
- SagaStatusTypeId = 4 indicates a Failed saga
- Only sagas created within the @Hours lookback window are checked
- Join via CorrelationId links the saga failure to the specific transaction

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransaction ID. |
| 2 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the receive transaction was recorded. |
| 3 | Amount | DECIMAL | NO | - | CODE-BACKED | Crypto amount received. |
| 4 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID linking to the failed saga. |
| 5 | BlockchainTransactionDate | DATETIME2 | YES | - | CODE-BACKED | When the blockchain transaction was confirmed. |
| 6 | ReceivedTransactionTypeId | TINYINT | NO | - | CODE-BACKED | Type of receive transaction (e.g., external, internal). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Saga.SagaRuns | FROM (read) | Failed ExternalReceiveTransactionSaga instances |
| Query body | Wallet.ReceivedTransactions | JOIN | Transaction details for failed sagas |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetFailedReceiveTransactions (procedure)
  ├── Saga.SagaRuns (table)
  └── Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Saga.SagaRuns | Table | FROM - saga run status |
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

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetFailedReceiveTransactions;
```

### 8.2 Check last 72 hours
```sql
EXEC Monitoring.GetFailedReceiveTransactions @Hours = 72;
```

### 8.3 Check all saga statuses for receive transactions
```sql
SELECT sr.SagaStatusTypeId, COUNT(*) AS Count
FROM Saga.SagaRuns sr WITH (NOLOCK)
WHERE sr.SagaName = 'ExternalReceiveTransactionSaga'
  AND sr.Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY sr.SagaStatusTypeId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetFailedReceiveTransactions | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetFailedReceiveTransactions.sql*
