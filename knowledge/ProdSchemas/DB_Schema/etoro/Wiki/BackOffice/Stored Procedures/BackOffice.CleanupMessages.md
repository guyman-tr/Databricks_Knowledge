# BackOffice.CleanupMessages

> Maintenance procedure that removes expired message links from Customer.CustomerToMessageQueue in batches of 1000, cleaning up customer-to-message associations where the message's ValidTo timestamp has passed.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - time-based cleanup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the expiry-based cleanup counterpart to `BackOffice.CleanupMessageQueue`. While CleanupMessageQueue removes messages with no customer links (orphan cleanup), CleanupMessages removes customer-to-message links where the message's ValidTo timestamp has expired. Together they keep the messaging system clean.

The target is `Customer.CustomerToMessageQueue` - the link table between customers and messages. When a message's ValidTo passes (GETUTCDATE() > ValidTo), any customer-to-message link pointing to that expired message is no longer needed. This procedure deletes those expired links in batches of 1000, preventing large single-transaction deletes that could cause blocking or log growth.

Note: This procedure does NOT delete from `Customer.MessageQueue` itself - it only removes the customer association links. The expired MessageQueue records themselves will be removed by `BackOffice.CleanupMessageQueue` as orphans (once all customer links are gone).

---

## 2. Business Logic

### 2.1 Expired Link Detection and Batch Deletion

**What**: Collects all CustomerToMessageQueue links pointing to expired messages, then deletes them in batches of 1000.

**Columns/Parameters Involved**: `Customer.MessageQueue.ValidTo`, `Customer.CustomerToMessageQueue.MessageQueueID`, `Customer.CustomerToMessageQueue.CID`

**Rules**:
- Staging: SELECT CID + MessageQueueID from Customer.CustomerToMessageQueue where the linked MessageQueue.ValidTo < GETUTCDATE()
- Stores results in temp table #TmpDeleteMessageQueue with a status column (0=pending, 1=processing)
- Batch loop: WHILE @@ROWCOUNT > 0 (from initial INSERT):
  - UPDATE TOP(1000) rows in temp table to status=1 (mark for deletion)
  - DELETE Customer.CustomerToMessageQueue WHERE temp.status=1
  - DELETE processed rows from temp table (status=1 rows)
  - Loop continues until all batches processed
- No RETURN statement - returns NULL

**Diagram**:
```
Customer.CustomerToMessageQueue (CTMQ)
  |  JOIN Customer.MessageQueue WHERE ValidTo < GETUTCDATE()
  v
#TmpDeleteMessageQueue (CID, MessageQueueID, status=0)
  |
WHILE rows remain:
  UPDATE TOP(1000) status = 1
  DELETE Customer.CustomerToMessageQueue WHERE status=1
  DELETE #TmpDeleteMessageQueue WHERE status=1
  (continue until empty)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters and no return value.

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 1 | RETURN | (none) | No RETURN statement - returns NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.CustomerToMessageQueue | DELETER | Removes expired message links (cross-schema) |
| - | Customer.MessageQueue | Lookup (JOIN) | Reads ValidTo to determine which links have expired (cross-schema) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called by scheduled maintenance job alongside CleanupMessageQueue.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CleanupMessages (procedure)
|- Customer.CustomerToMessageQueue (table) [DELETE target - expired links, cross-schema]
+-- Customer.MessageQueue (table) [ValidTo JOIN - identifies expired messages, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerToMessageQueue | Table | DELETE target: removes rows where linked message has expired |
| Customer.MessageQueue | Table | JOIN to read ValidTo: identifies messages past their expiry time |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled maintenance job | External | Called periodically to remove expired customer-message associations; typically paired with CleanupMessageQueue |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Batch size 1000 | Design | Deletes 1000 rows per iteration to prevent large transactions and reduce blocking/log pressure |
| ValidTo < GETUTCDATE() | Business | Expiry check uses UTC time; MessageQueue.ValidTo must be UTC for correct behavior |
| No MessageQueue deletion | Design | Only CustomerToMessageQueue links are deleted; MessageQueue records become orphans and are removed by CleanupMessageQueue |
| Status column pattern | Design | Uses status=0/1 in temp table for batch marking; allows safe iterative processing |
| No RETURN code | Design | No error handling or return value; failures propagate as unhandled exceptions |

---

## 8. Sample Queries

### 8.1 Run the cleanup manually

```sql
EXEC BackOffice.CleanupMessages
-- No return value; check row counts before/after
```

### 8.2 Check how many expired links exist before cleanup

```sql
SELECT COUNT(*) AS ExpiredLinkCount
FROM Customer.CustomerToMessageQueue CTMQ WITH (NOLOCK)
WHERE EXISTS (
    SELECT 1 FROM Customer.MessageQueue CMSQ WITH (NOLOCK)
    WHERE CMSQ.ValidTo < GETUTCDATE()
      AND CTMQ.MessageQueueID = CMSQ.MessageQueueID
)
```

### 8.3 Typical maintenance sequence (run CleanupMessages before CleanupMessageQueue)

```sql
-- Step 1: Remove expired customer-to-message links
EXEC BackOffice.CleanupMessages

-- Step 2: Remove orphaned message queue records (now without links)
DECLARE @Result INT
EXEC @Result = BackOffice.CleanupMessageQueue
SELECT @Result AS CleanupResult
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.9/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CleanupMessages | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CleanupMessages.sql*
