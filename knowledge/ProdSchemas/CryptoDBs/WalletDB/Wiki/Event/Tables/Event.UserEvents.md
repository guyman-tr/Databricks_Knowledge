# Event.UserEvents

> Fact table recording one-time user interaction events (popups, disclosures) per user in the crypto wallet platform, keyed by user, event type, and a unique event identifier.

| Property | Value |
|----------|-------|
| **Schema** | Event |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) + 1 NC on (Gcid, EventTypeId, EventIdentifier) |

---

## 1. Business Meaning

Event.UserEvents is the central fact table for the user event tracking subsystem of the crypto wallet platform. Each row records that a specific user (Gcid) experienced a specific event type (e.g., seeing the crypto-to-fiat popup, acknowledging a crypto disclosure) for a specific context identified by EventIdentifier (a GUID). This enables the platform to track which one-time interactions each user has completed.

This table exists to support compliance and UX requirements: the platform needs to know whether a user has already seen a mandatory popup or acknowledged a required disclosure, so it can avoid showing it again - or enforce that it must be seen before proceeding. Without this table, the application would have no persistent record of these user interactions.

Data flow: Rows are created exclusively by `Event.RegisterUserEvent`, which uses an INSERT-if-not-exists pattern to prevent duplicate registrations for the same (Gcid, EventTypeId, EventIdentifier) combination. The table is read by `Event.GetUserEventsStatus`, which counts how many events of each active type a user has completed. `Event.GetConversionToFiatTransactionCountByStatus` does not directly reference this table - it queries the Wallet schema instead.

---

## 2. Business Logic

### 2.1 Idempotent Event Registration

**What**: The system ensures each user-event-identifier combination is recorded at most once, using an application-level deduplication check rather than a UNIQUE constraint.

**Columns/Parameters Involved**: `Gcid`, `EventTypeId`, `EventIdentifier`

**Rules**:
- `Event.RegisterUserEvent` checks `IF NOT EXISTS (SELECT * FROM Event.UserEvents WHERE Gcid = @Gcid AND EventTypeId = @EventTypeId AND EventIdentifier = @EventIdentifier)` before inserting
- This means the same user can have MANY events of the same type - each with a different EventIdentifier (GUID). Data shows one user with 1,383 NewC2FPopup events, each for a distinct conversion context.
- The NC index on (Gcid, EventTypeId, EventIdentifier) supports this deduplication check efficiently
- The dedup is enforced in code, not by a DB UNIQUE constraint - concurrent calls could theoretically create duplicates

### 2.2 Event Completion Counting

**What**: The system counts how many times each active event type has been completed by a given user.

**Columns/Parameters Involved**: `EventTypeId`, `Gcid`, `Id` (counted)

**Rules**:
- `Event.GetUserEventsStatus` LEFT JOINs Event.EventTypes with Event.UserEvents on EventTypeId and Gcid
- Only active event types (IsActive = 1) are included
- Returns a count per event type - a count of 0 means the user has never triggered that event type
- Optional filtering by specific EventTypeId (when @EventTypeId != 0)

**Diagram**:
```
RegisterUserEvent(@Gcid, @EventTypeId, @EventIdentifier)
    |
    v
[Dedup Check] --exists--> (no-op, return)
    |
    not exists
    v
INSERT INTO UserEvents (Gcid, EventTypeId, EventIdentifier)
    Occurred = GETUTCDATE() (default)

GetUserEventsStatus(@Gcid, @EventTypeId=0)
    |
    v
EventTypes LEFT JOIN UserEvents ON EventTypeId + Gcid
    |
    v
Returns: EventType | Count  (per active event type)
```

---

## 3. Data Overview

