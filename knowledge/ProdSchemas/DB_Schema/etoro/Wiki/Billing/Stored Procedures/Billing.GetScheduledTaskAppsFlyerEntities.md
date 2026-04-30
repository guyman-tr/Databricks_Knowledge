# Billing.GetScheduledTaskAppsFlyerEntities

> Post-deposit scheduler fetch procedure for TaskID=1 (AppsFlyer attribution): claims pending deposits with PaymentStatusID=2, returns deposit + customer attribution data including AppsFlyerID, then marks claimed rows as In Progress (TaskState=3).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxEntitiesToFetch (batch cap); returns one row per claimed deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetScheduledTaskAppsFlyerEntities` is the batch-fetch step of the AppsFlyer attribution pipeline (TaskID=1). AppsFlyer is the mobile attribution analytics platform used to track which marketing channels drove customer deposits. This procedure selects and claims a batch of successful deposits (PaymentStatusID=2) that are queued for AppsFlyer attribution event sending, then returns the attribution data the caller needs to construct the event.

Part of the post-deposit scheduled task framework built on `Billing.ScheduledTaskState`. Introduced 02 Aug 2020 (Shay Oren, PAYUS-1254) with the optimization of pre-selecting eligible deposit IDs into a `#STS` temp table before the main JOIN - this avoids locking on the main ScheduledTaskState table while building the result set.

The claim-and-return pattern is atomic: the same procedure that returns the data also marks the rows as In Progress (TaskState=3), preventing double-processing in a concurrent environment.

---

## 2. Business Logic

### 2.1 Two-Stage Claim Pattern (PAYUS-1254 Optimization)

**What**: DepositIDs are pre-selected into `#STS` before the data JOIN to reduce lock contention.

**Rules**:
- Stage 1: `INSERT #STS SELECT DepositID FROM ScheduledTaskState WHERE TaskState=0 AND TaskID=1 AND EXISTS (SELECT ... FROM Deposit WHERE PaymentStatusID=2 AND DepositID=BST.DepositID)`
  - Only TaskID=1 (AppsFlyer) rows
  - Only TaskState=0 (Pending)
  - Only where the deposit has PaymentStatusID=2 (Approved/Successful)
- Stage 2: `SELECT TOP (@MaxEntitiesToFetch) ... FROM Deposit INNER JOIN #STS INTO #PostDepositTask`
- Stage 3: `UPDATE ScheduledTaskState SET TaskState=3 FROM #PostDepositTask` - atomic claim

### 2.2 AppsFlyer Attribution Data

**What**: Returns the fields needed to build an AppsFlyer attribution event.

**Columns/Parameters Involved**: `CS.GCID`, `CS.FunnelFromID`, `T.TrackingValue AS AppsFlyerID`

**Rules**:
- `AppsFlyerID = CONVERT(VARCHAR(300), T.TrackingValue)` from `Customer.TrackingId WHERE CID=CS.CID AND TrackingID=1`
  - TrackingID=1 identifies the AppsFlyer device tracking record
  - NULL if no AppsFlyer tracking record exists for this customer
- `FunnelFromID` from Customer.CustomerStatic - the acquisition funnel source ID
- `GCID` - global customer identifier needed for AppsFlyer event routing
- `IPAddress` - computed via `Internal.IPNumToIPAddress(CONVERT(VARCHAR(15), D.IPAddress))` - converts numeric IP to dotted-decimal string

### 2.3 MaxEntitiesToFetch Pattern

**What**: The @MaxEntitiesToFetch parameter caps the batch size; -1 means unlimited.

**Rules**:
- `TOP (IIF(@MaxEntitiesToFetch = -1, 2147483647, @MaxEntitiesToFetch))` - -1 becomes max INT (effectively no limit)
- Batch size is typically loaded from `Billing.ScheduledTaskConfig.MaxEntitiesToFetch` by the caller first (via `GetScheduledTaskConfig`)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxEntitiesToFetch | INT | YES | -1 | CODE-BACKED | Maximum number of deposits to claim in this batch. -1 = no limit (uses MAX INT as TOP). Typically loaded from `Billing.ScheduledTaskConfig.MaxEntitiesToFetch` for TaskID=1 (1000). |

