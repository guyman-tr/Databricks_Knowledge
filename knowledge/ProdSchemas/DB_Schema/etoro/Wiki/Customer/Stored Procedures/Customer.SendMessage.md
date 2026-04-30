# Customer.SendMessage

> Queues a notification message from a template to one or more customers, inserting into Customer.MessageQueue and Customer.CustomerToMessageQueue with deduplication for replaceable promotions.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ErrOut OUTPUT - error description on failure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.SendMessage` is the primary write path for the eToro in-platform notification system. It takes a template ID and a list of customer IDs, then creates a queued message record and links each customer to it. The message system is template-driven: templates (in `Maintenance.MessageTemplate`) define the message type, delivery channel, retention period, and whether the same promotion type can supersede an existing pending message.

This procedure is the single insertion point for all in-platform notifications - login confirmations, trading events (position closed, bonus applied), end-of-week fee notices, promotional messages, and more. With 14M+ records in Customer.MessageQueue, it is a high-frequency write path called from 17 different procedures across Customer, Trade, BackOffice, History, and Internal schemas.

Data flows as follows: the caller supplies a comma-separated customer list (@CustomerList) and a template ID. The procedure: (1) validates the template is active, (2) obtains the next MessageQueueID from `Internal.GetMessageQueueID`, (3) calculates message expiry (NOW + retention hours), (4) optionally removes old pending messages of the same replaceable promotion type for each customer, (5) inserts the message into `Customer.MessageQueue`, and (6) links each customer via `Customer.CustomerToMessageQueue` with deduplication to prevent duplicate pending non-replaceable promotions.

---

## 2. Business Logic

### 2.1 Template Active Guard

**What**: Inactive templates are silently skipped - no message is sent and no error is raised.

**Columns/Parameters Involved**: `@MessageTemplateID`, `Maintenance.MessageTemplate.IsActive`

**Rules**:
- Before any insert, checks: `SELECT * FROM Maintenance.MessageTemplate WHERE MessageTemplateID = @MessageTemplateID AND IsActive = 0`
- If the template is inactive (IsActive = 0), the procedure immediately returns without error.
- This allows templates to be disabled without requiring callers to be updated.

### 2.2 Replaceable Promotion Deduplication

**What**: For promotion-type messages, controls whether a new message replaces existing pending messages of the same promotion type, or is silently dropped if a pending one already exists.

**Columns/Parameters Involved**: `@MessageTemplateID`, `Dictionary.PromotionType.IsReplaceable`, `Customer.CustomerToMessageQueue.IsNotified`

**Rules**:
- If the template has a PromotionTypeID (is a promotion message), the procedure reads `Dictionary.PromotionType.IsReplaceable`.
- **IsReplaceable = 1**: DELETE all existing `CustomerToMessageQueue` links for the same promotion type and CID where IsNotified = 0 (not yet delivered). The new message will then be inserted - replacing the old.
- **IsReplaceable = 0**: The INSERT into CustomerToMessageQueue has a WHERE NOT EXISTS filter that skips inserting if the customer already has an undelivered message (IsNotified = 0) for any message of the same PromotionTypeID.
- Non-promotion templates (PromotionTypeID IS NULL): no deduplication; always inserted.

```
Template.PromotionTypeID IS NULL:
  -> No deduplication, always insert

Template.PromotionTypeID IS NOT NULL:
  -> Read PromotionType.IsReplaceable
  IsReplaceable = 1: DELETE old pending for same promo + customer, INSERT new
  IsReplaceable = 0: INSERT only if no pending message for same promo type + CID
```

### 2.3 Retention / Validity Window

**What**: Controls how long the message remains valid for delivery.

**Columns/Parameters Involved**: `@Retention`, `Maintenance.MessageTemplate.Retention`, `Customer.MessageQueue.ValidTo`

**Rules**:
- @Retention is optional (nullable). If provided, overrides the template's default.
- ValidTo = DATEADD(hh, ISNULL(@Retention, template.Retention), GETDATE()) - expiry in hours from now.
- Messages with ValidTo in the past are no longer deliverable by ReceiveMessage/ReceiveMessageAll.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CustomerList | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of CIDs (customer IDs) to receive the message. Parsed by Internal.ConvertListToTable() into a table of individual CID values. Each CID gets a separate row in Customer.CustomerToMessageQueue. |
| 2 | @MessageTemplateID | INT | NO | - | VERIFIED | Template defining the message type, content format, delivery channel, retention period, and promotion deduplication behavior. FK to Maintenance.MessageTemplate.MessageTemplateID. Inactive templates (IsActive=0) cause silent no-op. |
| 3 | @ParamList | NVARCHAR(MAX) | NO | - | CODE-BACKED | Parameter values that fill the template's placeholders. Stored verbatim in Customer.MessageQueue.ParamList. Format depends on the template - typically delimited values that the delivery system substitutes into the message body. |
| 4 | @Retention | INT | YES | null | CODE-BACKED | Override for the message validity window in hours. If NULL, the template's own Retention value is used. ValidTo = GETDATE() + @Retention hours. Controls how long ReceiveMessage can deliver this message. |
| 5 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT parameter. On success: empty string. On error: structured error string with SP name, ERROR_NUMBER, ERROR_LINE, and ERROR_MESSAGE. Raised as RAISERROR 60000 to caller on failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MessageTemplateID | Maintenance.MessageTemplate | Lookup | Reads template IsActive, Retention, PromotionTypeID |
| (internal) | Dictionary.PromotionType | Lookup | Reads IsReplaceable for promotion deduplication |
| (internal) | Internal.GetMessageQueueID | EXEC | Gets the next MessageQueueID for the new message |
| (internal) | Internal.ConvertListToTable | Function | Parses @CustomerList CSV into a table of CIDs |
| (INSERT) | Customer.MessageQueue | INSERT target | Creates the message record |
| (DELETE + INSERT) | Customer.CustomerToMessageQueue | DELETE + INSERT | Links customers to the message; deletes old replaceable promotions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SendEvent | EXEC | Caller | Sends event-triggered notifications |
| Customer.SetStatus | EXEC | Caller | Sends status-change notifications to customers |
| Customer.SetBalanceBonus | EXEC | Caller | Notifies customers of bonus credits |
| Customer.SetBalanceCompensation | EXEC | Caller | Notifies customers of compensation credits |
| Customer.SetBalanceDeposit | EXEC | Caller | Notifies customers of deposit confirmations |
| Customer.SetBalance | EXEC | Caller | Main balance orchestrator that routes notifications |
| Trade.PostClosePositionActions | EXEC | Caller | Notifies customers when positions close |
| BackOffice.FreazCustomer | EXEC | Caller | Notifies customers when their account is frozen |
| BackOffice.GetCustomersForStatusChange | EXEC | Caller | Sends status-change notifications in bulk |
| BackOffice.usp_CloseZeroMirrors | EXEC | Caller | Notifies on zero-balance mirror closure |
| History.LogIn | EXEC | Caller | Sends login-triggered notifications |
| History.LogOutByCID | EXEC | Caller | Sends logout-triggered notifications |
| History.LogOutByCID_OLD | EXEC | Caller | Legacy logout notification path |
| History.LogOutByLoginID | EXEC | Caller | Sends logout-by-login-ID notifications |
| Internal.SendEndOfWeekFeeMessage | EXEC | Caller | Sends end-of-week fee notices to affected customers |
| Trade.ChekAsyncFailedSteps | EXEC | Caller | Notifies of async trade processing failures |
| Trade.EOW_CloseCustomerPositionByMod | EXEC | Caller | Notifies on end-of-week position closure by moderator |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SendMessage (procedure)
├── Maintenance.MessageTemplate (table) [READ - validate active, get Retention + PromotionTypeID]
├── Dictionary.PromotionType (table) [READ - check IsReplaceable]
├── Internal.GetMessageQueueID (procedure) [EXEC - get next MessageQueueID]
├── Internal.ConvertListToTable (function) [parse @CustomerList CSV]
├── Customer.CustomerToMessageQueue (table) [DELETE + INSERT]
└── Customer.MessageQueue (table) [INSERT]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.MessageTemplate | Table | READ - validates IsActive, reads Retention and PromotionTypeID |
| Dictionary.PromotionType | Table | READ - reads IsReplaceable for deduplication logic |
| Internal.GetMessageQueueID | Procedure | EXEC - generates the next MessageQueueID |
| Internal.ConvertListToTable | Function | Parses comma-separated @CustomerList into a rowset |
| Customer.MessageQueue | Table | INSERT - creates the message header record |
| Customer.CustomerToMessageQueue | Table | DELETE (replaceable promo cleanup) + INSERT (link customers to message) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SendEvent | Procedure | Calls SendMessage to send event notifications |
| Customer.SetStatus | Procedure | Calls SendMessage when customer status changes |
| Customer.SetBalanceBonus | Procedure | Calls SendMessage for bonus notifications |
| Customer.SetBalanceCompensation | Procedure | Calls SendMessage for compensation notifications |
| Customer.SetBalanceDeposit | Procedure | Calls SendMessage for deposit confirmations |
| Customer.SetBalance | Procedure | Calls SendMessage as part of balance processing |
| Trade.PostClosePositionActions | Procedure | Calls SendMessage after position close |
| BackOffice.FreazCustomer | Procedure | Calls SendMessage for account freeze notifications |
| Internal.SendEndOfWeekFeeMessage | Procedure | Calls SendMessage for EoW fee notices |
| (+ 8 more procedures) | Procedure | Various notification triggers across schemas |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Template active guard | Application | Returns silently if MessageTemplate.IsActive = 0 - inactive templates produce no messages |
| Promotion deduplication | Application | Non-replaceable promotions: skips INSERT if customer has pending message for same PromotionTypeID |
| Transaction wrapper | Transaction | BEGIN/COMMIT TRANSACTION wraps the DELETE + two INSERTs for atomicity |
| RAISERROR 60000 | Error | On failure: rolls back transaction, raises error 60000 with structured message details |

---

## 8. Sample Queries

### 8.1 Check all pending messages for a specific customer

```sql
SELECT
    mq.MessageQueueID,
    mq.MessageTemplateID,
    mt.Name AS TemplateName,
    mq.ParamList,
    mq.ValidTo,
    cmq.IsNotified,
    mq.MessageQueued
