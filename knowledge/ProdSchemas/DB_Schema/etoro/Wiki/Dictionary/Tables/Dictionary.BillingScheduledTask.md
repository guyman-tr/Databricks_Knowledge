# Dictionary.BillingScheduledTask

> Lookup table defining the 8 scheduled task types in the Billing subsystem — covering deposit tracking, analytics integrations, and monitoring processes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TaskID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.BillingScheduledTask enumerates the types of background jobs (scheduled tasks) that run within the Billing subsystem. Each row identifies a specific automated process — such as sending deposit events to AppsFlyer for attribution, publishing first-time deposit (FTD) events to RabbitMQ, firing deposit tracking pixels, or running deposit monitoring processes.

These task type IDs are referenced when logging scheduled task executions, tracking task status, or configuring task-specific behavior. The billing engine uses these identifiers to distinguish which job is running, allowing monitoring dashboards and alert systems to report on each task type individually.

Rows are manually inserted with explicit TaskID values (not identity). No other tables or procedures in the current SSDT project directly reference this table via FK, suggesting it is consumed by application-layer scheduling code or a logging table outside the current project scope.

---

## 2. Business Logic

### 2.1 Billing Task Categories

**What**: Three functional categories of billing scheduled tasks.

**Columns/Parameters Involved**: `TaskID`, `TaskName`

**Rules**:
- **Analytics & Attribution (1, 3, 4)**: Tasks that fire deposit-related events to external analytics platforms — AppsFlyer (mobile attribution), DepositPixel (conversion tracking), MixPanel (user analytics).
- **Event Publishing (2, 6)**: Tasks that publish deposit lifecycle events to message queues — RabbitMqFtd pushes first-time deposit events, FirstApprovedWtf pushes first-approved withdrawal events.
- **Core Billing (5, 7, 8)**: Tasks that handle internal billing processes — DepositDR (deposit dispute resolution), Deposit (core deposit processing), MonitorProcessing (health monitoring for billing pipeline).

**Diagram**:
```
BillingScheduledTask
├── Analytics & Attribution
│   ├── 1: AppsFlyer (mobile attribution)
│   ├── 3: DepositPixel (conversion tracking)
│   └── 4: MixPanel (user analytics)
├── Event Publishing
│   ├── 2: RabbitMqFtd (first-time deposit events)
│   └── 6: FirstApprovedWtf (first-approved withdrawal)
└── Core Billing
    ├── 5: DepositDR (deposit dispute resolution)
    ├── 7: Deposit (core deposit processing)
    └── 8: MonitorProcessing (pipeline health)
```

---

## 3. Data Overview

| TaskID | TaskName | Meaning |
|---|---|---|
| 1 | AppsFlyer | Sends deposit event data to AppsFlyer for mobile app install attribution — tracks which marketing campaigns led to depositing users. |
| 2 | RabbitMqFtd | Publishes first-time deposit (FTD) events to a RabbitMQ message queue — downstream consumers use FTD events for sales attribution, bonus eligibility, and onboarding flows. |
| 5 | DepositDR | Processes deposit dispute resolution cases — handles chargebacks, reversed transactions, and deposit-related discrepancies. |
| 7 | Deposit | Core deposit processing task — likely handles batched deposit confirmations, status updates, or deposit finalization steps. |
| 8 | MonitorProcessing | Health monitoring for the billing processing pipeline — detects stuck transactions, delayed confirmations, or processing failures. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TaskID | int | NO | - | CODE-BACKED | Primary key identifying the scheduled task type. Manually assigned values 1-8. Referenced by billing scheduling infrastructure to identify which background job is executing. |
| 2 | TaskName | varchar(50) | YES | - | VERIFIED | PascalCase name of the scheduled task (e.g., 'AppsFlyer', 'RabbitMqFtd', 'MonitorProcessing'). Used as a human-readable identifier in logs, dashboards, and monitoring alerts. Nullable but all 8 production rows have values. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No FK references found in the SSDT project. Likely consumed by application-layer scheduling code.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | TaskID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all billing scheduled tasks
```sql
SELECT  TaskID,
        TaskName
FROM    Dictionary.BillingScheduledTask WITH (NOLOCK)
ORDER BY TaskID;
```

### 8.2 Find analytics-related tasks
```sql
SELECT  TaskID,
        TaskName
FROM    Dictionary.BillingScheduledTask WITH (NOLOCK)
WHERE   TaskName IN ('AppsFlyer', 'DepositPixel', 'MixPanel')
ORDER BY TaskID;
```

### 8.3 Find task by name pattern
```sql
SELECT  TaskID,
        TaskName
FROM    Dictionary.BillingScheduledTask WITH (NOLOCK)
WHERE   TaskName LIKE '%Deposit%'
ORDER BY TaskID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.BillingScheduledTask | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.BillingScheduledTask.sql*
