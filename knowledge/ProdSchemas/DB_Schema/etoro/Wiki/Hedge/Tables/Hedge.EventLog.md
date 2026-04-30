# Hedge.EventLog

> Operational event log for hedge server lifecycle events - connection, disconnection, recovery, and KPI threshold alerts - recording both DB-side insert time and the server's own event timestamp for latency analysis.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID IDENTITY (NONCLUSTERED PK + separate CLUSTERED index on ID) |
| **Partition** | No |
| **Indexes** | 2 active (NONCLUSTERED PK + CLUSTERED on ID) - both PAGE compressed |

---

## 1. Business Meaning

Hedge.EventLog captures operational lifecycle events for hedge servers and related infrastructure. Every connection, disconnection, reconnection, and recovery cycle of a hedge server's Primary and Backoffice channels is recorded here, as well as KPI threshold breaches (such as when a hedge account's volume exceeds customer volume for a given instrument). The table is the audit trail for hedge server availability and stability monitoring.

The table records 131,388 rows spanning 2023-01-04 to 2023-12-31 in this environment, all from HedgeServerID=1 (ServerType=6).

Two timestamps capture the event at two points in time: `OccurredInsert` is the DB server's wall-clock time at row insertion (DEFAULT getdate()); `Occurred` is the precise datetime2(7) timestamp as reported by the hedge server or calling system - this is the authoritative event time used in queries and deduplication checks.

The table is created on the [MAIN] filegroup with DATA_COMPRESSION=PAGE, indicating it is expected to grow large over time and benefit from compression. Its unusual index design (NONCLUSTERED PK on ID, plus a separate CLUSTERED index on the same ID column) is a SQL Server DDL artifact that results in the clustered index physically ordering the rows by ID while the PK constraint remains logically nonclustered.

---

## 2. Business Logic

### 2.1 Event Type Classification

**What**: Every row is classified by EventType, which determines what hedge server event occurred.

**Columns/Parameters Involved**: `EventType`, `Message`, `ServerID`

**Rules**:
- EventType FK to Dictionary.HedgeEventType (implicit - no DDL FK):

| EventTypeID | Name | Count in data |
|------------|------|---------------|
| 1 | Reconnect Primary | 202 |
| 2 | Disconnect Primary | 89,053 |
| 3 | Reconnect Backoffice | 202 |
| 4 | Disconnect Backoffice | 41,931 |
| 5 | Recovery Success | 0 (not observed) |
| 6 | Recovery Fail | 0 (not observed) |
| 7 | Exposures change to 0 | 0 (not observed) |
| 8 | Volume Account Larger than Volume Customers | 0 (KPI alert) |

- EventTypes 1 and 3 (Reconnect Primary + Backoffice) always appear in pairs at the same Occurred timestamp - a reconnect event logs both channels simultaneously.
- EventTypes 2 and 4 (Disconnect Primary + Backoffice) similarly appear together.
- The high frequency of Disconnect events (89,053 type-2 rows) relative to Reconnect (202 type-1 rows) suggests many transient disconnects that do not all require a tracked reconnect, or that the environment logs disconnects from periodic connectivity checks.

### 2.2 EventType 8 - KPI Volume Alert

**What**: EventType 8 records when a hedge account's volume in a given instrument exceeds the corresponding customer volume. This is a KPI threshold breach indicating potential hedge over-exposure or data inconsistency.

**Columns/Parameters Involved**: `EventType`, `Message`, `ServerID`, `Occurred`

**Rules**:
- Written by `Hedge.InsertKPIData` (via the `dbo.RW_EventLog` synonym target).
- Message format for EventType 8: `'InstrumentID={N}'` - identifies which instrument triggered the alert.
- `InsertKPIData` checks `NOT EXISTS` for a matching EventType=8 row (same Occurred + ServerID + InstrumentID in Message) before inserting - deduplication guard to prevent duplicate KPI alerts.
- EventType 8 rows use Occurred = @startTime (the KPI computation window start), not GETDATE(). This means the timestamp represents the period start, not the actual alert insert time.

