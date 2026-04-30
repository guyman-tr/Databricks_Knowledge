# Monitoring.GetDoneAfterErrorRequestStatuses

> Identifies requests that transitioned from Error status to Done status, which may indicate race conditions, retry logic issues, or compensating transactions that override a previous failure.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns requests with Done-after-Error status sequences |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetDoneAfterErrorRequestStatuses detects an abnormal request lifecycle pattern where a request first receives an Error status (RequestStatusId=2) and then later receives a Done status (RequestStatusId=1). In a normal flow, a request should either succeed or fail - not both. This pattern can indicate concurrent processing issues, retry storms, or manual overrides that mask real failures.

Without this procedure, these inconsistent status sequences would go undetected. A request marked as both Error and Done creates ambiguity about whether the operation actually succeeded or failed, potentially leading to double-processing or lost transactions.

The procedure uses two CTEs to find Done and Error status records separately, then joins them to find cases where the Done timestamp is AFTER the Error timestamp, within the specified lookback window.

---

## 2. Business Logic

### 2.1 Status Sequence Anomaly Detection

**What**: Detects Done-after-Error transitions indicating inconsistent request outcomes.

**Columns/Parameters Involved**: `RequestStatusId`, `StatusDoneTime`, `StatusErrorTime`

**Rules**:
- RequestStatusId = 1 means Done (success)
- RequestStatusId = 2 means Error (failure)
- Alert condition: StatusDoneTime > StatusErrorTime (Done came AFTER Error)
- Only requests within the @HoursTimeframe lookback window are scanned

**Diagram**:
```
Normal flow:    Request -> ... -> Done(1)        OK
Normal flow:    Request -> ... -> Error(2)       OK
Anomaly:        Request -> ... -> Error(2) -> ... -> Done(1)  ALERT!
                                    |                   |
                                 Earlier             Later
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursTimeframe | INT | NO | 24 | CODE-BACKED | Lookback window in hours from current UTC time. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RequestId | BIGINT | NO | - | CODE-BACKED | Request ID that exhibits the Done-after-Error anomaly. |
| 2 | CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID for tracing the full request flow. |
| 3 | DetailsJson | NVARCHAR | YES | - | CODE-BACKED | JSON details from the request, useful for understanding what the request was doing. |
| 4 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency involved in the anomalous request. |
| 5 | Gcid | INT | NO | - | CODE-BACKED | Customer ID who owns the anomalous request. |
| 6 | StatusDoneTime | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the Done status was recorded (the later, anomalous status). |
| 7 | StatusErrorTime | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the Error status was recorded (the earlier status that should have been final). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Source of request metadata |
| Query body | Wallet.RequestStatuses | LEFT JOIN | Source of Done (1) and Error (2) status timestamps |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetDoneAfterErrorRequestStatuses (procedure)
  ├── Wallet.Requests (table)
  └── Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - request data |
| Wallet.RequestStatuses | Table | LEFT JOIN - status timestamps |

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
EXEC Monitoring.GetDoneAfterErrorRequestStatuses;
```

### 8.2 Check last week
```sql
EXEC Monitoring.GetDoneAfterErrorRequestStatuses @HoursTimeframe = 168;
```

### 8.3 View full status timeline for an anomalous request
```sql
SELECT rs.RequestId, rs.RequestStatusId, rs.Timestamp, rs.DetailsJson
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
WHERE rs.RequestId = 12345
ORDER BY rs.Timestamp;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetDoneAfterErrorRequestStatuses | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetDoneAfterErrorRequestStatuses.sql*
