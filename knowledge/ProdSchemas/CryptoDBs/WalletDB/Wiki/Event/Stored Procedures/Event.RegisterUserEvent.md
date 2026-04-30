# Event.RegisterUserEvent

> Registers a one-time user interaction event using an idempotent insert-if-not-exists pattern, preventing duplicate registrations for the same user, event type, and event identifier.

| Property | Value |
|----------|-------|
| **Schema** | Event |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No output - void operation (INSERT only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the sole entry point for recording user interaction events in the crypto wallet platform. When a user encounters a tracked event (e.g., seeing the crypto-to-fiat conversion popup or acknowledging the crypto disclosure), the application calls this procedure to persist that fact. The idempotent design means the same call can be made multiple times safely - only the first call for a given (Gcid, EventTypeId, EventIdentifier) combination creates a row.

The procedure exists to decouple event registration from event querying. While `Event.GetUserEventsStatus` reads event completion data, this procedure handles the write side. The separation allows the read and write paths to be optimized independently. The EXECUTE AS OWNER clause indicates elevated permissions are needed for the INSERT operation.

Data flow: Called by the back-end API service (granted to BackApiUser) when a user interaction event occurs. Reads from Event.UserEvents (NOLOCK) to check for existing records, then conditionally INSERTs a new row. The `Occurred` column is not explicitly set - it defaults to GETUTCDATE() via the table's DEFAULT constraint.

---

## 2. Business Logic

### 2.1 Idempotent Insert Pattern

**What**: Ensures each user-event-identifier combination is recorded at most once, using a read-then-write pattern rather than a database constraint.

**Columns/Parameters Involved**: `@Gcid`, `@EventTypeId`, `@EventIdentifier`

**Rules**:
- First checks: IF NOT EXISTS (SELECT * FROM Event.UserEvents WHERE Gcid = @Gcid AND EventTypeId = @EventTypeId AND EventIdentifier = @EventIdentifier)
- The NOLOCK hint on the existence check means a concurrent call could pass the check simultaneously, potentially creating a duplicate (no UNIQUE constraint exists on the table to prevent this)
- Only if no matching row exists does the INSERT execute
- The INSERT sets only Gcid, EventTypeId, and EventIdentifier - the Occurred timestamp is set by the DEFAULT constraint (GETUTCDATE())
- No validation is performed on @EventTypeId against Event.EventTypes - the FK constraint on Event.UserEvents enforces referential integrity at the table level

**Diagram**:
```
RegisterUserEvent(@Gcid, @EventTypeId, @EventIdentifier)
    |
    v
SELECT FROM UserEvents (NOLOCK)
WHERE Gcid = @Gcid
  AND EventTypeId = @EventTypeId
  AND EventIdentifier = @EventIdentifier
    |
    +-- EXISTS --> Return (no-op, idempotent)
    |
    +-- NOT EXISTS
         |
         v
    INSERT INTO UserEvents
    (Gcid, EventTypeId, EventIdentifier)
    VALUES (@Gcid, @EventTypeId, @EventIdentifier)
    -- Occurred = GETUTCDATE() (default)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT (IN) | NO | - | CODE-BACKED | Global Customer ID of the user triggering the event. Written directly to Event.UserEvents.Gcid. |
| 2 | @EventTypeId | INT (IN) | NO | - | CODE-BACKED | Event type to register. Must be a valid Event.EventTypes.Id (enforced by FK). 1=NewC2FPopup, 2=UserCryptoDisclosure. See [Event.EventTypes](../Tables/Event.EventTypes.md). |
| 3 | @EventIdentifier | VARCHAR(80) (IN) | NO | - | CODE-BACKED | A GUID string identifying the specific context/instance of the event (e.g., a specific conversion session). Part of the dedup key - the same user can have multiple events of the same type with different identifiers. Written directly to Event.UserEvents.EventIdentifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT target | Event.UserEvents | WRITER | Inserts new event records. Also reads (SELECT with NOLOCK) for dedup check. |
| @EventTypeId | Event.EventTypes | Implicit (via FK on UserEvents) | The FK on UserEvents.EventTypeId enforces that only valid event types can be registered. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | EXECUTE permission | Caller | The back-end API service account has EXECUTE permission. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Event.RegisterUserEvent (procedure)
└── Event.UserEvents (table)
    └── Event.EventTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Event.UserEvents | Table | SELECT (dedup check) + INSERT (event registration) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| EXECUTE AS OWNER | Security | Procedure runs under the schema owner's context, elevating permissions for the INSERT operation. |

---

## 8. Sample Queries

### 8.1 Register a C2F popup event for a user
```sql
EXEC Event.RegisterUserEvent 
    @Gcid = 12345678, 
    @EventTypeId = 1, 
    @EventIdentifier = 'a420683b-f80e-4889-bd41-2dfda28cf43c'
```

### 8.2 Register a crypto disclosure acknowledgment
```sql
EXEC Event.RegisterUserEvent 
    @Gcid = 12345678, 
    @EventTypeId = 2, 
    @EventIdentifier = '3c2fec14-a19b-4a6f-ba97-c984c2e55492'
```

### 8.3 Verify the idempotent behavior (second call is a no-op)
```sql
-- First call creates the row
EXEC Event.RegisterUserEvent @Gcid = 99999, @EventTypeId = 1, @EventIdentifier = 'test-guid'
-- Second identical call does nothing (row already exists)
EXEC Event.RegisterUserEvent @Gcid = 99999, @EventTypeId = 1, @EventIdentifier = 'test-guid'
-- Verify only one row was created
SELECT COUNT(*) FROM Event.UserEvents WITH (NOLOCK) 
WHERE Gcid = 99999 AND EventTypeId = 1 AND EventIdentifier = 'test-guid'
-- Returns 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (self) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Event.RegisterUserEvent | Type: Stored Procedure | Source: WalletDB/Event/Stored Procedures/Event.RegisterUserEvent.sql*
