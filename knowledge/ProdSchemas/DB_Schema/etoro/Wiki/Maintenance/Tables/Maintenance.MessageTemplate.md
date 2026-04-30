# Maintenance.MessageTemplate

> Registry of 551 predefined message templates that define the delivery channel, parameterization, and lifetime for all platform-generated notifications sent to eToro users.

| Property | Value |
|----------|-------|
| **Schema** | Maintenance |
| **Object Type** | Table |
| **Key Identifier** | MessageTemplateID (int, PK) |
| **Partition** | No (MAIN filegroup) |
| **Indexes** | 4 (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

Maintenance.MessageTemplate is the master catalog of all communication blueprints available in the eToro platform messaging system. Each row defines a named message event — such as "Stop Loss", "First Deposit (Real)", "Trade Block", or "Over the Weekend Fee" — and specifies how that message will be delivered (DialogBox, notification Bar, Web popup, KICK overlay), how many dynamic runtime parameters its content template requires, and how long the message persists in a user's queue before automatic expiry.

Without this table the entire platform notification infrastructure would have no routing configuration. Customer.SendMessage, Customer.ReceiveMessage, and Internal.BuildMessage all look up the MessageTemplateID to determine delivery channel (via MessageTypeID) and message lifetime (via Retention). Every user-facing notification event — trading alerts, deposit confirmations, promotional offers, compliance kicks, and account status messages — traces back to a row in this table.

Data flows from BackOffice/Maintenance procedures (Add/Edit/Delete) that create and manage templates, through the Customer.SendMessage/SendEvent procedures that dispatch messages using a template, into the Customer.MessageQueue table (which stores pending per-user messages), and finally to Internal.BuildMessage / Internal.GetMessageByLanguageID which assemble the final localized text using the NumberOfParams count. The actual message body text is bound separately (via Maintenance.MessageTemplateBind / MessageTemplateEditBody) and stored in companion tables not visible in this DDL.

---

## 2. Business Logic

### 2.1 Message Channel Routing

**What**: Each template is assigned a delivery channel that controls where and how the message appears in the UI.

**Columns/Parameters Involved**: `MessageTypeID`, `Name`

**Rules**:
- MessageTypeID is a FK to Dictionary.MessageType - the 10 delivery channels are: 1=Dialog (modal, requires acknowledgment), 2=Bar (non-blocking notification bar), 3=Web (in-app web popup), 4=Promotion (Cashier flow), 5=Promotion (Trade interface), 6=WEB (On Exit intent), 7=KICK (On Login - forced), 8=KICK (On Chat - forced), 9=WEB (Default Browser), 10=Trade Block (prevents trading until acknowledged)
- Templates with MessageTypeID IN (7,8,10) — KICK and Trade Block — use extreme Retention values (192720 hours ~= 22 years), making them effectively permanent until explicitly dismissed or removed
- Templates with MessageTypeID=1 (Dialog) are used for both operational events (Stop Loss, Take Profit) and compliance messages
- The channel determines client-side rendering logic; all routing goes through Internal.BuildMessage

**Diagram**:
```
MessageTemplate
  |
  +-- MessageTypeID=1 (Dialog)      -> Modal popup, user must dismiss
  +-- MessageTypeID=2 (Bar)         -> Notification bar, dismissible
  +-- MessageTypeID=3 (Web)         -> In-app web view / onboarding popups
  +-- MessageTypeID=4/5 (Promotion) -> Cashier or Trade UI promo banners
  +-- MessageTypeID=6 (WEB OnExit)  -> Exit-intent message
  +-- MessageTypeID=7/8 (KICK)      -> Forced display at login or chat open
  +-- MessageTypeID=9 (WEB Browser) -> Opens in default browser
  +-- MessageTypeID=10 (TradeBlock) -> Full overlay, blocks all trading
```

### 2.2 Promotion Template Classification

**What**: Templates optionally carry a PromotionTypeID that determines how the messaging system handles concurrent promotions for the same user.

**Columns/Parameters Involved**: `PromotionTypeID`, `IsActive`

**Rules**:
- PromotionTypeID=NULL: standard operational message (trading alerts, account events) — no promotion behavior
- PromotionTypeID=1 (Replaceable Promotion): when a new message of this type is sent to a user, it replaces any existing active replaceable promotion message. Used for campaign-style announcements where only the latest matters (e.g., weekend fee warnings, onboarding popups)
- PromotionTypeID=2 (Deposit Bonus): bonus promotions that persist independently — multiple deposit bonuses can coexist for the same user; they are not replaced
- IsActive=false marks a template as retired: it remains in the table for historical audit purposes but Customer.SendMessage will not dispatch it to users
- The replaceability logic is enforced in Customer.SendMessage and Maintenance.MessageTemplate* procedures (confirmed by Dictionary.PromotionType.md)

**Diagram**:
```
PromotionTypeID
  |
  +-- NULL               -> Operational message (no promotion logic)
  +-- 1 (Replaceable)   -> New send replaces old send for same user
  +-- 2 (Deposit Bonus) -> Multiple active simultaneously per user
```

### 2.3 Message Retention Windows

**What**: The Retention column controls how long a dispatched message survives in a user's message queue (Customer.MessageQueue) before the platform auto-expires it.

**Columns/Parameters Involved**: `Retention`, `NumberOfParams`

**Rules**:
- Retention is stored in HOURS
- Short retention (1-30h): urgent operational alerts — stop loss notifications, deposit confirmations, trading pause messages — that lose relevance quickly
- Medium retention (144-720h): order execution alerts (720h = 30 days), time-limited event announcements (144h = 6 days for holiday notices)
- Long retention (4320h = 180 days): onboarding campaigns where user engagement may occur weeks later
- Permanent retention (192720h ~= 22 years): KICK and Trade Block templates that must stay until explicitly dismissed by admin or resolved by the user
- NumberOfParams declares how many runtime substitution parameters the content template requires (e.g., "Stop Loss" has 2: instrument name + amount). The Internal.BuildMessage function uses this to validate parameter counts before rendering

---

## 3. Data Overview

| MessageTemplateID | Name | MessageTypeID | PromotionTypeID | Retention (hrs) | IsActive | Meaning |
|---|---|---|---|---|---|---|
| 3 | Stop Loss | 2 (Bar) | NULL | 30 | true | Sent when a position closes due to stop loss trigger. Appears as a notification bar for 30 hours — long enough for the user to review but not permanently cluttering the UI. One of the most frequently dispatched templates. |
| 14 | Kick (on login) | 7 (KICK On Login) | NULL | 192720 | true | Forces a mandatory display at the next user login — used for compliance notices, account holds, or regulatory acknowledgment requirements. Retention of ~22 years makes it persistent until admin removes it from the user's queue. |
| 18 | Over the Weekend Fee | 1 (Dialog) | 1 (Replaceable) | 12 | true | Modal dialog warning users with open overnight positions that a weekend fee will reduce their balance. Retention of 12 hours aligns with the Friday-close window. PromotionTypeID=1 ensures a new warning replaces the old one rather than stacking. |
| 1068 | $500 first bonus | 3 (Web) | 2 (Deposit Bonus) | 1 | true | A web popup promoting the first-deposit bonus offer. PromotionTypeID=2 (Deposit Bonus) means it is NOT replaced by other promotions and can coexist alongside other active messages for the same user. |
| 1556 | Onboarding_Popup_EN | 3 (Web) | 1 (Replaceable) | 4320 | true | Long-lived onboarding popup for English-speaking WebTrader users. Retention of 4320h (180 days) gives the onboarding campaign a 6-month window. Paired with locale variants (e.g., Onboarding_Popup_ES) as separate rows. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageTemplateID | int | NO | - | CODE-BACKED | Unique identifier for the message template. PK, assigned by Internal.GetMessageTemplateID at insert time (called by Maintenance.MessageTemplateAdd). Referenced as FK by Customer.MessageQueue to identify which template a queued message uses. |
| 2 | MessageTypeID | int | NO | - | VERIFIED | Delivery channel for this template: 1=Dialog (modal), 2=Bar (notification bar), 3=Web (popup), 4=Promotion Cashier, 5=Promotion Trade, 6=WEB On Exit, 7=KICK On Login, 8=KICK On Chat, 9=WEB Default Browser, 10=Trade Block. FK to Dictionary.MessageType. Determines client-side rendering logic in Internal.BuildMessage. Indexed by DMST_TYPE for fast lookup by channel. |
| 3 | PromotionTypeID | int | YES | - | VERIFIED | Optional promotion category: 1=Replaceable Promotion (new send replaces old for same user), 2=Deposit Bonus (multiple coexist per user), NULL=operational message (no promotion behavior). FK to Dictionary.PromotionType. Indexed by DMST_PROMOTION. NULL for the majority of templates (trading alerts, account events). |
| 4 | Name | varchar(20) | NO | - | VERIFIED | Short human-readable label for the template (e.g., "Stop Loss", "First Deposit (Real)", "Kick (on login)"). Unique enforced by DMST_NAME index. Used by BackOffice staff in the Maintenance UI to identify and configure templates. Max 20 characters. |
| 5 | NumberOfParams | int | NO | - | CODE-BACKED | Count of dynamic runtime substitution parameters the template's message body expects. Internal.BuildMessage uses this count to validate that the caller supplies the correct number of parameters before rendering the final message text. 0 = static text (e.g., "Trade Block"), 1-8 = parameterized (e.g., "Stop Loss" needs instrument name + loss amount = 2 params). |
| 6 | Retention | int | NO | - | CODE-BACKED | How long (in hours) a dispatched instance of this template survives in Customer.MessageQueue before auto-expiry. Short (1-30h) for urgent trading alerts; medium (720h) for order notifications; long (4320h) for campaigns; permanent (192720h ~= 22 years) for KICK and Trade Block messages that must persist until explicitly resolved. |
| 7 | IsActive | bit | NO | - | CODE-BACKED | Controls whether this template can be dispatched: 1=active (Customer.SendMessage can use it), 0=retired (template preserved for history but no new messages dispatched). Allows templates to be soft-deleted without breaking historical MessageQueue records that reference the old MessageTemplateID. |
| 8 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text explanation of when and why this template is used. Written by the BackOffice/Maintenance team at template creation. Not used by any runtime logic — purely informational for administrators. Most rows are populated; a minority of older templates have NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageTypeID | Dictionary.MessageType | FK (FK_DMGT_DMST) | Specifies the delivery channel; Dictionary.MessageType maps ID to channel name and hidden flag |
| PromotionTypeID | Dictionary.PromotionType | FK (FK_DPMT_DMST) | Specifies the promotion replaceability category; NULL for non-promotional templates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.MessageQueue | MessageTemplateID | FK | Each pending user message references the template used to create it |
| BackOffice.GetEnglishMessageTemplate | MessageTemplateID | View JOIN | Exposes template metadata with English message body for BackOffice admin review |
| Customer.SendMessage | MessageTemplateID (param) | Lookup | Reads template to validate IsActive, get MessageTypeID channel, and apply promotion logic |
| Customer.ReceiveMessage | MessageTemplateID | Lookup | Returns message details including template metadata to the client |
| Customer.ReceiveMessageAll | MessageTemplateID | Lookup | Bulk retrieval of all pending messages for a user, joined to template |
| Customer.SendEvent | MessageTemplateID | Lookup | Event-triggered message dispatch that looks up template by ID |
| Internal.BuildMessage | MessageTemplateID | Lookup | Core message assembly function that reads NumberOfParams and Retention from template |
| Internal.GetMessageByLanguageID | MessageTemplateID | Lookup | Retrieves localized body text associated with a template and language |
| Trade.PostClosePositionActions | MessageTemplateID | Lookup | Dispatches Stop Loss / Take Profit messages on position close using specific template IDs |
| Trade.ChekAsyncFailedSteps | MessageTemplateID | Lookup | Monitors async messaging failures, references templates to identify failed dispatches |
| Maintenance.MessageTemplateAdd | MessageTemplateID (OUT) | WRITER | Inserts new template row; ID assigned by Internal.GetMessageTemplateID |
| Maintenance.MessageTemplateEdit | MessageTemplateID | MODIFIER | Updates template metadata (type, params, retention, active flag) |
| Maintenance.MessageTemplateDelete | MessageTemplateID | DELETER | Removes a template row |
| Maintenance.MessageTemplateEditBody | MessageTemplateID | MODIFIER | Updates the template body content (separate from metadata) |
| Maintenance.MessageTemplateBind | MessageTemplateID | MODIFIER | Associates a template with specific users or segments |
| Maintenance.MessageTemplateUnbind | MessageTemplateID | MODIFIER | Removes a template-user association |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Maintenance.MessageTemplate (table)
|- Dictionary.MessageType (table) [FK - leaf]
|- Dictionary.PromotionType (table) [FK - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MessageType | Table | FK target - MessageTypeID references MessageType.MessageTypeID; defines delivery channel |
| Dictionary.PromotionType | Table | FK target - PromotionTypeID references PromotionType.PromotionTypeID; defines promotion replaceability |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.MessageQueue | Table | FK reference - MessageTemplateID stored per queued user message |
| BackOffice.GetEnglishMessageTemplate | View | Reads - joins template metadata with English message body |
| Customer.SendMessage | Stored Procedure | Reads - validates and dispatches using template |
| Customer.ReceiveMessage | Stored Procedure | Reads - returns template metadata with message |
| Customer.ReceiveMessageAll | Stored Procedure | Reads - bulk template lookup for user messages |
| Customer.SendEvent | Stored Procedure | Reads - event-driven message dispatch |
| Internal.BuildMessage | Function | Reads - uses NumberOfParams, Retention for message assembly |
| Internal.GetMessageByLanguageID | Function | Reads - fetches localized body for template |
| Trade.PostClosePositionActions | Stored Procedure | Reads - sends Stop Loss/Take Profit alerts |
| Maintenance.MessageTemplateAdd | Stored Procedure | Writes - creates new template rows |
| Maintenance.MessageTemplateEdit | Stored Procedure | Modifies - updates template fields |
| Maintenance.MessageTemplateDelete | Stored Procedure | Deletes - removes template rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MMST | CLUSTERED | MessageTemplateID ASC | - | - | Active |
| DMST_NAME | UNIQUE NONCLUSTERED | Name ASC | - | - | Active |
| DMST_PROMOTION | NONCLUSTERED | PromotionTypeID ASC | - | - | Active |
| DMST_TYPE | NONCLUSTERED | MessageTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MMST | PRIMARY KEY | MessageTemplateID must be unique - enforced clustered |
| FK_DMGT_DMST | FOREIGN KEY | MessageTypeID must exist in Dictionary.MessageType - ensures only valid delivery channels are configured |
| FK_DPMT_DMST | FOREIGN KEY | PromotionTypeID must exist in Dictionary.PromotionType when not NULL - ensures only valid promotion categories are used |
| DMST_NAME | UNIQUE | Name must be unique across all templates - prevents duplicate template names in BackOffice UI |

---

## 8. Sample Queries

### 8.1 List all active templates by delivery channel

```sql
SELECT
    mt.MessageTemplateID,
    mt.Name,
    dmt.Name AS DeliveryChannel,
    mt.NumberOfParams,
    mt.Retention AS RetentionHours,
    ISNULL(dpt.Name, 'N/A') AS PromotionType,
    mt.Description
FROM Maintenance.MessageTemplate mt WITH (NOLOCK)
INNER JOIN Dictionary.MessageType dmt WITH (NOLOCK)
    ON mt.MessageTypeID = dmt.MessageTypeID
LEFT JOIN Dictionary.PromotionType dpt WITH (NOLOCK)
    ON mt.PromotionTypeID = dpt.PromotionTypeID
WHERE mt.IsActive = 1
ORDER BY dmt.Name, mt.Name
```

### 8.2 Find templates used for trading event notifications

```sql
SELECT
    mt.MessageTemplateID,
    mt.Name,
    mt.NumberOfParams,
    mt.Retention AS RetentionHours,
    mt.Description
FROM Maintenance.MessageTemplate mt WITH (NOLOCK)
WHERE mt.IsActive = 1
  AND mt.MessageTypeID IN (1, 2)  -- Dialog and Bar channels
  AND mt.PromotionTypeID IS NULL  -- Operational only, no promotions
ORDER BY mt.MessageTemplateID
```

### 8.3 Find all promotion templates with replaceability details

```sql
SELECT
    mt.MessageTemplateID,
    mt.Name,
    dmt.Name AS DeliveryChannel,
    dpt.Name AS PromotionType,
    dpt.IsReplaceable,
    mt.Retention AS RetentionHours,
    mt.IsActive,
    mt.Description
FROM Maintenance.MessageTemplate mt WITH (NOLOCK)
INNER JOIN Dictionary.MessageType dmt WITH (NOLOCK)
    ON mt.MessageTypeID = dmt.MessageTypeID
INNER JOIN Dictionary.PromotionType dpt WITH (NOLOCK)
    ON mt.PromotionTypeID = dpt.PromotionTypeID
ORDER BY dpt.PromotionTypeID, mt.IsActive DESC, mt.MessageTemplateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Maintenance.MessageTemplate | Type: Table | Source: etoro/etoro/Maintenance/Tables/Maintenance.MessageTemplate.sql*
