# Monitoring.GetFailedC2Fs

> Retrieves failed crypto-to-fiat conversions within a lookback window, including error details from the latest status, for failure investigation and alerting.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Failed conversions with error details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetFailedC2Fs retrieves conversions whose latest status is Failed (StatusId=2) within a configurable lookback window. It includes the error details (DetailsJson) from the ConversionStatuses record, providing operators with the failure reason. This is the primary procedure for monitoring conversion failure rates and investigating specific failures.

The procedure uses a well-structured MAX(Id) subquery pattern to get the latest status for each conversion, then filters to only failed ones.

---

## 2. Business Logic

### 2.1 Failed Conversion Detection with Error Details

**What**: Finds conversions with latest status = Failed, including error JSON.

**Columns/Parameters Involved**: `@HoursToLookBack`

**Rules**:
- Subquery: MAX(Id) per ConversionId to get latest status
- Inner join: latest status WHERE StatusId = 2 (Failed)
- Time filter: c.Occurred >= @FromDateTime (calculated as GETUTCDATE() - @HoursToLookBack hours)
- Default lookback: 24 hours
- Returns Gcid, CorrelationId, conversion details, status DetailsJson with error message
- Ordered by Occurred DESC (most recent failures first)
- Includes code comment documentation (rare in this codebase)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursToLookBack | int | NO | 24 | VERIFIED | Lookback window in hours. Default 24 hours. Conversions created before this window are excluded. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Gcid | bigint | VERIFIED | Customer ID |
| 2 | CorrelationId | uniqueidentifier | VERIFIED | Saga correlation ID |
| 3 | Occurred | datetime2 | VERIFIED | Conversion creation time |
| 4 | CryptoId | int | VERIFIED | Source crypto asset |
| 5 | FiatId | int | VERIFIED | Target fiat currency |
| 6 | CryptoAmount | decimal | VERIFIED | Crypto quantity attempted |
| 7 | StatusId | int | VERIFIED | Always 2 (Failed) |
| 8 | DetailsJson | varchar(max) | VERIFIED | Error details (e.g., "Crypto Transaction Failed") |
| 9 | StatusOccurred | datetime2 | VERIFIED | When the failure was recorded |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Conversion details + time filter |
| - | C2F.ConversionStatuses | INNER JOIN (subquery) | Latest status + failed filter + error details |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetFailedC2Fs (procedure)
├── C2F.Conversions (table)
└── C2F.ConversionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - conversion details |
| C2F.ConversionStatuses | Table | INNER JOIN subquery - latest failed status |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get failures from last 24 hours
```sql
EXEC Monitoring.GetFailedC2Fs
```

### 8.2 Get failures from last week
```sql
EXEC Monitoring.GetFailedC2Fs @HoursToLookBack = 168
```

### 8.3 Count failures by hour
```sql
SELECT DATEPART(HOUR, c.Occurred) AS HourOfDay, COUNT(*) AS Failures
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON cs.ConversionId = c.Id
WHERE cs.StatusId = 2 AND c.Occurred > DATEADD(DAY, -1, GETUTCDATE())
AND cs.Id = (SELECT MAX(Id) FROM C2F.ConversionStatuses WITH (NOLOCK) WHERE ConversionId = c.Id)
GROUP BY DATEPART(HOUR, c.Occurred)
ORDER BY HourOfDay
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 9 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetFailedC2Fs | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetFailedC2Fs.sql*
