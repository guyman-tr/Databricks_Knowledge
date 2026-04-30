# Monitoring.New_MonitorFiatCardStatusesMissingData

> Returns COUNT(*) of recent dbo.FiatCardStatuses records as [Value]. Zero = data gap. Newer version of MonitorFiatCardStatusesMissingData.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT COUNT(*) FROM dbo.FiatCardStatuses WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

## 1. Business Meaning

Newer version of MonitorFiatCardStatusesMissingData. Returns COUNT(*) AS [Value] instead of individual IDs. More efficient for alerting systems that only need to know if data exists. SET NOCOUNT ON for clean output.

## 2. Business Logic

`SELECT COUNT(*) AS [Value] FROM dbo.FiatCardStatuses WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | YES | 24 | CODE-BACKED | Hours to look back. |

## 5. Relationships

Reads: dbo.FiatCardStatuses.

## 6. Dependencies

Depends on: dbo.FiatCardStatuses.

## 7. Technical Details

N/A.

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.New_MonitorFiatCardStatusesMissingData;
```

### 8.2 Short window
```sql
EXEC Monitoring.New_MonitorFiatCardStatusesMissingData @TimeFrameInHours = 1;
```

### 8.3 Alert on zero
```sql
DECLARE @r TABLE ([Value] int);
INSERT INTO @r EXEC Monitoring.New_MonitorFiatCardStatusesMissingData @TimeFrameInHours = 1;
IF (SELECT [Value] FROM @r) = 0 PRINT 'ALERT: No recent FiatCardStatuses data!';
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.New_MonitorFiatCardStatusesMissingData | Type: Stored Procedure*
