# Wallet.GetPendingUserManualOutTransactions

> Retrieves user-level (non-omnibus) manual out transactions that have not yet been converted into formal requests, with built-in throttling and random batch sizing to distribute processing load.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns unprocessed user manual out transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds manual outbound crypto transactions initiated for specific customers (Gcid <> 0) that have been submitted but not yet picked up by the formal request processing pipeline. Manual out transactions are operator-initiated transfers on behalf of customers - such as manual redemptions, corrections, or fee adjustments - that require conversion into a formal `Wallet.Requests` record before the send pipeline can process them.

Without this procedure, user-level manual out transactions would remain in the `ManualOutTransactions` staging table indefinitely. It is the bridge between operator-submitted manual transactions and the automated wallet send pipeline. The procedure is the user-level counterpart to `Wallet.GetPendingOmnibusManualOutTransactions`, which handles system-level (Gcid=0) transactions.

The procedure is called by a scheduled job (granted to `RedeemSchedulerUser` and `ScheduledJobsUser`). It self-throttles to run no more than once every 5 minutes by checking the last activity time in `Wallet.ProcesseActivities` for the `HandleUserManualOutTransactions` process. Each invocation selects a random batch of 20-120 records (averaging ~65) to distribute processing load and avoid thundering-herd effects.

---

## 2. Business Logic

### 2.1 Throttle Mechanism

**What**: Prevents the scheduled job from running too frequently by enforcing a minimum 5-minute interval between executions.

**Columns/Parameters Involved**: `Wallet.Processes.Name`, `Wallet.ProcesseActivities.Occurred`

**Rules**:
- Looks up the process ID for 'HandleUserManualOutTransactions' in the Processes registry
- Retrieves the most recent activity timestamp from ProcesseActivities
- If fewer than 5 minutes have elapsed since the last run, the procedure rolls back and returns immediately with no results
- On successful execution, updates the activity timestamp to GETUTCDATE() before fetching data

**Diagram**:
```
Scheduled Job Trigger
       |
       v
[Check last run time]
       |
  < 5 min? --YES--> ROLLBACK (return nothing)
       |
      NO
       |
       v
[Update activity timestamp]
       |
       v
[Fetch random batch of pending transactions]
       |
       v
Return results to caller
```

### 2.2 Random Batch Sizing

**What**: Each invocation processes a randomly sized batch to smooth out processing load over time.

**Columns/Parameters Involved**: `@MaxRecords` (local variable)

**Rules**:
- Batch size is calculated as ROUND(RAND() * 90, 0) + 20, yielding a range of 20 to 110 (comment says 120 but formula produces max 110)
- Averaging ~65 transactions per run supports faster extractions without overwhelming downstream systems
- Records are ordered by Occurred (oldest first) for FIFO processing

### 2.3 Unprocessed Transaction Detection

**What**: Identifies manual out transactions that have not yet entered the formal request pipeline.

**Columns/Parameters Involved**: `ManualOutTransactions.CorrelationId`, `Requests.Id`, `ManualOutTransactions.Gcid`

**Rules**:
- LEFT JOIN to Wallet.Requests on CorrelationId: if no matching request exists (r.Id IS NULL), the transaction is unprocessed
- Gcid <> 0 filter ensures only user-level transactions are returned (omnibus/system transactions are handled by GetPendingOmnibusManualOutTransactions)
- Uses NOLOCK hints for non-blocking reads

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Identity PK of the ManualOutTransactions row. Used to track which specific manual transaction record is being processed. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the customer for whom the manual out transaction was created. Always non-zero (user-level transactions only; Gcid=0 is handled by the omnibus variant). |
| 3 | CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency identifier. FK to Wallet.CryptoTypes. Identifies which crypto asset is being sent (e.g., 1=BTC, 2=ETH). |
| 4 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Source wallet from which the manual outbound transfer will be sent. FK to Wallet.Wallets. |
| 5 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique correlation identifier linking this manual transaction to its eventual Request record. Used to detect whether the transaction has already been picked up (JOIN to Requests). |
| 6 | EtoroExternalAddressId | int | NO | - | CODE-BACKED | Destination external address for the outbound transfer. FK to Wallet.EtoroExternalAddresses. |
| 7 | Amount | decimal(26,18) | NO | - | CODE-BACKED | Crypto amount to send in the manual out transaction. Full precision to support fractional crypto amounts. |
| 8 | Comment | nvarchar(256) | NO | - | CODE-BACKED | Operator-provided comment or reason for the manual out transaction (e.g., "manual redemption correction", "fee adjustment"). |

