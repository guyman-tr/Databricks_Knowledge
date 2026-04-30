# dbo.ChangesLog

> DDL audit table that captures all schema change events (CREATE, ALTER, DROP) executed against the RecurringManager database, providing a complete change history for compliance and troubleshooting.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LogId (INT, IDENTITY) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

ChangesLog is a DDL audit table that records every schema modification event in the RecurringManager database. Each row represents a single DDL operation - a CREATE, ALTER, or DROP statement executed by a developer or deployment pipeline. It captures the full SQL command, the target object, the user who made the change, and the timestamp.

This table exists to provide a complete audit trail of database schema changes. Without it, there would be no record of who changed what and when, making it impossible to diagnose issues caused by schema modifications or to satisfy compliance requirements for change tracking. It is the database's "black box" for structural changes.

Data is inserted automatically by a server-level DDL trigger (not defined in the SSDT project - configured directly on the database server). No stored procedures, views, or application code in the RecurringManager project read from or write to this table. It is a passive receiver of DDL events, queried ad-hoc by DBAs and developers when investigating schema change history.

---

## 2. Business Logic

### 2.1 DDL Event Capture

**What**: Every DDL operation against the database is automatically intercepted and logged with full context.

**Columns/Parameters Involved**: `EventType`, `SchemaName`, `ObjectName`, `ObjectType`, `SqlCommand`, `EventDataXML`

**Rules**:
- The DDL trigger fires on CREATE, ALTER, and DROP events for all object types (tables, procedures, etc.)
- The full SQL command text is captured in `SqlCommand` for direct readability
- The complete XML event data is also captured in `EventDataXML` for structured parsing
- `EventDate` is defaulted to `GETUTCDATE()` at the moment the trigger fires

**Diagram**:
```
Developer/CI Pipeline
        |
        v
  DDL Statement (CREATE/ALTER/DROP)
        |
        v
  [DDL Trigger fires]
        |
        v
  INSERT into dbo.ChangesLog
  (EventType, Schema, Object, SQL, Login, Date)
```

### 2.2 Change Attribution

**What**: Every schema change is attributed to the login that executed it and the host machine it originated from.

**Columns/Parameters Involved**: `LoginName`, `HostName`, `ScriptName`

**Rules**:
- `LoginName` records the Active Directory or SQL login (e.g., `doriz@etoro.com`) that executed the DDL
- `HostName` records the client machine name for traceability
- `ScriptName` contains the SSMS session GUID or deployment tool identifier (stored with null-padded Unicode characters from the client application name)

---

## 3. Data Overview

| LogId | EventType | SchemaName | ObjectName | ObjectType | LoginName | EventDate |
|-------|-----------|------------|------------|------------|-----------|-----------|
| 99 | ALTER_PROCEDURE | Scheduler | UpdateExecutionsStatus | PROCEDURE | doriz@etoro.com | 2026-01-14 |
| 97 | CREATE_PROCEDURE | Recurring | GetPaymentExecution | PROCEDURE | doriz@etoro.com | 2026-01-14 |
| 95 | ALTER_PROCEDURE | Recurring | UpdatePayment | PROCEDURE | doriz@etoro.com | 2026-01-04 |
| 14 | ALTER_TABLE | Recurring | Payment | TABLE | doriz@etoro.com | 2023-03-22 |
| 1 | CREATE_TABLE | Dictionary | EntityType | TABLE | TRAD\deployer | 2022-12-11 |

