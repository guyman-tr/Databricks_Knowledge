# History.ExceptionalCustomers

> Temporal history table preserving all superseded versions of exceptional customer risk classification overrides from BackOffice.ExceptionalCustomers, enabling audit trails of manual compliance interventions.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | GCID + RiskClassificationParameterID + BeginTime (clustered index) |
| **Partition** | No (PAGE compression) |
| **Indexes** | 1 active (clustered) |

---

## 1. Business Meaning

This is the temporal history table for `BackOffice.ExceptionalCustomers`. It stores all superseded versions of exceptional customer risk classification overrides - cases where compliance officers manually override a customer's risk score for a specific parameter. Each row represents a previous override state that has since been changed or removed.

The table enables compliance audit trails and regulatory lookback for manual risk overrides. If an auditor needs to know what risk overrides were in place for a customer on a specific date, this table provides that information via temporal queries.

Rows arrive automatically via SQL Server system-versioning when a row in BackOffice.ExceptionalCustomers is updated or deleted. The BeginTime/EndTime columns define the validity period of each historical version.

---

## 2. Business Logic

### 2.1 Temporal History Pattern

**What**: System-managed archive of superseded exceptional customer records.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`

**Rules**:
- Rows are inserted automatically when BackOffice.ExceptionalCustomers rows are modified
- BeginTime = when this version became effective
- EndTime = when this version was superseded (replaced by a newer version)
- A row with EndTime close to BeginTime of another row for same GCID+ParameterID shows a rapid succession of changes
- Parameter 9999 entries represent overrides to the final aggregate score itself

---

## 3. Data Overview

| GCID | ParameterID | RiskScore | BeginTime | EndTime | Meaning |
|------|------------|-----------|-----------|---------|---------|
| 2765779 | 9999 | 100 | 2023-01-23 | 2024-07-18 | This customer had an exceptional override forcing final score to 100 (High) for ~18 months. The override was removed or changed in July 2024. |
| 4583199 | 9999 | 100 | 2023-01-23 | 2024-07-18 | Same batch of exceptional overrides on the same date - likely a bulk compliance action. |
| 5046920 | 9999 | 100 | 2023-01-23 | 2024-07-18 | Another customer in the same bulk override batch. |

Total: ~127K historical override records.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | INT | NO | - | VERIFIED | Global Customer ID. Identifies the customer whose risk override is being tracked. Part of clustered index. |
| 2 | RiskClassificationParameterID | INT | NO | - | VERIFIED | Risk parameter being overridden. Parameter 9999 = final aggregate score override. See [Risk Classification Parameter](../_glossary.md#risk-classification-parameter). Part of clustered index. |
| 3 | RiskScore | INT | YES | - | VERIFIED | The overridden risk score value that was in effect during [BeginTime, EndTime). |
| 4 | BeginTime | DATETIME2(7) | NO | - | VERIFIED | Start of this historical version's validity period. Set when the override was created or last modified. |
| 5 | EndTime | DATETIME2(7) | NO | - | VERIFIED | End of this historical version's validity period. Set when the override was superseded by a new version or removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (parent) | BackOffice.ExceptionalCustomers | Temporal history | System-versioned history table for BackOffice.ExceptionalCustomers |
| RiskClassificationParameterID | Dictionary.RiskClassificationParameter | Implicit FK | Risk parameter lookup |

### 5.2 Referenced By (other objects point to this)

No other objects directly reference this history table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies. System-managed temporal history table.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| Idx_History_ExceptionalCustomers | CLUSTERED | GCID ASC, RiskClassificationParameterID ASC, BeginTime ASC | - | - | Active (FILLFACTOR 90, PAGE compression) |

### 7.2 Constraints

None. History tables do not carry PK or FK constraints - they are populated by the temporal system.

---

## 8. Sample Queries

### 8.1 Find all historical overrides for a customer
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore, BeginTime, EndTime
FROM History.ExceptionalCustomers WITH (NOLOCK)
WHERE GCID = 2765779
ORDER BY BeginTime DESC
```

### 8.2 Find overrides that were active on a specific date
```sql
SELECT GCID, RiskClassificationParameterID, RiskScore
FROM History.ExceptionalCustomers WITH (NOLOCK)
WHERE BeginTime <= '2023-06-01' AND EndTime > '2023-06-01'
```

### 8.3 Count historical overrides by parameter
```sql
SELECT RiskClassificationParameterID, COUNT(*) AS HistoricalOverrides
FROM History.ExceptionalCustomers WITH (NOLOCK)
GROUP BY RiskClassificationParameterID
ORDER BY HistoricalOverrides DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.6/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ExceptionalCustomers | Type: Table | Source: RiskClassification/History/Tables/History.ExceptionalCustomers.sql*