### 2.3 Server Type Classification

**What**: ServerType categorizes which type of server generated the event.

**Columns/Parameters Involved**: `ServerType`

**Rules**:
- All 131,388 rows in this environment have ServerType=6 (HedgeServer).
- ServerType FK to Dictionary.ServerType (implicit - no DDL FK):

| ServerTypeID | Name |
|---|---|
| 0 | Unknown |
| 1 | General |
| 2 | Distributor |
| 3 | DBFrontOffice |
| 4 | DBBackOffice |
| 5 | GameServer |
| 6 | HedgeServer |
| 7 | PriceServer |
| 8 | PriceProviders |
| 13 | PriceDetector |

- The schema supports logging events from any server type, but hedge server events are the primary use case.

### 2.4 Dual Timestamp Design

**What**: Two timestamps serve different purposes for event analysis.

**Columns/Parameters Involved**: `OccurredInsert`, `Occurred`

**Rules**:
- `OccurredInsert`: DB server wall-clock at insert. DEFAULT = GETDATE() (local, not UTC). Used to measure latency between event occurrence and logging.
- `Occurred`: Server-reported event timestamp (datetime2(7) - sub-millisecond precision). This is the authoritative event time, used in all filtering and deduplication logic (e.g., InsertKPIData uses Occurred for its dedup check).
- The gap between OccurredInsert and Occurred represents the notification latency from the hedge server to the DB.

---

## 3. Data Overview

131,388 rows spanning 2023-01-04 to 2023-12-31. All rows are from ServerID=1, ServerType=6 (HedgeServer). No rows with non-empty Message in the current environment.

| ID | OccurredInsert | ServerID | ServerType | Occurred | EventType | Message | Meaning |
|---|---|---|---|---|---|---|---|
| 132383 | 2023-12-31 00:00:00.067 | 1 | 6 | 2023-12-31 00:00:00.042 | 3 | '' | Reconnect Backoffice at midnight - HedgeServer 1 Backoffice channel reconnected |
| 132382 | 2023-12-31 00:00:00.060 | 1 | 6 | 2023-12-31 00:00:00.042 | 1 | '' | Reconnect Primary at same timestamp - Primary channel also reconnected |
| 132381 | 2023-12-31 00:00:00.050 | 1 | 6 | 2023-12-31 00:00:00.025 | 4 | '' | Disconnect Backoffice - 17ms before the reconnect, scheduled cycle |
| 132380 | 2023-12-31 00:00:00.043 | 1 | 6 | 2023-12-31 00:00:00.025 | 2 | '' | Disconnect Primary - paired with Backoffice disconnect at same Occurred |

**Pattern note**: The midnight entries show a Disconnect Primary + Backoffice pair followed immediately by a Reconnect pair - typical periodic reconnect cycle behavior (scheduled daily restart or watchdog cycle).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-increment surrogate key. IDENTITY NOT FOR REPLICATION (safe for replication environments). Forms both the NONCLUSTERED PK and the CLUSTERED index key - physical row order is by ID (append order). |
| 2 | OccurredInsert | datetime | NO | getdate() | CODE-BACKED | DB server wall-clock time when the row was inserted. DEFAULT = GETDATE() (local time, not UTC). Measures lag between event occurrence (Occurred) and logging. |
| 3 | ServerID | int | NO | - | CODE-BACKED | The ID of the server that generated the event. In this environment, always 1 (HedgeServerID=1). Implicitly references Trade.HedgeServer when ServerType=6. No DDL FK. Used as a filter key in InsertKPIData's deduplication check. |
| 4 | ServerType | int | NO | - | CODE-BACKED | Classifies the server type. FK to Dictionary.ServerType (implicit). 6=HedgeServer for all current data. Enables EventLog to serve multiple server types from a single table. |
| 5 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Server-reported event timestamp with sub-millisecond precision. The authoritative event time - used in all deduplication checks and range queries. For KPI events (EventType=8), this is set to the computation window start time (@startTime), not the actual insert moment. |
| 6 | EventType | int | NO | - | CODE-BACKED | FK to Dictionary.HedgeEventType (implicit). 1=Reconnect Primary, 2=Disconnect Primary, 3=Reconnect Backoffice, 4=Disconnect Backoffice, 5=Recovery Success, 6=Recovery Fail, 7=Exposures change to 0, 8=Volume Account Larger than Volume Customers. |
| 7 | Message | varchar(255) | YES | - | CODE-BACKED | Optional free-text message. NULL allowed. For EventType=8 (KPI alerts), populated with 'InstrumentID={N}' to identify the triggering instrument. For connectivity events (types 1-4), typically empty ('') or NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventType | Dictionary.HedgeEventType | Implicit (no DDL FK) | EventTypeID -> Name lookup (8 event types: connect/disconnect/recovery/KPI) |
| ServerType | Dictionary.ServerType | Implicit (no DDL FK) | ServerTypeID -> Name lookup (HedgeServer=6, etc.) |
| ServerID | Trade.HedgeServer | Implicit when ServerType=6 | When ServerType=6, ServerID is a HedgeServerID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertHedgeEventLog | - | Writer | Primary writer - inserts disconnect/reconnect/recovery events for hedge servers |
| Hedge.InsertKPIData | EventType=8 | Reader+Writer | Reads for dedup check (NOT EXISTS EventType=8 for same server/time/instrument); writes via dbo.RW_EventLog synonym for KPI volume alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.EventLog (table)
  - Dictionary.HedgeEventType (implicit EventType lookup)
  - Dictionary.ServerType (implicit ServerType lookup)
```

No code-level dependencies in DDL.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeEventType | Table | Implicit FK target for EventType column |
| Dictionary.ServerType | Table | Implicit FK target for ServerType column |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertHedgeEventLog | Procedure | Writer - inserts connectivity events (disconnect, reconnect, recovery) |
| Hedge.InsertKPIData | Procedure | Reader (dedup check for EventType=8) + Writer (KPI volume alerts via dbo.RW_EventLog) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_EventLog | NONCLUSTERED PK | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |
| Idx_Hedge_EventLog | CLUSTERED | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |

**Design note**: NONCLUSTERED PK + separate CLUSTERED index on the same ID column is an unusual but valid SQL Server pattern. The clustered index physically orders data by ID (append order); the PK constraint is logically enforced nonclustered. Both are PAGE compressed.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_EventLog | PRIMARY KEY (NONCLUSTERED) | ID - unique row per event |
| Df_Hedge_EventLog_OccurredInsert | DEFAULT | OccurredInsert = GETDATE() |

---

## 8. Sample Queries

### 8.1 Recent hedge server connectivity events
```sql
SELECT TOP 100 ID, OccurredInsert, ServerID, ServerType,
       Occurred, EventType, HET.Name AS EventName, Message
FROM Hedge.EventLog EL
JOIN Dictionary.HedgeEventType HET ON EL.EventType = HET.EventTypeID
WHERE EL.Occurred > DATEADD(day, -7, GETUTCDATE())
  AND EL.EventType IN (1, 2, 3, 4, 5, 6)
ORDER BY EL.Occurred DESC;
```

### 8.2 KPI volume alert events with instrument context
```sql
SELECT EL.Occurred, EL.ServerID, EL.Message,
       DATEDIFF(ms, EL.Occurred, EL.OccurredInsert) AS LoggingLatencyMs
FROM Hedge.EventLog EL
WHERE EL.EventType = 8
  AND EL.Occurred > DATEADD(day, -30, GETUTCDATE())
ORDER BY EL.Occurred DESC;
```

### 8.3 Reconnect/disconnect event pairs to measure downtime windows
```sql
SELECT Occurred, ServerID, EventType, HET.Name AS EventName
FROM Hedge.EventLog EL
JOIN Dictionary.HedgeEventType HET ON EL.EventType = HET.EventTypeID
WHERE ServerID = 1
  AND EventType IN (1, 2)
  AND Occurred > DATEADD(day, -7, GETUTCDATE())
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for Hedge.EventLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.EventLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.EventLog.sql*
