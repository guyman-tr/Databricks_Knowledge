# BackOffice.UpgradeScript

> Database migration history table that records every SQL upgrade script executed against the database, tracking the script name, version, execution timestamp, who ran it, and from which machine - serving as the authoritative audit log for schema and data changes since 2011.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | UpgradeScriptID (int, IDENTITY, clustered PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK, FILLFACTOR 90) |

---

## 1. Business Meaning

BackOffice.UpgradeScript is the database migration history table for the fiktivo database. Every time a SQL script is executed to modify the database schema (DDL) or perform a data migration, a row is inserted to record what was run, when, by whom, and from which machine. It is the equivalent of migration tracking tables in application frameworks (e.g., Django's django_migrations, EF's __EFMigrationsHistory) but for manual and CI/CD-driven SQL script execution.

This table exists to provide a complete audit trail of database changes and to prevent duplicate script execution. Before running a script, the deployment process can check if a script with the same name has already been recorded, preventing accidental re-execution. The table has been active since March 2011, spanning 15+ years of database evolution.

Rows are inserted by the upgrade script execution framework - either manually by developers (LoginName shows domain accounts like TRAD\nogaro) or by the CI/CD pipeline (LoginName = CICD_DB_EXPERIENCE, HostName shows AKS runner pods). The defaults for Occurred, LoginName, and HostName auto-capture the execution context without the script needing to provide these values explicitly.

---

## 2. Business Logic

### 2.1 Execution Context Auto-Capture

**What**: Three columns automatically capture who ran the script, when, and from where.

**Columns/Parameters Involved**: `Occurred`, `LoginName`, `HostName`

**Rules**:
- Occurred: DEFAULT GETDATE() - captures the exact timestamp of script execution
- LoginName: DEFAULT ORIGINAL_LOGIN() - captures the Windows/SQL login that initiated the connection (not impersonated identity)
- HostName: DEFAULT HOST_NAME() - captures the machine name of the client executing the script
- These defaults mean a minimal INSERT only needs to provide Version and ScriptName

### 2.2 Manual vs CI/CD Execution Patterns

**What**: The LoginName and HostName values reveal the deployment method.

**Columns/Parameters Involved**: `LoginName`, `HostName`

**Rules**:
- Manual deployment: LoginName = domain\username (e.g., TRAD\nogaro), HostName = workstation name (e.g., PF2YPLJ7)
- CI/CD deployment: LoginName = CICD_DB_EXPERIENCE, HostName = AKS runner pod name (e.g., stg-runner-linux-aks-vjhmb-runner-8k6kf)
- Both methods insert into the same table - the context columns distinguish the source

### 2.3 Script Naming Convention

**What**: ScriptName follows a JIRA ticket-based convention.

**Columns/Parameters Involved**: `ScriptName`

**Rules**:
- Pattern: {JIRA-TICKET}_{Description}.sql (e.g., PART-5265_Fiktivo_ADF_Objects.sql)
- The JIRA ticket prefix provides traceability from the migration back to the business requirement
- ScriptName serves as the idempotency key - checking for duplicates prevents re-execution

---

## 3. Data Overview

| UpgradeScriptID | Version | ScriptName | Occurred | LoginName | Meaning |
|---|---|---|---|---|---|
| 28243 | 02.000.000.000 | PART-5522_ModifyAffiliateGroup.sql | 2026-02-09 09:39:41 | TRAD\nogaro | Most recent: manual deployment by Noga, affiliate group modification, version 2 (re-run) |
| 28241 | 01.000.000.000 | PART-5531_AffiliateGroup-ModifytoNewTabs.sql | 2026-02-09 09:37:40 | CICD_DB_EXPERIENCE | CI/CD pipeline deployment from AKS runner, affiliate group tab restructuring |
| 28240 | 01.000.000.000 | PART-5265_Fiktivo_ADF_Objects.sql | 2026-02-04 16:44:33 | TRAD\nogaro | Manual deployment creating the BILoad ADF schema objects (same PART-5265 from BILoad schema) |
| 28239 | 01.000.000.000 | PART-5445-Affiliate-Commission-Need-to-Trigger-Credit-Event.sql | 2026-01-06 14:09:19 | TRAD\nogaro | Manual deployment for credit event triggering changes |

