# Dictionary.PlanStatus

> Lookup table defining lifecycle states for recurring investment plans - from initialization through active execution, cancellation, or stop.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table describes the lifecycle state of a recurring investment plan. The plan status controls whether the system creates new instances, processes deposits, and places orders. It is the primary control mechanism for the plan's operational state.

Without this table, the system could not distinguish between active plans that should generate instances and inactive plans that should be ignored. The unique constraint on the Plans table (GCID+InstrumentID+PlanStatusID+CopyParentGCID WHERE PlanStatusID=1) ensures only one active plan per user per instrument per copy parent.

PlanStatusID is set during plan creation (initially 0=Initializing, then 1=Active on success) and updated by the PlanUpdate and PlansCancelAllUserPlansUpdateInstanceStatus stored procedures. The Before Deposit Job, Plan Instances Job, and Create Plan Job all filter on PlanStatusID=1 to find active plans.

---

## 2. Business Logic

### 2.1 Plan Lifecycle State Machine

**What**: Five-state model (three in active use) controlling plan operational behavior.

**Columns/Parameters Involved**: `ID`, `StatusName`, `Plans.StatusReasonID`

**Rules**:
- Initializing (0): Plan creation started but failed to complete - NOT a normal entry state, indicates something went wrong (per Confluence)
- Active (1): Only status that generates new instances and processes deposits
- Cancelled (2): Terminal state - plan cannot be reactivated. StatusReasonID (PlanEventCode) captures why
- Stopped (3): NOT currently in use (per Confluence). Reserved for future pause/resume
- Invalid (4): NOT currently in use (per Confluence). Reserved for configuration issues
- Confluence also mentions Paused (5) which is NOT in the DB table

**Diagram**:
```
Plan Creation
    |
    +-- Failed --> Initializing (0) [stuck]
    |
    +-- Success --> Active (1) [operational]
                      |
                      +-- User cancels --> Cancelled (2) [terminal]
                      +-- System cancels --> Cancelled (2) [terminal]
                      +-- BO cancels --> Cancelled (2) [terminal]
```

---

## 3. Data Overview

| ID | StatusName | Meaning |
|----|------------|---------|
| 0 | Initializing | Plan creation started but something went wrong during the process (per Confluence). The plan never fully activated. This is NOT a normal transitional state - it indicates a failed creation attempt. |
| 1 | Active | Plan is fully active and executing. New instances will be created on schedule, deposits will be processed, and orders will be placed. The only status that drives plan execution. |
| 2 | Cancelled | Plan has been permanently cancelled and cannot be reactivated. The StatusReasonID (PlanEventCode) captures the specific reason - user request (700), system rule (300-303), compliance (800-1100), etc. |
| 3 | Stopped | NOT currently in use (per Confluence). Reserved status, potentially for future pause/resume functionality where a user could temporarily halt and later reactivate a plan. |
| 4 | Invalid | NOT currently in use (per Confluence). Reserved status for plans with configuration or eligibility issues that prevent operation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the plan status. 0=Initializing (failed creation), 1=Active (only operational status), 2=Cancelled (terminal), 3=Stopped (unused), 4=Invalid (unused). See [Plan Status](../../_glossary.md#plan-status). |
| 2 | StatusName | varchar(50) | NO | - | VERIFIED | Human-readable label for the plan lifecycle state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | PlanStatusID | Implicit Lookup | Controls the operational state of each recurring investment plan |
| RecurringInvestment.Plans | DepositPlanStatusID | Implicit Lookup | DEPRECATED - status of the linked recurring deposit plan |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | PlanStatusID and DepositPlanStatusID columns reference this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlanStatus | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all plan statuses
```sql
SELECT ID, StatusName
FROM [Dictionary].[PlanStatus] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count plans by status
```sql
SELECT ps.ID, ps.StatusName, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanStatus] ps WITH (NOLOCK) ON p.PlanStatusID = ps.ID
GROUP BY ps.ID, ps.StatusName
ORDER BY ps.ID
```

### 8.3 Find active plans with user details
```sql
SELECT p.ID AS PlanID, p.GCID, p.InstrumentID, ps.StatusName,
       p.Amount, p.CurrencyID, p.CreationDate
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanStatus] ps WITH (NOLOCK) ON p.PlanStatusID = ps.ID
WHERE p.PlanStatusID = 1
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Full PlanStatus table with descriptions; Initializing means "something went wrong"; Stopped/Invalid/Paused are "not in use" |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Active Plan defined as "A running plan that is still active"; jobs filter on PlanStatusID=1 |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlanStatus | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.PlanStatus.sql*
