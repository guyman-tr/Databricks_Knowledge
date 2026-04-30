# Customer.SendEvent

> Translates a business lifecycle event (e.g., first deposit, login, championship win) into one or more queued notification messages by looking up active templates mapped to the event type.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ErrOut OUTPUT - error description on failure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.SendEvent` is the event-driven entry point to the eToro notification system. Rather than requiring callers to know which message templates to send, they supply a high-level event type (e.g., "First deposit", "Login", "Bonus received") and this procedure resolves the correct templates and dispatches the notifications automatically.

This abstraction decouples business logic from notification configuration. Adding a new notification for an existing event requires only inserting a row into `Maintenance.EventTypeToMessageTemplate` - no procedure changes needed. Deactivating an event or its templates suppresses all related notifications without touching calling code.

Data flows in from 15 procedures across Customer, History, BackOffice, and Championship schemas - fired when lifecycle milestones occur (registration, deposit, login, logout, bonus, chargeback, etc.). SendEvent validates the event type is active and the customer exists, then iterates over all active message templates for that event and calls `Customer.SendMessage` for each.

---

## 2. Business Logic

### 2.1 Event Type Guard

**What**: Both the event type and the customer must be valid or the procedure returns silently.

**Columns/Parameters Involved**: `@EventTypeID`, `@CID`

**Rules**:
- Checks `Dictionary.EventType.IsActive = 1` for the given event type.
- Checks `Customer.Customer` for the given CID.
- If either check fails: RETURN 0 (silent no-op, no error).
- Active event types (Dictionary.EventType): 1=Registration of demo customer, 2=Registration of real customer, 3=First deposit, 6=First position with positive net profit, 9=Money is over, 10=Any customer login, 11=Any customer logout, 28=First position.
- Inactive event types (IsActive=0): 4=First game, 5=Birthday, 7=Championship win, 8=Championship registration, 12=Demo customer login, 13=Demo customer logout, 14=Real customer login, 15=Real customer logout, 29=First Weekly Login.

### 2.2 Multi-Template Fan-Out

**What**: A single event can trigger multiple notification messages via multiple active templates.

**Columns/Parameters Involved**: `@EventTypeID`, `Maintenance.EventTypeToMessageTemplate`, `Maintenance.MessageTemplate.IsActive`

**Rules**:
- Builds a list of all active MessageTemplateIDs linked to the event via Maintenance.EventTypeToMessageTemplate (only where MessageTemplate.IsActive = 1).
- Iterates through templates in ascending order (MIN first), calling Customer.SendMessage for each.
- If a SendMessage call fails (@Answer != 0), iteration skips to the MAX template ID and then no more - effectively stopping the remaining templates in the loop.
- All SendMessage calls are wrapped in a single transaction (commit on success, rollback on error).

```
EventTypeID -> Maintenance.EventTypeToMessageTemplate
  -> [Template1 (active), Template2 (active), Template3 (inactive)]
  -> Sends: Template1, Template2 (Template3 skipped - inactive)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EventTypeID | INT | NO | - | VERIFIED | Business lifecycle event to fire. FK to Dictionary.EventType: 1=Registration demo, 2=Registration real, 3=First deposit, 6=First positive PnL position, 9=Money is over (balance depleted), 10=Any login, 11=Any logout, 28=First position. Inactive types (IsActive=0) cause silent return. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID to send event notifications to. Must exist in Customer.Customer view or procedure returns silently. Passed as @CustomerList to each Customer.SendMessage call. |
| 3 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT parameter. On success: empty string. On error: structured error string with SP name, ERROR_NUMBER, ERROR_LINE, and ERROR_MESSAGE from the CATCH block. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @EventTypeID | Dictionary.EventType | Lookup | Validates event is active and resolves event name |
| @CID | Customer.Customer | Lookup | Validates customer exists before sending |
| (internal) | Maintenance.EventTypeToMessageTemplate | Lookup | Resolves which templates are mapped to the event |
| (internal) | Maintenance.MessageTemplate | Lookup | Filters to only active templates |
| (EXEC) | Customer.SendMessage | Callee | Called once per active template for the event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Fires events during balance processing |
| Customer.SetBalanceBonus | EXEC | Caller | Fires event on bonus credit |
| Customer.SetBalanceCashOut | EXEC | Caller | Fires event on cashout |
| Customer.SetBalanceChargeBack | EXEC | Caller | Fires event on chargeback |
| Customer.SetBalanceCompensation | EXEC | Caller | Fires event on compensation |
| Customer.SetBalanceDeposit | EXEC | Caller | Fires event on deposit (e.g., EventTypeID 3=First deposit) |
| Customer.SetBalanceRefund | EXEC | Caller | Fires event on refund |
| Customer.SetBalanceRefundAsChargeBack | EXEC | Caller | Fires event on refund-as-chargeback |
| History.LogIn | EXEC | Caller | Fires EventTypeID 10=Any login |
| History.LogOutByCID | EXEC | Caller | Fires EventTypeID 11=Any logout |
| History.LogOutByCID_OLD | EXEC | Caller | Legacy logout path, fires logout event |
| History.LogOutByLoginID | EXEC | Caller | Fires logout event by LoginID |
| BackOffice.SendBirthDayMessage | EXEC | Caller | Fires birthday event (EventTypeID 5, currently inactive) |
| Championship.ChampionshipPlayerAdd | EXEC | Caller | Fires championship registration event |
| Championship.SetWinner | EXEC | Caller | Fires championship win event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SendEvent (procedure)
├── Dictionary.EventType (table) [READ - validate IsActive]
├── Customer.Customer (view) [READ - validate CID exists]
├── Maintenance.EventTypeToMessageTemplate (table) [READ - get template list for event]
├── Maintenance.MessageTemplate (table) [READ - filter active templates]
└── Customer.SendMessage (procedure)
      ├── Maintenance.MessageTemplate (table)
      ├── Dictionary.PromotionType (table)
      ├── Internal.GetMessageQueueID (procedure)
      ├── Internal.ConvertListToTable (function)
      ├── Customer.MessageQueue (table)
      └── Customer.CustomerToMessageQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EventType | Table | READ - validates EventTypeID is active |
