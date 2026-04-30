# RecurringInvestment.PlansGetActivePlansToCreateNewInstanceRecord

> Retrieves active recurring investment plans that need a new instance record created, either because their latest instance is completed and overdue, or because they have no instances at all.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters, returns plans needing new instances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the engine behind the Plan Instances Job. It identifies all active recurring investment plans that are due for a new execution cycle. The recurring investment system works by creating "instance" records for each execution cycle of a plan (deposit, order, position). This procedure finds plans where the system needs to create the next instance record.

There are two scenarios where a new instance is needed: (a) the plan has existing instances but the latest one has reached a terminal status and the NextOrderDate has passed, meaning it is time for the next cycle; (b) the plan was just created and has no instances at all yet. The UNION ALL of these two queries covers both cases.

Created per EDGE-3688 (Nilly Ron, 04/07/2024). Restored 27/3/25 after being temporarily removed.

---

## 2. Business Logic

### 2.1 Plans with Completed Instances Overdue for New Cycle

**What**: Finds active plans whose latest instance has completed and whose NextOrderDate is in the past.

**Columns/Parameters Involved**: `PlanStatusID`, `InstanceStatusID`, `NextOrderDate`, `PlanID`

**Rules**:
- INNER JOIN Plans to PlanInstances to find plans with existing instances
- Subquery finds MAX(NextOrderDate) per PlanID to identify the latest instance
- Latest instance must have Max_NextOrderDate < GETUTCDATE() (overdue)
- Plan must be active: PlanStatusID = 1
- Latest instance must be in a terminal status: InstanceStatusID IN (1, 3, 4, 6, 7)
  - 1 = Completed, 3 = Skipped, 4 = Failed, 6 = Cancelled, 7 = DepositFailed
- These statuses indicate the instance lifecycle is done and the plan is ready for its next cycle

### 2.2 Plans with No Instances at All

**What**: Finds active plans that have never had an instance created.

**Columns/Parameters Involved**: `PlanStatusID`, `InstanceID`, `PlanID`

**Rules**:
- LEFT JOIN Plans to PlanInstances
- WHERE PI.InstanceID IS NULL filters to plans with zero instances
- Plan must be active: PlanStatusID = 1
- This covers newly created plans that have not yet had their first execution cycle initiated

### 2.3 UNION ALL Combination

**What**: Combines both scenarios into a single result set.

**Rules**:
- UNION ALL (not UNION) is used because the two sets are mutually exclusive (one has instances, the other does not) and deduplication is unnecessary
- Both SELECT statements return the same column list from the Plans table

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Parameters**:

None. This procedure takes no input parameters.

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanID | int | NO | - | VERIFIED | Plans.ID - unique plan identifier. |
| 2 | GCID | bigint | NO | - | VERIFIED | User's Global Customer ID. |
| 3 | CID | bigint | YES | - | VERIFIED | User's Customer ID. |
| 4 | InstrumentID | int | YES | - | VERIFIED | Instrument for instrument-type plans. NULL for copy plans. |
| 5 | RecurringDepositID | int | YES | - | VERIFIED | Linked recurring deposit plan ID from Money Group. |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in plan currency. |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Always 1 (Active) due to filter. See [Plan Status](../../_glossary.md#plan-status). |
| 9 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 10 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 11 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. Always NULL here (active plans). |
| 12 | DepositStartDate | datetime | YES | - | VERIFIED | When the first deposit occurred. |
| 13 | FrequencyID | int | NO | - | VERIFIED | Execution frequency. See [Plan Frequencies](../../_glossary.md#plan-frequencies). |
| 14 | RepeatsOn | int | NO | - | VERIFIED | Day of month for execution. |
| 15 | HasBackupPayment | bit | YES | - | VERIFIED | Whether fallback payment is configured. |
| 16 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 17 | FundingID | int | YES | - | VERIFIED | Payment method ID. |
| 18 | CopyType | int | NO | - | VERIFIED | Copy trading type. See [Copy Type](../../_glossary.md#copy-type). |
| 19 | PlanType | int | NO | - | VERIFIED | Instrument (1) or Copy (2). See [Plan Type](../../_glossary.md#plan-type). |
| 20 | CopyParentCID | bigint | YES | - | VERIFIED | Copied trader's CID. |
| 21 | CopyParentGCID | bigint | YES | - | VERIFIED | Copied trader's GCID. |
| 22 | MopType | int | NO | - | VERIFIED | Payment method type. See [MOP Type](../../_glossary.md#mop-type). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.Plans | Read | Main data source, filtered by PlanStatusID = 1 |
| - | RecurringInvestment.PlanInstances | Read (INNER JOIN + LEFT JOIN) | Checks instance existence and latest status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Plan Instances Job | - | EXEC | Scheduled job that creates new instance records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetActivePlansToCreateNewInstanceRecord (procedure)
├── RecurringInvestment.Plans (table)
└── RecurringInvestment.PlanInstances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | SELECT FROM with NOLOCK |
| RecurringInvestment.PlanInstances | Table | INNER JOIN (first query) and LEFT JOIN (second query) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Plan Instances Job | Application | Calls this SP to find plans needing new instances |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints for performance
- No transaction wrapper (read-only procedure)
- Subquery aggregation uses MAX(NextOrderDate) to identify the latest instance per plan

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC [RecurringInvestment].[PlansGetActivePlansToCreateNewInstanceRecord]
```

### 8.2 Verify which plans have completed latest instances
```sql
SELECT PI.PlanID, MAX(PI.NextOrderDate) AS LatestNextOrderDate, PI.InstanceStatusID
FROM [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK)
INNER JOIN [RecurringInvestment].[Plans] P WITH (NOLOCK) ON P.ID = PI.PlanID
WHERE P.PlanStatusID = 1
  AND PI.InstanceStatusID IN (1, 3, 4, 6, 7)
GROUP BY PI.PlanID, PI.InstanceStatusID
HAVING MAX(PI.NextOrderDate) < GETUTCDATE()
```

### 8.3 Check plans with no instances
```sql
SELECT P.ID AS PlanID, P.GCID, P.PlanStatusID
FROM [RecurringInvestment].[Plans] P WITH (NOLOCK)
LEFT JOIN [RecurringInvestment].[PlanInstances] PI WITH (NOLOCK) ON P.ID = PI.PlanID
WHERE PI.InstanceID IS NULL AND P.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | Plans and PlanInstances table structure, instance lifecycle statuses |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Plan Instances Job architecture and instance creation flow |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Original implementation of instance creation job |

---

*Generated: 2026-04-13 | Quality: 9.2/10*
*Object: RecurringInvestment.PlansGetActivePlansToCreateNewInstanceRecord | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetActivePlansToCreateNewInstanceRecord.sql*
