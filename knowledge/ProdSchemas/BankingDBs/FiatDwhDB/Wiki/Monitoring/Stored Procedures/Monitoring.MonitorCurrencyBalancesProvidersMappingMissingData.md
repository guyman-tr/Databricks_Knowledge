# Monitoring.MonitorCurrencyBalancesProvidersMappingMissingData

> Returns IDs of recent CurrencyBalancesProvidersMapping records. Empty result = data gap.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT Id FROM dbo.CurrencyBalancesProvidersMapping WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

## 1. Business Meaning

Checks dbo.CurrencyBalancesProvidersMapping for recent records. Same pattern as all Monitor*MissingData SPs.

## 2. Business Logic

`SELECT Id FROM dbo.CurrencyBalancesProvidersMapping WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

## 4. Elements

@TimeFrameInHours (int, default 24).

## 5-6. Reads: dbo.CurrencyBalancesProvidersMapping.

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.MonitorCurrencyBalancesProvidersMappingMissingData;
```

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.MonitorCurrencyBalancesProvidersMappingMissingData | Type: Stored Procedure*
