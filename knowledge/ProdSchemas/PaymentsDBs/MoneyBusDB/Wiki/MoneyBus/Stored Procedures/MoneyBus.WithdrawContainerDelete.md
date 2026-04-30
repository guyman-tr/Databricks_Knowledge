# MoneyBus.WithdrawContainerDelete

> Deletes a withdrawal's SAGA container after the pipeline reaches a terminal state, cleaning up the execution state and returning the count of deleted rows.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from WithdrawContainers by WithdrawID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.WithdrawContainerDelete removes a withdrawal's SAGA execution state container after the withdrawal reaches a terminal state (Success, Decline, Technical, or Cancelled). Part of the WithdrawContainer lifecycle: WithdrawContainerUpsert (create/update) -> WithdrawContainerGet (read) -> WithdrawContainerDelete (cleanup).

Uses TRY/CATCH with RAISERROR for error propagation. Returns @@ROWCOUNT as DeletedCount (0 or 1) for caller verification. Returns 0 for success, -1 for error.

---

## 2. Business Logic

No complex business logic. Simple DELETE with error handling.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WithdrawID | bigint | NO | - | CODE-BACKED | The withdrawal whose container should be deleted. Maps to WithdrawContainers.WithdrawID (clustered PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE target) | MoneyBus.WithdrawContainers | Deleter | Removes the SAGA container for the given withdrawal |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.WithdrawContainerDelete (procedure)
└── MoneyBus.WithdrawContainers (table) [DELETE FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.WithdrawContainers | Table | DELETE FROM - removes container by WithdrawID |

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

### 8.1 Delete a withdrawal container
```sql
EXEC MoneyBus.WithdrawContainerDelete @WithdrawID = 773487;
```

### 8.2 Verify deletion
```sql
EXEC MoneyBus.WithdrawContainerDelete @WithdrawID = 773487;
SELECT * FROM MoneyBus.WithdrawContainers WITH (NOLOCK) WHERE WithdrawID = 773487;
```

### 8.3 Find orphaned containers
```sql
SELECT wc.WithdrawID, w.StatusID
FROM MoneyBus.WithdrawContainers wc WITH (NOLOCK)
JOIN MoneyBus.Withdrawals w WITH (NOLOCK) ON w.ID = wc.WithdrawID
WHERE w.StatusID IN (2, 3, 4, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.WithdrawContainerDelete | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.WithdrawContainerDelete.sql*
