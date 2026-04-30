# Trade.AcknowledgeMessagesBSLTest

> Test/alternate version of BSL message acknowledgement that reverses the DML order (DELETE before UPDATE) and uses READPAST hints instead of NOLOCK for concurrent queue processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IDs (Trade.IdIntList TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a **test variant** of `Trade.AcknowledgeMessagesBSL` that experiments with two changes to the acknowledgement logic: (1) reversing the DML order so the BSLQueue DELETE executes before the ManageBSL UPDATE, and (2) using `READPAST` hints instead of `NOLOCK` on both tables.

The `READPAST` hint skips rows that are currently locked by other transactions, which is appropriate for queue-processing patterns where multiple consumers may dequeue concurrently. This prevents blocking between concurrent acknowledgement calls, whereas the production version might block briefly on locked rows.

This procedure follows the same BSL message lifecycle as the production version: BSL consumer collects processed message IDs, packages them into a TVP, and calls this procedure to mark them complete. The reversed order (delete from queue first, then timestamp acknowledgement) may have been tested to reduce the window during which a message is both in the queue and not yet acknowledged.

---

## 2. Business Logic

### 2.1 Reversed DML Order vs Production

**What**: Unlike the production procedure which UPDATEs ManageBSL first then DELETEs from BSLQueue, this variant DELETEs from BSLQueue first.

**Columns/Parameters Involved**: `@IDs`, `Trade.BSLQueue.ID`, `Trade.ManageBSL.TimeMessageWasAck`

**Rules**:
- DELETE from BSLQueue (with READPAST) executes first - removes queue entry
- UPDATE on ManageBSL (with READPAST) executes second - sets TimeMessageWasAck = GETUTCDATE()
- Both are in a single transaction - atomicity is preserved
- READPAST hint on both tables allows concurrent dequeue operations without blocking

**Diagram**:
```
Production (AcknowledgeMessagesBSL):      Test (AcknowledgeMessagesBSLTest):
  BEGIN TRAN                                BEGIN TRAN
    1. UPDATE ManageBSL (NOLOCK)              1. DELETE BSLQueue (READPAST)
    2. IF EXISTS -> DELETE BSLQueue            2. UPDATE ManageBSL (READPAST)
  COMMIT                                    COMMIT
```

### 2.2 READPAST Queue Pattern

**What**: READPAST hints enable lock-free concurrent queue consumption.

**Columns/Parameters Involved**: `Trade.BSLQueue`, `Trade.ManageBSL`

**Rules**:
- READPAST skips locked rows rather than waiting or reading dirty data
- Prevents multiple consumers from processing the same message simultaneously
- No existence check before DELETE (unlike production) - the DELETE simply affects zero rows if the IDs are not in BSLQueue

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IDs | Trade.IdIntList (TVP) | NO | - | VERIFIED | Table-valued parameter containing ManageBSL.ID values of messages to acknowledge. Same TVP type as the production version. Clustered PK on Id (bigint) prevents duplicates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IDs.Id | Trade.ManageBSL.ID | JOIN (UPDATE) | Matches input IDs to BSL messages to set acknowledgement timestamp |
| @IDs.Id | Trade.BSLQueue.ID | JOIN (DELETE) | Matches input IDs to transient queue entries for removal |
| @IDs | Trade.IdIntList | Parameter (TVP) | Uses the generic bigint ID list type as input |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AcknowledgeMessagesBSL | - | Production variant | This is the test version of that production procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AcknowledgeMessagesBSLTest (procedure)
+-- Trade.BSLQueue (table)
+-- Trade.ManageBSL (table)
+-- Trade.IdIntList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.BSLQueue | Table | DELETE - removes processed queue entries (READPAST) |
| Trade.ManageBSL | Table | UPDATE - sets TimeMessageWasAck (READPAST) |
| Trade.IdIntList | User Defined Type | READONLY TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRY/CATCH | Wraps DELETE and UPDATE in a single transaction. ROLLBACK on first error (@@TRANCOUNT = 1), COMMIT on nested (@@TRANCOUNT > 1), then THROW. |

---

## 8. Sample Queries

### 8.1 Test acknowledgement with READPAST behavior

```sql
DECLARE @MsgIDs Trade.IdIntList;
INSERT INTO @MsgIDs (Id)
SELECT  TOP 100 M.ID
FROM    Trade.ManageBSL M WITH (NOLOCK)
WHERE   M.TimeMessageWasAck IS NULL
        AND M.TimeMessageWasRecieved IS NOT NULL;

EXEC Trade.AcknowledgeMessagesBSLTest @IDs = @MsgIDs;
```

### 8.2 Compare pending counts before and after acknowledgement

```sql
SELECT  'Before' AS Stage,
        COUNT(*) AS PendingInQueue
FROM    Trade.BSLQueue WITH (NOLOCK);

-- Execute acknowledgement, then:
SELECT  'After' AS Stage,
        COUNT(*) AS PendingInQueue
FROM    Trade.BSLQueue WITH (NOLOCK);
```

### 8.3 Verify READPAST skip behavior under concurrent load

```sql
SELECT  M.ID,
        M.TimeMessageWasAck,
        CASE WHEN Q.ID IS NULL THEN 'Dequeued' ELSE 'Still queued' END AS QueueStatus
FROM    Trade.ManageBSL M WITH (NOLOCK)
        LEFT JOIN Trade.BSLQueue Q WITH (NOLOCK) ON M.ID = Q.ID
WHERE   M.TimeMessageWasAck IS NOT NULL
        AND M.TimeMessageWasAck >= DATEADD(MINUTE, -5, GETUTCDATE())
ORDER BY M.TimeMessageWasAck DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AcknowledgeMessagesBSLTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AcknowledgeMessagesBSLTest.sql*
