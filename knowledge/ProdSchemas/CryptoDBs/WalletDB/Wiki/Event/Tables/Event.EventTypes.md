# Event.EventTypes

> Lookup table defining the types of one-time user interaction events tracked by the crypto wallet platform.

| Property | Value |
|----------|-------|
| **Schema** | Event |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 UNIQUE nonclustered on EventName |

---

## 1. Business Meaning

Event.EventTypes is a small lookup/enum table that defines the catalog of trackable user interaction events within the crypto wallet system. Each row represents a distinct one-time event that the platform needs to record per user - such as acknowledging a crypto disclosure or encountering a crypto-to-fiat conversion popup.

This table exists to provide a controlled vocabulary of event types that the Event.UserEvents table references. Without it, user event tracking would rely on free-text strings rather than a normalized, extensible set of event type definitions. The IsActive flag allows event types to be retired without data loss.

Data flow: Rows are seeded by administrators or deployment scripts (no WRITER procedures exist in the Event schema for this table). The table is consumed by Event.GetUserEventsStatus, which joins it with Event.UserEvents to produce per-user event completion counts. Event.RegisterUserEvent writes to Event.UserEvents referencing EventTypeId values from this table.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup table with an active/inactive flag. See individual element descriptions in Section 4.

### 2.1 Event Tracking Pattern

**What**: Each event type represents a one-time user interaction that the system needs to record and query.

**Columns/Parameters Involved**: `Id`, `EventName`, `IsActive`

**Rules**:
- Each event type has a unique name enforced by a UNIQUE constraint on EventName
- Only active event types (IsActive = 1) are returned by Event.GetUserEventsStatus when counting user event completion
- Event types are not deleted - they are deactivated via IsActive = 0

**Diagram**:
```
Event.EventTypes (lookup)          Event.UserEvents (fact)
+----+------------------------+    +----+------+-------------+
| Id | EventName              |    | Id | Gcid | EventTypeId |
+----+------------------------+    +----+------+-------------+
|  1 | NewC2FPopup            |<---| .. | 1234 |      1      |
|  2 | UserCryptoDisclosure   |<---| .. | 1234 |      2      |
+----+------------------------+    +----+------+-------------+
         |                                    |
         v                                    v
  GetUserEventsStatus(Gcid) ----> EventType | Count
                                       1    |   1
                                       2    |   1
```

---

## 3. Data Overview

| Id | EventName | IsActive | Meaning |
|----|-----------|----------|---------|
| 1 | NewC2FPopup | true | Tracks whether a user has seen the crypto-to-fiat (C2F) conversion popup. Used to ensure the informational popup is shown once per user before their first fiat conversion. |
| 2 | UserCryptoDisclosure | true | Tracks whether a user has acknowledged the crypto disclosure document. Required for regulatory compliance before the user can interact with cryptocurrency features. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int IDENTITY(1,1) | NO | (identity) | CODE-BACKED | Auto-incrementing primary key. Referenced by Event.UserEvents.EventTypeId (FK). Used as the event type identifier across all event tracking queries. Currently 1=NewC2FPopup, 2=UserCryptoDisclosure. |
| 2 | EventName | varchar(255) | YES | - | CODE-BACKED | Human-readable name identifying the event type. Enforced unique by a UNIQUE constraint. Values follow PascalCase naming convention (e.g., "NewC2FPopup", "UserCryptoDisclosure"). Used for display and lookup purposes - the Id column is used for joins. |
| 3 | IsActive | bit | YES | - | CODE-BACKED | Controls whether this event type is currently tracked. Event.GetUserEventsStatus filters on IsActive = 1 to only return active event types when counting user event completions. 1 = active (event type is in use), 0/NULL = inactive (retired, no longer tracked). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Event.UserEvents | EventTypeId | FK | Each user event record references the event type it tracks. FK constraint FK_Event_UserEvents_EventTypeId_Event_EventTypes_Id enforces referential integrity. |
| Event.GetUserEventsStatus | et.Id | JOIN | Joins EventTypes to UserEvents to count how many times each active event type has been completed by a given user (GCID). |
| Event.RegisterUserEvent | @EventTypeId | Parameter | Accepts an EventTypeId parameter that must correspond to a valid Id in this table (enforced by the FK on UserEvents). |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Event.UserEvents | Table | FK reference - EventTypeId column references EventTypes.Id |
| Event.GetUserEventsStatus | Stored Procedure | READER - joins EventTypes with UserEvents, filters by IsActive = 1 |
| Event.RegisterUserEvent | Stored Procedure | Indirect - inserts into UserEvents with EventTypeId values from this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_EventTypes | CLUSTERED PK | Id ASC | - | - | Active |
| UQ_EventTypes_EventName | NC UNIQUE | EventName ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_EventTypes | PRIMARY KEY | Clustered on Id. Ensures each event type has a unique integer identifier. PAGE compression enabled. |
| (unnamed) | UNIQUE | On EventName. Prevents duplicate event type names, ensuring each event is defined exactly once. |

---

## 8. Sample Queries

### 8.1 List all active event types
```sql
SELECT Id, EventName, IsActive
FROM Event.EventTypes WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY Id
```

### 8.2 Check which events a specific user has completed
```sql
SELECT et.EventName, 
       CASE WHEN ue.Id IS NOT NULL THEN 'Completed' ELSE 'Pending' END AS Status,
       ue.Occurred
FROM Event.EventTypes et WITH (NOLOCK)
LEFT JOIN Event.UserEvents ue WITH (NOLOCK) 
    ON et.Id = ue.EventTypeId AND ue.Gcid = @Gcid
WHERE et.IsActive = 1
ORDER BY et.Id
```

### 8.3 Count users who completed each event type
```sql
SELECT et.Id, et.EventName, COUNT(DISTINCT ue.Gcid) AS UserCount
FROM Event.EventTypes et WITH (NOLOCK)
LEFT JOIN Event.UserEvents ue WITH (NOLOCK) ON et.Id = ue.EventTypeId
WHERE et.IsActive = 1
GROUP BY et.Id, et.EventName
ORDER BY et.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.3/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Event.EventTypes | Type: Table | Source: WalletDB/Event/Tables/Event.EventTypes.sql*
