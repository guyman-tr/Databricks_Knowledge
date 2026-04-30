# BackOffice.UpgradeScript

> Tracks database schema upgrade scripts applied to the MoneyTransfer database's BackOffice schema.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | None (no primary key defined) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

BackOffice.UpgradeScript is a metadata tracking table that records which database upgrade scripts have been executed against the BackOffice schema in the MoneyTransfer database. It serves as a simple registry pairing script versions to script filenames, enabling teams to determine the current schema state and which migrations have been applied.

This table exists to support manual schema migration tracking. Without it, DBAs and deployment processes would have no record of which ad-hoc upgrade scripts have been applied to the BackOffice schema, risking duplicate execution or missed migrations. In environments where schema changes are deployed via SSDT dacpac (automated deployment), this table may remain empty since the dacpac model handles versioning internally.

No stored procedures, views, or functions in the MoneyTransfer database reference this table, indicating that rows are inserted directly via ad-hoc SQL scripts during manual upgrade procedures rather than through application-layer code. A more feature-rich sibling table (`Billing.UpgradeScript`) exists in the same database with additional tracking columns including an auto-incrementing primary key, execution timestamp (`Occurred`, defaulting to `GETDATE()`), and the login name of the executor (`LoginName`, defaulting to `ORIGINAL_LOGIN()`). The BackOffice version is a simplified variant without these audit trail features.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. The table stores simple version-to-script-name pairs with no computed relationships, status transitions, hierarchies, or conditional logic. See individual element descriptions in Section 4.

---

## 3. Data Overview

The table is currently empty (0 rows) in this environment. This may indicate:

- The BackOffice schema is deployed via SSDT dacpac (automated deployment), making manual upgrade script tracking unnecessary
- Upgrade scripts have not been needed for the BackOffice schema (which contains only this single table)
- The table is a structural placeholder provisioned as part of a standard schema template

No sample data is available to display.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Version | varchar(25) | YES | - | NAME-INFERRED | Version identifier of the upgrade script that was applied. Typically follows a semantic or sequential versioning scheme (e.g., "1.0.0", "2.3.1"). Used to determine which schema version has been reached and whether a given upgrade script still needs to be run. No uniqueness constraint exists, so duplicate version entries are technically possible. Compared to sibling `Billing.UpgradeScript.Version` which allows varchar(50), this column's varchar(25) limit accommodates shorter version strings. |
| 2 | ScriptName | varchar(80) | YES | - | NAME-INFERRED | Name or filename of the upgrade script that was executed at the corresponding version. Identifies the specific migration applied (e.g., "AddTransferColumns.sql", "UpdateStatusValues.sql"). Compared to sibling `Billing.UpgradeScript.ScriptName` which allows varchar(100), this column's varchar(80) limit accommodates shorter script names. No uniqueness constraint exists. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. No foreign keys, implicit lookups, or JOIN-discovered relationships exist.

### 5.2 Referenced By (other objects point to this)

No references to this table were discovered. No views, stored procedures, functions, or other tables in the MoneyTransfer database reference BackOffice.UpgradeScript.

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

No indexes are defined. The table has no primary key, clustered index, or non-clustered indexes. This is consistent with a low-volume metadata tracking table that is written to infrequently and typically scanned in full.

### 7.2 Constraints

None. The table has no CHECK, DEFAULT, UNIQUE, or FOREIGN KEY constraints. Both columns are nullable with no validation rules enforced at the database level.

Notable contrast: The sibling `Billing.UpgradeScript` table has a clustered primary key (`UpgradeScriptID`), a DEFAULT constraint for `Occurred` (`GETDATE()`), and a DEFAULT constraint for `LoginName` (`ORIGINAL_LOGIN()`).

---

## 8. Sample Queries

### 8.1 List all applied upgrade scripts ordered by version

```sql
SELECT Version, ScriptName
FROM BackOffice.UpgradeScript WITH (NOLOCK)
ORDER BY Version
```

### 8.2 Check if a specific upgrade version has been applied

```sql
SELECT COUNT(*) AS IsApplied
FROM BackOffice.UpgradeScript WITH (NOLOCK)
WHERE Version = '1.0.0'
```

### 8.3 Compare upgrade history across schemas in MoneyTransfer

```sql
SELECT 'BackOffice' AS SchemaName, bo.Version, bo.ScriptName, NULL AS Occurred, NULL AS LoginName
FROM BackOffice.UpgradeScript bo WITH (NOLOCK)
UNION ALL
SELECT 'Billing', b.Version, b.ScriptName, CONVERT(varchar(30), b.Occurred, 120), b.LoginName
FROM Billing.UpgradeScript b WITH (NOLOCK)
ORDER BY SchemaName, Version
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Searches for "BackOffice.UpgradeScript" and "UpgradeScript" in Confluence and Jira returned no results relevant to this specific table.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 1.5/10 (Elements: 0/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.UpgradeScript | Type: Table | Source: MoneyTransfer/BackOffice/Tables/BackOffice.UpgradeScript.sql*
