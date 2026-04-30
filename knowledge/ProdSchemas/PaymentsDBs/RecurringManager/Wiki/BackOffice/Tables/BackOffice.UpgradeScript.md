# BackOffice.UpgradeScript

> Tracks database upgrade/migration scripts that have been executed against the RecurringManager database, enabling idempotent deployments.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | None (no primary key) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

BackOffice.UpgradeScript is a deployment tracking table that records which database migration scripts have been applied to the RecurringManager database. Each row represents a single script execution, logging the database version and the script name. This is a standard infrastructure pattern used to ensure scripts are not accidentally re-run during deployments.

Without this table, the deployment process would have no way to know which scripts have already been applied, risking duplicate execution of DDL or DML changes. This is especially important for one-time data migrations, alert configurations, and index additions that should not be repeated.

Data enters this table during the database deployment/upgrade process. Scripts in the `NoDbObjectsScripts` folder (such as DML migrations and configuration scripts) register themselves here after successful execution. The table is write-once - rows are inserted during deployment and never updated or deleted by application code. No stored procedures, views, or functions in the RecurringManager database reference this table; it is consumed exclusively by the deployment tooling.

---

## 2. Business Logic

### 2.1 Deployment Script Tracking

**What**: Maintains a log of all upgrade scripts that have been executed against the database.

**Columns/Parameters Involved**: `Version`, `ScriptName`

**Rules**:
- Each row records a script execution event with the database version at the time and the script identifier
- ScriptName values follow the pattern `{ScriptPurpose}-{JiraTicket}` (e.g., `Alert_StuckWithTemproraryStatus-PAYUS-3322`), tying each migration to its originating work item
- Duplicate entries can exist (the same Version + ScriptName combination may appear more than once), indicating the table does not enforce uniqueness - the deployment process is responsible for idempotency checks
- The Version field groups scripts by release (e.g., `01.004.000.000`), enabling version-based queries during rollback or audit

**Diagram**:
```
Deployment Pipeline
       |
       v
  NoDbObjectsScripts/
  (DML migrations)
       |
       v
  Execute script
       |
       v
  INSERT INTO BackOffice.UpgradeScript
  (Version, ScriptName)
       |
       v
  Script tracked - will not re-run
```

---

## 3. Data Overview

| Version | ScriptName | Meaning |
|---------|-----------|---------|
| 01.004.000.000 | Alert_StuckWithTemproraryStatus-PAYUS-3322 | Deployed an alert stored procedure that monitors payment executions stuck in a temporary status - part of the PAYUS-3322 monitoring initiative |
| 01.004.000.000 | Alert_SendToBillingFailed-PAYUS-3322 | Deployed an alert for detecting payment executions that failed to send to the billing provider |
| 01.004.000.000 | Alert_PlanedDatePassed_NotTaken-PAYUS-3322 | Deployed an alert for scheduler executions whose planned date has passed without being picked up for processing |
| 01.004.000.000 | Alert_NotScheduled_Payments-PAYUS-3322 | Deployed an alert for recurring payments that have no scheduled execution plan |
| 01.004.000.000 | Add_RecurringIndexes-PAYUSOLA-4511 | Deployed performance indexes on Recurring schema tables as part of the PAYUSOLA-4511 optimization effort |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Version | varchar(25) | YES | - | CODE-BACKED | Database release version at the time the script was executed. Uses four-part versioning format (e.g., `01.004.000.000`). Groups related migration scripts by release - all scripts deployed in a single release share the same Version value. Nullable, though all observed data has a value. |
| 2 | ScriptName | varchar(80) | YES | - | CODE-BACKED | Identifier of the migration script that was executed. Follows the naming convention `{Purpose}-{JiraTicket}` (e.g., `Alert_StuckWithTemproraryStatus-PAYUS-3322`). The purpose prefix describes what the script does (alert creation, index addition, data migration), while the JIRA ticket suffix provides traceability to the originating work item. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No database objects in the RecurringManager repository reference this table. It is consumed exclusively by the external deployment tooling.

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

None. The table has no indexes, including no primary key or clustered index (heap table).

### 7.2 Constraints

None. The table has no CHECK, DEFAULT, or UNIQUE constraints. Both columns are nullable with no enforced validation.

---

## 8. Sample Queries

### 8.1 List all scripts deployed in a specific version
```sql
SELECT Version, ScriptName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE Version = '01.004.000.000'
ORDER BY ScriptName
```

### 8.2 Check if a specific script has already been executed
```sql
SELECT COUNT(*) AS ExecutionCount
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE ScriptName = 'Alert_StuckWithTemproraryStatus-PAYUS-3322'
```

### 8.3 List all distinct versions with script counts
```sql
SELECT Version, COUNT(*) AS ScriptCount
FROM BackOffice.UpgradeScript WITH (NOLOCK)
GROUP BY Version
ORDER BY Version
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 6.3/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 2.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: RecurringManager/BackOffice/Tables/BackOffice.UpgradeScript.sql*
