# Monitoring.New_MonitorFiatCurrencyBalancesStatusesMissingData

> Returns COUNT(*) of recent dbo.FiatCurrencyBalancesStatuses records as [Value]. Zero = data gap. Newer version of MonitorFiatCurrencyBalancesStatusesMissingData.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT COUNT(*) FROM dbo.FiatCurrencyBalancesStatuses WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

## 1. Business Meaning

Newer version of MonitorFiatCurrencyBalancesStatusesMissingData. Returns COUNT(*) AS [Value] instead of individual IDs. More efficient for alerting systems. SET NOCOUNT ON.

## 2. Business Logic

`SELECT COUNT(*) AS [Value] FROM dbo.FiatCurrencyBalancesStatuses WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | YES | 24 | CODE-BACKED | Hours to look back. |

## 5. Relationships

Reads: dbo.FiatCurrencyBalancesStatuses.

## 6. Dependencies

Depends on: dbo.FiatCurrencyBalancesStatuses.

## 7. Technical Details

N/A.

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.New_MonitorFiatCurrencyBalancesStatusesMissingData;
```

### 8.2 Short window
```sql
EXEC Monitoring.New_MonitorFiatCurrencyBalancesStatusesMissingData @TimeFrameInHours = 1;
```

### 8.3 Alert on zero
```sql
DECLARE @r TABLE ([Value] int);
INSERT INTO @r EXEC Monitoring.New_MonitorFiatCurrencyBalancesStatusesMissingData @TimeFrameInHours = 1;
IF (SELECT [Value] FROM @r) = 0 PRINT 'ALERT: No recent FiatCurrencyBalancesStatuses data!';
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.New_MonitorFiatCurrencyBalancesStatusesMissingData | Type: Stored Procedure*
