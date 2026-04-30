# Trade.ExecuteCashPayment

> Processes pending cash payment commands (dividends and corporate actions) for a specific shard, executing each payment dynamically and enqueuing notification messages to the payment service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ShardID - processes payments for one shard |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the execution engine for dividend and corporate action cash payments. It reads pending payment commands from `Trade.CashPaymentStatus` for a given shard, executes each command dynamically, updates the status to success or failure, and enqueues a notification message via `Trade.EnqueuePaymentToSvcPayment` for each successful payment.

The procedure exists to process cash payments that were staged by the corporate actions pipeline. Each `CashPaymentStatus` record contains a pre-built SQL command (`CMD` column) that applies the actual cash credit/debit when executed. Sharding distributes the payment processing workload across multiple parallel job instances.

After each successful payment execution, the procedure calls `Trade.EnqueuePaymentToSvcPayment` to notify downstream systems. According to the inline comments, the notification reaches Service Broker (SBR), which creates `AccountCreditChangeNotification` (consumed by CnpEventWriter to push "Trading.Account.Credit" to the client's portfolio) and `AccountDividendFeeNotification` (consumed by CnpNotificationsService for user email/in-app/push notifications).

---

## 2. Business Logic

### 2.1 Sequential Payment Execution with Error Isolation

**What**: Processes each payment individually in its own transaction to prevent one failure from blocking others.

**Columns/Parameters Involved**: `CMD`, `StatusID`, `StatusDescription`, `ErrorMessage`

**Rules**:
- Selects all pending payments (StatusID=0) for the specified shard, ordered by ROW_NUMBER
- Each payment executes in its own BEGIN TRY/BEGIN TRAN block
- On success: StatusID updated to 1, StatusDescription = 'Success', then notification enqueued
- On failure: ROLLBACK, StatusID set to -1, StatusDescription = 'Failed', ErrorMessage captured (with single quotes stripped)
- Processing continues to next payment regardless of individual failures

**Diagram**:
```
CashPaymentStatus (StatusID=0, Sharding=@ShardID)
  |
  FOR EACH (sequentially by RuningID):
  |
  +-> BEGIN TRAN
  |     EXEC (@Cmd)                         -- Dynamic SQL payment command
  |     UPDATE StatusID = 1 (Success)
  |     EXEC EnqueuePaymentToSvcPayment     -- SBR notification
  |   COMMIT
  |
  +-> On Error:
        ROLLBACK
        UPDATE StatusID = -1 (Failed)
        ErrorMessage = ERROR_MESSAGE()
```

### 2.2 Downstream Notification Flow

**What**: Each successful payment triggers a cascade of notifications through Service Broker.

**Columns/Parameters Involved**: `@CID`, `@InstrumentID`, `@Amount`, `@CorporateActionTypeID`

**Rules**:
- MirrorID=0 and IsMirrorActive=0 are hardcoded - cash payments are not mirror-aware
- CorporateActionTypeID and DataSource come from Trade.CashingOperationMonitor (the operation that generated this payment)
- Notification chain: SBR -> AccountCreditChangeNotification -> CnpEventWriter -> "Trading.Account.Credit" push -> client portfolio update
- Parallel chain: SBR -> AccountDividendFeeNotification -> CnpNotificationsService -> email/in-app/push to user

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ShardID | int | NO | - | CODE-BACKED | Shard identifier used to partition payment processing. Filters CashPaymentStatus.Sharding to process only this shard's pending payments. Enables parallel processing across multiple job instances. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.CashPaymentStatus | READER | Reads pending payments (StatusID=0) for the shard |
| JOIN | Trade.CashingOperationMonitor | READER | Gets CorporateActionTypeID and DataSource for each payment |
| UPDATE | Trade.CashPaymentStatus | MODIFIER | Updates StatusID to 1 (success) or -1 (failed) after each payment |
| EXEC | Trade.EnqueuePaymentToSvcPayment | Caller | Enqueues Service Broker notification for each successful payment |
| EXEC (@Cmd) | Dynamic SQL | Execution | Executes the pre-built payment command stored in CashPaymentStatus.CMD |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | Job | Likely called by sharded payment processing jobs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExecuteCashPayment (procedure)
+-- Trade.CashPaymentStatus (table)
+-- Trade.CashingOperationMonitor (table)
+-- Trade.EnqueuePaymentToSvcPayment (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CashPaymentStatus | Table | SELECT pending payments, UPDATE status after execution |
| Trade.CashingOperationMonitor | Table | JOIN to get CorporateActionTypeID and DataSource |
| Trade.EnqueuePaymentToSvcPayment | Stored Procedure | EXEC to enqueue payment notifications |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found. | - | Likely invoked by SQL Agent Job |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp table indexes created at runtime:
- `#CashPaymentStatus`: CLUSTERED INDEX CIX on (RuningID, StatusID), NC INDEX IX on (StatusID)

### 7.2 Constraints

None.

**Security Note**: Uses `EXEC (@Cmd)` to execute dynamic SQL stored in the CMD column. The CMD content is pre-built by the staging pipeline and trusted. This pattern requires careful access control on CashPaymentStatus to prevent injection.

---

## 8. Sample Queries

### 8.1 Process Payments for Shard 0

```sql
EXEC Trade.ExecuteCashPayment @ShardID = 0
```

### 8.2 Check Pending and Failed Payments by Shard

```sql
SELECT Sharding AS ShardID,
       StatusID,
       COUNT(*) AS PaymentCount,
       SUM(Amount) AS TotalAmount
  FROM Trade.CashPaymentStatus WITH (NOLOCK)
 WHERE StatusID IN (0, -1)
 GROUP BY Sharding, StatusID
 ORDER BY Sharding, StatusID
```

### 8.3 View Recent Failed Payments with Error Details

```sql
SELECT TOP 50
       cps.ID,
       cps.CID,
       cps.InstrumentID,
       cps.Amount,
       cps.StatusDescription,
       cps.ErrorMessage,
       com.CorporateActionTypeID,
       com.DataSource
  FROM Trade.CashPaymentStatus cps WITH (NOLOCK)
  JOIN Trade.CashingOperationMonitor com WITH (NOLOCK) ON cps.MonitorID = com.ID
 WHERE cps.StatusID = -1
 ORDER BY cps.ID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExecuteCashPayment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ExecuteCashPayment.sql*
