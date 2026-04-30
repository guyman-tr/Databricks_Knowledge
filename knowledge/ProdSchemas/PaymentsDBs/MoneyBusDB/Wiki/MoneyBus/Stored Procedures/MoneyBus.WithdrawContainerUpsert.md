# MoneyBus.WithdrawContainerUpsert

> Creates or updates a withdrawal's SAGA container using MERGE, persisting the execution state JSON and returning the current container data via an output parameter.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE on WithdrawContainers by WithdrawID, OUTPUT @ContainerOutput |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawContainerUpsert creates or updates a withdrawal's SAGA execution state using the MERGE pattern. Functionally identical to ContainerUpsert but for the withdrawal pipeline instead of the transaction pipeline. On the first call (pipeline start), it INSERTs the initial container. On subsequent calls (step completions), it UPDATEs the ContainerData and Modified timestamp.

The current ContainerData is returned via @ContainerOutput, confirming the write succeeded and giving the caller the persisted state.

---

## 2. Business Logic

### 2.1 MERGE Upsert Pattern

**What**: Atomic insert-or-update ensures exactly one container per withdrawal without race conditions.

**Columns/Parameters Involved**: `@WithdrawID`, `@Container`, `@ContainerOutput`

**Rules**:
- WHEN NOT MATCHED: INSERT with WithdrawID, ContainerData, Created = GETUTCDATE()
- WHEN MATCHED: UPDATE ContainerData and Modified = GETUTCDATE()
- OUTPUT INSERTED.ContainerData captured into @Out table variable
- @ContainerOutput set from TOP 1 of @Out
- Mirrors ContainerUpsert but targets WithdrawContainers instead of Containers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | bigint | NO | - | CODE-BACKED | The withdrawal whose container to create or update. Maps to WithdrawContainers.WithdrawID (clustered PK). |
| 2 | @Container | nvarchar(max) | NO | - | CODE-BACKED | The full SAGA execution state JSON. Contains ExecutingPlanName, LastExecutedStep, ContinuePlanQueueMessage, and the Withdraw object snapshot. |
| 3 | @ContainerOutput | nvarchar(max) OUTPUT | NO | - | CODE-BACKED | Returns the persisted ContainerData after the upsert. Confirms the write and provides the committed state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (MERGE target) | MoneyBus.WithdrawContainers | Writer/Modifier | Creates or updates the SAGA container |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawContainerUpsert (procedure)
└── MoneyBus.WithdrawContainers (table) [MERGE INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawContainers | Table | MERGE INTO - atomic insert or update |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create initial withdrawal container
```sql
DECLARE @Output NVARCHAR(MAX);
EXEC MoneyBus.WithdrawContainerUpsert
    @WithdrawID = 773487,
    @Container = '{"TransactionId":773487,"ExecutingPlanName":"withdraw-execute-plan","LastExecutedStep":"holdInitiate"}',
    @ContainerOutput = @Output OUTPUT;
SELECT @Output AS PersistedContainer;
```

### 8.2 Update container with new pipeline state
```sql
DECLARE @Output NVARCHAR(MAX);
EXEC MoneyBus.WithdrawContainerUpsert
    @WithdrawID = 773487,
    @Container = '{"TransactionId":773487,"ExecutingPlanName":"withdraw-execute-plan","LastExecutedStep":"authorizeInitiate"}',
    @ContainerOutput = @Output OUTPUT;
```

### 8.3 Verify state after upsert
```sql
SELECT * FROM MoneyBus.WithdrawContainers WITH (NOLOCK) WHERE WithdrawID = 773487;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawContainerUpsert | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawContainerUpsert.sql*
