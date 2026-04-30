# Monitoring.MonitorFiatAccountMissingData

> Returns IDs of recent dbo.FiatAccount records. Empty result = data gap.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT Id FROM dbo.FiatAccount WHERE recent |
| **Partition** | N/A |
| **Indexes** | N/A |

## 1. Business Meaning

Checks dbo.FiatAccount for recent records within @TimeFrameInHours (default 24). Returns IDs if data exists. Empty result = data gap alert. Part of the 13 Monitor*MissingData SP family.

## 2. Business Logic

`SELECT Id FROM dbo.FiatAccount WHERE DATEDIFF(hour, Created, GETUTCDATE()) < @TimeFrameInHours`

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | YES | 24 | CODE-BACKED | Hours to look back. |

## 5. Relationships

Reads: dbo.FiatAccount.

## 6. Dependencies

Depends on: dbo.FiatAccount.

## 7. Technical Details

N/A.

## 8. Sample Queries

### 8.1 Check
```sql
EXEC Monitoring.MonitorFiatAccountMissingData;
```

### 8.2 Short window
```sql
EXEC Monitoring.MonitorFiatAccountMissingData @TimeFrameInHours = 1;
```

### 8.3 Count
```sql
DECLARE @r TABLE (Id bigint);
INSERT INTO @r EXEC Monitoring.MonitorFiatAccountMissingData;
SELECT COUNT(*) FROM @r;
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Monitoring.MonitorFiatAccountMissingData | Type: Stored Procedure*
