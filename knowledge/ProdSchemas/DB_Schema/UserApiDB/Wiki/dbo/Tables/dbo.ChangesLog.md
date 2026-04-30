# dbo.ChangesLog

> DDL audit log table capturing all schema changes (CREATE, ALTER, DROP) with event metadata, login, and SQL command text.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LogId (INT IDENTITY, no PK - heap) |
| **Partition** | No |
| **Indexes** | None (heap table) |

---

## 1. Business Meaning

dbo.ChangesLog captures DDL events (CREATE TABLE, ALTER PROCEDURE, DROP INDEX, etc.) as an audit trail for all schema modifications in the database. Each row records the event type, schema/object name, the full SQL command, the login that executed it, the host, and the event timestamp. This is populated by a DDL trigger.

---

## 2. Business Logic

No complex business logic. Append-only DDL audit log. No PK (heap for fast inserts).

---

## 3. Data Overview

N/A - audit log table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogId | int (IDENTITY) | NO | - | CODE-BACKED | Auto-incrementing log entry identifier. Not a PK (heap). |
| 2 | EventDataXML | xml | YES | - | CODE-BACKED | Raw XML event data from the DDL trigger EVENTDATA() function. |
| 3 | DatabaseName | varchar(256) | YES | - | CODE-BACKED | Database where the change occurred. |
| 4 | EventType | varchar(50) | NO | - | CODE-BACKED | DDL event type: CREATE_TABLE, ALTER_PROCEDURE, DROP_INDEX, etc. |
| 5 | SchemaName | varchar(30) | NO | - | CODE-BACKED | Schema of the modified object. |
| 6 | ObjectName | varchar(256) | NO | - | CODE-BACKED | Name of the modified object. |
| 7 | ObjectType | varchar(25) | NO | - | CODE-BACKED | Type of object: TABLE, PROCEDURE, VIEW, INDEX, etc. |
| 8 | SqlCommand | varchar(max) | NO | - | CODE-BACKED | Full SQL command that was executed. |
| 9 | EventDate | datetime | NO | getutcdate() | CODE-BACKED | When the change occurred (UTC). Default: current UTC time. |
| 10 | LoginName | varchar(256) | NO | - | CODE-BACKED | SQL login that executed the change. |
| 11 | HostName | varchar(40) | YES | - | CODE-BACKED | Machine name that initiated the connection. |
| 12 | ScriptName | varchar(128) | YES | - | CODE-BACKED | Script or application name from the connection context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Populated by DDL trigger (not in SSDT).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None (heap table - no clustered index, optimized for fast inserts from DDL trigger).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EventsLog_EventDate | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent schema changes
```sql
SELECT TOP 50 EventDate, EventType, SchemaName, ObjectName, LoginName FROM dbo.ChangesLog WITH (NOLOCK) ORDER BY EventDate DESC
```

### 8.2 Changes by object
```sql
SELECT EventDate, EventType, SqlCommand FROM dbo.ChangesLog WITH (NOLOCK) WHERE ObjectName = @ObjectName ORDER BY EventDate DESC
```

### 8.3 Changes by login
```sql
SELECT EventDate, EventType, SchemaName, ObjectName FROM dbo.ChangesLog WITH (NOLOCK) WHERE LoginName = @Login ORDER BY EventDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: dbo.ChangesLog | Type: Table | Source: UserApiDB/UserApiDB/dbo/Tables/dbo.ChangesLog.sql*
