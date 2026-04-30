# Billing.UpsertNotificationMessage

> IF EXISTS upsert for Billing.NotificationMessages: records incoming payment provider notifications from Azure Service Bus (update existing by MessageID, or insert new with StatusID hardcoded to 1), returning the new record's ID on INSERT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MessageID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpsertNotificationMessage` is the write path for `Billing.NotificationMessages`, which persists incoming payment provider webhook/postback notifications received by the Notification Gateway Service (NGS). The NGS receives provider callbacks via Azure Service Bus queues (named `{env}-{provider}-notificationgateway`) and stores them in this table for processing and auditing.

The procedure uses an IF EXISTS / UPDATE / ELSE INSERT pattern keyed on `@MessageID`:
- If called with an existing `@MessageID`: updates the message fields using a patch pattern (ISNULL preserves existing values) and stamps `Processed=GETUTCDATE()` to record when the update occurred.
- If called with `@MessageID=-1` (or any non-matching ID): inserts a new notification record with `StatusID=1` hardcoded (not the @StatusID parameter), and returns the new `MessageID` via the `@NotificationID` OUTPUT parameter.

**Important quirk**: On INSERT, `StatusID` is always set to 1 regardless of the `@StatusID` parameter value. The parameter is only used in the UPDATE path. All new messages start at StatusID=1.

Context: The NGS was built on .NET Core 3.1 and deployed to Azure VMSS with Azure Service Bus for messaging. It uses a separate NGS database for its own persistence, but the `Billing.NotificationMessages` table in the etoro database is maintained in parallel for cross-service visibility and audit.

---

## 2. Business Logic

### 2.1 IF EXISTS Upsert Pattern (Not MERGE)

**What**: Uses IF EXISTS with UPDLOCK to check for an existing record, then branches to UPDATE or INSERT.

**Columns/Parameters Involved**: `@MessageID`, `Billing.NotificationMessages`

**Rules**:
- Match condition: `SELECT * FROM Billing.NotificationMessages WITH (UPDLOCK) WHERE MessageID = @MessageID`
  - UPDLOCK hint prevents concurrent inserts for the same MessageID during the existence check
- Default `@MessageID = -1`: -1 is never a real MessageID (IDENTITY starts at 1), so the default triggers the INSERT path
- WHEN found (UPDATE): Patch update on all content fields; always stamps `Processed=GETUTCDATE()` as last-processed timestamp
- WHEN not found (INSERT): Inserts with `StatusID=1` hardcoded, `Created=GETUTCDATE()`, `Processed=GETUTCDATE()`

**Diagram**:
```
@MessageID=-1 (default new message) or existing MessageID

  IF EXISTS MessageID:
    UPDATE NotificationMessages
    SET Provider=ISNULL(@Provider, Provider),
        RawMessage=ISNULL(@RawMessage, RawMessage),
        StatusID=ISNULL(@StatusID, StatusID),
        Queue=ISNULL(@Queue, Queue),
        Topic=ISNULL(@Topic, Topic),
        Subscription=ISNULL(@Subscription, Subscription),
        Processed=GETUTCDATE()
    WHERE MessageID=@MessageID
  ELSE:
    INSERT NotificationMessages (Provider, RawMessage, StatusID=1 [hardcoded!],
                                 Queue, Topic, Subscription, Created, Processed)
    SET @NotificationID = SCOPE_IDENTITY()
```

### 2.2 StatusID=1 Hardcoded on INSERT

**What**: The INSERT branch always sets StatusID=1 regardless of the @StatusID parameter.

**Rules**:
- All new notification messages start at StatusID=1
- The @StatusID parameter is only effective in the UPDATE path (ISNULL(@StatusID, StatusID))
- The distinction between StatusID values is managed externally; the NGS inserts new messages as StatusID=1 and updates status as processing progresses

### 2.3 Azure Service Bus Context Fields

**What**: `@Queue`, `@Topic`, and `@Subscription` capture the Service Bus routing metadata for the notification.

**Rules**:
- `@Queue`: The Service Bus queue name, following the pattern `{env}-{provider}-notificationgateway`
  - Examples: `prod-ixopay-notificationgateway`, `prod-notificationgateway` (default queue)
