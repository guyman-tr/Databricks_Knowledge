# DBA.UpgradeScript

> Database migration tracking table that records every upgrade script executed against the RecurringInvestment database, providing a complete deployment audit trail.

| Property | Value |
|----------|-------|
| **Schema** | DBA |
| **Object Type** | Table |
| **Key Identifier** | UpgradeScriptID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (PK + IX_UpgradeScript_VERSION) |

---

## 1. Business Meaning

This table serves as the database deployment audit trail. Every time a migration script is executed against the RecurringInvestment database, a row is inserted recording which script ran, when, by whom, and from which host. This enables the DBA team and deployment pipeline to verify which scripts have been applied, prevent duplicate executions, and troubleshoot deployment issues.

Without this table, there would be no record of which database changes have been applied to this environment. Deployments would be blind - unable to verify whether a specific migration was already executed or determine the current schema version.

Rows are inserted by the database deployment pipeline (typically SSDT publish or custom migration tooling) at the start of each upgrade script. The trigger SetScriptNameForSessionLevel automatically captures the script name into the session's CONTEXT_INFO, making it available for audit purposes in subsequent operations within the same session.

---

## 2. Business Logic

### 2.1 Session Context Tracking via Trigger

**What**: The INSERT trigger captures the script name into SQL Server CONTEXT_INFO for session-level audit tracking.

**Columns/Parameters Involved**: `ScriptName`, CONTEXT_INFO

**Rules**:
- On every INSERT, the trigger reads the ScriptName from the inserted row
- Casts the first 128 characters to VARBINARY(128) and stores it in CONTEXT_INFO
- This makes the script name available to any subsequent operations in the same session via `CONTEXT_INFO()`
- Used for audit logging - any table that has a Trace column can identify which deployment script made the change

### 2.2 Auto-Captured Metadata

**What**: Occurred and LoginName are auto-populated on insert.

**Columns/Parameters Involved**: `Occurred`, `LoginName`

**Rules**:
- Occurred defaults to GETDATE() - captures the exact deployment timestamp
- LoginName defaults to ORIGINAL_LOGIN() - captures the Windows/SQL login that initiated the deployment, even if impersonation is in effect

---

## 3. Data Overview

| UpgradeScriptID | Version | ScriptName | Occurred | LoginName | Meaning |
|-----------------|---------|------------|----------|-----------|---------|
| 52 | 01.000.000.000 | EDGE-6637_add_amountUsd_to_plans.sql | 2026-02-10 | nogaro@etoro.com | Most recent migration: added AmountUsd column to Plans table per EDGE-6637. Deployed by Noga. |
| 51 | 01.000.000.000 | EDGE-6386_add_new_mopType.sql | 2026-02-03 | nogaro@etoro.com | Added new MOP type support per EDGE-6386. |
| 50 | 01.000.000.000 | EDGE-6660_EDGE-6657_BlocksCountries.sql | 2026-01-21 | nogaro@etoro.com | Updated country blocking rules for recurring investment eligibility. |
| 48 | 01.000.000.000 | EDGE-6518_OpencryptoNCopyUSA.sql | 2025-12-11 | nogaro@etoro.com | Opened crypto and copy trading recurring investment for USA users. |
| 49 | 01.000.000.000 | EDGE-6517_allow_null_fundingId.sql | 2025-12-16 | nogaro@etoro.com | Made FundingID nullable in Plans table. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing unique identifier for each script execution record. Primary key. |
| 2 | Version | char(14) | YES | - | CODE-BACKED | Database schema version number in format NN.NNN.NNN.NNN (e.g., "01.000.000.000"). All current records use the same version, suggesting the version tracks the major release rather than incrementing per script. |
| 3 | ScriptName | varchar(200) | YES | - | VERIFIED | Name of the migration script file that was executed. Typically formatted as "{JIRA-ticket}_{description}.sql" (e.g., "EDGE-6637_add_amountUsd_to_plans.sql"). Also stored in CONTEXT_INFO by the INSERT trigger for session-level audit tracking. |
| 4 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the script was executed. Auto-captured at insert time. |
| 5 | LoginName | sysname | YES | ORIGINAL_LOGIN() | CODE-BACKED | Windows/SQL login that executed the deployment. Uses ORIGINAL_LOGIN() to capture the true identity even under impersonation. |
| 6 | HostName | sysname | YES | - | CODE-BACKED | Name of the host machine from which the deployment was executed. |
| 7 | ScriptID | int | YES | - | CODE-BACKED | Optional numeric identifier for the script, potentially used by external deployment tooling. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. This table is standalone infrastructure.

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
| PK_UpgradeScript_ID | CLUSTERED PK | UpgradeScriptID | - | - | Active (FILLFACTOR=90) |
| IX_UpgradeScript_VERSION | NONCLUSTERED | Version, ScriptName | - | - | Active (FILLFACTOR=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CON_UpgradeScript_OCCURRED | DEFAULT | GETDATE() - auto-timestamps script execution |
| CON_UpgradeScript_OrigLogin | DEFAULT | ORIGINAL_LOGIN() - captures deployment initiator |

### 7.3 Triggers

| Trigger | Event | Description |
|---------|-------|-------------|
| SetScriptNameForSessionLevel | FOR INSERT | Captures ScriptName (first 128 chars) into CONTEXT_INFO for session-level audit tracking |

---

## 8. Sample Queries

### 8.1 List recent deployments
```sql
SELECT UpgradeScriptID, Version, ScriptName, Occurred, LoginName
FROM [DBA].[UpgradeScript] WITH (NOLOCK)
ORDER BY Occurred DESC
```

### 8.2 Check if a specific script has been applied
```sql
SELECT CASE WHEN EXISTS (
  SELECT 1 FROM [DBA].[UpgradeScript] WITH (NOLOCK)
  WHERE ScriptName LIKE '%EDGE-6637%'
) THEN 'Applied' ELSE 'Not Applied' END AS ScriptStatus
```

### 8.3 Find all scripts by a specific deployer
```sql
SELECT ScriptName, Occurred, HostName
FROM [DBA].[UpgradeScript] WITH (NOLOCK)
WHERE LoginName = 'nogaro@etoro.com'
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Standard DBA infrastructure table for deployment tracking.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: DBA.UpgradeScript | Type: Table | Source: RecurringInvestment/DBA/Tables/DBA.UpgradeScript.sql*
