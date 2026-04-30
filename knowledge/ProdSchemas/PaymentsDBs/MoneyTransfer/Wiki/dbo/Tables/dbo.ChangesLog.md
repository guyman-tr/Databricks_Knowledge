# dbo.ChangesLog

> DDL audit log that captures schema change events (CREATE, ALTER, DROP) made to database objects in the MoneyTransfer database, recording who changed what, when, and the full SQL command executed.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | LogId (IDENTITY, no PK constraint defined) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

ChangesLog is a DDL audit trail table that records every schema modification event in the MoneyTransfer database. Each row represents a single DDL operation - a CREATE, ALTER, or DROP statement executed against a table, stored procedure, or other database object. It captures the full context of who performed the change, from which machine, at what time, and the complete SQL command that was executed.

This table exists to provide an audit history of database schema changes for compliance, troubleshooting, and change tracking purposes. Without it, there would be no record of when database objects were created, modified, or removed, or who performed those operations. This is critical for investigating production issues caused by schema changes and for regulatory audit trails.

Data was historically written to this table by a database-level DDL trigger that intercepted DDL events and inserted a row for each event. The trigger captured the event metadata from SQL Server's `EVENTDATA()` function and parsed it into individual columns. The DDL trigger has since been removed or disabled - no new rows are being written. The table currently contains 34 historical records spanning from August 2023 to June 2025. No stored procedures, views, or application code read from this table - it serves as a passive historical record. An identical table structure exists in the RecurringManager database, indicating this is an organization-wide DDL audit pattern deployed across multiple databases.

---

## 2. Business Logic

### 2.1 DDL Event Capture Pattern

**What**: Each row captures a complete DDL event with full audit context - the event type, the affected object, and the actor who performed it.

**Columns/Parameters Involved**: `EventType`, `ObjectType`, `SchemaName`, `ObjectName`, `SqlCommand`, `EventDataXML`

**Rules**:
- Every DDL statement (CREATE, ALTER, DROP) against any database object generates one row
- The `EventDataXML` column stores the raw XML from SQL Server's `EVENTDATA()` function, providing the complete event payload
- The `SqlCommand` column stores the actual T-SQL statement that was executed, enabling exact replay or review
- Events are recorded at UTC time via the `getutcdate()` default on `EventDate`

**Diagram**:
```
DDL Statement Executed
        |
        v
[DDL Trigger fires]
        |
        v
EVENTDATA() captured
        |
        v
INSERT into dbo.ChangesLog
  - Parse XML for metadata
  - Store full SQL command
  - Record login, host, timestamp
```

### 2.2 Actor Audit Trail

**What**: Each DDL event is attributed to a specific user login and workstation, enabling accountability for schema changes.

**Columns/Parameters Involved**: `LoginName`, `HostName`, `ScriptName`, `EventDate`

**Rules**:
- `LoginName` captures the Active Directory email of the person who executed the DDL (e.g., `doriz@etoro.com`)
- `HostName` captures the machine name from which the change was made (e.g., `PF1B1L2X`, `LON-DBA-TRM1`)
- `ScriptName` captures the SSMS session GUID (stored in UTF-16 encoding), identifying the specific client session
- Together these three columns answer "who changed what, from where" for any DDL event

---

## 3. Data Overview

