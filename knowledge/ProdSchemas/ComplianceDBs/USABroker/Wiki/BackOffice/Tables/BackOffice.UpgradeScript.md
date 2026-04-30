# BackOffice.UpgradeScript

> Database migration/upgrade script tracking table that records every schema change script executed against the USABroker database, providing an audit trail of who deployed what change and when.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | UpgradeScriptID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

BackOffice.UpgradeScript is a database migration tracking table that records every schema change script executed against the USABroker database. Each row represents one migration script that was run, capturing the script name (typically a Jira ticket reference), version number, who ran it (LoginName), from which machine (HostName), and when (Occurred). This provides a complete audit trail of database evolution.

This table is essential for deployment tracking and rollback planning. It allows the team to see the complete history of schema changes, identify who deployed each change, trace changes back to Jira tickets (e.g., COAKVU-3194 for ETH Staking, COAKVU-2805 for reasoning questions), and determine the current database version.

Data is inserted by migration scripts themselves when they execute. The defaults auto-capture getdate(), original_login(), and host_name() so the deployer's identity and timing are recorded automatically. Currently contains 35 migration records spanning from initial setup through 2024.

---

## 2. Business Logic

### 2.1 Auto-Captured Deployment Context

**What**: Three columns auto-capture deployment context using SQL Server functions as defaults, ensuring consistent audit data regardless of how the script is run.

**Columns/Parameters Involved**: `Occurred`, `LoginName`, `HostName`

**Rules**:
- Occurred defaults to GETDATE() - timestamp of migration execution
- LoginName defaults to ORIGINAL_LOGIN() - the login that initiated the session (not impersonated)
- HostName defaults to HOST_NAME() - the client machine name
- These are captured even if the migration script only inserts Version+ScriptName

---

## 3. Data Overview

| UpgradeScriptID | Version | ScriptName | Occurred | LoginName | Meaning |
|----------------|---------|------------|----------|-----------|---------|
| 35 | 01.000.000.000 | COAKVU-3194,3201 ETH Staking | 2024-05-30 | yuliakra@etoro.com | Most recent migration: added ETH Staking support. Jira tickets COAKVU-3194 and 3201. |
| 34 | 01.000.000.000 | COAKVU-2805 Add additional reasoning questions by intent | 2024-03-19 | yuliakra@etoro.com | Added new options reasoning form questions. |
| 31 | 01.000.000.000 | Create Masking to PII Columns | 2023-09-10 | yuliakra@etoro.com | Applied dynamic data masking to UserData PII columns for GDPR/privacy compliance. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. 35 migrations recorded to date. |
| 2 | Version | char(14) | YES | - | CODE-BACKED | Database version string in format "NN.NNN.NNN.NNN" (e.g., "01.000.000.000"). All observed records use the same version, suggesting a single-version deployment model rather than versioned releases. |
| 3 | ScriptName | varchar(500) | YES | - | VERIFIED | Name/description of the migration script. Typically includes Jira ticket references (e.g., "COAKVU-3194,3201 ETH Staking") enabling traceability from DB change to business requirement. |
| 4 | Occurred | datetime | NO | getdate() | CODE-BACKED | Timestamp when the migration was executed. Auto-captured via GETDATE() default. Used to determine deployment chronology. |
| 5 | LoginName | sysname | YES | original_login() | CODE-BACKED | The SQL Server login that ran the migration script. Uses ORIGINAL_LOGIN() to capture the true login even if impersonation is active. Observed: "yuliakra@etoro.com" - indicates AAD authentication. |
| 6 | HostName | sysname | YES | host_name() | CODE-BACKED | The client machine name from which the migration was executed. Uses HOST_NAME(). Observed: "PF24288P" - a developer workstation. |
| 7 | ScriptID | int | YES | - | NAME-INFERRED | Optional numeric script identifier. NULL in all observed records. May be used by an external migration framework for ordering or deduplication. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this table. It is read by deployment scripts and operations staff.

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

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BUPG | CLUSTERED PK | UpgradeScriptID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BUPG | PRIMARY KEY | Clustered on UpgradeScriptID |
| BUPG_OCCURRED | DEFAULT | Occurred = getdate() |
| (unnamed) | DEFAULT | LoginName = original_login() |
| (unnamed) | DEFAULT | HostName = host_name() |

---

## 8. Sample Queries

### 8.1 View all migrations in chronological order

```sql
SELECT UpgradeScriptID, Version, ScriptName, Occurred, LoginName, HostName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY Occurred;
```

### 8.2 Find migrations related to a specific Jira ticket

```sql
SELECT UpgradeScriptID, ScriptName, Occurred, LoginName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE ScriptName LIKE '%COAKVU%'
ORDER BY Occurred DESC;
```

### 8.3 Get the most recent migration

```sql
SELECT TOP 1 UpgradeScriptID, Version, ScriptName, Occurred, LoginName, HostName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 9.5/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: USABroker/BackOffice/Tables/BackOffice.UpgradeScript.sql*
