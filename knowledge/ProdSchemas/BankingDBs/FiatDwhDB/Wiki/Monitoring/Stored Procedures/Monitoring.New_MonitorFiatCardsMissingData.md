# Monitoring.New_MonitorFiatCardsMissingData

> Returns COUNT(*) of recent dbo.FiatCards records as [Value]. Zero = data gap. Newer version of MonitorFiatCardsMissingData.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT COUNT(*) FROM dbo.FiatCards WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

## 1. Business Meaning

Newer version of MonitorFiatCardsMissingData. Returns COUNT(*) AS [Value] instead of individual IDs. More efficient for alerting systems. SET NOCOUNT ON.

## 2. Business Logic

`SELECT COUNT(*) AS [Value] FROM dbo.FiatCards WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | YES | 24 | CODE-BACKED | Hours to look back. |

## 5. Relationships

Reads: dbo.FiatCards.

## 6. Dependencies

Depends on: dbo.FiatCards.

## 7. Technical Details

N/A.

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.New_MonitorFiatCardsMissingData;
```

### 8.2 Short window
```sql
EXEC Monitoring.New_MonitorFiatCardsMissingData @TimeFrameInHours = 1;
```

### 8.3 Alert on zero
```sql
DECLARE @r TABLE ([Value] int);
INSERT INTO @r EXEC Monitoring.New_MonitorFiatCardsMissingData @TimeFrameInHours = 1;
IF (SELECT [Value] FROM @r) = 0 PRINT 'ALERT: No recent FiatCards data!';
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.New_MonitorFiatCardsMissingData | Type: Stored Procedure*
