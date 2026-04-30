# History.CEPRuleToPosition_Archive

> Int-era archive of CEP rule-to-position assignments for positions opened 2014-2017, all with RuleID=-1 (no rule matched); bulk-migrated into temporal versioning September 2021. The bigint-era counterpart is History.CEPRuleToPosition.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (PositionID, RuleID) - composite PK CLUSTERED |
| **Partition** | No |
| **Temporal** | Yes - SYSTEM_VERSIONING=ON, HISTORY_TABLE=History.HistoryCEPRuleToPosition |
| **Indexes** | 1 (PK clustered, DATA_COMPRESSION=PAGE) |

---

## 1. Business Meaning

History.CEPRuleToPosition_Archive is the **int-era** table recording which CEP (Complex Event Processing) rules fired against trade positions. It covers positions opened in the int-era (PositionID as int, roughly 2014-2017). When the system migrated to bigint PositionIDs, this table was renamed with the `_Archive` suffix and the new History.CEPRuleToPosition (bigint) became the active table.

**All 797 rows have RuleID=-1**, the sentinel value meaning "no CEP rule was matched at assignment time." This is consistent with early-era positions predating meaningful CEP rule assignment. The table was bulk-loaded into SQL Server temporal versioning on 2021-09-13 (all SysStartTime values are identical: 2021-09-13 05:22:45), indicating a migration event rather than organic row-by-row inserts.

The table has active SYSTEM_VERSIONING with History.HistoryCEPRuleToPosition as its history table, meaning any future updates to rows here will produce versioned history records.

A trigger (TRG_T_CEPRuleToPosition) fires on INSERT: it does a no-op UPDATE (`SET PositionID=PositionID`) on matching rows in History.CEPRuleToPosition (the bigint table), which forces the temporal system to cut a new history record there. Because int-era PositionIDs (up to ~200M) do not overlap with bigint-era active PositionIDs, this trigger has no practical effect in production.

---

## 2. Business Logic

### 2.1 CEP Rule Assignment (Int-Era Positions)

**What**: Links a trade position to the CEP rule that was applied to it, on a specific hedge server, at a specific time.

**Columns/Parameters Involved**: `PositionID`, `RuleID`, `HedgeServerID`, `Ocurred`

**Rules**:
- One row per (PositionID, RuleID) - unique by composite PK
- Ocurred = UTC timestamp when the rule was applied (DEFAULT getutcdate())
- RuleID=-1 is a sentinel: no matching rule existed at assignment time
- HedgeServerID identifies which hedge server processed the rule event

### 2.2 Temporal Versioning via SYSTEM_VERSIONING

**What**: Any future UPDATE/DELETE on rows in this table will be versioned into History.HistoryCEPRuleToPosition.

**Key observation**: All current rows have identical SysStartTime (2021-09-13 05:22:45), confirming they were inserted in a single bulk operation. SysEndTime = '9999-12-31 23:59:59.9999999' on all rows = all are "current" rows, no temporal history generated yet.

### 2.3 Trigger TRG_T_CEPRuleToPosition

**What**: On INSERT into this table, the trigger does `UPDATE A SET A.PositionID=A.PositionID FROM History.CEPRuleToPosition A INNER JOIN Inserted B ON A.PositionID=B.PositionID AND A.RuleID=B.RuleID`.

**Effect**: The no-op UPDATE forces temporal versioning on History.CEPRuleToPosition (bigint) for matching rows. In practice, int-era PositionIDs do not overlap with active bigint-era PositionIDs in CEPRuleToPosition, so this trigger is a no-op in production.

### 2.4 Int-Era vs Bigint-Era Split

| Table | PositionID Type | Active? | Row Count | Date Range |
|-------|----------------|---------|-----------|------------|
| History.CEPRuleToPosition_Archive | int | No (legacy) | 797 | 2014-2017 |
| History.CEPRuleToPosition | bigint | No (inactive since May 2024) | 83,513 | 2023-2024 |

Both tables are now inactive. The CEP rule assignment mechanism appears to have been retired.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 797 |
| **Ocurred Range** | 2014-06-19 to 2017-04-25 |
| **SysStart Range** | All identical: 2021-09-13 05:22:45 (bulk migration) |
| **Distinct RuleIDs** | 1 (only RuleID=-1) |
| **Distinct HedgeServerIDs** | 2 (HedgeServerID 1 and 8) |

Sample rows:

| PositionID | RuleID | HedgeServerID | Ocurred |
|-----------|--------|--------------|---------|
| 119770983 | -1 | 8 | 2016-09-26 12:12:25 |
| 119770982 | -1 | 8 | 2016-09-26 10:47:14 |
| 119770979 | -1 | 1 | 2014-06-19 06:19:43 |