*279 total rows spanning 2011-03-01 to 2026-02-09 (15+ years of database history).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key. Clustered PK with FILLFACTOR 90 (tuned for append-only inserts with occasional page splits). NOT FOR REPLICATION ensures each environment generates its own ID sequence in replicated setups. |
| 2 | Version | char(14) | YES | - | CODE-BACKED | Script version in dotted format (e.g., "01.000.000.000", "02.000.000.000"). Fixed-width char(14) matches the 4-part version pattern XX.XXX.XXX.XXX. Version "02.000.000.000" indicates a re-run or second iteration of the same script. |
| 3 | ScriptName | varchar(200) | YES | - | CODE-BACKED | Name of the executed SQL script file. Follows the JIRA convention: {TICKET}_{Description}.sql (e.g., PART-5265_Fiktivo_ADF_Objects.sql). Serves as the idempotency key - deployment tools check for existing records with the same ScriptName before executing. |
| 4 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when the script was executed. Auto-captured via DEFAULT GETDATE(). Provides the chronological execution timeline. Combined with UpgradeScriptID, gives both ordering and exact timing. |
| 5 | LoginName | sysname | YES | ORIGINAL_LOGIN() | CODE-BACKED | Windows/SQL login that executed the script. Auto-captured via DEFAULT ORIGINAL_LOGIN() (not SUSER_SNAME - captures the original login, not an impersonated identity). Values: domain\username for manual deployments, CICD_DB_EXPERIENCE for CI/CD pipeline. |
| 6 | HostName | sysname | YES | HOST_NAME() | CODE-BACKED | Client machine name. Auto-captured via DEFAULT HOST_NAME(). Values: workstation names (e.g., PF2YPLJ7) for manual deployments, AKS runner pod names for CI/CD. |
| 7 | ScriptID | int | YES | - | CODE-BACKED | Optional script identifier for external tracking systems. Currently NULL in all recent records - appears to be a legacy column that is no longer populated by the current deployment framework. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No database objects reference this table. It is queried directly by deployment scripts and CI/CD pipelines for idempotency checks.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Deployment Scripts (external) | SQL Scripts | INSERT to record execution; SELECT to check idempotency |
| CI/CD Pipeline (external) | CICD_DB_EXPERIENCE | Automated deployments record their executions here |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BUPG | CLUSTERED | UpgradeScriptID ASC | - | - | Active (FILLFACTOR 90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BUPG | PRIMARY KEY | Unique identity for each script execution record |
| BUPG_OCCURRED | DEFAULT | GETDATE() - auto-captures execution timestamp |
| DF_UpgradeScript_LoginName | DEFAULT | ORIGINAL_LOGIN() - auto-captures the executing user's original login |
| CON_DefaultHostName | DEFAULT | HOST_NAME() - auto-captures the client machine name |
| NOT FOR REPLICATION | IDENTITY | UpgradeScriptID is not replicated - each environment has its own sequence |

---

## 8. Sample Queries

### 8.1 View recent deployments
```sql
SELECT TOP 20 UpgradeScriptID, ScriptName, Version, Occurred, LoginName, HostName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID DESC
```

### 8.2 Check if a script has already been executed (idempotency)
```sql
IF NOT EXISTS (
    SELECT 1 FROM BackOffice.UpgradeScript WITH (NOLOCK)
    WHERE ScriptName = 'PART-XXXX_MyMigration.sql'
)
BEGIN
    -- Execute migration here
    INSERT INTO BackOffice.UpgradeScript (Version, ScriptName)
    VALUES ('01.000.000.000', 'PART-XXXX_MyMigration.sql')
END
```

### 8.3 Deployment activity by month and source
```sql
SELECT YEAR(Occurred) AS Year,
       MONTH(Occurred) AS Month,
       CASE WHEN LoginName = 'CICD_DB_EXPERIENCE' THEN 'CI/CD' ELSE 'Manual' END AS Source,
       COUNT(*) AS ScriptCount
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE Occurred >= '2025-01-01'
GROUP BY YEAR(Occurred), MONTH(Occurred),
         CASE WHEN LoginName = 'CICD_DB_EXPERIENCE' THEN 'CI/CD' ELSE 'Manual' END
ORDER BY Year, Month
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found directly for this object. Script names reference JIRA tickets (PART-XXXX) which can be looked up individually for migration context.

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: fiktivo/BackOffice/Tables/BackOffice.UpgradeScript.sql*
