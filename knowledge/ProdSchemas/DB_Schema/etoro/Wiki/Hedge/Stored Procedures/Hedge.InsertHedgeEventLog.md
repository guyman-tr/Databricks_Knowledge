# Hedge.InsertHedgeEventLog

> Inserts a single lifecycle event (disconnect, reconnect, recovery) for a hedge server or related infrastructure component into the Hedge.EventLog audit table.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Writes to Hedge.EventLog |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.InsertHedgeEventLog` is the primary writer for `Hedge.EventLog`. It records a single hedge server operational event - connection, disconnection, reconnect, or recovery - with the precise event timestamp and a descriptive message.

Created in January 2016 to track hedge server availability, specifically to monitor disconnect, reconnect, and recovery cycles (code comment: "Keep track of HS Disconnect,Reconnect,Recovery"). The procedure is called by the hedge server itself (or its infrastructure layer) whenever a connectivity state change or alertable event occurs.

The procedure accepts all five EventLog columns directly as parameters and performs a single INSERT with no deduplication, no conditional logic, and no return value. It is intentionally minimal - a thin persistence layer that ensures the event is committed to the audit trail. KPI volume alert events (EventType=8) are written by a separate procedure (`Hedge.InsertKPIData`) which includes deduplication logic.

---

## 2. Business Logic

### 2.1 Lifecycle Event Recording

**What**: Persists one hedge server operational event to the audit trail.

**Columns/Parameters Involved**: `@HedgeServerID`, `@ServerType`, `@Occurred`, `@EventTypeID`, `@Message`

**Rules**:
- Maps directly to EventLog columns: (ServerID, ServerType, Occurred, EventType, Message).
- `OccurredInsert` (DB insert timestamp) is supplied by the EventLog DEFAULT = GETDATE() - not passed by this procedure.
- No deduplication - each call produces exactly one new row.
- EventType values: 1=Reconnect Primary, 2=Disconnect Primary, 3=Reconnect Backoffice, 4=Disconnect Backoffice, 5=Recovery Success, 6=Recovery Fail, 7=Exposures change to 0.
- EventType 8 (KPI volume alert - "Account Volume > Customer Volume") is NOT inserted via this procedure; it is written by `Hedge.InsertKPIData` which includes a NOT EXISTS dedup check.
- Reconnect events (types 1 and 3) and Disconnect events (types 2 and 4) typically appear in pairs at the same @Occurred timestamp (Primary + Backoffice channels simultaneously).

**Diagram**:
```
Hedge Server connectivity change
  |
  EXEC Hedge.InsertHedgeEventLog
      @HedgeServerID = 1,
      @ServerType    = 6,  -- 6=HedgeServer
      @Occurred      = <event timestamp>,
      @EventTypeID   = 2,  -- e.g., Disconnect Primary
      @Message       = ''
  |
  INSERT INTO Hedge.EventLog
      (ServerID, ServerType, Occurred, EventType, Message)
  VALUES
      (@HedgeServerID, @ServerType, @Occurred, @EventTypeID, @Message)
  |
  OccurredInsert = GETDATE() (from DEFAULT)
  |
  Row committed to audit trail
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | The hedge server (or server) that generated the event. Maps to EventLog.ServerID. Typically a Trade.HedgeServer ID when @ServerType=6. |
| 2 | @ServerType | INT | NO | - | CODE-BACKED | Type of server generating the event. Maps to EventLog.ServerType. FK to Dictionary.ServerType (implicit): 6=HedgeServer (all current data), 0=Unknown, 1=General, 2=Distributor, 4=DBBackOffice, etc. |
| 3 | @Occurred | DATETIME2 | NO | - | CODE-BACKED | Server-reported event timestamp with sub-millisecond precision. Stored as EventLog.Occurred - the authoritative event time used in all queries and deduplication checks. Should be the actual event time, not GETDATE(). |
| 4 | @EventTypeID | INT | NO | - | CODE-BACKED | Event classification. Maps to EventLog.EventType. FK to Dictionary.HedgeEventType (implicit): 1=Reconnect Primary, 2=Disconnect Primary, 3=Reconnect Backoffice, 4=Disconnect Backoffice, 5=Recovery Success, 6=Recovery Fail, 7=Exposures change to 0. EventType 8 (KPI volume alert) is NOT used here - see Hedge.InsertKPIData. |
| 5 | @Message | VARCHAR(255) | NO | - | CODE-BACKED | Optional descriptive message for the event. For connectivity events (types 1-4), typically empty string or NULL. Stored as EventLog.Message (nullable column accepts NULL despite non-nullable parameter declaration). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.EventLog | Writer (INSERT) | Inserts one lifecycle event row into the hedge server audit log |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.InsertHedgeEventLog (procedure)
+-- Hedge.EventLog (table) [INSERT - one lifecycle event row]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.EventLog | Table | Target of INSERT - records the lifecycle event |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo. | - | Called from hedge server application code. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Behavior | Not set in this procedure - row count message is returned to caller. No explicit transaction wrapping. |

---

## 8. Sample Queries

### 8.1 Record a hedge server disconnect event
```sql
EXEC [Hedge].[InsertHedgeEventLog]
    @HedgeServerID = 1,
    @ServerType    = 6,
    @Occurred      = '2026-03-19 08:30:00.0000000',
    @EventTypeID   = 2,  -- Disconnect Primary
    @Message       = ''
```

### 8.2 Verify recent event log entries for a server
```sql
SELECT TOP 20 ID, OccurredInsert, ServerID, Occurred, EventType, Message
FROM [Hedge].[EventLog] WITH (NOLOCK)
WHERE ServerID = 1
  AND Occurred > DATEADD(hour, -1, GETUTCDATE())
ORDER BY Occurred DESC
```

### 8.3 Check disconnect/reconnect pairs in the last day
```sql
SELECT Occurred, ServerID, EventType,
       DATEDIFF(ms, Occurred, OccurredInsert) AS LoggingLatencyMs,
       Message
FROM [Hedge].[EventLog] WITH (NOLOCK)
WHERE ServerID = 1
  AND EventType IN (1, 2, 3, 4)
  AND Occurred > DATEADD(day, -1, GETUTCDATE())
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL repo | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.InsertHedgeEventLog | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.InsertHedgeEventLog.sql*