All rows: RuleID=-1 (no CEP rule matched for any int-era position).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionID | int | NO | - | VERIFIED | Trade position ID (int era, values ~1-200M). The position to which the CEP rule was assigned. Implicit FK to Trade.PositionTbl (int-era positions). PK component. |
| 2 | RuleID | int | NO | - | VERIFIED | ID of the CEP rule that fired. FK to CEP.Rules. All current rows: -1 (sentinel = no rule matched / rule deleted at assignment time). PK component. Note: same typo pattern ("Ocurred") shared with parent table. |
| 3 | HedgeServerID | int | NO | - | VERIFIED | ID of the hedge server that processed the rule event. Implicit FK to History.HedgeServer. Observed: 1 and 8. |
| 4 | Ocurred | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when the CEP rule was applied to the position. Note: column name has a typo ("Ocurred" not "Occurred") - inherited from the original CEP table design, consistent across the CEP table family. |
| 5 | DbLoginName | computed AS suser_name() | - | - | VERIFIED | SQL Server login name at write time. Computed, not persisted. Records which DB login performed the insert. |
| 6 | AppLoginName | computed AS CONVERT(varchar(500), context_info()) | - | - | VERIFIED | Application-layer login name, passed via SET CONTEXT_INFO before the insert. Computed, not persisted. |
| 7 | SysStartTime | datetime2(7) GENERATED ALWAYS AS ROW START | NO | getutcdate() | VERIFIED | True temporal system column (GENERATED ALWAYS) - marks when the row version became current. All existing rows: 2021-09-13 05:22:45 (bulk migration date). |
| 8 | SysEndTime | datetime2(7) GENERATED ALWAYS AS ROW END | NO | '9999-12-31 23:59:59.9999999' | VERIFIED | True temporal system column (GENERATED ALWAYS) - marks when the row version was superseded. All existing rows: 9999-12-31 (current, not yet versioned). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl (int-era rows) | Implicit | The trade position to which the CEP rule was assigned. Int PositionIDs only. |
| RuleID | CEP.Rules | Implicit | The CEP rule. All rows have -1 (sentinel). |
| HedgeServerID | History.HedgeServer | Implicit | The hedge server context. Observed: HedgeServerID 1 and 8. |
| (SYSTEM_VERSIONING) | History.HistoryCEPRuleToPosition | Temporal | Auto-managed history table for this table's row versions. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TRG_T_CEPRuleToPosition (trigger on this table) | PositionID, RuleID | Self-referential via trigger | On INSERT, does no-op UPDATE on History.CEPRuleToPosition (bigint) to force temporal versioning there. |
| History.HistoryCEPRuleToPosition | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | Receives all closed row versions from this table when rows are updated or deleted. Documented in History.HistoryCEPRuleToPosition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CEPRuleToPosition_Archive (table)
  - leaf node (no code-level upstream dependencies)
  - SYSTEM_VERSIONING -> History.HistoryCEPRuleToPosition (auto-managed)
  - Trigger touches -> History.CEPRuleToPosition (bigint)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.HistoryCEPRuleToPosition | Table | HISTORY_TABLE for SYSTEM_VERSIONING - auto-populated by SQL Server |
| History.CEPRuleToPosition | Table | Trigger TRG_T_CEPRuleToPosition does no-op UPDATE on it on INSERT |

### 6.2 Objects That Depend On This

No downstream objects discovered in SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Options |
|-----------|------|-------------|-----------------|--------|---------|
| PK_CEPRuleToPosition | CLUSTERED PK | PositionID ASC, RuleID ASC | - | - | DATA_COMPRESSION=PAGE, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CEPRuleToPosition | PRIMARY KEY CLUSTERED | (PositionID, RuleID) |
| DF (Ocurred) | DEFAULT | getutcdate() |
| DF_CEPRuleToPosition_SysStart | DEFAULT | getutcdate() (overridden by GENERATED ALWAYS) |
| DF_CEPRuleToPosition_SysEnd | DEFAULT | '9999-12-31 23:59:59.9999999' (overridden by GENERATED ALWAYS) |

### 7.3 Triggers

| Trigger | Event | Description |
|---------|-------|-------------|
| TRG_T_CEPRuleToPosition | FOR INSERT | No-op UPDATE on History.CEPRuleToPosition (bigint) for matching PositionID/RuleID. Forces temporal versioning cut on bigint table. Practical effect: none (int/bigint PositionID ranges do not overlap). |

---

## 8. Sample Queries

### 8.1 View all int-era CEP rule assignments
```sql
SELECT PositionID, RuleID, HedgeServerID, Ocurred, SysStartTime
FROM History.CEPRuleToPosition_Archive
ORDER BY Ocurred DESC;
```

### 8.2 Combined int-era + bigint-era rule assignments
```sql
SELECT CAST(PositionID AS bigint) AS PositionID, RuleID, HedgeServerID, Ocurred, 'Int-era (Archive)' AS Source
FROM History.CEPRuleToPosition_Archive
UNION ALL
SELECT PositionID, RuleID, HedgeServerID, Ocurred, 'Bigint-era' AS Source
FROM History.CEPRuleToPosition WITH (NOLOCK)
ORDER BY Ocurred DESC;
```

### 8.3 Check temporal history for a specific position
```sql
SELECT PositionID, RuleID, HedgeServerID, Ocurred, SysStartTime, SysEndTime
FROM History.CEPRuleToPosition_Archive
FOR SYSTEM_TIME ALL
WHERE PositionID = 119770983;
```

---

## 9. Atlassian Knowledge Sources

Confluence search found "DB Tables And Fields" pages (general DB reference, not CEP-specific). No CEP-specific Confluence page found. For CEP context, see History.CEPRuleToPosition documentation.

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence (relevant) | Procedures: 1 trigger analyzed | App Code: not scanned*
*Object: History.CEPRuleToPosition_Archive | Type: Table | Source: etoro/etoro/History/Tables/History.CEPRuleToPosition_Archive.sql*