FROM Customer.CustomerToMessageQueue cmq WITH (NOLOCK)
JOIN Customer.MessageQueue mq WITH (NOLOCK) ON mq.MessageQueueID = cmq.MessageQueueID
JOIN Maintenance.MessageTemplate mt WITH (NOLOCK) ON mt.MessageTemplateID = mq.MessageTemplateID
WHERE cmq.CID = 12345
  AND cmq.IsNotified = 0
  AND mq.ValidTo > GETDATE()
ORDER BY mq.MessageQueued DESC
```

### 8.2 Find messages sent for a specific template recently

```sql
SELECT TOP 20
    mq.MessageQueueID,
    mq.ParamList,
    mq.MessageQueued,
    mq.ValidTo,
    COUNT(cmq.CID) AS CustomerCount
FROM Customer.MessageQueue mq WITH (NOLOCK)
JOIN Customer.CustomerToMessageQueue cmq WITH (NOLOCK) ON cmq.MessageQueueID = mq.MessageQueueID
WHERE mq.MessageTemplateID = 7
GROUP BY mq.MessageQueueID, mq.ParamList, mq.MessageQueued, mq.ValidTo
ORDER BY mq.MessageQueued DESC
```

### 8.3 Find promotion type deduplication activity - messages replaced vs accepted

```sql
SELECT
    mt.PromotionTypeID,
    pt.Name AS PromotionTypeName,
    pt.IsReplaceable,
    COUNT(DISTINCT mq.MessageQueueID) AS MessageCount
FROM Customer.MessageQueue mq WITH (NOLOCK)
JOIN Maintenance.MessageTemplate mt WITH (NOLOCK) ON mt.MessageTemplateID = mq.MessageTemplateID
JOIN Dictionary.PromotionType pt WITH (NOLOCK) ON pt.PromotionTypeID = mt.PromotionTypeID
WHERE mt.PromotionTypeID IS NOT NULL
GROUP BY mt.PromotionTypeID, pt.Name, pt.IsReplaceable
ORDER BY MessageCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 17 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SendMessage | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SendMessage.sql*
