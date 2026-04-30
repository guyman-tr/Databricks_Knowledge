# BackOffice.CleanupMessageQueue

> Maintenance procedure that purges orphaned message queue records from Customer.MessageQueue - messages that have no corresponding customer link in Customer.CustomerToMessageQueue.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - operates on full table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a maintenance cleanup job that removes orphaned records from the messaging system. `Customer.MessageQueue` holds message definitions, while `Customer.CustomerToMessageQueue` creates the many-to-many links between customers and messages. When a message exists in MessageQueue but has no customer link in CustomerToMessageQueue, it is an orphan - no customer will ever receive it, so it should be deleted to keep the table clean.

The procedure is designed to run as a scheduled maintenance task (SQL Agent job or similar). It uses `DEADLOCK_PRIORITY -10` to declare itself a low-priority process willing to be chosen as the deadlock victim, preventing it from blocking normal transactional traffic. The temp table staging approach (collect IDs first, then delete) is a two-phase pattern that avoids long-running DELETE scans and provides a checkpoint.

The double NOT EXISTS check (once during staging, again during DELETE) is a safety net against race conditions where new links might be created between the staging and delete phases.

---

## 2. Business Logic

### 2.1 Orphan Detection and Staged Deletion

**What**: Uses a temp table to collect orphaned MessageQueueIDs, then deletes them with a second NOT EXISTS verification.

**Columns/Parameters Involved**: `Customer.MessageQueue.MessageQueueID`, `Customer.CustomerToMessageQueue.MessageQueueID`

**Rules**:
- Phase 1 (Staging): SELECT MessageQueueID from Customer.MessageQueue WHERE NOT EXISTS any row in Customer.CustomerToMessageQueue with the same MessageQueueID
- Phase 2 (Delete): Only executes if @@ROWCOUNT > 0 from staging (at least one orphan found)
- Phase 2 uses a second NOT EXISTS check during DELETE as a race-condition guard
- Returns @ErrorLocal (@@ERROR from the DELETE phase): 0 on success, non-zero on failure
- DEADLOCK_PRIORITY -10: this proc yields in deadlock situations, protecting transactional traffic

**Diagram**:
```
Customer.MessageQueue
  |  NOT EXISTS in Customer.CustomerToMessageQueue?
  v
#RecordsToDelete (temp - MessageQueueID list)
  |  IF @@ROWCOUNT > 0
  v
DELETE Customer.MessageQueue
  WHERE MessageQueueID IN #RecordsToDelete
  AND NOT EXISTS in CustomerToMessageQueue  (race-condition safety net)
  -> Returns @@ERROR
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | RETURN | INT | @ErrorLocal = @@ERROR after DELETE phase: 0 on success or when no orphans exist (skip DELETE); non-zero SQL error code on DELETE failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.MessageQueue | DELETER | Removes orphaned message records (no customer link) |
| - | Customer.CustomerToMessageQueue | Lookup (NOT EXISTS) | Used to identify orphans: MessageQueue records with no matching CustomerToMessageQueue row |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called by scheduled maintenance job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CleanupMessageQueue (procedure)
|- Customer.MessageQueue (table) [DELETE target - orphaned message records, cross-schema]
+-- Customer.CustomerToMessageQueue (table) [NOT EXISTS check - identifies orphans, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.MessageQueue | Table | SELECT (orphan detection) + DELETE (orphan removal) |
| Customer.CustomerToMessageQueue | Table | NOT EXISTS subquery to identify MessageQueue records with no customer links |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled maintenance job | External | Called periodically to keep Customer.MessageQueue free of orphaned records |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEADLOCK_PRIORITY -10 | Design | Maintenance proc declares itself lowest priority deadlock victim; will yield to transactional traffic |
| Double NOT EXISTS | Design | Race-condition guard: orphan check is repeated during DELETE in case new links were created between staging and delete |
| Temp table staging | Design | #RecordsToDelete collects IDs before deletion; avoids long-running table scan during DELETE |
| Skips DELETE if empty | Design | IF @@ROWCOUNT > 0 guard prevents unnecessary DELETE execution when no orphans exist |

---

## 8. Sample Queries

### 8.1 Run the cleanup manually

```sql
DECLARE @Result INT
EXEC @Result = BackOffice.CleanupMessageQueue
SELECT @Result AS CleanupResult -- 0 = success
```

### 8.2 Check for orphaned message queue records before running

```sql
SELECT COUNT(*) AS OrphanCount
FROM Customer.MessageQueue MQ WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Customer.CustomerToMessageQueue CC2Q WITH (NOLOCK)
    WHERE MQ.MessageQueueID = CC2Q.MessageQueueID
)
```

### 8.3 Check message queue health

```sql
SELECT
    (SELECT COUNT(*) FROM Customer.MessageQueue WITH (NOLOCK)) AS TotalMessages,
    (SELECT COUNT(*) FROM Customer.CustomerToMessageQueue WITH (NOLOCK)) AS TotalLinks,
    (SELECT COUNT(*) FROM Customer.MessageQueue MQ WITH (NOLOCK)
     WHERE NOT EXISTS (SELECT 1 FROM Customer.CustomerToMessageQueue CC2Q WITH (NOLOCK)
                       WHERE MQ.MessageQueueID = CC2Q.MessageQueueID)) AS OrphanedMessages
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CleanupMessageQueue | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CleanupMessageQueue.sql*
