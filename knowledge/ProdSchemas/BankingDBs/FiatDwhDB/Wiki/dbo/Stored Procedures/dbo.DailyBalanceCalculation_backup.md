# dbo.DailyBalanceCalculation_backup

> Backup copy of DailyBalanceCalculation. Same logic as the production version, preserved before a code change for rollback capability.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Backup of DailyBalanceCalculation - same ETL pipeline |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DailyBalanceCalculation_backup is a preserved copy of dbo.DailyBalanceCalculation before a code change. It performs the same multi-step ETL: aggregating settled transactions into DailyMovements and computing CustomerEODBalance. Retained for rollback if the current version has issues.

---

## 2. Business Logic

Same as dbo.DailyBalanceCalculation. See that procedure's documentation for full logic description.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessDate | int | YES | 31 | CODE-BACKED | Number of days to look back. Same as production version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/INSERT/UPDATE | dbo.DailyMovements, dbo.CustomerEODBalance, dbo.FiatTransactionsStatuses, dbo.FiatTransactions, dbo.FiatAccount, dbo.FiatCurrencyBalances | Read/Write | Same dependencies as DailyBalanceCalculation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as dbo.DailyBalanceCalculation. See that procedure's documentation.

### 6.1 Objects This Depends On

Same as dbo.DailyBalanceCalculation.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run backup version
```sql
EXEC dbo.DailyBalanceCalculation_backup;
```

### 8.2 Compare with production
```sql
-- Run both and compare DailyMovements output
EXEC dbo.DailyBalanceCalculation @ProcessDate = 1;
EXEC dbo.DailyBalanceCalculation_backup @ProcessDate = 1;
```

### 8.3 Verify results
```sql
SELECT TOP 10 * FROM dbo.DailyMovements WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyBalanceCalculation_backup | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.DailyBalanceCalculation_backup.sql*