**Row meanings**:
- LogId 99: A deployment updated the Scheduler.UpdateExecutionsStatus procedure - modifying how execution status transitions work in the scheduling engine.
- LogId 97: A new stored procedure Recurring.GetPaymentExecution was created, adding a new data access path for payment execution records.
- LogId 95: The Recurring.UpdatePayment procedure was modified, likely changing how payment attributes (status, amount, funding source) are updated.
- LogId 14: The Recurring.Payment table structure was altered, adding or modifying columns that define the payment entity.
- LogId 1: The very first recorded change - creation of the Dictionary.EntityType table during initial database setup by the deployment pipeline.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogId | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Each DDL event gets a sequential ID. Not declared as PK constraint but serves as the logical row identifier via IDENTITY. |
| 2 | EventDataXML | xml | YES | - | CODE-BACKED | Complete XML representation of the DDL event as provided by SQL Server's EVENT_INSTANCE() function. Contains structured data including EventType, PostTime, SPID, ServerName, LoginName, UserName, DatabaseName, SchemaName, ObjectName, ObjectType, and the full TSQLCommand with SET options. Useful for programmatic parsing of change events. |
| 3 | DatabaseName | varchar(256) | YES | - | VERIFIED | Name of the database where the DDL event occurred. In practice always "RecurringManager" for this table. Nullable to handle edge cases where the trigger context cannot resolve the database name. |
| 4 | EventType | varchar(50) | NO | - | VERIFIED | The type of DDL operation performed. Observed values: CREATE_PROCEDURE (40 occurrences), ALTER_PROCEDURE (31), ALTER_TABLE (14), CREATE_TABLE (12), DROP_TABLE (1). Matches SQL Server DDL event group names. |
| 5 | SchemaName | varchar(30) | NO | - | VERIFIED | The schema of the object that was created, altered, or dropped. Values include Recurring, Scheduler, Dictionary, Configuration, History, BackOffice, Monitor, dbo - corresponding to the database's schema organization. |
| 6 | ObjectName | varchar(256) | NO | - | CODE-BACKED | The unqualified name of the database object affected by the DDL event (e.g., "UpdateExecutionsStatus", "Payment", "EntityType"). Combined with SchemaName gives the fully qualified object reference. |
| 7 | ObjectType | varchar(25) | NO | - | VERIFIED | The type of database object affected. Observed values: PROCEDURE, TABLE. Maps to SQL Server object type classifications as reported by the DDL trigger event data. |
| 8 | SqlCommand | varchar(max) | NO | - | CODE-BACKED | The complete SQL statement that was executed, captured verbatim from the DDL trigger's EVENT_INSTANCE(). Contains the full CREATE OR ALTER / CREATE / ALTER / DROP statement including all parameters, body logic, and formatting. Primary field for reviewing what exactly changed. |
| 9 | EventDate | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp of when the DDL event was captured by the trigger. Defaulted via constraint DF_EventsLog_EventDate to GETUTCDATE(), ensuring accurate timing even if the trigger does not explicitly set it. Note: constraint name "DF_EventsLog_EventDate" reveals the table was originally named "EventsLog". |
| 10 | LoginName | varchar(256) | NO | - | VERIFIED | The authenticated login that executed the DDL statement. Typically an Active Directory UPN (e.g., "doriz@etoro.com") for manual changes or a domain service account (e.g., "TRAD\deployer") for CI/CD pipeline deployments. |
| 11 | HostName | varchar(40) | YES | - | CODE-BACKED | The client machine name from which the DDL statement was issued. Useful for distinguishing between developer workstations and deployment servers. Nullable because some connection types may not provide a host name. |
| 12 | ScriptName | varchar(128) | YES | - | CODE-BACKED | The application name or script identifier from the client connection's APP_NAME() property. In practice contains SSMS session GUIDs (null-padded Unicode) or deployment tool identifiers. Nullable because not all clients set an application name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No other objects in the RecurringManager SSDT project reference dbo.ChangesLog. It is populated exclusively by a server-level DDL trigger configured outside the SSDT project.

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

No indexes are defined on this table. The table uses a heap structure (no clustered index). For a 98-row audit table, this has no performance impact, but means ad-hoc queries perform table scans.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EventsLog_EventDate | DEFAULT | `GETUTCDATE()` on EventDate - automatically timestamps each DDL event at the moment the trigger fires, using UTC to avoid timezone ambiguity. Constraint name reveals original table name "EventsLog". |

---

## 8. Sample Queries

### 8.1 Recent schema changes
```sql
SELECT TOP 20 LogId, EventType, SchemaName, ObjectName, ObjectType, LoginName, EventDate
FROM dbo.ChangesLog WITH (NOLOCK)
ORDER BY EventDate DESC
```

### 8.2 All changes to a specific object
```sql
SELECT LogId, EventType, LoginName, EventDate, SqlCommand
FROM dbo.ChangesLog WITH (NOLOCK)
WHERE SchemaName = 'Recurring' AND ObjectName = 'Payment'
ORDER BY EventDate DESC
```

### 8.3 Changes by a specific developer
```sql
SELECT EventType, SchemaName + '.' + ObjectName AS FullObjectName, ObjectType, EventDate
FROM dbo.ChangesLog WITH (NOLOCK)
WHERE LoginName = 'doriz@etoro.com'
ORDER BY EventDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 8.1/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ChangesLog | Type: Table | Source: RecurringManager/dbo/Tables/dbo.ChangesLog.sql*
