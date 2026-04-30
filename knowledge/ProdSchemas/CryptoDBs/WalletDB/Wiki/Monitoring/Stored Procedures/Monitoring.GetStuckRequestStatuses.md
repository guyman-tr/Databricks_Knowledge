# Monitoring.GetStuckRequestStatuses

> Detects requests that are stuck at specific status transitions by checking for requests that have a "from" status but never received the expected "to" status, using a configurable set of status transition pairs.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns requests stuck at defined status transition points |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetStuckRequestStatuses is a sophisticated stuck-request detector that works with predefined status transition pairs. Rather than checking for a single stuck status, it verifies that expected status progressions actually happened. For example, if a request reached status 3, it should eventually reach status 4. If it has status 3 but never got status 4 within the timeframe, it is stuck.

Without this procedure, detecting stuck transitions would require separate queries for each transition pair. This procedure centralizes the logic with a configurable transition map.

The procedure uses temp tables to define the expected transitions, then uses a double-timeframe window: requests that entered the "from" status in the older half of the window (1x-2x hours ago) are checked for the "to" status in the full window.

---

## 2. Business Logic

### 2.1 Status Transition Validation

**What**: Validates that specific status transitions complete within the expected timeframe.

**Columns/Parameters Involved**: `@HoursTimeframe`, `FromRequestStatusId`, `ToRequestStatusId`

**Rules**:
- Defined transition pairs: 3->4, 8->9, 28->29, 30->31
- A request is "stuck" if it has the FROM status older than @HoursTimeframe but no TO status in the full 2x window
- Final statuses (1=Done, 2=Error) are excluded from the analysis - these requests are resolved
- Default timeframe: 1 hour

**Diagram**:
```
Expected transitions:
  3 --> 4    (awaiting confirmation -> confirmed)
  8 --> 9    (awaiting processing -> processed)
  28 --> 29  (transition pair 28/29)
  30 --> 31  (transition pair 30/31)

Timeline:
  |---------- 2x hours ago ----------|---- 1x hours ago ----|---- now ----|
  |  "from" status must be here      |  "to" status should  |            |
  |  (old enough to be stuck)        |  exist somewhere     |            |
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursTimeframe | INT | NO | 1 | CODE-BACKED | Base timeframe in hours. Requests must be at FROM status for at least this long without progressing. Window extends to 2x for the full analysis. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | BIGINT | NO | - | CODE-BACKED | Request ID that is stuck at a transition point. |
| 2 | FromStatus | TINYINT | NO | - | CODE-BACKED | The status the request is stuck at (e.g., 3, 8, 28, 30). |
| 3 | ToStatus | TINYINT | YES | - | CODE-BACKED | The expected next status that was never reached. NULL confirms it is missing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of request records |
| Query body | Wallet.RequestStatuses | JOIN | Status records for transition checking |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetStuckRequestStatuses (procedure)
  ├── Wallet.Requests (table)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request records |
| Wallet.RequestStatuses | Table | JOIN - status transition verification |

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
EXEC Monitoring.GetStuckRequestStatuses;
```

### 8.2 Check with 4-hour window
```sql
EXEC Monitoring.GetStuckRequestStatuses @HoursTimeframe = 4;
```

### 8.3 View the full status timeline for a stuck request
```sql
SELECT rs.RequestId, rs.RequestStatusId, rs.Timestamp
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
WHERE rs.RequestId = 12345 ORDER BY rs.Timestamp;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetStuckRequestStatuses | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetStuckRequestStatuses.sql*
