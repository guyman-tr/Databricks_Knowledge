# History.RecurringInvestmentPlans

> System-versioned temporal history table storing previous row versions from RecurringInvestment.Plans - tracks the full history of every plan modification including amount changes, status changes, and cancellations.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Parent Table** | RecurringInvestment.Plans |
| **Partition** | No |
| **Indexes** | 1 clustered on (ValidTo, ValidFrom) + 1 nonclustered on (ID, ValidFrom, ValidTo) |
| **Data Compression** | PAGE |

---

## 1. Business Meaning

This is the SQL Server system-versioned (temporal) history table for `RecurringInvestment.Plans`. It automatically stores previous versions of rows from the parent table whenever a row is updated or deleted. Each row in this table represents a past state of a recurring investment plan configuration, bounded by the ValidFrom and ValidTo period columns.

Plans are the core configuration entity in the Recurring Investment system. When a user changes their investment amount, when a plan's status changes from Active to Cancelled, or when deposit plan linkages are modified, the previous state of the plan is preserved here. This provides a complete audit trail of every plan's configuration over time.

Key business events that generate history rows include:
- **Amount changes**: When a user modifies their recurring investment amount, the previous amount is preserved.
- **Status transitions**: When a plan moves from Active (1) to Cancelled (2), the active state is preserved with its exact timestamps.
- **Cancellation reasons**: StatusReasonID changes are captured, showing the progression of events leading to plan cancellation.
- **Deposit plan updates**: Changes to RecurringDepositID, FundingID, or MopType are tracked.

This table is never written to directly by application code. All inserts are handled automatically by the SQL Server temporal table mechanism.

---

## 2. Business Logic

No independent business logic. This table is a passive recipient of historical row versions managed entirely by SQL Server's SYSTEM_VERSIONING mechanism. Each row captures the exact configuration of a plan at a specific point in time.

Rows appear here in two scenarios:
- **UPDATE on parent**: The pre-update version of the row is inserted here with ValidTo set to the update timestamp. This is the primary flow - plan configuration changes, status transitions, and amount modifications all trigger history rows.
- **DELETE on parent**: The deleted row is inserted here with ValidTo set to the deletion timestamp.

The sequence of history rows for a single plan tells the complete story of that plan's lifecycle - from creation through any modifications to its current or final state.

---

## 3. Data Overview

Rows in this table represent previous configurations of recurring investment plans. A single plan ID may appear many times, each with different column values.

