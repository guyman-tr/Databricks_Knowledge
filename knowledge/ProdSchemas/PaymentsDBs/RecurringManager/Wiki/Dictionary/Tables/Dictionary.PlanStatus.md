# Dictionary.PlanStatus

> Lookup table representing the lifecycle state of a recurring payment plan - the top-level entity governing whether executions continue to be scheduled.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PlanStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.PlanStatus represents the lifecycle state of a recurring payment plan - the top-level entity that controls whether the scheduling engine continues to create new execution records. Only Active plans generate new scheduled executions; all other states prevent new charges from being created.

This table governs the user-facing state of their recurring deposit or investment subscription. A plan starts as Active, and can transition to Cancelled (user or back-office initiated), Stopped (system-initiated due to repeated failures), Invalid (configuration problem detected), or Paused (temporary suspension that can be resumed).

The reason for a plan leaving Active status is tracked separately in Dictionary.StatusReason, which provides the causality behind the transition (e.g., RemovedMOP, CancelledByUser, HardDecline).

---

## 2. Business Logic

### 2.1 Plan Lifecycle State Machine

**What**: Plans follow a state machine where only Active state generates new executions, with multiple exit paths depending on the cause.

**Columns/Parameters Involved**: `PlanStatusID`, `Name`

**Rules**:
- Active (1) is the only state that generates new scheduled executions
- Paused (5) is the only reversible non-active state - designed for temporary holds, can resume to Active
- Cancelled (2) vs Stopped (3) distinction: Cancelled is typically user-initiated or back-office initiated; Stopped is typically system-initiated (repeated failures)
- Invalid (4) indicates automated validation detected a configuration problem (e.g., payment method removed, regulatory restriction)
- StatusReason table provides the specific cause for each transition out of Active

**Diagram**:
```
              +--------> Cancelled (2)
              |            (user/BO initiated - StatusReason 2,3)
              |
Active (1) ---+--------> Stopped (3)
              |            (system-initiated - StatusReason 5)
              |
              +--------> Invalid (4)
              |            (config problem - StatusReason 1,4)
              |
              +<-------> Paused (5)
                           (temporary hold - reversible)
```

---

## 3. Data Overview

| PlanStatusID | Name | Meaning |
|---|---|---|
| 1 | Active | Plan is running normally. New executions will be scheduled according to the plan's frequency. The only state that generates charges. |
| 2 | Cancelled | Plan permanently terminated. No further executions. Typically initiated by user (StatusReason=2) or back-office (StatusReason=3). |
| 3 | Stopped | Plan stopped, usually system-initiated due to repeated payment failures. Differs from Cancelled in that it signals a system action, not a user choice. |
| 4 | Invalid | Plan configuration is invalid (e.g., payment method removed, investment no longer available). Cannot process. May auto-transition when validation detects problems. |
| 5 | Paused | Plan temporarily suspended. Can be resumed to Active without recreating the plan. The only non-terminal non-active state. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PlanStatusID | int | NO | - | VERIFIED | Primary key identifying the plan lifecycle state. 1=Active (generates executions), 2=Cancelled (permanent, user/BO), 3=Stopped (permanent, system), 4=Invalid (config error), 5=Paused (temporary, reversible). See [Plan Status](../../_glossary.md#plan-status) for full definitions. (Dictionary.PlanStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the plan status. Values: "Active", "Cancelled", "Stopped", "Invalid", "Paused". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Recurring plan tables) | PlanStatusID | Implicit FK | Tracks the current lifecycle state of each recurring payment plan |
| Dictionary.StatusReason | (semantic) | Semantic | StatusReason provides the causality for why a plan left Active status - the two tables work together |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by the plan management logic to control execution scheduling.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PlanStatus | CLUSTERED PK | PlanStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PlanStatus | PRIMARY KEY | Ensures each plan status has a unique integer identifier |

---

## 8. Sample Queries

### 8.1 List all plan statuses
```sql
SELECT PlanStatusID, Name
FROM Dictionary.PlanStatus WITH (NOLOCK)
ORDER BY PlanStatusID
```

### 8.2 Count plans by status
```sql
SELECT ps.Name AS PlanStatus, COUNT(*) AS PlanCount
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.PlanStatus ps WITH (NOLOCK) ON p.PlanStatusID = ps.PlanStatusID
GROUP BY ps.Name
ORDER BY PlanCount DESC
```

### 8.3 Find non-active plans with their status reasons
```sql
SELECT p.PaymentId, ps.Name AS PlanStatus, sr.Name AS StatusReason
FROM Recurring.Payment p WITH (NOLOCK)
INNER JOIN Dictionary.PlanStatus ps WITH (NOLOCK) ON p.PlanStatusID = ps.PlanStatusID
LEFT JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON p.StatusReasonID = sr.StatusReasonID
WHERE p.PlanStatusID <> 1 -- Not Active
ORDER BY ps.Name, sr.Name
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523) | Confluence | Business glossary: "Active Plan = A running plan that is still active"; Before Deposit Job checks eligibility of users with active plans |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlanStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.PlanStatus.sql*
