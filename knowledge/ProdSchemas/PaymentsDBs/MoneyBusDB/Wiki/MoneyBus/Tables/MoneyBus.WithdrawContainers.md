# MoneyBus.WithdrawContainers

> Stores the JSON execution state (SAGA container) for each withdrawal's pipeline, tracking the executing plan, last completed step, and full request/response context as the withdrawal progresses through hold-authorize-payout steps.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Table |
| **Key Identifier** | WithdrawID (BIGINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered on WithdrawID) |

---

## 1. Business Meaning

MoneyBus.WithdrawContainers stores the runtime execution state for each withdrawal's processing pipeline. The ContainerData JSON blob holds the full SAGA orchestration context - which plan is executing, which step was last completed, queue message payloads, and the complete withdrawal request/response data. This enables the withdrawal service to resume processing from any step if interrupted.

This table exists to support the stateful SAGA pattern used by the withdrawal execution microservice. The withdrawal pipeline (hold -> authorize -> payout) is asynchronous and may span multiple service calls. By persisting the execution state to this table, the service can resume a partially-completed withdrawal from exactly where it left off after a crash, restart, or timeout.

Data flows through ContainerUpsert (MERGE pattern - creates on first step, updates on subsequent steps), ContainerGet (reads current state), and ContainerDelete (cleans up after completion). The WithdrawID is both the PK and the clustered key, optimizing the one-to-one lookup pattern used by the withdrawal service.

---

## 2. Business Logic

### 2.1 SAGA Execution State Persistence

**What**: The ContainerData JSON tracks the pipeline's progress through withdrawal execution steps.

**Columns/Parameters Involved**: `ContainerData`, `WithdrawID`, `Modified`

**Rules**:
- Key JSON fields: ExecutingPlanName ("withdraw-execute-plan"), LastExecutedStep (holdInitiate, authorizeInitiate, payoutFinalize), ContinuePlanQueueMessage, Withdraw (full withdrawal snapshot)
- Created is set on first upsert (initial container creation at pipeline start)
- Modified is updated on each subsequent upsert (as new steps complete)
- Modified=NULL means the container was created but no step has completed yet (still on first step)
- The service reads the container, processes the next step, then upserts the updated state

---

## 3. Data Overview

| ID | WithdrawID | Created | Modified | ContainerData (excerpt) | Meaning |
|---|---|---|---|---|---|
| 773136 | 773515 | 2026-04-15 13:11:01 | NULL | LastExecutedStep: holdInitiate | Withdrawal just started - hold step initiated, no subsequent step completed yet |
| 773128 | 773507 | 2026-04-15 13:09:18 | 2026-04-15 13:09:20 | LastExecutedStep: authorizeInitiate | Withdrawal progressed past hold, now at authorize step - container updated 2 seconds after creation |
| 773115 | 773494 | 2026-04-15 13:05:25 | 2026-04-15 13:05:29 | LastExecutedStep: payoutFinalize | Withdrawal reached payout finalization - final step before completion/cleanup |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate key. Not the clustered key (WithdrawID is). |
| 2 | WithdrawID | bigint | NO | - | CODE-BACKED | FK to MoneyBus.Withdrawals.ID. One-to-one relationship - each withdrawal has exactly one container. Clustered PK for optimal access by the withdrawal service. |
| 3 | Created | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp when the container was first created (pipeline start). Default GETDATE(). |
| 4 | Modified | datetime | YES | - | CODE-BACKED | UTC timestamp of the last container update. NULL when the container has just been created and no step has completed. Updated by WithdrawContainerUpsert via MERGE. |
| 5 | ContainerData | nvarchar(max) | YES | - | CODE-BACKED | JSON blob containing the full SAGA execution state: ExecutingPlanName, LastExecutedStep, ContinuePlanQueueMessage, and the complete Withdraw object snapshot. Updated on each pipeline step completion. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | MoneyBus.Withdrawals | Implicit FK (1:1) | Links the container state to the withdrawal being processed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.WithdrawContainerGet | (whole table) | Reader | Reads container state for pipeline resumption |
| MoneyBus.WithdrawContainerUpsert | (whole table) | Writer/Modifier | Creates/updates container via MERGE |
| MoneyBus.WithdrawContainerDelete | (whole table) | Deleter | Removes container after pipeline completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawContainers (table)
└── MoneyBus.Withdrawals (table) [via WithdrawID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Withdrawals | Table | WithdrawID references Withdrawals.ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawContainerGet | Stored Procedure | Reader |
| MoneyBus.WithdrawContainerUpsert | Stored Procedure | Writer/Modifier (MERGE) |
| MoneyBus.WithdrawContainerDelete | Stored Procedure | Deleter |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawContainers | CLUSTERED PK | WithdrawID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_WithdrawContainers | PRIMARY KEY | Clustered on WithdrawID - one container per withdrawal, optimized for withdrawal-based lookups |
| DF_WithdrawContainers_Created | DEFAULT | GETDATE() for Created |

---

## 8. Sample Queries

### 8.1 Get container with withdrawal status context
```sql
SELECT wc.WithdrawID, wc.Created, wc.Modified, wc.ContainerData,
       w.StatusID, w.StatusReasonID
FROM MoneyBus.WithdrawContainers wc WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wc.WithdrawID
WHERE wc.WithdrawID = @WithdrawID;
```

### 8.2 Find containers still in process (not yet cleaned up)
```sql
SELECT wc.WithdrawID, wc.Created, wc.Modified, w.StatusID, w.StatusReasonID
FROM MoneyBus.WithdrawContainers wc WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wc.WithdrawID
WHERE w.StatusID = 1
ORDER BY wc.Created ASC;
```

### 8.3 Check container age for stale pipeline detection
```sql
SELECT wc.WithdrawID, wc.Created,
       DATEDIFF(MINUTE, wc.Created, GETUTCDATE()) AS AgeMinutes
FROM MoneyBus.WithdrawContainers wc WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wc.WithdrawID
WHERE w.StatusID = 1 AND wc.Created < DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY wc.Created ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawContainers | Type: Table | Source: MoneyBusDB/MoneyBus/Tables/MoneyBus.WithdrawContainers.sql*
