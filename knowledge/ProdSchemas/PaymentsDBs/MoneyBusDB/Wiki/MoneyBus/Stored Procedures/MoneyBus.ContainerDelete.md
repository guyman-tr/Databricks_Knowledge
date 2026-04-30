# MoneyBus.ContainerDelete

> Deletes a transaction's SAGA container after the pipeline reaches a terminal state, cleaning up the execution state that is no longer needed.

| Property | Value |
|----------|-------|
| **Schema** | MoneyBus |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from Containers by TransactionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

MoneyBus.ContainerDelete removes a transaction's SAGA execution state container after the transaction reaches a terminal state (Success, Decline, Technical, or Canceled). The transaction pipeline uses MoneyBus.Containers to persist workflow state across async steps; once the pipeline completes, the container is no longer needed and is cleaned up by calling this procedure.

This is part of the Container lifecycle: ContainerUpsert (create/update during pipeline) -> ContainerGet (read for resumption) -> ContainerDelete (cleanup after completion).

---

## 2. Business Logic

No complex business logic. This is a simple DELETE by the clustered PK (TransactionID).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | bigint | NO | - | CODE-BACKED | The transaction whose container should be deleted. Maps to Containers.TransactionID (clustered PK). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE target) | MoneyBus.Containers | Deleter | Removes the SAGA container for the given transaction |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
MoneyBus.ContainerDelete (procedure)
└── MoneyBus.Containers (table) [DELETE FROM]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| MoneyBus.Containers | Table | DELETE FROM - removes container by TransactionID |

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

### 8.1 Delete a container after transaction completion
```sql
EXEC MoneyBus.ContainerDelete @TransactionID = 7747200;
```

### 8.2 Verify container was deleted
```sql
EXEC MoneyBus.ContainerDelete @TransactionID = 7747200;
SELECT * FROM MoneyBus.Containers WITH (NOLOCK) WHERE TransactionID = 7747200;
-- Should return no rows
```

### 8.3 Check for orphaned containers (completed transactions still having containers)
```sql
SELECT c.TransactionID, t.StatusID
FROM MoneyBus.Containers c WITH (NOLOCK)
JOIN MoneyBus.Transactions t WITH (NOLOCK) ON t.ID = c.TransactionID AND t.PartitionCol = c.TransactionID % 100
WHERE t.StatusID IN (2, 3, 4, 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: MoneyBus.ContainerDelete | Type: Stored Procedure | Source: MoneyBusDB/MoneyBus/Stored Procedures/MoneyBus.ContainerDelete.sql*
