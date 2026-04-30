# dbo.DailyBalanceSync

> Synchronization procedure that seeds and catches up DailyMovements and CustomerEODBalance data, handling initial load and gap-filling scenarios.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sync/seed ETL for DailyMovements + CustomerEODBalance |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

DailyBalanceSync handles initial seeding and catch-up of the daily balance data. While DailyBalanceCalculation runs as a regular scheduled job, DailyBalanceSync handles cases where data needs to be backfilled or re-synced (e.g., after a gap in processing or for newly onboarded accounts).

It reads from the same source tables (FiatTransactionsStatuses, FiatTransactions, FiatAccount, FiatCurrencyBalances) and writes to the same target tables (DailyMovements, CustomerEODBalance).

---

## 2. Business Logic

### 2.1 Sync/Seed Pattern

**What**: Fills gaps in DailyMovements and CustomerEODBalance that DailyBalanceCalculation may have missed.

**Rules**:
- Handles initial load for accounts without any DailyMovements
- Catches up gaps where scheduled runs were missed
- Same aggregation logic as DailyBalanceCalculation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

Parameters vary by version. Typically accepts date range or account filters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatTransactionsStatuses, dbo.FiatTransactions, dbo.FiatAccount, dbo.FiatCurrencyBalances | Read | Source data |
| INSERT/UPDATE | dbo.DailyMovements, dbo.CustomerEODBalance | Write | Target tables |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.DailyBalanceSync (procedure)
├── dbo.FiatTransactionsStatuses (table)
├── dbo.FiatTransactions (table)
├── dbo.FiatAccount (table)
├── dbo.FiatCurrencyBalances (table)
├── dbo.DailyMovements (table)
└── dbo.CustomerEODBalance (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactionsStatuses | Table | Source |
| dbo.FiatTransactions | Table | Source |
| dbo.FiatAccount | Table | Source |
| dbo.FiatCurrencyBalances | Table | Source |
| dbo.DailyMovements | Table | Target |
| dbo.CustomerEODBalance | Table | Target |

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

### 8.1 Run sync
```sql
EXEC dbo.DailyBalanceSync;
```

### 8.2 Verify sync results
```sql
SELECT TOP 10 * FROM dbo.DailyMovements WITH (NOLOCK) ORDER BY Created DESC;
SELECT TOP 10 * FROM dbo.CustomerEODBalance WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Check for gaps
```sql
SELECT DISTINCT DateId FROM dbo.DailyMovements WITH (NOLOCK) WHERE DateId >= 20260401 ORDER BY DateId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DailyBalanceSync | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.DailyBalanceSync.sql*
