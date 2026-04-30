# Dictionary.MessageType

> Classifies the delivery channels and display formats for real-time messages and promotional notifications sent to users within the trading platform.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MessageTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique NC on Name |

---

## 1. Business Meaning

Dictionary.MessageType defines how real-time messages are delivered to users on the trading platform. Each type represents a distinct UI delivery mechanism — modal dialogs, notification bars, web popups, promotional banners, login kick messages, and trade blocking overlays. The IsHidden flag controls whether the message type appears in BackOffice message configuration screens.

Without this table, the messaging infrastructure could not differentiate between message delivery channels. The system needs to know whether to show a blocking dialog, a dismissible banner, or trigger a browser redirect based on the message type.

Referenced by the Broker messaging subsystem and viewed through Dictionary.GetMessageType (which filters to non-hidden types). Used by BackOffice staff to configure targeted messages for specific users or customer segments.

---

## 2. Business Logic

### 2.1 Message Delivery Channels

**What**: Ten distinct ways to deliver messages to users, from passive bars to blocking overlays.

**Columns/Parameters Involved**: `MessageTypeID`, `Name`, `IsHidden`

**Rules**:
- Dialog (1): Modal popup requiring user acknowledgment
- Bar (2): Non-blocking notification bar at top/bottom of screen
- Web (3): Web-based notification (in-app banner)
- Promotion (Cashier) (4): Promotional message shown in the deposit/cashier flow
- Promotion (Trade) (5): Promotional message shown in the trading interface
- WEB (On Exit) (6): Message triggered when user attempts to leave the platform
- KICK (On Login) (7): Forces content display immediately at login
- KICK (On Chat) (8): Forces content when user opens chat
- WEB (Def Browser) (9): Opens in default browser outside the app
- Trade Block (10): Blocking overlay preventing trading until acknowledged
- Currently all types have IsHidden=false (all visible in BackOffice)

---

## 3. Data Overview

| MessageTypeID | Name | IsHidden | Meaning |
|---|---|---|---|
| 1 | Dialog | false | Modal dialog requiring explicit user dismissal — used for critical announcements, regulatory notices, and mandatory acknowledgments |
| 7 | KICK (On Login) | false | Forces content display at login — used for compliance notices or urgent account messages that cannot be skipped |
| 10 | Trade Block | false | Overlays the trading interface to prevent any trading activity until the user acknowledges the message — used for margin calls or regulatory holds |
| 4 | Promotion (Cashier) | false | Targeted promotional message in the deposit flow — used to encourage specific funding actions or highlight bonuses |
| 6 | WEB (On Exit) | false | Exit-intent message triggered when user navigates away — used for retention campaigns or uncompleted action reminders |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageTypeID | int | NO | - | CODE-BACKED | Unique identifier for the message delivery channel: 1=Dialog, 2=Bar, 3=Web, 4=Promotion (Cashier), 5=Promotion (Trade), 6=WEB (On Exit), 7=KICK (On Login), 8=KICK (On Chat), 9=WEB (Def Browser), 10=Trade Block. |
| 2 | Name | varchar(20) | NO | - | VERIFIED | Short label describing the delivery mechanism. Enforced unique by index DMGT_NAME. Displayed in BackOffice message configuration. |
| 3 | IsHidden | bit | NO | - | CODE-BACKED | Controls visibility in BackOffice message type selection: 0=visible (available for message configuration), 1=hidden (deprecated or system-only). Currently all types are visible (0). Filtered by Dictionary.GetMessageType view. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.GetMessageType | MessageTypeID | View | Filters to non-hidden message types for BackOffice UI |
| Maintenance.MessageTemplate | MessageTypeID | FK | Each message template specifies its delivery channel via this table |
| Broker messaging subsystem | MessageTypeID | Implicit | Routes messages to appropriate delivery channel |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.GetMessageType | View | Filters visible message types |
| Maintenance.MessageTemplate | Table | FK reference - MessageTypeID identifies delivery channel per template |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMGT | CLUSTERED PK | MessageTypeID | - | - | Active |
| DMGT_NAME | NC UNIQUE | Name | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all message types
```sql
SELECT  MessageTypeID,
        Name,
        IsHidden
FROM    [Dictionary].[MessageType] WITH (NOLOCK)
ORDER BY MessageTypeID;
```

### 8.2 List only visible (non-hidden) message types
```sql
SELECT  MessageTypeID,
        Name
FROM    [Dictionary].[MessageType] WITH (NOLOCK)
WHERE   IsHidden = 0
ORDER BY MessageTypeID;
```

### 8.3 Use the view for BackOffice-safe listing
```sql
SELECT  *
FROM    [Dictionary].[GetMessageType] WITH (NOLOCK)
ORDER BY MessageTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MessageType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MessageType.sql*
