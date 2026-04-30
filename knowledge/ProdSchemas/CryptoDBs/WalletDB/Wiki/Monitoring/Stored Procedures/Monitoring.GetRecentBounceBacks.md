# Monitoring.GetRecentBounceBacks

> Lists recent requests that entered the BounceBackPending state (RequestStatusId=36) within the specified time window, providing a quick count and detail of new bounceback activity.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns recent BounceBackPending request statuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetRecentBounceBacks provides a simple view of recently initiated bouncebacks. While GetBounceBackRequestsByDaysBack classifies bouncebacks by lifecycle stage, this procedure focuses on the initial BounceBackPending trigger event. It answers: "How many bouncebacks were initiated recently?"

Without this procedure, detecting the rate of new bounceback initiation would require manual queries with hardcoded status IDs.

---

## 2. Business Logic

### 2.1 Bounceback Initiation Tracking

**What**: Identifies when requests first enter the bounceback pipeline.

**Columns/Parameters Involved**: `RequestStatusId`, `@HoursBack`

**Rules**:
- RequestStatusId = 36 (BounceBackPending) marks the entry into the bounceback pipeline
- Only status records within the @HoursBack window from current time are returned
- Returns CorrelationId, Gcid, and StatusTimestamp for each bounceback

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Request correlation ID for the bounceback. |
| 2 | Gcid | INT | NO | - | CODE-BACKED | Customer ID affected by the bounceback. |
| 3 | StatusTimestamp | DATETIME2 | NO | - | CODE-BACKED | When the BounceBackPending status was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.RequestStatuses | FROM (read) | Source of status records (StatusId=36) |
| Query body | Wallet.Requests | JOIN | Request metadata (CorrelationId, Gcid) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetRecentBounceBacks (procedure)
  ├── Wallet.RequestStatuses (table)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | FROM - bounceback status events |
| Wallet.Requests | Table | JOIN - request metadata |

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
EXEC Monitoring.GetRecentBounceBacks;
```

### 8.2 Check last 4 hours
```sql
EXEC Monitoring.GetRecentBounceBacks @HoursBack = 4;
```

### 8.3 Count bouncebacks per hour
```sql
SELECT DATEPART(HOUR, RS.Timestamp) AS HourOfDay, COUNT(*) AS BBCount
FROM Wallet.RequestStatuses RS WITH (NOLOCK)
WHERE RS.RequestStatusId = 36 AND RS.Timestamp >= DATEADD(DAY, -1, SYSDATETIME())
GROUP BY DATEPART(HOUR, RS.Timestamp) ORDER BY HourOfDay;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetRecentBounceBacks | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetRecentBounceBacks.sql*