| Id | Gcid | EventTypeId | EventIdentifier | Occurred | Meaning |
|----|------|-------------|-----------------|----------|---------|
| 649890 | 10885549 | 1 | a420683b-... | 2026-04-14 | User 10885549 saw the crypto-to-fiat conversion popup for a specific conversion context. Most recent event in the table. |
| 647381 | 19718567 | 2 | 3c2fec14-... | 2026-03-03 | User 19718567 acknowledged the crypto disclosure. Type 2 events are less frequent (30% of total). |
| 649881 | 18639318 | 1 | 5bf312bb-... | 2026-04-12 | Another C2F popup event. The EventIdentifier GUID distinguishes this from other popups the same user may have seen. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint IDENTITY(1,1) | NO | (identity) | CODE-BACKED | Auto-incrementing surrogate primary key. Bigint type accommodates the high volume of events (639K+ rows and growing). Used in GetUserEventsStatus as the COUNT target. |
| 2 | Gcid | bigint | YES | - | CODE-BACKED | Global Customer ID identifying the user who triggered the event. Despite being nullable in DDL, no NULL values exist in practice - RegisterUserEvent always requires @Gcid. Part of the composite dedup key (Gcid + EventTypeId + EventIdentifier) and the covering NC index. |
| 3 | EventTypeId | int | NO | - | CODE-BACKED | FK to Event.EventTypes.Id. Identifies the category of event: 1=NewC2FPopup (crypto-to-fiat conversion popup), 2=UserCryptoDisclosure (crypto disclosure acknowledgment). See [Event.EventTypes](Event.EventTypes.md). Distribution: 69.7% type 1, 30.3% type 2. |
| 4 | EventIdentifier | varchar(80) | YES | - | CODE-BACKED | A GUID string uniquely identifying the specific context/instance of the event. For C2F popups, this likely represents the specific conversion session or transaction context. Enables multiple events of the same type per user - each with a unique identifier. Part of the composite dedup key checked by RegisterUserEvent. Despite being nullable, no NULLs exist in practice. |
| 5 | Occurred | datetime2(7) | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of when the event was recorded. Defaults to GETUTCDATE() on INSERT - RegisterUserEvent does not explicitly set this column, relying on the default. Date range spans from 2023-02-05 (system inception) to present, confirming continuous use over 3+ years. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventTypeId | Event.EventTypes | FK | Each user event references a defined event type. Enforced by FK constraint FK_Event_UserEvents_EventTypeId_Event_EventTypes_Id. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Event.GetUserEventsStatus | ue (alias) | JOIN | LEFT JOINs UserEvents on EventTypeId and Gcid to count event completions per type per user. |
| Event.RegisterUserEvent | INSERT target | WRITER | The sole writer to this table. Uses INSERT-if-not-exists pattern with dedup on (Gcid, EventTypeId, EventIdentifier). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Event.UserEvents (table)
└── Event.EventTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Event.EventTypes | Table | FK reference - EventTypeId column references EventTypes.Id |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Event.GetUserEventsStatus | Stored Procedure | READER - LEFT JOINs on EventTypeId and Gcid to count events per type |
| Event.RegisterUserEvent | Stored Procedure | WRITER - inserts new event records with dedup check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_UserEvents | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Event_UserEvents_Gcid_Event_Type_Id_EventIdentifier | NONCLUSTERED | Gcid ASC, EventTypeId ASC, EventIdentifier ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserEvents | PRIMARY KEY | Clustered on Id. PAGE compression enabled. |
| FK_Event_UserEvents_EventTypeId_Event_EventTypes_Id | FOREIGN KEY | EventTypeId references Event.EventTypes(Id). Ensures only valid event types are recorded. |
| DF_Event_UserEvents__Occurred | DEFAULT | GETUTCDATE() for Occurred column. Automatically timestamps event registration in UTC. |

---

## 8. Sample Queries

### 8.1 Get all events for a specific user
```sql
SELECT ue.Id, et.EventName, ue.EventIdentifier, ue.Occurred
FROM Event.UserEvents ue WITH (NOLOCK)
JOIN Event.EventTypes et WITH (NOLOCK) ON ue.EventTypeId = et.Id
WHERE ue.Gcid = @Gcid
ORDER BY ue.Occurred DESC
```

### 8.2 Check if a specific user-event-identifier combination exists (mirrors RegisterUserEvent logic)
```sql
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM Event.UserEvents WITH (NOLOCK)
    WHERE Gcid = @Gcid AND EventTypeId = @EventTypeId AND EventIdentifier = @EventIdentifier
) THEN 'Already registered' ELSE 'Not registered' END AS Status
```

### 8.3 Count distinct users per event type
```sql
SELECT et.EventName, COUNT(DISTINCT ue.Gcid) AS UniqueUsers, COUNT(*) AS TotalEvents
FROM Event.UserEvents ue WITH (NOLOCK)
JOIN Event.EventTypes et WITH (NOLOCK) ON ue.EventTypeId = et.Id
WHERE et.IsActive = 1
GROUP BY et.EventName
ORDER BY TotalEvents DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.7/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Event.UserEvents | Type: Table | Source: WalletDB/Event/Tables/Event.UserEvents.sql*
