# Dictionary.StatusReason

> Lookup table providing the specific reason why a recurring plan's status changed, capturing the causality behind transitions from Active to Cancelled, Stopped, or Invalid states.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusReasonID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.StatusReason provides the specific cause for why a recurring payment plan's status changed from Active to a non-active state. While Dictionary.PlanStatus tells you WHAT state the plan is in, StatusReason tells you WHY it got there. This distinction is essential for audit, customer support, and analytics - knowing that a plan is "Cancelled" is less useful than knowing it was "CancelledByUser" vs "CancelledByBO" vs stopped due to "HardDecline."

The five reasons cover the three sources of plan termination: user-initiated (CancelledByUser), system-initiated (RemovedMOP, CanceledInvestment, HardDecline), and operator-initiated (CancelledByBO). Each reason has different implications for customer communication, support workflows, and potential plan recovery.

Note the spelling inconsistency: StatusReasonID=4 is "CanceledInvestment" (single L) while IDs 2 and 3 use "Cancelled" (double L). The PK constraint name "PK_Dictionary_ActionReason" reveals this table was originally called "ActionReason" before being renamed.

---

## 2. Business Logic

### 2.1 Three Sources of Plan Termination

**What**: Plan termination reasons are categorized by who or what triggered the status change - the user, the system, or a back-office operator.

**Columns/Parameters Involved**: `StatusReasonID`, `Name`

**Rules**:
- User-initiated: CancelledByUser (2) - user explicitly requested plan cancellation
- Operator-initiated: CancelledByBO (3) - back-office team canceled the plan (compliance, support, account review)
- System-initiated automatic: RemovedMOP (1) - payment method removed, plan cannot execute
- System-initiated automatic: CanceledInvestment (4) - underlying investment was canceled
- System-initiated from execution: HardDecline (5) - billing provider permanently declined, linking execution-level failure to plan-level status change

**Diagram**:
```
User Action               System Detection           Back-Office Action
     |                         |                          |
     v                         v                          v
CancelledByUser (2)    RemovedMOP (1)              CancelledByBO (3)
                       CanceledInvestment (4)
                       HardDecline (5)
                            |
                            |-- connects to ExecutionResultStatus.HardDecline (ID=3)
                            |   at execution level
```

---

## 3. Data Overview

| StatusReasonID | Name | Meaning |
|---|---|---|
| 1 | RemovedMOP | User's method of payment (credit card, bank account) was removed from their account. Plan cannot execute without a funding source. Triggers automatic plan invalidation. |
| 2 | CancelledByUser | User explicitly requested cancellation of their recurring plan through the platform UI or API. |
| 3 | CancelledByBO | Back-office/operations team manually cancelled the plan. Typical reasons: compliance requirement, support escalation, account review. |
| 4 | CanceledInvestment | The underlying investment was canceled or became unavailable. Applies to RecurringInvestment (ProgramType=2) plans only. Note: single-L "Canceled" spelling inconsistency. |
| 5 | HardDecline | Payment provider permanently declined the charge. Escalated from execution-level HardDecline (ExecutionResultStatus=3) to plan-level status change. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusReasonID | int | NO | - | VERIFIED | Primary key identifying the reason for plan status change. 1=RemovedMOP, 2=CancelledByUser, 3=CancelledByBO, 4=CanceledInvestment, 5=HardDecline. Categorized as user-initiated (2), operator-initiated (3), or system-initiated (1,4,5). See [Status Reason](../../_glossary.md#status-reason) for full definitions. (Dictionary.StatusReason) |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Human-readable label for the status reason. Note: this is the only Dictionary table using nvarchar instead of varchar for the Name column. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Recurring plan tables) | StatusReasonID | Implicit FK | Records why each plan's status changed from Active |
| Dictionary.PlanStatus | (semantic) | Semantic | PlanStatus records the new state; StatusReason records why the transition happened |
| Dictionary.ExecutionResultStatus | (semantic) | Semantic | HardDecline (StatusReason=5) is the plan-level escalation of ExecutionResultStatus.HardDecline (ID=3) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by plan management logic for audit trail and customer communication.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ActionReason | CLUSTERED PK | StatusReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ActionReason | PRIMARY KEY | Legacy constraint name reveals this table was originally "ActionReason" before being renamed to StatusReason |

---

## 8. Sample Queries

### 8.1 List all status reasons
```sql
SELECT StatusReasonID, Name
FROM Dictionary.StatusReason WITH (NOLOCK)
ORDER BY StatusReasonID
```

### 8.2 Categorize reasons by initiator type
```sql
SELECT StatusReasonID, Name,
    CASE
        WHEN StatusReasonID = 2 THEN 'User-Initiated'
        WHEN StatusReasonID = 3 THEN 'Operator-Initiated'
        ELSE 'System-Initiated'
    END AS InitiatorCategory
FROM Dictionary.StatusReason WITH (NOLOCK)
ORDER BY StatusReasonID
```

### 8.3 Distribution of plan cancellation reasons
```sql
SELECT sr.Name AS StatusReason, ps.Name AS PlanStatus, COUNT(*) AS PlanCount
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON p.StatusReasonID = sr.StatusReasonID
INNER JOIN Dictionary.PlanStatus ps WITH (NOLOCK) ON p.PlanStatusID = ps.PlanStatusID
WHERE p.PlanStatusID <> 1 -- Not Active
GROUP BY sr.Name, ps.Name
ORDER BY PlanCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business context: Before Deposit Job checks user eligibility - if not eligible, goes to Control Service, which may set a StatusReason |
| [HLD- Recurring Integration with provider](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1860534325) | Confluence | Business context: HardDecline from providers triggers plan-level action per "error handling according to the Recurring Payments HLD" |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.StatusReason | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.StatusReason.sql*
