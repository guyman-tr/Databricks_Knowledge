# Dictionary.GetMessageType

> Filtered view returning only user-visible (non-hidden) message types from Dictionary.MessageType.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | MessageTypeID (from MessageType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetMessageType filters the MessageType lookup table to return only message types where IsHidden = 0 (visible). The full MessageType table contains 10 message delivery channels including some that are internal-only or system-level. This view provides a "safe default" that excludes hidden entries, ensuring that user-facing components (notification selectors, message type dropdowns, communication configuration UIs) never show internal message types.

Without this view, every consumer would need to remember to add `WHERE IsHidden = 0` to their queries. The view centralizes this filter, preventing accidental exposure of internal message types in customer-facing interfaces.

The 10 visible message types span the platform's communication channels: Dialog (modal popup), Bar (banner notification), Web (browser-based), Promotion (trade and cashier overlays), KICK (forced-action on login or chat), and Trade Block (trading suspension notification).

---

## 2. Business Logic

### 2.1 Message Type Visibility Filter

**What**: Separates user-facing message channels from internal/system-only channels.

**Columns/Parameters Involved**: `MessageTypeID`, `Name`, `IsHidden` (filter column, not output)

**Rules**:
- IsHidden = 0 → visible in this view (user-facing message types)
- IsHidden = 1 → excluded (internal/system message types, not shown to users)
- The base table Dictionary.MessageType has 10 rows total; all 10 pass the IsHidden=0 filter in the current data (no hidden types currently exist)
- Message types define HOW a message is delivered, not WHAT it contains — the message content is stored elsewhere

**Diagram**:
```
Dictionary.MessageType (10 rows)
│
├── IsHidden = 0 ──→ Dictionary.GetMessageType (visible)
│   ├── 1: Dialog         (modal popup)
│   ├── 2: Bar            (banner notification)
│   ├── 3: Web            (browser-based page)
│   ├── 4: Promotion (Cashier)  (deposit page overlay)
│   ├── 5: Promotion (Trade)    (trading page overlay)
│   ├── 6: WEB (On Exit)        (shown when user leaves)
│   ├── 7: KICK (On Login)      (forced action at login)
│   ├── 8: KICK (On Chat)       (forced action on chat)
│   ├── 9: WEB (Def Browser)    (default browser notification)
│   └── 10: Trade Block          (trading suspension notice)
│
└── IsHidden = 1 ──→ EXCLUDED (none currently exist)
```

---

## 3. Data Overview

| MessageTypeID | Name | Meaning |
|---|---|---|
| 1 | Dialog | Modal popup dialog displayed in the platform UI — used for important announcements, confirmations, and regulatory notices that require user acknowledgment |
| 2 | Bar | Banner/bar notification shown at the top or bottom of the trading platform — non-intrusive informational messages |
| 7 | KICK (On Login) | Forced-action message displayed immediately when a user logs in — used for mandatory compliance acknowledgments, account warnings, or platform-wide alerts |
| 10 | Trade Block | Trading suspension notification — displayed when a user's ability to trade is temporarily blocked (margin call, compliance hold, or platform maintenance) |
| 4 | Promotion (Cashier) | Promotional overlay displayed on the deposit/cashier page — used for deposit bonus offers, first-time deposit incentives, or payment method promotions |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageTypeID | int | NO | - | VERIFIED | Message delivery channel identifier. PK from Dictionary.MessageType. Values 1-10 define distinct notification/communication channels: 1=Dialog, 2=Bar, 3=Web, 4=Promotion(Cashier), 5=Promotion(Trade), 6=WEB(OnExit), 7=KICK(OnLogin), 8=KICK(OnChat), 9=WEB(DefBrowser), 10=TradeBlock. (Dictionary.MessageType) |
| 2 | Name | varchar(50) | YES | - | VERIFIED | Human-readable message type name describing the delivery channel. Used in BackOffice message configuration UIs and reporting. Inherited from Dictionary.MessageType.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageTypeID | Dictionary.MessageType | Base table (filtered) | Source data filtered on IsHidden = 0 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No direct SQL consumers found in SSDT project) | - | - | Likely consumed by application code directly rather than other SQL objects |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetMessageType (view)
└── Dictionary.MessageType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.MessageType | Table | Base table — filtered WHERE IsHidden = 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Consumed by application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Base table Dictionary.MessageType has a clustered PK on MessageTypeID.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all visible message types
```sql
SELECT  MessageTypeID, Name
FROM    Dictionary.GetMessageType WITH (NOLOCK)
ORDER BY MessageTypeID
```

### 8.2 Compare visible vs hidden message types
```sql
SELECT  mt.MessageTypeID, mt.Name, mt.IsHidden,
        CASE WHEN gmt.MessageTypeID IS NOT NULL THEN 'Visible' ELSE 'Hidden' END AS Visibility
FROM    Dictionary.MessageType mt WITH (NOLOCK)
LEFT JOIN Dictionary.GetMessageType gmt WITH (NOLOCK) ON gmt.MessageTypeID = mt.MessageTypeID
ORDER BY mt.MessageTypeID
```

### 8.3 Find KICK-type messages for forced user actions
```sql
SELECT  MessageTypeID, Name
FROM    Dictionary.GetMessageType WITH (NOLOCK)
WHERE   Name LIKE '%KICK%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetMessageType | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetMessageType.sql*
