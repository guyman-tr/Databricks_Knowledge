# Dictionary.InstanceStatusID

> Lookup table defining lifecycle states for recurring investment plan instances - from in-progress through success, skip, cancellation, or failure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table describes the lifecycle state of a single plan instance - one execution cycle of a recurring investment plan. Each month (or cycle), a plan generates an instance that progresses through deposit, order, and position stages. This table classifies the final outcome of that instance.

Without this table, the system could not distinguish why an instance did not result in a position - whether it succeeded, was skipped by the system or user, failed technically, or completed the deposit but could not open a position. This distinction is critical for customer-facing status displays, retry logic, and operational reporting.

Instance status is written by the recurring investment backend service during the plan execution pipeline. The status is set as the instance progresses through Before Deposit Job, Deposit Message Handler, Order Execution Job, and the position confirmation flow. The InstanceStatusReasonID column (referencing Dictionary.PlanEventCode) provides the specific reason behind the status.

---

## 2. Business Logic

### 2.1 Instance Lifecycle States

**What**: Seven-state model covering all possible outcomes of a recurring investment cycle.

**Columns/Parameters Involved**: `ID`, `InstanceStatusID` (name column)

**Rules**:
- InProgress (5) is the only non-terminal state - instance is actively executing
- Success (1) means the full cycle completed: deposit -> order -> position opened
- Cancelled (2) means the instance was cancelled before completion (system or business rule)
- Skipped (3) vs UserSkipped (4): system-initiated vs user-initiated skip
- Technical Issue (6) means a system error prevented completion
- Completed without position (7) means deposit succeeded but no position opened (order cancelled/expired/rejected)

**Diagram**:
```
Instance Created --> InProgress (5)
    |
    +-- Full cycle success --> Success (1)
    |
    +-- System skip (eligibility, blacklist) --> Skipped (3)
    |
    +-- User skip --> UserSkipped (4)
    |
    +-- System/business cancel --> Cancelled (2)
    |
    +-- System error --> Technical Issue (6)
    |
    +-- Deposit OK but order failed --> Completed without position (7)
```

---

## 3. Data Overview

| ID | InstanceStatusID | Meaning |
|----|------------------|---------|
| 1 | Success | Instance completed the full recurring investment cycle: deposit received, order placed and filled, position successfully opened. The user's automated investment executed as planned. |
| 2 | Cancelled | Instance was cancelled before it could complete, either by a system rule (e.g., plan cancellation propagation) or a business condition. No position was opened. |
| 3 | Skipped | Instance was automatically skipped by the system due to a failing eligibility check, blacklist match, or other automated rule. The plan remains active for the next cycle. |
| 4 | UserSkipped | Instance was explicitly skipped at the user's request. The user chose not to execute this cycle but keeps the plan active for future cycles. |
| 5 | InProgress | Instance is currently executing - deposit, order, or position step is underway. This is the only non-terminal state. |
| 6 | Techenical Issue | Instance failed due to a technical/system error such as service unavailability, timeout, or unexpected exception. Note: original spelling ("Techenical") preserved from source data. |
| 7 | Completed without position | Instance completed the deposit successfully but no position was opened - the order was cancelled, expired, or rejected. The user's money was deposited but the investment did not execute. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric identifier for the instance status. 1=Success, 2=Cancelled, 3=Skipped, 4=UserSkipped, 5=InProgress, 6=Technical Issue, 7=Completed without position. See [Instance Status](../../_glossary.md#instance-status). |
| 2 | InstanceStatusID | varchar(50) | NO | - | VERIFIED | Human-readable label for the instance lifecycle state. Note: column name matches table name, which is a naming convention anomaly - this is the descriptive label, not a foreign key. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.PlanInstances | InstanceStatusID | Implicit Lookup | Tracks the lifecycle state of each plan instance cycle |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.PlanInstances | Table | InstanceStatusID column references this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_InstanceStatusID | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all instance statuses
```sql
SELECT ID, InstanceStatusID AS StatusName
FROM [Dictionary].[InstanceStatusID] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find non-successful instances with their reasons
```sql
SELECT pi.InstanceID, pi.PlanID, ist.InstanceStatusID AS StatusName,
       pec.EventName AS ReasonName
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[InstanceStatusID] ist WITH (NOLOCK) ON pi.InstanceStatusID = ist.ID
LEFT JOIN [Dictionary].[PlanEventCode] pec WITH (NOLOCK) ON pi.InstanceStatusReasonID = pec.ID
WHERE pi.InstanceStatusID NOT IN (1, 5)
```

### 8.3 Count instances by status
```sql
SELECT ist.ID, ist.InstanceStatusID AS StatusName, COUNT(*) AS InstanceCount
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[InstanceStatusID] ist WITH (NOLOCK) ON pi.InstanceStatusID = ist.ID
GROUP BY ist.ID, ist.InstanceStatusID
ORDER BY ist.ID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | InstanceStatusID based on Dictionary table; InstanceStatusReasonID is same as PlanEventCode |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | Instance lifecycle through Create Plan Job, Deposit Handler, Order Execution Job |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.InstanceStatusID | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.InstanceStatusID.sql*