### Result Set Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositID | INT | NO | - | CODE-BACKED | PK of the claimed deposit. |
| 3 | Amount | MONEY | YES | - | CODE-BACKED | `Billing.Deposit.Amount` - deposit amount in deposit currency. |
| 4 | ExchangeRate | DECIMAL | YES | - | CODE-BACKED | `Billing.Deposit.ExchangeRate` - exchange rate at deposit time. Multiply by Amount for USD value. |
| 5 | IsFTD | BIT | YES | - | CODE-BACKED | `Billing.Deposit.IsFTD` - whether this is the customer's first-time deposit. Key flag for AppsFlyer FTD attribution events. |
| 6 | IPAddress | VARCHAR | YES | - | CODE-BACKED | Customer's IP address at deposit time, converted from numeric to dotted-decimal via `Internal.IPNumToIPAddress`. |
| 7 | CurrencyID | INT | YES | - | CODE-BACKED | `Billing.Deposit.CurrencyID` - deposit currency. FK to `Dictionary.Currency`. |
| 8 | GCID | INT | YES | - | CODE-BACKED | `Customer.CustomerStatic.GCID` - global customer identifier used by AppsFlyer for cross-platform attribution. |
| 9 | FunnelFromID | INT | YES | - | CODE-BACKED | `Customer.CustomerStatic.FunnelFromID` - acquisition funnel source identifier. |
| 10 | AppsFlyerID | VARCHAR(300) | YES | - | CODE-BACKED | Customer's AppsFlyer device ID from `Customer.TrackingId WHERE TrackingID=1`. NULL if customer has no AppsFlyer tracking record. |
| 11 | PaymentStatusID | INT | YES | - | CODE-BACKED | `Billing.Deposit.PaymentStatusID` - always 2 (Approved) per the TaskState filter. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DepositID | Billing.ScheduledTaskState | SELECT + UPDATE | Claim pending TaskID=1 rows; mark as TaskState=3 |
| DepositID | Billing.Deposit | INNER JOIN | Deposit amount, exchange rate, IsFTD, IP, currency, payment status |
| D.CID | Customer.CustomerStatic | INNER JOIN | GCID, FunnelFromID |
| CS.CID | Customer.TrackingId | LEFT JOIN (TrackingID=1) | AppsFlyerID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AppsFlyer attribution scheduler (TaskID=1) | @MaxEntitiesToFetch | EXEC | Batch fetch before sending attribution events to AppsFlyer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetScheduledTaskAppsFlyerEntities (procedure)
+-- Billing.ScheduledTaskState (table)
+-- Billing.Deposit (table)
+-- Customer.CustomerStatic (table, cross-schema)
+-- Customer.TrackingId (table, cross-schema)
+-- Internal.IPNumToIPAddress (function, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.ScheduledTaskState | Table | Claim pending TaskID=1 rows; mark as TaskState=3 |
| Billing.Deposit | Table | Deposit data for AppsFlyer event |
| Customer.CustomerStatic | Table | GCID, FunnelFromID |
| Customer.TrackingId | Table | AppsFlyerID (TrackingID=1) |
| Internal.IPNumToIPAddress | Function (cross-schema) | IP address formatting |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AppsFlyer attribution worker | External | Processes batch to send attribution events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| #STS temp table pre-filter | Performance (PAYUS-1254) | Pre-selects DepositIDs before main JOIN to reduce ScheduledTaskState lock contention |
| PaymentStatusID=2 filter | Business rule | Only approved/successful deposits are sent to AppsFlyer |
| TaskState=0 -> TaskState=3 | Atomic claim | Prevents double-processing in concurrent scheduler instances |
| EXISTS with TOP 1 1 | Optimization | EXISTS check avoids full scan of Deposit table for each candidate |

---

## 8. Sample Queries

### 8.1 Fetch up to 100 AppsFlyer attribution entities
```sql
EXEC Billing.GetScheduledTaskAppsFlyerEntities @MaxEntitiesToFetch = 100;
```

### 8.2 Check pending AppsFlyer queue depth
```sql
SELECT COUNT(*) AS PendingCount
FROM Billing.ScheduledTaskState WITH (NOLOCK)
WHERE TaskID = 1 AND TaskState = 0;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-1254 (referenced in DDL comment, Shay Oren, 02/08/2020) | Jira | Added #STS temp table pre-selection optimization to reduce lock contention (Jira unavailable for full details) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1,8,9,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (unavailable) | Procedures: 0 callers analyzed | App Code: 0 repos (billing repos not configured) | Corrections: 0 applied*
*Object: Billing.GetScheduledTaskAppsFlyerEntities | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetScheduledTaskAppsFlyerEntities.sql*
