# History.RecurringInvestmentPlanInstances

> System-versioned temporal history table storing previous row versions from RecurringInvestment.PlanInstances - tracks the full history of every plan instance update as each deposit/order/position stage change creates a history row.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.PlanInstances |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) + 1 nonclustered on (PlanID, ValidFrom, ValidTo) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.PlanInstances`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row in this table represents a past state of a plan instance, bounded by the ValidFrom and ValidTo period columns.

Plan instances progress through multiple stages (deposit, order, position), and each stage transition triggers an UPDATE on the parent table, which automatically creates a history row here. This means a single plan instance can have many history rows - one for each time the instance was modified as it progressed through its lifecycle. For example, when a deposit is confirmed, the deposit columns are filled and the previous state (with NULL deposit columns) moves to history. When the order is placed, the pre-order state moves to history, and so on.

This table is the most heavily written history table in the RecurringInvestment database because every plan instance passes through multiple state changes per cycle. It is critical for diagnosing issues in the deposit-order-position pipeline, investigating failed instances, and providing audit trails for compliance.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. Each row captures the exact state of a plan instance at a specific point in time, including which deposit/order/position columns were populated at that moment.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp. This is the primary flow - every stage transition (deposit received, order placed, position opened, status changed) creates a history row.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp.

The progression of history rows for a single instance tells the story of that instance's lifecycle - from initial creation through deposit, order, and position stages.

---

## 3. Data Overview

Rows in this table represent previous states of plan instances. A single InstanceID may appear many times, each with different column values representing the state at that point in time.

| InstanceID | PlanID | DepositID | OrderStatusId | PositionStatus | InstanceStatusID | ValidFrom | ValidTo | Meaning |
|------------|--------|-----------|---------------|----------------|------------------|-----------|---------|---------|
| 209781 | 189 | NULL | NULL | NULL | NULL | 2026-04-01 | 2026-04-10 08:00 | Instance 209781 before deposit - just created by Plan Instances Job, all execution columns NULL. |
| 209781 | 189 | 75101367 | NULL | NULL | 5 | 2026-04-10 08:00 | 2026-04-10 09:30 | Same instance after deposit received (DepositID filled, status InProgress). Order not yet placed. |
| 209781 | 189 | 75101367 | 1 | NULL | 5 | 2026-04-10 09:30 | 2026-04-10 10:00 | Same instance after order placed (OrderStatusId=1 Received). Position not yet opened. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | InstanceID | int | NO | - | Same as parent table RecurringInvestment.PlanInstances.InstanceID. Unique auto-incrementing surrogate key for the instance. Not an identity column in the history table. |
| 2 | PlanID | int | NO | - | Same as parent table RecurringInvestment.PlanInstances.PlanID. FK to Plans.ID. Identifies which plan this instance belongs to. |
| 3 | NextOrderDate | datetime | NO | - | Same as parent table RecurringInvestment.PlanInstances.NextOrderDate. Scheduled execution date for this instance. |
| 4 | CreationDate | datetime | NO | - | Same as parent table RecurringInvestment.PlanInstances.CreationDate. When this instance record was created by the Plan Instances Job. |
| 5 | DepositID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositID. Deposit identifier from Money ServiceBus. NULL before deposit stage. |
| 6 | DepositAmountUsd | decimal(18,2) | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositAmountUsd. DEPRECATED. Deposit amount in USD. |
| 7 | DepositAmountCurrency | decimal(18,2) | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositAmountCurrency. DEPRECATED. Deposit amount in plan currency. |
| 8 | DepositCycleNumber | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositCycleNumber. Deposit cycle number from Billing system. |
| 9 | DepositDate | datetime | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositDate. When the deposit was made or attempted. |
| 10 | HighLevelDepositStatusId | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.HighLevelDepositStatusId. 1=Success, 2=SoftDecline, 3=HardDecline. |
| 11 | DepositStatusID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositStatusID. Detailed deposit status from Billing DB. |
| 12 | OrderStatusId | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.OrderStatusId. Order lifecycle state from Trading API enum. |
| 13 | OrderID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.OrderID. Order identifier from Trading API. |
| 14 | OrderTradeDate | datetime | YES | - | Same as parent table RecurringInvestment.PlanInstances.OrderTradeDate. The time the order was requested from Trading API. |
| 15 | PositionStatus | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.PositionStatus. Position creation outcome: 1=Success, 2=Failed, etc. |
| 16 | PositionAmountUsd | decimal(18,2) | YES | - | Same as parent table RecurringInvestment.PlanInstances.PositionAmountUsd. Actual position amount in USD. |
| 17 | PositionAmountCurrency | decimal(18,2) | YES | - | Same as parent table RecurringInvestment.PlanInstances.PositionAmountCurrency. Actual position amount in plan currency. |
| 18 | PositionExecutionDate | datetime | YES | - | Same as parent table RecurringInvestment.PlanInstances.PositionExecutionDate. When the position was opened. |
| 19 | PositionFailErrorCode | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.PositionFailErrorCode. Error code from Trading API when position fails. |
| 20 | NotificationSent | bit | YES | - | Same as parent table RecurringInvestment.PlanInstances.NotificationSent. DEPRECATED. Notification flag. |
| 21 | NotificationReason | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.NotificationReason. DEPRECATED. Notification reason code. |
| 22 | InstanceStatus | bit | YES | - | Same as parent table RecurringInvestment.PlanInstances.InstanceStatus. DEPRECATED. Legacy done flag replaced by InstanceStatusID. |
| 23 | UpdateDate | datetime | NO | - | Same as parent table RecurringInvestment.PlanInstances.UpdateDate. Last modification timestamp at the time this row version was current. |
| 24 | Trace | nvarchar(733) | NO | - | Same as parent table RecurringInvestment.PlanInstances.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 25 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 26 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |
| 27 | InstanceStatusReasonID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.InstanceStatusReasonID. Specific reason for the instance's status. Maps to Dictionary.PlanEventCode. |
| 28 | InstanceStatusID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.InstanceStatusID. Instance lifecycle state: 1=Success, 2=Cancelled, 3=Skipped, etc. |
| 29 | MirrorOrderCreated | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.MirrorOrderCreated. Copy trading flag: 1=TRUE when mirror order initiated. NULL for instrument-type plans. |
| 30 | MirrorID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.MirrorID. ID of the mirror/copy relationship. NULL for instrument-type plans. |
| 31 | CopyPositionStatusID | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.CopyPositionStatusID. Copy position step: 1=RegisterSuccess, 2=AddFundsSuccess, 3=RegisterFailed, 4=AddFundFailed. |
| 32 | CopyFailErrorCode | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.CopyFailErrorCode. Error code for copy position failures. |
| 33 | DepositFailReason | int | YES | - | Same as parent table RecurringInvestment.PlanInstances.DepositFailReason. Reason for deposit failure when applicable. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.PlanInstances | System-versioned history | System-versioned history for RecurringInvestment.PlanInstances |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentPlanInstances (history table)
└── RecurringInvestment.PlanInstances (parent, system-versioned)
    └── RecurringInvestment.Plans (via PlanID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentPlanInstances | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |
| IX_HistoryRecurringInvestmentPlanInstancesID | NONCLUSTERED | PlanID ASC, ValidFrom ASC, ValidTo ASC | - | - | - | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they contain multiple historical versions of the same logical row (same InstanceID/PlanID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency. This is important given the high volume of history rows generated by frequent instance updates.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.
- The nonclustered index on (PlanID, ValidFrom, ValidTo) enables efficient history queries filtered by plan, such as "show me all historical states for instances of plan X."

---

## 8. Sample Queries

### 8.1 View the full state history of a specific plan instance
```sql
SELECT InstanceID, PlanID, DepositID, OrderStatusId, PositionStatus,
       InstanceStatusID, ValidFrom, ValidTo
FROM [RecurringInvestment].[PlanInstances]
FOR SYSTEM_TIME ALL
WHERE InstanceID = @InstanceID
ORDER BY ValidFrom
```

### 8.2 See what all instances looked like at a specific point in time
```sql
SELECT InstanceID, PlanID, NextOrderDate, DepositID, OrderStatusId,
       PositionStatus, InstanceStatusID
FROM [RecurringInvestment].[PlanInstances]
FOR SYSTEM_TIME AS OF '2026-04-10 09:00:00'
WHERE PlanID = @PlanID
ORDER BY NextOrderDate DESC
```

### 8.3 Query history table directly for recent changes
```sql
SELECT TOP 100 InstanceID, PlanID, InstanceStatusID, UpdateDate, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentPlanInstances] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentPlanInstances | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentPlanInstances.sql*
