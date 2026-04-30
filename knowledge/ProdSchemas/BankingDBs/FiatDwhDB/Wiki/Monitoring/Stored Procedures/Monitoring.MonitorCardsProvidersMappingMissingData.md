# Monitoring.MonitorCardsProvidersMappingMissingData

> Returns IDs of recent CardsProvidersMapping records within @TimeFrameInHours. Empty result indicates data gap.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT Id FROM dbo.CardsProvidersMapping WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Checks dbo.CardsProvidersMapping for recent records. Returns IDs if data exists within @TimeFrameInHours (default 24). Empty result = data gap alert. Part of the 13 individual Monitor* SPs (consolidated version: FiatMissingData_RowsReturned). Newer version: New_MonitorCardsProvidersMappingMissingData returns COUNT instead.

---

## 2. Business Logic

`SELECT Id FROM dbo.CardsProvidersMapping WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

---

## 3-4. @TimeFrameInHours (default 24).

## 5-6. Reads: dbo.CardsProvidersMapping.

## 7-9. Standard.

---

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.MonitorCardsProvidersMappingMissingData;
```

### 8.2 Short window
```sql
EXEC Monitoring.MonitorCardsProvidersMappingMissingData @TimeFrameInHours = 1;
```

### 8.3 Count results
```sql
DECLARE @r TABLE (Id bigint);
INSERT INTO @r EXEC Monitoring.MonitorCardsProvidersMappingMissingData;
SELECT COUNT(*) FROM @r;
```

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.MonitorCardsProvidersMappingMissingData | Type: Stored Procedure*
