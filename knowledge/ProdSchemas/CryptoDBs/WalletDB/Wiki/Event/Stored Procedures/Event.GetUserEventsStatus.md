# Event.GetUserEventsStatus

> Returns the count of recorded events per active event type for a given user, optionally filtered to a specific event type.

| Property | Value |
|----------|-------|
| **Schema** | Event |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set: EventType (int), Count (int) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure answers the question "How many times has this user completed each tracked event?" It returns one row per active event type with the count of matching UserEvents records for the given user (GCID). If a user has never completed an event type, that type still appears with Count = 0 (thanks to the LEFT JOIN from EventTypes).

The procedure serves the wallet front-end by enabling it to determine which mandatory user interactions (crypto disclosure acknowledgments, C2F popups) have been completed. For example, the UI can call this to check if a user has already acknowledged the crypto disclosure before showing the crypto features, or how many C2F popup events have been recorded for the user.

Data flow: Called by the back-end API service (granted to BackApiUser). Reads from Event.EventTypes (to get the list of active event types) and Event.UserEvents (to count completions per user). Does not write to any table.

---

## 2. Business Logic

### 2.1 Active Event Type Enumeration with Completion Count

**What**: Returns ALL active event types with their per-user completion counts, including zero-count types.

**Columns/Parameters Involved**: `@Gcid`, `@EventTypeId`, `et.Id`, `et.IsActive`, `ue.EventTypeId`

**Rules**:
- LEFT JOIN ensures event types with no user events still appear (Count = 0) - the application needs to know about events the user has NOT yet completed
- Only active event types (et.IsActive = 1) are included - retired event types are excluded
- When @EventTypeId = 0 (default), all active types are returned
- When @EventTypeId != 0, only the specified type is returned
- Count represents the number of distinct EventIdentifiers the user has for that type (a user can trigger the same event type multiple times with different identifiers)

**Diagram**:
```
@Gcid = 12345, @EventTypeId = 0 (all)

EventTypes (active)         UserEvents (for Gcid 12345)
+----+----------------------+    +----+---------+
| Id | EventName            |    | Id | TypeId  |
+----+----------------------+    +----+---------+
|  1 | NewC2FPopup          |<---|  x |    1    | (3 records)
|  2 | UserCryptoDisclosure |<---|  y |    2    | (1 record)
+----+----------------------+    +----+---------+

Result:
| EventType | Count |
|-----------|-------|
|     1     |   3   |
|     2     |   1   |
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID of the user to check. Used to filter Event.UserEvents. |
| 2 | @EventTypeId | INT (IN) | NO | 0 | CODE-BACKED | Optional event type filter. 0 = return all active types (default). Non-zero = return only that specific event type. Maps to Event.EventTypes.Id: 1=NewC2FPopup, 2=UserCryptoDisclosure. |
| 3 | EventType (output) | INT (result set) | NO | - | CODE-BACKED | The event type ID from Event.EventTypes. Aliased from et.Id. |
| 4 | Count (output) | INT (result set) | NO | - | CODE-BACKED | Number of Event.UserEvents records for this user and event type. 0 if the user has never triggered this event type. Counts all records (different EventIdentifiers) - not just distinct events. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| et (alias) | Event.EventTypes | FROM | Drives the result set - one row per active event type. Filtered by IsActive = 1. |
| ue (alias) | Event.UserEvents | LEFT JOIN | Joined on et.Id = ue.EventTypeId AND ue.Gcid = @Gcid to count per-user event completions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | EXECUTE permission | Caller | The back-end API service account has EXECUTE permission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Event.GetUserEventsStatus (procedure)
├── Event.EventTypes (table)
└── Event.UserEvents (table)
    └── Event.EventTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Event.EventTypes | Table | FROM - source of active event type list |
| Event.UserEvents | Table | LEFT JOIN - source of per-user event records |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all event statuses for a user
```sql
EXEC Event.GetUserEventsStatus @Gcid = 12345678
-- Returns all active event types with completion counts
```

### 8.2 Check a specific event type for a user
```sql
EXEC Event.GetUserEventsStatus @Gcid = 12345678, @EventTypeId = 2
-- Returns only UserCryptoDisclosure count for this user
```

### 8.3 Equivalent manual query showing the logic
```sql
SELECT et.Id AS EventType, COUNT(ue.Id) AS Count
FROM Event.EventTypes et WITH (NOLOCK)
LEFT JOIN Event.UserEvents ue WITH (NOLOCK)
    ON et.Id = ue.EventTypeId AND ue.Gcid = @Gcid
WHERE et.IsActive = 1
GROUP BY et.Id
ORDER BY et.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Event.GetUserEventsStatus | Type: Stored Procedure | Source: WalletDB/Event/Stored Procedures/Event.GetUserEventsStatus.sql*
