# History.ConditionToRule

> Temporal HISTORY_TABLE for CEP.ConditionToRule - stores 3 versioned snapshots of direct condition-to-rule assignments; rarely changes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for CEP.ConditionToRule |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.ConditionToRule is the SQL Server temporal HISTORY_TABLE for CEP.ConditionToRule. It stores prior row versions when direct condition-to-rule mappings change.

CEP.ConditionToRule maps individual conditions directly to CEP rules (without going through compound properties). This is an alternative path for simple single-condition rules. Most complex rules use CEP.ConditionToCompoundProperty instead.

3 rows - very rarely modified. The observed history shows RuleID=92 with ConditionID=204 was changed on 2025-06-04 with a short 10-minute validity window, then changed again.

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every change to a row in CEP.ConditionToRule writes the prior version here.

**Rules**:
- Never written to directly
- 3 rows = minimal change history (CEP.ConditionToRule is very stable)
- Observed: rule-condition assignment (RuleID=92, ConditionID=204) modified with very short validity window (10 minutes), then immediately changed again

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 3 |
| **Last Change** | 2025-06-04 |

Sample:

| RuleID | ConditionID | ValidFrom | SysStartTime | SysEndTime |
|--------|------------|-----------|-------------|------------|
| 92 | 204 | 2025-06-04 09:41 | 2025-06-04 09:41 | 2025-06-04 09:51 |
| 92 | 204 | 2025-06-04 09:41 | 2025-06-04 09:41 | 2025-06-04 09:41 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RuleID | int | NO | - | VERIFIED | ID of the CEP rule. FK to CEP.Rules. |
| 2 | ConditionID | int | NO | - | VERIFIED | ID of the condition directly assigned to this rule. FK to CEP.Conditions. |
| 3 | ValidFrom | datetime | YES | - | CODE-BACKED | Application-level effective date for this assignment. |
| 4 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at time of change. Audit column. |
| 5 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info(). Audit column. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this version became current. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | CEP.ConditionToRule | HISTORY_TABLE (temporal) | Auto-managed history table for CEP.ConditionToRule. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_ConditionToRule | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- Full history of condition assignments to a rule
SELECT RuleID, ConditionID, ValidFrom, SysStartTime, SysEndTime
FROM CEP.ConditionToRule
FOR SYSTEM_TIME ALL
WHERE RuleID = 92
ORDER BY SysStartTime;
```

---

*Generated: 2026-03-19 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.ConditionToRule | Type: Table | Source: etoro/etoro/History/Tables/History.ConditionToRule.sql*
