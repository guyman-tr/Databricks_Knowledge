# History.Conditions

> Temporal HISTORY_TABLE for CEP.Conditions - stores 9,558 versioned row snapshots of CEP rule conditions as they are created, modified, and deleted; actively written to as CEP rules evolve.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table (clustered on SysEndTime, SysStartTime) |
| **Partition** | No |
| **Temporal** | Yes - HISTORY_TABLE for CEP.Conditions |
| **Indexes** | 1 (clustered on SysEndTime ASC, SysStartTime ASC) |
| **Compression** | DATA_COMPRESSION=PAGE |

---

## 1. Business Meaning

History.Conditions is the SQL Server temporal HISTORY_TABLE automatically managed by CEP.Conditions. It stores all prior row versions of CEP conditions - the individual condition expressions used to build CEP rules.

CEP.Conditions defines conditions of the form: `<PropertyID> <OperatorID> <Value>`. For example: "PropertyID=2 (instrument) OperatorID=1 (equals) Value=1211 (crypto instrument)". Each condition is a predicate that, when combined with others via AND/OR logic (through CompoundProperty), forms a complete CEP rule trigger.

9,558 rows with recent activity (last version: 2026-03-18) - CEP.Conditions is an **actively versioned** table. CEP rule conditions are modified frequently as the hedging system's behavior is tuned. Versions are short-lived (SysStartTime = SysEndTime in the most recent samples, indicating rapid successive updates).

---

## 2. Business Logic

### 2.1 Auto-Managed by SQL Server Temporal Versioning

**What**: Every change to a row in CEP.Conditions writes the previous version here.

**Rules**:
- Never written to directly
- 9,558 rows indicates significant change history for CEP conditions
- Short SysStartTime-to-SysEndTime windows observed (same timestamp in recent rows) = rapid successive updates, batch updates, or immediate corrections
- ValidFrom in the versioned rows is the application-level "effective from" date, distinct from SysStartTime (SQL Server temporal timestamp)

### 2.2 CEP Condition Structure

Each archived row represents a condition expression:
- `PropertyID` = what property is being tested (from Dictionary.ConditionProperties)
- `OperatorID` = comparison operator (from Dictionary.ConditionOperators, e.g., 1=equals)
- `Value` = the threshold or target value (varchar, e.g., "5", "1211", "100")
- `ValidFrom` = application-level effective date (business logic, not SQL Server temporal)
- `HostName` = server name that made the change (audit)

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 9,558 |
| **Last Updated** | 2026-03-18 23:18:58 (recent activity) |
| **Status** | Actively versioned - CEP conditions change frequently |

Sample archived conditions:

| ConditionID | OperatorID | Value | PropertyID | ValidFrom | SysStartTime | SysEndTime |
|------------|-----------|-------|-----------|-----------|-------------|------------|
| 4931 | 1 | "5" | 2 | 2026-03-18 23:18 | 2026-03-18 23:18 | 2026-03-18 23:18 |
| 4931 | 1 | "5" | 2 | 2026-03-18 23:18 | 2026-03-18 23:18 | 2026-03-18 23:18 |
| 4930 | 1 | "1211" | 2 | 2026-03-18 23:13 | 2026-03-18 23:13 | 2026-03-18 23:13 |

Note: Duplicate rows with identical SysStart/SysEnd timestamps occur when the base table is updated twice in rapid succession - SQL Server temporal granularity is datetime2(7).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConditionID | int | NO | - | VERIFIED | ID of the CEP condition being versioned. Matches CEP.Conditions.ConditionID. |
| 2 | OperatorID | int | NO | - | VERIFIED | Comparison operator for this condition. FK to Dictionary.ConditionOperators. E.g., 1=equals. |
| 3 | Value | varchar(50) | NO | - | VERIFIED | The threshold or target value for the condition. Varchar to accommodate numeric, string, and list values. |
| 4 | PropertyID | int | NO | - | VERIFIED | The property being tested. FK to Dictionary.ConditionProperties. E.g., 2=some instrument-related property. |
| 5 | ValidFrom | datetime | YES | - | CODE-BACKED | Application-level effective date for this condition. Business logic field, distinct from SQL Server's SysStartTime. Set by the CEP UI/service layer. |
| 6 | DbLoginName | nvarchar(128) | YES | - | VERIFIED | SQL Server login at time of change. Audit column. |
| 7 | AppLoginName | varchar(500) | YES | - | VERIFIED | Application login from context_info(). Audit column. |
| 8 | SysStartTime | datetime2(7) | NO | - | VERIFIED | When this version became current in CEP.Conditions. Set by SQL Server temporal engine. |
| 9 | SysEndTime | datetime2(7) | NO | - | VERIFIED | When this version was superseded. Set by SQL Server temporal engine. |
| 10 | HostName | nvarchar(128) | YES | - | CODE-BACKED | Server hostname that performed the change. Additional audit field beyond DbLoginName/AppLoginName. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | CEP.Conditions | HISTORY_TABLE (temporal) | Auto-managed history table for CEP.Conditions. |
| OperatorID | Dictionary.ConditionOperators | Implicit (via base table) | The operator type used in the condition. |
| PropertyID | Dictionary.ConditionProperties | Implicit (via base table) | The property being evaluated. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Compression |
|-----------|------|-------------|-------------|
| ix_Conditions | CLUSTERED | SysEndTime ASC, SysStartTime ASC | PAGE |

---

## 8. Sample Queries

```sql
-- Full history of a specific condition
SELECT ConditionID, OperatorID, Value, PropertyID, ValidFrom, SysStartTime, SysEndTime
FROM CEP.Conditions
FOR SYSTEM_TIME ALL
WHERE ConditionID = 4931
ORDER BY SysStartTime;

-- State of all conditions as of a specific date
SELECT ConditionID, OperatorID, Value, PropertyID
FROM CEP.Conditions
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY ConditionID;
```

---

*Generated: 2026-03-19 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: History.Conditions | Type: Table | Source: etoro/etoro/History/Tables/History.Conditions.sql*
