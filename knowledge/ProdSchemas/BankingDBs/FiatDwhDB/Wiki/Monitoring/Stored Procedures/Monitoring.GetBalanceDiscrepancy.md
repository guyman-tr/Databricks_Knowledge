# Monitoring.GetBalanceDiscrepancy

> Detects settled balance discrepancies between CalcSettled and ProviderSettled/100 in the latest BalanceReports per account.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from BalanceReports WHERE CalcSettled - ProviderSettled/100 <> 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetBalanceDiscrepancy finds accounts where platform-calculated settled balance differs from Provider settled balance. Same pattern as GetAvailableBalanceDiscrepancies but compares CalcSettled vs ProviderSettled/100 (instead of CUG vs Provider). Returns accounts with non-zero differences.

---

## 2. Business Logic

### 2.1 Calc vs Provider Settled Comparison

**Rules**:
- Difference = CalcSettled - ProviderSettled/100
- Filters: Difference <> 0, AccountId > 104, within @TimeFrameInMinutes
- Uses MAX(Id) GROUP BY AccountId for latest report

---

## 3-4. @TimeFrameInMinutes (default 60).

## 5-6. Reads: dbo.BalanceReports.

## 7-9. Standard.

---

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.GetBalanceDiscrepancy;
```

### 8.2 Last 5 minutes
```sql
EXEC Monitoring.GetBalanceDiscrepancy @TimeFrameInMinutes = 5;
```

### 8.3 Count
```sql
DECLARE @r TABLE (Created datetime2, AccountId bigint, CurrencyIson nvarchar(128), CalcSettled decimal(36,18), ProviderSettled decimal(36,18), Difference decimal(36,18));
INSERT INTO @r EXEC Monitoring.GetBalanceDiscrepancy;
SELECT COUNT(*) FROM @r;
```

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.GetBalanceDiscrepancy | Type: Stored Procedure*
