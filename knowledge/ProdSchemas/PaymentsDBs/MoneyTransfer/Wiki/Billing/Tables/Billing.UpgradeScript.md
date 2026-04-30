# Billing.UpgradeScript

> Migration tracking table that records manual database upgrade scripts executed against the Billing schema, preserving a history of schema changes with versioning, authorship, and timestamps.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | UpgradeScriptID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Billing.UpgradeScript is a schema migration audit table that records every manual database upgrade script executed against the Billing schema. Each row represents a single execution of an upgrade script, capturing the version, script name (including Jira ticket reference), who ran it, and when.

This table enables the operations and DBA teams to track which schema changes have been applied to the database, verify version alignment across environments, and troubleshoot deployment issues. Without it, there would be no record of manual schema modifications outside of the SSDT deployment pipeline.

The table is only 6 rows as of 2026, all dating from May 2022, suggesting the Billing schema was set up via manual scripts initially and has since been managed through the standard SSDT CI/CD pipeline (CICD_DB user has permissions). No stored procedures read from or write to this table - entries are created directly by migration scripts.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| UpgradeScriptID | Version | ScriptName | Occurred | LoginName | Meaning |
|---|---|---|---|---|---|
| 2 | 01.004.000.000 | GetTransfersByCID-PAYSOLB-1003 | 2022-05-22 | shayor@etoro.com | First execution of the GetTransfersByCID procedure creation script, linked to Jira ticket PAYSOLB-1003 for adding customer transfer lookup capability. |
| 3 | 01.004.000.000 | PostTransfer_Procedures-PAYSOLB-995 | 2022-05-22 | shayor@etoro.com | First attempt at deploying post-transfer action procedures (CreatePostTransfer, GetPostTransfer, etc.), linked to PAYSOLB-995. |
| 6 | 01.004.000.000 | PostTransfer_Procedures-PAYSOLB-995 | 2022-05-22 | shayor@etoro.com | Final successful execution of post-transfer procedures deployment. Multiple runs of the same script (IDs 3, 4, 6) suggest iterative fixes during initial setup. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. Sequential identifier for each script execution event. |
| 2 | Version | char(14) | YES | - | CODE-BACKED | Database schema version string in format `NN.NNN.NNN.NNN` (e.g., `01.004.000.000`). All 6 existing rows use the same version, indicating they were part of a single release package. Fixed-width char(14) matches the version format exactly. |
| 3 | ScriptName | varchar(200) | YES | - | CODE-BACKED | Name of the upgrade script executed, typically in format `{Description}-{JiraTicket}` (e.g., `PostTransfer_Procedures-PAYSOLB-995`). Serves as both a description and traceability link to the originating Jira ticket. |
| 4 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Timestamp of script execution. Defaults to current local time (GETDATE, not GETUTCDATE). Records when the migration was applied to this database instance. |
| 5 | LoginName | sysname | YES | ORIGINAL_LOGIN() | CODE-BACKED | Windows/SQL login of the person or service account that executed the script. Defaults to ORIGINAL_LOGIN() to capture the true identity even when impersonation is used. All existing entries show `shayor@etoro.com`. |
| 6 | HostName | sysname | YES | - | CODE-BACKED | Machine name from which the script was executed. Currently NULL for all rows - optional field that would be populated if the migration script explicitly sets it. |
| 7 | ScriptID | int | YES | - | CODE-BACKED | Optional numeric identifier for the script, potentially linking to an external script registry. Currently NULL for all rows - not in active use. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this table. It is a standalone audit/tracking table.

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
| PK_BUPG | CLUSTERED | UpgradeScriptID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BUPG_OCCURRED | DEFAULT | GETDATE() - auto-stamps execution time using local server time |
| DF__UpgradeSc__Login__72418BC6 | DEFAULT | ORIGINAL_LOGIN() - captures the true login identity of the executor |

---

## 8. Sample Queries

### 8.1 View all migration history
```sql
SELECT UpgradeScriptID, Version, ScriptName, Occurred, LoginName
FROM Billing.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID
```

### 8.2 Find all scripts for a specific Jira ticket
```sql
SELECT UpgradeScriptID, Version, ScriptName, Occurred, LoginName
FROM Billing.UpgradeScript WITH (NOLOCK)
WHERE ScriptName LIKE '%PAYSOLB-995%'
ORDER BY Occurred
```

### 8.3 Check the latest applied version
```sql
SELECT TOP 1 Version, ScriptName, Occurred, LoginName
FROM Billing.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.UpgradeScript | Type: Table | Source: MoneyTransfer/Billing/Tables/Billing.UpgradeScript.sql*
