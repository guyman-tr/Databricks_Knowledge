# RecurringInvestment.PlansGetPlansMissingDepositPlanID

> Retrieves non-cancelled plans that are missing a valid RecurringDepositID, indicating they failed to link to a deposit plan during creation.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters, returns plans with missing deposit linkage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a recurring investment plan is created, it must be linked to a recurring deposit plan managed by the Money Group service. The RecurringDepositID column in the Plans table stores this linkage. If the deposit plan creation fails or the linkage is not established, the plan cannot execute its deposit cycle.

This procedure identifies plans that are in this broken state -- they exist as active (or other non-cancelled) plans but have no valid RecurringDepositID. The Create Plan Job uses this procedure to find such plans and retry the deposit plan creation/linkage process.

A RecurringDepositID is considered missing if it is NULL, 0, or -1 (sentinel values indicating failure or uninitialized state).

Created per EDGE-3688 (Nilly Meyrav & Noga, 02/06/2024).

---

## 2. Business Logic

### 2.1 Missing Deposit Plan Detection

**What**: Finds plans where RecurringDepositID is not set to a valid value.

**Columns/Parameters Involved**: `RecurringDepositID`, `PlanStatusID`

**Rules**:
- RecurringDepositID IS NULL -- never set
- OR RecurringDepositID = 0 -- initialized but not linked
- OR RecurringDepositID = -1 -- explicit failure sentinel
- AND PlanStatusID <> 2 -- exclude cancelled plans (no point retrying for cancelled plans)
- Only reads from the Plans table; no instance data is needed

### 2.2 Exclusion of Cancelled Plans

**What**: Excludes cancelled plans from the result set since they do not need repair.

**Columns/Parameters Involved**: `PlanStatusID`

**Rules**:
- PlanStatusID <> 2 filters out cancelled plans
- Active plans (1), initializing plans, and any other non-cancelled status are included
- This ensures the Create Plan Job only retries linkage for plans that will actually execute

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
| 5 | RecurringDepositID | int | YES | - | VERIFIED | Will be NULL, 0, or -1 (the missing/invalid values that triggered inclusion). |
| 6 | Amount | decimal(18,2) | NO | - | VERIFIED | Investment amount per cycle in plan currency. |
| 7 | CurrencyID | int | NO | - | VERIFIED | Currency of the Amount. |
| 8 | PlanStatusID | int | NO | - | VERIFIED | Plan status (never 2/Cancelled). See [Plan Status](../../_glossary.md#plan-status). |
| 9 | StatusReasonID | int | YES | - | VERIFIED | Reason for current status. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 10 | CreationDate | datetime | NO | - | VERIFIED | When the plan was created. |
| 11 | EndDate | datetime | YES | - | VERIFIED | When the plan was cancelled. Expected NULL for non-cancelled plans. |
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
| - | RecurringInvestment.Plans | Read | Single table read with missing-deposit filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Create Plan Job | - | EXEC | Finds plans needing deposit plan linkage retry |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.PlansGetPlansMissingDepositPlanID (procedure)
└── RecurringInvestment.Plans (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | SELECT FROM with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Create Plan Job | Application | Scheduled job for deposit plan linkage repair |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- All reads use NOLOCK hints
- No transaction wrapper (read-only procedure)
- Simple single-table query with no joins
- Three-way OR condition for missing RecurringDepositID (NULL, 0, -1)

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC [RecurringInvestment].[PlansGetPlansMissingDepositPlanID]
```

### 8.2 Check count of plans missing deposit linkage
```sql
SELECT COUNT(*) AS MissingDepositCount
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE (RecurringDepositID IS NULL OR RecurringDepositID = 0 OR RecurringDepositID = -1)
  AND PlanStatusID <> 2
```

### 8.3 Breakdown by plan status
```sql
SELECT PlanStatusID, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] WITH (NOLOCK)
WHERE (RecurringDepositID IS NULL OR RecurringDepositID = 0 OR RecurringDepositID = -1)
  AND PlanStatusID <> 2
GROUP BY PlanStatusID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798) | Confluence | RecurringDepositID column purpose, plan creation flow |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Create Plan Job architecture and deposit plan linkage |
| [EDGE-3688](https://etoro-jira.atlassian.net/browse/EDGE-3688) | Jira | Plan creation job and deposit plan linkage implementation |

---

*Generated: 2026-04-13 | Quality: 9.0/10*
*Object: RecurringInvestment.PlansGetPlansMissingDepositPlanID | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.PlansGetPlansMissingDepositPlanID.sql*