### Internal Variables

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | @MaxRecords | int | Random batch size between 20 and 110, controlling how many pending transactions are returned per invocation. |
| 2 | @MinutesBetweenCalls | int | Throttle interval set to 5 minutes. If the procedure was called less than 5 minutes ago, it returns immediately. |
| 3 | @ProcessId | int | Resolved ID of the 'HandleUserManualOutTransactions' process from Wallet.Processes. |
| 4 | @LastRan | datetime2(7) | Timestamp of the most recent activity for this process from Wallet.ProcesseActivities. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Output: CryptoId | Wallet.CryptoTypes | Lookup | Cryptocurrency type of the manual out transaction |
| Output: WalletId | Wallet.Wallets | Lookup | Source wallet for the outbound transfer |
| Output: CorrelationId | Wallet.Requests | JOIN (LEFT) | Used to detect unprocessed transactions - no matching request means pending |
| Output: EtoroExternalAddressId | Wallet.EtoroExternalAddresses | Lookup | Destination external blockchain address |
| @ProcessId | Wallet.Processes | Lookup | Process registry for throttle management |
| @LastRan | Wallet.ProcesseActivities | Lookup | Last execution timestamp for throttle check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | GRANT EXECUTE | Permission | Scheduled job user that invokes this procedure |
| ScheduledJobsUser | GRANT EXECUTE | Permission | Scheduled job user that invokes this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPendingUserManualOutTransactions (procedure)
├── Wallet.ManualOutTransactions (table)
├── Wallet.Requests (table)
├── Wallet.Processes (table)
└── Wallet.ProcesseActivities (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ManualOutTransactions | Table | Main data source - SELECT with NOLOCK |
| Wallet.Requests | Table | LEFT JOIN to detect unprocessed transactions |
| Wallet.Processes | Table | Lookup process ID for throttle check |
| Wallet.ProcesseActivities | Table | Read/update last activity timestamp for throttle |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Scheduled jobs) | External | Called by RedeemSchedulerUser / ScheduledJobsUser on a schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction wrapping | TRY/CATCH | Entire operation runs within a transaction. On failure, rolls back and raises the error with full context (message, number, severity, state, procedure, line). |
| Throttle guard | Logic | DATEDIFF(MINUTE, @LastRan, GETUTCDATE()) < 5 triggers early ROLLBACK with no output. |
| Insert-only source table | Trigger | ManualOutTransactions has an INSTEAD OF DELETE/UPDATE trigger preventing modification - data is append-only. |

---

## 8. Sample Queries

### 8.1 Check for pending user manual out transactions
```sql
SELECT omot.Id, omot.Gcid, omot.CryptoId, omot.Amount, omot.Comment, omot.Occurred
FROM Wallet.ManualOutTransactions omot WITH (NOLOCK)
    LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = omot.CorrelationId
WHERE omot.Gcid <> 0
    AND r.Id IS NULL
ORDER BY omot.Occurred;
```

### 8.2 Check last execution time of the HandleUserManualOutTransactions process
```sql
SELECT TOP 1 pa.Occurred AS LastRan,
    DATEDIFF(MINUTE, pa.Occurred, GETUTCDATE()) AS MinutesSinceLastRun
FROM Wallet.Processes p WITH (NOLOCK)
    JOIN Wallet.ProcesseActivities pa WITH (NOLOCK) ON pa.ProcessId = p.Id
WHERE p.Name = 'HandleUserManualOutTransactions'
ORDER BY pa.Id DESC;
```

### 8.3 Count pending user vs omnibus manual out transactions
```sql
SELECT
    CASE WHEN omot.Gcid = 0 THEN 'Omnibus' ELSE 'User' END AS TransactionType,
    COUNT(*) AS PendingCount
FROM Wallet.ManualOutTransactions omot WITH (NOLOCK)
    LEFT JOIN Wallet.Requests r WITH (NOLOCK) ON r.CorrelationId = omot.CorrelationId
WHERE r.Id IS NULL
GROUP BY CASE WHEN omot.Gcid = 0 THEN 'Omnibus' ELSE 'User' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPendingUserManualOutTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPendingUserManualOutTransactions.sql*
