# Billing.UpdateAppsFlyerDepositData

> Atomically claims the AppsFlyer post-deposit task for a specific deposit (TaskState 0->3) and returns all deposit + customer data the analytics service needs to send the deposit event to AppsFlyer.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - targets TaskID=1 (AppsFlyer) in Billing.ScheduledTaskState |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateAppsFlyerDepositData` is the analytics service's atomic fetch-and-lock procedure for AppsFlyer deposit attribution. When the analytics service needs to report a deposit event to AppsFlyer (for mobile app install attribution and LTV tracking), it calls this procedure to simultaneously claim the AppsFlyer task (preventing duplicate processing) and retrieve all the data needed to construct the AppsFlyer event payload.

The "claim" is done via an `UPDATE ... OUTPUT` pattern: it sets `Billing.ScheduledTaskState.TaskState = 3` (In Progress) WHERE `TaskID=1` (AppsFlyer task), `TaskState=0` (still Pending), and `DepositID = @DepositID`. The UPDATE is atomic - if another service instance claims the same deposit first, this procedure's UPDATE matches 0 rows and returns an empty result set.

The procedure returns the deposit's amount, exchange rate, first-time-deposit flag, IP address (formatted), currency, GCID (global customer ID), funnel attribution source, AppsFlyer device ID (from Customer.TrackingId), and payment status - everything needed for the AppsFlyer server-to-server event call.

Created as part of the AppsFlyer migration (PAYIL-5148, November 2022). Called exclusively by the Analytics service (AnalyticsServiceUser role).

---

## 2. Business Logic

### 2.1 Atomic Task Claim via UPDATE OUTPUT

**What**: The UPDATE...OUTPUT pattern atomically transitions the AppsFlyer task from Pending (0) to In-Progress (3) and returns deposit data in a single atomic operation, preventing double-processing.

**Columns/Parameters Involved**: `Billing.ScheduledTaskState.TaskState`, `TaskID`, `DepositID`, `@DepositID`

**Rules**:
- Only rows WHERE `TaskID=1 AND TaskState=0 AND DepositID=@DepositID` are updated
- `TaskID=1` identifies the AppsFlyer post-deposit task specifically
- `TaskState=0` (Pending) filter ensures only unclaimed tasks are taken; if already claimed (TaskState=3) or done (TaskState=1), the UPDATE finds 0 rows and the result set is empty
- After UPDATE: `TaskState=3` (In Progress) + `Created=GETUTCDATE()` (timestamp of claim)
- The OUTPUT INTO pattern inserts the affected rows and joined data into #PostDepositTask simultaneously
- Result: the caller gets deposit data back only if it successfully claimed the task

**Diagram**:
```
ScheduledTaskState row: (DepositID=X, TaskID=1, TaskState=0) <- Pending, unclaimed

EXEC UpdateAppsFlyerDepositData @DepositID=X
  |
  +-> UPDATE ScheduledTaskState SET TaskState=3
      WHERE TaskID=1 AND TaskState=0 AND DepositID=X
        |
        +-> 1 row affected (success):
            OUTPUT -> JOIN Billing.Deposit + Customer.CustomerStatic + Customer.TrackingId
            -> #PostDepositTask has 1 row
            -> SELECT returns: DepositID, Amount, ExchangeRate, IsFTD, IPAddress (formatted),
                               CurrencyID, GCID, FunnelFromID, AppsFlyerID, PaymentStatusID
        |
        +-> 0 rows affected (already claimed or done):
            -> #PostDepositTask is empty
            -> SELECT returns empty result set (caller knows: skip this deposit)

After successful processing, analytics service calls UpdateScheduledTask or UpdateScheduledTaskState
to mark TaskState=1 (Done).
```

### 2.2 AppsFlyer Device ID Retrieval

**What**: The LEFT JOIN to Customer.TrackingId with TrackingID=1 fetches the AppsFlyer device ID for the customer, enabling attribution back to the mobile app install.

**Columns/Parameters Involved**: `Customer.TrackingId.TrackingValue`, `Customer.TrackingId.TrackingID`

**Rules**:
- `TrackingID=1` identifies AppsFlyer as the tracking provider (not Google Analytics, Facebook, etc.)
- `TrackingValue` is the AppsFlyer device ID string (up to 300 chars) that AppsFlyer uses to correlate the deposit with the app install
- LEFT JOIN: customers without an AppsFlyer tracking ID (organic acquisition, desktop users) get NULL - the analytics service handles NULL AppsFlyerID separately
- The IP address is stored as NUMERIC(18,0) in Billing.Deposit and converted to dotted-decimal format by `Internal.IPNumToIPAddress`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to process. Used to filter Billing.ScheduledTaskState to the specific (DepositID, TaskID=1, TaskState=0) row to claim. |

**Result set columns** (returned via SELECT from #PostDepositTask):

| # | Element | Source | Confidence | Description |
|---|---------|--------|------------|-------------|
| OUT1 | DepositID | Billing.ScheduledTaskState (OUTPUT) | CODE-BACKED | The deposit ID that was claimed. Confirms which deposit was processed (should match @DepositID). |
| OUT2 | Amount | Billing.Deposit.Amount | CODE-BACKED | Deposit amount in the customer's deposit currency (MONEY). Sent to AppsFlyer as the deposit value for LTV attribution. |
| OUT3 | ExchangeRate | Billing.Deposit.ExchangeRate | CODE-BACKED | Exchange rate from deposit currency to USD at time of deposit (decimal(16,8)). Used to normalize deposit value for AppsFlyer cross-currency reporting. |
| OUT4 | IsFTD | Billing.Deposit.IsFTD | CODE-BACKED | First-Time-Deposit flag: 1=this is the customer's first successful deposit, 0=repeat deposit. Critical AppsFlyer event differentiator - FTD events receive different attribution treatment and drive install-to-deposit conversion metrics. |
| OUT5 | IPAddress | Billing.Deposit.IPAddress via Internal.IPNumToIPAddress | CODE-BACKED | Customer's IP address at time of deposit, formatted as dotted-decimal string (e.g., "192.168.1.1"). The raw NUMERIC(18,0) value is converted by Internal.IPNumToIPAddress. Sent to AppsFlyer for fraud detection and geo-attribution. |
| OUT6 | CurrencyID | Billing.Deposit.CurrencyID | CODE-BACKED | Currency of the deposit (FK to Dictionary.Currency: 1=USD, 2=EUR, 3=GBP, etc.). Needed by AppsFlyer to report deposit revenue in the correct currency. |
| OUT7 | GCID | Customer.CustomerStatic.GCID | CODE-BACKED | Global Customer ID - the platform-wide unique customer identifier used by the analytics layer (distinct from CID which is the billing system's customer ID). AppsFlyer uses GCID to identify the customer. |
| OUT8 | FunnelFromID | Customer.CustomerStatic.FunnelFromID | CODE-BACKED | The marketing funnel/acquisition source ID for the customer. Tells AppsFlyer which campaign or channel originally acquired this depositing customer. |
| OUT9 | AppsFlyerID | Customer.TrackingId.TrackingValue (TrackingID=1) | CODE-BACKED | The AppsFlyer device ID string for this customer (up to 300 chars). AppsFlyer's primary key for linking server-to-server deposit events back to the mobile app install. NULL if customer has no AppsFlyer tracking ID (non-mobile or organic). |
| OUT10 | PaymentStatusID | Billing.Deposit.PaymentStatusID | CODE-BACKED | Payment processing status of the deposit at time of AppsFlyer reporting. Allows the analytics service to filter out or flag deposits by payment status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE WHERE DepositID | Billing.ScheduledTaskState | UPDATE (task claim) | Atomically sets TaskState=3 for TaskID=1 (AppsFlyer) to claim the task |
| JOIN ON DepositID | Billing.Deposit | SELECT JOIN (via OUTPUT) | Provides deposit amount, exchange rate, IsFTD, IP, currency, payment status |
| JOIN ON CID | Customer.CustomerStatic | SELECT JOIN (cross-schema) | Provides GCID and FunnelFromID for AppsFlyer attribution |
| LEFT JOIN ON CID + TrackingID=1 | Customer.TrackingId | SELECT JOIN (cross-schema) | Provides AppsFlyer device ID (TrackingID=1 = AppsFlyer) |
| IPNumToIPAddress() | Internal.IPNumToIPAddress | Function call (cross-schema) | Converts IP from NUMERIC(18,0) to dotted-decimal string |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Analytics service | @DepositID | EXEC (AnalyticsServiceUser role) | Called to claim and retrieve AppsFlyer deposit data for attribution reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateAppsFlyerDepositData (procedure)
├── Billing.ScheduledTaskState (table) - UPDATE
├── Billing.Deposit (table) - SELECT via OUTPUT JOIN
├── Customer.CustomerStatic (table) - SELECT JOIN (cross-schema)
├── Customer.TrackingId (table) - SELECT JOIN (cross-schema)
└── Internal.IPNumToIPAddress (function) - called in SELECT
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | UPDATE - claims AppsFlyer task (TaskID=1) by setting TaskState=3 WHERE TaskState=0 AND DepositID=@DepositID |
| Billing.Deposit | Table | SELECT JOIN via OUTPUT - provides deposit amount, exchange rate, IsFTD, IP, currency, payment status |
| Customer.CustomerStatic | Table | INNER JOIN via OUTPUT - provides GCID and FunnelFromID |
| Customer.TrackingId | Table | LEFT JOIN via OUTPUT - provides AppsFlyer device ID (TrackingID=1) |
| Internal.IPNumToIPAddress | Function | Called in SELECT to format IPAddress from numeric to dotted-decimal string |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Analytics service (AnalyticsServiceUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: A NONCLUSTERED index is created on the temp table #PostDepositTask on (DepositID) to support the final SELECT DISTINCT, though with at most 1 row per deposit ID this is primarily a pattern for consistency.

### 7.2 Constraints

N/A for stored procedure. Note: The `SELECT DISTINCT` in the final result prevents duplicate rows if the OUTPUT somehow produced duplicates (defensive pattern).

---

## 8. Sample Queries

### 8.1 Execute the procedure for a specific deposit
```sql
-- Claim and retrieve AppsFlyer data for deposit 12345
EXEC Billing.UpdateAppsFlyerDepositData @DepositID = 12345;
-- Returns 1 row if TaskID=1 was pending; 0 rows if already claimed/done
```

### 8.2 Check pending AppsFlyer tasks for a deposit
```sql
SELECT DepositID, TaskID, TaskState, Created
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE DepositID = 12345
  AND TaskID = 1;
-- TaskState=0: pending (procedure will claim it)
-- TaskState=3: in-progress (procedure will return empty)
-- TaskState=1: done (already processed)
```

### 8.3 Find deposits with stuck AppsFlyer tasks (in-progress for > 1 hour)
```sql
SELECT DepositID, TaskState, Created,
       DATEDIFF(MINUTE, Created, GETUTCDATE()) AS MinutesInProgress
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskID = 1
  AND TaskState = 3
  AND Created < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY Created;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PAYIL-5148: Staging DB - Billing.UpdateAppsFlyerDepositData sp](https://etoro-jira.atlassian.net/browse/PAYIL-5148) | Jira | Confirms SP was created 2022-11-14 as part of the AppsFlyer migration (parent: PAYIL-5200 Analytics Service AppsFlyer Migration Testing + Deployment). Assigned to Shay Oren, reported by Lior Tamam. |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 1 Jira (PAYIL-5148) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateAppsFlyerDepositData | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateAppsFlyerDepositData.sql*
