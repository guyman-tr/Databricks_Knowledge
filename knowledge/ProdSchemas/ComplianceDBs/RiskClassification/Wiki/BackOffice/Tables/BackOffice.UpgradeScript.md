# BackOffice.UpgradeScript

> Schema migration tracking table that logs every database upgrade script executed against the RiskClassification database, providing an audit trail of schema changes with timestamps, script names, and operator identity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | UpgradeScriptID (INT IDENTITY, CLUSTERED PK) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table serves as the deployment log for database schema changes. Each row records one upgrade script that was executed against the RiskClassification database, capturing the script name (often referencing a Jira ticket), the version number, who ran it, and when. This enables the team to trace any schema change back to its source and operator.

The table is not consumed by any business logic - it is purely operational/DevOps infrastructure for deployment tracking. With only 16 rows, it reflects the relatively low frequency of manual schema changes to the RiskClassification database.

---

## 2. Business Logic

### 2.1 Deployment Audit Trail

**What**: Tracks every manual schema change with full operator context.

**Columns/Parameters Involved**: `ScriptName`, `Version`, `LoginName`, `HostName`, `Occurred`

**Rules**:
- ScriptName typically references a Jira ticket and description (e.g., "COINF-2358 RiskClassification Job fails", "COINF-575,577, RiskClassification PEPs with Medium Risk Score and ScreeningService")
- LoginName captures who ran the script (e.g., "yuliakra@etoro.com") via ORIGINAL_LOGIN()
- HostName captures which machine it was run from via HOST_NAME()
- Occurred defaults to GETDATE() at execution time
- Version appears fixed at "01.000.000.000" for all entries

---

## 3. Data Overview

| UpgradeScriptID | Version | ScriptName | Occurred | LoginName | Meaning |
|----------------|---------|-----------|----------|-----------|---------|
| 16 | 01.000.000.000 | Remove exceptional Customers | 2024-07-18 | yuliakra@etoro.com | Most recent change - cleaned up exceptional customer overrides. Matches the July 2024 EndTime seen in History.ExceptionalCustomers. |
| 15 | 01.000.000.000 | COINF-2358 RiskClassification Job fails | 2023-02-02 | yuliakra@etoro.com | Fix for risk classification job failure bug. |
| 14 | 01.000.000.000 | COINF-575,577, RiskClassification PEPs with Medium Risk Score and ScreeningService | 2022-03-10 | yuliakra@etoro.com | PEP and screening status scoring logic update. |

Total: 16 upgrade scripts logged.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UpgradeScriptID | INT | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing PK. Sequential deployment counter. |
| 2 | Version | CHAR(14) | YES | - | CODE-BACKED | Version string, fixed-width. All observed values are "01.000.000.000". Appears to be a placeholder rather than a meaningful versioning scheme. |
| 3 | ScriptName | VARCHAR(MAX) | NO | - | VERIFIED | Name/description of the upgrade script executed. Typically includes Jira ticket references (COINF-xxxx) and a brief description. The primary audit field. NOT NULL. |
| 4 | Occurred | DATETIME | NO | GETDATE() | VERIFIED | When the script was executed. Defaults to current timestamp. Provides the deployment timeline. |
| 5 | LoginName | SYSNAME | YES | ORIGINAL_LOGIN() | VERIFIED | SQL Server login of the person who ran the script. Captured automatically via ORIGINAL_LOGIN(). E.g., "yuliakra@etoro.com". |
| 6 | HostName | SYSNAME | YES | HOST_NAME() | VERIFIED | Machine name from which the script was executed. Captured automatically via HOST_NAME(). E.g., "PF24288P". |
| 7 | ScriptID | INT | YES | - | CODE-BACKED | Optional script identifier. NULL in all observed rows. May reference an external deployment management system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. Standalone operational table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BUPG | CLUSTERED PK | UpgradeScriptID ASC | - | - | Active (DATA_COMPRESSION = PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BUPG | PRIMARY KEY | UpgradeScriptID (IDENTITY) |
| BUPG_OCCURRED | DEFAULT | GETDATE() - auto-captures execution time |
| (unnamed) | DEFAULT | ORIGINAL_LOGIN() on LoginName |
| (unnamed) | DEFAULT | HOST_NAME() on HostName |

---

## 8. Sample Queries

### 8.1 View all deployment history
```sql
SELECT UpgradeScriptID, Version, ScriptName, Occurred, LoginName, HostName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY UpgradeScriptID DESC
```

### 8.2 Find deployments by Jira ticket
```sql
SELECT UpgradeScriptID, ScriptName, Occurred, LoginName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE ScriptName LIKE '%COINF-%'
ORDER BY Occurred DESC
```

### 8.3 Deployment frequency by year
```sql
SELECT YEAR(Occurred) AS DeployYear, COUNT(*) AS Scripts
FROM BackOffice.UpgradeScript WITH (NOLOCK)
GROUP BY YEAR(Occurred)
ORDER BY DeployYear DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: RiskClassification/BackOffice/Tables/BackOffice.UpgradeScript.sql*
