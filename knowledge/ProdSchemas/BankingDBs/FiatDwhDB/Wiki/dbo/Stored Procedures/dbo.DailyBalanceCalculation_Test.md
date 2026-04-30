# dbo.DailyBalanceCalculation_Test

> Test version of DailyBalanceCalculation that operates on _Test tables (DailyMovements_Test, CustomerEODBalance_Test) for validation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Same ETL as DailyBalanceCalculation, targeting _Test tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DailyBalanceCalculation_Test performs the same ETL as DailyBalanceCalculation but targets the _Test tables (DailyMovements_Test, CustomerEODBalance_Test). Used to validate changes to the balance calculation logic without affecting production data.

---

## 2. Business Logic

Same as dbo.DailyBalanceCalculation but writes to _Test tables. See DailyBalanceCalculation for full logic.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProcessDate | int | YES | 31 | CODE-BACKED | Days to look back. Same as production version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT/INSERT/UPDATE | dbo.DailyMovements_Test, dbo.CustomerEODBalance_Test | Write | Test output tables |
| SELECT | dbo.FiatTransactionsStatuses, dbo.FiatTransactions, dbo.FiatAccount, dbo.FiatCurrencyBalances | Read | Same source data as production |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DailyBalanceCalculation_Test (procedure)
├── dbo.DailyMovements_Test (table)
├── dbo.CustomerEODBalance_Test (table)
├── dbo.FiatTransactionsStatuses (table)
├── dbo.FiatTransactions (table)
├── dbo.FiatAccount (table)
└── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.DailyMovements_Test | Table | Test write target |
| dbo.CustomerEODBalance_Test | Table | Test write target |
| dbo.FiatTransactionsStatuses | Table | Source data |
| dbo.FiatTransactions | Table | Source data |

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

### 8.1 Run test calculation
```sql
EXEC dbo.DailyBalanceCalculation_Test @ProcessDate = 7;
```

### 8.2 Verify test results
```sql
SELECT TOP 10 * FROM dbo.DailyMovements_Test WITH (NOLOCK) ORDER BY Created DESC;
SELECT TOP 10 * FROM dbo.CustomerEODBalance_Test WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Compare test vs production
```sql
SELECT 'Test' AS Src, COUNT(*) FROM dbo.DailyMovements_Test WITH (NOLOCK)
UNION ALL SELECT 'Prod', COUNT(*) FROM dbo.DailyMovements WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyBalanceCalculation_Test | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.DailyBalanceCalculation_Test.sql*