| LogId | EventType | SchemaName | ObjectName | ObjectType | LoginName | EventDate | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | CREATE_TABLE | BackOffice | UpgradeScript | TABLE | doriz@etoro.com | 2023-08-14 | First recorded DDL event - creation of the BackOffice.UpgradeScript table, likely used to track database upgrade/migration scripts applied to this database. |
| 8 | ALTER_TABLE | Billing | Transfers | TABLE | doriz@etoro.com | 2024-07-07 | Schema modification to the core Billing.Transfers table - the primary transactional table in MoneyTransfer. Multiple ALTER events on this date indicate a coordinated schema change (adding columns or constraints). |
| 17 | ALTER_PROCEDURE | Billing | GetTransferByReferenceID | PROCEDURE | doriz@etoro.com | 2024-11-05 | Procedure update that coincides with a batch of ALTER_TABLE and CREATE_PROCEDURE events - indicates a feature release that required both schema and logic changes to the Billing system. |
| 24 | CREATE_PROCEDURE | Monitoring | GetLastTransfersStatusesInPercentage | PROCEDURE | doriz@etoro.com | 2024-11-05 | Creation of a monitoring procedure - shows the Monitoring schema being built out with observability queries for transfer health dashboards. |
| 34 | ALTER_PROCEDURE | Billing | GetLastDepotIdForTransferStatusesByCid | PROCEDURE | doriz@etoro.com | 2025-06-03 | Most recent recorded DDL event - procedure modification by the primary DBA, indicating the DDL trigger was still active as recently as mid-2025. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LogId | int IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate key for each DDL audit event. Despite being NOT NULL with IDENTITY, no explicit PRIMARY KEY constraint is defined on this column - the table relies on the IDENTITY property for uniqueness. Sequential values (1-34 observed) provide chronological ordering of DDL events. |
| 2 | EventDataXML | xml | YES | - | CODE-BACKED | Raw XML payload from SQL Server's `EVENTDATA()` function captured at trigger fire time. Contains the complete DDL event metadata in XML format including the full T-SQL command text, object identifiers, schema information, and session details. This is the authoritative source; the other columns are parsed extracts from this XML for query convenience. |
| 3 | DatabaseName | varchar(256) | YES | - | CODE-BACKED | Name of the database where the DDL event occurred. All 34 rows contain "MoneyTransfer" - the value is always the current database name since the trigger fires at database scope. Nullable by design to handle edge cases, but practically always populated. |
| 4 | EventType | varchar(50) | NO | - | CODE-BACKED | SQL Server DDL event type identifier. Observed values: `CREATE_TABLE`, `ALTER_TABLE`, `DROP_TABLE`, `CREATE_PROCEDURE`, `ALTER_PROCEDURE`. These match the DDL event groups in SQL Server's event notification system. Distribution: CREATE_PROCEDURE (29%), ALTER_TABLE (26%), ALTER_PROCEDURE (24%), CREATE_TABLE (12%), DROP_TABLE (9%). |
| 5 | SchemaName | varchar(30) | NO | - | CODE-BACKED | Database schema of the affected object. Observed values: `Billing` (71% of events - the most actively modified schema), `dbo` (18%), `Monitoring` (9%), `BackOffice` (3%). Reflects that Billing is the primary schema in MoneyTransfer with the most active development. |
| 6 | ObjectName | varchar(256) | NO | - | CODE-BACKED | Name of the database object that was created, altered, or dropped (without schema prefix). Examples: `Transfers`, `GetTransferByReferenceID`, `PostTransferActions`. Combined with SchemaName, provides the fully qualified object reference. |
| 7 | ObjectType | varchar(25) | NO | - | CODE-BACKED | SQL Server object type classification. Observed values: `TABLE` (47%), `PROCEDURE` (53%). These correspond to the sys.objects type descriptions for the affected DDL target. Only tables and procedures have been captured in this database's history. |
| 8 | SqlCommand | varchar(max) | NO | - | CODE-BACKED | Complete T-SQL statement that was executed, stored verbatim. Contains the full CREATE, ALTER, or DROP statement text. Stored on TEXTIMAGE_ON [PRIMARY] filegroup due to varchar(max) requiring off-row storage. This enables exact review or replay of any historical schema change. |
| 9 | EventDate | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp of when the DDL event was captured by the trigger. Default constraint `DF_EventsLog_EventDate` uses `getutcdate()` - note the constraint name references "EventsLog", indicating the table was originally named `dbo.EventsLog` and was later renamed to `dbo.ChangesLog`. Observed range: 2023-08-14 to 2025-06-03. |
| 10 | LoginName | varchar(256) | NO | - | CODE-BACKED | Windows/AD login identity of the user who executed the DDL statement. Stored as email format (e.g., `doriz@etoro.com`, `ranov@etoro.com`, `itayhay@etoro.com`). Captured from the SQL Server session context. Primary actor for audit accountability - 4 distinct users observed across all 34 events. |
| 11 | HostName | varchar(40) | YES | - | CODE-BACKED | NetBIOS name of the client machine from which the DDL statement was executed. Examples: `PF1B1L2X` (most frequent - primary DBA workstation), `LON-DBA-TRM1` (London DBA terminal), `PF2YPLJ7`. Nullable to handle connections where hostname is not available. Helps identify whether changes came from a DBA workstation vs automated deployment. |
| 12 | ScriptName | varchar(128) | YES | - | CODE-BACKED | SSMS session identifier captured from the client connection. Contains a GUID in UTF-16 encoding (visible as alternating characters with null bytes). Identifies the specific SQL Server Management Studio session that executed the DDL. Multiple DDL events sharing the same ScriptName GUID were executed in the same SSMS session (e.g., a deployment script running multiple ALTER statements). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a standalone audit table with no foreign keys or implicit lookups.

### 5.2 Referenced By (other objects point to this)

No incoming references discovered. No views, stored procedures, or functions in the MoneyTransfer SSDT project reference this table. The table was populated exclusively by a DDL trigger (now removed).

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. The table is an isolated audit artifact with no consumers in the current codebase.

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. The table has no PRIMARY KEY constraint, no clustered index, and no nonclustered indexes. This means the table is stored as a heap. For an audit table with only 34 rows and no query consumers, this is acceptable.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_EventsLog_EventDate | DEFAULT | `getutcdate()` on EventDate. Automatically stamps the UTC time when a DDL event row is inserted. The constraint name references the original table name "EventsLog" - the table was renamed to "ChangesLog" but the constraint was not renamed. |

---

## 8. Sample Queries

### 8.1 Recent DDL changes by schema
```sql
SELECT EventType, SchemaName, ObjectName, ObjectType, LoginName, EventDate
FROM dbo.ChangesLog WITH (NOLOCK)
ORDER BY EventDate DESC
```

### 8.2 Summary of changes per user
```sql
SELECT LoginName,
       COUNT(*) AS TotalChanges,
       MIN(EventDate) AS FirstChange,
       MAX(EventDate) AS LastChange,
       COUNT(DISTINCT ObjectName) AS UniqueObjects
FROM dbo.ChangesLog WITH (NOLOCK)
GROUP BY LoginName
ORDER BY TotalChanges DESC
```

### 8.3 Find all modifications to a specific object
```sql
SELECT LogId, EventType, SqlCommand, LoginName, HostName, EventDate
FROM dbo.ChangesLog WITH (NOLOCK)
WHERE ObjectName = 'Transfers'
  AND SchemaName = 'Billing'
ORDER BY EventDate
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. No dedicated Confluence page exists for dbo.ChangesLog, and no relevant Jira tickets were discovered referencing this table or the DDL audit trigger mechanism.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 6.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ChangesLog | Type: Table | Source: MoneyTransfer/dbo/Tables/dbo.ChangesLog.sql*
