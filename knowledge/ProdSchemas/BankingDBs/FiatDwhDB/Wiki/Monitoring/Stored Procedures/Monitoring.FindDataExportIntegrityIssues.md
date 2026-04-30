# Monitoring.FindDataExportIntegrityIssues

> Data integrity monitor that detects orphaned records: accounts without currency balances, cards without statuses, cards without provider mappings, and transactions without statuses.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UNION of LEFT JOIN IS NULL checks across 4 parent-child relationships |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

FindDataExportIntegrityIssues detects records that exist in a parent table but are missing the expected child records. This catches data export/sync failures where a parent was synced but its children were not. Checks 4 integrity cases:
1. FiatAccount without FiatCurrencyBalances (account has no currency balances)
2. FiatCards without FiatCardStatuses (card has no status history)
3. FiatCards without CardsProvidersMapping (card has no provider mapping)
4. FiatTransactions without FiatTransactionsStatuses (transaction has no status events)

Uses @hoursGap to ignore very recent records (still being processed) and @hoursIgnore to skip very old records.

---

## 2. Business Logic

### 2.1 Four Integrity Checks

**Parameters**: `@hoursGap` (default 2, skip records newer than N hours), `@LimitRowsPerCase` (default 100), `@hoursIgnore` (default 336/14 days, skip very old)

**Rules**:
- LEFT JOIN parent -> child WHERE child.FK IS NULL
- Time window: between @hoursGap and @hoursIgnore hours old
- Excludes GCID=0 accounts (test/system accounts)
- Returns Id, UseCase (string label), Created per orphan

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @hoursGap | int | YES | 2 | CODE-BACKED | Minimum age in hours. Records newer than this are ignored (still being processed). |
| 2 | @LimitRowsPerCase | int | YES | 100 | CODE-BACKED | Max rows to return per integrity case. |
| 3 | @hoursIgnore | int | YES | 336 | CODE-BACKED | Maximum age in hours (336 = 14 days). Records older than this are ignored. |

---

## 5. Relationships

Reads: FiatAccount, FiatCurrencyBalances, FiatCards, FiatCardStatuses, CardsProvidersMapping, FiatTransactions, FiatTransactionsStatuses.

---

## 6. Dependencies

Depends on: 7 dbo tables (all documented).

---

## 7. Technical Details

N/A.

---

## 8. Sample Queries

### 8.1 Run with defaults
```sql
EXEC Monitoring.FindDataExportIntegrityIssues;
```

### 8.2 Check last 6 hours with tight window
```sql
EXEC Monitoring.FindDataExportIntegrityIssues @hoursGap = 1, @hoursIgnore = 6, @LimitRowsPerCase = 10;
```

### 8.3 Count issues by case
```sql
DECLARE @r TABLE (Id bigint, UseCase varchar(200), Created datetime);
INSERT INTO @r EXEC Monitoring.FindDataExportIntegrityIssues;
SELECT UseCase, COUNT(*) AS IssueCount FROM @r GROUP BY UseCase;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.4/10*
*Object: Monitoring.FindDataExportIntegrityIssues | Type: Stored Procedure*
