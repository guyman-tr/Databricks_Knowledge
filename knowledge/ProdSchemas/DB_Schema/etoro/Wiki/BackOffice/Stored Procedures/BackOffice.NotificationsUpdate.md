# BackOffice.NotificationsUpdate

> Updates the delivery status and/or retry counter of an existing notification queue record, using ISNULL to apply only the fields the caller provides.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE BackOffice.Notifications WHERE ID = @ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.NotificationsUpdate` is called by the BackOffice notification scheduler after processing a notification delivery attempt. It updates the notification's status (e.g., from Pending to Completed, or from Pending to Failed) and increments the retry counter when a delivery fails. The `LastModificationDate` is always stamped with GETDATE() regardless of which fields are updated.

The procedure exists as the scheduler's write-back path after attempting notification delivery. Without it, queue records would remain in their initial Pending state forever, and the scheduler would repeatedly pick up the same records. The ISNULL pattern allows partial updates: the caller can update only status, only the retry counter, or both, without needing to pass both values when only one changes.

Note: `Set @NotificationID = Scope_Identity()` after an UPDATE is a no-op in SQL Server - SCOPE_IDENTITY() returns the last inserted identity, not the updated row's ID. After an UPDATE, SCOPE_IDENTITY() returns NULL. The `Select @NotificationID` result set will always return NULL from this procedure. The ID tracking is non-functional; callers relying on the returned value should use the input @ID instead.

---

## 2. Business Logic

### 2.1 Partial Update Pattern (ISNULL)

**What**: Either or both of NotificationStatusID and TriesCounter can be updated independently by passing NULL for the field to leave unchanged.

**Columns/Parameters Involved**: `@NotificationStatusID`, `@TriesCounter`, `BackOffice.Notifications.NotificationStatusID`, `BackOffice.Notifications.TriesCounter`

**Rules**:
- `SET NotificationStatusID = ISNULL(@NotificationStatusID, NotificationStatusID)`: if @NotificationStatusID is NULL, the existing value is preserved (self-assignment no-op).
- `SET TriesCounter = ISNULL(@TriesCounter, TriesCounter)`: same pattern for retry counter.
- LastModificationDate is ALWAYS updated to GETDATE() regardless of which fields are actually changing.
- Scheduler behavior: on successful delivery, calls with @NotificationStatusID=3 (Completed), @TriesCounter=NULL. On failure, calls with @NotificationStatusID=4 (Failed/Retry), @TriesCounter=<incremented value>.

**Diagram**:
```
Scheduler delivery attempt result:
  SUCCESS -> NotificationsUpdate(@ID, @NotificationStatusID=3, @TriesCounter=NULL)
             => Status=3(Completed), TriesCounter unchanged, LastModified=now

  FAILURE -> NotificationsUpdate(@ID, @NotificationStatusID=4, @TriesCounter=prev+1)
             => Status=4(Failed/Retry), TriesCounter++, LastModified=now
```

### 2.2 Known Issue: Non-functional @NotificationID Return

**What**: The @NotificationID OUTPUT parameter and SELECT result set always return NULL after this procedure.

**Rules**:
- SCOPE_IDENTITY() returns the last auto-generated IDENTITY value from an INSERT in the current scope. After an UPDATE (no INSERT), it returns NULL.
- The `Set @NotificationID = Scope_Identity()` line produces @NotificationID = NULL.
- The `Select @NotificationID` returns NULL as the result set.
- This is a bug inherited from the pattern used in NotificationsAdd. Callers should not rely on the returned @NotificationID from this procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Primary key of the BackOffice.Notifications record to update. Identifies which queue entry to modify. |
| 2 | @NotificationStatusID | int | YES | NULL | VERIFIED | New delivery status for the notification. NULL = do not change. Values: 1=Pending, 2=InProgress, 3=Completed, 4=Failed/Retry. Applied via ISNULL pattern so only non-NULL values take effect. |
| 3 | @TriesCounter | int | YES | NULL | VERIFIED | New retry attempt count. NULL = do not change. Typically incremented by the caller on failure before passing in. Applied via ISNULL pattern. |
| 4 | @NotificationID | int OUTPUT | - | - | CODE-BACKED | OUTPUT: always returns NULL from this procedure due to SCOPE_IDENTITY() returning NULL after UPDATE (not INSERT). Non-functional. Use input @ID to reference the updated record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ID | BackOffice.Notifications.ID | Modifier | Updates status and retry count on the target notification record |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called by the BackOffice notification scheduler service after delivery attempts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.NotificationsUpdate (procedure)
+-- BackOffice.Notifications (table) [UPDATE target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Notifications | Table | UPDATE - modifies NotificationStatusID, TriesCounter, LastModificationDate |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Mark a notification as successfully delivered

```sql
DECLARE @OutID INT;
EXEC BackOffice.NotificationsUpdate
    @ID = 320201,
    @NotificationStatusID = 3,  -- Completed
    @TriesCounter = NULL,        -- Leave unchanged
    @NotificationID = @OutID OUTPUT;
-- @OutID will be NULL (known limitation)
```

### 8.2 Mark a notification as failed and increment retry counter

```sql
EXEC BackOffice.NotificationsUpdate
    @ID = 320201,
    @NotificationStatusID = 4,  -- Failed/Retry
    @TriesCounter = 2;           -- Second attempt failed
```

### 8.3 Verify the update was applied

```sql
SELECT ID, NotificationStatusID, TriesCounter, LastModificationDate
FROM BackOffice.Notifications WITH (NOLOCK)
WHERE ID = 320201;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.NotificationsUpdate | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.NotificationsUpdate.sql*
