# Monitoring.GetRequestStartWOOtherStatus

> Identifies requests that have exactly one status record (only the initial Start) and have been in that state for longer than the specified timeframe, detecting requests stuck at the beginning of processing.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns requests with only a single Start status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetRequestStartWOOtherStatus detects requests that were created but never progressed beyond the initial status. In a healthy flow, a request should quickly acquire additional statuses (processing, done, or error). A request with only one status record that is older than the threshold indicates the processing pipeline may have dropped it.

Without this procedure, these "orphaned" requests would go unnoticed, potentially leaving customer operations in limbo.

The procedure counts statuses per request and filters for those with exactly 1 status, within the window of 1x to 2x @HoursTimeframe ago (avoiding very recent requests that may still be processing normally).

---

## 2. Business Logic

### 2.1 Stuck-at-Start Detection

**What**: Finds requests with no status progression.

**Columns/Parameters Involved**: `@HoursTimeframe`, `RequestStatuses count`

**Rules**:
- Request must have exactly 1 status record (COUNT = 1)
- Request timestamp must be older than @HoursTimeframe hours (not too recent)
- Request timestamp must be newer than @HoursTimeframe * 2 hours (not too old - avoids legacy data)
- Default window: 1-2 hours ago
- Returns SELECT * from Wallet.Requests for matching records

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursTimeframe | INT | NO | 1 | CODE-BACKED | Defines the detection window. Requests between 1x and 2x this value hours old with only 1 status are flagged. |

**Output Columns:**

Returns all columns from Wallet.Requests (SELECT *) for matching requests.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of request records |
| Query body | Wallet.RequestStatuses | Subquery COUNT | Counts statuses per request |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetRequestStartWOOtherStatus (procedure)
  ├── Wallet.Requests (table)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request records |
| Wallet.RequestStatuses | Table | Subquery - status count |

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

### 8.1 Check with default 1-hour window
```sql
EXEC Monitoring.GetRequestStartWOOtherStatus;
```

### 8.2 Check with wider 4-hour window
```sql
EXEC Monitoring.GetRequestStartWOOtherStatus @HoursTimeframe = 4;
```

### 8.3 Count stuck-at-start requests by type
```sql
SELECT r.RequestTypeId, COUNT(*) AS StuckCount
FROM Wallet.Requests r WITH (NOLOCK)
WHERE (SELECT COUNT(*) FROM Wallet.RequestStatuses rs WITH (NOLOCK) WHERE rs.RequestId = r.Id) = 1
  AND r.Timestamp < DATEADD(HOUR, -1, GETUTCDATE())
  AND r.Timestamp > DATEADD(HOUR, -2, GETUTCDATE())
GROUP BY r.RequestTypeId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetRequestStartWOOtherStatus | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetRequestStartWOOtherStatus.sql*
