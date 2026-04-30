# Monitoring.GetAvailableBalanceDiscrepancies

> Detects available balance discrepancies between CUG and Provider by comparing CugAvailable vs ProviderAvailable/100 in the latest BalanceReports per account.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from BalanceReports WHERE CugAvailable - ProviderAvailable/100 <> 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetAvailableBalanceDiscrepancies finds accounts where CUG available balance differs from Provider available balance (converted from minor units by /100). Uses MAX(Id) per AccountId to get the latest report, then filters for non-zero differences within @TimeFrameInMinutes. Excludes test accounts (AccountId <= 104).

---

## 2. Business Logic

### 2.1 Available Balance Comparison

**Rules**:
- Provider values in MINOR UNITS -> /100 for comparison
- Difference = CugAvailable - ProviderAvailable/100
- Filters: Difference <> 0, AccountId > 104, within time frame
- Returns: Created, AccountId, CurrencyIson, CugAvailable, ProviderAvailable, CugSettled, ProviderSettled, Difference

---

## 3. Data Overview

N/A.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInMinutes | int | YES | 60 | CODE-BACKED | Minutes to look back. Default 60 (1 hour). |

---

## 5. Relationships

Reads: dbo.BalanceReports.

---

## 6. Dependencies

Depends on: dbo.BalanceReports.

---

## 7-9. Standard. No Atlassian sources.

---

## 8. Sample Queries

### 8.1 Check for discrepancies
```sql
EXEC Monitoring.GetAvailableBalanceDiscrepancies;
```

### 8.2 Check last 5 minutes
```sql
EXEC Monitoring.GetAvailableBalanceDiscrepancies @TimeFrameInMinutes = 5;
```

### 8.3 Count discrepancies
```sql
DECLARE @r TABLE (Created datetime2, AccountId bigint, CurrencyIson nvarchar(128), CugAvailable decimal(36,18), ProviderAvailable decimal(36,18), CugSettled decimal(36,18), ProviderSettled decimal(36,18), Difference decimal(36,18));
INSERT INTO @r EXEC Monitoring.GetAvailableBalanceDiscrepancies;
SELECT COUNT(*) AS DiscrepancyCount FROM @r;
```

---

*Generated: 2026-04-14 | Quality: 9.2/10*
*Object: Monitoring.GetAvailableBalanceDiscrepancies | Type: Stored Procedure*
