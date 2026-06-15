# Dictionary.PlanEventCode

> Comprehensive event classification table for recurring investment plan lifecycle events, organized by numeric ranges covering successes, failures, cancellations, eligibility, compliance, and position errors.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table is the master event classification system for the entire recurring investment lifecycle. Every significant event that occurs during plan creation, deposit processing, order execution, position opening, eligibility checking, and compliance validation is assigned a code from this table. It serves as the "reason why" behind plan status changes and instance outcomes.

Without this table, the system would have no standardized way to communicate why a plan was cancelled, why an instance was skipped, or why a position failed to open. This information is critical for customer support, automated event handling, notification systems, and compliance auditing.

PlanEventCode is referenced by two columns in PlanInstances: InstanceStatusReasonID (the specific reason for the instance's final status) and the deprecated NotificationReason. It is also referenced by Plans.StatusReasonID (the reason for the plan's current status). The Confluence documentation confirms InstanceStatusReasonID "is the same as PlanEventCode."

---

## 2. Business Logic

### 2.1 Range-Based Event Classification

**What**: Events are organized into numeric ranges that categorize the type and severity of each lifecycle event.

**Columns/Parameters Involved**: `ID`, `EventName`

**Rules**:
- 100-199: Success events (plan creation, deposit, order, position)
- 200-299: Deposit failure events (hard decline, soft decline, generic failure)
- 300-399: Plan cancellation events (by user, by system, by back office, removed MOP)
- 400-499: Plan creation failure events (failed to create, ineligible)
- 500-599: Order issue events (no balance, missed order, duplicate order, user/system cancellation)
- 600-699: Position issue events (open failed, missing data, deadline passed)
- 700-799: User action events (cancel plan by user)
- 800-899: User eligibility events (PI level, verification, player status)
- 900-999: Instrument compatibility events (country restrictions, instrument blacklists)
- 1000-1099: Validation events (invalid deposit plan, plan not active)
- 1100-1199: Compliance gap events (instrument type, leverage, crypto, jurisdiction-specific)
- 1200+: Position open error events (specific Trading API error codes)

### 2.2 Phase Suffixes

**What**: Some event codes include processing phase suffixes indicating which system phase detected the issue.

**Columns/Parameters Involved**: `ID`, `EventName`

**Rules**:
- _Phase02 suffix: Issue detected during Phase 2 processing (early detection)
- _Phase05 suffix: Issue detected during Phase 5 processing (later detection, may indicate escalation)
- Events without phase suffix are phase-independent

---

## 3. Data Overview

| ID | EventName | Meaning |
|----|-----------|---------|
| 100 | CreatePlanSuccess | Plan was successfully created. Initial success event in the lifecycle. |
| 200 | DepositFailedHardDeclineBlocked | Deposit hard-declined by payment processor and user is now blocked from further deposits. Most severe deposit failure. |
| 300 | DepositPlanCancelled | Recurring deposit plan was cancelled. Generic cancellation from Money team. |
| 700 | CancelPlanByUser | User explicitly requested plan cancellation through the UI. |
| 1100 | ComplianceGapInstrumentTypeNotAllowed | Regulatory compliance check failed: instrument type not permitted for user's jurisdiction or classification. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Unique numeric event code. Range-based: 100s=success, 200s=deposit fail, 300s=cancel, 400s=creation fail, 500s=order issues, 600s=position issues, 700s=user actions, 800s=eligibility, 900s=instrument, 1000s=validation, 1100s=compliance, 1200+=position errors. See [Plan Event Code](../../_glossary.md#plan-event-code). |
| 2 | EventName | varchar(50) | NO | - | VERIFIED | Human-readable event name describing the specific lifecycle event. Phase suffixes (_Phase02, _Phase05) indicate detection phase. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.Plans | StatusReasonID | Implicit Lookup | Reason for the plan's current status (e.g., why it was cancelled) |
| RecurringInvestment.PlanInstances | InstanceStatusReasonID | Implicit Lookup | Specific reason for the instance's final status |
| RecurringInvestment.PlanInstances | NotificationReason | Implicit Lookup | DEPRECATED - reason a notification was sent to the user |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.Plans | Table | StatusReasonID references this domain |
| RecurringInvestment.PlanInstances | Table | InstanceStatusReasonID and NotificationReason reference this domain |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PlanEventCode | CLUSTERED PK | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all event codes by range
```sql
SELECT ID, EventName,
  CASE
    WHEN ID < 200 THEN 'Success'
    WHEN ID < 300 THEN 'Deposit Failure'
    WHEN ID < 400 THEN 'Cancellation'
    WHEN ID < 500 THEN 'Creation Failure'
    WHEN ID < 600 THEN 'Order Issue'
    WHEN ID < 700 THEN 'Position Issue'
    WHEN ID < 800 THEN 'User Action'
    WHEN ID < 900 THEN 'Eligibility'
    WHEN ID < 1000 THEN 'Instrument'
    WHEN ID < 1100 THEN 'Validation'
    WHEN ID < 1200 THEN 'Compliance'
    ELSE 'Position Open Error'
  END AS Category
FROM [Dictionary].[PlanEventCode] WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Find instances with failure reasons
```sql
SELECT pi.InstanceID, pi.PlanID, pec.EventName AS Reason, ist.InstanceStatusID AS Status
FROM [RecurringInvestment].[PlanInstances] pi WITH (NOLOCK)
JOIN [Dictionary].[PlanEventCode] pec WITH (NOLOCK) ON pi.InstanceStatusReasonID = pec.ID
JOIN [Dictionary].[InstanceStatusID] ist WITH (NOLOCK) ON pi.InstanceStatusID = ist.ID
WHERE pi.InstanceStatusID NOT IN (1, 5)
```

### 8.3 Top cancellation reasons for plans
```sql
SELECT pec.ID, pec.EventName, COUNT(*) AS PlanCount
FROM [RecurringInvestment].[Plans] p WITH (NOLOCK)
JOIN [Dictionary].[PlanEventCode] pec WITH (NOLOCK) ON p.StatusReasonID = pec.ID
WHERE p.PlanStatusID = 2
GROUP BY pec.ID, pec.EventName
ORDER BY PlanCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Full PlanEventCode table with explanations for each event; StatusReasonID maps to this table; InstanceStatusReasonID "is the same as PlanEventCode" |
| [Recurring Investment Backend HLD](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/12311953523/Recurring+Investment+Backend+HLD) | Confluence | System diagram showing event flows between jobs, handlers, and the database |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 10/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PlanEventCode | Type: Table | Source: RecurringInvestment/Dictionary/Tables/Dictionary.PlanEventCode.sql*
