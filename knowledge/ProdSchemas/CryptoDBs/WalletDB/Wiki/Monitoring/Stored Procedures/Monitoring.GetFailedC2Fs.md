# Monitoring.GetFailedC2Fs

> Retrieves crypto-to-fiat (C2F) conversions that failed, showing the latest failed status details for each conversion within the specified lookback window.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns failed C2F conversions with error details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetFailedC2Fs monitors the crypto-to-fiat conversion pipeline for failures. C2F (Crypto to Fiat) conversions allow customers to sell their crypto holdings for fiat currency. When these fail, customers cannot liquidate their crypto positions, which is a critical business function.

Without this procedure, C2F failures would require manual investigation through multiple tables. Early detection of failure spikes enables the operations team to identify systemic issues (e.g., provider outages, liquidity problems) before they impact a large number of customers.

The procedure joins C2F.Conversions with C2F.ConversionStatuses, finding the latest status per conversion and filtering for StatusId=2 (Failed).

---

## 2. Business Logic

### 2.1 Failed Conversion Detection

**What**: Identifies conversions whose most recent status is Failed.

**Columns/Parameters Involved**: `StatusId`, `ConversionId`

**Rules**:
- StatusId = 2 indicates a failed conversion status
- Only the MOST RECENT status per conversion is checked (MAX(Id) per ConversionId)
- Only conversions that occurred within the lookback window are returned
- Results ordered by conversion time descending

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursToLookBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours for daily monitoring. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | INT | NO | - | CODE-BACKED | Customer whose C2F conversion failed. |
| 2 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID for tracing the conversion flow. |
| 3 | Occurred | DATETIME2 | NO | - | CODE-BACKED | When the conversion was initiated. |
| 4 | CryptoId | INT | NO | - | CODE-BACKED | Source cryptocurrency being converted. |
| 5 | FiatId | INT | NO | - | CODE-BACKED | Target fiat currency. |
| 6 | CryptoAmount | DECIMAL | NO | - | CODE-BACKED | Amount of crypto being converted. |
| 7 | StatusId | TINYINT | NO | - | CODE-BACKED | Status ID of the latest status (always 2 = Failed in results). |
| 8 | DetailsJson | NVARCHAR | YES | - | CODE-BACKED | JSON details of the failure including error codes and messages. |
| 9 | StatusOccurred | DATETIME2 | NO | - | CODE-BACKED | When the failure status was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | C2F.Conversions | FROM (read) | Source of conversion records |
| Query body | C2F.ConversionStatuses | JOIN | Latest failed status per conversion |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

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
| C2F.Conversions | Table | FROM - conversion records |
| C2F.ConversionStatuses | Table | JOIN - status lookup (StatusId=2) |

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

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetFailedC2Fs;
```

### 8.2 Check last 48 hours
```sql
EXEC Monitoring.GetFailedC2Fs @HoursToLookBack = 48;
```

### 8.3 Count failed conversions by crypto type
```sql
SELECT c.CryptoId, COUNT(*) AS FailedCount
FROM C2F.Conversions c WITH (NOLOCK)
INNER JOIN C2F.ConversionStatuses cs WITH (NOLOCK) ON c.Id = cs.ConversionId
  AND cs.Id = (SELECT MAX(Id) FROM C2F.ConversionStatuses WITH (NOLOCK) WHERE ConversionId = c.Id)
WHERE cs.StatusId = 2 AND c.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY c.CryptoId ORDER BY FailedCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetFailedC2Fs | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetFailedC2Fs.sql*
