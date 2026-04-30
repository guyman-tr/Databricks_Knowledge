# Monitoring.NoSendTransactionRequestsForLongTime

> Alerts when no send transaction requests (RequestTypeId=1) have been submitted for longer than the specified threshold, detecting potential send pipeline outages.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns status 1 (alert) or 0 (OK) based on send request recency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.NoSendTransactionRequestsForLongTime is the send-side counterpart to NoReceiveTransactionRequestsForLongTime. It verifies that send transaction requests (RequestTypeId=1) are being submitted regularly. A gap exceeding the threshold indicates the send pipeline may be stalled, preventing customers from sending crypto.

---

## 2. Business Logic

### 2.1 Pipeline Heartbeat Check

**What**: Verifies send requests are still being submitted.

**Columns/Parameters Involved**: `@Hours`, `RequestTypeId`, `Timestamp`

**Rules**:
- Finds MAX(Timestamp) for RequestTypeId = 1 (send transactions)
- If NULL or older than threshold -> Status = 1 (Alert)
- Otherwise -> Status = 0 (OK)
- Default threshold: 3 hours

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
| 1 | Status | INT | NO | - | CODE-BACKED | 1 = Alert (no recent send requests), 0 = OK. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.Requests | FROM (read) | Checks for recent send requests (TypeId=1) |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.NoSendTransactionRequestsForLongTime (procedure)
  └── Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - MAX(Timestamp) for RequestTypeId=1 |

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
EXEC Monitoring.NoSendTransactionRequestsForLongTime;
```

### 8.2 Check with 1-hour threshold
```sql
EXEC Monitoring.NoSendTransactionRequestsForLongTime @Hours = 1;
```

### 8.3 View latest send request
```sql
SELECT TOP 1 * FROM Wallet.Requests WITH (NOLOCK) WHERE RequestTypeId = 1 ORDER BY Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.NoSendTransactionRequestsForLongTime | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.NoSendTransactionRequestsForLongTime.sql*
