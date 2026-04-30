# Monitoring.GetSettledBalanceDiscrepancies

> Detects settled balance discrepancies between CUG and Provider by comparing CugSettled vs ProviderSettled/100 in the latest BalanceReports per account.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from BalanceReports WHERE CugSettled - ProviderSettled/100 <> 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetSettledBalanceDiscrepancies finds accounts where CUG settled balance differs from Provider settled balance. Same pattern as the other balance discrepancy SPs but compares CugSettled vs ProviderSettled/100.

---

## 2. Business Logic

### 2.1 CUG vs Provider Settled Comparison

**Rules**: Difference = CugSettled - ProviderSettled/100. Same filtering as other balance SPs.

---

## 3-4. @TimeFrameInMinutes (default 60).

## 5-6. Reads: dbo.BalanceReports.

## 7-9. Standard.

---

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.GetSettledBalanceDiscrepancies;
```

### 8.2 Last 5 minutes
```sql
EXEC Monitoring.GetSettledBalanceDiscrepancies @TimeFrameInMinutes = 5;
```

### 8.3 Count
```sql
DECLARE @r TABLE (Created datetime2, AccountId bigint, CurrencyIson nvarchar(128), CugAvailable decimal(36,18), ProviderAvailable decimal(36,18), CugSettled decimal(36,18), ProviderSettled decimal(36,18), Difference decimal(36,18));
INSERT INTO @r EXEC Monitoring.GetSettledBalanceDiscrepancies;
SELECT COUNT(*) FROM @r;
```

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.GetSettledBalanceDiscrepancies | Type: Stored Procedure*