| ID | GCID | Amount | PlanStatusID | StatusReasonID | ValidFrom | ValidTo | Meaning |
|----|------|--------|--------------|----------------|-----------|---------|---------|
| 76747 | 24776282 | 25.00 | 1 | 100 | 2025-09-01 | 2026-01-15 | Plan 76747 was originally $25/month. User later changed to $50 (the current value in parent). |
| 76733 | 40359244 | 200.00 | 1 | 100 | 2025-07-01 | 2026-03-01 | Plan 76733 was active during this period. A modification at ValidTo created this history row. |
| 500 | 12345678 | 100.00 | 1 | 100 | 2024-06-01 | 2025-02-15 | Plan 500 was active, then cancelled. The active state is preserved here. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Description |
|---|---------|------|----------|---------|-------------|
| 1 | ID | int | NO | - | Same as parent table RecurringInvestment.Plans.ID. Unique identifier for the recurring investment plan. Not an identity column in the history table. |
| 2 | GCID | bigint | NO | - | Same as parent table RecurringInvestment.Plans.GCID. Global Customer ID of the user who owns this plan. |
| 3 | CID | bigint | YES | - | Same as parent table RecurringInvestment.Plans.CID. Customer ID - alternate user identifier. |
| 4 | InstrumentID | int | YES | - | Same as parent table RecurringInvestment.Plans.InstrumentID. ID of the instrument for Instrument-type plans (PlanType=1). NULL for Copy-type plans. |
| 5 | RecurringDepositID | int | YES | - | Same as parent table RecurringInvestment.Plans.RecurringDepositID. ID of the linked Recurring Deposit Plan from MIMO/Money Group. |
| 6 | Amount | decimal(18,2) | NO | - | Same as parent table RecurringInvestment.Plans.Amount. Investment amount per cycle in the plan's CurrencyID at the time this row version was current. |
| 7 | CurrencyID | int | NO | - | Same as parent table RecurringInvestment.Plans.CurrencyID. Currency of the plan's Amount. |
| 8 | PlanStatusID | int | NO | - | Same as parent table RecurringInvestment.Plans.PlanStatusID. Lifecycle state: 0=Initializing, 1=Active, 2=Cancelled. |
| 9 | DepositPlanStatusID | int | YES | - | Same as parent table RecurringInvestment.Plans.DepositPlanStatusID. DEPRECATED. Status of the linked recurring deposit plan. |
| 10 | StatusReasonID | int | YES | - | Same as parent table RecurringInvestment.Plans.StatusReasonID. Reason for the plan status at this point in time. Maps to Dictionary.PlanEventCode. |
| 11 | CreationDate | datetime | NO | - | Same as parent table RecurringInvestment.Plans.CreationDate. When the plan was originally created. |
| 12 | EndDate | datetime | YES | - | Same as parent table RecurringInvestment.Plans.EndDate. When the plan was cancelled. NULL while active. |
| 13 | DepositStartDate | datetime | YES | - | Same as parent table RecurringInvestment.Plans.DepositStartDate. When the plan's first deposit occurred or was scheduled. |
| 14 | FrequencyID | int | NO | - | Same as parent table RecurringInvestment.Plans.FrequencyID. Execution cadence: 3=Monthly. |
| 15 | RepeatsOn | int | NO | - | Same as parent table RecurringInvestment.Plans.RepeatsOn. Day of the month when the plan executes (1-28). |
| 16 | FundingID | int | YES | - | Same as parent table RecurringInvestment.Plans.FundingID. ID of the plan's payment method. |
| 17 | Trace | nvarchar(733) | NO | - | Same as parent table RecurringInvestment.Plans.Trace, but stored as nvarchar(733) NOT computed (unlike the parent's computed column). Contains JSON with HostName, AppName, SUserName, SPID, DBName, ObjectName captured at the time the row was current. |
| 18 | ValidFrom | datetime2(7) | NO | - | Period start - the point in time when this row version became the "current" version in the parent table. |
| 19 | ValidTo | datetime2(7) | NO | - | Period end - the point in time when this row version was superseded by an update or deleted from the parent table. |
| 20 | PlanType | int | NO | - | Same as parent table RecurringInvestment.Plans.PlanType. Plan classification: 1=Instrument, 2=Copy. |
| 21 | CopyParentCID | bigint | YES | - | Same as parent table RecurringInvestment.Plans.CopyParentCID. CID of the trader being copied. NULL for Instrument-type plans. |
| 22 | CopyParentGCID | bigint | YES | - | Same as parent table RecurringInvestment.Plans.CopyParentGCID. GCID of the trader being copied. NULL for Instrument-type plans. |
| 23 | CopyType | int | NO | - | Same as parent table RecurringInvestment.Plans.CopyType. Copy relationship type: 0=None, 1=PI, 4=SmartPortfolio. |
| 24 | HasBackupPayment | bit | YES | - | Same as parent table RecurringInvestment.Plans.HasBackupPayment. Whether the plan has a fallback payment method. |
| 25 | MopType | int | NO | - | Same as parent table RecurringInvestment.Plans.MopType. Method of Payment type for deposits. |
| 26 | AmountUsd | decimal(18,2) | YES | - | Same as parent table RecurringInvestment.Plans.AmountUsd. Investment amount per cycle in USD. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | RecurringInvestment.Plans | System-versioned history | System-versioned history for RecurringInvestment.Plans |

### 5.2 Referenced By (other objects point to this)

No other tables reference this history table directly. History tables are queried via `FOR SYSTEM_TIME` clauses on the parent table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RecurringInvestmentPlans (history table)
└── RecurringInvestment.Plans (parent, system-versioned)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | Parent table - this history table receives rows automatically via SYSTEM_VERSIONING |

### 6.2 Objects That Depend On This

No objects depend directly on this history table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Compression | Status |
|-----------|------|-------------|-----------------|--------|-------------|--------|
| ix_RecurringInvestmentPlans | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | PAGE | Active |
| IX_HistoryRecurringInvestmentPlansID | NONCLUSTERED | ID ASC, ValidFrom ASC, ValidTo ASC | - | - | - | Active |

### 7.2 Constraints

No primary key constraints. History tables do not enforce PK uniqueness because they contain multiple historical versions of the same logical row (same plan ID with different validity periods).

### 7.3 Storage

- DATA_COMPRESSION = PAGE on the table and clustered index for storage efficiency.
- The clustered index on (ValidTo, ValidFrom) is optimized for temporal query patterns, enabling efficient point-in-time lookups.
- The nonclustered index on (ID, ValidFrom, ValidTo) enables efficient history queries filtered by plan ID, such as "show me all historical configurations for plan X."

---

## 8. Sample Queries

### 8.1 View the full configuration history of a specific plan
```sql
SELECT ID, GCID, InstrumentID, Amount, CurrencyID, PlanStatusID,
       StatusReasonID, EndDate, ValidFrom, ValidTo
FROM [RecurringInvestment].[Plans]
FOR SYSTEM_TIME ALL
WHERE ID = @PlanID
ORDER BY ValidFrom
```

### 8.2 Find what a plan looked like at a specific point in time
```sql
SELECT ID, GCID, Amount, CurrencyID, PlanStatusID, PlanType, CopyType
FROM [RecurringInvestment].[Plans]
FOR SYSTEM_TIME AS OF '2025-12-01'
WHERE ID = @PlanID
```

### 8.3 Query history table directly for recently modified plans
```sql
SELECT TOP 100 ID, GCID, Amount, PlanStatusID, StatusReasonID, ValidFrom, ValidTo
FROM [History].[RecurringInvestmentPlans] WITH (NOLOCK)
ORDER BY ValidTo DESC
```

### 8.4 Track amount changes for a plan over time
```sql
SELECT ID, Amount, AmountUsd, CurrencyID, ValidFrom, ValidTo
FROM [RecurringInvestment].[Plans]
FOR SYSTEM_TIME ALL
WHERE ID = @PlanID
ORDER BY ValidFrom
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources specific to this history table. See parent table documentation for business context.

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: History.RecurringInvestmentPlans | Type: Table | Source: RecurringInvestment/History/Tables/History.RecurringInvestmentPlans.sql*
