# Monitoring.FiatMissingData_RowsReturned

> Comprehensive monitoring procedure that counts recent rows across all 13 dbo data tables in a single query, returning a per-table row count for data gap detection.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UNION ALL COUNT(*) across 13 dbo tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

FiatMissingData_RowsReturned is the comprehensive data freshness monitor for the fiat DWH. It counts rows created within the last @TimeFrameInHours (default 24) across all 13 core dbo tables in a single UNION ALL query. Each row in the result shows the table name and count, enabling quick detection of which tables stopped receiving data.

This is the consolidated version of the 13 individual Monitor* SPs. If any table shows 0 rows, it indicates a data pipeline issue.

---

## 2. Business Logic

### 2.1 Multi-Table Data Freshness Check

**What**: Counts recent rows across all dbo entity tables.

**Tables Monitored** (13):
- CardsProvidersMapping, CurrencyBalancesProvidersMapping, FiatAccount, FiatAccountStatuses, FiatBankAccount, FiatCards, FiatCardStatuses, FiatCurrencyBalances, FiatCurrencyBalancesStatuses, FiatMerchants, FiatTransactions, FiatTransactionsStatuses, TransactionsProvidersMapping

**Rules**:
- Uses `Created >= DATEADD(hour, -@TimeFrameInHours, GETUTCDATE())` for time filtering
- Returns `[Value]` (count) and `[Object]` (table name) per table
- WITH(NOLOCK) on all reads
- A count of 0 for any table indicates potential data gap

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | YES | 24 | CODE-BACKED | Hours to look back. Default 24 (full day). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | 13 dbo tables | Read | Counts recent rows per table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.FiatMissingData_RowsReturned (procedure)
├── dbo.CardsProvidersMapping (table)
├── dbo.CurrencyBalancesProvidersMapping (table)
├── dbo.FiatAccount (table)
├── dbo.FiatAccountStatuses (table)
├── dbo.FiatBankAccount (table)
├── dbo.FiatCards (table)
├── dbo.FiatCardStatuses (table)
├── dbo.FiatCurrencyBalances (table)
├── dbo.FiatCurrencyBalancesStatuses (table)
├── dbo.FiatMerchants (table)
├── dbo.FiatTransactions (table)
├── dbo.FiatTransactionsStatuses (table)
└── dbo.TransactionsProvidersMapping (table)
```

### 6.1 Objects This Depends On

All 13 core dbo entity tables (all documented).

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

### 8.1 Check data freshness (last 24 hours)
```sql
EXEC Monitoring.FiatMissingData_RowsReturned;
```

### 8.2 Check last 1 hour
```sql
EXEC Monitoring.FiatMissingData_RowsReturned @TimeFrameInHours = 1;
```

### 8.3 Find tables with zero recent rows (data gaps)
```sql
DECLARE @r TABLE ([Value] int, [Object] varchar(100));
INSERT INTO @r EXEC Monitoring.FiatMissingData_RowsReturned @TimeFrameInHours = 1;
SELECT * FROM @r WHERE [Value] = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Object: Monitoring.FiatMissingData_RowsReturned | Type: Stored Procedure*
