# History.CEPRuleToPosition

> Inactive bigint-era archive of CEP rule-to-position assignments, recording which CEP rule triggered on which trade position on which hedge server - last written May 2024.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PositionID, RuleID) - composite PK CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

History.CEPRuleToPosition records which CEP (Complex Event Processing) rules fired against specific trade positions. Each row maps one trade position to one CEP rule, on one hedge server, at a specific time. This data tracks which automated CEP rule logic was applied to positions as part of the hedging and risk management pipeline.

This is the **bigint-era** version (PositionID bigint). The int-era counterpart is History.CEPRuleToPosition_Archive (int PositionID), which has active SYSTEM_VERSIONING. History.CEPRuleToPosition does NOT use SQL temporal versioning - it has SysStartTime/SysEndTime columns with default values that mimic the temporal structure, but these are not GENERATED ALWAYS system columns.

**Status: Inactive**. Data spans Jan 2023 to May 2024 (83,513 rows). No new writes since May 2024. The [PROD\CEP_UI_USER] login had direct INSERT permission - writes came from the CEP UI/service layer directly.

Only two distinct RuleIDs appear: 88 ("Rivka") with 61,132 rows, and -1 (sentinel for "no rule / rule deleted") with 22,381 rows.

---

## 2. Business Logic

### 2.1 CEP Rule Application to Positions

**What**: Records when a CEP rule fired against a trade position on a specific hedge server.

**Columns/Parameters Involved**: `PositionID`, `RuleID`, `HedgeServerID`, `Ocurred`

**Rules**:
- One row per (PositionID, RuleID) - unique by PK
- Ocurred = when the rule was applied (DEFAULT getutcdate())
- RuleID=-1 is a sentinel value indicating the rule was removed or no matching rule existed at write time
- HedgeServerID links to the hedge server that processed the rule event

### 2.2 SysStartTime/SysEndTime Columns

These columns mimic SQL Server temporal versioning structure (DEFAULT getutcdate() for SysStart, DEFAULT '9999-12-31' for SysEnd) but are NOT configured as GENERATED ALWAYS system columns and have no PERIOD FOR SYSTEM_TIME. They function as regular datetime2 columns. This pattern is consistent with other tables in this int-to-bigint migration series.

### 2.3 Relationship to History.CEPRuleToPosition_Archive

History.CEPRuleToPosition_Archive (int PositionID) has a trigger TRG_T_CEPRuleToPosition that fires on INSERT and does a no-op UPDATE (`SET PositionID=PositionID`) on matching rows in this table (History.CEPRuleToPosition). This forces temporal versioning to record a new row in HistoryCEPRuleToPosition if SysStartTime changes, but has no net effect on data in CEPRuleToPosition itself.

---

## 3. Data Overview

| PositionID | RuleID | HedgeServerID | Ocurred | Meaning |
|-----------|--------|--------------|---------|---------|
| 2150658563 | 88 | 1 | 2024-05-19 09:11 | "Rivka" rule applied to position on hedge server 1 |
| (various) | -1 | 1 | (various) | Rule deleted or no rule matched at assignment time |

83,513 rows total | Date range: 2023-01-04 to 2024-05-19 | Now inactive.

RuleID distribution: 88 "Rivka" = 61,132 rows | -1 (sentinel) = 22,381 rows

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | bigint | NO | - | VERIFIED | Trade position ID (bigint era). The position to which the CEP rule was applied. Implicit FK to Trade.PositionTbl/History.Position_Active. PK component. |
| 2 | RuleID | int | NO | - | VERIFIED | ID of the CEP rule that fired. FK to CEP.Rules. Observed values: 88 = "Rivka", -1 = rule deleted/no rule matched (sentinel). PK component. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | ID of the hedge server that processed the rule event. Implicit FK to History.HedgeServer. All observed rows: HedgeServerID=1. |
| 4 | Ocurred | datetime | YES | getutcdate() | CODE-BACKED | Timestamp when the CEP rule was applied to the position. Note: column name has a typo ("Ocurred" instead of "Occurred") - consistent with other CEP tables (same typo in CEPRuleToPosition_Archive). |
| 5 | DbLoginName | computed AS suser_name() | - | - | VERIFIED | SQL Server login name at write time. Computed column, not stored. |
| 6 | AppLoginName | computed AS CONVERT(varchar(500), context_info()) | - | - | VERIFIED | Application login name set via SET CONTEXT_INFO before write. Computed column, not stored. |
| 7 | SysStartTime | datetime2(7) | NO | getutcdate() | CODE-BACKED | Pseudo-temporal row start time. NOT a true GENERATED ALWAYS system column - regular datetime2 with a DEFAULT. Set at insert time. |
| 8 | SysEndTime | datetime2(7) | NO | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Pseudo-temporal row end time. NOT a true GENERATED ALWAYS system column - regular datetime2 with DEFAULT far-future date, indicating current/active row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl / History.Position_Active | Implicit | The trade position to which the CEP rule was applied. |
| RuleID | CEP.Rules | Implicit | The CEP rule that fired. RuleID=88 = "Rivka". |
| HedgeServerID | History.HedgeServer | Implicit | The hedge server context for the rule event. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.TRG_T_CEPRuleToPosition (trigger on CEPRuleToPosition_Archive) | PositionID, RuleID | No-op UPDATE | On INSERT to _Archive, touches matching rows here (no data change). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEPRuleToPosition (table)
  - leaf node: no code-level dependencies
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CEPRuleToPosition_Archive | Table (via trigger) | Trigger touches this table on Archive INSERT events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CEPRuleToPosition_BIGINT | CLUSTERED PK | PositionID ASC, RuleID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEPRuleToPosition_BIGINT | PRIMARY KEY CLUSTERED | (PositionID, RuleID), DATA_COMPRESSION=PAGE, on [HISTORY] filegroup |
| DF_CEPRuleToPosition_SysStart_BIGINT | DEFAULT | SysStartTime = getutcdate() |
| DF_CEPRuleToPosition_SysEnd_BIGINT | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |

---

## 8. Sample Queries

### 8.1 Get all rule assignments for a position
```sql
SELECT PositionID, RuleID, HedgeServerID, Ocurred
FROM History.CEPRuleToPosition WITH (NOLOCK)
WHERE PositionID = 2150658563;
```

### 8.2 Count rule assignments by rule
```sql
SELECT r.RuleID, r.Name AS RuleName, COUNT(h.PositionID) AS PositionCount
FROM History.CEPRuleToPosition h WITH (NOLOCK)
LEFT JOIN CEP.Rules r ON h.RuleID = r.RuleID
GROUP BY r.RuleID, r.Name
ORDER BY PositionCount DESC;
```

### 8.3 Combined int + bigint rule assignments (cross-era)
```sql
SELECT CAST(PositionID AS bigint) AS PositionID, RuleID, HedgeServerID, Ocurred, 'Archive (int)' AS Source
FROM History.CEPRuleToPosition_Archive WITH (NOLOCK)
UNION ALL
SELECT PositionID, RuleID, HedgeServerID, Ocurred, 'Current (bigint)' AS Source
FROM History.CEPRuleToPosition WITH (NOLOCK)
ORDER BY Ocurred DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence search found "CEP Schema" (ID: 1973846017) - likely contains schema-level CEP documentation.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 + 1 trigger analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CEPRuleToPosition | Type: Table | Source: etoro/etoro/History/Tables/History.CEPRuleToPosition.sql*
