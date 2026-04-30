# History.Maintenance

> Trigger-based audit log recording every INSERT, UPDATE, and DELETE made to Billing.Maintenance - the table that controls billing system availability windows and scheduled maintenance periods per funding type.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: ID + Occurred + IsInserted |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID, Occurred, IsInserted) |

---

## 1. Business Meaning

History.Maintenance captures the complete change history of Billing.Maintenance through a DML trigger. Billing.Maintenance controls when billing operations (deposits, withdrawals, payment processing) are available for each funding type - entries can be active, scheduled for maintenance windows, or inactive. Every time an operator adds, modifies, or removes a maintenance window in the billing system, the trigger Tr_Billing_Maintenance writes the old and new state to this history table.

This audit trail matters for billing compliance and incident investigation. If a payment method was unexpectedly unavailable, the team can query this table to see exactly when the maintenance entry was created, what status it was changed to, and at what time. The before/after pair pattern (IsInserted = 0 for old, 1 for new) enables reconstructing the exact state at any point in time without a full temporal table setup.

The insert pattern is trigger-driven and automatic - there is no application or stored procedure that writes directly to History.Maintenance. All writes happen synchronously within the same transaction as the Billing.Maintenance DML.

---

## 2. Business Logic

### 2.1 Inserted/Deleted Pair Pattern - Full Audit Trail

**What**: The trigger writes two rows per UPDATE (the old state with IsInserted=0, the new state with IsInserted=1), one row per INSERT (IsInserted=1), and one row per DELETE (IsInserted=0), creating a complete before/after audit trail using SQL Server's Inserted/Deleted pseudo-tables.

**Columns/Parameters Involved**: `IsInserted`, `ID`, `Occurred`, all data columns

**Rules**:
- INSERT into Billing.Maintenance: one row in History.Maintenance, IsInserted=1, data = new row
- DELETE from Billing.Maintenance: one row in History.Maintenance, IsInserted=0, data = deleted row
- UPDATE to Billing.Maintenance: two rows in History.Maintenance with the same Occurred timestamp; IsInserted=0 = old values (from Deleted pseudo-table), IsInserted=1 = new values (from Inserted pseudo-table)
- Occurred is stamped by DEFAULT = getdate() at insert time (same for both rows of an update pair, since they are in one INSERT...UNION ALL statement)
- The PK (ID, Occurred, IsInserted) prevents exact duplicate rows but allows the same ID to appear multiple times

**Diagram**:
```
Billing.Maintenance UPDATE (ID=25, StatusID 3->1):
  History.Maintenance row 1: IsInserted=0, ID=25, StatusID=3 (old)
  History.Maintenance row 2: IsInserted=1, ID=25, StatusID=1 (new)
  Both have same Occurred timestamp (same trigger execution)

To reconstruct maintenance state at time T:
  Find most recent row WHERE Occurred <= T AND ID = @ID AND IsInserted = 1
  (the latest "new" row before T is the state at T)
```

### 2.2 Billing Maintenance Status Lifecycle

**What**: StatusID tracks the availability state of a funding type's billing service, and changes between statuses are the primary reason this history exists.

**Columns/Parameters Involved**: `StatusID`, `FundingTypeID`, `ScheduledFrom`, `ScheduledTo`

**Rules**:
- StatusID=1 (Active): funding type is available for transactions - normal operating state
- StatusID=3 (UnderMaintenance): funding type is currently unavailable - maintenance in progress
- StatusID=5 (InActive): funding type is permanently disabled - not a temporary outage
- ScheduledFrom/ScheduledTo: planned maintenance window boundaries - NULL when maintenance is immediate/unplanned
- The status transition Active (1) -> UnderMaintenance (3) -> Active (1) represents a planned maintenance cycle

---

## 3. Data Overview

