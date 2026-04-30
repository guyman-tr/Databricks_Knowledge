# Monitoring.NoReceiveTransactionRequestsForLongTime

> Alerts when no receive transaction requests (RequestTypeId=8) have been submitted for longer than the specified threshold, detecting potential receive pipeline outages.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns status 1 (alert) or 0 (OK) based on receive request recency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.NoReceiveTransactionRequestsForLongTime is a heartbeat check for the receive transaction pipeline. Under normal operation, receive requests (RequestTypeId=8) are created continuously as customers receive crypto. If the most recent request is older than the threshold, the receive pipeline may be stalled.

The default 3-hour threshold reflects the expectation that receive requests should be frequent during normal business hours.

---

## 2. Business Logic

### 2.1 Pipeline Heartbeat Check

**What**: Verifies receive requests are still being submitted.

**Columns/Parameters Involved**: `@Hours`, `RequestTypeId`, `Timestamp`

**Rules**:
- Finds MAX(Timestamp) for RequestTypeId = 8
- If NULL or older than threshold -> Status = 1 (Alert)
- Otherwise -> Status = 0 (OK)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Hours | INT | NO | 3 | CODE-BACKED | Threshold in hours. Default 3 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Status | INT | NO | - | CODE-BACKED | 1 = Alert (no recent receive requests), 0 = OK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Checks for recent receive requests (TypeId=8) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.NoReceiveTransactionRequestsForLongTime (procedure)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - MAX(Timestamp) for RequestTypeId=8 |

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

### 8.1 Check with default 3-hour threshold
```sql
EXEC Monitoring.NoReceiveTransactionRequestsForLongTime;
```

### 8.2 Check with 1-hour threshold
```sql
EXEC Monitoring.NoReceiveTransactionRequestsForLongTime @Hours = 1;
```

### 8.3 View latest receive request
```sql
SELECT TOP 1 * FROM Wallet.Requests WITH (NOLOCK) WHERE RequestTypeId = 8 ORDER BY Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.NoReceiveTransactionRequestsForLongTime | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.NoReceiveTransactionRequestsForLongTime.sql*
