# Monitoring.GetStuckRequestsByStatusWindow

> Finds requests stuck at a specific status within a configurable time window, returning detailed request information including how long each request has been in that status.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns requests stuck at a specific status with age details |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetStuckRequestsByStatusWindow is a parameterized stuck-request finder specifically designed for bounceback monitoring. Unlike GetStuckRequestStatuses which checks predefined transition pairs, this procedure accepts any RequestStatusId and a from/to hours window. It finds requests where the specified status is the LATEST status and was set within the time window.

Without this procedure, detecting stuck bouncebacks at specific statuses would require building custom queries for each status/window combination.

The procedure uses NOT EXISTS to ensure the specified status is the most recent one (no newer status exists), and validates that @FromHoursBack > @ToHoursBack.

---

## 2. Business Logic

### 2.1 Status-Specific Stuck Detection

**What**: Finds requests whose latest status matches the specified ID and falls within the time window.

**Columns/Parameters Involved**: `@RequestStatusId`, `@FromHoursBack`, `@ToHoursBack`

**Rules**:
- @FromHoursBack must be greater than @ToHoursBack (validated with RAISERROR)
- The specified status must be the LATEST for that request (NOT EXISTS for newer statuses)
- The status timestamp must be between @FromHoursBack and @ToHoursBack hours ago
- Returns MinutesInStatus calculated from status timestamp to current time

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestStatusId | TINYINT | NO | - | CODE-BACKED | Status ID to check for stuck requests. |
| 2 | @FromHoursBack | INT | NO | - | CODE-BACKED | Start of window (older boundary). Must be > @ToHoursBack. |
| 3 | @ToHoursBack | INT | NO | - | CODE-BACKED | End of window (newer boundary). |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestId | BIGINT | NO | - | CODE-BACKED | Stuck request ID. |
| 2 | StatusTimestamp | DATETIME2 | NO | - | CODE-BACKED | When the stuck status was recorded. |
| 3 | MinutesInStatus | INT | NO | - | CODE-BACKED | How long the request has been in this status (minutes). |
| 4 | RequestStatusId | TINYINT | NO | - | CODE-BACKED | The stuck status ID (echo of input). |
| 5 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Request correlation ID. |
| 6 | Gcid | INT | NO | - | CODE-BACKED | Customer ID. |
| 7 | Cryptoid | INT | NO | - | CODE-BACKED | Cryptocurrency ID. |
| 8 | DeviceId | INT | YES | - | CODE-BACKED | Originating device ID. |
| 9 | RequestTypeId | TINYINT | NO | - | CODE-BACKED | Type of request. |
| 10 | RequestCreatedAt | DATETIME2 | NO | - | CODE-BACKED | When the original request was created. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.RequestStatuses | FROM (read) | Status records for stuck detection |
| Query body | Wallet.Requests | JOIN | Request metadata |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetStuckRequestsByStatusWindow (procedure)
  ├── Wallet.RequestStatuses (table)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | FROM - status records |
| Wallet.Requests | Table | JOIN - request metadata |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Parameter validation | RAISERROR | @FromHoursBack must be > @ToHoursBack, otherwise raises error severity 16 |

---

## 8. Sample Queries

### 8.1 Check for bouncebacks stuck at BounceBackPending for 2-12 hours
```sql
EXEC Monitoring.GetStuckRequestsByStatusWindow @RequestStatusId = 36, @FromHoursBack = 12, @ToHoursBack = 2;
```

### 8.2 Check for requests stuck at status 3 for 1-4 hours
```sql
EXEC Monitoring.GetStuckRequestsByStatusWindow @RequestStatusId = 3, @FromHoursBack = 4, @ToHoursBack = 1;
```

### 8.3 View current latest status distribution
```sql
SELECT rs.RequestStatusId, COUNT(*) AS Count
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Wallet.RequestStatuses rs2 WITH (NOLOCK) WHERE rs2.RequestId = rs.RequestId AND rs2.Timestamp > rs.Timestamp)
  AND rs.Timestamp >= DATEADD(DAY, -1, SYSDATETIME())
GROUP BY rs.RequestStatusId ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetStuckRequestsByStatusWindow | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetStuckRequestsByStatusWindow.sql*
