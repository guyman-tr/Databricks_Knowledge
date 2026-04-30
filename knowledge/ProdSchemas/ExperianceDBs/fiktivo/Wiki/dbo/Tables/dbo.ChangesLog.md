# dbo.ChangesLog

> DDL change tracking log that captures all schema modifications (CREATE, ALTER, DROP) made to database objects, recording the event type, object affected, and the full SQL command.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LogId (INT IDENTITY, no explicit PK) |
| **Partition** | No |
| **Indexes** | 0 (heap table) |

---

## 1. Business Meaning

This table records DDL events (schema changes) made to the fiktivo database. Unlike AuditLog which tracks data changes by admin users, ChangesLog captures structural changes such as CREATE/ALTER/DROP on tables, procedures, views, and other objects. This provides a complete history of schema evolution.

Without this table, DBAs would have no record of who made schema changes or when. It is populated by a DDL trigger that fires on schema modification events. Each entry captures the full SQL command text, enabling reconstruction of any schema change.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A - DDL change log entries are operational/infrastructure data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing identifier for each log entry. |
| 2 | EventDataXML | xml | YES | - | CODE-BACKED | Full XML event data from the DDL trigger including all metadata. |
| 3 | DatabaseName | varchar(256) | YES | - | CODE-BACKED | Name of the database where the DDL event occurred. |
| 4 | EventType | varchar(50) | NO | - | CODE-BACKED | Type of DDL event: CREATE_TABLE, ALTER_PROCEDURE, DROP_VIEW, etc. |
| 5 | SchemaName | varchar(30) | NO | - | CODE-BACKED | Schema of the affected object (e.g., "dbo", "Dictionary", "Trade"). |
| 6 | ObjectName | varchar(256) | NO | - | CODE-BACKED | Name of the affected database object. |
| 7 | ObjectType | varchar(25) | NO | - | CODE-BACKED | Type of the affected object: TABLE, PROCEDURE, VIEW, FUNCTION, etc. |
| 8 | SqlCommand | varchar(max) | NO | - | CODE-BACKED | Full SQL command text that was executed. Enables reconstruction of any change. |
| 9 | EventDate | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the DDL event occurred. |
| 10 | LoginName | varchar(256) | NO | - | CODE-BACKED | SQL Server login name of the user who executed the DDL command. |
| 11 | HostName | varchar(40) | YES | - | CODE-BACKED | Machine name from which the DDL command was executed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

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

N/A - heap table (no clustered index).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EventsLog_EventDate | DEFAULT | EventDate = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 View recent schema changes
```sql
SELECT TOP 20 EventDate, LoginName, EventType, SchemaName + '.' + ObjectName AS Object, ObjectType
FROM dbo.ChangesLog WITH (NOLOCK)
ORDER BY EventDate DESC
```

### 8.2 Find all changes to a specific object
```sql
SELECT EventDate, EventType, LoginName, HostName, SqlCommand
FROM dbo.ChangesLog WITH (NOLOCK)
WHERE ObjectName = 'tblaff_Affiliates'
ORDER BY EventDate DESC
```

### 8.3 Count DDL events by type
```sql
SELECT EventType, COUNT(*) AS EventCount
FROM dbo.ChangesLog WITH (NOLOCK)
GROUP BY EventType
ORDER BY EventCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ChangesLog | Type: Table | Source: fiktivo/dbo/Tables/dbo.ChangesLog.sql*
