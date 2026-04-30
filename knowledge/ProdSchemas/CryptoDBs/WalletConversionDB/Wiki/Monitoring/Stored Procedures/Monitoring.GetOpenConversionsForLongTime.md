# Monitoring.GetOpenConversionsForLongTime

> Detects stuck conversions that have been in Pending status for longer than a configurable threshold, indicating pipeline stalls requiring investigation or manual intervention.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Pending conversions older than threshold |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetOpenConversionsForLongTime finds conversions that remain in Pending (StatusId=1) status for longer than expected. Normal conversions complete in ~4 minutes. A conversion stuck in Pending for hours indicates a pipeline stall - the saga may have failed silently, the worker may have crashed, or an external dependency may be down.

This is one of the most important monitoring procedures - stuck conversions mean customer funds are locked without progress. The procedure joins to Dictionary.ConversionToFiatStatuses to include the human-readable status name in results.

---

## 2. Business Logic

### 2.1 Stuck Pending Conversion Detection

**What**: Finds conversions whose latest status is Pending and age exceeds threshold.

**Columns/Parameters Involved**: `@TimeFrameInHours`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY c.Id ORDER BY cs.Occurred DESC) to get latest status per conversion
- WHERE row_number = 1 AND StatusId = 1 (Pending is the latest status)
- AND DATEDIFF(HOUR, Occurred, GETUTCDATE()) > @TimeFrameInHours
- Default threshold: 10 hours
- JOINs Dictionary.ConversionToFiatStatuses for status Name
- Returns: Id, Occurred, CorrelationId, StatusId, Status name, DetailsJson

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeFrameInHours | int | NO | 10 | VERIFIED | Minimum age in hours for a Pending conversion to be considered stuck. Default 10 hours. |

**Return Columns:**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | Id | bigint | VERIFIED | Conversion ID |
| 2 | Occurred | datetime2 | VERIFIED | Conversion creation time |
| 3 | CorrelationId | uniqueidentifier | VERIFIED | Saga correlation ID for cross-referencing |
| 4 | StatusId | int | VERIFIED | Always 1 (Pending) due to filter |
| 5 | Status | varchar | VERIFIED | "Pending" (from Dictionary.ConversionToFiatStatuses) |
| 6 | DetailsJson | varchar(max) | VERIFIED | Any details from the latest status record |
| 7 | row_number | bigint | CODE-BACKED | Always 1 (from the ROW_NUMBER filter) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | C2F.Conversions | SELECT (FROM) | Conversion details |
| - | C2F.ConversionStatuses | LEFT JOIN | Latest status via ROW_NUMBER |
| - | Dictionary.ConversionToFiatStatuses | LEFT JOIN | Status name lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetOpenConversionsForLongTime (procedure)
├── C2F.Conversions (table)
├── C2F.ConversionStatuses (table)
└── Dictionary.ConversionToFiatStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| C2F.Conversions | Table | FROM - conversion data |
| C2F.ConversionStatuses | Table | LEFT JOIN - status history |
| Dictionary.ConversionToFiatStatuses | Table | LEFT JOIN - status name |

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

### 8.1 Check for stuck conversions (default 10+ hours)
```sql
EXEC Monitoring.GetOpenConversionsForLongTime
```

### 8.2 Check with lower threshold (1 hour)
```sql
EXEC Monitoring.GetOpenConversionsForLongTime @TimeFrameInHours = 1
```

### 8.3 Count stuck conversions by age bucket
```sql
SELECT
    CASE
        WHEN DATEDIFF(HOUR, c.Occurred, GETUTCDATE()) < 1 THEN '< 1h'
        WHEN DATEDIFF(HOUR, c.Occurred, GETUTCDATE()) < 10 THEN '1-10h'
        ELSE '10h+'
    END AS AgeBucket,
    COUNT(*) AS StuckCount
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN (
    SELECT ConversionId, StatusId, ROW_NUMBER() OVER (PARTITION BY ConversionId ORDER BY Id DESC) AS rn
    FROM C2F.ConversionStatuses WITH (NOLOCK)
) cs ON cs.ConversionId = c.Id AND cs.rn = 1
WHERE cs.StatusId = 1
GROUP BY CASE
    WHEN DATEDIFF(HOUR, c.Occurred, GETUTCDATE()) < 1 THEN '< 1h'
    WHEN DATEDIFF(HOUR, c.Occurred, GETUTCDATE()) < 10 THEN '1-10h'
    ELSE '10h+'
END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetOpenConversionsForLongTime | Type: Stored Procedure | Source: WalletConversionDB/Monitoring/Stored Procedures/Monitoring.GetOpenConversionsForLongTime.sql*