| IsInserted | ID | FundingTypeID | StatusID | ScheduledFrom | ScheduledTo | Meaning |
|---|---|---|---|---|---|---|
| 0 | 1 | 1 | 1 | NULL | NULL | Old state of FundingTypeID=1 (likely default/catch-all funding) before an update. StatusID=1=Active with no maintenance window. Being replaced. |
| 1 | 1 | 1 | 1 | NULL | NULL | New state of FundingTypeID=1 after update. StatusID stayed Active (1), Description unchanged ("")- likely a no-op update from an automated process. |
| 0 | 25 | 1 | 1 | NULL | NULL | Old state of a second Billing.Maintenance entry (ID=25) before update. Same pattern as ID=1. |
| 1 | 25 | 1 | 1 | NULL | NULL | New state of ID=25 after update. Both ID=1 and ID=25 being updated simultaneously suggests an automated heartbeat or polling mechanism updating these records periodically. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Occurred | datetime | NO | getdate() | CODE-BACKED | Local server timestamp when the trigger fired and wrote this history row. For UPDATE operations, both the old (IsInserted=0) and new (IsInserted=1) rows share the same Occurred value (same trigger execution). Note: uses getdate() (local time), not getutcdate(). Part of the composite PK. |
| 2 | IsInserted | bit | NO | - | CODE-BACKED | Indicates whether this row represents the NEW state (1) or OLD state (0) of the Billing.Maintenance record. For INSERT events: only IsInserted=1 rows exist (no prior state). For DELETE events: only IsInserted=0 rows exist. For UPDATE events: both IsInserted=0 (old) and IsInserted=1 (new) exist with the same Occurred timestamp. Part of the composite PK allowing both rows to coexist. |
| 3 | ID | int | NO | - | CODE-BACKED | The primary key from Billing.Maintenance identifying which maintenance configuration was changed. Billing.Maintenance uses IDENTITY(1,2) (increments by 2), so odd IDs are from the initial sequence. Part of the composite PK here. Referenced via implicit relationship - no FK enforced since history rows must persist even after source rows are deleted. |
| 4 | FundingTypeID | int | NO | - | CODE-BACKED | The funding/payment method type being managed. References a funding type classification for the billing system (e.g., credit card, bank transfer, crypto). No FK enforced in this history table. Matches the FundingTypeID in Billing.Maintenance which is the source of truth. |
| 5 | StatusID | int | NO | - | CODE-BACKED | Availability status of the funding type: 1=Active (available for transactions), 3=UnderMaintenance (temporarily unavailable), 5=InActive (permanently disabled). Source: Dictionary.BillingMaintenanceStatus. No FK enforced here (historical values must remain even if dictionary changes). |
| 6 | ScheduledFrom | datetime | YES | - | CODE-BACKED | Start of the planned maintenance window, if this was a scheduled outage. NULL for immediate/unplanned maintenance or when no window was set. Copied verbatim from Billing.Maintenance at time of the DML operation. |
| 7 | ScheduledTo | datetime | YES | - | CODE-BACKED | End of the planned maintenance window. NULL for open-ended maintenance or when no end time was set. Together with ScheduledFrom defines the planned outage window for compliance and customer communication. |
| 8 | Description | nvarchar(500) | YES | - | CODE-BACKED | Free-text description of the maintenance event or reason for the status change. Up to 500 Unicode characters. Empty string ("") or NULL for programmatic/automated updates with no human-entered context. Meaningful values are entered by operators when manually scheduling maintenance windows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ID | Billing.Maintenance | Implicit (trigger source) | Each row traces back to a specific Billing.Maintenance record. No FK enforced - history rows persist after source is deleted. |
| StatusID | Dictionary.BillingMaintenanceStatus | Implicit lookup | 1=Active, 3=UnderMaintenance, 5=InActive. FK exists on Billing.Maintenance but not enforced here. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Maintenance | Tr_Billing_Maintenance (trigger) | Writer | The ONLY writer - trigger fires on INSERT/UPDATE/DELETE and writes to this table automatically |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Maintenance (table)
  - No code-level dependencies (leaf table, populated by trigger)
  - Source: Billing.Maintenance (table) via Tr_Billing_Maintenance trigger
```

### 6.1 Objects This Depends On

No dependencies. Written automatically by trigger.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Maintenance | Table | Source table - trigger Tr_Billing_Maintenance fires on all DML and writes to this history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_History_Maintenance | CLUSTERED | ID ASC, Occurred ASC, IsInserted ASC | - | - | Active |

FILLFACTOR: 95% - high fill factor appropriate for an append-only log with no updates. PAGE compression applied.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_History_Maintenance | PRIMARY KEY | Composite on (ID, Occurred, IsInserted) - prevents exact duplicates while allowing multiple versions of same ID |
| Df_History_Maintenance_Occurred | DEFAULT | Occurred = getdate() - server local time applied automatically by trigger insert |

---

## 8. Sample Queries

### 8.1 Get full change history for a specific maintenance entry

```sql
SELECT
    ID,
    Occurred,
    CASE IsInserted WHEN 1 THEN 'New' WHEN 0 THEN 'Old' END AS RowState,
    FundingTypeID,
    StatusID,
    ScheduledFrom,
    ScheduledTo,
    Description
FROM [History].[Maintenance] WITH (NOLOCK)
WHERE ID = 25
ORDER BY Occurred ASC, IsInserted ASC
```

### 8.2 Reconstruct the current (or point-in-time) state of all maintenance entries

```sql
-- Latest state of each maintenance entry as of now
SELECT
    ID,
    FundingTypeID,
    StatusID,
    ScheduledFrom,
    ScheduledTo,
    Description,
    Occurred AS LastChangedAt
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ID ORDER BY Occurred DESC) AS rn
    FROM [History].[Maintenance] WITH (NOLOCK)
    WHERE IsInserted = 1
) t
WHERE rn = 1
ORDER BY ID
```

### 8.3 Find all maintenance status transitions (Active <-> UnderMaintenance) with before/after

```sql
SELECT
    old_row.ID,
    old_row.FundingTypeID,
    old_row.StatusID AS OldStatusID,
    new_row.StatusID AS NewStatusID,
    old_row.Occurred AS ChangedAt
FROM [History].[Maintenance] old_row WITH (NOLOCK)
JOIN [History].[Maintenance] new_row WITH (NOLOCK)
    ON new_row.ID = old_row.ID
    AND new_row.Occurred = old_row.Occurred
    AND new_row.IsInserted = 1
WHERE old_row.IsInserted = 0
  AND old_row.StatusID <> new_row.StatusID
ORDER BY old_row.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (trigger-written) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Maintenance | Type: Table | Source: etoro/etoro/History/Tables/History.Maintenance.sql*