- `@Topic`: Azure Service Bus topic name (if topic-based routing)
- `@Subscription`: Azure Service Bus subscription name (if subscription-based routing)
- These fields enable tracing which provider sent the notification and through which channel

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MessageID | INT | YES | -1 | CODE-BACKED | PK of `Billing.NotificationMessages`. If -1 (default), always triggers INSERT. If an existing MessageID is provided, triggers UPDATE. |
| 2 | @Provider | VARCHAR(100) | YES | NULL | CODE-BACKED | Payment provider name (e.g., "ixopay", "etorotest"). Used for routing and audit. ISNULL-preserved on UPDATE. |
| 3 | @RawMessage | VARCHAR(MAX) | YES | NULL | CODE-BACKED | The raw webhook/postback payload from the payment provider. Stored as-is for audit and replay. ISNULL-preserved on UPDATE. |
| 4 | @StatusID | TINYINT | YES | NULL | CODE-BACKED | Processing status of the message. Only used in UPDATE path (ISNULL preserved). On INSERT, always 1 regardless of this parameter. |
| 5 | @Queue | VARCHAR(100) | YES | NULL | CODE-BACKED | Azure Service Bus queue name from which the message was received (e.g., "prod-ixopay-notificationgateway"). ISNULL-preserved on UPDATE. |
| 6 | @Topic | VARCHAR(100) | YES | NULL | CODE-BACKED | Azure Service Bus topic name (if topic-based routing). ISNULL-preserved on UPDATE. |
| 7 | @Subscription | VARCHAR(100) | YES | NULL | CODE-BACKED | Azure Service Bus subscription name. ISNULL-preserved on UPDATE. |
| 8 | @NotificationID | INT OUTPUT | YES | NULL | CODE-BACKED | OUTPUT parameter. Populated with SCOPE_IDENTITY() on INSERT only. NULL when the procedure performs an UPDATE. Allows the caller to retrieve the new MessageID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MessageID | Billing.NotificationMessages | IF EXISTS + UPDATE or INSERT | Upserts the notification message record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Notification Gateway Service (application) | Webhook/postback handler | Application call | Called when a payment provider notification is received from Azure Service Bus |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpsertNotificationMessage (procedure)
+-- Billing.NotificationMessages (table) [IF EXISTS check + UPDATE or INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.NotificationMessages | Table | IF EXISTS check with UPDLOCK + UPDATE or INSERT based on MessageID existence |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Notification Gateway Service (application) | Application | Persists incoming provider notifications for processing and audit |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID=1 hardcoded on INSERT | Design | @StatusID parameter has no effect on INSERT; all new records start at status 1. The parameter only applies to the UPDATE path. |
| UPDLOCK hint | Concurrency | Prevents concurrent processes from both passing the EXISTS check and both inserting |
| No transaction wrapper | Design | No explicit TRY/CATCH; if INSERT or UPDATE fails, SQL Server auto-rollback applies |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Insert a new notification (typical: @MessageID=-1)
```sql
DECLARE @NewID INT;
EXEC Billing.UpsertNotificationMessage
    @MessageID    = -1,
    @Provider     = 'ixopay',
    @RawMessage   = '{"transactionId":"abc123","status":"success"}',
    @StatusID     = NULL,
    @Queue        = 'prod-ixopay-notificationgateway',
    @Topic        = NULL,
    @Subscription = NULL,
    @NotificationID = @NewID OUTPUT;
SELECT @NewID AS NewMessageID;
```

### 8.2 Update the status of an existing notification
```sql
EXEC Billing.UpsertNotificationMessage
    @MessageID = 987654,
    @StatusID  = 2;   -- processing complete
-- @NotificationID OUTPUT will be NULL (UPDATE path)
```

### 8.3 View recent notifications from a provider
```sql
SELECT TOP 20
    n.MessageID,
    n.Provider,
    n.StatusID,
    n.Queue,
    n.Created,
    n.Processed
FROM Billing.NotificationMessages n WITH (NOLOCK)
WHERE n.Provider = 'ixopay'
ORDER BY n.MessageID DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Notification Gateway Service Deployment requirements](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/813367297) | Confluence | NGS architecture: .NET Core 3.1, Azure Service Bus queues named {env}-{provider}-notificationgateway; Billing.NotificationMessages table schema; NGS reads from Azure Service Bus and persists provider notifications |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.UpsertNotificationMessage | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpsertNotificationMessage.sql*
