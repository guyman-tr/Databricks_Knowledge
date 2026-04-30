# MoneyBus.ContainerUpsert

> Creates or updates a transaction's SAGA container using MERGE, persisting the execution state JSON and returning the current container data via an output parameter.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE on Containers by TransactionID, OUTPUT @ContainerOutput |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.ContainerUpsert creates or updates a transaction's SAGA execution state using the MERGE pattern. On the first call for a transaction (pipeline start), it INSERTs the initial container with the Created timestamp. On subsequent calls (pipeline step completions), it UPDATEs the ContainerData JSON and Modified timestamp. The current ContainerData is returned via the @ContainerOutput parameter for the caller to use.

This is the write path of the Container lifecycle. Called at each step transition by the transaction execution service to persist the updated pipeline state before acknowledging the step completion.

---

## 2. Business Logic

### 2.1 MERGE Upsert Pattern

**What**: Atomic insert-or-update ensures exactly one container per transaction without race conditions.

**Columns/Parameters Involved**: `@TransactionID`, `@Container`, `@ContainerOutput`

**Rules**:
- WHEN NOT MATCHED (first call): INSERT with TransactionID, ContainerData, Created = GETUTCDATE()
- WHEN MATCHED (subsequent calls): UPDATE ContainerData and Modified = GETUTCDATE()
- OUTPUT INSERTED.ContainerData is captured into @Out table variable
- @ContainerOutput is set from the first row of @Out (there's always exactly one)
- This ensures the caller gets the persisted state back, confirming the write succeeded

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | bigint | NO | - | CODE-BACKED | The transaction whose container to create or update. Maps to Containers.TransactionID (clustered PK). |
| 2 | @Container | nvarchar(max) | NO | - | CODE-BACKED | The full SAGA execution state JSON to persist. Contains _transactionId, User, TransactionRequestMessage, and pipeline progress. |
| 3 | @ContainerOutput | nvarchar(max) OUTPUT | NO | - | CODE-BACKED | Returns the persisted ContainerData after the upsert. Confirms the write and provides the caller with the committed state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (MERGE target) | MoneyBus.Containers | Writer/Modifier | Creates or updates the SAGA container |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.ContainerUpsert (procedure)
└── MoneyBus.Containers (table) [MERGE INTO]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Containers | Table | MERGE INTO - atomic insert or update |

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

### 8.1 Create initial container
```sql
DECLARE @Output NVARCHAR(MAX);
EXEC MoneyBus.ContainerUpsert
    @TransactionID = 7747200,
    @Container = '{"_transactionId":7747200,"User":{"GCID":12345}}',
    @ContainerOutput = @Output OUTPUT;
SELECT @Output AS PersistedContainer;
```

### 8.2 Update existing container with new pipeline state
```sql
DECLARE @Output NVARCHAR(MAX);
EXEC MoneyBus.ContainerUpsert
    @TransactionID = 7747200,
    @Container = '{"_transactionId":7747200,"User":{"GCID":12345},"LastStep":"debitComplete"}',
    @ContainerOutput = @Output OUTPUT;
```

### 8.3 Verify container state after upsert
```sql
SELECT * FROM MoneyBus.Containers WITH (NOLOCK) WHERE TransactionID = 7747200;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.ContainerUpsert | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.ContainerUpsert.sql*
