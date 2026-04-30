# History.BSLSuspectedWrongResultsPartition

> Partition-generation equivalent of History.BSLSuspectedWrongResults; stores Balance Stop Loss suspected-wrong equity results on the PRIMARY filegroup instead of the EndMonth partition scheme.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (heap on PRIMARY) |
| **Partition** | No (PRIMARY filegroup, unlike BSLSuspectedWrongResults which uses EndMonth) |
| **Indexes** | 0 (heap - no indexes defined) |

---

## 1. Business Meaning

History.BSLSuspectedWrongResultsPartition is the PRIMARY-filegroup counterpart to History.BSLSuspectedWrongResults. Both tables have identical column structures and serve the same purpose: recording BSL equity calculation results that were flagged as potentially incorrect during a BSL execution run verification (Trade.CheckBSL).

The distinction is storage placement: BSLSuspectedWrongResults uses the EndMonth range partition scheme on Occurred (distributes rows across monthly partitions), while this Partition table stores on PRIMARY without partitioning. This pattern (Original + Partition-suffix) is common in the BSL family and typically represents a migration of the active write target while the original table retains its monthly partitioned data.

Currently empty (0 rows), suggesting either data has not yet been routed here, or it was a staging table used during a migration.

---

## 2. Business Logic

### 2.1 Identical to History.BSLSuspectedWrongResults

See History.BSLSuspectedWrongResults documentation for full business logic. This table has:
- Same columns (ExecutionID, CID, RealizedEquity, UnRealizedEquity, BSLRealFunds, BonusCredit, Occurred)
- Same BSL verification context
- Different filegroup placement (PRIMARY vs. EndMonth partition scheme)

The naming convention "...Partition" in the eToro BSL family typically means "newer generation that targets PRIMARY filegroup" rather than "uses a SQL Server partition scheme."

---

## 3. Data Overview

The table is empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExecutionID | int | NO | - | CODE-BACKED | BSL execution run where the discrepancy was detected. Links to Trade.ManageBSL ExecutionID. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer whose BSL result was suspect. Implicit FK to Customer.Customer. |
| 3 | RealizedEquity | money | YES | - | CODE-BACKED | Realized equity value flagged as suspect for this customer in this execution. See History.BSLSuspectedWrongResults for full description. |
| 4 | UnRealizedEquity | money | YES | - | CODE-BACKED | Unrealized PnL value that raised the discrepancy flag. |
| 5 | BSLRealFunds | money | YES | - | CODE-BACKED | BSL real funds (realized + unrealized, no bonus) - the threshold comparison value that appeared incorrect. |
| 6 | BonusCredit | money | YES | - | CODE-BACKED | Bonus credit component at time of suspect result. |
| 7 | Occurred | datetime | NO | getdate() | CODE-BACKED | Server timestamp when the suspect result was recorded. Default = getdate(). Unlike BSLSuspectedWrongResults, this column is NOT used as a partition key - table is on PRIMARY. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID | Trade.ManageBSL | Implicit | BSL run that produced the suspect result |
| CID | Customer.Customer | Implicit | Customer with flagged equity calculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BSLSuspectedWrongResultsPartition (table)
```

---

### 6.1 Objects This Depends On

No hard dependencies.

### 6.2 Objects That Depend On This

No dependents found in the codebase (0 rows, no active writers detected).

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. Heap table.

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (none) | - | - | - | - | - |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BSLSuspectedWrongResultsNEWPartition | DEFAULT | Occurred = getdate() |

---

## 8. Sample Queries

### 8.1 Check current row count
```sql
SELECT COUNT(*) AS RowCount FROM [History].[BSLSuspectedWrongResultsPartition] WITH (NOLOCK)
```

### 8.2 Get suspect results by execution
```sql
SELECT ExecutionID, CID, RealizedEquity, UnRealizedEquity, BSLRealFunds, BonusCredit, Occurred
FROM [History].[BSLSuspectedWrongResultsPartition] WITH (NOLOCK)
WHERE ExecutionID = @ExecutionID
ORDER BY CID
```

### 8.3 Compare record counts between Partition and non-Partition versions
```sql
SELECT 'BSLSuspectedWrongResults' AS TableName, COUNT(*) AS RowCount
FROM [History].[BSLSuspectedWrongResults] WITH (NOLOCK)
UNION ALL
SELECT 'BSLSuspectedWrongResultsPartition', COUNT(*)
FROM [History].[BSLSuspectedWrongResultsPartition] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (inherits context from BSLSuspectedWrongResults) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BSLSuspectedWrongResultsPartition | Type: Table | Source: etoro/etoro/History/Tables/History.BSLSuspectedWrongResultsPartition.sql*
