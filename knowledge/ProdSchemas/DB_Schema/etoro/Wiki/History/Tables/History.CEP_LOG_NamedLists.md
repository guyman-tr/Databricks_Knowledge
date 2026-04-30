# History.CEP_LOG_NamedLists

> Trigger-based audit log capturing previous versions of CEP named list definitions; each row records a past state of a named list's SQL statement, refresh interval, and type.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (NamedListID, ValidFrom, ValidTo) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEP_LOG_NamedLists captures the version history of named lists in the CEP rules engine. A named list is a dynamic or static data set that conditions can reference - for example, "customers with bonus accounts", "US ILQ customers", or other segmented customer/instrument groups. Named lists of type 2 execute a SQL statement (Statment) on a periodic interval (PeriodicIntervalSec) to refresh their membership. Named lists of type 1 appear to be simpler reference sets.

CEP.NamedLists stores the live definitions. When a named list definition is modified or deleted, triggers copy the old row here. With 11 rows, named list changes are infrequent compared to conditions or rules.

Key historical data shows lists like "Bonus traders" (periodic SQL-based list) and "US ILQ" (US customers from a specific broker label, periodically refreshed) - reflecting early-stage CEP rule targeting by customer segment.

---

## 2. Business Logic

### 2.1 Named List Change Capture

**What**: Each row is a snapshot of one named list definition before it was changed.

**Columns/Parameters Involved**: `NamedListID`, `Name`, `Statment`, `PeriodicIntervalSec`, `NamedListTypeID`, `ValidFrom`, `ValidTo`

**Rules**:
- NamedListTypeID=1: Simple/static list (no SQL statement; Statment is empty)
- NamedListTypeID=2: SQL-driven list (Statment contains a SELECT query executed every PeriodicIntervalSec seconds)
- Statment column (note: misspelled "Statment" not "Statement") stores the SQL query for dynamic lists; empty string for static or blank lists
- ValidFrom='2100-01-01' observed in one row - anomalous future timestamp, likely a data artifact from clock skew or manual correction
- Same trigger pattern: UPDATE/DELETE on CEP.NamedLists write old rows here

---

## 3. Data Overview

11 rows of named list change events. Key examples from data:

| NamedListID | Name | NamedListTypeID | Statment Summary | ValidFrom |
|---|---|---|---|---|
| 4 | US ILQ | 2 | SELECT CID from Customer.Customer where LabelID=14... | 2012-10-21 |
| 5 | Bonus traders | 2 | (empty - cleared) | 2013-01-30 |
| 15 | (blank) | 1 | (empty) | 2024-12-19 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NamedListID | int | NO | - | CODE-BACKED | Identifies the named list that was changed. References CEP.NamedLists. Part of composite PK. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | The human-readable name of the named list as it existed before this change. Examples: "Bonus traders", "US ILQ". |
| 3 | Statment | varchar(8000) | YES | - | CODE-BACKED | The SQL statement executed to populate this list (for dynamic lists, NamedListTypeID=2). Note: misspelling of "Statement" preserved from DDL. Empty string for static lists. |
| 4 | PeriodicIntervalSec | int | YES | - | CODE-BACKED | For SQL-driven lists, how often (in seconds) the SQL statement is re-executed to refresh list membership. 60=refresh every minute. NULL or 0 for static lists. |
| 5 | NamedListTypeID | int | YES | - | CODE-BACKED | Type of named list: 1=static/simple list, 2=SQL-driven dynamic list (executes Statment on schedule). |
| 6 | LastUpdated | datetime | YES | - | CODE-BACKED | Timestamp of the most recent list membership refresh at time of this change. May be NULL for lists that have never been refreshed. |
| 7 | ValidFrom | datetime | NO | - | CODE-BACKED | Timestamp when this named list version became active. Copied from parent row. Part of composite PK. |
| 8 | ValidTo | datetime | NO | getutcdate() | CODE-BACKED | Timestamp when this named list was superseded. Defaults to getutcdate() at INSERT. Part of composite PK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| NamedListID | CEP.NamedLists | Trigger audit | Past version of a live named list |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.NamedLists | DELETE/UPDATE triggers | Writer | Copies changed named list rows here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEP_LOG_NamedLists (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.NamedLists | Table | Trigger writer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEP_LOG_NamedLists | CLUSTERED PK | NamedListID ASC, ValidFrom ASC, ValidTo ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEP_LOG_NamedLists | PRIMARY KEY | (NamedListID, ValidFrom, ValidTo) |
| (DEFAULT) | DEFAULT | ValidTo = getutcdate() |

Storage: ON [PRIMARY] filegroup.

---

## 8. Sample Queries

### 8.1 View history of a specific named list
```sql
SELECT NamedListID, Name, Statment, PeriodicIntervalSec, NamedListTypeID, ValidFrom, ValidTo
FROM [History].[CEP_LOG_NamedLists]
WHERE NamedListID = @NamedListID
ORDER BY ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by triggers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEP_LOG_NamedLists | Type: Table | Source: etoro/etoro/History/Tables/History.CEP_LOG_NamedLists.sql*
