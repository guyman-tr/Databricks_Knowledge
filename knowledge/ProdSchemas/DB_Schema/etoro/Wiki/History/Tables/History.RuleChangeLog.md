# History.RuleChangeLog

> System-versioned temporal history table for CEP.RuleChangeLog, archiving all past states of the Complex Event Processing (CEP) rule change audit entries, including what rule configuration changed, when, and by whom.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite temporal key (SysEndTime, SysStartTime) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

This table is the **active system-versioned temporal history table** for `CEP.RuleChangeLog`. SQL Server archives superseded rows here when rows in the source table are updated or deleted.

`CEP.RuleChangeLog` records every configuration change event in the CEP (Complex Event Processing) hedging rules engine. The CEP system manages automated routing of hedge orders between hedge servers based on configured rules. Whenever an operator or automated process modifies a rule or related configuration, an entry is written to `CEP.RuleChangeLog` with: what type of change occurred (`ChangeType`), what kind of entity was changed (`ChangeItemType`), a descriptive message (`Messgae` - note the typo in the column name), and who made the change (`DbLoginName` = SQL login, `AppLoginName` = application context).

The temporal history table (`History.RuleChangeLog`) tracks changes to those change log entries themselves - i.e., if a logged event record is ever updated. The table is currently empty (0 rows), meaning no CEP.RuleChangeLog entries have been modified after being created.

Note: The source table also has a trigger `Tr_T_RuleChangeLoge_INSERT` that on INSERT, updates a `CEP.OccueredAt` table - a secondary tracking mechanism.

---

## 2. Business Logic

### 2.1 CEP Rule Configuration Change Audit

**What**: Each row in the source (`CEP.RuleChangeLog`) represents a configuration change event in the CEP hedging rules engine. The history table archives modifications to those events.

**Columns/Parameters Involved**: `ChangeType`, `ChangeItemType`, `Messgae`

**Rules**:
- `ChangeType` classifies the operation type (insert, update, delete, enable, disable - exact values not confirmed)
- `ChangeItemType` identifies what entity category was modified (rule, property, condition, etc. - exact values not confirmed)
- `Messgae` (typo for "Message") contains a human-readable or JSON description of the change
- `DbLoginName`: computed as `suser_name()` in the source - the SQL Server login that made the change
- `AppLoginName`: computed as `CONVERT(varchar(500), context_info())` - application-set context identifier

---

## 3. Data Overview

The table has no rows in production. No rows in CEP.RuleChangeLog have been modified after insertion.

| ChangeID | OccueredAt | ChangeType | ChangeItemType | Messgae | Meaning |
|---|---|---|---|---|---|
| (no rows) | - | - | - | - | No CEP.RuleChangeLog entries have been modified after initial insertion |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeID | bigint | NO | - | CODE-BACKED | Identifier of the original `CEP.RuleChangeLog` row (IDENTITY bigint in source, NOT an identity here). Same ChangeID can appear multiple times - one per historical state of the log entry. |
| 2 | OccueredAt | datetime | NO | - | CODE-BACKED | Timestamp when the rule change event occurred in the CEP system (note: "OccueredAt" is a typo for "OccurredAt" that is preserved in the DDL). Set by the source table. The trigger `Tr_T_RuleChangeLoge_INSERT` copies this value to `CEP.OccueredAt` on INSERT. |
| 3 | ChangeType | int | NO | - | NAME-INFERRED | Integer code identifying the type of operation performed (e.g., insert, update, delete, enable, disable). Exact values not defined in DDL; defined in application code or a lookup table not identified. |
| 4 | ChangeItemType | int | NO | - | NAME-INFERRED | Integer code identifying the category of entity that was changed (e.g., rule, property, condition, schedule). Exact values not defined in DDL; defined in application code. |
| 5 | Messgae | nvarchar(max) | NO | - | CODE-BACKED | Human-readable or structured description of the rule configuration change (note: "Messgae" is a typo for "Message" preserved in DDL). Contains details of what changed. Stored as nvarchar(max) with TEXTIMAGE_ON, accommodating verbose change descriptions or JSON payloads. |
| 6 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Computed in the source as `suser_name()` - captures the SQL Server login name of whoever executed the change. Stored as a plain value in the history table. Nullable (NULL in history = the computed column evaluated to NULL at the time). |
| 7 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Computed in the source as `CONVERT(varchar(500), context_info())` - the application-set session context. Applications set this via `SET CONTEXT_INFO` before writing to CEP.RuleChangeLog to identify the app-level caller. |
| 8 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | UTC instant when this CEP.RuleChangeLog row became the current state. Automatically managed by SQL Server temporal system versioning. |
| 9 | SysEndTime | datetime2(7) | NO | '9999-12-31...' | CODE-BACKED | UTC instant when this row was superseded. Automatically set by SQL Server. Leading key of the clustered index for temporal range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ChangeID | CEP.RuleChangeLog | Temporal History | Each row is a past state of the source log entry identified by ChangeID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CEP.RuleChangeLog | HISTORY_TABLE | Temporal History | Active source table; SQL Server archives modified rows here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.RuleChangeLog (table)
  (temporal history - no code-level dependencies; populated by SQL Server from CEP.RuleChangeLog)
```

---

### 6.1 Objects This Depends On

No dependencies. Temporal history table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CEP.RuleChangeLog | Table | Active source table; expired rows archived here automatically. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RuleChangeLog | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

Note: DATA_COMPRESSION = PAGE. TEXTIMAGE_ON [PRIMARY] for nvarchar(max) Messgae column.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage | Page compression for archival data. |

---

## 8. Sample Queries

### 8.1 Check if any change log entries have been modified
```sql
SELECT TOP 10 *
FROM [History].[RuleChangeLog] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

### 8.2 Point-in-time view of a specific change log entry
```sql
SELECT ChangeID, OccueredAt, ChangeType, ChangeItemType, Messgae, DbLoginName, AppLoginName
FROM [CEP].[RuleChangeLog]
FOR SYSTEM_TIME AS OF @PointInTime
WHERE ChangeID = @ChangeID
```

### 8.3 All historical states of CEP.RuleChangeLog entries
```sql
SELECT
    ChangeID,
    ChangeType,
    ChangeItemType,
    LEFT(Messgae, 200) AS MessagePreview,
    DbLoginName,
    AppLoginName,
    SysStartTime AS ValidFrom,
    SysEndTime AS ValidTo
FROM [History].[RuleChangeLog] WITH (NOLOCK)
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.8/10 (Elements: 7.8/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RuleChangeLog | Type: Table | Source: etoro/etoro/History/Tables/History.RuleChangeLog.sql*