| Customer.Customer | View | READ - validates CID exists |
| Maintenance.EventTypeToMessageTemplate | Table | READ - looks up MessageTemplateIDs for the event |
| Maintenance.MessageTemplate | Table | READ - filters to active templates only |
| Customer.SendMessage | Procedure | EXEC - sends each resolved template to the customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls SendEvent for various balance-related lifecycle events |
| Customer.SetBalanceBonus | Procedure | Fires bonus event notification |
| Customer.SetBalanceCashOut | Procedure | Fires cashout event notification |
| Customer.SetBalanceChargeBack | Procedure | Fires chargeback event notification |
| Customer.SetBalanceCompensation | Procedure | Fires compensation event notification |
| Customer.SetBalanceDeposit | Procedure | Fires deposit event (e.g., first deposit milestone) |
| Customer.SetBalanceRefund | Procedure | Fires refund event notification |
| Customer.SetBalanceRefundAsChargeBack | Procedure | Fires refund-as-chargeback event notification |
| History.LogIn | Procedure | Fires login event (EventTypeID 10) |
| History.LogOutByCID | Procedure | Fires logout event (EventTypeID 11) |
| History.LogOutByLoginID | Procedure | Fires logout event by login ID |
| BackOffice.SendBirthDayMessage | Procedure | Fires birthday event |
| Championship.ChampionshipPlayerAdd | Procedure | Fires championship registration event |
| Championship.SetWinner | Procedure | Fires championship win event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Event active guard | Application | Returns 0 silently if EventType.IsActive != 1 or CID not found |
| Template active filter | Application | Only EventTypeToMessageTemplate rows with MessageTemplate.IsActive = 1 are used |
| Transaction wrapper | Transaction | BEGIN/COMMIT TRANSACTION wraps all SendMessage calls - all succeed or all roll back |

---

## 8. Sample Queries

### 8.1 View all active event types and their mapped templates

```sql
SELECT
    et.EventTypeID,
    et.Name AS EventName,
    et.IsActive,
    e2m.MessageTemplateID,
    mt.Name AS TemplateName,
    mt.IsActive AS TemplateActive
FROM Dictionary.EventType et WITH (NOLOCK)
LEFT JOIN Maintenance.EventTypeToMessageTemplate e2m WITH (NOLOCK) ON e2m.EventTypeID = et.EventTypeID
LEFT JOIN Maintenance.MessageTemplate mt WITH (NOLOCK) ON mt.MessageTemplateID = e2m.MessageTemplateID
ORDER BY et.EventTypeID, e2m.MessageTemplateID
```

### 8.2 Check which events fired for a customer recently

```sql
SELECT TOP 20
    cmq.CID,
    mq.MessageTemplateID,
    mt.Name AS TemplateName,
    e2m.EventTypeID,
    et.Name AS EventName,
    mq.MessageQueued,
    cmq.IsNotified
FROM Customer.CustomerToMessageQueue cmq WITH (NOLOCK)
JOIN Customer.MessageQueue mq WITH (NOLOCK) ON mq.MessageQueueID = cmq.MessageQueueID
JOIN Maintenance.MessageTemplate mt WITH (NOLOCK) ON mt.MessageTemplateID = mq.MessageTemplateID
LEFT JOIN Maintenance.EventTypeToMessageTemplate e2m WITH (NOLOCK) ON e2m.MessageTemplateID = mt.MessageTemplateID
LEFT JOIN Dictionary.EventType et WITH (NOLOCK) ON et.EventTypeID = e2m.EventTypeID
WHERE cmq.CID = 12345
ORDER BY mq.MessageQueued DESC
```

### 8.3 Find event types with no active templates (orphaned events)

```sql
SELECT
    et.EventTypeID,
    et.Name AS EventName,
    et.IsActive,
    COUNT(CASE WHEN mt.IsActive = 1 THEN 1 END) AS ActiveTemplateCount
FROM Dictionary.EventType et WITH (NOLOCK)
LEFT JOIN Maintenance.EventTypeToMessageTemplate e2m WITH (NOLOCK) ON e2m.EventTypeID = et.EventTypeID
LEFT JOIN Maintenance.MessageTemplate mt WITH (NOLOCK) ON mt.MessageTemplateID = e2m.MessageTemplateID
GROUP BY et.EventTypeID, et.Name, et.IsActive
HAVING COUNT(CASE WHEN mt.IsActive = 1 THEN 1 END) = 0
ORDER BY et.EventTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SendEvent | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SendEvent.sql*
