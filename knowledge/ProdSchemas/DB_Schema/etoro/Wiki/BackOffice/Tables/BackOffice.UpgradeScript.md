# BackOffice.UpgradeScript

> Audit log of every database upgrade script executed against the eToro database, recording the script name, version, timestamp, and deploying login - acts as the DB migration history ledger.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BUPG: UpgradeScriptID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (1 clustered PK + 1 nonclustered) |

---

## 1. Business Meaning

`BackOffice.UpgradeScript` is the database deployment audit log. Every time a database change script (migration, hotfix, feature schema change) is applied to the eToro production database, a row is inserted here recording what was deployed, when, by whom, and from which host. It is the equivalent of a "migration history" table found in frameworks like Flyway or Liquibase, but implemented as a manual audit trail.

The table is written to directly during script execution - a script that makes schema changes begins by inserting a row into this table. A trigger (`SetScriptNameForSessionLevel`) fires on every insert and stores the script name as SQL Server `CONTEXT_INFO` for the session, enabling other code to know which deployment script is currently running.

Live data: 39,755 rows (IDs up to ~39,755). All recent entries show Version="01.000.000.000" (versioning appears nominal, not semantic), with script names following Jira ticket conventions: `{PROJECT}-{TICKET}-{description}_{date}.sql`. The deploying login is consistently `TRAD\nogaro` (a DBA service account). `ScriptID` and `HostName` are always NULL in recent data, suggesting they were used in earlier deployments but the fields are now effectively deprecated.

---

## 2. Business Logic

### 2.1 Deployment Audit Logging

**What**: Each database deployment script logs itself to this table before making changes.

**Columns/Parameters Involved**: `Version`, `ScriptName`, `Occurred`, `LoginName`

**Rules**:
- Scripts insert a row at the start of execution: `INSERT INTO BackOffice.UpgradeScript (Version, ScriptName) VALUES (...)` - Occurred and LoginName auto-populate via defaults.
- `Occurred` defaults to `GETDATE()` - the wall clock time of the deployment.
- `LoginName` defaults to `ORIGINAL_LOGIN()` - the SQL Server login of the deploying session.
- `Version` is a char(14) field (e.g., "01.000.000.000") - nominally a schema version string but all recent records use the same value.
- `ScriptName` follows Jira naming: `{PROJECT}-{TICKETID}-{description}_{DDMMYY}.sql`.

**Script naming examples**:
```
ONBRD-ONBRD-9456_NewFunnel_160226.sql    -> ONBRD project, ticket 9456, deployed 2026-02-16
PART-4615-RAFCompensation_FraudReason_NewColumn.sql -> PART project, ticket 4615
```

### 2.2 CONTEXT_INFO Session Tagging (Trigger)

**What**: The `SetScriptNameForSessionLevel` trigger propagates the script name to the SQL Server session context on every INSERT.

**Columns/Parameters Involved**: `ScriptName`

**Rules**:
- On INSERT, the trigger casts `LEFT(ScriptName, 128)` to `VARBINARY(128)` and calls `SET CONTEXT_INFO @BinValue`.
- This sets the session's `CONTEXT_INFO` to the script name bytes.
- Other code can read `CONTEXT_INFO()` to determine if a DB upgrade script is currently running and which one.
- This is used as a mechanism to suppress certain triggers or audit logging during migrations.

**Diagram**:
```
DBA runs: INSERT INTO BackOffice.UpgradeScript (Version, ScriptName) VALUES ('01.000.000.000', 'ONBRD-9456.sql')
  -> CONTEXT_INFO set to binary('ONBRD-9456.sql') for session
  -> DBA runs DDL/DML changes for the migration
  -> Other triggers check CONTEXT_INFO() to know a migration is in progress
```

---

## 3. Data Overview

| Column | Observed Values |
|--------|----------------|
| Total rows | ~39,755 (via max UpgradeScriptID) |
| Version | Always "01.000.000.000" in recent data |
| ScriptName pattern | `{PROJECT}-{TICKET}-{description}_{date}.sql` |
| LoginName | TRAD\nogaro (DBA service account) |
| ScriptID | NULL in all recent data |
| HostName | NULL in all recent data |
| Date range | Oldest: legacy; Latest: 2026-02-16 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each deployment event. ~39,755 deployments recorded to date. |
| 2 | Version | char(14) | YES | - | CODE-BACKED | Nominal schema version string at time of deployment. Format "XX.XXX.XXX.XXX" (e.g., "01.000.000.000"). All recent deployments use "01.000.000.000" - versioning is no longer semantically meaningful, serves as a filler. |
| 3 | ScriptName | varchar(200) | YES | - | CODE-BACKED | Filename of the deployed script. Follows Jira naming convention: `{PROJECT}-{TICKET}-{description}_{DDMMYY}.sql`. Stored as CONTEXT_INFO during the session by the SetScriptNameForSessionLevel trigger. |
| 4 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Wall-clock timestamp when the script registration row was inserted. Defaults to GETDATE() - automatically captures deployment time. |
| 5 | LoginName | sysname | YES | ORIGINAL_LOGIN() | CODE-BACKED | SQL Server login name of the session that ran the deployment script. Defaults to ORIGINAL_LOGIN(). Consistently "TRAD\nogaro" (DBA account) in production. |
| 6 | ScriptID | int | YES | - | NAME-INFERRED | Legacy field. NULL in all recent data. May have previously referenced an external script registry or deployment system. No longer populated. |
| 7 | HostName | nvarchar(128) | YES | - | NAME-INFERRED | Legacy field. NULL in all recent data. Likely was intended to record the deploying workstation hostname. No longer populated (possibly replaced by CONTEXT_INFO mechanism). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SetScriptNameForSessionLevel (trigger) | CONTEXT_INFO | Internal trigger | Sets session CONTEXT_INFO from ScriptName on each INSERT |
| DB deployment scripts | INSERT | Writers | Each migration script inserts a row here at start of execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (standalone audit log, no FKs).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SetScriptNameForSessionLevel | Trigger | Reads ScriptName on INSERT; sets CONTEXT_INFO |
| DB migration scripts (external) | SQL Scripts | Write to this table at start of each deployment |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BUPG | CLUSTERED PK | UpgradeScriptID ASC (FILLFACTOR=90) | - | - | Active |
| BUPG_VERSION | NONCLUSTERED | Version ASC, ScriptName ASC (FILLFACTOR=90) | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BUPG_OCCURRED | DEFAULT | Occurred defaults to GETDATE() |
| LoginName DEFAULT | DEFAULT | LoginName defaults to ORIGINAL_LOGIN() |
| SetScriptNameForSessionLevel | TRIGGER (FOR INSERT) | Sets CONTEXT_INFO from ScriptName on each insert |

---

## 8. Sample Queries

### 8.1 Get recent deployment history

```sql
SELECT TOP 20
    UpgradeScriptID, Version, ScriptName, Occurred, LoginName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID DESC;
```

### 8.2 Find deployments for a specific Jira project

```sql
SELECT UpgradeScriptID, ScriptName, Occurred, LoginName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE ScriptName LIKE 'ONBRD%'
ORDER BY Occurred DESC;
```

### 8.3 Find all deployments in a date range

```sql
SELECT UpgradeScriptID, ScriptName, Occurred, LoginName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE Occurred >= '2026-01-01' AND Occurred < '2026-04-01'
ORDER BY Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (trigger analyzed) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.UpgradeScript.sql*
